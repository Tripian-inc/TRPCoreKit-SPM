import XCTest
import UIKit
import TRPFoundationKit
@testable import TRPCoreKit

/// Covers the AddPlan past-day rule at the edges not exercised by `AddPlanPastDaySelectionTests`:
/// the time-selection grid's own day guard and the day-chip view's nil-selection rendering.
final class AddPlanPastDayCoverageTests: XCTestCase {

    private func day(_ offset: Int) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: offset, to: today)!.addingTimeInterval(12 * 3600)
    }

    private func makeTour() -> TRPTourProduct {
        return TRPTourProduct(
            id: "C_1_15_1",
            productId: "C_1_15_1",
            cityId: 1,
            name: "City Tour",
            image: nil,
            gallery: nil,
            duration: nil,
            price: nil,
            rating: nil,
            ratingCount: nil,
            description: nil,
            webUrl: nil,
            phone: nil,
            hours: nil,
            address: nil,
            icon: "",
            coordinate: nil,
            categories: [],
            tags: [],
            distance: nil,
            status: true,
            offers: [],
            additionalData: nil
        )
    }

    // MARK: - AddPlanTimeSelectionViewModel.selectDay(at:)

    func testTimeSelectionSelectDayIgnoresPastIndex() {
        var planData = AddPlanData()
        planData.availableDays = [day(-1), day(0), day(1)]
        planData.selectedDay = day(0)

        let viewModel = AddPlanTimeSelectionViewModel(tour: makeTour(), planData: planData)

        viewModel.selectDay(at: 0)

        XCTAssertTrue(Calendar.current.isDate(viewModel.getSelectedDate()!, inSameDayAs: day(0)))
    }

    func testTimeSelectionSelectDayIgnoresOutOfRangeIndex() {
        var planData = AddPlanData()
        planData.availableDays = [day(-1), day(0), day(1)]
        planData.selectedDay = day(0)

        let viewModel = AddPlanTimeSelectionViewModel(tour: makeTour(), planData: planData)

        viewModel.selectDay(at: 99)

        XCTAssertTrue(Calendar.current.isDate(viewModel.getSelectedDate()!, inSameDayAs: day(0)))
    }

    func testTimeSelectionSelectDayAcceptsFutureIndex() {
        var planData = AddPlanData()
        planData.availableDays = [day(-1), day(0), day(1)]
        planData.selectedDay = day(0)

        let viewModel = AddPlanTimeSelectionViewModel(tour: makeTour(), planData: planData)

        viewModel.selectDay(at: 2)

        XCTAssertTrue(Calendar.current.isDate(viewModel.getSelectedDate()!, inSameDayAs: day(1)))
    }

    // MARK: - TRPTimelineDayFilterView

    /// Finds the view's real collection view (registered cell, dataSource/delegate wired) rather than
    /// creating a fresh one, since `dequeueReusableCell` would crash on an unregistered identifier.
    private func collectionView(in filterView: TRPTimelineDayFilterView) -> UICollectionView? {
        return filterView.subviews.first { $0 is UICollectionView } as? UICollectionView
    }

    func testConfigureWithNilSelectionRendersNoSelectedCellWithoutCrashing() {
        let filterView = TRPTimelineDayFilterView(frame: CGRect(x: 0, y: 0, width: 300, height: 66))
        let dates = [day(-1), day(0), day(1)]

        filterView.configure(with: dates, selectedDay: nil, mode: .addPlan)

        guard let collectionView = collectionView(in: filterView) else {
            return XCTFail("Expected the day filter view to host a collection view")
        }

        XCTAssertEqual(filterView.collectionView(collectionView, numberOfItemsInSection: 0), dates.count)

        for index in dates.indices {
            let cell = filterView.collectionView(collectionView, cellForItemAt: IndexPath(item: index, section: 0))
            XCTAssertNotEqual(cell.contentView.layer.borderWidth, 2, "No cell should render as selected when selectedDay is nil")
        }
    }

    func testConfigureWithValidSelectionMarksThatCellSelected() {
        let filterView = TRPTimelineDayFilterView(frame: CGRect(x: 0, y: 0, width: 300, height: 66))
        let dates = [day(-1), day(0), day(1)]

        filterView.configure(with: dates, selectedDay: 1, mode: .addPlan)

        guard let collectionView = collectionView(in: filterView) else {
            return XCTFail("Expected the day filter view to host a collection view")
        }

        let selectedCell = filterView.collectionView(collectionView, cellForItemAt: IndexPath(item: 1, section: 0))
        XCTAssertEqual(selectedCell.contentView.layer.borderWidth, 2)
    }

    func testAddPlanModeDoesNotAllowSelectingPastDay() {
        let filterView = TRPTimelineDayFilterView(frame: CGRect(x: 0, y: 0, width: 300, height: 66))
        let dates = [day(-1), day(0), day(1)]
        filterView.configure(with: dates, selectedDay: nil, mode: .addPlan)

        guard let collectionView = collectionView(in: filterView) else {
            return XCTFail("Expected the day filter view to host a collection view")
        }

        let shouldSelectPast = filterView.collectionView(collectionView, shouldSelectItemAt: IndexPath(item: 0, section: 0))
        let shouldSelectFuture = filterView.collectionView(collectionView, shouldSelectItemAt: IndexPath(item: 2, section: 0))

        XCTAssertFalse(shouldSelectPast)
        XCTAssertTrue(shouldSelectFuture)
    }
}
