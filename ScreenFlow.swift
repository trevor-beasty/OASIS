//
//  ScreenFlow.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/16/19.
//

import Foundation
import RxSwift

open class ScreenFlow<Output>: _OutputObservableType {
    
    private let outputSubject = PublishSubject<Output>()
    
    internal let bag = DisposeBag()
    
    public init() { }
    
    open func start() {
        fatalError(abstractMethodMessage)
    }
    
    var outputObservable: Observable<Output> { return outputSubject.asObservable() }
    
    public func dispatchOutput(_ output: Output) {
        outputSubject.onNext(output)
    }
    
}
