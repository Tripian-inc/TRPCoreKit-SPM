//
//  TRPImageModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public class TRPImageModel: NSObject, Decodable {
    
    /// An Int value. Unique id of a city.
    public var url: String?
    public var imageOwner: TRPImageOwnerModel?
    public var width: Int?
    public var height: Int?
    
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case url
        case imageOwner
        case width
        case height
    }
    
}
