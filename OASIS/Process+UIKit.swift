//
//  Process+UIKit.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/8/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit
import RxSwift

public class Flow<Entity: ScreenEntity, LaunchArg, Output>: Process<Entity, LaunchArg, Void, Output>  { }

public class RootFlow<Entity: StatefulEntity, LaunchArg, Output>: Process<Entity, LaunchArg, UIViewController, Output>  { }

public class WindowCoordinator<Entity: WindowEntity, LaunchArg, Output>: Process<Entity, LaunchArg, Void, Output>  { }
