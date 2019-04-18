////
////  ReducerStore.swift
////  OASIS
////
////  Created by Trevor Beasty on 4/18/19.
////
//
//import Foundation
//import RxSwift
//
//public class Agent<Input, Action>: Module<Input, Action> { }
//
//public class ReducerStore<State, Action, Output, Agent>: Module<Action, Output> {
//    
//    open class func reduce(action: Action, state: State) -> State? {
//        fatalError(abstractMethodMessage)
//    }
//    
//    public init(initialState: State, agent: Agent<> qos: DispatchQoS = .userInitiated) {
//        self.stateVariable = Variable<State>(initialState)
//        self.qos = qos
//        super.init()
//        setUp()
//    }
//    
//}
