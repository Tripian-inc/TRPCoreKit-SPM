//
//  TRPCalendarTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 20.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class TRPCalendarTableViewCell: TRPBaseTableViewCell {
    
    var dateChangeHandler: ((_ date: Date) -> Void)?
    var findATableHandler: ((_ date: String) -> Void)?
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        if let timeZone = TimeZone(identifier: "UTC") {
            picker.timeZone = timeZone
        }
        picker.datePickerMode = UIDatePicker.Mode.date
        picker.backgroundColor = UIColor.white
        picker.addTarget(self, action: #selector(datePickerValeuChanged(sender:)), for: UIControl.Event.valueChanged)
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        return picker
    }()
    
    
    public var inputText: UITextField = {
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.textColor = UIColor.black //UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        input.placeholder = "Date"
        input.keyboardType = .numberPad
        input.translatesAutoresizingMaskIntoConstraints = false
        return input
    }()
    
    private var dateToolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        return toolBar
    }()
    
    override func setupCustom(stack: UIStackView) {
        stack.addArrangedSubview(inputText)
        inputText.widthAnchor.constraint(equalToConstant: 280).isActive = true
        inputText.inputView = datePicker
        setupToolBar()
    }
    
    @objc fileprivate func datePickerValeuChanged(sender: UIDatePicker) {
        let date = dateFormatter(sender.date)
        inputText.text = date
        dateChangeHandler?(sender.date)
    }
    
    
    private func setupToolBar() {
        let toolBarButton = UIBarButtonItem(title: "Check availability", style: .plain, target: self, action: #selector(findATablePressed))
        let flexItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        inputText.inputAccessoryView = dateToolBar
        dateToolBar.items = [flexItem, toolBarButton]
        dateToolBar.updateConstraintsIfNeeded()
    }
    
    @objc func findATablePressed() {
        let formatted = dateFormatter(datePicker.date)
        findATableHandler?(formatted)
        endEditing(true)
    }
    
    func dateFormatter(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "d MMM yyyy"
        return df.string(from: date)
    }
}
