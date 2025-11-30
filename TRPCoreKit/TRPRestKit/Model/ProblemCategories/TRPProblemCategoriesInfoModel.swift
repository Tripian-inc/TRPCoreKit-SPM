//
//  TRPProblemCategoriesInfoModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 26.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
/// Indicates categories that used to report a error
public struct TRPProblemCategoriesInfoModel: Decodable {
    
    /// An Int valuee. Id of category
    public var id: Int
    /// A String value. Name of category
    public var name: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: TRPProblemCategoriesInfoModel.CodingKeys.id)
        self.name = try values.decode(String.self, forKey: TRPProblemCategoriesInfoModel.CodingKeys.name)
    }
    
}
