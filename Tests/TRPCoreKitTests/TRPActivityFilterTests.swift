import XCTest
@testable import TRPCoreKit

/// The activity filter's rating bound and slider labels follow the provider, and Civitatis keeps
/// the filter it shipped with.
final class TRPActivityFilterTests: XCTestCase {

    func testRatingFilterIsOfferedToEveryProviderButCivitatis() {
        XCTAssertFalse(TripianProvider.civitatis.offersActivityRatingFilter)
        XCTAssertTrue(TripianProvider.nexus.offersActivityRatingFilter)
        XCTAssertTrue(TripianProvider.getYourGuide.offersActivityRatingFilter)
    }

    func testSliderLabelsStayPinnedForEveryProviderButCivitatis() {
        XCTAssertEqual(TripianProvider.civitatis.rangeSliderValueLabelPlacement, .followingThumbs)
        XCTAssertEqual(TripianProvider.nexus.rangeSliderValueLabelPlacement, .pinnedToEdges)
        XCTAssertEqual(TripianProvider.getYourGuide.rangeSliderValueLabelPlacement, .pinnedToEdges)
    }

    func testMinimumRatingCountsAsAnActiveFilter() {
        let filter = FilterData(minRating: 4.5)
        XCTAssertFalse(filter.isEmpty)
        XCTAssertEqual(filter.activeFilterCount, 1)
        XCTAssertEqual(FilterData(minPrice: 10, minDuration: 60, minRating: 4).activeFilterCount, 3)
        XCTAssertTrue(FilterData().isEmpty)
    }

    func testRatingOptionsAscendFromThree() {
        XCTAssertEqual(AddPlanFilterVC.minimumRatingOptions, [3.0, 3.5, 4.0, 4.5])
        XCTAssertTrue(AddPlanFilterVC.ratingChipTitle(for: 4).hasSuffix("+"))
        XCTAssertEqual(AddPlanFilterVC.ratingChipTitle(for: 4.5).filter(\.isNumber), "45")
    }

    func testPinnedLabelsStayAtTheEdgesWhileThumbsMove() {
        let slider = makeSlider(placement: .pinnedToEdges)
        let before = labelFrames(of: slider)
        slider.lowerValue = 40
        slider.upperValue = 60
        let after = labelFrames(of: slider)

        XCTAssertEqual(after.lower.minX, 0)
        XCTAssertEqual(after.upper.maxX, slider.bounds.width, accuracy: 0.5)
        XCTAssertEqual(before.lower.minX, after.lower.minX)
        XCTAssertEqual(before.upper.maxX, after.upper.maxX, accuracy: 0.5)
    }

    func testFollowingLabelsMoveWithTheirThumbs() {
        let slider = makeSlider(placement: .followingThumbs)
        let before = labelFrames(of: slider)
        slider.lowerValue = 40
        slider.upperValue = 60
        let after = labelFrames(of: slider)

        XCTAssertGreaterThan(after.lower.midX, before.lower.midX)
        XCTAssertLessThan(after.upper.midX, before.upper.midX)
    }

    private func makeSlider(placement: TRPRangeSlider.ValueLabelPlacement) -> TRPRangeSlider {
        let slider = TRPRangeSlider(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.lowerValue = 0
        slider.upperValue = 100
        slider.valueLabelPlacement = placement
        slider.layoutIfNeeded()
        return slider
    }

    private func labelFrames(of slider: TRPRangeSlider) -> (lower: CGRect, upper: CGRect) {
        let labels = slider.subviews.compactMap { $0 as? UILabel }
        return (labels[0].frame, labels[1].frame)
    }
}
