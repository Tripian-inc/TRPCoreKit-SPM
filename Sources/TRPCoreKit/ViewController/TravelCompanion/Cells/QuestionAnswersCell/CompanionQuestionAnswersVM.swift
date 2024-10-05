//
//  CompanionsCollectionVM.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation

public protocol CompanionQuestionAnswersVMDelegate: AnyObject {
    func itemSelected(id: Int, menuId: Int)
    func itemDeselected(id: Int, menuId: Int)
}

class CompanionQuestionAnswersVM {
    var companionDetailMenu: CompanionDetailMenu
    var selectedItemIds = [Int]()
    
    init(companionDetailMenu: CompanionDetailMenu) {
        self.companionDetailMenu = companionDetailMenu
    }
    
    public weak var delegate: CompanionQuestionAnswersVMDelegate?
    
    func numberOfRows() -> Int {
        return companionDetailMenu.companionPrefs?.count ?? 1
    }
    
    func cellInfo(_ indexPath: IndexPath) -> PersonalPreference {
        return companionDetailMenu.companionPrefs?[indexPath.row] ?? PersonalPreference(id: 0, name: "wrong")
    }
    
    func itemSelectionToggled(id: Int) {
        if isItemSelected(id: id) {
            self.selectedItemIds.remove(element: id)
            self.delegate?.itemDeselected(id: id, menuId: companionDetailMenu.menuId)
        } else {
            self.clearSelections()
            self.selectedItemIds.append(id)
            self.delegate?.itemSelected(id: id, menuId: companionDetailMenu.menuId)
        }
    }
    
    func isItemSelected(id: Int) -> Bool {
        return selectedItemIds.contains(id)
    }
    
    func clearSelections() {
        if let multiple = companionDetailMenu.selectMultiple, multiple == false, let cells = companionDetailMenu.companionPrefs {
            for cell in cells {
                self.selectedItemIds.remove(element: cell.id)
            }
        }
    }
    
//    func sectionTitle() -> String {
//        return companionDetailMenu.name
//    }
}
