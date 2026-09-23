//
//  TRPUnauthorizedRetrier.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Sends a call again after renewing the session when it fails with 401. Calls that fail together
/// share a single refresh, each is sent once more, and a second 401 goes back to the caller.
/// Without a `refresher` it only passes calls through, so nothing changes until a host opts in.
public final class TRPUnauthorizedRetrier {

    public static let shared = TRPUnauthorizedRetrier()

    public var refresher: TRPTokenRefreshing?

    private let lock = NSLock()
    private var isRefreshing = false
    private var waitingForRefresh: [(Error?) -> Void] = []

    public init(refresher: TRPTokenRefreshing? = nil) {
        self.refresher = refresher
    }

    /// - Parameters:
    ///   - retriesOnUnauthorized: false for calls whose 401 a refresh cannot fix, such as login
    ///     or the refresh itself.
    ///   - call: starts the request and reports its result to the closure it is given.
    public func send<Value>(retriesOnUnauthorized: Bool = true,
                            _ call: @escaping (@escaping (Result<Value, Error>) -> Void) -> Void,
                            completion: @escaping (Result<Value, Error>) -> Void) {
        call { result in
            guard retriesOnUnauthorized,
                  self.refresher != nil,
                  case .failure(let error) = result,
                  Self.isUnauthorized(error) else {
                completion(result)
                return
            }
            self.refreshOnce { refreshError in
                if let refreshError = refreshError {
                    completion(.failure(refreshError))
                } else {
                    self.send(retriesOnUnauthorized: false, call, completion: completion)
                }
            }
        }
    }

    private func refreshOnce(_ completion: @escaping (Error?) -> Void) {
        lock.lock()
        waitingForRefresh.append(completion)
        let alreadyRefreshing = isRefreshing
        isRefreshing = true
        lock.unlock()

        guard !alreadyRefreshing else { return }

        guard let refresher = refresher else {
            finishRefresh(with: nil)
            return
        }
        refresher.refreshToken { error in
            self.finishRefresh(with: error)
        }
    }

    private func finishRefresh(with error: Error?) {
        lock.lock()
        let waiting = waitingForRefresh
        waitingForRefresh = []
        isRefreshing = false
        lock.unlock()
        waiting.forEach { $0(error) }
    }

    private static func isUnauthorized(_ error: Error) -> Bool {
        return (error as NSError).code == 401
    }
}
