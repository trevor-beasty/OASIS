//
//  ScreenFlowContext.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/17/19.
//

import UIKit

public enum ScreenFlowContext {
    case modal(UIViewController)
    case navigationController(UINavigationController)
}

extension ScreenFlowContext {
    
    public func startModalStyle(with viewController: UIViewController) {
        let base: UIViewController
        switch self {
        case .modal(let baseViewController):
            base = baseViewController
        case .navigationController(let baseNavigationController):
            base = baseNavigationController
        }
        base.present(viewController, animated: true, completion: nil)
    }
    
    public func startNavigationControllerStyle(with viewController: UIViewController) -> UINavigationController {
        let navigationController: UINavigationController
        switch self {
        case .modal(let baseViewController):
            let newNavigationController = UINavigationController(rootViewController: viewController)
            baseViewController.present(newNavigationController, animated: true, completion: nil)
            navigationController = newNavigationController
            
        case .navigationController(let baseNavigationController):
            baseNavigationController.pushViewController(viewController, animated: true)
            navigationController = baseNavigationController
        }
        return navigationController
    }
    
}
