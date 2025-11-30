//
//  Accommondation.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 26.03.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

public struct Accommondation {
    public var refId: String?
    public var name: String?
    public let address: String?
    public let coordinate: TRPLocation
    
    public init(refId: String? = nil, name: String? = nil, address: String? = nil, coordinate: TRPLocation) {
        self.refId = refId
        self.name = name
        self.address = address
        self.coordinate = coordinate
    }
    
    public func json() -> [String: Any]? {
        var params: [String: Any] = [:]
        
        if let refId = refId {
            params["refID"] = refId
        }
        
        if let name = name {
            params["name"] = name
        }
        
        params["address"] = address
        params["coordinate"] = coordinate.json()
        return params
    }
}
