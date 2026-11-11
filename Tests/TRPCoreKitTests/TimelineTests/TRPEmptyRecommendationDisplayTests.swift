import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// A recommendation card is rendered only when its plan has steps.
final class TRPEmptyRecommendationDisplayTests: XCTestCase {

    private func segment(type: TRPTimelineSegmentType, title: String, start: String, end: String, city: TRPCity) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = type
        segment.title = title
        segment.startDate = start
        segment.endDate = end
        segment.city = city
        segment.cityId = city.id
        return segment
    }

    func testItineraryWithoutStepsIsDroppedWhileBookedAndFilledItinerariesStay() {
        let barcelona = GenerationFixtures.barcelona
        let madrid = TRPCity(id: 45, name: "Madrid", coordinate: TRPLocation(lat: 40.4168, lon: -3.7038))

        let booked = TRPMergedTimelineItem(
            segment: segment(type: .bookedActivity, title: "Booked", start: "2025-12-09 08:00", end: "2025-12-09 09:00", city: barcelona),
            plan: nil,
            originalSegmentIndex: 0)
        let filled = TRPMergedTimelineItem(
            segment: segment(type: .itinerary, title: "Recommendations", start: "2025-12-09 10:00", end: "2025-12-09 14:00", city: barcelona),
            plan: GenerationFixtures.plan(id: "1", generatedStatus: 1, stepCount: 3),
            originalSegmentIndex: 1)
        let emptyInBarcelona = TRPMergedTimelineItem(
            segment: segment(type: .itinerary, title: "Recommendations 2", start: "2025-12-09 15:00", end: "2025-12-09 18:00", city: barcelona),
            plan: GenerationFixtures.plan(id: "2", generatedStatus: 1, stepCount: 0),
            originalSegmentIndex: 2)
        let emptyInMadrid = TRPMergedTimelineItem(
            segment: segment(type: .itinerary, title: "Recommendations", start: "2025-12-09 19:00", end: "2025-12-09 21:00", city: madrid),
            plan: nil,
            originalSegmentIndex: 3)
        XCTAssertEqual(filled.steps.count, 3)

        let viewModel = TRPTimelineItineraryViewModel(timeline: nil)
        viewModel.mergedTimeline = TRPDateGroupedTimeline(items: [booked, filled, emptyInBarcelona, emptyInMadrid])
        viewModel.allTripDates = [booked.startDate!]
        viewModel.selectedDayIndex = 0

        viewModel.updateDisplayItems()

        XCTAssertEqual(viewModel.displayItems.count, 1, "a city section holding only empty recommendations is removed")
        XCTAssertEqual(viewModel.displayItems.first?.city?.id, barcelona.id)
        XCTAssertEqual(viewModel.displayItems.first?.items.map(\.originalSegmentIndex), [0, 1])
    }
}
