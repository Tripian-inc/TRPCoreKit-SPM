//
//  TRPLoginJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 11.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Indicates a informaion of login.
public struct TRPLoginInfoModel: Codable {
    
    /// Type of token
    public var tokenType: String?
    /// Token access key
//    public var accessToken: String?
    public var expiresIn: Int
    public var refreshToken: String
    public var idToken: String
    
    private enum CodingKeys: String, CodingKey {
        case tokenType
//        case accessToken
        case expiresIn
        case refreshToken
        case idToken 
    }
    
    /*/// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.tokenType = try values.decodeIfPresent(String.self, forKey: .tokenType)
        self.accessToken = try values.decode(String.self, forKey: .accessToken)
        self.expiresIn = try values.decode(Int.self, forKey: .expiresIn)
        self.refresthToken = try values.decode(String.self, forKey: .refreshToken)
    }
    
    public func encode(to encoder: Encoder) throws {
        
    }*/
}
