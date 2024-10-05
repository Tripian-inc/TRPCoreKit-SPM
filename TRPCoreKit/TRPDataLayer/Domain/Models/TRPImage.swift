//
//  TRPImage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct TRPImage: Codable {
    
    public let url: String
    public var imageOwner: TRPImageOwner?
    public let width: Int?
    public let height: Int?
    
}
