//
//  TBStore.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/23/19.
//

import Foundation

protocol TBStoreDefinition {
    associatedtype State
    associatedtype Action
    associatedtype Output
}

protocol TBViewDefinition {
    associatedtype ViewState
    associatedtype ViewAction
}

protocol TBStoreProtocol {
    associatedtype State
    associatedtype Action
    associatedtype Output
    
    func handleAction(_ action: Action)
    func observeState(_ observer: @escaping (State) -> Void)
    func observeOutput(_ observer: @escaping (Output, State) -> Void)
}

class TBStore<Definition: TBStoreDefinition>: TBStoreProtocol {
    typealias State = Definition.State
    typealias Action = Definition.Action
    typealias Output = Definition.Output
    
    public private(set) var state: State
    internal var stateObservers: [(State) -> Void] = []
    internal var outputObservers: [(Output, State) -> Void] = []
    
    internal let qos: DispatchQoS
    private lazy var processingQueue = DispatchQueue(label: "StoreProcessing", qos: qos)
    
    // Public API
    
    internal init(initialState: State, qos: DispatchQoS = .userInitiated) {
        self.state = initialState
        self.qos = qos
    }
    
    open func handleAction(_ action: Action) {
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
    
    public func update(_ newState: State) {
        self.state = newState
        emit {
            self.stateObservers.forEach({ $0(newState) })
        }
    }
    
    public func output(_ output: Output) {
        let currentState = state
        emit {
            self.outputObservers.forEach({ $0(output, currentState) })
        }
    }
    
}

private func emit(_ execute: @escaping () -> Void) {
    DispatchQueue.main.async(execute: execute)
}

class TBStoreAdapter<StoreDefinition: TBStoreDefinition, ViewDefinition: TBViewDefinition> {
    typealias Store = TBStore<StoreDefinition>
    typealias ViewState = ViewDefinition.ViewState
    typealias ViewAction = ViewDefinition.ViewAction
    
    typealias StateMap = (Store.State) -> ViewState
    typealias ActionMap = (ViewAction) -> Store.Action
    
    private let stateMap: StateMap
    private let actionMap: ActionMap
    
    private let store: Store
    
    init(_ store: Store, stateMap: @escaping StateMap, actionMap: @escaping ActionMap) {
        self.store = store
        self.stateMap = stateMap
        self.actionMap = actionMap
    }
    
    var viewState: ViewState {
        return stateMap(store.state)
    }
    
    func observeState(_ observer: @escaping (ViewState) -> Void) {
        let stateMap = self.stateMap
        store.observeState({ state in
            let viewState = stateMap(state)
            observer(viewState)
        })
    }
    
    func dispatchAction(_ viewAction: ViewAction) {
        let action = actionMap(viewAction)
        store.handleAction(action)
    }
    
}
