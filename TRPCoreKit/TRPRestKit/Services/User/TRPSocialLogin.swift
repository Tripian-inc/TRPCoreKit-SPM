//
//  TRPSocialLogin.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 30.08.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPSocialLogin: TRPRestServices<TRPGenericParser<TRPSocialLoginInfoModel>> {
    
    //Test server
    private var socialLoginParameters: [String: Any]
    
    init?(parameters: [String: Any]) {
        if parameters.count == 0 {
            return nil
        }
        for param in parameters {
            if param.key.isEmpty  {
                return nil
            }
        }
        socialLoginParameters = parameters
    }
    
    override public func requestMode() -> TRPRequestMode {
        return TRPRequestMode.post
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.socialLogin.link
    }
    
    public override func bodyParameters() -> [String: Any]? {
        return socialLoginParameters
    }
    override func userOAuth() -> Bool {
        true
    }

}

/// Indicates a informaion of login.
public struct TRPSocialLoginInfoModel: Codable {
    
    /// Type of token
    public var tokenType: String?
    /// Token access key
//    public var accessToken: String?
    public var expiresIn: Int?
    public var refreshToken: String?
    public var idToken: String?
    public var alreadyExists: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case tokenType
//        case accessToken
        case expiresIn
        case refreshToken
        case idToken
        case alreadyExists = "already_exists"
    }
}
