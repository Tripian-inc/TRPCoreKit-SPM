//
//  ReadableDistance.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 7.10.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
class ReadableDistance {
    
    public static func calculate(distance:Float, time:TimeInterval) -> (distance: Float, time: Int) {
        let myDistance = Float(distance / 1000)
        let readableDistance = Float(round(10 * myDistance)/10)
        let readableTime = Int(time / 60)
        return (distance: readableDistance, time:readableTime)
    }
    
}
