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

open class ChangeStore<Definition: ChangeStoreDefinition>: _StoreType {
    public typealias State = Definition.State
    public typealias Change = Definition.Change
    public typealias Action = Definition.Action
    public typealias Output = Definition.Output
    
    private let stateVariable: Variable<State>
    private let actionSubject = PublishSubject<Action>()
    private let outputSubject = PublishSubject<Output>()
    
    internal let bag = DisposeBag()
    
    private let qos: DispatchQoS
    
    public init(initialState: State, qos: DispatchQoS = .userInitiated) {
        self.stateVariable = Variable<State>(initialState)
        self.qos = qos
        setUp()
    }
    
    private func setUp() {
        
        actionSubject.asObservable()
            .observeOn(SerialDispatchQueueScheduler(qos: qos))
            .subscribe(onNext: {
                self.handleAction($0)
            })
            .disposed(by: bag)
        
    }
    
    open func handleAction(_ action: Action) { fatalError(abstractMethodMessage) }
    
    open class func reduce(change: Change, state: State) -> State { fatalError(abstractMethodMessage) }
    
    public func dispatchChange(_ change: Change) {
        let newState = type(of: self).reduce(change: change, state: stateVariable.value)
        stateVariable.value = newState
    }
    
    public func dispatchBatchChanges(_ changes: [Change]) {
        let newState = changes.reduce(stateVariable.value) { (lastState, nextChange) -> State in
            return type(of: self).reduce(change: nextChange, state: lastState)
        }
        stateVariable.value = newState
    }
    
    public func dispatchOutput(_ output: Output) {
        outputSubject.onNext(output)
    }
    
    internal var stateObservable: Observable<State> { return stateVariable.asObservable() }
    
    public var getState: () -> State {
        
        return { [stateVariable] in
            return stateVariable.value
        }
        
    }
    
    internal var actionObserver: AnyObserver<Action> { return actionSubject.asObserver() }
    internal var outputObservable: Observable<Output> { return outputSubject.asObservable() }
    
}
