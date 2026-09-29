import TRPBookingKit

extension BookingRecordStatus {

    var textKey: TRPBookingTextKey {
        switch self {
        case .held: return .statusHeld
        case .charged: return .statusCharged
        case .confirmed: return .statusConfirmed
        case .pending: return .statusPending
        case .needsRefund: return .statusNeedsRefund
        case .refunded: return .statusRefunded
        case .cancelled: return .statusCancelled
        case .expired: return .statusExpired
        case .failed: return .statusFailed
        }
    }

    var isLive: Bool {
        self == .confirmed || self == .pending
    }
}
