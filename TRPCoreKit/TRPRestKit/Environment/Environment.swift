//
//  Enviremoment.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 16.12.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
public enum Environment {
    case test, sandbox, production
    
    public var baseUrl: BaseUrlCreater {
        
        switch self {
        case .test:
            return BaseUrlCreater(baseUrl: "mrzxnta2wl.execute-api.us-east-1.amazonaws.com", basePath: "v2")
        case .sandbox:
            return BaseUrlCreater(baseUrl: "uqo7xnd7f9.execute-api.eu-west-1.amazonaws.com", basePath: "v2")
        case .production:
            return BaseUrlCreater(baseUrl: "ybesi12ydk.execute-api.us-east-1.amazonaws.com", basePath: "v02")
        }
    }
    
}
