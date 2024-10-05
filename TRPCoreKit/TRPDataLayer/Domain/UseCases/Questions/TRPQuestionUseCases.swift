//
//  TRPQuestionUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public class TRPQuestionsUseCases {
    
    private(set) var repository: QuestionsRepository
    
    public init(repository: QuestionsRepository = TRPQuestionsRepository()) {
        self.repository = repository
    }
    
    
    /// Repository içinde soruların var olup olmadığını kontrol eder
    /// - Parameter category: Soru tipi
    /// - Returns: Bool
    private func contaionInRepository(category: QuestionCategory) -> Bool {
        return repository.questions.contains(where: { (key, questions) -> Bool in
                    if key == category && !questions.isEmpty {
                        return true
                    }
                    return false
                })
    }
    
    
    
    /// Category e göre cevapları getirir.
    ///  Eger cevaplar daha önce getirildiyse onları döndürür.
    /// - Parameters:
    ///   - category: Soru tipi
    ///   - completion:
    private func questionController(category: QuestionCategory,
                                    completion: @escaping ((Result<[TRPQuestion], Error>) -> Void)) {
        
        if contaionInRepository(category: category) {
            let questions = repository.questions[category] ?? []
            completion(.success(questions))
            return
        }
        
        repository.fetchQuestions(type: category) { result in
            switch(result) {
            case .success(let questions):
                self.repository.questions[category] = questions
                completion(.success(questions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension TRPQuestionsUseCases: FetchTripQuestionsUseCase {
    
    public func executeTripQuestions(completion: ((Result<[TRPQuestion], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        let category: QuestionCategory = .trip
        questionController(category: category, completion: onComplete)
    }
    
}

extension TRPQuestionsUseCases: FetchProfileQuestionsUseCase {
    
    public func executeProfileQuestions(completion: ((Result<[TRPQuestion], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        let category: QuestionCategory = .profile
        questionController(category: category, completion: onComplete)
    }
    
}

extension TRPQuestionsUseCases: FetchCompanionQuestionsUseCase {
 
    public func executeCompanionQuestions(completion: ((Result<[TRPQuestion], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        let category: QuestionCategory = .companion
        questionController(category: category, completion: onComplete)
    }
    
}
