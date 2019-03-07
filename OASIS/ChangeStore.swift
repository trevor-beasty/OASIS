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
    
    internal let bag = DisposeBag()
    
    public init(initialState: State) {
        self.stateVariable = Variable<State>(initialState)
        setUp()
    }
    
    private func setUp() {
        
        changeSubject.asObservable()
            .map({
                return type(of: self).reduce(change: $0, state: self.stateVariable.value)
            })
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
    
    internal var state: Observable<State> { return stateVariable.asObservable() }
    internal var getState: () -> State { return { return self.stateVariable.value } }
    internal var action: AnyObserver<Action> { return actionSubject.asObserver() }
    internal var output: Observable<Output> { return outputSubject.asObservable() }
    
}
