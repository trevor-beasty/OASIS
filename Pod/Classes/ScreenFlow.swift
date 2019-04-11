//
//  ScreenFlow.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/16/19.
//

import Foundation
import RxSwift

public enum None { }

open class ScreenFlow<Output>: Module<None, Output> {
    
    open func start(in context: ScreenFlowContext) {
        fatalError(abstractMethodMessage)
    }
    
}
