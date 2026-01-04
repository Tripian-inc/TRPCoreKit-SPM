//
//  GeneralError.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.11.2025.
//

import Foundation

enum GeneralError: Error {
    case customMessage(String)
    case customMessageKey(String)
}

extension GeneralError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .customMessage(let message):
            return message
        case .customMessageKey(let key):
            return key
        }
    }
}
