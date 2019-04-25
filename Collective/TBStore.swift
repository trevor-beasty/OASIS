//
//  TBStore.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/23/19.
//

import Foundation

public protocol TBModuleDefinition {
    associatedtype Action
    associatedtype Output
}

public protocol TBStoreDefinition: TBModuleDefinition {
    associatedtype State
}

public protocol TBViewDefinition {
    associatedtype ViewState
    associatedtype ViewAction
}

public protocol TBModuleProtocol: TBModuleDefinition {
    func handleAction(_ action: Action)
    func observeOutput(_ observer: @escaping (Output) -> Void)
}

public protocol TBStoreProtocol: TBStoreDefinition, StateBindable {
    func handleAction(_ action: Action)
    func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void)
}

open class TBModule<Action, Output>: TBModuleProtocol {
    
    private var outputObservers: [(Output) -> Void] = []
    
    public init() { }
    
    open func handleAction(_ action: Action) {
        fatalError(abstractMethodMessage)
    }
    
    public func observeOutput(_ observer: @escaping (Output) -> Void) {
        outputObservers.append(observer)
    }
    
    public func output(_ output: Output) {
        emit {
            self.outputObservers.forEach({ $0(output) })
        }
    }
    
}

open class TBStore<Definition: TBStoreDefinition>: TBModule<Definition.Action, Definition.Output>, TBStoreProtocol {
    public typealias State = Definition.State
    public typealias R = State
    
    public private(set) var stateBinder: Binder<State>
    private var stateObservers: [(State) -> Void] = []
    
    public static func create(with initialState: State) -> AnyTBStore<TBStore<Definition>> {
        let store = self.init(initialState: initialState)
        return store.asAnyStore()
    }
    
    public required init(initialState: State) {
        self.stateBinder = Binder(initialState)
    }
    
    public func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void) {
        observeOutput({ [weak self] output in
            guard let strongSelf = self else { return }
            observer(output, strongSelf .stateBinder.value)
        })
    }
    
}

private func emit(_ execute: @escaping () -> Void) {
    DispatchQueue.main.async(execute: execute)
}

internal class TBStoreAdapter<StoreDefinition: TBStoreDefinition, ViewDefinition: TBViewDefinition>: StateBindable {
    typealias Store = TBStore<StoreDefinition>
    typealias State = StoreDefinition.State
    typealias Action = StoreDefinition.Action
    typealias ViewState = ViewDefinition.ViewState
    typealias ViewAction = ViewDefinition.ViewAction
    
    typealias R = ViewState
    
    typealias StateMap = (State) -> ViewState
    typealias ActionMap = (ViewAction) -> Action
    
    private let stateMap: StateMap
    private let actionMap: ActionMap
    
    private let store: Store
    
    internal init(_ store: Store, stateMap: @escaping StateMap, actionMap: @escaping ActionMap) {
        self.store = store
        self.stateMap = stateMap
        self.actionMap = actionMap
    }
    
    func dispatchAction(_ viewAction: ViewAction) {
        let action = actionMap(viewAction)
        store.handleAction(action)
    }
    
    var stateBinder: Binder<State> {
        return store.stateBinder
    }
    
    var transform: (State) -> ViewState {
        return stateMap
    }
    
}

public class AnyTBStore<Store: TBStoreProtocol>: TBStoreProtocol {
    public typealias State = Store.State
    public typealias Action = Store.Action
    public typealias Output = Store.Output
    
    public typealias R = State
    
    private let store: Store
    
    internal init(_ store: Store) {
        self.store = store
    }
    
    public func handleAction(_ action: Action) {
        store.handleAction(action)
    }
    
    public func observeStatefulOutput(_ observer: @escaping (Output, State) -> Void) {
        store.observeStatefulOutput(observer)
    }
    
    public var stateBinder: Binder<State> {
        return store.stateBinder
    }
    
}

extension TBStoreProtocol {
    
    func asAnyStore() -> AnyTBStore<Self> {
        return AnyTBStore<Self>(self)
    }
    
}
