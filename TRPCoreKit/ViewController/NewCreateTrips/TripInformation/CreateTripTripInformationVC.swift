//
//  CreateTripTripInformationVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 28.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit

public protocol CreateTripTripInformationVCDelegate: AnyObject {
    func createTripTripInformationVCOpenSelectCity(_ viewController: UIViewController)
    func createTripTripInformationVCOpenDate(_ viewController: UIViewController, isArrival: Bool, arrivalDate: CreateTripDateModel?, departureDate: CreateTripDateModel?)
    func createTripTripInformationVCOpenHour(_ viewController: UIViewController, isArrival: Bool, selectedHour: String?, minimumHour: String?)
    
}

@objc(SPMCreateTripTripInformationVC)
class CreateTripTripInformationVC: TRPBaseUIViewController {
    @IBOutlet weak var tableView: UITableView!
    weak var delegate: CreateTripTripInformationVCDelegate?
    
    var viewModel: CreateTripTripInformationViewModel!
    override func viewDidLoad() {
        super.viewDidLoad()        
    }
    
    public override func setupViews() {
        super.setupViews()
        setupTableView()
    }

}

//MARK: - TableView
extension CreateTripTripInformationVC: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 95
        tableView.showsVerticalScrollIndicator = false
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension;
        self.tableView.estimatedSectionHeaderHeight = 50;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getSectionCount()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(withIdentifier: "CreateTripTextFieldHeaderCell") as? CreateTripTextFieldHeaderCell else {return UIView() }
        let title = viewModel.getSectionTitle(section: section)
        headerView.setTitle(title, isRequired: viewModel.getSectionIsRequired(section: section))
        
        return headerView
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getCellCount(section: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getCellModel(at: indexPath)
        switch model.contentType {
        case .destination:
            let destinationCell = makeDestinationCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return destinationCell
        case .arrivalDate, .departureDate:
            let cell = makeDateSelectionCell(tableView: tableView, cellForRowAt: indexPath, model: model, isArrival: model.contentType == .arrivalDate, isDate: true)
            return cell
        case .arrivalHour, .departureHour:
            let cell = makeDateSelectionCell(tableView: tableView, cellForRowAt: indexPath, model: model, isArrival: model.contentType == .arrivalHour, isDate: false)
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getCellModel(at: indexPath)
        cellTapped(cell: model.contentType)
        
        if let datePickerCell = tableView.cellForRow(at: indexPath) as? DateAndTravellerDataPickerCell {
            datePickerCell.inputText.becomeFirstResponder()
        }
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let datePickerCell = tableView.cellForRow(at: indexPath) as? DateAndTravellerDataPickerCell {
            datePickerCell.inputText.resignFirstResponder()
        }
    }
    
    
}

extension CreateTripTripInformationVC {
    private func makeDestinationCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: CreateTripTripInformationCellModel) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripTextFieldCell", for: indexPath) as! CreateTripTextFieldCell
        
        cell.setupCell()
        cell.setPlaceholder(text: model.title)
        cell.textField.text = viewModel.getSelectedCityName()
        if viewModel.isEditing {
            cell.isUserInteractionEnabled = false
            cell.contentView.alpha = 0.5
        }
        return cell
    }
    
    private func makeDateSelectionCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: CreateTripTripInformationCellModel, isArrival: Bool, isDate: Bool) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripTextFieldRightTextCell", for: indexPath) as! CreateTripTextFieldRightTextCell
        
        cell.setupCell()
        cell.setPlaceholder(text: model.title)
        let rightText = isDate ? viewModel.getSelectedDate(isArrival: isArrival) : viewModel.getSelectedHour(isArrival: isArrival)
        cell.setRightText(rightText)
        return cell
    }
    
    func cellTapped(cell: CreateTripTripInformationViewModel.CellContentType) {
        dismissKeyboard()
        switch cell {
        case .destination:
            delegate?.createTripTripInformationVCOpenSelectCity(self)
        case .arrivalDate:
            delegate?.createTripTripInformationVCOpenDate(self, isArrival: true, arrivalDate: viewModel.getArrivalDateModel(), departureDate: nil)
        case .departureDate:
            delegate?.createTripTripInformationVCOpenDate(self, isArrival: false, arrivalDate: nil, departureDate: viewModel.getDepartureDateModel())
        case .arrivalHour:
            delegate?.createTripTripInformationVCOpenHour(self, isArrival: true, selectedHour: viewModel.getSelectedArrivalHour(), minimumHour: nil)
        case .departureHour:
            delegate?.createTripTripInformationVCOpenHour(self, isArrival: false, selectedHour: viewModel.getSelectedDepartureHour(), minimumHour: viewModel.getMinimumHour())
        }
    }
}

extension CreateTripTripInformationVC: CreateTripTripInformationViewModelDelegate {
    
    public override func viewModel(dataLoaded: Bool) {
        if tableView != nil {
            tableView.reloadData()
        }
    }
}
