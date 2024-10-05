//
//  UIKitInfo.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 26.08.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
public class UIKitInfo: NSObject {
    
    public override init() {}
    
    public func version()  -> String? {
        return Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
}
