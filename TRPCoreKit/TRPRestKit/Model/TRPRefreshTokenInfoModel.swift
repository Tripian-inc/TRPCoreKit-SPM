//
//  TRPRefreshTokenInfoModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 28.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public struct TRPRefreshTokenInfoModel: Decodable {
       
     /// Type of token
     public var tokenType: String?
     /// Token access key
//     public var accessToken: String?
    public var idToken: String
     
     public var expiresIn: Int
     
     private enum CodingKeys: String, CodingKey {
         case tokenType
//         case accessToken
         case expiresIn
         case idToken
     }
     
     /// Initializes a new object with decoder
     ///
     /// - Parameter decoder: Json decoder
     public init(from decoder: Decoder) throws {
         let values = try decoder.container(keyedBy: CodingKeys.self)
         self.tokenType = try values.decodeIfPresent(String.self, forKey: .tokenType)
//         self.accessToken = try values.decode(String.self, forKey: .accessToken)
         self.expiresIn = try values.decode(Int.self, forKey: .expiresIn)
         self.idToken = try values.decode(String.self, forKey: .idToken)
     }
    
}
