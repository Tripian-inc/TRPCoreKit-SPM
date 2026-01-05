//
//  TRPTourSchedule.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPTourScheduleSlot: Codable {
    public let time: String

    public init(time: String) {
        self.time = time
    }
}

public struct TRPTourSchedule: Codable {
    public let title: String
    public let slots: [TRPTourScheduleSlot]

    public init(title: String, slots: [TRPTourScheduleSlot]) {
        self.title = title
        self.slots = slots
    }
}
