//
//  TRPImageController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 11.01.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class TRPImageController {
    
    public func getImage(inFramework: String?, inApp: String?) -> UIImage? {
        if let inApp = inApp, let image = UIImage(named: inApp, in: Bundle.main, compatibleWith: nil) {
            return image
        }
        if let image = inFramework {
            return UIImage(named: image, in: Bundle.module, compatibleWith: nil)
        }
        return nil
    }
    
}
