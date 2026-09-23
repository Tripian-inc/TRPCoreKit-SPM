//
//  TRPPastDayActionStyle.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

/// How a timeline row's actions behave on a day that has already passed.
/// Reservation CTAs are hidden in every style.
public enum TRPPastDayActionStyle {
    /// Change-time is hidden; the item can still be removed.
    case removalOnly
    /// Change-time and remove stay visible, greyed out, and ignore taps.
    case readOnly

    var allowsRemoval: Bool {
        return self == .removalOnly
    }

    func apply(changeTime: [UIButton], remove: [UIButton], reservation: [UIButton]) {
        reservation.forEach { $0.isHidden = true }
        switch self {
        case .removalOnly:
            changeTime.forEach { $0.isHidden = true }
        case .readOnly:
            (changeTime + remove).forEach { $0.setPastDayDisabled(true, originalTint: ColorSet.primary.uiColor) }
        }
    }

    /// Undoes `apply` on a reused row.
    func reset(changeTime: [UIButton], remove: [UIButton], reservation: [UIButton]) {
        (reservation + changeTime).forEach { $0.isHidden = false }
        (changeTime + remove).forEach { $0.setPastDayDisabled(false, originalTint: ColorSet.primary.uiColor) }
    }
}
