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

internal protocol StoreType: StateObservableType, StateStoreType, ActionObserverType, OutputObservableType { }

internal protocol ViewStoreType: StateObservableType, StateStoreType, ActionObserverType { }

internal protocol ClientStoreType: StateStoreType, ActionObserverType, OutputObservableType { }

internal protocol StateObservableType: AnyObject {
    associatedtype State
    
    var stateObservable: Observable<State> { get }
    var bag: DisposeBag { get }
}

internal protocol StateStoreType: AnyObject {
    associatedtype State
    
    var state: () -> State { get }
}

internal protocol ActionObserverType: AnyObject {
    associatedtype Action
    
    var actionObserver: AnyObserver<Action> { get }
}

internal protocol OutputObservableType: AnyObject {
    associatedtype Output
    
    var outputObservable: Observable<Output> { get }
    var bag: DisposeBag { get }
}

extension StateObservableType {
    
    public func observeState(_ observer: @escaping (State) -> Void) {
        stateObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                observer($0)
            })
            .disposed(by: bag)
    }
    
}

extension ActionObserverType {
    
    public func dispatchAction(_ action: Action) {
        self.actionObserver.onNext(action)
    }
    
}

extension OutputObservableType {
    
    public func observeOutput(_ observer: @escaping (Output) -> Void) {
        outputObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                observer($0)
            })
            .disposed(by: bag)
    }
    
}

public class AnyStore<State, Action, Output>: StoreType {

    let stateObservable: Observable<State>
    let state: () -> State
    let actionObserver: AnyObserver<Action>
    let outputObservable: Observable<Output>
    let bag: DisposeBag
    
    private let store: AnyObject
    
    internal init<Store: StoreType>(_ store: Store) where Store.State == State, Store.Action == Action, Store.Output == Output {
        self.state = store.state
        self.stateObservable = store.stateObservable
        self.actionObserver = store.actionObserver
        self.outputObservable = store.outputObservable
        self.bag = store.bag
        self.store = store
    }
    
}

public class AnyViewStore<State, Action>: ViewStoreType {
    
    let stateObservable: Observable<State>
    let state: () -> State
    let actionObserver: AnyObserver<Action>
    let bag: DisposeBag
    
    private let store: AnyObject
    
    internal init<Store: ViewStoreType>(_ store: Store) where Store.State == State, Store.Action == Action {
        self.state = store.state
        self.stateObservable = store.stateObservable
        self.actionObserver = store.actionObserver
        self.bag = store.bag
        self.store = store
    }
    
}

public class AnyClientStore<State, Action, Output>: ClientStoreType {
    
    let state: () -> State
    let actionObserver: AnyObserver<Action>
    let outputObservable: Observable<Output>
    let bag: DisposeBag
    
    private let store: AnyObject
    
    internal init<Store: ClientStoreType>(_ store: Store) where Store.State == State, Store.Action == Action, Store.Output == Output {
        self.state = store.state
        self.actionObserver = store.actionObserver
        self.outputObservable = store.outputObservable
        self.bag = store.bag
        self.store = store
    }
    
}

extension StoreType {

    public func asStore() -> AnyStore<State, Action, Output> {
        return AnyStore(self)
    }

}

extension ViewStoreType {
    
    public func asViewStore() -> AnyViewStore<State, Action> {
        return AnyViewStore(self)
    }
    
}

extension ClientStoreType {
    
    public func asClientStore() -> AnyClientStore<State, Action, Output> {
        return AnyClientStore(self)
    }
    
}
