//
//  Enviremoment.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 16.12.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
public enum Environment {
    case dev, test, production
    
    public var baseUrl: BaseUrlCreater {
        
        switch self {
        case .dev:
            return BaseUrlCreater(baseUrl: "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com", basePath: "dev")
        case .test:
            return BaseUrlCreater(baseUrl: "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com", basePath: "test")
        case .production:
            return BaseUrlCreater(baseUrl: "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com", basePath: "prod")
        }
    }
    
}
