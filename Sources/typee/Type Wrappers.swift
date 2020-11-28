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


public final class State: Equatable, Hashable {
//        enum SuccessorExpandingError: Error {
//            case stateIsAlreadyAmongSuccessors
//        }
    let name: String
    let predicate: (Any) -> Bool
    private(set) var availableSuccsessors: Set<State> = []
    public  func addSuccesorState(_ state: State...) /*throws*/ {
        state.forEach({ state in
            availableSuccsessors.insert(state)
        })
    }
    public static func == (lhs: State, rhs: State) -> Bool {
        return lhs.name == rhs.name
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
    init(name: String, predicate: @escaping (Any) -> Bool) {
        self.name = name
        self.predicate = predicate
    }
}
public struct TransitionGraph {
    var initialState: State
    let setOfStates: Set<State>
}
@propertyWrapper
public struct Stateful<Value> {
    private var value: Value
    private(set) var transitionGraph: Set<State>
    private(set) var currentState: State
    public var wrappedValue: Value {
        get { value }
        set {
            var satisfied: Bool = false
            var candidateTransition: State? = nil
            for state in currentState.availableSuccsessors {
                if state.predicate(newValue) {
                    if satisfied == true {
                        fatalError("""
                        Found multiple possible next states for transition, but transitions must be deterministic,
                            and thus contain only single valid transition.
                            New value can become both \(candidateTransition!.name) and \(state.name)
                        """)
                    
                    }
                    satisfied = true
                    candidateTransition = state
                }
            }
            if satisfied {
                self.value = newValue
                self.currentState = candidateTransition!
            } else {
                fatalError("""
                    The current state '\(currentState.name)' does not contain any available succesor states for the value '\(newValue)'.
                    Expected to have one of the following: '\(currentState.availableSuccsessors.map({$0.name}))'
                    """)
            }
        }
    }
    public init(wrappedValue: Value, configuration: TransitionGraph) {
        self.currentState = configuration.initialState
        if self.currentState.predicate(wrappedValue) {
            self.value = wrappedValue
        } else {
            fatalError("""
            Value '\(wrappedValue)' cannot be assigned, because it cannot be used to construct state '\(configuration.initialState.name)'.
            """)
        }
        self.transitionGraph = configuration.setOfStates
    }
}
infix operator =>> : MultiplicationPrecedence
@discardableResult
func =>> (lhs: State, rhs: State) -> State {
    lhs.addSuccesorState(rhs)
    return rhs
}
public enum MatchReport: Equatable, Hashable, ExpressibleByBooleanLiteral {
   public typealias BooleanLiteralType = Bool
   case allOk, violation
   public init(booleanLiteral value: Bool) {
      if value {
         self = .allOk
      } else {
         self = .violation
      }
   }
}
@propertyWrapper
public struct Modal<Value> {
   public struct Condition {
      let description: String
      let condition: (Value) -> Bool
      let check: (Value) -> MatchReport
      let discardOption: DiscardOption
   }
   public enum DiscardOption {
      case never, onCondition((Value) -> Bool)
   }
   private var value: Value
   public var wrappedValue: Value {
      mutating get {
         if !activeTriggers.isEmpty {
            for (idx, cond) in activeTriggers.enumerated() {
               if cond.check(value) == .violation {
                  fatalError("""
                  Value \(value) violated condition that is '\(cond.description)'
                  """)
               }
               if case DiscardOption.onCondition(let icond) = cond.discardOption {
                  if icond(value) == true { activeTriggers.remove(at: idx) }
               }
            }
         }
         return value
      }
      set(nw) {
         if !activeTriggers.isEmpty {
            for (idx, cond) in activeTriggers.enumerated() {
               if cond.check(nw) == .violation {
                  fatalError("""
                  Value \(value) violated condition that is '\(cond.description)'
                  """)
               }
               if case DiscardOption.onCondition(let icond) = cond.discardOption {
                  if icond(nw) == true { activeTriggers.remove(at: idx) }
               }
            }
         }
         for (idx, cond) in allConditions.enumerated() {
            if cond.condition(nw) == true { activeTriggers.append(cond); allConditions.remove(at: idx) }
         }
         value = nw
      }
   }
   private var activeTriggers: Array<Condition> = []
   private var allConditions: Array<Condition>
   public init (wrappedValue: Value, conditions: Array<Condition> = []) {
      self.value = wrappedValue
      allConditions = conditions
   }
   public mutating func necessarily(
      after condition: @escaping (Value) -> Bool,
      ensure constraint: @escaping (Value) -> MatchReport,
      description: (Value) -> String,
      discard option: DiscardOption = .never
   ) {
      allConditions.append(Condition
                              .init(description: description(value), condition: condition,
                                    check: constraint, discardOption: option))
   }
}
