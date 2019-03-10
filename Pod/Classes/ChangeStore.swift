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

open class ChangeStore<Definition: ChangeStoreDefinition>: StoreType {
    public typealias State = Definition.State
    public typealias Change = Definition.Change
    public typealias Action = Definition.Action
    public typealias Output = Definition.Output
    
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
    
    internal var stateObservable: Observable<State> { return stateVariable.asObservable() }
    
    internal var state: () -> State {
        
        return { [stateVariable] in
            return stateVariable.value
        }
        
    }
    
    internal var actionObserver: AnyObserver<Action> { return actionSubject.asObserver() }
    internal var outputObservable: Observable<Output> { return outputSubject.asObservable() }
    
}
