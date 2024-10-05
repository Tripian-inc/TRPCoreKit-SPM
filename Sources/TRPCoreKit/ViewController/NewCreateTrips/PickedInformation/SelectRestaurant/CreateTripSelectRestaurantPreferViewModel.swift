//
//  CreateTripSelectRestaurantPreferViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

class CreateTripSelectRestaurantPreferViewModel {
    public var selectableQuestion: SelectableQuestionModelNew?
        
    
    public func getTitle() -> String {
        return selectableQuestion?.headerTitle ?? ""
    }
    
    public func getRowCount() -> Int {
        return selectableQuestion?.answers.count ?? 0
    }
    
    public func getAnswer(indexPath: IndexPath) -> SelectableAnswer {
        return (selectableQuestion?.answers[indexPath.row])!
    }
}
