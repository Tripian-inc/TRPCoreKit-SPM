//
//  CreateTripSelectedItemTagViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 9.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public protocol CreateTripSelectedItemTagViewModelDelegate: AnyObject {
    func itemRemove(id: Int)
}

class CreateTripSelectedItemTagViewModel {
    var selectedItems: [SelectedItemTagModel]
    
    init(selectedItems: [SelectedItemTagModel]) {
        self.selectedItems = selectedItems
    }
    
    public weak var delegate: CreateTripSelectedItemTagViewModelDelegate?
    
    func numberOfRows() -> Int {
        return selectedItems.count
    }
    
    func cellInfo(_ indexPath: IndexPath) -> SelectedItemTagModel {
        return selectedItems[indexPath.row]
    }
    
    func itemRemove(id: Int) {
        if let index = selectedItems.firstIndex(where: {$0.id == id}) {
            selectedItems.remove(at: index)
        }
    }
}

struct SelectedItemTagModel {
    var id: Int
    var title: String
}
