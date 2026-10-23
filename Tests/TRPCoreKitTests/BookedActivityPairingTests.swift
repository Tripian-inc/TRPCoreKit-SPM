import Testing
import TRPFoundationKit
@testable import TRPCoreKit

/// Test suite for BookedActivityPairing.pairBooked/pairReserved (line-id, legacy city/day
/// fallback, and reserved-segment matching).
@Suite("Booked Activity Pairing Tests")
struct BookedActivityPairingTests {

    typealias Entry = BookedActivityPairing.Entry
    typealias Pair = BookedActivityPairing.Pair

    @Test("Round trip pairs by line id even when city and day are swapped")
    func testRoundTripPairsByLineIdEvenWhenCityAndDayAreSwapped() {
        let inInbound = Entry(index: 0, key: "2160", lineId: "24150760", cityId: 1, day: "2026-10-21 09:45")
        let inOutbound = Entry(index: 1, key: "2160", lineId: "24150761", cityId: 2, day: "2026-10-28 10:00")
        let storedInbound = Entry(index: 0, key: "2160", lineId: "24150760", cityId: 2, day: "2026-10-28 10:00")
        let storedOutbound = Entry(index: 1, key: "2160", lineId: "24150761", cityId: 1, day: "2026-10-21 09:45")

        let result = BookedActivityPairing.pairBooked(
            incoming: [inInbound, inOutbound],
            stored: [storedInbound, storedOutbound]
        )

        #expect(result.pairs.sorted { $0.storedIndex < $1.storedIndex } == [
            Pair(incomingIndex: 0, storedIndex: 0),
            Pair(incomingIndex: 1, storedIndex: 1),
        ])
        #expect(result.unmatchedIncoming.isEmpty)
        #expect(result.unmatchedStored.isEmpty)
    }

    @Test("Legacy stored without line id pairs by city when day is corrupted")
    func testLegacyStoredWithoutLineIdPairsByCityWhenDayIsCorrupted() {
        let inInbound = Entry(index: 0, key: "2160", lineId: "24150760", cityId: 1, day: "2026-10-21 09:45")
        let inOutbound = Entry(index: 1, key: "2160", lineId: "24150761", cityId: 2, day: "2026-10-28 10:00")
        let s1 = Entry(index: 0, key: "2160", lineId: nil, cityId: 1, day: "2026-10-21 09:45")
        let s2 = Entry(index: 1, key: "2160", lineId: nil, cityId: 2, day: "2026-10-21 09:45")

        let result = BookedActivityPairing.pairBooked(incoming: [inInbound, inOutbound], stored: [s1, s2])

        #expect(result.pairs.sorted { $0.storedIndex < $1.storedIndex } == [
            Pair(incomingIndex: 0, storedIndex: 0),
            Pair(incomingIndex: 1, storedIndex: 1),
        ])
        #expect(result.unmatchedIncoming.isEmpty)
        #expect(result.unmatchedStored.isEmpty)
    }

    @Test("Legacy stored without line id pairs by city when day is corrupted, reversed input order")
    func testLegacyStoredWithoutLineIdPairsByCityWhenDayIsCorruptedReversedInputOrder() {
        let inInbound = Entry(index: 0, key: "2160", lineId: "24150760", cityId: 1, day: "2026-10-21 09:45")
        let inOutbound = Entry(index: 1, key: "2160", lineId: "24150761", cityId: 2, day: "2026-10-28 10:00")
        let s1 = Entry(index: 0, key: "2160", lineId: nil, cityId: 1, day: "2026-10-21 09:45")
        let s2 = Entry(index: 1, key: "2160", lineId: nil, cityId: 2, day: "2026-10-21 09:45")

        let result = BookedActivityPairing.pairBooked(incoming: [inOutbound, inInbound], stored: [s2, s1])

        #expect(result.pairs.sorted { $0.storedIndex < $1.storedIndex } == [
            Pair(incomingIndex: 0, storedIndex: 0),
            Pair(incomingIndex: 1, storedIndex: 1),
        ])
        #expect(result.unmatchedIncoming.isEmpty)
        #expect(result.unmatchedStored.isEmpty)
    }

    @Test("Reserved segment prefers the same day incoming item")
    func testReservedPrefersSameDayIncomingItem() {
        let sameDay = Entry(index: 0, key: "100", lineId: nil, cityId: nil, day: "2026-10-21 09:00")
        let otherDay = Entry(index: 1, key: "100", lineId: nil, cityId: nil, day: "2026-10-22 09:00")
        let reserved = Entry(index: 0, key: "100", lineId: nil, cityId: nil, day: "2026-10-21 09:00")

        let result = BookedActivityPairing.pairReserved(incoming: [otherDay, sameDay], booked: [], reserved: [reserved])

        #expect(result.pairs == [Pair(incomingIndex: 0, storedIndex: 0)])
        #expect(result.unmatchedIncoming == [1])
        #expect(result.unmatchedStored.isEmpty)
    }

    @Test("Reserved pairs with same key incoming on a different day when no same day item exists")
    func testReservedPairsWithSameKeyIncomingOnDifferentDayWhenNoSameDayItemExists() {
        let incoming = Entry(index: 0, key: "100", lineId: nil, cityId: nil, day: "2026-10-22 09:00")
        let reserved = Entry(index: 0, key: "100", lineId: nil, cityId: nil, day: "2026-10-21 09:00")

        let result = BookedActivityPairing.pairReserved(incoming: [incoming], booked: [], reserved: [reserved])

        #expect(result.pairs == [Pair(incomingIndex: 0, storedIndex: 0)])
        #expect(result.unmatchedIncoming.isEmpty)
        #expect(result.unmatchedStored.isEmpty)
    }

    @Test("Two reserved with one incoming leaves one reserved unmatched")
    func testTwoReservedWithOneIncomingLeavesOneReservedUnmatched() {
        let incoming = Entry(index: 0, key: "100", lineId: nil, cityId: nil, day: "2026-10-21 09:00")
        let reservedA = Entry(index: 0, key: "100", lineId: nil, cityId: nil, day: "2026-10-21 09:00")
        let reservedB = Entry(index: 1, key: "100", lineId: nil, cityId: nil, day: "2026-10-22 09:00")

        let result = BookedActivityPairing.pairReserved(incoming: [incoming], booked: [], reserved: [reservedA, reservedB])

        #expect(result.pairs.count == 1)
        #expect(result.unmatchedIncoming.isEmpty)
        #expect(result.unmatchedStored.count == 1)
    }

    @Test("Incoming with no stored counterpart is unmatched incoming")
    func testIncomingWithNoStoredCounterpartIsUnmatchedIncoming() {
        let incoming = Entry(index: 0, key: "999", lineId: nil, cityId: nil, day: nil)

        let result = BookedActivityPairing.pairBooked(incoming: [incoming], stored: [])

        #expect(result.pairs.isEmpty)
        #expect(result.unmatchedIncoming == [0])
        #expect(result.unmatchedStored.isEmpty)
    }

    @Test("Stored with a line id not present in incoming is unmatched and not stolen by legacy pass")
    func testStoredWithLineIdNotPresentInIncomingIsUnmatchedAndNotStolenByLegacyPass() {
        let incomingLegacyLike = Entry(index: 0, key: "100", lineId: nil, cityId: 1, day: "2026-10-21 09:00")
        let storedWithUnknownLineId = Entry(index: 0, key: "100", lineId: "unknown-line", cityId: 1, day: "2026-10-21 09:00")

        let result = BookedActivityPairing.pairBooked(incoming: [incomingLegacyLike], stored: [storedWithUnknownLineId])

        #expect(result.pairs.isEmpty)
        #expect(result.unmatchedIncoming == [0])
        #expect(result.unmatchedStored == [0])
    }

    @Test("Different keys never pair")
    func testDifferentKeysNeverPair() {
        let incoming = Entry(index: 0, key: "100", lineId: nil, cityId: 1, day: "2026-10-21 09:00")
        let stored = Entry(index: 0, key: "200", lineId: nil, cityId: 1, day: "2026-10-21 09:00")

        let result = BookedActivityPairing.pairBooked(incoming: [incoming], stored: [stored])

        #expect(result.pairs.isEmpty)
        #expect(result.unmatchedIncoming == [0])
        #expect(result.unmatchedStored == [0])
    }

    @Test("Pair booked is order independent under shuffling")
    func testPairBookedIsOrderIndependentUnderShuffling() {
        let inInbound = Entry(index: 0, key: "2160", lineId: "24150760", cityId: 1, day: "2026-10-21 09:45")
        let inOutbound = Entry(index: 1, key: "2160", lineId: "24150761", cityId: 2, day: "2026-10-28 10:00")
        let extraIncoming = Entry(index: 2, key: "555", lineId: nil, cityId: 3, day: "2026-11-01 10:00")
        let s1 = Entry(index: 0, key: "2160", lineId: nil, cityId: 1, day: "2026-10-21 09:45")
        let s2 = Entry(index: 1, key: "2160", lineId: nil, cityId: 2, day: "2026-10-21 09:45")

        let baseline = BookedActivityPairing.pairBooked(
            incoming: [inInbound, inOutbound, extraIncoming],
            stored: [s1, s2]
        )

        for _ in 0..<20 {
            let shuffledIncoming = [inInbound, inOutbound, extraIncoming].shuffled()
            let shuffledStored = [s1, s2].shuffled()
            let result = BookedActivityPairing.pairBooked(incoming: shuffledIncoming, stored: shuffledStored)
            #expect(result == baseline)
        }
    }

    @Test("Legacy stored with different city and day pairs with the remaining item")
    func testLegacyStoredWithDifferentCityAndDayPairsWithRemainingItem() {
        let incoming = Entry(index: 0, key: "100", lineId: "24150760", cityId: 1, day: "2026-10-21 09:00")
        let legacyStored = Entry(index: 0, key: "100", lineId: nil, cityId: 2, day: "2026-10-25 10:00")

        let result = BookedActivityPairing.pairBooked(incoming: [incoming], stored: [legacyStored])

        #expect(result.pairs == [Pair(incomingIndex: 0, storedIndex: 0)])
        #expect(result.unmatchedIncoming.isEmpty)
        #expect(result.unmatchedStored.isEmpty)
    }

    @Test("Reserved does not convert when its only item is held by a booked segment")
    func testReservedDoesNotConvertWhenItsOnlyItemIsHeldByBookedSegment() {
        let incoming = Entry(index: 0, key: "100", lineId: "24150760", cityId: 1, day: "2026-10-21 09:00")
        let booked = Entry(index: 0, key: "100", lineId: nil, cityId: 1, day: "2026-10-21 09:00")
        let reserved = Entry(index: 1, key: "100", lineId: nil, cityId: 1, day: "2026-10-21 09:00")

        let result = BookedActivityPairing.pairReserved(incoming: [incoming], booked: [booked], reserved: [reserved])

        #expect(result.pairs.isEmpty)
        #expect(result.unmatchedStored == [1])
    }

    @Test("Round trip timeline segments in different cities on the same day pair with both items")
    func testRoundTripTimelineSegmentsInDifferentCitiesOnSameDayPairWithBothItems() {
        let inbound = tripItem(lineId: "24150760", cityId: 1, start: "2026-10-21 09:45")
        let outbound = tripItem(lineId: "24150761", cityId: 2, start: "2026-10-21 18:00")
        let storedOutbound = bookedSegment(cityId: 2, start: "2026-10-21 18:00")
        let storedInbound = bookedSegment(cityId: 1, start: "2026-10-21 09:45")

        let result = BookedActivityPairing.pairBooked(tripItems: [inbound, outbound],
                                                      segments: [storedOutbound, storedInbound])

        #expect(result.pairs == [
            Pair(incomingIndex: 1, storedIndex: 0),
            Pair(incomingIndex: 0, storedIndex: 1),
        ])
        #expect(result.unmatchedIncoming.isEmpty)
        #expect(result.unmatchedStored.isEmpty)
    }

    @Test("Entry normalises empty line id, non positive city, and short day")
    func testEntryNormalisesEmptyLineIdNonPositiveCityAndShortDay() {
        let entry = Entry(index: 0, key: "100", lineId: "", cityId: 0, day: "2026-10-2")

        #expect(entry.lineId == nil)
        #expect(entry.cityId == nil)
        #expect(entry.day == nil)
    }

    @Test("Entry keeps first ten characters of day")
    func testEntryKeepsFirstTenCharactersOfDay() {
        let entry = Entry(index: 0, key: "100", lineId: "abc", cityId: 5, day: "2026-10-21 09:45")

        #expect(entry.day == "2026-10-21")
    }

    private func tripItem(lineId: String, cityId: Int, start: String) -> TRPSegmentActivityItem {
        TRPSegmentActivityItem(activityId: "2160", bookingId: nil, title: "Transfer", imageUrl: nil,
                               description: nil, startDatetime: start, endDatetime: nil,
                               coordinate: TRPLocation(lat: 28.1, lon: -16.6), cancellation: nil,
                               adultCount: 2, childCount: 0, cityId: cityId, lineId: lineId)
    }

    private func bookedSegment(cityId: Int, start: String) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .bookedActivity
        segment.cityId = cityId
        segment.startDate = start
        segment.additionalData = TRPSegmentActivityItem(activityId: "2160", bookingId: nil, title: "Transfer",
                                                        imageUrl: nil, description: nil, startDatetime: start,
                                                        endDatetime: nil, coordinate: TRPLocation(lat: 28.1, lon: -16.6),
                                                        cancellation: nil, adultCount: 2, childCount: 0, cityId: cityId)
        return segment
    }
}
