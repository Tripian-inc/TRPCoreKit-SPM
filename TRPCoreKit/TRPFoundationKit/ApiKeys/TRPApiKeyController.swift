//
//  TRPApiKeyController.swift
//  TRPFoundationKit
//
//  Created by APPLE on 4.11.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
public class TRPApiKeyController {
    
    /// Detect missing api key in info.Plist    *
    /// - Parameter frameworks: frameworks list
    public static func checkMissingApiKeys(_ frameworks: [TRPApiKeys], bundle: Bundle = Bundle.main) -> [TRPApiKeys] {
        var missingKey = [TRPApiKeys]()
        for framework in frameworks {
            let key:String? = getKey(framework, bundle: bundle)
            if key == nil  {
                missingKey.append(framework)
            }else {
                if key!.count < 3 {
                    missingKey.append(framework)
                }
            }
        }
        return missingKey
    }
    
    public static func getKey(_ framework: TRPApiKeys, bundle: Bundle = Bundle.main) -> String? {
        guard let path = bundle.path(forResource: "Info", ofType: "plist") else {
            print("[Error] : Path nil")
            return nil
        }
        
        guard let dict = NSDictionary(contentsOfFile: path) else {
            print("[Error] : NSDictionary nil")
            return nil
        }
        return dict[framework.rawValue] as? String
    }
}
