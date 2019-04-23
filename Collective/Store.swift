//
//  Store.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/23/19.
//

import Foundation

protocol WWStoreDefinition {
    associatedtype State
    associatedtype Action
    associatedtype Output
    associatedtype Agent
}

class WWStore<Definition: WWStoreDefinition> {
    typealias State = Definition.State
    typealias Action = Definition.Action
    typealias Output = Definition.Output
    typealias Agent = Definition.Agent
    
    typealias AgentHandler = (Agent, @escaping (Action) -> Void) -> Void
    
    public private(set) var state: State
    internal var stateObservers: [(State) -> Void] = []
    internal var outputObservers: [(Output, State) -> Void] = []
    private let agentHandler: AgentHandler
    
    internal let qos: DispatchQoS
    private lazy var processingQueue = DispatchQueue(label: "StoreProcessing", qos: qos)
    
    // Public API
    
    public init(initialState: State, agentHandler: @escaping AgentHandler, qos: DispatchQoS = .userInitiated) {
        self.state = initialState
        self.agentHandler = agentHandler
        self.qos = qos
    }
    
    open func reduce(action: Action, state: State) -> (State?, Output?) {
        fatalError(abstractMethodMessage)
    }
    
    public func observeState(_ observer: @escaping (State) -> Void) {
        stateObservers.append(observer)
        let currentState = state
        emit {
            observer(currentState)
        }
    }
    
    public func observeOutput(_ observer: @escaping (Output, State) -> Void) {
        outputObservers.append(observer)
    }
    
    public func dispatchAction(_ action: Action) {
        processingQueue.async {
            let (newState, output) = self.reduce(action: action, state: self.state)
            if let someNewState = newState {
                self.state = someNewState
                emit {
                    self.stateObservers.forEach({ $0(someNewState) })
                }
            }
            if let someOutput = output {
                emit {
                    self.outputObservers.forEach({ $0(someOutput, newState ?? self.state) })
                }
            }
        }

    }
    
    public func executeAgent(_ agent: Agent) {
        processingQueue.async {
            self.agentHandler(agent) { [weak self] action in
                self?.dispatchAction(action)
            }
        }
    }
    
}

private func emit(_ execute: @escaping () -> Void) {
    DispatchQueue.main.async(execute: execute)
}
