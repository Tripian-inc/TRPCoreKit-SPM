import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

final class TRPTimelineDateAndFavouriteTests: XCTestCase {

    private let barcelona: TRPCity = {
        var city = TRPCity(id: 1, name: "Barcelona", coordinate: TRPLocation(lat: 41.38, lon: 2.17))
        city.timezone = TimeZone.current.identifier
        return city
    }()

    private func timelineDateSegment(start: String, end: String) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.title = "TimelineDate"
        segment.available = false
        segment.startDate = start
        segment.endDate = end
        return segment
    }

    private func timeline(segments: [TRPTimelineSegment], favourites: [TRPSegmentFavoriteItem]? = nil) -> TRPTimeline {
        let profile = TRPTimelineProfile()
        profile.segments = segments
        return TRPTimeline(id: 1, tripHash: "hash", tripProfile: profile, city: barcelona, plans: [], segments: [], favouriteItems: favourites)
    }

    private func localDay(_ ymd: String) -> Date {
        return TRPDateHelper.parseDate(ymd)!
    }

    // MARK: - Trip day boundaries

    func testTimelineDateSegmentYieldsLocalDays() {
        let vm = TRPTimelineItineraryViewModel(timeline: timeline(segments: [
            timelineDateSegment(start: "2026-09-03 00:00", end: "2026-09-10 23:59")
        ]))

        let days = vm.getDayDates().map(TRPDateHelper.formatDateString)
        XCTAssertEqual(days.count, 8)
        XCTAssertEqual(days.first, "2026-09-03")
        XCTAssertEqual(days.last, "2026-09-10")
        XCTAssertTrue(vm.getDays().first?.contains("03/09") ?? false)
    }

    func testDayCountSurvivesDaylightSavingChange() {
        let vm = TRPTimelineItineraryViewModel(timeline: timeline(segments: [
            timelineDateSegment(start: "2026-10-20 00:00", end: "2026-10-30 23:59")
        ]))

        let days = vm.getDayDates().map(TRPDateHelper.formatDateString)
        XCTAssertEqual(days.count, 11)
        XCTAssertEqual(days[5], "2026-10-25")
    }

    func testBoundariesFallBackToSegmentDates() {
        let segment = TRPTimelineSegment()
        segment.startDate = "2026-09-05 10:00"
        segment.endDate = "2026-09-05 12:00"
        let vm = TRPTimelineItineraryViewModel(timeline: timeline(segments: [segment]))

        XCTAssertEqual(vm.getDayDates().map(TRPDateHelper.formatDateString), ["2026-09-05"])
    }

    // MARK: - Day matching

    func testMatchDayUsesLocalCalendarDay() {
        let days = ["2026-09-19", "2026-09-20", "2026-09-21"].map(localDay)

        let match = TRPDateHelper.matchDay(ymd: "2026-09-20", in: days)

        XCTAssertNotNil(match)
        XCTAssertEqual(match.map(TRPDateHelper.formatDateString), "2026-09-20")
        XCTAssertNil(TRPDateHelper.matchDay(ymd: "2026-09-25", in: days))
    }

    // MARK: - Past-time check

    func testHasPassedOnlyAppliesToToday() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let hour = calendar.component(.hour, from: now)

        if hour >= 1 {
            let earlier = calendar.date(byAdding: .hour, value: -1, to: now)!
            XCTAssertTrue(TimePickerBounds.hasPassed(selectedDay: today, city: nil, time: earlier))
            XCTAssertTrue(TimePickerBounds.hasPassed(selectedDay: today, city: barcelona, time: earlier))
            XCTAssertFalse(TimePickerBounds.hasPassed(selectedDay: tomorrow, city: barcelona, time: earlier))
        }
        if hour <= 22 {
            let later = calendar.date(byAdding: .hour, value: 1, to: now)!
            XCTAssertFalse(TimePickerBounds.hasPassed(selectedDay: today, city: nil, time: later))
            XCTAssertFalse(TimePickerBounds.hasPassed(selectedDay: today, city: barcelona, time: later))
        }
        XCTAssertFalse(TimePickerBounds.hasPassed(selectedDay: nil, city: barcelona, time: now))
    }

    func testCityTodayMatchesLocalTripDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        XCTAssertTrue(barcelona.isDateTodayInCityTimezone(today))
        XCTAssertFalse(barcelona.isDateTodayInCityTimezone(tomorrow))
    }

    // MARK: - Favourites

    private func favourite(_ id: String, hostCityId: Int? = nil) -> TRPSegmentFavoriteItem {
        return TRPSegmentFavoriteItem(activityId: id, title: id, cityName: "Somewhere", cityId: hostCityId,
                                      photoUrl: nil, description: nil, activityUrl: nil,
                                      coordinate: TRPLocation(lat: 0, lon: 0), rating: nil, ratingCount: nil,
                                      cancellation: nil, duration: nil, price: nil, locations: nil)
    }

    func testFavouritesOutsideTripOrUnresolvedAreHidden() {
        let vm = TRPTimelineItineraryViewModel(timeline: timeline(segments: [
            timelineDateSegment(start: "2026-09-03 00:00", end: "2026-09-10 23:59")
        ]))
        vm.timeline?.favouriteItems = [
            favourite("111"),
            favourite("222"),
            favourite("333"),
            favourite("444", hostCityId: 1),
            favourite("555", hostCityId: 99),
            favourite("666", hostCityId: 99)
        ]
        vm.favouriteCityLookups = ["111": 1, "222": 99, "333": nil, "666": 1]

        vm.filterFavoriteItems()

        XCTAssertEqual(vm.getFavoriteItems().map { $0.activityId }, ["111", "444", "666"])
        XCTAssertEqual(vm.getFavoriteItemsCount(), 3)
    }

    func testFavouritesAreKeptWhenTripCitiesAreNotKnownYet() {
        var unknownCity = TRPCity(id: 0, name: "", coordinate: TRPLocation(lat: 0, lon: 0))
        unknownCity.timezone = nil
        let profile = TRPTimelineProfile()
        profile.segments = [timelineDateSegment(start: "2026-09-03 00:00", end: "2026-09-10 23:59")]
        let vm = TRPTimelineItineraryViewModel(timeline: TRPTimeline(id: 1, tripHash: "hash", tripProfile: profile, city: unknownCity, plans: [], segments: [], favouriteItems: nil))
        vm.timeline?.favouriteItems = [favourite("111"), favourite("222")]
        vm.favouriteCityLookups = ["111": 7, "222": nil]

        vm.filterFavoriteItems()

        XCTAssertEqual(vm.getFavoriteItems().map { $0.activityId }, ["111"])
    }

    // MARK: - Booked activities

    private func bookedTripItem(_ id: String) -> TRPSegmentActivityItem {
        return TRPSegmentActivityItem(activityId: id, bookingId: "B-\(id)", title: id, imageUrl: nil, description: nil,
                                      startDatetime: "2026-10-09 10:30", endDatetime: "2026-10-09 12:30",
                                      coordinate: TRPLocation(lat: 0, lon: 0), cancellation: nil, adultCount: 2, childCount: 0)
    }

    private func activitySegment(_ id: String, type: TRPTimelineSegmentType) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = type
        segment.startDate = "2026-10-09 10:30"
        segment.endDate = "2026-10-09 12:30"
        segment.additionalData = bookedTripItem(id)
        return segment
    }

    func testReservedSegmentDoesNotHideTheMatchingBooking() {
        let profile = TRPTimelineProfile()
        profile.segments = [
            timelineDateSegment(start: "2026-10-01 00:00", end: "2026-10-22 23:59"),
            activitySegment("C_111_15", type: .reservedActivity),
            activitySegment("222", type: .bookedActivity)
        ]
        let timeline = TRPTimeline(id: 1, tripHash: "hash", tripProfile: profile, city: barcelona, plans: [],
                                   segments: [activitySegment("111", type: .reservedActivity)], favouriteItems: nil)
        let vm = TRPTimelineItineraryViewModel(timeline: timeline)

        let missing = vm.missingBookedTripItems(from: [bookedTripItem("111"), bookedTripItem("222"), bookedTripItem("333")], in: timeline)

        XCTAssertEqual(missing.map { $0.activityId }, ["111", "333"])
    }

    func testBookedSegmentProfileFallsBackToTheTripCity() {
        let profile = TRPTimelineProfile()
        profile.segments = [timelineDateSegment(start: "2026-10-01 00:00", end: "2026-10-22 23:59")]
        let vm = TRPTimelineItineraryViewModel(timeline: TRPTimeline(id: 1, tripHash: "hash", tripProfile: profile, city: barcelona, plans: [], segments: [], favouriteItems: nil))
        var item = bookedTripItem("111")
        item.cityId = 0

        let segmentProfile = vm.createSegmentProfileFromTripItem(item, tripHash: "hash")

        XCTAssertEqual(segmentProfile.city?.id, barcelona.id)
        XCTAssertEqual(segmentProfile.coordinate?.lat, barcelona.coordinate.lat)
        XCTAssertEqual(segmentProfile.additionalData?.isNoLocation, true)
    }

    func testSavedPlansViewModelExposesPlannedIds() {
        let ids = ["2026-09-05": ["C_111_15_1"]]
        let vm = SavedPlansViewModel(favouriteItems: [], tripHash: "hash", availableDays: [], availableCities: [barcelona], activityIdsByDay: ids)

        XCTAssertEqual(vm.plannedActivityIdsByDay(), ids)
    }
}
