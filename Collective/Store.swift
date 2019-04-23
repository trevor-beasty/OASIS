//
//  Store.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/23/19.
//

import Foundation

protocol WWStoreDefinition {
    associatedtype State
    associatedtype Action
    associatedtype Output
    
    typealias ActionProducer = (@escaping () -> State, @escaping (Action) -> Void) -> Void
}

class WWStore<Definition: WWStoreDefinition> {
    typealias State = Definition.State
    typealias Action = Definition.Action
    typealias Output = Definition.Output
    typealias ActionProducer = Definition.ActionProducer
    
    public private(set) var state: State
    internal var stateObservers: [(State) -> Void] = []
    internal var outputObservers: [(Output, State) -> Void] = []
    
    internal let qos: DispatchQoS
    private lazy var processingQueue = DispatchQueue(label: "StoreProcessing", qos: qos)
    
    // Public API
    
    public init(initialState: State, qos: DispatchQoS = .userInitiated) {
        self.state = initialState
        self.qos = qos
    }
    
    open class func reduce(action: Action, state: State) -> (State?, Output?) {
        fatalError(abstractMethodMessage)
    }
    
    public func observeState(_ observer: @escaping (State) -> Void) {
        stateObservers.append(observer)
        let currentState = state
        emit {
            observer(currentState)
        }
    }
    
    public func observeOutput(_ observer: @escaping (Output, State) -> Void) {
        outputObservers.append(observer)
    }
    
    public func dispatch(_ actionProducer: ActionProducer) {
        actionProducer({ self.state }) { [weak self] action in
            self?.handleAction(action)
        }
    }
    
    // Private
    
    private func handleAction(_ action: Action) {
        processingQueue.async {
            let (newState, output) = type(of: self).reduce(action: action, state: self.state)
            if let someNewState = newState {
                self.state = someNewState
                emit {
                    self.stateObservers.forEach({ $0(someNewState) })
                }
            }
            if let someOutput = output {
                emit {
                    self.outputObservers.forEach({ $0(someOutput, newState ?? self.state) })
                }
            }
        }
    }
    
}

private func emit(_ execute: @escaping () -> Void) {
    DispatchQueue.main.async(execute: execute)
}

enum WWResult<T> {
    case success(T)
    case failure(Error)
}

enum Lottery: WWStoreDefinition {
    
    struct State {
        var player: Player
        var coins: Int
        var phase: Phase
        
        enum Phase {
            case idle
            case loading
            case error(message: String)
        }
        
    }
    
    enum Action {
        case lotteryResult(WWResult<Bool>)
        case processingLottery
        case bannedMessage
    }
    
    enum Output {
        case didLose
    }
    
    struct Player {
        let id: String
        let name: String
        var isBanned: Bool
    }
    
}

class LotteryStore: WWStore<Lottery> {
    
    override static func reduce(action: Action, state: State) -> (State?, Output?) {
        var copy = state
        switch action {
        case .processingLottery:
            copy.phase = .loading
            return (copy, nil)
            
        case .lotteryResult(let lotteryResult):
            switch lotteryResult {
            case .success(let winner):
                let output: Output?
                if winner {
                    copy.coins *= 2
                    copy.phase = .idle
                    output = nil
                }
                else {
                    copy.coins = 0
                    output = .didLose
                }
                return (copy, output)
            case .failure:
                copy.phase = .error(message: "Please try again later")
                return (copy, nil)
            }
        case .bannedMessage:
            copy.phase = .error(message: "You are banned from playing this game")
            return (copy, nil)
        }
    }
    
}

// didPressPlayLottery
let doubleOrNothing: Lottery.ActionProducer = { state, emitAction in
    guard !state().player.isBanned else {
        emitAction(.bannedMessage)
        return
    }
    emitAction(.processingLottery)
    playLottery(player: state().player) { lotteryResult in
        emitAction(.lotteryResult(lotteryResult))
    }
}

// playLottery service
func playLottery(player: Lottery.Player, completion: @escaping (WWResult<Bool>) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0, execute: {
        let winner = Bool.random()
        completion(.success(winner))
    })
}
