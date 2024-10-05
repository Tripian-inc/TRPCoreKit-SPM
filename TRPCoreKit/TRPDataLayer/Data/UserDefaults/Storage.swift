//
//  Storage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
@propertyWrapper
struct Storage<T> {
    
    let key: String
    let defaultValue: T
    
    private let userDefault = UserDefaults.standard
    
    var wrappedValue: T {
        get {
            return userDefault.object(forKey: key) as? T ?? defaultValue
        }
        
        set {
            userDefault.set(newValue, forKey: key)
        }
    }
    
    
    
    init(key: String, value: T) {
        self.key = key
        self.defaultValue = value
    }
    
}
