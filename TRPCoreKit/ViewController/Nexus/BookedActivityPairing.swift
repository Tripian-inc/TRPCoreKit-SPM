//
//  BookedActivityPairing.swift
//  TRPCoreKit
//
//  Pairs host reservation items with stored booked and reserved segments. Pure, deterministic, no I/O.
//

import Foundation

struct BookedActivityPairing {

    /// One side of the pairing. `index` is the position in the caller's array
    /// (tripItems for incoming, timeline segments for stored); `day` is `yyyy-MM-dd`.
    struct Entry: Equatable {
        let index: Int
        let key: String
        let lineId: String?
        let cityId: Int?
        let day: String?

        init(index: Int, key: String, lineId: String?, cityId: Int?, day: String?) {
            self.index = index
            self.key = key
            self.lineId = lineId.flatMap { $0.isEmpty ? nil : $0 }
            self.cityId = cityId.flatMap { $0 > 0 ? $0 : nil }
            self.day = day.flatMap { $0.count >= 10 ? String($0.prefix(10)) : nil }
        }
    }

    struct Pair: Equatable {
        let incomingIndex: Int
        let storedIndex: Int
    }

    struct Result: Equatable {
        /// Sorted by `storedIndex`.
        let pairs: [Pair]
        /// Incoming indices with no stored counterpart, ascending.
        let unmatchedIncoming: [Int]
        /// Stored indices with no incoming counterpart, ascending.
        let unmatchedStored: [Int]
    }

    /// Pairs incoming items with stored booked segments. Inside each product key group the
    /// line id decides first; stored segments without a line id then pair with the remaining
    /// incoming items by city and day, then by city alone, then by day alone, then with any remaining item.
    static func pairBooked(incoming: [Entry], stored: [Entry]) -> Result {
        pair(incoming: incoming, stored: stored) { incomingGroup, storedGroup in
            var state = GroupState(incoming: incomingGroup, stored: storedGroup)
            state.match(storedFilter: { $0.lineId != nil }) { stored, incoming in
                incoming.lineId == stored.lineId
            }
            let legacy: (Entry) -> Bool = { $0.lineId == nil }
            state.match(storedFilter: legacy) { stored, incoming in
                stored.cityId != nil && stored.cityId == incoming.cityId
                    && stored.day != nil && stored.day == incoming.day
            }
            state.match(storedFilter: legacy) { stored, incoming in
                stored.cityId != nil && stored.cityId == incoming.cityId
            }
            state.match(storedFilter: legacy) { stored, incoming in
                stored.day != nil && stored.day == incoming.day
            }
            state.match(storedFilter: legacy) { _, _ in true }
            return state.pairs
        }
    }

    /// Pairs stored reserved segments with the incoming items no booked segment holds (see `pairBooked`),
    /// by product key, preferring an item on the same day and otherwise any item of that product.
    /// Each reserved segment consumes one item; `unmatchedIncoming` excludes the items held by booked segments.
    static func pairReserved(incoming: [Entry], booked: [Entry], reserved: [Entry]) -> Result {
        let held = Set(pairBooked(incoming: incoming, stored: booked).pairs.map(\.incomingIndex))
        return pairReserved(incoming: incoming.filter { !held.contains($0.index) }, reserved: reserved)
    }

    private static func pairReserved(incoming: [Entry], reserved: [Entry]) -> Result {
        pair(incoming: incoming, stored: reserved) { incomingGroup, reservedGroup in
            var state = GroupState(incoming: incomingGroup, stored: reservedGroup)
            state.match(storedFilter: { _ in true }) { stored, incoming in
                stored.day != nil && stored.day == incoming.day
            }
            state.match(storedFilter: { _ in true }) { _, _ in true }
            return state.pairs
        }
    }

    private static func pair(incoming: [Entry],
                             stored: [Entry],
                             matchGroup: ([Entry], [Entry]) -> [Pair]) -> Result {
        let incomingByKey = Dictionary(grouping: incoming, by: \.key)
        let storedByKey = Dictionary(grouping: stored, by: \.key)

        var pairs: [Pair] = []
        for key in Set(incomingByKey.keys).intersection(storedByKey.keys).sorted() {
            let incomingGroup = (incomingByKey[key] ?? []).sorted(by: canonicalOrder)
            let storedGroup = (storedByKey[key] ?? []).sorted(by: canonicalOrder)
            pairs.append(contentsOf: matchGroup(incomingGroup, storedGroup))
        }

        let pairedIncoming = Set(pairs.map(\.incomingIndex))
        let pairedStored = Set(pairs.map(\.storedIndex))
        return Result(
            pairs: pairs.sorted { $0.storedIndex < $1.storedIndex },
            unmatchedIncoming: incoming.map(\.index).filter { !pairedIncoming.contains($0) }.sorted(),
            unmatchedStored: stored.map(\.index).filter { !pairedStored.contains($0) }.sorted()
        )
    }

    private static func canonicalOrder(_ lhs: Entry, _ rhs: Entry) -> Bool {
        if lhs.day != rhs.day { return (lhs.day ?? "\u{10FFFF}") < (rhs.day ?? "\u{10FFFF}") }
        if lhs.cityId != rhs.cityId { return (lhs.cityId ?? Int.max) < (rhs.cityId ?? Int.max) }
        if lhs.lineId != rhs.lineId { return (lhs.lineId ?? "\u{10FFFF}") < (rhs.lineId ?? "\u{10FFFF}") }
        return lhs.index < rhs.index
    }

    private struct GroupState {
        let incoming: [Entry]
        let stored: [Entry]
        var usedIncoming = Set<Int>()
        var usedStored = Set<Int>()
        var pairs: [Pair] = []

        init(incoming: [Entry], stored: [Entry]) {
            self.incoming = incoming
            self.stored = stored
        }

        /// One greedy pass: every still-free stored entry accepted by `storedFilter` takes the
        /// first still-free incoming entry (canonical order) that `matches` it.
        mutating func match(storedFilter: (Entry) -> Bool, matches: (Entry, Entry) -> Bool) {
            for storedEntry in stored where !usedStored.contains(storedEntry.index) && storedFilter(storedEntry) {
                guard let candidate = incoming.first(where: {
                    !usedIncoming.contains($0.index) && matches(storedEntry, $0)
                }) else { continue }
                usedStored.insert(storedEntry.index)
                usedIncoming.insert(candidate.index)
                pairs.append(Pair(incomingIndex: candidate.index, storedIndex: storedEntry.index))
            }
        }
    }
}
