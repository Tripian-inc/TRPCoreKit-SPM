import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// `TRPCreateEditTimelineSegmentProfile.doNotGenerate` must be 0 when creating a new segment
/// (no `segmentIndex`); on update it is 0 for booked and reserved activity segments and 1 for
/// every other type (itinerary, manualPoi), regardless of what was assigned to it or copied from
/// a base segment.
final class TRPSegmentDoNotGenerateTests: XCTestCase {

    // MARK: - Profile-level: create

    func testNewSegmentProfileWithoutIndexSendsDoNotGenerateZero() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")

        XCTAssertNil(profile.segmentIndex)
        XCTAssertEqual(profile.doNotGenerate, 0)
    }

    func testCreateSendsDoNotGenerateZeroForEveryType() {
        for type in [TRPTimelineSegmentType.itinerary, .bookedActivity, .reservedActivity, .manualPoi] {
            let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
            profile.segmentType = type

            XCTAssertEqual(profile.doNotGenerate, 0, "create must send 0 regardless of segment type (\(type))")
        }
    }

    func testAssigningDoNotGenerateDirectlyIsIgnoredOnCreate() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")

        profile.doNotGenerate = 1
        XCTAssertEqual(profile.doNotGenerate, 0, "assignment must be ignored while segmentIndex is nil")
    }

    // MARK: - Profile-level: update, type-aware

    func testUpdateOfItinerarySegmentSendsDoNotGenerateOne() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 2
        profile.segmentType = .itinerary

        XCTAssertEqual(profile.doNotGenerate, 1)
    }

    func testUpdateOfBookedActivitySegmentSendsDoNotGenerateZero() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 2
        profile.segmentType = .bookedActivity

        XCTAssertEqual(profile.doNotGenerate, 0)
    }

    func testUpdateOfReservedActivitySegmentSendsDoNotGenerateZero() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 2
        profile.segmentType = .reservedActivity

        XCTAssertEqual(profile.doNotGenerate, 0)
    }

    func testUpdateOfManualPoiSegmentSendsDoNotGenerateOne() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 2
        profile.segmentType = .manualPoi

        XCTAssertEqual(profile.doNotGenerate, 1)
    }

    func testAssigningDoNotGenerateDirectlyIsIgnoredOnUpdate() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 0
        profile.segmentType = .itinerary

        profile.doNotGenerate = 0
        XCTAssertEqual(profile.doNotGenerate, 1, "assignment must be ignored while segmentIndex is set")
    }

    // MARK: - init(from:tripHash:segmentIndex:)

    func testInitFromBaseWithoutSegmentIndexSendsDoNotGenerateZeroEvenIfBaseWasOne() {
        let base = TRPTimelineSegment()
        base.doNotGenerate = 1
        base.segmentType = .itinerary

        let profile = TRPCreateEditTimelineSegmentProfile(from: base, tripHash: "trip-hash", segmentIndex: nil)

        XCTAssertEqual(profile.doNotGenerate, 0)
    }

    func testInitFromBaseWithSegmentIndexSendsDoNotGenerateOneForItinerary() {
        let base = TRPTimelineSegment()
        base.segmentType = .itinerary

        let profile = TRPCreateEditTimelineSegmentProfile(from: base, tripHash: "trip-hash", segmentIndex: 3)

        XCTAssertEqual(profile.doNotGenerate, 1)
    }

    func testInitFromBaseWithSegmentIndexSendsDoNotGenerateZeroForBookedActivity() {
        let base = TRPTimelineSegment()
        base.segmentType = .bookedActivity

        let profile = TRPCreateEditTimelineSegmentProfile(from: base, tripHash: "trip-hash", segmentIndex: 3)

        XCTAssertEqual(profile.doNotGenerate, 0)
    }

    func testBaseSegmentDefaultDoNotGenerateIsZero() {
        let base = TRPTimelineSegment()

        XCTAssertEqual(base.doNotGenerate, 0)
    }

    // MARK: - Mapper-level

    func testMakeTimelineSegmentSettingsForNewSegmentSendsDoNotGenerateZero() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")

        let settings = TimelineProfileMapper().makeTimelineSegmentSettings(editTimelineProfile: profile, tripHash: "trip-hash")

        XCTAssertEqual(settings?.doNotGenerate, 0)
        XCTAssertNil(settings?.segmentIndex)
        XCTAssertEqual(settings?.getParameters()["doNotGenerate"] as? Int, 0)
    }

    func testMakeTimelineSegmentSettingsForItineraryUpdateSendsDoNotGenerateOne() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 4
        profile.segmentType = .itinerary

        let settings = TimelineProfileMapper().makeTimelineSegmentSettings(editTimelineProfile: profile, tripHash: "trip-hash")

        XCTAssertEqual(settings?.doNotGenerate, 1)
        XCTAssertEqual(settings?.segmentIndex, 4)
        XCTAssertEqual(settings?.getParameters()["doNotGenerate"] as? Int, 1)
    }

    func testMakeTimelineSegmentSettingsForManualPoiUpdateSendsDoNotGenerateOne() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 4
        profile.segmentType = .manualPoi

        let settings = TimelineProfileMapper().makeTimelineSegmentSettings(editTimelineProfile: profile, tripHash: "trip-hash")

        XCTAssertEqual(settings?.doNotGenerate, 1)
        XCTAssertEqual(settings?.getParameters()["doNotGenerate"] as? Int, 1)
    }

    func testMakeTimelineSegmentSettingsForBookedActivityUpdateSendsDoNotGenerateZero() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 4
        profile.segmentType = .bookedActivity

        let settings = TimelineProfileMapper().makeTimelineSegmentSettings(editTimelineProfile: profile, tripHash: "trip-hash")

        XCTAssertEqual(settings?.doNotGenerate, 0)
        XCTAssertEqual(settings?.segmentIndex, 4)
        XCTAssertEqual(settings?.getParameters()["doNotGenerate"] as? Int, 0)
    }
}
