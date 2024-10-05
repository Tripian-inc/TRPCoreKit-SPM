//
//  TRPImageController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 11.01.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation

class TRPImageController {
    
    public func getImage(inFramework: String?, inApp: String?) -> UIImage? {
        if let image = inApp {
            return UIImage(named: image, in: Bundle.main, compatibleWith: nil)
        }
        if let image = inFramework {
            return UIImage(named: image, in: Bundle.init(for: type(of: self)), compatibleWith: nil)
        }
        return nil
    }
    
}
