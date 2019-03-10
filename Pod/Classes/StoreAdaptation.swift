//
//  StoreAdaptation.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/7/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

internal class ViewStoreAdapter<Store: _StoreType, View: ViewType>: _ViewStoreType {
    typealias State = View.ViewState
    typealias Action = View.ViewAction
    
    let stateObservable: Observable<View.ViewState>
    let getState: () -> View.ViewState
    private let viewActionSubject = PublishSubject<View.ViewAction>()
    let bag: DisposeBag
    
    var actionObserver: AnyObserver<View.ViewAction> { return viewActionSubject.asObserver() }
    
    init(_ store: Store, viewType: View.Type, stateMap: @escaping (Store.State) -> View.ViewState, actionMap: @escaping (View.ViewAction) -> Store.Action) {
        
        self.stateObservable = store.stateObservable
            .map({ return stateMap($0) })
        
        self.getState = {
            return stateMap(store.getState())
        }
        
        self.bag = store.bag
        
        viewActionSubject
            .asObservable()
            .map({ return actionMap($0) })
            .subscribe(onNext: {
                store.actionObserver.onNext($0)
            })
            .disposed(by: store.bag)
        
    }
    
}
