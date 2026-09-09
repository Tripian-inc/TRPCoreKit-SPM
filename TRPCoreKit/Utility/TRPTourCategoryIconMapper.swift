//
//  TRPTourCategoryIconMapper.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 04.05.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

public enum TRPTourCategoryIconMapper {

    public static let allCategoriesIconName: String = "ic_all_categories"

    /// Maps a facet category `key` (e.g. "activity_main_category_1") to a local SDK asset name.
    /// Falls back to `ic_cat_poi` for unknown keys.
    public static func iconName(forKey key: String?) -> String {
        guard let key = key else { return fallback }
        switch key {
        case "activity_main_category_1":  return "ic_activities"
        case "activity_main_category_2":  return "ic_cat_excursions"
        case "activity_main_category_4":  return "ic_cat_actions"
        case "activity_main_category_5":  return "ic_cat_tickets"
        case "activity_main_category_6":  return "ic_cat_shows"
        case "activity_main_category_7":  return "ic_cat_passes"
        case "activity_main_category_8":  return "ic_cat_passes"
        case "activity_main_category_9":  return "ic_cat_food_drinks"
        case "activity_main_category_11": return "ic_cat_transfers"
        case "activity_main_category_12": return "ic_cat_services"
        case "activity_main_category_13": return "ic_cat_experiences"
        default:                          return fallback
        }
    }

    private static let fallback: String = "ic_cat_experiences"
}
