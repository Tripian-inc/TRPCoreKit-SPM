//
//  PlanUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchPlanUseCase {
    
    func executeFetchPlan(id: Int, completion: ((Result<TRPPlan, Error>) -> Void)?)
}

public protocol ChangeDailyPlanUseCase {
    
    func executeChangeDailyPlan(id: Int, completion: ((Result<TRPPlan, Error>) -> Void)?)
}

public protocol EditPlanHoursUseCase {
    
    func executeEditPlanHours(startTime: String, endTime: String, completion: ((Result<TRPPlan, Error>) -> Void)?)
    
}

public protocol ExportItineraryUseCase {
    func executeFetchExportItinerary(tripHash: String, completion: ((Result<TRPExportItinerary, Error>)-> Void)?)
}
