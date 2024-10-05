//
//  TRPImageOwner.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 17.04.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation

/// Indicates information of person who photographed.
public struct TRPImageOwnerModel: Decodable {
    /// A String value. The name of person who photographed.
    public var title: String?
    /// A String value. Url of a image
    public var url: String?
    
    public var avatar: String?
    
}
