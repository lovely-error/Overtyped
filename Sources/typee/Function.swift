//
//  Function.swift
//  SOOQAframework
//
//  Created by Lolka_malyavka on 8/22/20.
//

import Foundation


@propertyWrapper
open class Function<Args, R> {
    
    private var preconditions: Array<(Args) -> Bool> = []
    private var preCalls: [(Args) -> Void] = []
    private var function: (Args) throws -> R
    private var postconditions: Array<(R) -> Bool> = []
    private var postCalls: [(Args) -> Void] = []
    open var projectedValue: Function<Args, R> { return self }
    public var wrappedValue: (Args) throws -> R {
        get {
            return self.invoke
        }
        set { function = newValue }
    }
    public enum PredicateError: Error {
        case precondition((Args) throws -> Bool)
        case postcondition((R) throws -> Bool)
    }

    public init(wrappedValue: @escaping (Args) throws -> R){
        self.function = wrappedValue
    }

    internal func invoke(_ arg: Args) throws -> R {
        defer {
            for f in self.postCalls {
                f(arg)
            }
        }
        
        for f in self.preCalls {
            f(arg)
        }
        
        for i in self.preconditions {
            if i(arg) == false {
                throw PredicateError.precondition(i)
            }
        }
        
        let result: R
        do {
            result = try self.function(arg)
        } catch let error {
            throw error
        }
        
        for i in self.postconditions {
            if i(result) == false {
                throw PredicateError.postcondition(i)
            }
        }
        
        return result
    }
    public func afterCall(_ closure: @escaping (Args) -> Void) {
        self.postCalls.append(closure)
    }
    public func beforeCall(_ closure: @escaping (Args) -> Void) {
        self.preCalls.append(closure)
    }
    public func addPrecondition(_ newPrecondition: @escaping Predicate<Args>) {
        self.preconditions.append(newPrecondition)
    }
    public func addPostcondition(_ newPostcondition: @escaping Predicate<R>) {
        self.postconditions.append(newPostcondition)
    }
}

infix operator <<! : DefaultPrecedence
public func <<! <Args, R>(lhs: Function<Args, R>, rhs: Args) -> R {
    return try! lhs.invoke(rhs)
}
infix operator <<? : DefaultPrecedence
public func <<? <Args, R>(lhs: Function<Args, R>, rhs: Args) throws -> R {
    do {
        return try lhs.invoke(rhs)
    } catch let error {
        throw error
    }
}
