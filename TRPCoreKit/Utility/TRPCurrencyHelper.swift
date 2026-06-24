//
//  TRPCurrencyHelper.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 03.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Centralized currency formatting utility.
/// Provides locale-aware currency formatting with proper symbol placement.
public struct TRPCurrencyHelper {

    // MARK: - Shared Formatter

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    // MARK: - Public Methods

    /// Format a floating point value with currency code
    /// - Parameters:
    ///   - value: The price value (Float or Double)
    ///   - currency: The currency code (e.g., "USD", "EUR", "TRY")
    /// - Returns: Formatted price string (e.g., "$45.00", "45,00 €")
    public static func formatPrice<T: BinaryFloatingPoint>(_ value: T, currency: String) -> String {
        let doubleValue = Double(value)
        formatter.currencyCode = currency

        if let formattedPrice = formatter.string(from: NSNumber(value: doubleValue)) {
            return formattedPrice
        }
        return "\(currency) \(String(format: "%.2f", doubleValue))"
    }

    /// Format an integer value with currency code
    /// - Parameters:
    ///   - value: The price value (Int)
    ///   - currency: The currency code (e.g., "USD", "EUR", "TRY")
    /// - Returns: Formatted price string (e.g., "$45.00", "45,00 €")
    public static func formatPrice<T: BinaryInteger>(_ value: T, currency: String) -> String {
        return formatPrice(Double(value), currency: currency)
    }
}
