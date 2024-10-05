//
//  CreateTripStayShareVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 5.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit
import TRPDataLayer

public protocol CreateTripStayShareVCDelegate: AnyObject {
    func createTripStayShareVCOpenSelectHotel(_ viewController: UIViewController)
    func createTripStayShareVCOpenSelectCompanion(_ viewController: UIViewController, selectedCompanions: [TRPCompanion])
    func createTripStayShareVCOpenCreateCompanion(_ viewController: UIViewController)
    func createTripStayShareVCCompanionRemoved(_ companion: TRPCompanion)
}

class CreateTripStayShareVC: TRPBaseUIViewController {

    @IBOutlet weak var tableView: UITableView!
    weak var delegate: CreateTripStayShareVCDelegate?
    
    var viewModel: CreateTripStayShareViewModel!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func setupViews() {
        super.setupViews()
        setupTableView()
    }
}
//MARK: - TableView
extension CreateTripStayShareVC: UITableViewDelegate, UITableViewDataSource {
    
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
        case .adultNumber, .childNumber:
            return makeTravelerCountCell(tableView: tableView, cellForRowAt: indexPath, model: model)
        case .accommodation:
            return makeTextFieldCell(tableView: tableView, cellForRowAt: indexPath, model: model)
        case .createCompanion, .companion:
            return makeCreateNewCell(tableView: tableView, cellForRowAt: indexPath, model: model)
        case .selectedCompanions:
            return makeSelectedItemTagCell(tableView: tableView, cellForRowAt: indexPath, model: model)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getCellModel(at: indexPath)
        cellTapped(cellType: model.contentType)
        
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

extension CreateTripStayShareVC {
    private func makeTravelerCountCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: CreateTripStayShareCellModel) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripTextFieldRightAddRemoveButtons", for: indexPath) as! CreateTripTextFieldRightAddRemoveButtonsCell
        cell.setupCell()
        cell.setPlaceholder(text: model.title) 
        
        if model.contentType == .adultNumber {
            cell.minimumCount = 1
            cell.currentCount = viewModel.getAdultCount()
            cell.countChangeAction = { count in
                self.viewModel.setAdultCount(count)
            }
        } else {
            cell.minimumCount = 0
            cell.currentCount = viewModel.getChildCount()
            cell.countChangeAction = { count in
                self.viewModel.setChildCount(count)
            }
        }
        return cell
    }
    
    private func makeTextFieldCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: CreateTripStayShareCellModel) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripTextFieldCell", for: indexPath) as! CreateTripTextFieldCell
        
        cell.setupCell()
        cell.setPlaceholder(text: model.title)
        if model.contentType == .accommodation {
            cell.textField.text = viewModel.getStayAddressName()
        } else {
            cell.textField.text = ""
        }
        return cell
    }
    
    private func makeCreateNewCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: CreateTripStayShareCellModel) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripCreateNewButtonCell", for: indexPath) as! CreateTripCreateNewButtonCell
        cell.setupCell(text: model.title)
        if model.contentType == .companion {
            cell.action = {
                self.delegate?.createTripStayShareVCOpenSelectCompanion(self, selectedCompanions: self.viewModel.getSelectedCompanions())
            }
        } else {
            cell.action = {
                self.delegate?.createTripStayShareVCOpenCreateCompanion(self)
            }
        }
        return cell
    }
    
    private func makeSelectedItemTagCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: CreateTripStayShareCellModel) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripSelectedItemTagCell", for: indexPath) as! CreateTripSelectedItemTagCell
        let selectedItemTagVM = CreateTripSelectedItemTagViewModel(selectedItems: viewModel.getSelectedCompanionTagModel())
        cell.viewModel = selectedItemTagVM
        cell.removeAction = { itemId in
            self.viewModel.removeTravellerCompanion(itemId)
        }
        cell.configure()
        return cell
    }
    
    private func cellTapped(cellType: CreateTripStayShareViewModel.CellContentType) {
        switch cellType {
        case .adultNumber, .childNumber, .createCompanion, .selectedCompanions:
            break
        case .accommodation:
            self.delegate?.createTripStayShareVCOpenSelectHotel(self)
        case .companion:
            self.delegate?.createTripStayShareVCOpenSelectCompanion(self, selectedCompanions: viewModel.getSelectedCompanions())
        
        }
    }
}

extension CreateTripStayShareVC : CreateTripStayShareViewModelDelegate {
    func companionRemoved(_ companion: TRPCompanion) {
        self.delegate?.createTripStayShareVCCompanionRemoved(companion)
    }
    
    func travelCompanionsNotEqual() {
        let message = TRPLanguagesController.shared.getLanguageValue(for: "travelers_mismatch_error")
        self.showMessage(message, type: .warning)
    }
    
    override func viewModel(dataLoaded: Bool) {
        if tableView != nil {
            tableView.reloadData()
        }
    }
}
