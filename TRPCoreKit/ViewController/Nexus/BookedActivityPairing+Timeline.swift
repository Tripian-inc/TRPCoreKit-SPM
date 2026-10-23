//
//  BookedActivityPairing+Timeline.swift
//  TRPCoreKit
//
//  Builds BookedActivityPairing entries from host trip items and timeline segments.
//

import Foundation

extension BookedActivityPairing.Entry {

    /// Entry for a host trip item, or nil when the item carries no activity id.
    init?(tripItem: TRPSegmentActivityItem, index: Int) {
        guard let activityId = tripItem.activityId, !activityId.isEmpty else { return nil }
        self.init(index: index,
                  key: activityId.trp_activityMatchKey(),
                  lineId: tripItem.lineId,
                  cityId: tripItem.cityId,
                  day: tripItem.startDatetime)
    }

    /// Entry for a stored segment, or nil when it carries no activity id. The city comes from the
    /// segment's own `cityId`, then its resolved city; the day from the activity start.
    init?(segment: TRPTimelineSegment, index: Int) {
        guard let data = segment.additionalData,
              let activityId = data.activityId, !activityId.isEmpty else { return nil }
        let cityId = (segment.cityId ?? 0) > 0 ? segment.cityId : segment.city?.id
        self.init(index: index,
                  key: activityId.trp_activityMatchKey(),
                  lineId: data.lineId,
                  cityId: cityId,
                  day: data.startDatetime ?? segment.startDate)
    }
}

extension BookedActivityPairing {

    /// Pairs host trip items with the booked-activity segments in `segments`.
    /// Indices in the result refer to `tripItems` and `segments`.
    static func pairBooked(tripItems: [TRPSegmentActivityItem], segments: [TRPTimelineSegment]) -> Result {
        pairBooked(incoming: entries(tripItems), stored: entries(segments, of: .bookedActivity))
    }

    /// Pairs the reserved-activity segments in `segments` with the host trip items that no
    /// booked-activity segment in `segments` holds. Indices in the result refer to `tripItems` and `segments`.
    static func pairReserved(tripItems: [TRPSegmentActivityItem], segments: [TRPTimelineSegment]) -> Result {
        pairReserved(incoming: entries(tripItems),
                     booked: entries(segments, of: .bookedActivity),
                     reserved: entries(segments, of: .reservedActivity))
    }

    private static func entries(_ tripItems: [TRPSegmentActivityItem]) -> [Entry] {
        tripItems.enumerated().compactMap { Entry(tripItem: $0.element, index: $0.offset) }
    }

    private static func entries(_ segments: [TRPTimelineSegment], of type: TRPTimelineSegmentType) -> [Entry] {
        segments.enumerated().compactMap { offset, segment in
            segment.segmentType == type ? Entry(segment: segment, index: offset) : nil
        }
    }
}
