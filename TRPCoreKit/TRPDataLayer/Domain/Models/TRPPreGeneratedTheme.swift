//
//  TRPTheme.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 18.02.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
public enum TRPPreGeneratedTheme: String, CaseIterable, Codable {
    case art = "art"
    case historyBuffs = "history_buffs"
    case foodies = "foodies"
    case instagram = "instagram"
    case outdoor = "outdoor"
    case noTheme = ""
    
    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case TRPPreGeneratedTheme.historyBuffs.rawValue:
            self = .historyBuffs
        case TRPPreGeneratedTheme.art.rawValue:
            self = .art
        case TRPPreGeneratedTheme.foodies.rawValue:
            self = .foodies
        case TRPPreGeneratedTheme.instagram.rawValue:
            self = .instagram
        case TRPPreGeneratedTheme.outdoor.rawValue:
            self = .outdoor
        default:
            self = .noTheme
        }
    }
    
    public func displayName() -> String {
        switch self {
        case .historyBuffs:
            return "History buffs"
        case .art:
            return "Art lovers"
        case .foodies:
            return "Foodies"
        case .instagram:
            return "Instagram"
        case .outdoor:
            return "Outdoor"
        default:
            return "Your Perfect Day"
        }
    }
    
    public func getImageName() -> String? {
        switch self {
        case .historyBuffs:
            return "theme_history"
        case .art:
            return "theme_art"
        case .foodies:
            return "theme_food"
        case .instagram:
            return "theme_insta"
        case .outdoor:
            return "theme_outdoor"
        case .noTheme:
            return "theme_history"
        }
    }
}
