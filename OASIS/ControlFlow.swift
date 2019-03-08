//
//  ControlFlow.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/8/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

public protocol Process: AnyObject {
    associatedtype Entity: StatefulEntity
    associatedtype LaunchArg
    associatedtype LaunchReturn
    associatedtype Output
    
    init(entity: Entity)
    func start(_ launchArg: LaunchArg) -> LaunchReturn
    func observeOutput(_ observer: @escaping (Output) -> Void)
}

public protocol StatefulEntity: AnyObject { }
