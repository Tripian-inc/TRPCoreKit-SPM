//
//  QuestionsVM.swift
//  Wiserr
//
//  Created by Cem Çaygöz on 6.09.2021.
//

import Foundation

public protocol QuestionsVMDelegate: AnyObject {
    func itemSelected(id: Int)
    func itemDeselected(id: Int)
}

class QuestionsVM {
    var questionMenu: QuestionsMenu?
    var selectedItemIds = [Int]()
    
    init(questionMenu: QuestionsMenu) {
        self.questionMenu = questionMenu
    }
    
    public weak var delegate: QuestionsVMDelegate?
    
    func numberOfRows() -> Int {
        return questionMenu?.questionPrefs?.count ?? 1
    }
    
    func cellInfo(_ indexPath: IndexPath) -> PersonalPreference {
        return questionMenu?.questionPrefs?[indexPath.row] ?? PersonalPreference(id: 0, name: "wrong")
    }
    
    func isItemSelected(id: Int) -> Bool {
        return selectedItemIds.contains(id)
    }
    
    func itemIsSelected(id: Int) {
        if selectedItemIds.contains(id) == false {
            selectedItemIds.append(id)
            self.delegate?.itemSelected(id: id)
        }
    }
    
    func itemIsDeselected(id: Int) {
        if selectedItemIds.contains(id) {
            if let index = selectedItemIds.firstIndex(of: id) {
                selectedItemIds.remove(at: index)
                self.delegate?.itemDeselected(id: id)
            }
        }
    }
    
    func clearSelections() {
//        if let multiple = companionDetailMenu?.selectMultiple, multiple == false, let cells = companionDetailMenu?.companionPrefs {
//            for cell in cells {
//                itemIsDeselected(id: cell.id)
//            }
//        }
    }
    
    func sectionTitle() -> String {
        return questionMenu?.name ?? ""
    }
}
