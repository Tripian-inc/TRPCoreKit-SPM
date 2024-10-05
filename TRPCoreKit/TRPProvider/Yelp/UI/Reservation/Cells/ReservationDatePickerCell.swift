//
//  ReservationDatePicker.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 7.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
class ReservationDatePickerCell: ReservationBaseCell {
    
    var dateChangeHandler: ((_ date: String) -> Void)?
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
    
    /*private lazy var timePicker: TRPTimePickerView = {
     let picker = TRPTimePickerView()
     picker.timePickerDelegate = self
     picker.dataSource = picker
     picker.delegate = picker
     picker.setTimeFieldType(with: .start)
     return picker
     }() */
    
    private var dateToolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        return toolBar
    }()
    
    public var inputText: UITextField = {
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.textColor = UIColor.black //UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        input.text = ""
        
        return input
    }()
    
    
    override func setupCustom(stack: UIStackView) {
        stack.addArrangedSubview(inputText)
        inputText.inputView = datePicker
        inputText.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        setupToolBar()
    }
    
    private func setupToolBar() {
        let toolBarButton = UIBarButtonItem(title: "Find a table", style: .plain, target: self, action: #selector(findATablePressed))
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
    
    @objc fileprivate func datePickerValeuChanged(sender: UIDatePicker) {
        let formatted = dateFormatter(sender.date)
        inputText.text = formatted
        dateChangeHandler?(formatted)
    }
    
    func dateFormatter(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
}


