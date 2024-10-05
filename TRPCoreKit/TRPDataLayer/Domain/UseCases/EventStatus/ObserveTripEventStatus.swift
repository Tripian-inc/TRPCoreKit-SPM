//
//  ObserveTripEventStatus.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 3.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public enum EventType {
    case addStep, deleteStep, fetchPlan, editStep, fetchTrip, changeTime, reorderStep
}

public typealias LoaderResult = (showLoader: Bool, type: EventType)?

public typealias ErrorResult = (error: Error, type: EventType)?

public protocol ObserveTripEventStatusUseCase {
    
    var successfullyUpdated: ValueObserver<EventType> {get set}
    
    var showLoader: ValueObserver<LoaderResult> { get set}
    
    var error: ValueObserver<ErrorResult> { get set}
    
}
