import Foundation
import TRPBookingKit

/// What a booking shows about cancelling: the terms that apply, the policy text and what tapping Cancel leads to.
struct BookingCancelPrompt {

    /// A confirmation carrying the refund text, or the message that the booking can no longer be cancelled.
    enum Outcome: Equatable {
        case confirm(message: String)
        case notCancellable(message: String)
    }

    let text: TRPBookingText
    var formatting = BookingFormatting()

    /// The terms as `client` quotes them now; the booking's stored terms when it cannot quote or the quote fails.
    static func cancellation(for booking: BookingContract.Booking,
                             client: BookingClient) async -> BookingContract.Booking.Cancellation {
        guard let quoting = client as? BookingCancellationQuoting else { return booking.cancellation }
        return (try? await quoting.cancellationQuote(uuid: booking.uuid)) ?? booking.cancellation
    }

    /// `booking` carrying `cancellation` in place of its own.
    static func booking(_ booking: BookingContract.Booking,
                        with cancellation: BookingContract.Booking.Cancellation) -> BookingContract.Booking {
        booking.with(cancellation: cancellation)
    }

    func outcome(for booking: BookingContract.Booking, cancellation: BookingContract.Booking.Cancellation) -> Outcome {
        guard cancellation.allowed else { return .notCancellable(message: text(.notCancellable)) }
        return .confirm(message: refund(for: booking, cancellation: cancellation))
    }

    /// The deadline and refund lines, or nil while cancelling is not allowed.
    func policy(for booking: BookingContract.Booking, cancellation: BookingContract.Booking.Cancellation) -> String? {
        guard cancellation.allowed else { return nil }
        var parts: [String] = []
        if let deadline = cancellation.deadline.flatMap(CheckoutDeadline.date(from:)) {
            parts.append(text(.cancelUntil, DateFormatter.localizedString(from: deadline, dateStyle: .medium, timeStyle: .short)))
        }
        parts.append(refund(for: booking, cancellation: cancellation))
        return parts.joined(separator: "\n")
    }

    func refund(for booking: BookingContract.Booking, cancellation: BookingContract.Booking.Cancellation) -> String {
        switch cancellation.refund.value {
        case .none: return text(.cancelQuoteNoRefund)
        case .full: return text(.cancelQuoteMessage, formatting.price(booking.amount) ?? booking.amount.amount)
        case .partial, .unknown:
            guard let amount = formatting.price(cancellation.refundAmount) else { return text(.cancelQuoteNoRefund) }
            return text(.cancelQuoteMessage, amount)
        }
    }
}
