//
//  UserTripLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol UserTimelineLocalStorage {
    func fetchMYTimeline(completion: @escaping (UserTimelineResultsValue) -> Void) 
}
