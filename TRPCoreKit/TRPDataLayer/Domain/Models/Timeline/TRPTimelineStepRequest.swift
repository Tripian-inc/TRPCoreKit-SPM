//
//  TRPTimelineCreateStep.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 20.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import TRPFoundationKit

public struct TRPTimelineStepCreate {
    var planId: Int
    var poiId: String?
    var stepType: String?
    var customPoi: TRPTimelineStepCustomPoi?
    var startTime: String?
    var endTime: String?
    var order: Int?
}

public struct TRPTimelineStepEdit {
    var stepId: Int
    var poiId: String?
    var stepType: String?
    var customPoi: TRPTimelineStepCustomPoi?
    var startTime: String?
    var endTime: String?
    var order: Int?
}

public struct TRPTimelineStepCustomPoi {
    var name: String?
    var coordinate: TRPLocation?
    var address: String?
    var description: String?
    var tags: [String]?
    var phone: String?
    var web: String?
    var categoryId: Int?
    
    public init(name: String? = nil, coordinate: TRPLocation? = nil, address: String? = nil, description: String? = nil, tags: [String]? = nil, phone: String? = nil, web: String? = nil, categoryId: Int? = nil) {
        self.name = name
        self.coordinate = coordinate
        self.address = address
        self.description = description
        self.tags = tags
        self.phone = phone
        self.web = web
        self.categoryId = categoryId
    }
}
