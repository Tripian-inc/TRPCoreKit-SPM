//
//  TRPLoginHelper.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.08.2025.
//

import TRPRestKit
import UIKit

class TRPLoginHelper {
    public static var shared: TRPLoginHelper = TRPLoginHelper()
    
    private let guestFirstName: String = "Guest"
    private let guestLastName: String = "User"
    private let tripianFirstName: String = "Tripian"
    private let tripianLastName: String = "User"
    private lazy var guestEmail: String = {
        "\(getUUID())@tripianguest.com"
    }()
    private let guestPsw = "Tripian1234"
    
    func login() {
        
    }
    
    func guestLogin(completion: @escaping ((Bool) -> Void)) {
        
        TRPRestKit().guestLogin(firstName: guestFirstName, lastName: guestLastName, email: guestEmail, password: guestPsw) { (_, error) in
            if let error = error as? TRPErrors {
                EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
                completion(false)
                return
            }
            completion(true)
        }
    }

    func lightLogin(uniqueId: String, firstName: String? = nil, lastName: String? = nil, completion: @escaping ((Bool) -> Void)) {

        TRPRestKit().lightLogin(uniqueId: uniqueId, firstName: firstName, lastName: lastName) { (_, error) in
            if let error = error as? TRPErrors {
                EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func login(email: String,
               password: String? = nil,
               completion: @escaping ((Bool) -> Void)) {
        var psw = guestPsw
        if let password {
            psw = password
        }
        
        TRPRestKit().login(withEmail: email, password: psw) { [weak self] (result, error) in
            if error is TRPErrors {
                self?.register(email: email, completion: completion)
                return
            }
            completion(true)
        }
    }
    
    private func register(email: String,
                          password: String? = nil,
                          name: String? = nil,
                          lastName: String? = nil,
                          completion: @escaping ((Bool) -> Void)) {
        var psw = guestPsw
        var firstName = ""
        var surname = ""
        if let password {
            psw = password
        }
        if let name {
            firstName = name
        }
        if let lastName {
            surname = lastName
        }
        TRPRestKit().register(email: email, password: psw, firstName: firstName, lastName: surname) { (result, error) in
            if let error = error as? TRPErrors {
                EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
                completion(false)
            }
            completion(true)
        }
    }
    
    private func getUUID() -> String {
        var uuid = ""
        if let uuidString = UIDevice.current.identifierForVendor?.uuidString {
            uuid = uuidString
        } else {
            uuid = UUID().uuidString
        }
        return uuid
    }
}
