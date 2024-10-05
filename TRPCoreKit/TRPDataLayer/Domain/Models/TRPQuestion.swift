//
//  TRPQuestion.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 30.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public enum QuestionCategory {
    case trip
    case profile
    case companion
}

public struct TRPQuestionAnswer {
    public var id: Int
    public var name: String
    public var subAnswers: [TRPQuestionAnswer]?
    public var description: String?
}

public struct TRPQuestion {
    public var id: Int
    public var stepId: Int?
    public var skippable: Bool
    public var selectMultiple: Bool
    public var name: String
    public var title: String?
    public var iconUrl: String?
    public var description: String?
    public var theme: String?
    public var category: QuestionCategory
    public var order: Int
    public var answers: [TRPQuestionAnswer]?
}
