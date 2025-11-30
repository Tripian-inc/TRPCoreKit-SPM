//
//  TRPUserMeInfoModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// This model provide you to use information of user.
public struct TRPUserInfoModel: Decodable {
    
    public var username: String
    
    public var id: Int?
    /// A String value. Email of the user.
    public var email: String
    /// A String value. First name of the user.
    public var firstName: String?
    //public var age:String?
    /// A String value. Last name of the user.
    public var lastName: String?
    
    public var dateOfBirth: String?
    
    public var answers: [Int]?
   
    /// A array of TRPUserPreferencesInfoModel objects.
//    public var profile: TRPUserProfileInfoModel?
    
    private enum CodingKeys: String, CodingKey {
        case userName = "username"
        case id
        case email
//        case profile
        case firstName
        case lastName
        case dateOfBirth
        case answers
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: .id)
        
        if let email = try values.decodeIfPresent(String.self, forKey: .email) {
            username = ""
            self.email = email
        }else if let uName = try values.decodeIfPresent(String.self, forKey: .userName){
            username = uName 
            self.email = ""
        }else {
            username = ""
            self.email = ""
        }
        
        self.firstName = try values.decodeIfPresent(String.self, forKey: .firstName)
        self.lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
        self.dateOfBirth = try values.decodeIfPresent(String.self, forKey: .dateOfBirth)
        self.answers = try values.decodeIfPresent([Int].self, forKey: .answers)
//        self.profile = try values.decodeIfPresent(TRPUserProfileInfoModel.self, forKey: .profile)
    }
    
}

/// This model provide you to use information of user.
public struct TRPRegisterUserInfo: Decodable {
    /// A String value. Name of user.
    public var userName: String
    /// A array of TRPUserPreferencesInfoModel objects.
    public var profile: TRPUserProfileInfoModel?
    
    private enum CodingKeys: String, CodingKey {
        case userName = "username"
        case info
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.userName = try values.decode(String.self, forKey: .userName)
        self.profile = try values.decodeIfPresent(TRPUserProfileInfoModel.self, forKey: .info)
    }
    
}

