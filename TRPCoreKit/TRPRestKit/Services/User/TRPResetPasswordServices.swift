//
//  TRPResetPasswordServices.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 5.09.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPResetPasswordServices : TRPRestServices<TRPParentJsonModel> {
    
    private enum RequestType {
        case sendEmail
        case resetPassword
        
        func getRequestMode() -> TRPRequestMode {
            switch self {
            case .sendEmail:
                return TRPRequestMode.post
            case .resetPassword:
                return TRPRequestMode.put
            
            }
        }
    }
    
    private var requestType: RequestType = .sendEmail
    private var email: String?
    private var password: String?
    private var hash: String?
    
    init(email: String) {
        self.requestType = .sendEmail
        self.email = email
    }
    
    init(password: String, hash: String) {
        self.requestType = .resetPassword
        self.password = password
        self.hash = hash
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.resetPassword.link
    }
    
    
    override public func requestMode() -> TRPRequestMode {
        return requestType.getRequestMode()
}
    
    public override func bodyParameters() -> [String: Any]? {
        var params = [String: Any]()
        if requestType == .sendEmail {
            params["email"] = email
        } else {
            params["password"] = password
            params["hash"] = hash
        }
        return params
    }

}
