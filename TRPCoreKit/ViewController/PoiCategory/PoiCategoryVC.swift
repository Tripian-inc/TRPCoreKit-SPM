//
//  PoiCategoryVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 28.02.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit

protocol PoiCategoryVCDelegate: AnyObject {
    func poiCategorySelectedCategories(_ selectedCategories: [TRPPoiCategory])
    func poiCategoryAllCategories(_ categories: [TRPPoiCategory])
}

@objc(SPMPoiCategoryVC)
class PoiCategoryVC: TRPBaseUIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnCancel: TRPBlackButtonSecondary!
    @IBOutlet weak var btnSelect: TRPBlackButton!
    var viewModel: PoiCategoryViewModel!
    open var delegate: PoiCategoryVCDelegate?
    
    private var isDataLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        btnCancel.setTitle(TRPLanguagesController.shared.getCancelBtnText(), for: .normal)
        btnSelect.setTitle(TRPLanguagesController.shared.getLanguageValue(for: "select_category"), for: .normal)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
//        delegate?.poiCategorySelectedCategories(viewModel.selectedCategories)
    }
    
    @IBAction func selectAction(_ sender: Any) {
        let categories = viewModel.getSelectedCategories()
        if categories.isEmpty {
            delegate?.poiCategoryAllCategories(viewModel.getAllCategories())
        } else {
            delegate?.poiCategorySelectedCategories(categories)
        }
        dismiss(animated: true)
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
extension PoiCategoryVC: UITableViewDelegate, UITableViewDataSource  {
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        self.tableView.estimatedRowHeight = UITableView.automaticDimension;
//        self.tableView.estimatedSectionHeaderHeight = 50;
    }
    
}

//MARK: - Cells and Sections of TableView
extension PoiCategoryVC {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getCellCount(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripPersonalizeTripCell", for: indexPath) as! CreateTripPersonalizeTripCell
        
        let model = viewModel.getCellModel(at: indexPath)
        
        cell.titleLabel.text = model.name
        cell.itemSelected = model.isSelected
        cell.isSubSelectable = false
        cell.setSubAnsert(!model.isCategoryGroup)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectCell(at: indexPath)
    }
   
}

extension PoiCategoryVC: PoiCategoryViewModelDelegate {
    func selectedAllCategoriesForFirstInit() {
        delegate?.poiCategoryAllCategories(viewModel.getAllCategories())
    }
    
    
    override func viewModel(dataLoaded:Bool){
//        createSelectedSections()
        tableView.reloadData()
    }
}
