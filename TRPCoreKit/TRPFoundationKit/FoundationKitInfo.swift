//
//  FoundationKitInfo.swift
//  TRPFoundationKit
//
//  Created by Evren Yaşar on 26.08.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
public class FoundationKitInfo: NSObject {
    
    public override init() {}
    
    public func version()  -> String? {
        return Bundle.module.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
}
