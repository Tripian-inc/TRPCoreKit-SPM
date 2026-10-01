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

extension TRPTimelineDateAndFavouriteTests {

    func testTravellerCountComesFromTheSegmentNotThePlaceholderAdditionalData() {
        let segment = activitySegment("1505", type: .bookedActivity)
        segment.adults = 2
        segment.children = 1
        // The API never fills these in; the mapper writes 1/0 placeholders.
        segment.additionalData?.adultCount = 1
        segment.additionalData?.childCount = 0

        let item = TRPMergedTimelineItem(segment: segment, plan: nil, originalSegmentIndex: 0)

        XCTAssertEqual(item.adultCount, 2)
        XCTAssertEqual(item.childCount, 1)
        XCTAssertEqual(BookedActivityCellData(from: item, order: 1).adultCount, 2)
    }

    private func bookedItemWithoutEndTime(endDatetime: String?, duration: Double?) -> TRPMergedTimelineItem {
        let segment = activitySegment("1505", type: .bookedActivity)
        segment.startDate = "2026-10-24 21:00"
        segment.endDate = nil
        segment.additionalData?.startDatetime = "2026-10-24 21:00"
        segment.additionalData?.endDatetime = endDatetime
        segment.additionalData?.duration = duration
        return TRPMergedTimelineItem(segment: segment, plan: nil, originalSegmentIndex: 0)
    }

    func testMissingEndTimeIsDerivedFromDuration() {
        XCTAssertEqual(bookedItemWithoutEndTime(endDatetime: nil, duration: 120).timeRangeString, "21:00 - 23:00")
        XCTAssertEqual(bookedItemWithoutEndTime(endDatetime: "", duration: 90).timeRangeString, "21:00 - 22:30")
    }

    func testMissingEndTimeWithoutDurationShowsOnlyTheStartTime() {
        let item = bookedItemWithoutEndTime(endDatetime: nil, duration: nil)

        XCTAssertEqual(item.timeRangeString, "21:00")
        XCTAssertEqual(BookedActivityCellData(from: item, order: 1).timeRange, "21:00")
    }

    func testMergedBookingWithEmptyEndTimeEndsAfterItsDuration() {
        let segment = activitySegment("1505", type: .bookedActivity)
        segment.additionalData?.endDatetime = ""
        segment.additionalData?.duration = 90
        let profile = TRPTimelineProfile()
        profile.segments = [timelineDateSegment(start: "2026-10-01 00:00", end: "2026-10-22 23:59"), segment]
        let timeline = TRPTimeline(id: 1, tripHash: "hash", tripProfile: profile, city: barcelona, plans: [],
                                   segments: [], favouriteItems: nil)

        let items = TRPTimelineItineraryViewModel(timeline: timeline).mergeTimelineData()

        XCTAssertEqual(items.map { $0.timeRangeString }, ["10:30 - 12:00"])
    }

    private func bookedSegment(start: String?, end: String?, duration: Double?) -> TRPTimelineSegment {
        let segment = activitySegment("1505", type: .bookedActivity)
        segment.startDate = start
        segment.endDate = end
        segment.additionalData?.startDatetime = start
        segment.additionalData?.endDatetime = end
        segment.additionalData?.duration = duration
        return segment
    }

    private func assertBookedCellWithFlexibleTime(_ segment: TRPTimelineSegment, file: StaticString = #filePath, line: UInt = #line) {
        let item = TRPMergedTimelineItem(segment: segment, plan: nil, originalSegmentIndex: 0)

        XCTAssertTrue(item.isFlexibleActivity, file: file, line: line)
        XCTAssertTrue(TRPMapDisplayItem.activity(segment).isFlexibleActivity, file: file, line: line)
        guard case .bookedActivity(let data) = TimelineCellType.from(item, order: 1) else {
            return XCTFail("A flexible booked activity keeps the booked cell", file: file, line: line)
        }
        XCTAssertTrue(data.isFlexible, file: file, line: line)
    }

    func testBookedActivitySentLikeAFlexibleReservationIsFlexible() {
        assertBookedCellWithFlexibleTime(bookedSegment(start: "2026-10-24 00:00", end: "2026-10-24 23:59", duration: -1))
    }

    func testFlexibleBookedActivityWithoutEndTimeIsFlexible() {
        assertBookedCellWithFlexibleTime(bookedSegment(start: "2026-10-24 00:00", end: nil, duration: -1))
    }

    func testBookedActivityWithoutTimesIsFlexible() {
        assertBookedCellWithFlexibleTime(bookedSegment(start: "2026-10-24", end: nil, duration: nil))
    }

    func testBookedActivityWithAStartTimeIsNotFlexible() {
        let segment = bookedSegment(start: "2026-10-24 21:00", end: nil, duration: nil)
        let item = TRPMergedTimelineItem(segment: segment, plan: nil, originalSegmentIndex: 0)

        XCTAssertFalse(item.isFlexibleActivity)
        XCTAssertFalse(TRPMapDisplayItem.activity(segment).isFlexibleActivity)
        XCTAssertFalse(BookedActivityCellData(from: item, order: 1).isFlexible)
    }

    private func conflictFlags(_ segments: [TRPTimelineSegment]) -> [Bool] {
        let items = segments.enumerated().map { TRPMergedTimelineItem(segment: $1, plan: nil, originalSegmentIndex: $0) }
        viewModel().detectTimeConflicts(items: items)
        return items.map { $0.hasConflict }
    }

    func testBookingWithoutEndTimeOverlapsForItsDuration() {
        let flags = conflictFlags([bookedSegment(start: "2026-10-24 10:00", end: nil, duration: 120),
                                   bookedSegment(start: "2026-10-24 11:00", end: "2026-10-24 11:30", duration: nil)])

        XCTAssertEqual(flags, [true, true])
    }

    func testBookingWithoutEndTimeDoesNotOverlapAfterItsDuration() {
        let flags = conflictFlags([bookedSegment(start: "2026-10-24 10:00", end: nil, duration: 60),
                                   bookedSegment(start: "2026-10-24 11:00", end: "2026-10-24 11:30", duration: nil)])

        XCTAssertEqual(flags, [false, false])
    }

    func testBookingWithOnlyAStartTimeNeverOverlaps() {
        let flags = conflictFlags([bookedSegment(start: "2026-10-24 10:00", end: nil, duration: nil),
                                   bookedSegment(start: "2026-10-24 10:00", end: "2026-10-24 11:30", duration: nil)])

        XCTAssertEqual(flags, [false, false])
    }

    private func bookedSegmentFromHost(start: String?, end: String?, duration: Double?) -> TRPTimelineSegment? {
        let booking = TRPSegmentActivityItem(activityId: "1505", bookingId: "B1", title: "Free tour por Roma", imageUrl: nil, description: nil,
                                             startDatetime: start, endDatetime: end, coordinate: TRPLocation(lat: 41.9, lon: 12.5),
                                             cancellation: nil, adultCount: 2, childCount: 0, duration: duration)
        let itinerary = TRPItineraryWithActivities(tripName: "Roma", startDatetime: "2026-10-22 00:00", endDatetime: "2026-10-27 18:00",
                                                   uniqueId: "U1", tripianHash: nil,
                                                   destinationItems: [TRPSegmentDestinationItem(title: "Roma", coordinate: "41.9,12.5")],
                                                   favouriteItems: nil, tripItems: [booking])
        return itinerary.createTimelineProfileFromBookings().segments.first { $0.segmentType == .bookedActivity }
    }

    func testBookingWithoutEndTimeDoesNotEndAtTheTripEnd() {
        XCTAssertNil(bookedSegmentFromHost(start: "2026-10-24 21:00", end: nil, duration: nil)?.endDate)
    }

    func testBookingWithoutEndTimeEndsAfterItsDuration() {
        XCTAssertEqual(bookedSegmentFromHost(start: "2026-10-24 21:00", end: nil, duration: 120)?.endDate, "2026-10-24 23:00")
    }

    func testBookingEndTimeIsKept() {
        XCTAssertEqual(bookedSegmentFromHost(start: "2026-10-24 21:00", end: "2026-10-24 22:00", duration: 120)?.endDate, "2026-10-24 22:00")
    }

    private func itinerary(tripItems: [TRPSegmentActivityItem]?) -> TRPItineraryWithActivities {
        return TRPItineraryWithActivities(tripName: nil, startDatetime: "2026-10-01 00:00", endDatetime: "2026-10-22 23:59",
                                          uniqueId: "U1", tripianHash: "hash", destinationItems: [],
                                          favouriteItems: nil, tripItems: tripItems)
    }

    private func cancelledIds(tripItems: [TRPSegmentActivityItem]?) -> [String?] {
        let segments = [
            timelineDateSegment(start: "2026-10-01 00:00", end: "2026-10-22 23:59"),
            activitySegment("111", type: .bookedActivity),
            activitySegment("C_222_15", type: .reservedActivity),
            activitySegment("333", type: .bookedActivity)
        ]
        let vm = TRPTimelineItineraryViewModel(timeline: TRPTimeline(id: 1, tripHash: "hash", tripProfile: TRPTimelineProfile(), city: barcelona,
                                                                     plans: [], segments: [], favouriteItems: nil))
        return vm.collectCancelledBookedSegments(in: segments, itinerary: itinerary(tripItems: tripItems))
            .map { $0.segment.additionalData?.activityId }
    }

    func testBookingMissingFromTheHostListIsRemoved() {
        XCTAssertEqual(cancelledIds(tripItems: [bookedTripItem("111")]), ["333"])
    }

    func testAllBookingsAreRemovedWhenTheHostListIsEmpty() {
        XCTAssertEqual(cancelledIds(tripItems: []), ["111", "333"])
    }

    func testAllBookingsAreRemovedWhenTheHostSendsNoBookingList() {
        XCTAssertEqual(cancelledIds(tripItems: nil), ["111", "333"])
    }

    func testPrefixedActivityIdMatchesTheSegmentWhenTheHostSendsNoBookingId() {
        var prefixed = bookedTripItem("C_111_15")
        prefixed.bookingId = nil
        XCTAssertEqual(cancelledIds(tripItems: [prefixed, bookedTripItem("333")]), [])
    }

    private func booking(_ activityId: String, bookingId: String?, start: String = "2026-10-09 10:30") -> TRPSegmentActivityItem {
        var item = bookedTripItem(activityId)
        item.bookingId = bookingId
        item.startDatetime = start
        return item
    }

    private func bookedSegment(for booking: TRPSegmentActivityItem) -> TRPTimelineSegment {
        let segment = activitySegment(booking.activityId ?? "", type: .bookedActivity)
        segment.additionalData = booking
        return segment
    }

    private func viewModel() -> TRPTimelineItineraryViewModel {
        return TRPTimelineItineraryViewModel(timeline: TRPTimeline(id: 1, tripHash: "hash", tripProfile: TRPTimelineProfile(), city: barcelona,
                                                                   plans: [], segments: [], favouriteItems: nil))
    }

    func testCancelledBookingOfATourBookedTwiceIsRemovedByBookingId() {
        let kept = booking("111", bookingId: "B-1")
        let cancelled = booking("111", bookingId: "B-2", start: "2026-10-10 10:30")
        let segments = [bookedSegment(for: kept), bookedSegment(for: cancelled)]

        let removed = viewModel().collectCancelledBookedSegments(in: segments, itinerary: itinerary(tripItems: [kept]))

        XCTAssertEqual(removed.map { $0.segment.additionalData?.bookingId }, ["B-2"])
    }

    func testSecondBookingOfTheSameTourIsAdded() {
        let first = booking("111", bookingId: "B-1")
        let second = booking("111", bookingId: "B-2", start: "2026-10-10 10:30")
        let profile = TRPTimelineProfile()
        profile.segments = [bookedSegment(for: first)]
        let timeline = TRPTimeline(id: 1, tripHash: "hash", tripProfile: profile, city: barcelona, plans: [], segments: [], favouriteItems: nil)

        let missing = viewModel().missingBookedTripItems(from: [first, second], in: timeline)

        XCTAssertEqual(missing.map { $0.bookingId }, ["B-2"])
    }

    func testPrefixedBookingIdMatchesThePlainBookingId() {
        let segment = bookedSegment(for: booking("111", bookingId: "C_2113_15"))

        let removed = viewModel().collectCancelledBookedSegments(in: [segment], itinerary: itinerary(tripItems: [booking("111", bookingId: "2113")]))

        XCTAssertTrue(removed.isEmpty)
    }

    func testSegmentWithoutBookingIdIsMatchedByActivityId() {
        let segment = bookedSegment(for: booking("111", bookingId: nil))

        let removed = viewModel().collectCancelledBookedSegments(in: [segment], itinerary: itinerary(tripItems: [booking("111", bookingId: "B-1")]))

        XCTAssertTrue(removed.isEmpty)
    }
}
