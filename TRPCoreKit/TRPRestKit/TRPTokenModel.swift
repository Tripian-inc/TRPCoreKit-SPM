//
//  TRPTokenModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 4.06.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public struct TRPToken: Codable {
    
//    public var accessToken: String?
    public var idToken: String
    
    public var expiresIn: Int
    
    public var refreshToken: String?
    
    public init(login: TRPLoginInfoModel) {
//        accessToken = login.accessToken
        expiresIn = login.expiresIn
        refreshToken = login.refreshToken
        idToken = login.idToken
    }
    
    public init(refresh: TRPRefreshTokenInfoModel) {
//        accessToken = refresh.accessToken
        expiresIn = refresh.expiresIn
        idToken = refresh.idToken
        refreshToken = nil
    }
    
    public init(idToken: String, accessToken: String, expiresIn: Int, refreshToken: String?) {
        self.idToken = idToken
//        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
    }
}
