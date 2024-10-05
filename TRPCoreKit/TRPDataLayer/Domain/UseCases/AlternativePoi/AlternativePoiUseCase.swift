//
//  AlternativePoiUseCase.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 18.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchStepAlternative {
    
    func executeFetchStepAlternative(stepId: Int,
                                     completion: ((Result<[TRPPoi], Error>) -> Void)?
                                    )
}


public protocol FetchPlanAlternative {
    
    func executeFetchPlanAlternative(completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)? )
    
}

public protocol FetchAlternativeWithCategory {
    
    func executeFetchAlternativeWithCategory(categories: [Int], completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)? )
}

