//
//  ReducerStore.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/18/19.
//

import Foundation
import RxSwift

// Ultimately, I think this approach is not desirable.
// 1 - In networking calls, you lose the context of a completion handler. That completion handler is now essentially
// a 'unidirectional flow'. It's possible results are just discrete actions. This loss of context does not read well.
// 2 - All this would really do for us is provide an easy way to mock 'agents'. B/c agents now partake in the action stream,
// we could simulate their behavior by sending actions into the store. We would also be able to check that correct inputs are being sent
// to the agent OR associate reactions with inputs (if this input, then send this action, etc).
// 3 - We would now need to to map all service calls and other artifacts into actions. This would need to be tested.
// 4 - It may be better to just provide a better way (from a testing standpoint) to inject services into a store.

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
    
    public func update(_ newState: State) {
        self.stateVariable.value = newState
    }
    
}
