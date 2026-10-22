import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// `TRPCreateEditTimelineSegmentProfile.doNotGenerate` must be 0 only when creating a new
/// segment (no `segmentIndex`) and 1 on every update of an existing segment, regardless of
/// what was assigned to it or copied from a base segment.
final class TRPSegmentDoNotGenerateTests: XCTestCase {

    // MARK: - Profile-level

    func testNewSegmentProfileWithoutIndexSendsDoNotGenerateZero() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")

        XCTAssertNil(profile.segmentIndex)
        XCTAssertEqual(profile.doNotGenerate, 0)
    }

    func testEditSegmentProfileWithIndexSendsDoNotGenerateOne() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 2

        XCTAssertEqual(profile.doNotGenerate, 1)
    }

    func testAssigningDoNotGenerateDirectlyIsIgnored() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")

        profile.doNotGenerate = 1
        XCTAssertEqual(profile.doNotGenerate, 0, "assignment must be ignored while segmentIndex is nil")

        profile.segmentIndex = 0
        profile.doNotGenerate = 0
        XCTAssertEqual(profile.doNotGenerate, 1, "assignment must be ignored while segmentIndex is set")
    }

    func testInitFromBaseWithoutSegmentIndexSendsDoNotGenerateZeroEvenIfBaseWasOne() {
        let base = TRPTimelineSegment()
        base.doNotGenerate = 1

        let profile = TRPCreateEditTimelineSegmentProfile(from: base, tripHash: "trip-hash", segmentIndex: nil)

        XCTAssertEqual(profile.doNotGenerate, 0)
    }

    func testInitFromBaseWithSegmentIndexSendsDoNotGenerateOne() {
        let base = TRPTimelineSegment()

        let profile = TRPCreateEditTimelineSegmentProfile(from: base, tripHash: "trip-hash", segmentIndex: 3)

        XCTAssertEqual(profile.doNotGenerate, 1)
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

    func testMakeTimelineSegmentSettingsForExistingSegmentSendsDoNotGenerateOne() {
        let profile = TRPCreateEditTimelineSegmentProfile(tripHash: "trip-hash")
        profile.segmentIndex = 4

        let settings = TimelineProfileMapper().makeTimelineSegmentSettings(editTimelineProfile: profile, tripHash: "trip-hash")

        XCTAssertEqual(settings?.doNotGenerate, 1)
        XCTAssertEqual(settings?.segmentIndex, 4)
        XCTAssertEqual(settings?.getParameters()["doNotGenerate"] as? Int, 1)
    }
}
