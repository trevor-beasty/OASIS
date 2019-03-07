//
//  ChangeStore.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/7/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

protocol ChangeStoreDefinition: StoreDefinition {
    associatedtype Change
}

open class ChangeStore<State, Change, Action, Output>: StoreType {
    
    private let stateVariable: Variable<State>
    private let actionSubject = PublishSubject<Action>()
    private let outputSubject = PublishSubject<Output>()
    
    private let bag = DisposeBag()
    
    public init(initialState: State) {
        self.stateVariable = Variable<State>(initialState)
        setUp()
    }
    
    private func setUp() {
        
    }
    
    open func handleAction(_ action: Action) {
        fatalError()
    }
    
    open func reduce(change: Change, state: State) -> State {
        fatalError()
    }
    
    public func observeState(_ stateObserver: @escaping (State) -> Void) {
        stateVariable.asObservable()
            .subscribe(onNext: {
                stateObserver($0)
            })
            .disposed(by: bag)
    }
    
    public func dispatchAction(_ action: Action) {
        actionSubject.onNext(action)
    }
    
    public func observeOutput(_ outputObserver: @escaping (Output) -> Void) {
        outputSubject.asObservable()
            .subscribe(onNext: {
                outputObserver($0)
            })
            .disposed(by: bag)
    }
    
}
