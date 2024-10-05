//
//  DateAndTravellerDataPickerCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit

class DateAndTravellerDataPickerCell: UITableViewCell, UITextFieldDelegate {
    
//    enum PickerType {
//        case date, time
//    }
    
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
    
    private lazy var timePicker: TRPTimePickerView = {
        let picker = TRPTimePickerView()
        picker.timePickerDelegate = self
        picker.dataSource = picker
        picker.delegate = picker
        picker.setTimeFieldType(with: .start)
        return picker
    }()
    
    private var dateToolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        return toolBar
    }()
    
    private var timeToolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        return toolBar
    }()
    
    @IBOutlet weak var inputText: TRPTextField!
    @IBOutlet weak var timePickerText: TRPTextField!
    
    public var selectedDate: Date? {
        didSet {
            var hour = selectedHours
            if hour == nil {
                hour = timePicker.getDefaultVal()
            }
            updateInputText(selectedDate: self.selectedDate, time: hour)
        }
    }
    
    private var selectedHours: String? {
        didSet {
            selectedDate = selectedDate?.setHour(for: selectedHours)
        }
    }
    
    public var selectedHandler: ((_ day: Date?, _ hours: String?) -> Void)?
    
    func setupCell() {
        inputText.delegate = self
        inputText.inputView = datePicker
        timePickerText.delegate = self
        timePickerText.inputView = timePicker
        
        let leftImage = TRPImageController().getImage(inFramework: "icon_calendar", inApp: nil) ?? UIImage()
        inputText.setLeftImage(image: leftImage)
        
        let leftTimeImage = TRPImageController().getImage(inFramework: "icon_clock_big", inApp: nil) ?? UIImage()
        timePickerText.setLeftImage(image: leftTimeImage)
        setupToolBar()
    }
    
    private func readableDate(_ date:Date) -> String {
        return date.toString(dateStyle: DateFormatter.Style.medium)
    }
    
    public func setDateTime(_ date: DateAndTravellerCountViewModel.DatePickerModel) {
        
        datePicker.minimumDate = date.minimumDate
        datePicker.maximumDate = date.maximumDate
        selectedDate = date.selectedDate
        
        timePicker.setDefaultVal(with: date.selectedDate.getHour())
        self.selectedHours = timePicker.getDefaultVal()
        
        if let max = date.maximumDate, let select = selectedDate {
            self.selectedDate = compareSelectedDate(min: date.minimumDate, max: max, selected: select)
        }else {
            self.selectedDate = selectedDate != nil ? selectedDate : date.minimumDate
        }
    }
    
    private func compareSelectedDate(min: Date, max:Date, selected: Date) -> Date? {
        if selected > min && selected < max {
            return selected
        }else if selected < min {
            return min
        }else if selected > max {
            return max
        }
        return selected
    }
    
    private func updateInputText(selectedDate: Date?, time: String?){
        guard let date = selectedDate, let hours = time else {return}
        selectedHandler?(date, hours)
        let _readableDate = readableDate(date)
        inputText.text = _readableDate // + " - " + hours
        
        timePickerText.text = hours
    }
}

//MARK: - ToolBar
extension DateAndTravellerDataPickerCell {
    private func setupToolBar() {
        let setTimeTitle = TRPLanguagesController.shared.getApplyBtnText()
        let setDate = UIBarButtonItem(title: setTimeTitle, style: .plain, target: self, action: #selector(applyButtonOfDatePressed))
        setDate.setDefaultColor()
        
        let flexItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        dateToolBar.items = [flexItem, setDate]
        dateToolBar.updateConstraintsIfNeeded()
        inputText.inputAccessoryView = dateToolBar
        
        timePickerText.inputAccessoryView = timePicker.getToolBar(with: TRPLanguagesController.shared.getApplyBtnText(), TRPAppearanceSettings.Common.barButtonForInputButtonColor)
    }
    
    @objc private func applyButtonOfDatePressed() {
        inputText.resignFirstResponder()
        if selectedHours != nil {
            timePicker.setDefaultVal(with: selectedHours!)
        }
    }
    
    @objc private func applyButtonOfTimePressed() {
        timePickerText.resignFirstResponder()
        self.isEditing = false
        
        if let selectedInTimePicker =  timePicker.getSelectedHour(), !selectedInTimePicker.isEmpty {
            self.selectedHours = timePicker.getSelectedHour()
        }else if let defaultTime = timePicker.getDefaultVal(), !defaultTime.isEmpty {
            self.selectedHours = defaultTime
        }
    }
}

//MARK: - Date Picker
extension DateAndTravellerDataPickerCell {
    
    @objc fileprivate func datePickerValeuChanged(sender: UIDatePicker) {
        selectedDate = sender.date
    }
    
}

//MARK: - Time Picker
extension DateAndTravellerDataPickerCell: TRPTimePickerViewProtocol {
    
    func timePickerDidSelectRow(selectedHour: String?, timeType: TimeFieldType?) {
        self.selectedHours = selectedHour
    }
    
    func toolBarButtonPressed(selectedHour: String?, timeType: TimeFieldType?) {
        self.applyButtonOfTimePressed()
    }
    
}
