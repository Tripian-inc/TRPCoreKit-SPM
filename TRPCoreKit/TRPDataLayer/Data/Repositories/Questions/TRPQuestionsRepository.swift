//
//  TRPQuestionsRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 30.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPQuestionsRepository: QuestionsRepository {
    
    public var questions: [QuestionCategory : [TRPQuestion]] = [:]
    private var remoteApi: QuestionRemoteApi
    private var localStorage: QuestionLocalStorage
    
    public init(remoteApi: QuestionRemoteApi = TRPQuestionRemoteApi(),
         localStorage: QuestionLocalStorage = TRPQuestionLocalStorage()) {
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    
    public func fetchQuestions(type: QuestionCategory, completion: @escaping (QuestionsResultsValue) -> Void) {
        
        remoteApi.fetchQuestions(type: type) { (result) in
            switch(result){
            case .success(let questions):
                completion(.success(questions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}
