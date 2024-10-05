//
//  ButterflyCellStatus.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 5.05.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


public class ButterflyCellStatus {
    
    public var step: TRPStep
    public var isUninterest: Bool = false
    public var isLiked: Bool = false
    public var isProgress: Bool = false
    public var reactionId: Int?
    
    init(step: TRPStep, isUninterest: Bool = false) {
        self.step = step
        self.isUninterest = isUninterest
    }
    
}

extension ButterflyCellStatus: Equatable {
    public static func == (lhs: ButterflyCellStatus, rhs: ButterflyCellStatus) -> Bool {
        return lhs.step.id == rhs.step.id
    }
}
