//
//  TRPTastesModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 26.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public struct TRPTastesInfoModel: Decodable {
    public var id: Int
    public var name: String
    public var description: String?
    public var image: TRPImageModel?
}
