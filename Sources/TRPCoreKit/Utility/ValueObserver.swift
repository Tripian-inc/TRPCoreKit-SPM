//
//  ValueObserver.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 5.09.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
public class ValueObserver<T> {
    
    public typealias ObserverBlock = (T) -> Void
    public var observers : [UInt: ObserverBlock] = [:]
    
    public var value: T? {
        didSet {
            if value != nil {
                notifyAll(value!)
            }
        }
    }
    
    public init(_ value : T?) {
        self.value = value;
    }
    
    public func addObserver(_ object: AnyObject,  observer: @escaping ObserverBlock)  {
        let objectId = objectUniqueId(obj: object)
        observers[objectId] = observer
        if value != nil {
            observer(value!);
        }
    }
    
    public func notifyAll(_ change: T) {
        for observer in observers.values {
            observer(change)
        }
    }
    
    public func removeObservers() {
        observers.removeAll()
    }
    
    public func removeObserver(_ object: AnyObject) {
        let objectId = objectUniqueId(obj: object)
        observers.removeValue(forKey: objectId)
    }
    
    func objectUniqueId(obj: AnyObject) -> UInt {
        return UInt(bitPattern: ObjectIdentifier(obj))
    }
}
