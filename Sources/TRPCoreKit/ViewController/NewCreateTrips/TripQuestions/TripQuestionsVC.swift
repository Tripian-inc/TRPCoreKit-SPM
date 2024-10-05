//
//  TripQuestionsVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 23.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPUIKit

protocol TripQuestionsVCDelegate: AnyObject {
    func tripQuestionsVCCompleted()
}

class TripQuestionsViewController: TRPBaseUIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var applyBtn: TRPBlackButton!
    var viewModel: TripQuestionViewModel!
    
    private var headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.backgroundColor = UIColor.white
        return view
    }()
    
    //Tekli seçim için SectionBazlı cell leri tutuar.
    // Bir section da sadece 1 tane eleman seçileceği yapıda çalışır
    private var selectedCellInSection: [Int: Int?] = [:]
    
    public weak var delegate: TripQuestionsVCDelegate?
    private var isDataLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Trip Questions"
    }
    
    override func setupViews() {
        super.setupViews()
        addBackButton(position: .left)
        setupTableView()
        applyBtn.setTitle("Continue".toLocalized(), for: .normal)
        setupStepView()
    }
    
    private func setupStepView() {
        let view = CreateTripStepView()
        view.setStep(step: viewModel.getCurrentStep())
        addNavigationBarCustomView(view: view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !isDataLoaded {
            isDataLoaded.toggle()
            viewModel.start()
        }
    }
    
    @IBAction func applyBtnPressed(_ sender: Any) {
        viewModel.setTripProperties()
        delegate?.tripQuestionsVCCompleted()
    }
    
}

//MARK: - TableView
extension TripQuestionsViewController: UITableViewDelegate, UITableViewDataSource  {
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension;
        self.tableView.estimatedSectionHeaderHeight = 50;
    }
    
}

//MARK: - Cells and Sections of TableView
extension TripQuestionsViewController {
    /// SECTIONS
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getSectionCount()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(withIdentifier: "TripQuestionsHeaderCell") as? TripQuestionsHeaderCell else {return UIView() }
        let title = viewModel.getSectionModel(section: section).questionCategory
        headerView.titleLabel.text = title
        
        return headerView
    }
    
    /// CELLS
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getCellCount(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "TripQuestionsCell", for: indexPath) as! TripQuestionsCell
        
        let model = viewModel.getCellModel(at: indexPath)
        let isSelectedQuesion = viewModel.isSelectedQuesion(id: model.id)
        
        cell.setTitle(model.name)
        //Bircen çok seçilebilen cevaplar
        if viewModel.shouldAllowSelectionAt(indexPath.section) {
            cell.setSelect(isSelectedQuesion)
            cell.setSubAnsert(model.isSubAnswers)
            return cell
        }
        
        cell.removeIcon()
        
        //Tek bir seçilebilir cevaplar
        if isSelectedQuesion && !viewModel.shouldAllowSelectionAt(indexPath.section) {
            cell.setSelect(true)
        }else {
            cell.setSelect(false)
        }
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
        if let sectionRow = selectedCellInSection[indexPath.section] {
            if sectionRow != nil {
                deselect(section: indexPath.section)
                selectedCellInSection[indexPath.section] = nil
            }
        }
        if let cell = tableView.cellForRow(at: indexPath) as? TripQuestionsCell {
            cell.setSelect(true)
        }
        selectedCellInSection[indexPath.section] = indexPath.row
        let cell = viewModel.getCellModel(at: indexPath)
        if viewModel.getSectionModel(section: indexPath.section).isPace {
            
            viewModel.setPaceWith(id: cell.id)
        }
        viewModel.selectedAnswers(at: indexPath)
        //viewModel.addSelectedItem(id: cell.id)
    }
    
    private func deselect(section: Int) {
        if let item = selectedCellInSection[section] {
            let indexPath = IndexPath(item: item!, section: section)
            
            if let cell = tableView.cellForRow(at: indexPath) as? TripQuestionsCell {
                cell.setSelect(false)
            }
            let quesions = viewModel.getCellModel(at: indexPath)
            viewModel.removeSelectedItem(id: quesions.id)
        }
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

extension TripQuestionsViewController: TripQuestionViewModelDelegate {
    
    override func viewModel(dataLoaded:Bool){
        createSelectedSections()
        tableView.reloadData()
    }
}
