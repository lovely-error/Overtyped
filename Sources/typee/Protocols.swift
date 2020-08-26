//
//  Protocols.swift
//  typee
//
//  Created by aoAOAOoaooAOaoaoOAooaoAoaoaOAOoAoao on 8/26/20.
//
protocol StatefulType {
    associatedtype StateRepresentingType: CaseIterable
    var currentState: StateRepresentingType { get }
}
