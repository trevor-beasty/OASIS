//
//  Types.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/7/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

// TODO: Amongst views, a top level view which owns a store should be distinguished from lower-level component view which are really just utilities.
// While these lower-level store should be store agnostic, it would be nice to provide a type definition / api the demonstrates the cascading of
// top-level ViewState to lower level component views. This would probably just involve discretizing the render(:) function and the notion of ViewState.
// Lower-level views may not necessarily participate explicity (via the type system) in Action propogation.

// TODO: Convenience for mapping relationships between StoreType and ViewType. Could then provide utilities for creating views relative to a store, providing
// a slimmer API than adaptTo() currently provides.

// TODO: Flow as a transitive container. For the stores it owns, flow maps Outputs to Actions across stores. For signals for which it is not responsible, it merely
// propogates those signals as its own Output, in an analogous fashion to Stores. This is a universal modularity concept - define what you are responsible for
// and leave all other handling up to some unknown client.

// TODO: The Output concept should be semantically defined as a Module. A module executes some private behavior internally, and propogates outwards all signals unrelated
// to that behavior. (re-purpose OutputObservableType)

// TODO: It may be uncalled for to model flow outside of a screen context - I have mostly screen context right now. That said, I can define a ScreenFlow concept.
// This would be a Module that is provided with some stateful artifact such that it can create side effects in the navigation hierarchy.

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

// TODO: Rename to something like StateRepresentableType.
// TODO: Give new and old state for efficient rendering / animation purposes.
public protocol ViewType: AnyObject {
    associatedtype Definition: ViewDefinition

    typealias ViewState = Definition.ViewState
    typealias ViewAction = Definition.ViewAction

    typealias Store = AnyViewStore<ViewState, ViewAction>

    func render(_ viewState: ViewState)
}

public protocol StoreType: ViewStoreType, ClientStoreType {
    func asStore() -> AnyStore<State, Action, Output>
    func adaptTo<View: ViewType>(_ viewType: View.Type, stateMap: @escaping (State) -> View.ViewState, actionMap: @escaping (View.ViewAction) -> Action) -> AnyViewStore<View.ViewState, View.ViewAction>
}

internal protocol _StoreType: StoreType, _ViewStoreType, _ClientStoreType  { }

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

extension _StoreType {
    
    public func adaptTo<View: ViewType>(_ viewType: View.Type, stateMap: @escaping (State) -> View.ViewState, actionMap: @escaping (View.ViewAction) -> Action) -> AnyViewStore<View.ViewState, View.ViewAction> {
        return ViewStoreAdapter(self, viewType: viewType, stateMap: stateMap, actionMap: actionMap)
            .asViewStore()
    }
    
}

extension StoreType {
    
    public func adaptTo<View: ViewType>(_ viewType: View.Type, stateMap: @escaping (State) -> View.ViewState) -> AnyViewStore<View.ViewState, View.ViewAction> where View.ViewAction == Action {
        return adaptTo(viewType, stateMap: stateMap, actionMap: { viewAction in return viewAction })
    }
    
    public func adaptTo<View: ViewType>(_ viewType: View.Type, actionMap: @escaping (View.ViewAction) -> Action) -> AnyViewStore<View.ViewState, View.ViewAction> where View.ViewState == State {
        return adaptTo(viewType, stateMap: { state in return state }, actionMap: actionMap)
    }
    
}

extension ViewType {
    
    public func bind(to store: Store) {
        store.observeState({ [weak self] viewState in
            self?.render(viewState)
        })
    }
    
}
