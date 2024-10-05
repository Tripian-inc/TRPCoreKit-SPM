//
//  Bench.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-01-13.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import CoreFoundation
class BenchMark {

    private var startTime: CFAbsoluteTime?
    private var endTime: CFAbsoluteTime?

    init() {
        
    }

    func start() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    
    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()
        print("BenchMark: \(duration)")
        return duration!
    }

    var duration:CFAbsoluteTime? {
        if let startTime = startTime, let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}
