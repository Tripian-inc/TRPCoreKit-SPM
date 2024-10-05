//
//  TRPGuestLogin.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 21.08.2024.
//  Copyright © 2024 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPGuestLogin: TRPRestServices<TRPLoginJsonModel>  {
    private var email: String
    private var password: String
    private var firstName: String
    private var lastName: String
    
    private var device: TRPDevice?
    
    public init(email: String,
                password: String,
                firstName: String,
                lastName: String,
                device: TRPDevice? = nil) {
        self.password = password
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.device = device
    }
    
    
    public override func servicesResult(data: Data?, error: NSError?) {
        if let error = error {
            self.completion?(nil, error, nil)
            return
        }
        guard let data = data else {
            self.completion?(nil, TRPErrors.wrongData as NSError, nil)
            return
        }
        
        let jsonDecode = JSONDecoder()
        do {
//            if password != nil && email != nil {
//                let result = try jsonDecode.decode(TRPLoginJsonModel.self, from: data)
//                let pag = paginationController(parentJson: result)
//                self.completion?(result, nil, pag)
//            } else if userName != nil {
//                let result = try jsonDecode.decode(TRPTestUserInfoJsonModel.self, from: data)
//                let pag = paginationController(parentJson: result)
//                self.completion?(result, nil, pag)
//            }
            let result = try jsonDecode.decode(TRPLoginJsonModel.self, from: data)
            let pag = paginationController(parentJson: result)
            self.completion?(result, nil, pag)
        } catch let tryError {
            self.completion?(nil, tryError as NSError, nil)
        }
    }
    
    public override func bodyParameters() -> [String: Any]? {
//        if let email = email,
//            let password = password {
            
            var parameters: [String: Any] = [:]
            parameters["email"] = email
            parameters["password"] = password
            parameters["firstName"] = firstName
            parameters["lastName"] = lastName
            
            
            if let device = device, let deviceParams = device.params() {
                parameters["device"] = deviceParams
            }
            return parameters
//        }
//        if let userName = userName {
//            return ["username": userName]
//        }
        
//        return [:]
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    public override func requestMode() -> TRPRequestMode {
        return TRPRequestMode.post
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.guestLogin.link
    }
}
