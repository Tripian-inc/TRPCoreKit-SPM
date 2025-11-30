//
//  TRPUserPersistent.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 27.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
public struct TRPUserPersistent {
    
    private static let userIdCodeTag = "trpuserid"
    private static let userEmailCodeTag = "trpuseremail"

    public static var isLoggedIn: Bool {
        guard let tokens = TripianTokenController().fetchTokenInfo() else {return false}
        if !tokens.idToken.isEmpty && tokens.expiresIn != 0 {
            return true
        }
        return false
    }

    public static var isTokenValid: Bool {
        return TripianTokenController().isTokenValid
    }
    
    public static var tokenInfo: TRPToken? {
        return TripianTokenController().fetchTokenInfo()
    }

    public static func getUserEmail() -> String? {
        return UserDefaults.standard.string(forKey: userEmailCodeTag)
    }
    
    public static func saveUserEmail(_ mail: String) {
        UserDefaults.standard.set(mail, forKey: userEmailCodeTag)
    }
    
    public static var isSocialLogin: Bool {
        return TripianTokenController().isSocialLoggedIn()
    }
    
    public static func saveSocialLogin() {
        TripianTokenController().saveSocialLogin()
    }
    
    public static func remove() {
        UserDefaults.standard.removeObject(forKey: userIdCodeTag)
        UserDefaults.standard.removeObject(forKey: userEmailCodeTag)
        TripianTokenController().clearDataInUserDefaults()
    }
}
