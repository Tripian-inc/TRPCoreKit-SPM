//
//  NetworkStatusManagerr.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 10.05.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation

class NetworkStatusManager: NSObject {
    
    public enum Connection {
        case none
        case wifi
        case cell
    }
    
    typealias ConnectionHandler = (_ connection: Connection) -> Void
    
    static let shared: NetworkStatusManager = {
        return NetworkStatusManager()
    }()
    
    private var reachability: Reachability!
    public var connectionHandler: ConnectionHandler? = nil
    public var status: Connection = .none {
        didSet {
            connectionHandler?(status)
            NotificationCenter.default.post(name: .TRPNetworkStatusChanged, object: self, userInfo: ["status":status])
        }
    }
    
    override init() {
        super.init()
        reachability = Reachability()
        NotificationCenter.default.addObserver(self, selector: #selector(networkChanged(_:)), name: .reachabilityChanged, object: reachability!)
        do {
            try reachability.startNotifier()
        }catch let error as NSError {
//            Log.e("\(error.localizedDescription)")
        }
    }
    
    @objc func networkChanged(_ notification: Notification) {
        let connection = NetworkStatusManager.shared.reachability.connection
        var type: Connection
        switch connection {
        case .none:
            type = .none
        case .cellular:
            type = .cell
        case .wifi:
            type = .wifi
        }
        status = type
    }
    
    static func stopNotifier() {
        do {
            shared.reachability.stopNotifier()
        }
    }
    
    static func isReachable(completed: @escaping (NetworkStatusManager) -> Void) {
        if NetworkStatusManager.shared.reachability.connection != .none {
            completed(NetworkStatusManager.shared)
        }
    }
    
    static func unReachable(completed: @escaping (NetworkStatusManager) -> Void) {
        if NetworkStatusManager.shared.reachability.connection == .none {
            completed(NetworkStatusManager.shared)
        }
    }
    
    static func isReachableViaCell(completed: @escaping (NetworkStatusManager) -> Void) {
        if NetworkStatusManager.shared.reachability.connection == .cellular {
            completed(NetworkStatusManager.shared)
        }
    }
    
    static func isReachableViaWifi(completed: @escaping (NetworkStatusManager) -> Void) {
        if NetworkStatusManager.shared.reachability.connection == .wifi {
            completed(NetworkStatusManager.shared)
        }
    }
}
