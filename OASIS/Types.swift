//
//  Types.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/7/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

public protocol StoreDefinition {
    associatedtype State
    associatedtype Action
    associatedtype Output
    
    typealias Store = AnyStore<State, Action, Output>
}

public protocol ViewDefinition {
    associatedtype ViewState
    associatedtype ViewAction
}

public protocol ViewType: AnyObject {
    associatedtype Definition: ViewDefinition
    
    typealias ViewState = Definition.ViewState
    typealias ViewAction = Definition.ViewAction
    
    typealias Store = AnyViewStore<ViewState, ViewAction>
    
    func render(_ viewState: ViewState)
}

public protocol ViewStoreType: AnyObject {
    associatedtype State
    associatedtype Action
    
    typealias StateObserver = (State) -> Void
    
    func observeState(_ stateObserver: @escaping StateObserver)
    func dispatchAction(_ action: Action)
}

public protocol ClientStoreType: AnyObject {
    associatedtype Action
    associatedtype Output
    
    typealias OutputObserver = (Output) -> Void
    
    func observeOutput(_ outputObserver: @escaping OutputObserver)
    func dispatchAction(_ action: Action)
}

public protocol StoreType: ViewStoreType, ClientStoreType {}

public class AnyViewStore<State, Action>: ViewStoreType {
    
    private let _observeState: (@escaping (State) -> Void) -> Void
    private let _dispatchAction: (Action) -> Void
    
    internal init<Store: ViewStoreType>(_ store: Store) where Store.State == State, Store.Action == Action {
        _observeState = store.observeState
        _dispatchAction = store.dispatchAction
    }
    
    public func observeState(_ stateObserver: @escaping (State) -> Void) {
        _observeState(stateObserver)
    }
    
    public func dispatchAction(_ action: Action) {
        _dispatchAction(action)
    }
    
}

public class AnyClientStore<Action, Output>: ClientStoreType {
    
    private let _observeOutput: (@escaping (Output) -> Void) -> Void
    private let _dispatchAction: (Action) -> Void
    
    internal init<Store: ClientStoreType>(_ store: Store) where Store.Action == Action, Store.Output == Output {
        _observeOutput = store.observeOutput
        _dispatchAction = store.dispatchAction
    }
    
    public func observeOutput(_ outputObserver: @escaping (Output) -> Void) {
        _observeOutput(outputObserver)
    }
    
    public func dispatchAction(_ action: Action) {
        _dispatchAction(action)
    }
    
}

public class AnyStore<State, Action, Output>: StoreType {
    
    private let _observeState: (@escaping (State) -> Void) -> Void
    private let _observeOutput: (@escaping (Output) -> Void) -> Void
    private let _dispatchAction: (Action) -> Void
    
    internal init<Store: StoreType>(_ store: Store) where Store.State == State, Store.Action == Action, Store.Output == Output {
        _observeState = store.observeState
        _observeOutput = store.observeOutput
        _dispatchAction = store.dispatchAction
    }
    
    public func observeState(_ stateObserver: @escaping (State) -> Void) {
        _observeState(stateObserver)
    }
    
    public func observeOutput(_ outputObserver: @escaping (Output) -> Void) {
        _observeOutput(outputObserver)
    }
    
    public func dispatchAction(_ action: Action) {
        _dispatchAction(action)
    }
    
}

extension ViewStoreType {
    
    public func asViewStore() -> AnyViewStore<State, Action> {
        return AnyViewStore(self)
    }
    
}

extension ClientStoreType {
    
    public func asClientStore() -> AnyClientStore<Action, Output> {
        return AnyClientStore(self)
    }
    
}

extension StoreType {
    
    public func asStore() -> AnyStore<State, Action, Output> {
        return AnyStore(self)
    }
    
}
