//
//  TimeAlert.swift
//  TRPUIKit
//
//  Created by Rozeri Dağtekin on 11/12/19.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

//TimeAlert class is used in Map activities.
//User can choose their current travel's start and end times via TimeAlert class.

import Foundation
import UIKit

public protocol TimeAlertDelegate: AnyObject {
    func timeChanged(_ startTime: String,_ endTime: String)
    func dismissTimeAlert()
}

public class TimeAlert: NSObject {
    
    //MARK: - Variables
    
    private var timeAlert: UIAlertController = UIAlertController(title: "", message: nil, preferredStyle: .alert)
    
    private weak var timeAlertDelegate: TimeAlertDelegate?
    
    fileprivate lazy var selectedTime = (startTime: TimeConstants.startTime, endTime: TimeConstants.endTime)
    
    public struct TimeConstants {
        static let startTime = "09:00"
        static let endTime = "21:00"
    }
    
    //MARK: - Outlets
    
    private var startTimeField: UITextField = {
        let textField = UITextField();
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = UIColor.black
        textField.placeholder = TimeConstants.startTime
        return textField
    }()
    
    private var endTimeField: UITextField = {
        let textField = UITextField();
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = UIColor.black
        textField.placeholder = TimeConstants.endTime
        return textField
    }()
    
    private lazy var startTimePicker: TRPTimePickerView = {
        let picker = TRPTimePickerView()
        picker.timePickerDelegate = self
        picker.dataSource = picker
        picker.delegate = picker
        picker.setTimeFieldType(with: TimeFieldType.start)
        return picker
    }()
    
    //MARK: - Initialization
    private lazy var endTimePicker: TRPTimePickerView = {
        let picker = TRPTimePickerView()
        picker.timePickerDelegate = self
        picker.dataSource = picker
        picker.delegate = picker
        picker.setTimeFieldType(with: TimeFieldType.end)
        return picker
    }()
    
    
    public init(title: String, saveActionTitle: String, cancelActionTitle: String, applyButtonTitle: String, doneButtonTitle: String, startTimePlaceHolder: String, endTimePlaceHolder: String) {
        
        super.init()
        
        self.timeAlert = UIAlertController(title: "", message: nil, preferredStyle: .alert)
        let TitleString = NSAttributedString(string: title , attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : TRPColor.darkerGrey])
        timeAlert.setValue(TitleString, forKey: "attributedTitle")
        
        timeAlert.addTextField { (textField) in
            self.startTimeField = textField
            textField.placeholder = startTimePlaceHolder
            textField.inputView = self.startTimePicker
            self.startTimePicker.setDefaultVal(with: 9)
            textField.inputAccessoryView = self.startTimePicker.getToolBar(with: applyButtonTitle)
            textField.delegate = self
            textField.tag = TimeFieldType.start.rawValue
        }
        
        timeAlert.addTextField { (textField) in
            self.endTimeField = textField
            textField.inputView = self.endTimePicker
            textField.inputAccessoryView = self.endTimePicker.getToolBar(with: doneButtonTitle)
            textField.placeholder = endTimePlaceHolder
            textField.delegate = self
            textField.text = ""
            textField.tag = TimeFieldType.end.rawValue
        }
        
        let saveAction = UIAlertAction(title: saveActionTitle, style: .default) { [weak self] (aciton) in
            guard let strongSelf = self else {return}
            strongSelf.updateSelectedTime()
            guard let timeAlertDelegate = strongSelf.timeAlertDelegate else{
                return
            }
            timeAlertDelegate.timeChanged(strongSelf.selectedTime.startTime,strongSelf.selectedTime.endTime)
        }
        
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel) { (action) in}
        
        cancelAction.setValue(TRPColor.pink, forKey: "titleTextColor")
        timeAlert.addAction(saveAction)
        timeAlert.addAction(cancelAction)
    }
    
    //MARK: Public Functions
    public func setDelegate(timeDelegate: TimeAlertDelegate) -> Self{
        self.timeAlertDelegate = timeDelegate
        return self
    }
    
    public func build() -> UIAlertController {
        if let textFields = self.timeAlert.textFields {
            if textFields.count > 0{
                guard let firstTextView = textFields[0].superview else {return timeAlert}
                firstTextView.superview!.subviews[0].removeFromSuperview()
                firstTextView.backgroundColor = UIColor.white
                guard let secondTextView = textFields[1].superview else {return timeAlert}
                secondTextView.superview!.subviews[0].removeFromSuperview()
                secondTextView.backgroundColor = UIColor.white
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlertController))
        self.timeAlert.view.superview?.subviews[0].addGestureRecognizer(tapGesture)
        
        return timeAlert
    }
}

//MARK: - Time Picker View Protocol
extension TimeAlert: TRPTimePickerViewProtocol{
    public func timePickerDidSelectRow(selectedHour: String?, timeType: TimeFieldType?) {
        guard let selectedHour = selectedHour else{
            return
        }
        if(selectedHour.contains(":")){
            setTime(with: selectedHour, timeType: timeType)
        }
    }
    
    private func setTime(with hour: String, timeType: TimeFieldType?){
        if let type = timeType{
            switch type {
            case TimeFieldType.start:
                self.startTimeField.text = hour
            default:
                self.endTimeField.text = hour
            }
        }
    }
    
    public func toolBarButtonPressed(selectedHour: String?, timeType: TimeFieldType?) {
        if let type = timeType{
            switch type {
            case TimeFieldType.start:
                if(startTimeField.text?.count == 0){
                    startTimeField.text = TimeConstants.startTime
                }
                self.endTimeField.becomeFirstResponder()
            case TimeFieldType.end:
                if endTimeField.text?.count == 0, selectedHour?.count == 0{
                    endTimeField.text = TimeConstants.endTime
                }
                
                if  startTimeField.text == TRPTimePickerView.lastStartHour{
                    endTimeField.text = TRPTimePickerView.lastEndHour
                }
                self.endTimeField.resignFirstResponder()
                
                showUpdatedHour()
            }
        }
    }
    
    private func showUpdatedHour() {
        updateSelectedTime()
        completed()
    }
    
    fileprivate func updateSelectedTime(){
        guard let startText = startTimeField.text else {return}
        selectedTime.startTime = startText == "" ? selectedTime.startTime : startText
        guard let endText = endTimeField.text else {return}
        selectedTime.endTime = endText == "" ? selectedTime.endTime : endText
    }
    
    fileprivate func completed() {
        guard let timeAlertDelegate = timeAlertDelegate else{
            return
        }
        timeAlertDelegate.dismissTimeAlert()
        timeAlertDelegate.timeChanged(selectedTime.startTime,selectedTime.endTime)
    }
    
    @objc func dismissAlertController(){
        guard let timeAlertDelegate = timeAlertDelegate else{
            return
        }
        timeAlertDelegate.dismissTimeAlert()
    }
}

//MARK: - Set Time Field Text Field Delegate Functions
extension TimeAlert: UITextFieldDelegate{
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case startTimeField:
            guard let endHour = endTimeField.text, endHour.count != 0 else {
                return
            }
            startTimePicker.setMaxVal(in: endHour)
            startTimePicker.setDefaultVal(with: TimeConstants.startTime)
        case endTimeField:
            guard let startHour = startTimeField.text, startHour.count != 0 else {
                startTimeField.text = TimeConstants.startTime
                endTimePicker.setMinVal(in: TimeConstants.startTime)
                return
            }
            if(startHour == TRPTimePickerView.lastStartHour){
                endTimeField.text = TRPTimePickerView.lastEndHour
            }
            endTimePicker.setMinVal(in: startHour)
            endTimePicker.setDefaultVal(with: TimeConstants.endTime)
        default:
            return
        }
    }
}
