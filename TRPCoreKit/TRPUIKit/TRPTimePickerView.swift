//
//  TRPTimePickerView.swift
//  TRPUIKit
//
//  Created by Rozeri Dağtekin on 11/4/19.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

//Custom Time Picker View Class

import UIKit

public protocol TRPTimePickerViewProtocol {
    func timePickerDidSelectRow(selectedHour:String?, timeType: TimeFieldType?)
    func toolBarButtonPressed(selectedHour:String?, timeType: TimeFieldType?)
}

public enum TimeFieldType: Int{
    case start,end
}

public class TRPTimePickerView: UIPickerView {
    
    private final let times: [String] = ["00:00", "00:30", "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30"]
    //MARK: - Variables
    private var hours: [String] = []
    
    private var defaultHour: String = ""
    private var selectedHour: String = ""
    private var timeType: TimeFieldType?
    
    public static let lastStartHour = "23:00"
    public static let lastEndHour = "23:59"
    
    //MARK: - Delegate
    public var timePickerDelegate:TRPTimePickerViewProtocol?
    
    private var timeToolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        return toolBar
    }()
    
    //MARK: - Initialization
    public override init(frame:CGRect){
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Private Functions
    private func commonInit() {
        self.backgroundColor = UIColor.white
        hours = times
    }
    
    //MARK: - ObjC Functions
    @objc func applyButtonOfTimePressed() {
        timePickerDelegate?.toolBarButtonPressed(selectedHour: selectedHour, timeType: timeType)
    }
}

//MARK: - Delegate & DataSource functions
extension TRPTimePickerView: UIPickerViewDataSource, UIPickerViewDelegate{
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return hours.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedHour = hours[row]
        timePickerDelegate?.timePickerDidSelectRow(selectedHour: selectedHour, timeType: timeType)
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return hours[row]
    }
}

//MARK: - Calculation functions
extension TRPTimePickerView{
    
    public func setMaxVal(in maxVal: Int) {
        hours = times
        
        if(maxVal < hours.count){
            hours.removeSubrange(ClosedRange(uncheckedBounds: (lower: maxVal, upper: times.count - 1)))
            reloadAllComponents()
        }
    }
    
    public func setMaxVal(in maxVal: String, isMinMax: Bool = false) {
        if(!isMinMax && hours.count != times.count){
            hours = times
        }
        guard let maxHourValue = getHourValue(for: maxVal) else {return}
        
        if let maxValueIndex = hours.firstIndex(of: maxHourValue), maxValueIndex < hours.count - 1 {
            hours.removeSubrange(ClosedRange(uncheckedBounds: (lower: maxValueIndex + 1, upper: hours.count - 1)))
        }
        reloadAllComponents()
    }
    
    public func setMinVal(in minVal: Int) {
        if(hours.count != times.count){
            hours = times
        }
        if(minVal == 23){
            hours = ["23:59"]
        }else{
            hours.removeSubrange(ClosedRange(uncheckedBounds: (lower: 0, upper: minVal)))
        }
        reloadAllComponents()
    }
    
    public func setMinVal(in minVal: String, isMinMax: Bool = false){
        if(!isMinMax && hours.count != times.count){
            hours = times
        }
        guard let minHourValue = getHourValue(for: minVal) else {return}
        
        if let minValueIndex = hours.firstIndex(of: minHourValue), minValueIndex < hours.count, minValueIndex > 0 {
            hours.removeSubrange(ClosedRange(uncheckedBounds: (lower: 0, upper: minValueIndex - 1)))
        }
        reloadAllComponents()
    }
    
    public func setMaxAndMinVal(minVal: String, maxVal: String) {
        if(hours.count != times.count){
            hours = times
        }
        setMinVal(in: minVal, isMinMax: true)
        setMaxVal(in: maxVal, isMinMax: true)
//        if let minHourValue = getHourValue(for: minVal), let maxHourValue = getHourValue(for: maxVal) {
//            
//            if let minValueIndex = hours.firstIndex(of: minHourValue), minValueIndex < hours.count, minValueIndex > 0 {
//                hours.removeSubrange(ClosedRange(uncheckedBounds: (lower: 0, upper: minValueIndex - 1)))
//            }
//            
//            if let maxValueIndex = hours.firstIndex(of: maxHourValue), maxValueIndex < hours.count - 1 {
//                hours.removeSubrange(ClosedRange(uncheckedBounds: (lower: maxValueIndex + 1, upper: hours.count - 1)))
//            }
//            reloadAllComponents()
//        }
        
    }
    
    private func getHourValue(for value: String) -> String? {
        if value.count != 0, value.contains(":"){
            let newTime = value.components(separatedBy: ":")
            if newTime.count == 2 {
                let hour = newTime[0]
                let minute = getMinute(for: newTime[1])
                return "\(hour):\(minute)"
            }
        }
        return nil
    }
    
    private func getMinute(for value: String) -> String {
        if value.count == 2 {
            if ["0","1","2"].contains(value.first) {
                return "00"
            }
            if ["4","5","6"].contains(value.first) {
                return "30"
            }
            if value.first == "3" {
                return value.last == "0" ? "00" : "30"
            }
        }
        return "00"
    }
    
    public func setDefaultVal(with defaultVal: Int) {
        guard defaultVal < hours.count else{
            return
        }
        defaultHour = hours[defaultVal]
        self.selectRow(defaultVal, inComponent: 0, animated: false)
    }
    
    public func setDefaultVal(with defaultVal: String) {
        defaultHour = defaultVal
        guard let index = hours.firstIndex(of: defaultVal) else {
            return
        }
        selectedHour = defaultHour
        self.selectRow(index, inComponent: 0, animated: false)
    }
    
    public func getDefaultVal() -> String? {
        return defaultHour
    }
    
    public func getSelectedHour() -> String? {
        return selectedHour
    }
    
    public func getToolBar(with buttonTitle: String, _ buttonTintColor: UIColor? = nil) -> UIToolbar{
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let applyTitle = buttonTitle
        let applyButton = UIBarButtonItem(title: applyTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(applyButtonOfTimePressed))
        if let color = buttonTintColor{
            applyButton.tintColor = color
        }else{
            applyButton.tintColor = TRPColor.pink
        }
        timeToolBar.items = [spaceButton,applyButton]
        timeToolBar.updateConstraintsIfNeeded()
        return timeToolBar
    }
    
    public func setTimeFieldType(with type:TimeFieldType){
        timeType = type
        setDefaultTime(with: type)
    }
    
    private func setDefaultTime(with type: TimeFieldType){
        switch type {
        case TimeFieldType.start:
            setDefaultVal(with: "09:00")
        default:
            setDefaultVal(with: "21:00")
        }
    }
    
    public func getTimeFieldType() -> TimeFieldType?{
        return timeType
    }
}

//MARK: - Toolbar functions
extension TRPTimePickerView{
    public func setToolBarRightText(with text: String) {
        
    }
}
