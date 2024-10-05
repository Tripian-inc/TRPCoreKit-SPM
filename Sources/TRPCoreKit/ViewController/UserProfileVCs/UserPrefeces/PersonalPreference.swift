//
//  UserPreferences.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 8.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation

//struct UserPreference {
//    var id:Int
//    var name:String
//    
//    init(id: Int, name: String) {
//        self.id = id
//        self.name = name
//    }
//}

struct MockUserPreference {
    
    static func getFoodPref() -> [PersonalPreference] {
        return [PersonalPreference(id: 1, name: "Vegetarian"),
                PersonalPreference(id: 2, name: "Vegan"),
                PersonalPreference(id: 11, name: "Meat Lover"),
                PersonalPreference(id: 23, name: "All types of food"),
                PersonalPreference(id: 20, name: "Casual Dining"),
                PersonalPreference(id: 21, name: "Fine Dining")]
    }
    
    static func getDrinkPref() -> [PersonalPreference] {
        return [PersonalPreference(id: 9, name: "Wine"),
                PersonalPreference(id: 10, name: "Craft Beer"),
                PersonalPreference(id: 22, name: "Cocktails")]
    }
}



