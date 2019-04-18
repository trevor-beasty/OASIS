//
//  ReducerStore.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/18/19.
//

import Foundation
import RxSwift

public class Agent<Input, Action>: Module<Input, Action> { }

public class ReducerStore<State, Action, Output, AgentInput>: Module<Action, Output>, _StoreType {

    private let stateVariable: Variable<State>
    
    private let qos: DispatchQoS
    
    public let agent: Agent<AgentInput, Action>
    
    public init(initialState: State, agent: Agent<AgentInput, Action>, qos: DispatchQoS) {
        self.stateVariable = Variable<State>(initialState)
        self.qos = qos
        self.agent = agent
        super.init()
        setUp()
    }
    
    private func setUp() {
        
        Observable.merge(actionSubject.asObservable(), agent.outputObservable)
            .observeOn(SerialDispatchQueueScheduler(qos: qos))
            .subscribe(onNext: {
                if let newState = type(of: self).reduce(action: $0, state: self.stateVariable.value) {
                    self.stateVariable.value = newState
                }
            })
            .disposed(by: bag)
        
    }
    
    open class func reduce(action: Action, state: State) -> State? {
        fatalError(abstractMethodMessage)
    }
    
    internal var stateObservable: Observable<State> { return stateVariable.asObservable() }
    
    public var getState: () -> State {
        
        return { [stateVariable] in
            return stateVariable.value
        }
        
    }
    
}
