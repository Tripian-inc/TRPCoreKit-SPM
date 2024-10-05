//
//  TRPQuestionRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 30.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public class TRPQuestionRemoteApi: QuestionRemoteApi {
    
    public init() {}
    
    public func fetchQuestions(type: QuestionCategory,
                               language: String,
                               completion: @escaping (QuestionsResultsValue) -> Void) {
        
        var questionType: TRPQuestionCategory = .companion
        
        if type == .profile {
            questionType = .profile
        }else if type == .trip {
            questionType = .trip
        }
        
        TRPRestKit().questions(type: questionType,
                               language: language) { (result, error, paging) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let questions = result as? [TRPQuestionInfoModel] {
                let converted = QuestionMapper().map(questions)
                completion(.success(converted))
            }
        }
    }
    
}
