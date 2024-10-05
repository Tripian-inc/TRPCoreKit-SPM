//
//  UserDefaults+extensions.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 21.04.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
extension UserDefaults {
    
    /// Codable objeyi kaydetmeye yarar
    /// - Parameters:
    ///   - model: Codable Json Obje
    ///   - key: key
    func save<T: Codable>(_ model: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(model)
            set(data, forKey: key)
        }catch {
            print("[Error] \(error.localizedDescription)")
        }
    }
    
    /// Kaydedilen codable objeyi geri dönüştürür
    /// - Parameters:
    ///   - type: Decodable Obje
    ///   - key: Key
    func load<T>(type: T.Type, forKey key: String) -> T? where T: Decodable {
        guard let encoded = data(forKey: key) else {return nil}
        do {
            return try JSONDecoder().decode(type, from: encoded)
        }catch {
            print("[Error] \(error.localizedDescription)")
        }
        return nil
    }
    
}
