//
//  CreateTripPickedInformationVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 12.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit

protocol CreateTripPickedInformationVCDelegate: AnyObject {
    func createTripPickedInformationVCDelegateOpenSelectAnswer(_ viewController: UIViewController, question: SelectableQuestionModelNew)
}
class CreateTripPickedInformationVC: TRPBaseUIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    public var viewModel: CreateTripPickedInformationViewModel!
    public weak var delegate: CreateTripPickedInformationVCDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.start()
    }
    
    public override func setupViews() {
        super.setupViews()
        setupTableView()
    }

}
//MARK: - TableView
extension CreateTripPickedInformationVC: UITableViewDelegate, UITableViewDataSource {
    
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
        headerView.titleLabel.text = title
        
        return headerView
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let cellType = viewModel.getCellType(section: section)
        if cellType == .restaurant {
            return viewModel.getCellCountForRestaurantPrefer(section: section)
        } else {
            return viewModel.getCellCount(section: section)
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = viewModel.getCellType(section: indexPath.section)
        if cellType == .withDescription {
            let model = viewModel.getCellModel(at: indexPath)
            return makeDescriptionSelectionCell(tableView: tableView, cellForRowAt: indexPath, model: model)
        } else if cellType == .restaurant {
            let model = viewModel.getCellModelForRestaurantPrefer(at: indexPath)
            return makeBeenBeforeCell(tableView: tableView, cellForRowAt: indexPath, model: model)
        } else if cellType == .radio {
            let model = viewModel.getCellModel(at: indexPath)
            return makeTravelTypeCell(tableView: tableView, cellForRowAt: indexPath, model: model)
        }
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.cellSelected(indexPath: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let datePickerCell = tableView.cellForRow(at: indexPath) as? DateAndTravellerDataPickerCell {
            datePickerCell.inputText.resignFirstResponder()
        }
    }
    
}

extension CreateTripPickedInformationVC {
        
    private func makeBeenBeforeCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: SelectableQuestionModelNew) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripTextFieldRightTextCell", for: indexPath) as! CreateTripTextFieldRightTextCell
        
        cell.setupCell()
        cell.setPlaceholder(text: model.headerTitle)
        cell.setRightText(viewModel.getSelectedRestaurantAnswer(questionId: model.id))
        return cell
    }
    
    private func makeDescriptionSelectionCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: SelectableAnswer) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripDescriptionSelectionCell", for: indexPath) as! CreateTripDescriptionSelectionCell
        
//        cell.setupCell()
        cell.titleLbl.text = model.name
        cell.descriptionLbl.text = model.description
        cell.itemSelected = viewModel.isSelectedAnswer(id: model.id)
        return cell
    }
    
    private func makeTravelTypeCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: SelectableAnswer) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripPersonalizeTripCell", for: indexPath) as! CreateTripPersonalizeTripCell
        
        let isSelectedQuesion = viewModel.isSelectedAnswer(id: model.id)
        cell.isSubSelectable = model.subAnswers?.isEmpty == false
        cell.setSubAnsert(model.isSubAnswers)
        cell.titleLabel.text = model.name
        
        cell.itemSelected = isSelectedQuesion && !viewModel.shouldAllowSelectionAt(indexPath.section)
        return cell
    }
    
}

extension CreateTripPickedInformationVC: CreateTripPickedInformationViewModelDelegate {
    func restaurantPreferSelected(questionModel: SelectableQuestionModelNew) {
        self.delegate?.createTripPickedInformationVCDelegateOpenSelectAnswer(self, question: questionModel)
    }
    
    override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
}
