//
//  QuestionsRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 30.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


public typealias QuestionsResultsValue = (Result<[TRPQuestion], Error>)


public protocol QuestionsRepository {
    
    var questions: [QuestionCategory: [TRPQuestion]] {get set}
    
    func fetchQuestions(type: QuestionCategory,
                        completion: @escaping (QuestionsResultsValue) -> Void)
}
