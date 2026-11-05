import Foundation
import Testing
@testable import TRPCoreKit

/// Test suite for NexusTripStore's per-identity scoping, legacy-key migration
/// and the isNexusFlow/activeUniqueId gate on onTimelineCreated.
/// Serialized because every test swaps the shared static `NexusTripStore.defaults`
/// (and `isNexusFlow`/`activeUniqueId`), which is not safe under Swift Testing's
/// default parallel execution.
@Suite("Nexus Trip Store Tests", .serialized)
struct NexusTripStoreTests {

    private func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "NexusTripStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let previousDefaults = NexusTripStore.defaults
        let previousIsNexusFlow = NexusTripStore.isNexusFlow
        let previousActiveUniqueId = NexusTripStore.activeUniqueId
        NexusTripStore.defaults = defaults
        defer {
            NexusTripStore.defaults = previousDefaults
            NexusTripStore.isNexusFlow = previousIsNexusFlow
            NexusTripStore.activeUniqueId = previousActiveUniqueId
            defaults.removePersistentDomain(forName: suiteName)
        }
        body(defaults)
    }

    @Test("Two identities store independent trip hashes")
    func testTwoIdentitiesAreIndependent() {
        withIsolatedDefaults { _ in
            NexusTripStore.setTripHash("hash-a", for: "user-a")
            NexusTripStore.setTripHash("hash-b", for: "user-b")

            #expect(NexusTripStore.tripHash(for: "user-a") == "hash-a")
            #expect(NexusTripStore.tripHash(for: "user-b") == "hash-b")
        }
    }

    @Test("Clearing one identity does not affect the other")
    func testClearOnlyAffectsItsOwnIdentity() {
        withIsolatedDefaults { _ in
            NexusTripStore.setTripHash("hash-a", for: "user-a")
            NexusTripStore.setTripHash("hash-b", for: "user-b")

            NexusTripStore.clear(for: "user-a")

            #expect(NexusTripStore.tripHash(for: "user-a") == nil)
            #expect(NexusTripStore.tripHash(for: "user-b") == "hash-b")
        }
    }

    @Test("Setting an empty hash removes the stored value")
    func testSettingEmptyHashRemovesStoredValue() {
        withIsolatedDefaults { _ in
            NexusTripStore.setTripHash("hash-a", for: "user-a")
            NexusTripStore.setTripHash("", for: "user-a")

            #expect(NexusTripStore.tripHash(for: "user-a") == nil)
        }
    }

    @Test("A legacy unscoped value is ignored and removed on first access")
    func testLegacyUnscopedKeyIsIgnoredAndRemoved() {
        withIsolatedDefaults { defaults in
            defaults.set("legacy-hash", forKey: NexusTripStore.legacyKey)

            #expect(NexusTripStore.tripHash(for: "user-a") == nil)
            #expect(defaults.object(forKey: NexusTripStore.legacyKey) == nil)
        }
    }

    @Test("A legacy unscoped value is removed even without an identity")
    func testLegacyUnscopedKeyIsRemovedWithoutAnIdentity() {
        withIsolatedDefaults { defaults in
            defaults.set("legacy-hash", forKey: NexusTripStore.legacyKey)

            #expect(NexusTripStore.tripHash(for: nil) == nil)
            #expect(defaults.object(forKey: NexusTripStore.legacyKey) == nil)
        }
    }

    @Test("A nil identity stores and returns nothing")
    func testNilIdentityStoresNothing() {
        withIsolatedDefaults { _ in
            NexusTripStore.setTripHash("hash", for: nil)

            #expect(NexusTripStore.tripHash(for: nil) == nil)
            #expect(NexusTripStore.key(for: nil) == nil)
        }
    }

    @Test("An empty identity stores and returns nothing")
    func testEmptyIdentityStoresNothing() {
        withIsolatedDefaults { _ in
            NexusTripStore.setTripHash("hash", for: "")

            #expect(NexusTripStore.tripHash(for: "") == nil)
            #expect(NexusTripStore.key(for: "") == nil)
        }
    }

    @Test("onTimelineCreated stores under the active identity only during the Nexus flow")
    func testOnTimelineCreatedRespectsIsNexusFlowAndActiveUniqueId() {
        withIsolatedDefaults { _ in
            NexusTripStore.isNexusFlow = false
            NexusTripStore.activeUniqueId = "user-a"

            NexusTripStore.onTimelineCreated("hash-while-not-nexus")
            #expect(NexusTripStore.tripHash(for: "user-a") == nil)

            NexusTripStore.isNexusFlow = true
            NexusTripStore.onTimelineCreated("hash-a")
            #expect(NexusTripStore.tripHash(for: "user-a") == "hash-a")

            NexusTripStore.activeUniqueId = "user-b"
            NexusTripStore.onTimelineCreated("hash-b")
            #expect(NexusTripStore.tripHash(for: "user-a") == "hash-a")
            #expect(NexusTripStore.tripHash(for: "user-b") == "hash-b")
        }
    }
}
