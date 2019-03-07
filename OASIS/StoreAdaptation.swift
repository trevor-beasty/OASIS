//
//  StoreAdaptation.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/7/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

internal class ViewStoreAdapter<Store: StoreType, View: ViewType>: ViewStoreType {
    
    let state: Observable<View.ViewState>
    let getState: () -> View.ViewState
    private let viewActionSubject = PublishSubject<View.ViewAction>()
    let bag: DisposeBag
    
    var action: AnyObserver<View.ViewAction> { return viewActionSubject.asObserver() }
    
    init(_ store: Store, viewType: View.Type, stateMap: @escaping (Store.State) -> View.ViewState, actionMap: @escaping (View.ViewAction) -> Store.Action) {
        
        self.state = store.state
            .asObservable()
            .map({ return stateMap($0) })
        
        self.getState = {
            return stateMap(store.getState())
        }
        
        self.bag = store.bag
        
        viewActionSubject
            .asObservable()
            .map({ return actionMap($0) })
            .subscribe(onNext: {
                store.action.onNext($0)
            })
            .disposed(by: store.bag)
        
    }
    
}

extension StoreType {
    
    public func adaptTo<View: ViewType>(_ viewType: View.Type, stateMap: @escaping (State) -> View.ViewState, actionMap: @escaping (View.ViewAction) -> Action) -> AnyViewStore<View.ViewState, View.ViewAction> {
        return ViewStoreAdapter(self, viewType: viewType, stateMap: stateMap, actionMap: actionMap)
            .asViewStore()
    }
    
    public func adaptTo<View: ViewType>(_ viewType: View.Type, stateMap: @escaping (State) -> View.ViewState) -> AnyViewStore<View.ViewState, View.ViewAction> where View.ViewAction == Action {
        return adaptTo(viewType, stateMap: stateMap, actionMap: { viewAction in return viewAction })
    }

    public func adaptTo<View: ViewType>(_ viewType: View.Type, actionMap: @escaping (View.ViewAction) -> Action) -> AnyViewStore<View.ViewState, View.ViewAction> where View.ViewState == State {
        return adaptTo(viewType, stateMap: { state in return state }, actionMap: actionMap)
    }
    
}
