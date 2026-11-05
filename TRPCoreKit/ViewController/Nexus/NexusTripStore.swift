//
//  NexusTripStore.swift
//  TRPCoreKit
//
//  Persists the Nexus-created timeline's tripHash so a subsequent reservations
//  open can RESUME it instead of always creating a fresh timeline (mirrors the
//  Android storedTripHash mechanism). Scoped per Tripian identity (the uniqueId
//  sent to light login), keyed in UserDefaults as `nexus_saved_trip_hash.<uniqueId>`.
//
//  `isNexusFlow` gates the persistence so only the Nexus entry stores a hash;
//  other hosts (e.g. Civitatis) are unaffected.
//

import Foundation

enum NexusTripStore {

    static let legacyKey = "nexus_saved_trip_hash"

    static var defaults: UserDefaults = .standard

    /// Set true by the Nexus coordinator entry; lets the shared create path persist
    /// the new tripHash without affecting other hosts.
    static var isNexusFlow = false

    /// Identity of the running Nexus session; `onTimelineCreated` stores under it.
    static var activeUniqueId: String?

    /// UserDefaults key for the given identity, or nil when the identity is missing.
    static func key(for uniqueId: String?) -> String? {
        guard let uniqueId, !uniqueId.isEmpty else { return nil }
        return "\(legacyKey).\(uniqueId)"
    }

    static func tripHash(for uniqueId: String?) -> String? {
        removeLegacyHash()
        guard let key = key(for: uniqueId) else { return nil }
        let value = defaults.string(forKey: key)
        return (value?.isEmpty == false) ? value : nil
    }

    static func setTripHash(_ tripHash: String?, for uniqueId: String?) {
        removeLegacyHash()
        guard let key = key(for: uniqueId) else { return }
        if let tripHash, !tripHash.isEmpty {
            defaults.set(tripHash, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    /// Called from the timeline create success — stores only during the Nexus flow.
    static func onTimelineCreated(_ tripHash: String) {
        guard isNexusFlow else { return }
        setTripHash(tripHash, for: activeUniqueId)
    }

    /// Forgets the identity's stored tripHash so its next open creates a fresh timeline.
    static func clear(for uniqueId: String?) {
        setTripHash(nil, for: uniqueId)
    }

    private static func removeLegacyHash() {
        if defaults.object(forKey: legacyKey) != nil {
            defaults.removeObject(forKey: legacyKey)
        }
    }
}
