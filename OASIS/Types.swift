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
    
    var state: Observable<State> { get }
    var bag: DisposeBag { get }
}

internal protocol StateStoreType: AnyObject {
    associatedtype State
    
    var getState: () -> State { get }
}

internal protocol ActionObserverType: AnyObject {
    associatedtype Action
    
    var action: AnyObserver<Action> { get }
}

internal protocol OutputObservableType: AnyObject {
    associatedtype Output
    
    var output: Observable<Output> { get }
    var bag: DisposeBag { get }
}

extension StateObservableType {
    
    public func observeState(_ observer: @escaping (State) -> Void) {
        state
            .asObservable()
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

extension ActionObserverType {
    
    public func dispatchAction(_ action: Action) {
        self.action.onNext(action)
    }
    
}

extension OutputObservableType {
    
    public func observeOutput(_ observer: @escaping (Output) -> Void) {
        output
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                observer($0)
            })
            .disposed(by: bag)
    }
    
}

public class AnyStore<State, Action, Output>: StoreType {

    let state: Observable<State>
    let getState: () -> State
    let action: AnyObserver<Action>
    let output: Observable<Output>
    let bag: DisposeBag
    
    internal init<Store: StoreType>(_ store: Store) where Store.State == State, Store.Action == Action, Store.Output == Output {
        self.state = store.state
        self.getState = store.getState
        self.action = store.action
        self.output = store.output
        self.bag = store.bag
    }
    
}

public class AnyViewStore<State, Action>: ViewStoreType {
    
    let state: Observable<State>
    let getState: () -> State
    let action: AnyObserver<Action>
    let bag: DisposeBag
    
    internal init<Store: ViewStoreType>(_ store: Store) where Store.State == State, Store.Action == Action {
        self.state = store.state
        self.getState = store.getState
        self.action = store.action
        self.bag = store.bag
    }
    
}

public class AnyClientStore<State, Action, Output>: ClientStoreType {
    
    let getState: () -> State
    let action: AnyObserver<Action>
    let output: Observable<Output>
    let bag: DisposeBag
    
    internal init<Store: ClientStoreType>(_ store: Store) where Store.State == State, Store.Action == Action, Store.Output == Output {
        self.getState = store.getState
        self.action = store.action
        self.output = store.output
        self.bag = store.bag
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
