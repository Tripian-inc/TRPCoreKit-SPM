//
//  TRPTokenRefreshing.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Renews the session when the api answers 401. The host app implements it, since only the host
/// knows how its users sign in, and hands it to `TRPUnauthorizedRetrier`.
public protocol TRPTokenRefreshing: AnyObject {

    /// Obtains a fresh token and saves it where TRPRestKit reads it (`TRPRestKit().saveToken`)
    /// before calling `completion`, with nil on success or the reason it failed.
    func refreshToken(completion: @escaping (Error?) -> Void)
}
