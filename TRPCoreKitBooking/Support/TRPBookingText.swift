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
        [bookTitle, myBookingsTitle, close, done, back, retry, cancel, loading, processing, errorTitle, chooseDate,
         chooseOption, noOptions, travellers, traveller, total, date, time, stepProgress, stepIndex, holdExpiresIn, holdExpired,
         extendHold, leaveTitle, leaveMessage, leaveConfirm, stay, required, invalidValue, invalidEmail, quantityTotal,
         optionalSuffix, selectValue, orTypeIt, priceChanged, soldOutMessage, stepChanged, paymentDeclined,
         unavailable, awaitingConfirmation, continueOnWeb, paymentTitle, successTitle, successMessage, pendingTitle,
         pendingMessage, failureTitle, reference, voucher, meetingPoint, cancellationPolicy, cancelUntil, refund,
         bookingsEmpty, loadMore, refreshStatus, cancelBooking, cancelQuoteMessage, cancelQuoteNoRefund, cancelConfirm,
         cancelDone, notCancellable, statusOnHold, statusConfirmed, statusPending, statusExpired, statusCancelled,
         statusRejected, paymentCanceledTitle, paymentCanceledMessage, hostedCheckoutDone]
    }

    static let bookTitle = TRPBookingTextKey("booking_title", "Book")
    static let myBookingsTitle = TRPBookingTextKey("booking_my_bookings", "My bookings")
    static let close = TRPBookingTextKey("booking_close", "Close")
    static let done = TRPBookingTextKey("booking_done", "Done")
    static let back = TRPBookingTextKey("booking_back", "Back")
    static let retry = TRPBookingTextKey("booking_retry", "Try again")
    static let cancel = TRPBookingTextKey("booking_cancel", "Cancel")
    static let loading = TRPBookingTextKey("booking_loading", "Loading…")
    static let processing = TRPBookingTextKey("booking_processing", "Confirming your booking…")
    static let errorTitle = TRPBookingTextKey("booking_error_title", "Something went wrong")
    static let chooseDate = TRPBookingTextKey("booking_choose_date", "Choose a date")
    static let chooseOption = TRPBookingTextKey("booking_choose_option", "Choose an option")
    static let noOptions = TRPBookingTextKey("booking_no_options", "Nothing is available to choose right now.")
    static let travellers = TRPBookingTextKey("booking_travellers", "Travellers")
    static let traveller = TRPBookingTextKey("booking_traveller", "Traveller %d")
    static let total = TRPBookingTextKey("booking_total", "Total")
    static let date = TRPBookingTextKey("booking_date", "Date")
    static let time = TRPBookingTextKey("booking_time", "Time")
    static let stepProgress = TRPBookingTextKey("booking_step_progress", "Step %d of %d")
    static let stepIndex = TRPBookingTextKey("booking_step_index", "Step %d")
    static let holdExpiresIn = TRPBookingTextKey("booking_hold_expires_in", "Reserved for %@")
    static let holdExpired = TRPBookingTextKey("booking_hold_expired", "The reservation expired. Please start again.")
    static let extendHold = TRPBookingTextKey("booking_extend_hold", "Keep my reservation")
    static let leaveTitle = TRPBookingTextKey("booking_leave_title", "Leave booking?")
    static let leaveMessage = TRPBookingTextKey("booking_leave_message", "Your selection will be lost.")
    static let leaveConfirm = TRPBookingTextKey("booking_leave_confirm", "Leave")
    static let stay = TRPBookingTextKey("booking_stay", "Stay")
    static let required = TRPBookingTextKey("booking_required", "This is required.")
    static let invalidValue = TRPBookingTextKey("booking_invalid_value", "Check this value.")
    static let invalidEmail = TRPBookingTextKey("booking_invalid_email", "Enter a valid email address.")
    static let quantityTotal = TRPBookingTextKey("booking_quantity_total", "Choose between %d and %d.")
    static let optionalSuffix = TRPBookingTextKey("booking_optional_suffix", "(optional)")
    static let selectValue = TRPBookingTextKey("booking_select_value", "Select")
    static let orTypeIt = TRPBookingTextKey("booking_or_type_it", "Or type it")
    static let priceChanged = TRPBookingTextKey("booking_price_changed", "The price has changed. Please review it before paying.")
    static let soldOutMessage = TRPBookingTextKey("booking_sold_out_message", "This is no longer available. Please choose something else.")
    static let stepChanged = TRPBookingTextKey("booking_step_changed", "Your booking moved on. Please check this step.")
    static let paymentDeclined = TRPBookingTextKey("booking_payment_declined", "The payment was declined. Please try another card.")
    static let unavailable = TRPBookingTextKey("booking_unavailable", "The booking service is not available right now. Please try again.")
    static let awaitingConfirmation = TRPBookingTextKey("booking_awaiting_confirmation", "The supplier is still confirming. You can check again, or follow it in My bookings.")
    static let continueOnWeb = TRPBookingTextKey("booking_continue_on_web", "Continue on the web")
    static let paymentTitle = TRPBookingTextKey("booking_payment_title", "Payment")
    static let paymentCanceledTitle = TRPBookingTextKey("booking_payment_canceled_title", "Payment not completed")
    static let paymentCanceledMessage = TRPBookingTextKey("booking_payment_canceled_message", "You closed the payment before it finished. You can try again or cancel the booking.")
    static let hostedCheckoutDone = TRPBookingTextKey("booking_hosted_checkout_done", "Done")
    static let successTitle = TRPBookingTextKey("booking_success_title", "You're booked")
    static let successMessage = TRPBookingTextKey("booking_success_message", "Your confirmation has been sent to your email.")
    static let pendingTitle = TRPBookingTextKey("booking_pending_title", "Booking requested")
    static let pendingMessage = TRPBookingTextKey("booking_pending_message", "The supplier will confirm shortly. You can follow it in My bookings.")
    static let failureTitle = TRPBookingTextKey("booking_failure_title", "Booking failed")
    static let reference = TRPBookingTextKey("booking_reference", "Reference")
    static let voucher = TRPBookingTextKey("booking_voucher", "View voucher")
    static let meetingPoint = TRPBookingTextKey("booking_meeting_point", "Meeting point")
    static let cancellationPolicy = TRPBookingTextKey("booking_cancellation_policy", "Cancellation policy")
    static let cancelUntil = TRPBookingTextKey("booking_cancel_until", "Free cancellation until %@")
    static let refund = TRPBookingTextKey("booking_refund", "Refund")
    static let bookingsEmpty = TRPBookingTextKey("booking_bookings_empty", "You have no bookings yet.")
    static let loadMore = TRPBookingTextKey("booking_load_more", "Load more")
    static let refreshStatus = TRPBookingTextKey("booking_refresh_status", "Refresh status")
    static let cancelBooking = TRPBookingTextKey("booking_cancel_booking", "Cancel booking")
    static let cancelQuoteMessage = TRPBookingTextKey("booking_cancel_quote_message", "You will get %@ back.")
    static let cancelQuoteNoRefund = TRPBookingTextKey("booking_cancel_quote_no_refund", "This booking is not refundable.")
    static let cancelConfirm = TRPBookingTextKey("booking_cancel_confirm", "Cancel booking")
    static let cancelDone = TRPBookingTextKey("booking_cancel_done", "The booking was cancelled.")
    static let notCancellable = TRPBookingTextKey("booking_not_cancellable", "This booking can no longer be cancelled.")
    static let statusOnHold = TRPBookingTextKey("booking_status_on_hold", "Reserved")
    static let statusConfirmed = TRPBookingTextKey("booking_status_confirmed", "Confirmed")
    static let statusPending = TRPBookingTextKey("booking_status_pending", "Awaiting confirmation")
    static let statusExpired = TRPBookingTextKey("booking_status_expired", "Expired")
    static let statusCancelled = TRPBookingTextKey("booking_status_cancelled", "Cancelled")
    static let statusRejected = TRPBookingTextKey("booking_status_rejected", "Not confirmed")
}
