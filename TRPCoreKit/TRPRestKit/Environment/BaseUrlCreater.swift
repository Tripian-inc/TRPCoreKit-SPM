//
//  BaseUrlProtocol.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 16.12.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
public struct BaseUrlCreater {
    public var baseUrl: String
    public var basePath: String
    
    public init(baseUrl: String, basePath: String) {
        self.baseUrl = baseUrl
        self.basePath = basePath
    }
    
    public var reableUrl: String {
        return "https://\(self.baseUrl)/\(self.basePath)"
    }
}
