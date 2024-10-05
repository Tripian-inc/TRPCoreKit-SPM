//
//  TRPProblemCategories.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.03.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPProblemCategories: TRPRestServices<TRPProblemCategoriesJsonModel> {
    
    internal override init() {}
    
    override func path() -> String {
        return "problem-categories"
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
}
