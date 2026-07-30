//
//  TRPAvailabilityPriceRefreshTests.swift
//  TRPCoreKitTests
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Testing
import Foundation
@testable import TRPCoreKit

/// Slot-selection rule behind the availability sweep's price refresh.
@Suite("Availability Price Refresh Tests")
struct TRPAvailabilityPriceRefreshTests {

    private let date = "2026-08-01"

    private func makeViewModel() -> TRPTimelineItineraryViewModel {
        return TRPTimelineItineraryViewModel(timeline: nil)
    }

    private func makeSchedule(_ slots: [TRPTourScheduleSlot], date: String) -> TRPTourSchedule {
        return TRPTourSchedule(title: "Test", dates: [TRPTourScheduleDay(date: date, slots: slots)])
    }

    @Test("Timed target takes the exact slot's price")
    func testExactTimeMatch() {
        let schedule = makeSchedule([
            TRPTourScheduleSlot(time: "10:00", price: 20),
            TRPTourScheduleSlot(time: "11:15", price: 48.67)
        ], date: date)

        let price = makeViewModel().refreshedSlotPrice(schedule: schedule, dateString: date,
                                                       expectedHHmm: "11:15", isFlexible: false)
        #expect(price == 48.67)
    }

    @Test("Timed target falls back to the flexible slot when its time is not listed")
    func testFallsBackToFlexibleSlot() {
        let schedule = makeSchedule([
            TRPTourScheduleSlot(time: nil, price: 33)
        ], date: date)

        let price = makeViewModel().refreshedSlotPrice(schedule: schedule, dateString: date,
                                                       expectedHHmm: "11:15", isFlexible: false)
        #expect(price == 33)
    }

    @Test("Timed target with neither an exact nor a flexible slot keeps the timeline price")
    func testNoMatchReturnsNil() {
        let schedule = makeSchedule([
            TRPTourScheduleSlot(time: "09:00", price: 20)
        ], date: date)

        let price = makeViewModel().refreshedSlotPrice(schedule: schedule, dateString: date,
                                                       expectedHHmm: "11:15", isFlexible: false)
        #expect(price == nil)
    }

    @Test("Flexible target prefers the flexible slot")
    func testFlexibleTargetPrefersFlexibleSlot() {
        let schedule = makeSchedule([
            TRPTourScheduleSlot(time: "10:00", price: 15),
            TRPTourScheduleSlot(time: nil, price: 42)
        ], date: date)

        let price = makeViewModel().refreshedSlotPrice(schedule: schedule, dateString: date,
                                                       expectedHHmm: nil, isFlexible: true)
        #expect(price == 42)
    }

    @Test("Flexible target without a flexible slot takes the cheapest")
    func testFlexibleTargetTakesCheapest() {
        let schedule = makeSchedule([
            TRPTourScheduleSlot(time: "10:00", price: 30),
            TRPTourScheduleSlot(time: "14:00", price: 18),
            TRPTourScheduleSlot(time: "18:00", price: nil)
        ], date: date)

        let price = makeViewModel().refreshedSlotPrice(schedule: schedule, dateString: date,
                                                       expectedHHmm: nil, isFlexible: true)
        #expect(price == 18)
    }

    @Test("Missing or non-positive slot price keeps the timeline price")
    func testNonPositivePriceReturnsNil() {
        let viewModel = makeViewModel()

        let noPrice = makeSchedule([TRPTourScheduleSlot(time: "11:15", price: nil)], date: date)
        #expect(viewModel.refreshedSlotPrice(schedule: noPrice, dateString: date,
                                             expectedHHmm: "11:15", isFlexible: false) == nil)

        let zeroPrice = makeSchedule([TRPTourScheduleSlot(time: "11:15", price: 0)], date: date)
        #expect(viewModel.refreshedSlotPrice(schedule: zeroPrice, dateString: date,
                                             expectedHHmm: "11:15", isFlexible: false) == nil)

        #expect(viewModel.refreshedSlotPrice(schedule: nil, dateString: date,
                                             expectedHHmm: "11:15", isFlexible: false) == nil)
    }

    @Test("Price comes from the requested day's bucket")
    func testPicksRequestedDayBucket() {
        let schedule = TRPTourSchedule(title: "Test", dates: [
            TRPTourScheduleDay(date: "2026-07-31", slots: [TRPTourScheduleSlot(time: "11:15", price: 10)]),
            TRPTourScheduleDay(date: date, slots: [TRPTourScheduleSlot(time: "11:15", price: 55)])
        ])

        let price = makeViewModel().refreshedSlotPrice(schedule: schedule, dateString: date,
                                                       expectedHHmm: "11:15", isFlexible: false)
        #expect(price == 55)
    }
}
