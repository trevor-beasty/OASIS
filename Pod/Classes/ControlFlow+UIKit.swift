//
//  ControlFlow+UIKit.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/8/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit

public protocol WindowEntity: StatefulEntity {
    var window: UIWindow { get }
}

public protocol ScreenEntity: StatefulEntity {
    var rootScreenContext: ScreenContext { get }
}

public enum ScreenContext {
    case modal(UIViewController)
    case navigationController(UINavigationController)
}
