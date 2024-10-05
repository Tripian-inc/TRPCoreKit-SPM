//
//  CreateTripPersonalizeTripVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 14.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit

class CreateTripPersonalizeTripVC: TRPBaseUIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var viewModel: CreateTripPersonalizeTripViewModel!
    
    private var selectedCellInSection: [Int: Int?] = [:]
    
    public weak var delegate: TripQuestionsVCDelegate?
    private var isDataLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func setupViews() {
        super.setupViews()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !isDataLoaded {
            isDataLoaded.toggle()
            viewModel.start()
        }
    }
    

}

//MARK: - TableView
extension CreateTripPersonalizeTripVC: UITableViewDelegate, UITableViewDataSource  {
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension;
        self.tableView.estimatedSectionHeaderHeight = 50;
    }
    
}

//MARK: - Cells and Sections of TableView
extension CreateTripPersonalizeTripVC {
    /// SECTIONS
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getSectionCount()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(withIdentifier: "CreateTripTextFieldHeaderCell") as? CreateTripTextFieldHeaderCell else {return UIView() }
        let title = viewModel.getSectionTitle(section: section)
        headerView.titleLabel.text = title
        
        return headerView
    }
    
    /// CELLS
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getCellCount(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripPersonalizeTripCell", for: indexPath) as! CreateTripPersonalizeTripCell
        
        let model = viewModel.getCellModel(at: indexPath)
        let isSelectedQuesion = viewModel.isSelectedAnswer(id: model.id)
        
        cell.titleLabel.text = model.name
        //Bircen çok seçilebilen cevaplar
        if viewModel.shouldAllowSelectionAt(indexPath.section) {
            cell.itemSelected = isSelectedQuesion
            cell.isSubSelectable = model.subAnswers?.isEmpty == false
            cell.setSubAnsert(model.isSubAnswers)
            return cell
        }
        
//        cell.removeIcon()
        
        //Tek bir seçilebilir cevaplar
        cell.itemSelected = isSelectedQuesion && !viewModel.shouldAllowSelectionAt(indexPath.section)
//        if isSelectedQuesion && !viewModel.shouldAllowSelectionAt(indexPath.section) {
//            cell.setSelect(true)
//        }else {
//            cell.setSelect(false)
//        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.viewModel.shouldAllowSelectionAt(indexPath.section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return self.viewModel.shouldAllowSelectionAt(indexPath.section)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewModel.shouldAllowSelectionAt(indexPath.section) {
            didSelectMultipleSection(tableView, didSelectRowAt: indexPath)
        }else {
           didSelectSingleSection(tableView, didSelectRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if viewModel.shouldAllowSelectionAt(indexPath.section) {
            let quesions = viewModel.getCellModel(at: indexPath)
            viewModel.removeSelectedItem(id: quesions.id)
        }
    }
    
    private func didSelectMultipleSection(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let cell = viewModel.getCellModel(at: indexPath)
        //viewModel.addSelectedItem(id: cell.id)
        viewModel.selectedAnswers(at: indexPath)
    }
    
    private func didSelectSingleSection(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedCellInSection[indexPath.section] != nil {
            deselect(indexPath: indexPath)
            selectedCellInSection[indexPath.section] = nil
        }
        if let cell = tableView.cellForRow(at: indexPath) as? CreateTripPersonalizeTripCell {
            cell.itemSelected = true
        }
        selectedCellInSection[indexPath.section] = indexPath.row
        viewModel.selectedAnswers(at: indexPath)
        //viewModel.addSelectedItem(id: cell.id)
    }
    
    private func deselect(indexPath: IndexPath) {
            
        if let cell = tableView.cellForRow(at: indexPath) as? CreateTripPersonalizeTripCell {
            cell.itemSelected = false
        }
        let quesions = viewModel.getCellModel(at: indexPath)
        viewModel.removeSelectedItem(id: quesions.id)
    }
    
    private func createSelectedSections() {
        selectedCellInSection.removeAll()
        //Edit trip de seçilen soruları buradaki selectedCellInSection sistemine entegre eder.
        for section in 0..<(viewModel.getSectionCount()){
            if !viewModel.shouldAllowSelectionAt(section) {
                let selected = viewModel.getSingleSelectedItemIndexIn(section: section)
                selectedCellInSection[section] = selected
            }else {
                selectedCellInSection[section] = nil
            }
        }
    }
   
}

extension CreateTripPersonalizeTripVC: TripQuestionViewModelDelegate {
    
    override func viewModel(dataLoaded:Bool){
        createSelectedSections()
        tableView.reloadData()
    }
}
