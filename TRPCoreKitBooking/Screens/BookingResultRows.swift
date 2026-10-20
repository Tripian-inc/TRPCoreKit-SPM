import Foundation
import TRPBookingKit

/// The reference a customer quotes for a booking: the provider's own when it has one, else the booking uuid.
enum BookingReference {

    static func preferred(providerReference: String?, uuid: String?) -> String? {
        if let providerReference, !providerReference.isEmpty { return providerReference }
        guard let uuid, !uuid.isEmpty else { return nil }
        return uuid
    }
}

/// The rows the result screen shows for a finished checkout; `booking` is the booking it created, once loaded.
struct BookingResultRows {
    let checkout: BookingContract.Checkout
    let booking: BookingContract.Booking?

    func rows(text: TRPBookingText) -> [BookingSummaryRow] {
        var rows = [BookingSummaryRow(title: checkout.product.title, value: "")]
        if let amount = BookingFormatting().price(checkout.amount) {
            rows.append(BookingSummaryRow(title: text(.total), value: amount))
        }
        let uuid = checkout.booking?.uuid ?? checkout.result?.bookingUuid ?? booking?.uuid
        if let reference = BookingReference.preferred(providerReference: booking?.providerReference, uuid: uuid) {
            rows.append(BookingSummaryRow(title: text(.reference), value: reference))
        }
        return rows
    }
}
