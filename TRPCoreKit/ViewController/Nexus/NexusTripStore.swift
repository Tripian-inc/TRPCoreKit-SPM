//
//  NexusTripStore.swift
//  TRPCoreKit
//
//  Persists the Nexus-created timeline's tripHash so a subsequent reservations
//  open can RESUME it instead of always creating a fresh timeline (mirrors the
//  Android storedTripHash mechanism). Device-scoped (one Nexus trip at a time),
//  keyed in UserDefaults.
//
//  `isNexusFlow` gates the persistence so only the Nexus entry stores a hash;
//  other hosts (e.g. Civitatis) are unaffected.
//

import Foundation

enum NexusTripStore {

    private static let key = "nexus_saved_trip_hash"

    /// Set true by the Nexus coordinator entry; lets the shared create path persist
    /// the new tripHash without affecting other hosts.
    static var isNexusFlow = false

    static var tripHash: String? {
        get {
            let value = UserDefaults.standard.string(forKey: key)
            return (value?.isEmpty == false) ? value : nil
        }
        set {
            if let newValue = newValue, !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// Called from the timeline create success — stores only during the Nexus flow.
    static func onTimelineCreated(_ tripHash: String) {
        guard isNexusFlow else { return }
        self.tripHash = tripHash
    }
}
