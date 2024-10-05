//
//  QuestionUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 30.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchTripQuestionsUseCase {
    
    func executeTripQuestions(completion: ((Result<[TRPQuestion], Error>) -> Void)? )    
}


public protocol FetchProfileQuestionsUseCase {
    
    func executeProfileQuestions(completion: ((Result<[TRPQuestion], Error>) -> Void)? )
}

public protocol FetchCompanionQuestionsUseCase {
    
    func executeCompanionQuestions(completion: ((Result<[TRPQuestion], Error>) -> Void)? )
}
