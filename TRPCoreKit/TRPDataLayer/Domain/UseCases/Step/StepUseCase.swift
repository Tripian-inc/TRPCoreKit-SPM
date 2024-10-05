//
//  StepUseCase.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol AddStepUseCase {
        
    
    /// CurrentDay e yeni bir step(poi) ekler.
    /// - Parameters:
    ///   - poiId: Place Id
    ///   - completion:
    func executeAddStep(poiId: String, completion: ((Result<TRPStep, Error>) -> Void)?)
}

public protocol DeleteStepUseCase {
        
    func executeDeleteStep(id: Int, completion: ((Result<Bool, Error>) -> Void)?)
    
    func executeDeletePoi(id: String, completion: ((Result<Bool, Error>) -> Void)?)
}

public protocol EditStepUseCase {
    
    func execureEditStep(id: Int, poiId: String, completion: ((Result<TRPStep, Error>) -> Void)?)
}

public protocol ReOrderStepUseCase {
    
    func execureReOrderStep(id: Int, order: Int, completion: ((Result<TRPStep, Error>) -> Void)?)
    
}

