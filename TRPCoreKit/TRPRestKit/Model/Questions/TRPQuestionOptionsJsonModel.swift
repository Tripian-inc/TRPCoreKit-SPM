//
//  TRPQuestionOptionsJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 23.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Options of a Question.
public struct TRPQuestionOptionsJsonModel: Decodable {
    
    /// An Int value. Unique Id of option.
    public var id: Int
    /// A String value. Name of option.
    public var name: String
    
    public var subAnswers: [TRPQuestionOptionsJsonModel]?
    public var description: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case subAnswers
        case description
    }
    
}
