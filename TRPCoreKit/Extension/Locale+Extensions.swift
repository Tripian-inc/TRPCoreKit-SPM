//
//  Locale+Extensions.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

extension Locale {

    /// This locale with Latin digits, so a date written for the api stays "2026-10-05" in
    /// languages such as Persian or Arabic; month and day names keep the locale's language.
    var withLatinDigits: Locale {
        let separator = identifier.contains("@") ? ";" : "@"
        return Locale(identifier: identifier + separator + "numbers=latn")
    }
}
