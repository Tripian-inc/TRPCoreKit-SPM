import Foundation

/// A piece of user-facing text: the key the host translates and the English used until it does.
public struct TRPBookingTextKey: Hashable, Sendable {
    public let key: String
    public let fallback: String

    public init(_ key: String, _ fallback: String) {
        self.key = key
        self.fallback = fallback
    }
}

/// Resolves the booking screens' text through the host's translations.
///
/// `localize` gets the key and its English fallback and returns what to show; the default returns
/// the fallback. `%@` and `%d` placeholders in a translation are filled in the order of the fallback's.
public struct TRPBookingText {

    public var localize: (_ key: String, _ fallback: String) -> String

    public init(localize: @escaping (_ key: String, _ fallback: String) -> String = { $1 }) {
        self.localize = localize
    }

    public static let `default` = TRPBookingText()

    func callAsFunction(_ key: TRPBookingTextKey) -> String {
        let value = localize(key.key, key.fallback)
        return value.isEmpty || value == key.key ? key.fallback : value
    }

    func callAsFunction(_ key: TRPBookingTextKey, _ arguments: CVarArg...) -> String {
        String(format: self(key), arguments: arguments)
    }
}

extension TRPBookingTextKey {

    /// Every key the booking screens use, for publishing them to the cms.
    public static var all: [TRPBookingTextKey] {
        [bookTitle, myBookingsTitle, close, continueAction, done, retry, cancel, loading, errorTitle,
         chooseDate, chooseTime, chooseRate, chooseOption, chooseTickets, chooseQuantity, travellers, details,
         summary, pay, payNow, total, subtotal, serviceFee, tax, date, time, seatsLeft, unlimitedSeats, fromPrice,
         soldOut, noAvailability, holdExpiresIn, holdExpired, leaveTitle, leaveMessage, leaveConfirm, stay,
         requiredField, optionalSuffix, contact, traveller, pickup, dropoff, pickupPoint, meetAtDeparture,
         pickupNote, languageGuide, firstName, lastName, email, phone, fullName, street, extendedAddress, city,
         region, postalCode, country, cancellationPolicy, successTitle, successMessage, pendingTitle,
         pendingMessage, failureTitle, reference, voucher, bookingsEmpty, refreshStatus, cancelBooking,
         cancelQuoteMessage, cancelQuoteNoRefund, cancelConfirm, cancelDone, statusHeld, statusCharged,
         statusConfirmed, statusPending, statusNeedsRefund, statusRefunded, statusCancelled, statusExpired,
         statusFailed, priceChanged, paymentTitle, ticketRow, ticketSection, ticketNotes, ageRange, perPerson,
         unit, selectValue, noChoice, free, chargedNotConfirmed, invalidEmail]
    }

    static let bookTitle = TRPBookingTextKey("booking_title", "Book")
    static let myBookingsTitle = TRPBookingTextKey("booking_my_bookings", "My bookings")
    static let close = TRPBookingTextKey("booking_close", "Close")
    static let continueAction = TRPBookingTextKey("booking_continue", "Continue")
    static let done = TRPBookingTextKey("booking_done", "Done")
    static let retry = TRPBookingTextKey("booking_retry", "Try again")
    static let cancel = TRPBookingTextKey("booking_cancel", "Cancel")
    static let loading = TRPBookingTextKey("booking_loading", "Loading…")
    static let errorTitle = TRPBookingTextKey("booking_error_title", "Something went wrong")
    static let chooseDate = TRPBookingTextKey("booking_choose_date", "Choose a date")
    static let chooseTime = TRPBookingTextKey("booking_choose_time", "Choose a time")
    static let chooseRate = TRPBookingTextKey("booking_choose_rate", "Choose a rate")
    static let chooseOption = TRPBookingTextKey("booking_choose_option", "Choose an option")
    static let chooseTickets = TRPBookingTextKey("booking_choose_tickets", "Choose tickets")
    static let chooseQuantity = TRPBookingTextKey("booking_choose_quantity", "How many tickets?")
    static let travellers = TRPBookingTextKey("booking_travellers", "Travellers")
    static let details = TRPBookingTextKey("booking_details", "Your details")
    static let summary = TRPBookingTextKey("booking_summary", "Summary")
    static let pay = TRPBookingTextKey("booking_pay", "Pay %@")
    static let payNow = TRPBookingTextKey("booking_pay_now", "Pay now")
    static let total = TRPBookingTextKey("booking_total", "Total")
    static let subtotal = TRPBookingTextKey("booking_subtotal", "Subtotal")
    static let serviceFee = TRPBookingTextKey("booking_service_fee", "Service fee")
    static let tax = TRPBookingTextKey("booking_tax", "Tax")
    static let date = TRPBookingTextKey("booking_date", "Date")
    static let time = TRPBookingTextKey("booking_time", "Time")
    static let seatsLeft = TRPBookingTextKey("booking_seats_left", "%d left")
    static let unlimitedSeats = TRPBookingTextKey("booking_unlimited_seats", "Available")
    static let fromPrice = TRPBookingTextKey("booking_from_price", "From %@")
    static let soldOut = TRPBookingTextKey("booking_sold_out", "Sold out")
    static let noAvailability = TRPBookingTextKey("booking_no_availability", "There is no availability for the coming days.")
    static let holdExpiresIn = TRPBookingTextKey("booking_hold_expires_in", "Reserved for %@")
    static let holdExpired = TRPBookingTextKey("booking_hold_expired", "The reservation expired. Please start again.")
    static let leaveTitle = TRPBookingTextKey("booking_leave_title", "Leave booking?")
    static let leaveMessage = TRPBookingTextKey("booking_leave_message", "Your selection will be lost.")
    static let leaveConfirm = TRPBookingTextKey("booking_leave_confirm", "Leave")
    static let stay = TRPBookingTextKey("booking_stay", "Stay")
    static let requiredField = TRPBookingTextKey("booking_required_field", "%@ is required.")
    static let optionalSuffix = TRPBookingTextKey("booking_optional_suffix", "(optional)")
    static let contact = TRPBookingTextKey("booking_contact", "Contact")
    static let traveller = TRPBookingTextKey("booking_traveller", "Traveller %d")
    static let pickup = TRPBookingTextKey("booking_pickup", "Pickup")
    static let dropoff = TRPBookingTextKey("booking_dropoff", "Drop-off")
    static let pickupPoint = TRPBookingTextKey("booking_pickup_point", "Pickup point")
    static let meetAtDeparture = TRPBookingTextKey("booking_meet_at_departure", "I'll meet at the departure point")
    static let pickupNote = TRPBookingTextKey("booking_pickup_note", "Pickup address or note")
    static let languageGuide = TRPBookingTextKey("booking_language_guide", "Tour language")
    static let firstName = TRPBookingTextKey("booking_first_name", "First name")
    static let lastName = TRPBookingTextKey("booking_last_name", "Last name")
    static let email = TRPBookingTextKey("booking_email", "Email")
    static let phone = TRPBookingTextKey("booking_phone", "Phone")
    static let fullName = TRPBookingTextKey("booking_full_name", "Full name")
    static let street = TRPBookingTextKey("booking_street", "Street address")
    static let extendedAddress = TRPBookingTextKey("booking_extended_address", "Apartment, suite")
    static let city = TRPBookingTextKey("booking_city", "City")
    static let region = TRPBookingTextKey("booking_region", "State or region")
    static let postalCode = TRPBookingTextKey("booking_postal_code", "Postal code")
    static let country = TRPBookingTextKey("booking_country", "Country code (e.g. US)")
    static let cancellationPolicy = TRPBookingTextKey("booking_cancellation_policy", "Cancellation policy")
    static let successTitle = TRPBookingTextKey("booking_success_title", "You're booked")
    static let successMessage = TRPBookingTextKey("booking_success_message", "Your confirmation has been sent to your email.")
    static let pendingTitle = TRPBookingTextKey("booking_pending_title", "Booking requested")
    static let pendingMessage = TRPBookingTextKey("booking_pending_message", "The supplier will confirm shortly. You can follow it in My bookings.")
    static let failureTitle = TRPBookingTextKey("booking_failure_title", "Booking failed")
    static let reference = TRPBookingTextKey("booking_reference", "Reference")
    static let voucher = TRPBookingTextKey("booking_voucher", "View voucher")
    static let bookingsEmpty = TRPBookingTextKey("booking_bookings_empty", "You have no bookings yet.")
    static let refreshStatus = TRPBookingTextKey("booking_refresh_status", "Refresh status")
    static let cancelBooking = TRPBookingTextKey("booking_cancel_booking", "Cancel booking")
    static let cancelQuoteMessage = TRPBookingTextKey("booking_cancel_quote_message", "You will get %@ back.")
    static let cancelQuoteNoRefund = TRPBookingTextKey("booking_cancel_quote_no_refund", "This booking is not refundable.")
    static let cancelConfirm = TRPBookingTextKey("booking_cancel_confirm", "Cancel booking")
    static let cancelDone = TRPBookingTextKey("booking_cancel_done", "The booking was cancelled.")
    static let statusHeld = TRPBookingTextKey("booking_status_held", "Reserved")
    static let statusCharged = TRPBookingTextKey("booking_status_charged", "Processing")
    static let statusConfirmed = TRPBookingTextKey("booking_status_confirmed", "Confirmed")
    static let statusPending = TRPBookingTextKey("booking_status_pending", "Awaiting confirmation")
    static let statusNeedsRefund = TRPBookingTextKey("booking_status_needs_refund", "Refund in progress")
    static let statusRefunded = TRPBookingTextKey("booking_status_refunded", "Refunded")
    static let statusCancelled = TRPBookingTextKey("booking_status_cancelled", "Cancelled")
    static let statusExpired = TRPBookingTextKey("booking_status_expired", "Expired")
    static let statusFailed = TRPBookingTextKey("booking_status_failed", "Failed")
    static let priceChanged = TRPBookingTextKey("booking_price_changed", "The price has changed. Please review it before paying.")
    static let paymentTitle = TRPBookingTextKey("booking_payment_title", "Payment")
    static let ticketRow = TRPBookingTextKey("booking_ticket_row", "Row %@")
    static let ticketSection = TRPBookingTextKey("booking_ticket_section", "Section %@")
    static let ticketNotes = TRPBookingTextKey("booking_ticket_notes", "Notes")
    static let ageRange = TRPBookingTextKey("booking_age_range", "Age %@")
    static let perPerson = TRPBookingTextKey("booking_per_person", "%@ per person")
    static let unit = TRPBookingTextKey("booking_unit", "Unit")
    static let selectValue = TRPBookingTextKey("booking_select_value", "Select")
    static let noChoice = TRPBookingTextKey("booking_no_choice", "None")
    static let free = TRPBookingTextKey("booking_free", "Free")
    static let chargedNotConfirmed = TRPBookingTextKey("booking_charged_not_confirmed", "You were charged but the supplier did not confirm. The payment will be refunded.")
    static let invalidEmail = TRPBookingTextKey("booking_invalid_email", "Enter a valid email address.")
}
