import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Each provider keeps the timeline rules it shipped with: map routes, where a tapped step
/// opens, and whether host city ids reach the backend.
final class TRPProviderRulesTests: XCTestCase {

    private var originalProvider: TripianProvider = .civitatis

    override func setUp() {
        super.setUp()
        originalProvider = TRPCoreKit.shared.provider
    }

    override func tearDown() {
        TRPCoreKit.shared.provider = originalProvider
        super.tearDown()
    }

    func testMapRouteStyles() {
        XCTAssertEqual(TripianProvider.civitatis.mapRouteStyle, .walkingPerSegment)
        XCTAssertEqual(TripianProvider.nexus.mapRouteStyle, .dayLegs)
        XCTAssertEqual(TripianProvider.getYourGuide.mapRouteStyle, .none)
        XCTAssertTrue(TripianProvider.nexus.drawsRoutesOnMap)
        XCTAssertFalse(TripianProvider.civitatis.drawsRoutesOnMap)
        XCTAssertFalse(TripianProvider.getYourGuide.drawsRoutesOnMap)
    }

    func testCivitatisSendsOnlyActivityStepsToTheHost() {
        let civitatis = TripianProvider.civitatis
        XCTAssertTrue(civitatis.opensHostDetail(forStepType: "activity"))
        XCTAssertFalse(civitatis.opensHostDetail(forStepType: "poi"))
        XCTAssertFalse(civitatis.opensHostDetail(forStepType: nil))
        XCTAssertFalse(civitatis.opensHostDetail(forStepType: "event"))
    }

    func testOtherProvidersSendEveryNonPoiStepToTheHost() {
        for provider in [TripianProvider.nexus, .getYourGuide] {
            XCTAssertTrue(provider.opensHostDetail(forStepType: "activity"))
            XCTAssertFalse(provider.opensHostDetail(forStepType: "poi"))
            XCTAssertTrue(provider.opensHostDetail(forStepType: nil))
            XCTAssertTrue(provider.opensHostDetail(forStepType: "event"))
        }
    }

    private func itinerary(bookedCityId: Int) -> TRPItineraryWithActivities {
        let booking = TRPSegmentActivityItem(
            activityId: "C_123_15", bookingId: "B1", title: "Booked tour", imageUrl: nil, description: nil,
            startDatetime: "2026-10-05 10:00", endDatetime: "2026-10-05 12:00",
            coordinate: TRPLocation(lat: 41.38, lon: 2.17), cancellation: nil,
            adultCount: 2, childCount: 0, cityId: bookedCityId
        )
        return TRPItineraryWithActivities(
            tripName: nil, startDatetime: "2026-10-05 00:00", endDatetime: "2026-10-06 23:59",
            uniqueId: "", tripianHash: nil,
            destinationItems: [TRPSegmentDestinationItem(title: "Barcelona", coordinate: "41.38,2.17", cityId: bookedCityId)],
            favouriteItems: nil, tripItems: [booking]
        )
    }

    private func bookedSegmentCityIds(_ profile: TRPTimelineProfile) -> [Int?] {
        return profile.segments.filter { $0.additionalData != nil }.map { $0.city?.id }
    }

    func testCivitatisSendsBookedSegmentsWithoutACity() {
        TRPCoreKit.shared.provider = .civitatis
        let profile = itinerary(bookedCityId: 5).createTimelineProfileFromBookings()

        XCTAssertEqual(bookedSegmentCityIds(profile), [nil])
    }

    func testNexusSendsBookedSegmentsInTheHostCity() {
        TRPCoreKit.shared.provider = .nexus
        let profile = itinerary(bookedCityId: 5).createTimelineProfileFromBookings()

        XCTAssertEqual(bookedSegmentCityIds(profile), [5])
    }
}
