//
//  TRPProviderKeys.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

/// Map and places credentials a host app hands to the SDK, typically from its platform configuration.
/// A nil or empty value leaves the SDK on the matching Info.plist key.
public struct TRPProviderKeys: Equatable {
    public var mapboxAccessToken: String?
    public var googlePlacesApiKey: String?

    public init(mapboxAccessToken: String? = nil, googlePlacesApiKey: String? = nil) {
        self.mapboxAccessToken = mapboxAccessToken
        self.googlePlacesApiKey = googlePlacesApiKey
    }
}

/// Resolves the Mapbox token and Google Places key the SDK uses: a non-empty host-supplied value first,
/// the Info.plist value otherwise. `hostKeys` may be read and written from any thread.
final class TRPProviderKeyResolver {

    static let shared = TRPProviderKeyResolver()

    var hostKeys: TRPProviderKeys {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedHostKeys
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedHostKeys = newValue
        }
    }

    private let lock = NSLock()
    private var storedHostKeys = TRPProviderKeys()
    private let plistKey: (TRPApiKeys) -> String?

    init(plistKey: @escaping (TRPApiKeys) -> String? = { TRPApiKeyController.getKey($0) }) {
        self.plistKey = plistKey
    }

    func mapboxAccessToken() -> String? {
        return resolve(hostKeys.mapboxAccessToken, plist: .mglMapboxAccessToken)
    }

    func googlePlacesApiKey() -> String? {
        return resolve(hostKeys.googlePlacesApiKey, plist: .trpGooglePlace)
    }

    /// Both keys as the SDK uses them.
    func resolvedKeys() -> TRPProviderKeys {
        let keys = hostKeys
        return TRPProviderKeys(mapboxAccessToken: resolve(keys.mapboxAccessToken, plist: .mglMapboxAccessToken),
                               googlePlacesApiKey: resolve(keys.googlePlacesApiKey, plist: .trpGooglePlace))
    }

    /// Whether the host supplied a non-empty value for `key`, which then makes its Info.plist entry optional.
    func hasHostValue(for key: TRPApiKeys) -> Bool {
        switch key {
        case .mglMapboxAccessToken:
            return Self.nonEmpty(hostKeys.mapboxAccessToken) != nil
        case .trpGooglePlace:
            return Self.nonEmpty(hostKeys.googlePlacesApiKey) != nil
        default:
            return false
        }
    }

    private func resolve(_ hostValue: String?, plist key: TRPApiKeys) -> String? {
        return Self.nonEmpty(hostValue) ?? plistKey(key)
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
