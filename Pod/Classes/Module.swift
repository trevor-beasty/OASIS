//
//  Module.swift
//  OASIS
//
//  Created by Trevor Beasty on 4/11/19.
//

import Foundation
import RxSwift

open class Module<Action, Output>: _OutputObservableType {
    
    private let outputSubject = PublishSubject<Output>()
    
    internal let bag = DisposeBag()
    
    public init() { }
    
    var outputObservable: Observable<Output> { return outputSubject.asObservable() }
    
    public func dispatchOutput(_ output: Output) {
        outputSubject.onNext(output)
    }
    
    open func handleAction(_ action: Action) { fatalError(abstractMethodMessage) }
    
}
