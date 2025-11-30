//
//  TRPRefreshTokenService.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 27.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPRefreshTokenService: TRPRestServices<TRPGenericParser<TRPRefreshTokenInfoModel>> {
    
    private var refreshToken: String
    private var device: TRPDevice?
    
    init(refreshToken: String, device: TRPDevice? = nil) {
        self.refreshToken = refreshToken
        self.device = device
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.refresh.link
    }
    
    override func requestMode() -> TRPRequestMode {
        return .post
    }
    override func userOAuth() -> Bool {
        return true
    }
    override func bodyParameters() -> [String: Any]? {
        var params = [String: Any]()
        params["refreshToken"] = refreshToken
    
        params["timezone"] = TimeZone.current.identifier
        if let device = device, let deviceParameters = device.params() {
            params["device"] = deviceParameters
        }
        return params
    }
    
    override var isRefresh: Bool {
        return true
    }
}
