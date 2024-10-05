//
//  TRPUserProfileInfoModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 27.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
/// Indicate preferences of user with Key/Value.
public struct TRPUserProfileInfoModel: Decodable {
    public var age: Int?
    public var answers: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case age
        case answers
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.age = try values.decodeIfPresent(Int.self, forKey: .age)
        self.answers = try values.decodeIfPresent([Int].self, forKey: .answers) ?? []
    }
    
}
