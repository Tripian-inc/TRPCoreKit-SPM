//
//  TRPDisabledControlAwareTapDelegate.swift
//  TRPCoreKit
//
//  Shared `UIGestureRecognizerDelegate` that prevents a tap gesture from firing when the
//  underlying touch landed on a disabled `UIControl` (e.g. past-day action buttons that
//  are `isEnabled = false`). Without this, taps on a disabled button still fall through
//  to a parent view's tap gesture even though the button itself swallows the action.
//
//  Usage:
//      tapGesture.delegate = TRPDisabledControlAwareTapDelegate.shared
//

import UIKit

final class TRPDisabledControlAwareTapDelegate: NSObject, UIGestureRecognizerDelegate {

    /// Singleton — `UIGestureRecognizer.delegate` is weak, so we need a long-lived object.
    static let shared = TRPDisabledControlAwareTapDelegate()

    private override init() { super.init() }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                            shouldReceive touch: UITouch) -> Bool {
        // Walk up the view chain from the hit view; if any ancestor is a disabled UIControl,
        // the user is effectively tapping a "greyed-out" button — silently swallow the tap.
        var view: UIView? = touch.view
        while let current = view {
            if let control = current as? UIControl, !control.isEnabled {
                return false
            }
            view = current.superview
        }
        return true
    }
}
