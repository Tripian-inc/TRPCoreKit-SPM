//
//  TRPTaste.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPTaste: Codable {
    
    public var id: Int
    public var name: String
    public var description: String?
    public var image: TRPImage?
    
}
