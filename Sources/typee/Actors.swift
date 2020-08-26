//
//  Actors.swift
//  typee
//
//  Created by LILLY on 8/24/20.
//

import Foundation

public protocol ActorProtocol: Identifiable {
    var messageQueue: DispatchQueue { get }
    func isValidDeclaration() throws -> Bool
    mutating func finalize()
    var id: UUID { get }
}
public enum InvalidDeclaration: Error {
    case actorExposesUntrustedMembers(variable: String)
}

public extension ActorProtocol {
    func isValidDeclaration() throws -> Bool {
        let mirror = Mirror.init(reflecting: self)
        for variable in mirror.children.filter({
            String(describing: $0.value).hasSuffix("-> ()")
        }) {
            if !(variable.value is _isBehaviour) {
                throw InvalidDeclaration.actorExposesUntrustedMembers(variable: variable.label!)
            }
        }
        return true
    }
    mutating func finalize() {
        let mirror = Mirror.init(reflecting: self)
        var children = mirror.children.filter({
            String(describing: $0.value).hasSuffix("-> ()")
        })
        for (idx, member) in children.enumerated() {
            var val = (member.value as! HasInjectableQueue)
            val.injectQueue(self.messageQueue)
            children[idx].value = val
        }
    }
}
internal protocol HasInjectableQueue {
    mutating func injectQueue(_ info: DispatchQueue)
}
protocol _isBehaviour { var dispatchProxy: DispatchQueue? { get } }
@propertyWrapper
public class Behaviour<Input>: HasInjectableQueue, _isBehaviour {
    
    private var value: (Input) -> Void
    //let methodName: String
    public var dispatchProxy: DispatchQueue? = nil
    public var wrappedValue: (Input) -> Void {
        get {
            return self.run
        }
        set { value = newValue }
    }
    internal func run (_ args: Input) -> Void {
        self.dispatchProxy!.sync {
            self.value(args)
        }
    }
    public init(wrappedValue: @escaping (Input) -> Void) {
        value = wrappedValue
    }
    internal func injectQueue(_ info: DispatchQueue) {
        self.dispatchProxy = info
    }
}
@propertyWrapper
struct Actor<T: ActorProtocol> {
    var value: T
    var wrappedValue: T {
        get { return value }
        set {
            do {
                _ = try newValue.isValidDeclaration()
                var val = newValue
                val.finalize()
                value = val
            } catch {
                if case InvalidDeclaration.actorExposesUntrustedMembers(variable: let name) = error {
                    fatalError("""
                    Actor \(newValue) does not satisfy requirements of a protocol, because it has
                    behaiviour named \(name), that is not declared with @Behaviour property.
                    Note: actors can only contain @Behaviours"
                    """)
                }
            }
        }
    }
    init(wrappedValue: T) {
        self.value = wrappedValue
        self.wrappedValue = wrappedValue
    }
}
