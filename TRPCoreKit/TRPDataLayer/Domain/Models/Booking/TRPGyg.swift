//
//  TRPGyg.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 2020-12-30.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public class TRPGyg: Codable {
  
    public var tourName: String = ""
    public var description: String = ""
    public var image: String = ""
    public var dateTime: String = ""
    public var cityName: String = ""
    public var url: String = ""
    public var cancellation_policy_text: String = ""
    public var cancelUrl: String = ""
    public var ticketUrl: String = ""
    public var bookingHash: String = ""
}
