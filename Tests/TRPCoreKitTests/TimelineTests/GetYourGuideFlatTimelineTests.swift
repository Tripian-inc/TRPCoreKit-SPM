import XCTest
@testable import TRPCoreKit

/// GetYourGuide shows the day as the same flat timeline as Nexus, so every Nexus flat timeline test runs again for it.
final class GetYourGuideFlatTimelineTests: NexusFlatTimelineTests {

    override var provider: TripianProvider { .getYourGuide }

    func testProviderIsGetYourGuide() {
        XCTAssertEqual(TRPCoreKit.shared.provider, .getYourGuide)
        XCTAssertTrue(TRPTimelineItineraryViewModel(timeline: TRPTimelineMockData.getMockTimeline()).usesFlatTimeline)
    }
}
