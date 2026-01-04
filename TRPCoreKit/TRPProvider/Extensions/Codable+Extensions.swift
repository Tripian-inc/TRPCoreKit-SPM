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
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self.value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            self.value = dictionaryValue.mapValues { $0.value }
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
        } else if let arrayValue = value as? [Any] {
            try container.encode(arrayValue.map { AnyCodable($0) })
        } else if let dictionaryValue = value as? [String: Any] {
            let encodableDictionary = dictionaryValue.mapValues { AnyCodable($0) }
            try container.encode(encodableDictionary)
        } else {
            try container.encodeNil()
        }
    }
}

extension Encodable {
    /// Converts a Codable object to a JSON dictionary
    /// - Returns: A dictionary representation of the object, or nil if encoding fails
    func convertToJSONObject() -> [String: Any]? {
        do {
            // Encode the object into JSON Data.
            let jsonData = try JSONEncoder().encode(self)
            
            // Convert the JSON Data into a JSON object (dictionary).
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            // Cast the JSON object as a [String: Any] dictionary.
            return jsonObject as? [String: Any]
        } catch {
            print("Error converting object to JSON: \(error)")
            return nil
        }
    }
}

