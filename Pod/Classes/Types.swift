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

// TODO: Allow testing clients to pass in initialState in initializer.

// TODO: Empty state analog? (state when fresh prior to network request)

// TODO: Apply operators to individual Action cases (ex. filter out rapid button taps)

// TODO: Animations?

// TODO: Efficient updates (ex. inserting element into table)

// TODO: Give current state to output observer so they don't need to reference the store separately.

// TODO: Require mapping of ViewAction to Action to always return a value; Stores must ignore unneeded actions. Helps avoid gross mapping functions / duplicity.

// TODO: Module container for transitioning screens into a flow pattern.

// TODO: GET RID OF VIEWACTION -
// 1) It should be tested that stores respond to significant actions.. no need to avoid 'default' case
// 2) mapping of ViewAction's into Action's is gross and adds no value, causes duplication in some cases
// ... but actually View is not reusable without this.. what is this sense of reusability and do we need it?

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

public protocol StoreType: ViewStoreType, OutputObservableType {
    func asStore() -> AnyStore<State, Action, Output>
    func adaptTo<View: ViewType>(_ viewType: View.Type, stateMap: @escaping (State) -> View.ViewState, actionMap: @escaping (View.ViewAction) -> Action?) -> AnyViewStore<View.ViewState, View.ViewAction>
}

internal protocol _StoreType: StoreType, _ViewStoreType, _OutputObservableType  { }

public protocol ViewStoreType: StateObservableType, StateStoreType, ActionObserverType {
    func asViewStore() -> AnyViewStore<State, Action>
}

internal protocol _ViewStoreType: ViewStoreType, _StateObservableType, _ActionObserverType { }

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

extension _StoreType {
    
    public func adaptTo<View: ViewType>(_ viewType: View.Type, stateMap: @escaping (State) -> View.ViewState, actionMap: @escaping (View.ViewAction) -> Action?) -> AnyViewStore<View.ViewState, View.ViewAction> {
        return ViewStoreAdapter(self, viewType: viewType, stateMap: stateMap, actionMap: actionMap)
            .asViewStore()
    }
    
}

extension StoreType {
    
    public func adaptTo<View: ViewType>(_ viewType: View.Type, stateMap: @escaping (State) -> View.ViewState) -> AnyViewStore<View.ViewState, View.ViewAction> where View.ViewAction == Action {
        return adaptTo(viewType, stateMap: stateMap, actionMap: { viewAction in return viewAction })
    }
    
    public func adaptTo<View: ViewType>(_ viewType: View.Type, actionMap: @escaping (View.ViewAction) -> Action?) -> AnyViewStore<View.ViewState, View.ViewAction> where View.ViewState == State {
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
