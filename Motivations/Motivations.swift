//
//  Motivations.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/19/19.
//

import Foundation

protocol Motivation {
    static var priority: MotivationPriority { get }
    static var axiom: String { get }
    static var explanation: String { get }
}

enum MotivationPriority {
    case veryHigh
    case high
    case normal
    case low
}

enum MinimalExhaustiveState: Motivation {
    
    static var priority: MotivationPriority { return .veryHigh }
    
    static var axiom: String {
        return """
        The State of any Store should include the minimal set of properties such that any required artifacts can be implied from that state.
        """
    }
    
    static var explanation: String {
        return """
        State should not hold redundant / derived state. This is where ViewState becomes very important. It should be possible to derive all required
        artifacts demanded by ViewState from State. ViewState is a tremendous tool because it provides an arena for us to test that we have satisfied
        the minimal exhaustive state requirement - if we can't derive something we need, we must rework our State definition.
        
        Further, State should not hold duplicitous representations. It should not be possible for our state to become 'out of sync' because we failed to
        update two things at the same time.
        """
    }
    
}
