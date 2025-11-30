//
//  TRPUserMeJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
/// Parent Json parser model for UserInfo
internal class TRPUserInfoJsonModel: TRPParentJsonModel {
    
    /// User data
    public var data: TRPUserInfoModel
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try values.decode(TRPUserInfoModel.self, forKey: .data)
        try super.init(from: decoder)
    }
}

internal class TRPTestUserInfoJsonModel: TRPParentJsonModel {
    
    /// User data
    public var data: TRPRegisterUserInfo
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try values.decode(TRPRegisterUserInfo.self, forKey: .data)
        try super.init(from: decoder)
    }
}
