//
//  GYGTourOption.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
internal class GYGToursOptionParser: Decodable {
    
    public var options: [GYGTourOption]?
    
    private enum CodingKeys: String, CodingKey {
        case options = "tour_options"
    }
}

public struct GYGTourOption: Codable {
    public let optionID, tourID: Int
    public let title: String
    public let meetingPoint, pickUp, dropOff: String?
    public let duration: Float
    public let durationUnit: String
    public let condLanguage: GYGCondLanguage?
    public let bookingParameter: [GYGBookingParameter]
    public let services: [String: Bool]
    public let coordinateType: String
    public let coordinates: GYGCoordinates?
    public let price: GYGPrice?
    public let special: GYGSpecial?
    public let freeSale: Bool
    public let description: String?
    
    enum CodingKeys: String, CodingKey {
        case optionID = "option_id"
        case tourID = "tour_id"
        case title
        case meetingPoint = "meeting_point"
        case pickUp = "pick_up"
        case dropOff = "drop_off"
        case duration
        case durationUnit = "duration_unit"
        case condLanguage = "cond_language"
        case bookingParameter = "booking_parameter"
        case services
        case coordinates
        case coordinateType = "coordinate_type"
        case price
        case special
        case freeSale = "free_sale"
        case description
    }
}

// MARK: - BookingParameter
public struct GYGBookingParameter: Codable {
    public let name: String
    public let mandatory: Bool?
    public let description: String?

    enum CodingKeys: String, CodingKey {
        case name, mandatory
        case description
    }
}

public struct GYGCondLanguage: Codable {
    public let languageAudio: [String]
    public let languageBooklet, languageLive: [String]

    enum CodingKeys: String, CodingKey {
        case languageAudio = "language_audio"
        case languageBooklet = "language_booklet"
        case languageLive = "language_live"
    }
}
