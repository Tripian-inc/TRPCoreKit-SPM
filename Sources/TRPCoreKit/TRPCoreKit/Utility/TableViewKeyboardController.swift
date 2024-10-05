//
//  TableViewKeyboardController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-01-04.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation

class TableViewKeyboardController {
    
    private let tableView: UITableView
    
    
    init(tableView: UITableView) {
        self.tableView = tableView
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + tableView.rowHeight, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = .zero
    }
}

extension TableViewKeyboardController: ObserverProtocol {
        
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
}

