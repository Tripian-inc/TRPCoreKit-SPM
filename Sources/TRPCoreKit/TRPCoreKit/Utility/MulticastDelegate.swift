//
//  MulticastDelegate.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 17.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

// See also: - https://medium.com/@ivan_m/multicast-on-swift-3-and-mvvm-c-ff74ce802bcc
import Foundation
public class MulticastDelegate<T> {
    private var delegates = [Weak]()
    
    public func add(_ delegate: T) {
        delegates.append(Weak(value: delegate as AnyObject))
    }
    
    public func remove(_ delegate: T) {
        let weak = Weak(value: delegate as AnyObject)
        if let index = delegates.firstIndex(of: weak) {
            delegates.remove(at: index)
        }
    }
    
    public func invoke(_ invocation: @escaping (T) -> ()) {
        delegates = delegates.filter({$0.value != nil})
        delegates.forEach({
            if let delegate = $0.value as? T {
                invocation(delegate)
            }
        })
    }
    
    
}

public class Weak: Equatable {
    public weak var value: AnyObject?
    
    public init(value: AnyObject) {
        self.value = value
    }
    
    static public func ==(lhs: Weak, rhs: Weak) -> Bool {
        return lhs.value === rhs.value
    }
}
