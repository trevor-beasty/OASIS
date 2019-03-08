//
//  Flow.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/8/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import UIKit
import RxSwift

public class Flow<Entity: ScreenEntity, LaunchArg, Output>: ScreenProcess {
    
    public let entity: Entity
    private let outputSubject = PublishSubject<Output>()
    private let bag = DisposeBag()
    
    public required init(entity: Entity) {
        self.entity = entity
    }
    
    open func start(_ launchArg: LaunchArg) -> () {
        fatalError(abstractMethodMessage)
    }
    
    public func observeOutput(_ observer: @escaping (Output) -> Void) {
        outputSubject
            .asObservable()
            .subscribe(onNext: {
                observer($0)
            })
            .disposed(by: bag)
    }
    
    public func dispatchOutput(_ output: Output) {
        outputSubject.onNext(output)
    }
    
}
