//
//  Codable+Extensions.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 25.08.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

    
// Helper to handle 'Any' type for Codable
struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self.value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            self.value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            self.value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
        } else {
            self.value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if let value = value as? Int {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}

