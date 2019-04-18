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

open class ChangeStore<Definition: ChangeStoreDefinition>: Module<Definition.Action, Definition.Output>, _StoreType {
    public typealias State = Definition.State
    public typealias Change = Definition.Change
    public typealias Action = Definition.Action
    public typealias Output = Definition.Output
    
    private let stateVariable: Variable<State>
    private let outputSubject = PublishSubject<Output>()
    
    private let qos: DispatchQoS
    // Linear queue which ensures sequential change processing. It is important the one change finishes processing (creating new state) before the next begins processing.
    private lazy var changeQueue = DispatchQueue(label: "ChangeQueue", qos: qos)
    
    public init(initialState: State, qos: DispatchQoS = .userInitiated) {
        self.stateVariable = Variable<State>(initialState)
        self.qos = qos
        super.init()
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
    
    open class func reduce(change: Change, state: State) -> State { fatalError(abstractMethodMessage) }
    
    // TODO: Should be making sure this occurs on specified qos - could send a change following a network request, which could dictate a different qos.
    // Need to check that adjacent, synchronous changes produce the expected result - expect first change to be fully processed before next change begins.
    
    // Dispatched changes must block the current thread (via 'sync'). This is b/c we must guarantee that the dispatched change updates the store state before the store attempts to
    // access that state. Without this, a client that dispatches a change and then immediately reads the state will not see the change reflected in that state. It is safe
    // to block the executing thread b/c we know that we are not on the main thread. Blocking via 'sync' is only delaying the data processing control flow thread. We know we are
    // on some background thread (as defined by qos property) b/c all actions are immediately dispatched to this queue.
    public func dispatchChange(_ change: Change) {
        changeQueue.sync {
            let newState = type(of: self).reduce(change: change, state: self.stateVariable.value)
            self.stateVariable.value = newState
        }
    }
    
    public func dispatchBatchChanges(_ changes: [Change]) {
        changeQueue.sync {
            let newState = changes.reduce(self.stateVariable.value) { (lastState, nextChange) -> State in
                return type(of: self).reduce(change: nextChange, state: lastState)
            }
            self.stateVariable.value = newState
        }
    }
    
    internal var stateObservable: Observable<State> { return stateVariable.asObservable() }
    
    public var getState: () -> State {
        
        return { [stateVariable] in
            return stateVariable.value
        }
        
    }
    
}
