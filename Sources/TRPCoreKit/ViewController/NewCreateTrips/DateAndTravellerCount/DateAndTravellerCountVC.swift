//
//  DateAndTravellerCountVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 13.05.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit

public protocol DateAndTravellerCountVCDelegate: AnyObject {
    func dateAndTravellerCountVCOpenTravelers(_ viewController: UIViewController, adultCount: Int, childrenCount: Int)
    func dateAndTravellerCountVCOpenCompanion(_ viewController: UIViewController)
    func dateAndTravellerCountVCOpenStayAddress(_ viewController: UIViewController)
    func dateAndTravellerCountVCCompleted()
//    func dateAndTravellerCountVCUpdateUserage(_ age: Int)
    func dateAndTravellerCountVCUpdateUserDateOfBirth(_ dateOfBirth: String)
}

public class DateAndTravellerCountVC: TRPBaseUIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var applyBtn: TRPBlackButton!
    
    var viewModel: DateAndTravellerCountViewModel!
    public weak var delegate: DateAndTravellerCountVCDelegate?
    
    var departureDatePickerCell: DateAndTravellerDataPickerCell?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.getMainTitle();
        //Pushdan dolayı geç yükleniyor o yüzden start buraya eklendi.
        viewModel.start()
    }
    
    public override func setupViews() {
        super.setupViews()
        addBackButton(position: .left)
//        applyBtn.setTitle("Continue".toLocalized(), for: .normal)
        
        setupTableView()
        setupStepView()
    }
    
    private func setupStepView() {
        let view = CreateTripStepView()
        view.setStep(step: viewModel.getCurrentStep())
        addNavigationBarCustomView(view: view)
    }
    
    @IBAction func applyBtnPressed(_ sender: Any) {
        viewModel.setTripProperties()
        delegate?.dateAndTravellerCountVCCompleted()
    }
    
}

//MARK: - TableView
extension DateAndTravellerCountVC: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 95
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getCellViewModel(at: indexPath)
        if model.contentType == .arrival || model.contentType == .departure {
            let dateCell = makeDateCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return dateCell
        }else if model.contentType == .adultCount || model.contentType == .childCount {
            let peopleCountCell = makePeopleCountCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return peopleCountCell
        }else if model.contentType == .hotelAdress || model.contentType == .travelCompanion {
            let cellWithAddButton = makeAddButtonCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return cellWithAddButton
        }else if model.contentType == .userAge {
            let cellWithAddButton = makeUserAgeCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return cellWithAddButton
        }
        let cell = tableView.dequeue(cellClass: DateAndTravellerCell.self, forIndexPath: indexPath)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getCellViewModel(at: indexPath)
        addButtonCellTapped(tag: model.contentType.hashValue)
        
        if let datePickerCell = tableView.cellForRow(at: indexPath) as? DateAndTravellerDataPickerCell {
            datePickerCell.inputText.becomeFirstResponder()
        }
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let datePickerCell = tableView.cellForRow(at: indexPath) as? DateAndTravellerDataPickerCell {
            datePickerCell.inputText.resignFirstResponder()
        }
    }
  
    private func updateDepartureDate(arrivalDay day: Date) {
        if let departureDatePickerCell = departureDatePickerCell {
            departureDatePickerCell.setDateTime(viewModel.departureDate)
            departureDatePickerCell.reloadInputViews()
        }
    }
    
    func addButtonCellTapped(tag: Int) {
        closeKeyboard()
        if tag == DateAndTravellerCountViewModel.CellContentType.hotelAdress.hashValue {
            delegate?.dateAndTravellerCountVCOpenStayAddress(self)
        }else if tag == DateAndTravellerCountViewModel.CellContentType.travelCompanion.hashValue {
            delegate?.dateAndTravellerCountVCOpenCompanion(self)
        }
    }
    
    
    @objc func removeButtonInCellPressed(_ sender: UIButton) {
        closeKeyboard()
        viewModel.addStayAddress(nil)
    }
    
    @objc func openTravelerVC(_ sender: UITextField) {
        closeKeyboard()
        delegate?.dateAndTravellerCountVCOpenTravelers(self, adultCount: viewModel.adultCount, childrenCount: viewModel.childCount)
    }
    
    
}

//MARK: - Make Cells
extension DateAndTravellerCountVC {
    
    private func makeDateCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: DateAndTravellerModel) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "DateAndTravellerDataPickerCell", for: indexPath) as! DateAndTravellerDataPickerCell
        
        cell.setupCell()
        cell.selectionStyle = .none
        
        if model.contentType == .arrival {
            cell.setDateTime(viewModel.arrivalDate)
            cell.selectedHandler = { [weak self] day, hour in
                guard let day = day else {return}
                self?.viewModel.changeArrivalDate(day, hours: hour)
                self?.updateDepartureDate(arrivalDay: day)
            }
        }else {
            cell.setDateTime(viewModel.departureDate)
            cell.selectedHandler = { [weak self] day, hour in
                guard let day = day else {return}
                self?.viewModel.changeDepartureDate(day, hours: hour)
            }
            departureDatePickerCell = cell
        }
        return cell
    }
    
    private func makePeopleCountCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: DateAndTravellerModel) -> UITableViewCell {
        
            
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "DateAndTravellerNumberOfPeopleCell", for: indexPath) as! DateAndTravellerNumberOfPeopleCell
        cell.setupUI()
        cell.inputText.text = viewModel.getTravelerTFText()
        cell.inputText.addTarget(self, action: #selector(openTravelerVC(_:)), for: .editingDidBegin)
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeAddButtonCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: DateAndTravellerModel) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "DateAndTravellerAddButtonCell", for: indexPath) as! DateAndTravellerAddButtonCell
        
        cell.titleLabel.text = model.title
        cell.selectionStyle = .none
        cell.tag = model.contentType.hashValue
        
        if model.contentType == .hotelAdress {
            cell.subTitle = viewModel.addressName
            cell.subLabelImage.image = TRPImageController().getImage(inFramework: "icon_hotel", inApp: nil) ?? UIImage()
            cell.showRemoveButton = true
            
            cell.removeButton.addTarget(self, action: #selector(removeButtonInCellPressed(_:)), for: .touchUpInside)
            cell.removeButton.tag = model.contentType.hashValue
            
        } else if model.contentType == .travelCompanion {
            cell.subTitle = viewModel.travelCompanionsNames
            cell.subLabelImage.image = TRPImageController().getImage(inFramework: "icon_companion", inApp: nil) ?? UIImage()
        }
        
        
        return cell
    }
    
    
    private func makeUserAgeCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: DateAndTravellerModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: DateAndTravellerUserAgeCell.self, forIndexPath: indexPath)
        cell.titleLabel.text = model.title
        cell.inputText.addTarget(self, action: #selector(userAgeInputChanged(sender:)), for: .editingChanged)
        if let age = viewModel.userAge {
            cell.inputText.text = "\(age)"
        }
        cell.selectionStyle = .none
        return cell
    }
    
//    @objc func countInputChanged(sender: UITextField) {
//        let text = sender.text
//        guard let _text = text, let count = Int(_text) else {return}
//        let peopleCount = peopleCountLimi(count)
//        sender.text = "\(peopleCount)"
//        if sender.tag == 1 {
//            viewModel.setAdultCount(peopleCount)
//        }else {
//            viewModel.setChildCount(peopleCount)
//        }
//    }
    
  
    private func peopleCountLimi(_ value:Int) -> Int {
        if value > 20 {
            return 20
        }
        return value
    }
    
    @objc func userAgeInputChanged(sender: UITextField) {
        let text = sender.text
        guard let _text = text, let age = Int(_text) else {return}
        var _age = age
        if _age > 115 {
           _age = 115
        }
        sender.text = "\(_age)"
//        delegate?.dateAndTravellerCountVCUpdateUserage(_age)
    }
    
    private func closeKeyboard(){
        self.view.endEditing(true)
    }
    
}

extension DateAndTravellerCountVC: DateAndTravellerCountViewModelDelegate {
    func dateAndTravellerCountVMDepartureDate(day: Date?, hour: String?) {
        
    }
    
    func dateAndTravellerCountVMTravelCompanionsNotEqual() {
        let message = "Number of travelers and travel companion(s) previously added to this trip don’t match."
        EvrAlertView.showAlert(contentText: message, type: .warning)
    }
    
    public override func viewModel(dataLoaded: Bool) {
        if tableView != nil {
            tableView.reloadData()
        }
    }
}
