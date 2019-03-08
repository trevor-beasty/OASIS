//
//  ControlFlow+UIKit.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/8/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit

public protocol ScreenProcess: Process where Entity: ScreenEntity, LaunchReturn == Void { }

public protocol RootScreenProcess: Process where LaunchReturn == UIViewController { }

public protocol ScreenEntity: StatefulEntity {
    var rootScreenContext: ScreenContext { get }
}

public enum ScreenContext {
    case modal(UIViewController)
    case navigationController(UINavigationController)
}
