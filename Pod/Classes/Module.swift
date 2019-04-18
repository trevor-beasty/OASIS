//
//  Module.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/11/19.
//

import Foundation
import RxSwift

open class Module<Action, Output>: _OutputObservableType, _ActionObserverType {
    
    internal let actionSubject = PublishSubject<Action>()
    private let outputSubject = PublishSubject<Output>()
    
    internal let bag = DisposeBag()
    
    public init() { }
    
    internal var actionObserver: AnyObserver<Action> { return actionSubject.asObserver() }
    
    internal var outputObservable: Observable<Output> { return outputSubject.asObservable() }
    
    public func dispatchOutput(_ output: Output) {
        outputSubject.onNext(output)
    }
    
    open func handleAction(_ action: Action) { fatalError(abstractMethodMessage) }
    
}
