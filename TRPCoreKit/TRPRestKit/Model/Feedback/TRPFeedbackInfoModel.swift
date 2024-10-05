//
//  TRPFeedbackInfoModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 26.04.2023.
//  Copyright © 2023 Evren Yaşar. All rights reserved.
//

import Foundation

/// This model provides you information of Favorites Poi.
public struct TRPFeedbackInfoModel: Decodable {
    
    public var mainSubjects: [TRPFeedbackItemInfoModel]?
    public var poiSubjects: [TRPFeedbackItemInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case poiSubjects
        case mainSubjects
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.mainSubjects = try values.decodeIfPresent([TRPFeedbackItemInfoModel].self, forKey: .mainSubjects)
        self.poiSubjects = try values.decodeIfPresent([TRPFeedbackItemInfoModel].self, forKey: .poiSubjects)
    }
}

/// This model provides you information of Favorites Poi.
public struct TRPFeedbackItemInfoModel: Decodable {
    
    public var id: Int
    
    public var title: String
    
    public var subjectType: String
    
    private enum CodingKeys: String, CodingKey {
        case title = "title"
        case subjectType = "subjectType"
        case id
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try values.decode(String.self, forKey: .title)
        self.subjectType = try values.decode(String.self, forKey: .subjectType)
        self.id = try values.decode(Int.self, forKey: .id)
    }
}
