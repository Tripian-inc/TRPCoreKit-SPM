//
//  TimelineSegmentMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 17.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import TRPRestKit

final class TimelineSegmentMapper {
    
    /// Maps a TRPTimelineSegmentModel to TRPTimelineSegmentProfile
    /// - Parameter restModel: The source TRPTimelineSegmentModel
    /// - Returns: A mapped TRPTimelineSegmentProfile
    func map(_ restModel: TRPTimelineSegmentModel) -> TRPTimelineSegment {
        let profile = TRPTimelineSegment()
        profile.available = restModel.available
        profile.title = restModel.title
        profile.description = restModel.description
        profile.startDate = restModel.startDate
        profile.endDate = restModel.endDate
        profile.coordinate = restModel.coordinate
        profile.destinationCoordinate = restModel.destinationCoordinate
        profile.adults = restModel.adults
        profile.children = restModel.children
        profile.pets = restModel.pets
//        profile.cityId = restModel.cityId
        profile.generatedStatus = restModel.generatedStatus
        profile.answerIds = restModel.answerIds
        profile.doNotRecommend = restModel.doNotRecommend
        profile.excludePoiIds = restModel.excludePoiIds
        profile.includePoiIds = restModel.includePoiIds
        profile.dayIds = restModel.dayIds
        profile.considerWeather = restModel.considerWeather
        profile.distinctPlan = restModel.distinctPlan
        
        if let accommondation = restModel.accommodation {
            profile.accommodation = AccommondationMapper().map(accommondation)
        }
        
        if let destinationAccommodation = restModel.destinationAccommodation {
            profile.destinationAccommodation = AccommondationMapper().map(destinationAccommodation)
        }
        return profile
    }
    
    func map(_ restModels: [TRPTimelineSegmentModel], planId: Int? = nil) -> [TRPTimelineSegment] {
        return restModels.compactMap { map($0) }
    }
    
}
