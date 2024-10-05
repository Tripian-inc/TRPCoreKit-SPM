//
//  GYGCatalogCategoryIds.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 14.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public enum GYGCatalogCategory: String, CaseIterable {
  
    case adventure = "Adventure"
    case food = "Food"
    case cultureAndHistory = "Culture and History"
    case sightseeing = "Sightseeing"
    case artAndMuseums = "Art and Museums"
    case localAndNeigborhood = "Local and Neighborhood"
    
    
    public func id() -> Int {
        switch  self {
        case .adventure:
            return 35
        case .food:
            return 103
        case .cultureAndHistory:
            return 27
        case .sightseeing:
            return 2
        case .artAndMuseums:
            return 28 //28
        case .localAndNeigborhood:
            return 21
        }
    }
    
    public static func getTitle(from id: Int) -> String? {
        switch id {
        case 35:
            return GYGCatalogCategory.adventure.rawValue
        case 103:
            return GYGCatalogCategory.food.rawValue
        case 27:
            return GYGCatalogCategory.cultureAndHistory.rawValue
        case 2:
            return GYGCatalogCategory.sightseeing.rawValue
        case 28:
            return GYGCatalogCategory.artAndMuseums.rawValue
        case 21:
            return GYGCatalogCategory.localAndNeigborhood.rawValue
        default:
            return nil
        }
    }
}
