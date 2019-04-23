//
//  TBStore.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/23/19.
//

import Foundation

public protocol TBStoreDefinition {
    associatedtype State
    associatedtype Action
    associatedtype Output
}

public protocol TBViewDefinition {
    associatedtype ViewState
    associatedtype ViewAction
}

public protocol TBStoreProtocol: AnyObject, TBStoreDefinition {
    func handleAction(_ action: Action)
    func observeState(_ observer: @escaping (State) -> Void)
    func observeOutput(_ observer: @escaping (Output, State) -> Void)
}

class TBModule<Action, Output> {
    
    
    
}

open class TBStore<Definition: TBStoreDefinition>: TBStoreProtocol {
    public typealias State = Definition.State
    public typealias Action = Definition.Action
    public typealias Output = Definition.Output
    
    public private(set) var state: State
    internal var stateObservers: [(State) -> Void] = []
    internal var outputObservers: [(Output, State) -> Void] = []
    
    internal let qos: DispatchQoS
    private lazy var processingQueue = DispatchQueue(label: "StoreProcessing", qos: qos)
    
    // Public API
    
    public static func create(with initialState: State) -> AnyTBStore<TBStore<Definition>> {
        let store = self.init(initialState: initialState)
        return store.asAnyStore()
    }
    
    public required init(initialState: State, qos: DispatchQoS = .userInitiated) {
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

public class AnyTBStore<Store: TBStoreProtocol>: TBStoreProtocol {
    public typealias State = Store.State
    public typealias Action = Store.Action
    public typealias Output = Store.Output
    
    private let store: Store
    
    init(_ store: Store) {
        self.store = store
    }
    
    public func handleAction(_ action: Action) {
        store.handleAction(action)
    }
    
    public func observeState(_ observer: @escaping (State) -> Void) {
        store.observeState(observer)
    }
    
    public func observeOutput(_ observer: @escaping (Output, State) -> Void) {
        store.observeOutput(observer)
    }
    
}

extension TBStoreProtocol {
    
    func asAnyStore() -> AnyTBStore<Self> {
        return AnyTBStore<Self>(self)
    }
    
}
