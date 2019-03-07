//
//  ChangeStore.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/7/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

internal let abstractMethodMessage = "abstract method must be overriden by subclass"

public protocol ChangeStoreDefinition: StoreDefinition {
    associatedtype Change
}

open class ChangeStore<State, Change, Action, Output>: StoreType {
    
    private let stateVariable: Variable<State>
    private let changeSubject = PublishSubject<Change>()
    private let actionSubject = PublishSubject<Action>()
    private let outputSubject = PublishSubject<Output>()
    
    private let bag = DisposeBag()
    
    public init(initialState: State) {
        self.stateVariable = Variable<State>(initialState)
        setUp()
    }
    
    private func setUp() {
        
        changeSubject.asObservable()
            .map({
                return type(of: self).reduce(change: $0, state: self.stateVariable.value)
            })
        // TODO: 'Push' sequence onto stateVariable? (Is it possible?) May need to change stateVariable Type.
            .subscribe(onNext: {
                self.stateVariable.value = $0
            })
            .disposed(by: bag)
        
        actionSubject.asObservable()
            .observeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: {
                self.handleAction($0)
            })
            .disposed(by: bag)
        
    }
    
    open func handleAction(_ action: Action) { fatalError(abstractMethodMessage) }
    
    open class func reduce(change: Change, state: State) -> State { fatalError(abstractMethodMessage) }
    
    public func dispatchChange(_ change: Change) {
        changeSubject.onNext(change)
    }
    
    public func dispatchOutput(_ output: Output) {
        outputSubject.onNext(output)
    }
    
    public func observeState(_ stateObserver: @escaping (State) -> Void) {
        stateVariable.asObservable()
            .observeOn(MainScheduler.instance)
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
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                outputObserver($0)
            })
            .disposed(by: bag)
    }
    
}
