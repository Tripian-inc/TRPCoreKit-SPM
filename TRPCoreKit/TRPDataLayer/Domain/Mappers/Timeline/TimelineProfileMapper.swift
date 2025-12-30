//
//  TripProfileMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPFoundationKit

final class TimelineProfileMapper {
    
    func map(_ restModel: TRPTimelineProfileModel?) -> TRPTimelineProfile? {
        
        guard let restModel else { return nil }
        let newModel = TRPTimelineProfile(cityId: restModel.cityId)
        
        newModel.hash = restModel.hash
        newModel.answerIds = restModel.answerIds
        
        newModel.adults = restModel.adults
        newModel.children = restModel.children ?? 0
        newModel.pets = restModel.pets ?? 0
        newModel.doNotRecommend = restModel.doNotRecommend
        newModel.excludePoiIds = restModel.excludePoiIds
        newModel.excludeHashPois = restModel.excludeHashPois
        newModel.considerWeather = restModel.considerWeather
        
        if let segments = restModel.segments {
            newModel.segments = TimelineSegmentMapper().map(segments)
        }
        
        
        return newModel
    }
    
    func map(_ restModels: [TRPTimelineProfileModel]) -> [TRPTimelineProfile] {
        return restModels.compactMap{ map($0) }
    }
 
    public func makeTimelineSettings(editTimelineProfile: TRPCreateEditTimelineProfile, tripHash: String) ->  TRPTimelineSettings?{
        let timelineSettings = makeTimelineSettings(profile: editTimelineProfile, tripHash: tripHash)
//        timelineSettings?.doNotGenerate = editTimelineProfile.doNotGenerate
        return timelineSettings
    }
 
    public func makeTimelineSegmentSettings(editTimelineProfile: TRPCreateEditTimelineSegmentProfile, tripHash: String) ->  TRPTimelineSegmentSettings?{
        let timelineSettings = getTimelineSegmentSettings(from: editTimelineProfile)
        timelineSettings.doNotGenerate = editTimelineProfile.doNotGenerate ?? 0
        timelineSettings.hash = tripHash
        if let segmentIndex = editTimelineProfile.segmentIndex {
            timelineSettings.segmentIndex = segmentIndex
        }
        return timelineSettings
    }
    
    
    public func makeTimelineSettings(profile: TRPTimelineProfile, tripHash: String? = nil) ->  TRPTimelineSettings?{
        
        let setting = TRPTimelineSettings(cityId: profile.cityId)
        
        setting.answers = profile.answerIds ?? []
        setting.doNotRecommend = profile.doNotRecommend
        setting.excludePoiIds = profile.excludePoiIds
        setting.adults = profile.adults
        setting.children = profile.children
        setting.pets = profile.pets
        setting.considerWeather = profile.considerWeather

        setting.segments = getTimelineSegments(from: profile.segments)

        return setting
    }
    
    private func getTimelineSegments(from segments: [TRPTimelineSegment]) -> [TRPTimelineSegmentSettings] {
        return segments.map { segment in
            return getTimelineSegmentSettings(from: segment)
        }
    }
    
    private func getTimelineSegmentSettings(from segment: TRPTimelineSegment) -> TRPTimelineSegmentSettings {
        var _segment = segment
        if _segment is TRPCreateEditTimelineSegmentProfile {
            _segment = segment as! TRPCreateEditTimelineSegmentProfile
        }
        let restKitSegment = TRPTimelineSegmentSettings()

        // Set segment type
        restKitSegment.segmentType = _segment.segmentType.rawValue

        restKitSegment.cityId = _segment.city?.id
        restKitSegment.title = _segment.title
        restKitSegment.description = _segment.description
        restKitSegment.startDate = _segment.startDate
        restKitSegment.endDate = _segment.endDate
        restKitSegment.coordinate = _segment.coordinate
        restKitSegment.destinationCoordinate = _segment.destinationCoordinate
        restKitSegment.adults = _segment.adults
        restKitSegment.children = _segment.children
        restKitSegment.pets = _segment.pets
        restKitSegment.answerIds = _segment.answerIds ?? []
        restKitSegment.doNotRecommend = _segment.doNotRecommend
        restKitSegment.excludePoiIds = _segment.excludePoiIds
        restKitSegment.considerWeather = _segment.considerWeather
        restKitSegment.available = _segment.available
        restKitSegment.distinctPlan = _segment.distinctPlan

        // Smart Recommendations properties
        restKitSegment.activityFreeText = _segment.activityFreeText
        restKitSegment.activityIds = _segment.activityIds
        restKitSegment.smartRecommendation = _segment.smartRecommendation
        restKitSegment.excludedActivityIds = _segment.excludedActivityIds

        // Set additional data for booked/reserved activities
        if let additionalData = _segment.additionalData {
            restKitSegment.additionalData = mapAdditionalData(from: additionalData)
        }

        if let accommondation = _segment.accommodation {
            let restKitAccommondation = Accommondation(refId: accommondation.referanceId,
                                                       name: accommondation.name,
                                                       address: accommondation.address,
                                                       coordinate: accommondation.coordinate)
            restKitSegment.accommodationAdress = restKitAccommondation
        }

        if let accommondation = _segment.destinationAccommodation {
            let restKitAccommondation = Accommondation(refId: accommondation.referanceId,
                                                       name: accommondation.name,
                                                       address: accommondation.address,
                                                       coordinate: accommondation.coordinate)
            restKitSegment.destinationAccommodationAdress = restKitAccommondation
        }

        return restKitSegment
    }

    private func mapAdditionalData(from data: TRPSegmentActivityItem) -> TRPTimelineSegmentAdditionalData {
        var additionalData = TRPTimelineSegmentAdditionalData()
        additionalData.activityId = data.activityId
        additionalData.bookingId = data.bookingId
        additionalData.title = data.title
        additionalData.imageUrl = data.imageUrl
        additionalData.description = data.description
        additionalData.startDatetime = data.startDatetime
        additionalData.endDatetime = data.endDatetime
        additionalData.coordinate = data.coordinate
        additionalData.cancellation = data.cancellation
        additionalData.duration = data.duration
        if let price = data.price {
            additionalData.price = price.value
            additionalData.currency = price.currency
        }
        // Note: TRPRestKit model doesn't have adultCount/childCount
        // These are stored in the segment itself, not in additionalData
        return additionalData
    }
}
