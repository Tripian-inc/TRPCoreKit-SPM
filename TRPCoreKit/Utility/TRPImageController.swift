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
    
    public func getImage(inFramework: String?, inApp: String?, withTintColor: Bool = false) -> UIImage? {
        var image: UIImage?
        if let inApp = inApp, let inAppImage = UIImage(named: inApp, in: Bundle.main, compatibleWith: nil) {
            image = inAppImage
        }
        
        if let inFramework = inFramework, image == nil {
            image = UIImage(named: inFramework, in: Bundle.module, compatibleWith: nil)
        }
        
        if withTintColor {
            return image?.withRenderingMode(.alwaysTemplate)
        }
        return image
    }
    
}
