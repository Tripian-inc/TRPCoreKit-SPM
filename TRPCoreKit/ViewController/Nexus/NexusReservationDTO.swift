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
    let productId: Int?
    let bookingId: String?
    let destinationId: Int?
    let detailUrlRelative: String?
    let locator: String?
    let title: String?
    let paxAdults: Int?
    let paxChildren: Int?
    let paxBabies: Int?
    let nexusBookingInformation: NexusBookingInformationDTO?
    let amountClient: Double?
    let currencyClient: String?
    let meetingTimeAssigned: Bool?

    // Transformed fields appended by the web app (front useTripianActivity).
    let detailURL: String?
    let meetingPointAlias: String?
    let locatorAlias: String?
    let productIdAlias: Int?
    let bookingIdAlias: String?
    let destinationIdAlias: Int?

    /// Catalogue product id as a non-empty string, or nil when the host sent none.
    var catalogueProductId: String? {
        (productId ?? productIdAlias).flatMap { $0 > 0 ? String($0) : nil }
    }

    /// Juniper zone id as a non-empty string, or nil when the host sent none.
    var zoneId: String? {
        (destinationId ?? destinationIdAlias).flatMap { $0 > 0 ? String($0) : nil }
    }

    /// Juniper line id of the booked service.
    var juniperLineId: String? {
        (bookingId ?? bookingIdAlias).flatMap { $0.isEmpty ? nil : $0 }
    }

    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case productId = "ProductId"
        case bookingId = "BookingId"
        case destinationId = "DestinationId"
        case detailUrlRelative = "DetailUrl"
        case locator = "Locator"
        case title = "Title"
        case paxAdults = "PaxAdults"
        case paxChildren = "PaxChildren"
        case paxBabies = "PaxBabies"
        case nexusBookingInformation = "NexusBookingInformation"
        case amountClient = "AmountClient"
        case currencyClient = "CurrencyClient"
        case meetingTimeAssigned = "MeetingTimeAssigned"
        case detailURL
        case meetingPointAlias = "meetingPoint"
        case locatorAlias = "locator"
        case productIdAlias = "productId"
        case bookingIdAlias = "bookingId"
        case destinationIdAlias = "destinationId"
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
