//
//  NexusReservationDTO.swift
//  TRPCoreKit
//
//  Nexus reservation payload (the web app's TripService plus the transformed
//  fields it appends — full detailURL, lower-cased aliases). Consumed only by
//  NexusItineraryBuilder to build a TRPItineraryWithActivities. Mirrors the
//  Android NexusReservationDto. Unknown keys are ignored by Codable.
//

import Foundation

struct NexusReservationDTO: Codable {
    let date: String?
    let detailUrlRelative: String?
    let locator: String?
    let title: String?
    let paxAdults: Int?
    let paxChildren: Int?
    let paxBabies: Int?
    let nexusBookingInformation: NexusBookingInformationDTO?
    let amountClient: Double?
    let currencyClient: String?

    // Transformed fields appended by the web app (front useTripianActivity).
    let detailURL: String?
    let meetingPointAlias: String?
    let locatorAlias: String?

    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case detailUrlRelative = "DetailUrl"
        case locator = "Locator"
        case title = "Title"
        case paxAdults = "PaxAdults"
        case paxChildren = "PaxChildren"
        case paxBabies = "PaxBabies"
        case nexusBookingInformation = "NexusBookingInformation"
        case amountClient = "AmountClient"
        case currencyClient = "CurrencyClient"
        case detailURL
        case meetingPointAlias = "meetingPoint"
        case locatorAlias = "locator"
    }

    struct NexusBookingInformationDTO: Codable {
        let coverImageUrl: String?
        let description: String?
        let cancellationPolicyDescription: String?

        enum CodingKeys: String, CodingKey {
            case coverImageUrl = "CoverImageUrl"
            case description = "Description"
            case cancellationPolicyDescription = "CancellationPolicyDescription"
        }
    }
}
