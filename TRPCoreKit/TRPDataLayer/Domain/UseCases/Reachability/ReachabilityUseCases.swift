//
//  ReachabilityUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 2.01.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
public class ReachabilityUseCases {
    private init() {}
    private let reachability = Reachability()
    public static let shared = ReachabilityUseCases()
    
    public var isOnline: Bool {
        return self.reachability?.connection != Reachability.Connection.none
    }
    
    public func startMonitoring() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reachabilityChanged),
                                               name: Notification.Name.reachabilityChanged,
                                               object: reachability)
        
        reachability?.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("[Evren] Reachable via WiFi")
            } else {
                print("[Evren] Reachable via Cellular")
            }
        }
        reachability?.whenUnreachable = { _ in
            print("[Evren] Not reachable")
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            debugPrint("Could not start reachability notifier")
        }
    }
    
    public func stopMonitoring() {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.reachabilityChanged,
                                                  object: reachability)
    }
    
    @objc func reachabilityChanged(notification: Notification) {
        guard let reachability = notification.object as? Reachability else { return }
        print("[Evren] NetStatus: \(reachability.connection)")
    }
    
}

