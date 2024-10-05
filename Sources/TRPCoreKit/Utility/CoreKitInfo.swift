//
//  GetKitVersion.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 26.08.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
public class CoreKitInfo: NSObject {
    
    public override init() {}
    
    public func version()  -> String? {
        return Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
}
