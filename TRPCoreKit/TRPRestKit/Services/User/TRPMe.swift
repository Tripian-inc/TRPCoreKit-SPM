//
//  TRPMe.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPUserInfoServices: TRPRestServices<TRPUserInfoJsonModel> {
    
    enum ServiceType {
        case getInfo, updateInfo, updateAnswer
    }
    
    let serviceType: ServiceType
    var answers: [Int]?
    var firstName: String?
    var lastName: String?
    var password: String?
    var dateOfBirth: String?
    
    init(type: ServiceType) {
        self.serviceType = type
    }
    
    init(answers: [Int]) {
        self.serviceType = .updateAnswer
        self.answers = answers
    }
    
    init(firstName: String? = nil, lastName: String? = nil, dateOfBirth: String? = nil, password: String? = nil, answers: [Int]? = nil) {
        self.serviceType = .updateInfo
        self.answers = answers
        self.firstName = firstName
        self.lastName = lastName
        self.password = password
        self.dateOfBirth = dateOfBirth
    }
    
    public override func bodyParameters() -> [String: Any]? {
        if serviceType == .getInfo {return nil}
        
        var params: [String: Any] = [:]
        if serviceType == .updateAnswer {
            if let answers = answers {
                params["answers"] = answers
            }
        } else if serviceType == .updateInfo {
            if let firstName = firstName {
                params["firstName"] = firstName
            }
            if let lastName = lastName {
                params["lastName"] = lastName
            }
            if let dateOfBirth = dateOfBirth, !dateOfBirth.isEmpty {
                params["dateOfBirth"] = dateOfBirth
            }
            if let answers = answers {
                params["answers"] = answers
            }
            
            if let password = password {
                params["password"] = password
            }
        }
        return params
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.user.link
    }
    
    public override func requestMode() -> TRPRequestMode {
        if serviceType == .updateAnswer || serviceType == .updateInfo {
            return TRPRequestMode.put
        }
        return TRPRequestMode.get
    }
}
