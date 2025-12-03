//
//  PlanMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class TimelinePlanMapper {
    
    func map(_ restModel: TRPTimelinePlansInfoModel, profileSegment: TRPTimelineSegment? = nil) -> TRPTimelinePlan {
        
        let steps = addHomeBaseIfExist(restModel, profileSegment: profileSegment)
        var city: TRPCity?
        if let cityModel = restModel.city {
            city = CityMapper().map(cityModel)
        }
        
        return TRPTimelinePlan(id: restModel.id,
                               startDate: restModel.startDate,
                               endDate: restModel.endDate,
                               steps: steps,
                               available: restModel.available,
                               tripType: restModel.tripType,
                               name: restModel.name,
                               description: restModel.description,
                               generatedStatus: restModel.generatedStatus,
                               children: restModel.children,
                               pets: restModel.pets,
                               adults: restModel.adults,
                               city: city,
                               accommodation: profileSegment?.accommodation,
                               destinationAccommodation: profileSegment?.destinationAccommodation)
    }
    
    func map(_ restModels: [TRPTimelinePlansInfoModel], profileSegments: [TRPTimelineSegment?]? = nil) -> [TRPTimelinePlan] {
        var index = 0
        var plans: [TRPTimelinePlan] = []
        restModels.forEach { plan in
            let profileSegment = profileSegments?[index]
            plans.append(map(plan, profileSegment: profileSegment))
            index += 1
        }
        return plans
    }
    /// Accommondation varsa onu PLANIN ilk basamağına ekler
    /// - Parameter dailyPlan: DailyPlan
    /// - Returns: Accommondation eklenmiş plan
    private func addHomeBaseIfExist(_ restModel: TRPTimelinePlansInfoModel, profileSegment: TRPTimelineSegment?) -> [TRPTimelineStep] {
        var steps = TimelineStepMapper().map(restModel.steps)
        
        guard let city = restModel.city, let accommodation = profileSegment?.accommodation else { return steps}
        
        let stayAddress = getStepFromAccommodation(accommodation, cityId: city.id)
        if let firstStep = steps.first, firstStep.poi?.id != accommodation.referanceId {
            steps.insert(stayAddress, at: 0)
        }
        
        guard let destinationAccommodation = profileSegment?.destinationAccommodation else { return steps}
        
        let destinationAddress = getStepFromAccommodation(destinationAccommodation, cityId: city.id)
        if let lastStep = steps.last, lastStep.poi?.id != destinationAccommodation.referanceId {
            steps.append(destinationAddress)
        }
        
        return steps
    }
    
    private func getStepFromAccommodation(_ accommodation: TRPAccommodation, cityId: Int) -> TRPTimelineStep {
        
        let hotel = PoiMapper().accommodation(accommodation, cityId: cityId)
        let hotelStep = TRPTimelineStep(id: 1, poi: hotel, stepType: "hotel", alternatives: [])
        return hotelStep
    }
    
}
