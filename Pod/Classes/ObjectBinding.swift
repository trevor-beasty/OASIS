//
//  ObjectBinding.swift
//  OASIS
//
//  Created by Trevor Beasty on 3/17/19.
//

import Foundation

// Reference management handled by ResourceBindingManager allows clients to tie together the lives of disparate objects.
// An object will live as long as any of the objects to which it is 'bound'.
internal final class BindingManager {
    
    static let shared = BindingManager()
    
    private var retained: [(bound: AnyObject, binders: [WeakBox<AnyObject>])] = []
    
    private init() { }
    
    func handleDeallocatin(of binder: Binder) {
        binder.bound
            .compactMap({ $0.boxed })
            .forEach({ handleDeallocatin(for: $0) })
    }
    
    private func handleDeallocatin(for bound: AnyObject) {
        guard let existingBoundIndex = retained.firstIndex(where: { $0.bound === bound }) else { return }
        var copy = retained[existingBoundIndex]
        copy.binders.removeAll(where: { $0.boxed == nil })
        if copy.binders.isEmpty {
            retained.remove(at: existingBoundIndex)
        }
        else {
            retained[existingBoundIndex] = copy
        }
    }
    
    func handleBind(binder: AnyObject, bound: AnyObject) {
        let _binder = WeakBox<AnyObject>(binder)
        if let existingBoundIndex = retained.firstIndex(where: { $0.bound === bound }) {
            var copy = retained[existingBoundIndex]
            copy.binders.append(_binder)
            retained[existingBoundIndex] = copy
        }
        else {
            let new = (bound, [_binder])
            retained.append(new)
        }
    }
}

public protocol Bindable: AnyObject {
    var binder: Binder { get }
}

public final class Binder {
    
    private(set) var bound: [WeakBox<AnyObject>] = []
    
    public init() { }
    
    deinit {
        BindingManager.shared.handleDeallocatin(of: self)
    }
    
    internal func bind(_ toBound: AnyObject) {
        let _toBound = WeakBox<AnyObject>(toBound)
        bound.append(_toBound)
        BindingManager.shared.handleBind(binder: self, bound: toBound)
    }
    
}

internal final class WeakBox<T: AnyObject> {
    
    weak var boxed: T?
    
    init(_ boxed: T) {
        self.boxed = boxed
    }
    
}

extension Bindable {
    
    public func bind(_ toBound: AnyObject) {
        binder.bind(toBound)
    }
    
}
