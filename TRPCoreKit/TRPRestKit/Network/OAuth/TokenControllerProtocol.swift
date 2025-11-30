//
//  TokenControllerProtocol.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 28.04.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
protocol TokenControllerProtocol {
    
    var isTokenValid: Bool {get}
    var loginTokenTag: String {get}
    var tokenExpiredTime: String {get}
    
    func saveTokenInfo(_ value: TRPToken)
    func fetchTokenInfo() -> TRPToken?
    
    func saveTokenTime(expiresIn: Int)
    func fetchTokenExpiredTime() -> Int?
    
}
