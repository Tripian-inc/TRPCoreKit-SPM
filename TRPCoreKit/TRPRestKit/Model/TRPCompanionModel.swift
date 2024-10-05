//
//  TRPCompanionModel.swift
//  TRPRestKit
//
//  Created by Rozeri Dağtekin on 6/26/19.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

/// Companion model
import Foundation

/// This model provide you to use information of user.
public struct TRPCompanionModel: Decodable {
    /// A Int value. Id of the companion.
    public var id: Int
    /// A String value. Name of the companion.
    public var name: String
    /// A String value. Last name of the companion.
    public var answers: [Int]
    /// A String value. Age of the companion.
    public var age: Int?
    public var title: String?
    public var trips: [String]?

    private enum CodingKeys: String, CodingKey {case id, name, answers, age, title, trips}
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.answers = try values.decode([Int].self, forKey: .answers)
        self.age = try values.decodeIfPresent(Int.self, forKey: .age)
        self.title = try values.decodeIfPresent(String.self, forKey: .title)
        self.trips = try values.decodeIfPresent([String].self, forKey: .trips)
    }
    
}
