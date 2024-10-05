//
//  RestKitInfo.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 26.08.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation

public class RestKitInfo: NSObject {
    
    public override init() {}
    
    public func version() -> String? {
        return Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
}
