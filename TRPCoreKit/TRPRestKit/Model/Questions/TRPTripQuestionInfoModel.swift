//
//  TRPQuestionInfoJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 23.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// This model provide you to use full information of Question to creating a trip.
public struct TRPQuestionInfoModel: Decodable {
    
    /// An Int value. Unique Id of question.
    public var id: Int
    /// A Bool value. Indicates that the question can be skipped without an answer.
    public var skippable: Bool
    /// A Bool value. A Question can be multiple answer.
    public var selectMultiple: Bool
    /// A String value. Name of question.
    public var name: String
    
    public var stepId: Int?
    public var title: String?
    public var iconUrl: String?
    public var description: String?
    public var theme: String?
    
    public var category: TRPQuestionCategory
    
    public var order: Int
    
    /// A TRPQuestionOptionsJsonModel object. Options of a question.
    public var answers: [TRPQuestionOptionsJsonModel]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case stepId
        case skippable
        case selectMultiple = "selectMultiple"
        case name
        case title
        case iconUrl
        case description
        case theme
        case category
        case order
        case answers
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.stepId = try values.decodeIfPresent(Int.self, forKey: .stepId)
        self.skippable = try values.decode(Bool.self, forKey: .skippable)
        self.selectMultiple = try values.decode(Bool.self, forKey: .selectMultiple)
        self.name = try values.decode(String.self, forKey: .name)
        self.title = try values.decodeIfPresent(String.self, forKey: .title)
        self.iconUrl = try values.decodeIfPresent(String.self, forKey: .iconUrl)
        self.description = try values.decodeIfPresent(String.self, forKey: .description)
        self.theme = try values.decodeIfPresent(String.self, forKey: .theme)
        let questionCategory = try values.decode(String.self, forKey: .category)
        self.category = TRPQuestionCategory(rawValue: questionCategory) ?? .trip
        self.order = try values.decode(Int.self, forKey: .order)
        self.answers = try values.decodeIfPresent([TRPQuestionOptionsJsonModel].self, forKey: .answers)
    }
    
}
