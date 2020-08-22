//
//  Type Wrappers.swift
//  SOOQAframework
//
//  Created by SOOQA on 8/22/20.
//

import Foundation

@propertyWrapper
public struct Unique<T> {
    internal enum State {
        case present(T)
        case absent
    }
    internal var value: State
    public var projectedValue: Unique<T> { return self }
    public var isEmpty: Bool {
        switch self.value {
            case .absent:
            return true
            default:
            return false
        }
    }
    public var wrappedValue: T {
        mutating get {
            switch self.value {
                case .present(let val):
                    self.value = .absent
                    return val
                default:
                    fatalError("Value has already been used at this time and has been moved out to a another place.")
            }
        }
        set {
            value = .present(newValue)
        }
    }
    public mutating func fill (with newValue: T) {
        self.value = .present(newValue)
    }
    public init(wrappedValue: T) {
        self.value = .present(wrappedValue)
    }
}
public typealias Predicate<T> = (T) -> Bool
@propertyWrapper
public final class Constrained<T> {
    
    internal var constraints: Array<Predicate<T>>
    internal var value: T
    public var projectedValue: Constrained<T> { return self }
    public var wrappedValue: T {
        get { return value  }
        set {
            //#if debug
            for predicate in constraints {
                if predicate(newValue) == false {
                    fatalError("""
                    Predicate \(String(describing: predicate)) of constrained value '\(self)' was not satisfied with value \(newValue)
                    """)
                }
            }
            //#endif
            value = newValue
        }
    }
    public init(wrappedValue: T, by constraints: Array<Predicate<T>> = []) {
        self.constraints = constraints
        self.value = wrappedValue
        self.wrappedValue = value
    }
    public init(wrappedValue: T, by constraint: @escaping Predicate<T>) {
        self.constraints = []
        self.constraints.append(constraint)
        self.value = wrappedValue
        self.wrappedValue = value
    }
    public func addNewConstraint(_ constraint: @escaping Predicate<T>) {
        self.constraints.append(constraint)
    }
}
@propertyWrapper
public struct Linear<T> {
    public enum Strictness: Equatable { case exact, inexact }
    internal var value: T
    private var typeSequence: ArraySlice<(T) -> Bool>
    private let strictness: Strictness
    public var wrappedValue: T {
        get {
            return value
        }
        set {
            //#if debug
            if typeSequence.isEmpty {
                switch strictness {
                    case .exact:
                    fatalError("""
                    Variable has been exhausted. It cannot accept new value, because it is made strict.
                    If you need to allow further mutation after the last predicate was hold true,
                    initialize property wrapper with .inexact strictness.
                    """)
                    case .inexact:
                    value = newValue
                }
            } else {
                if typeSequence.first!(newValue) {
                    value = newValue
                } else { fatalError("Unsatisfied predicate") }
                typeSequence = typeSequence.dropFirst()
            }
            //#else
            //value = newValue
            //#endif
        }
    }
    public init(wrappedValue: T, strictness: Strictness = .exact, _ typeSequence: Array<(T) -> Bool>) {
        self.typeSequence = typeSequence[...]
        value = wrappedValue
        self.strictness = strictness
        self.wrappedValue = wrappedValue
    }
}
