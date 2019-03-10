//
//  Types.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/7/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

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

public protocol StoreType: StateObservableType, StateStoreType, ActionObserverType, OutputObservableType {
    func asStore() -> AnyStore<State, Action, Output>
}

internal protocol _StoreType: StoreType, _StateObservableType, _ActionObserverType, _OutputObservableType  { }

public protocol ViewStoreType: StateObservableType, StateStoreType, ActionObserverType {
    func asViewStore() -> AnyViewStore<State, Action>
}

internal protocol _ViewStoreType: ViewStoreType, _StateObservableType, _ActionObserverType { }

public protocol ClientStoreType: StateStoreType, ActionObserverType, OutputObservableType {
    func asClientStore() -> AnyClientStore<State, Action, Output>
}

internal protocol _ClientStoreType: ClientStoreType, _ActionObserverType, _OutputObservableType { }

public protocol StateObservableType: AnyObject {
    associatedtype State
    
    func observeState(_ observer: @escaping (State) -> Void)
}

internal protocol _StateObservableType: StateObservableType {
    var stateObservable: Observable<State> { get }
    var bag: DisposeBag { get }
}

public protocol StateStoreType: AnyObject {
    associatedtype State
    
    var getState: () -> State { get }
}

public protocol ActionObserverType: AnyObject {
    associatedtype Action
    
    func dispatchAction(_ action: Action)
}

internal protocol _ActionObserverType: ActionObserverType {
    var actionObserver: AnyObserver<Action> { get }
}

public protocol OutputObservableType: AnyObject {
    associatedtype Output
    
    func observeOutput(_ observer: @escaping (Output) -> Void)
}

internal protocol _OutputObservableType: OutputObservableType {
    var outputObservable: Observable<Output> { get }
    var bag: DisposeBag { get }
}

extension _StateObservableType {
    
    public func observeState(_ observer: @escaping (State) -> Void) {
        stateObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                observer($0)
            })
            .disposed(by: bag)
    }
    
}

extension StateStoreType {
    
    public var state: State {
        return getState()
    }
    
}

extension _ActionObserverType {
    
    public func dispatchAction(_ action: Action) {
        self.actionObserver.onNext(action)
    }
    
}

extension _OutputObservableType {
    
    public func observeOutput(_ observer: @escaping (Output) -> Void) {
        outputObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                observer($0)
            })
            .disposed(by: bag)
    }
    
}

public class AnyStore<State, Action, Output>: _StoreType {

    let stateObservable: Observable<State>
    public let getState: () -> State
    let actionObserver: AnyObserver<Action>
    let outputObservable: Observable<Output>
    let bag: DisposeBag
    
    private let store: AnyObject
    
    internal init<Store: _StoreType>(_ store: Store) where Store.State == State, Store.Action == Action, Store.Output == Output {
        self.getState = store.getState
        self.stateObservable = store.stateObservable
        self.actionObserver = store.actionObserver
        self.outputObservable = store.outputObservable
        self.bag = store.bag
        self.store = store
    }
    
}

public class AnyViewStore<State, Action>: _ViewStoreType {
    
    let stateObservable: Observable<State>
    public let getState: () -> State
    let actionObserver: AnyObserver<Action>
    let bag: DisposeBag
    
    private let store: AnyObject
    
    internal init<Store: _ViewStoreType>(_ store: Store) where Store.State == State, Store.Action == Action {
        self.getState = store.getState
        self.stateObservable = store.stateObservable
        self.actionObserver = store.actionObserver
        self.bag = store.bag
        self.store = store
    }
    
}

public class AnyClientStore<State, Action, Output>: _ClientStoreType {
    
    public let getState: () -> State
    let actionObserver: AnyObserver<Action>
    let outputObservable: Observable<Output>
    let bag: DisposeBag
    
    private let store: AnyObject
    
    internal init<Store: _ClientStoreType>(_ store: Store) where Store.State == State, Store.Action == Action, Store.Output == Output {
        self.getState = store.getState
        self.actionObserver = store.actionObserver
        self.outputObservable = store.outputObservable
        self.bag = store.bag
        self.store = store
    }
    
}

extension _StoreType {

    public func asStore() -> AnyStore<State, Action, Output> {
        return AnyStore(self)
    }

}

extension _ViewStoreType {
    
    public func asViewStore() -> AnyViewStore<State, Action> {
        return AnyViewStore(self)
    }
    
}

extension _ClientStoreType {
    
    public func asClientStore() -> AnyClientStore<State, Action, Output> {
        return AnyClientStore(self)
    }
    
}
