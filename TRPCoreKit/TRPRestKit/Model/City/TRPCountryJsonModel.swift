//
//  TRPCountryJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 21.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
/// This model provide you to use full information of Country
public struct TRPCountryJsonModel: Decodable {
    
    /// Code of Country such as us
    public var code: String
    /// Name of Country such as USA
    public var name: String
    /// Continient of County
    public var continent: String?
    public var continentModel: TRPContinentJsonModel?
    
    private enum CodingKeys: String, CodingKey {
        case code
        case name
        case continent
    }
    
    private enum ContinientKeys: String, CodingKey {
        case name
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try values.decode(String.self, forKey: .code)
        self.name = try values.decode(String.self, forKey: .name)
        //For continient
        let continientContainer = try values.nestedContainer(keyedBy: ContinientKeys.self, forKey: .continent)
        self.continent = try continientContainer.decodeIfPresent(String.self, forKey: .name)
        
        if let continent = try? values.decodeIfPresent(TRPContinentJsonModel.self, forKey: .continent) {
            self.continentModel = continent
        }
    }
    
}

public struct TRPContinentJsonModel: Decodable {
    
    public var name: String?
    public var slug: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case slug
    }
}
