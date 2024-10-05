//
//  CreateTripSelectCompanionVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 10.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit


protocol CreateTripSelectCompanionVCDelegate: AnyObject {
    func createTripSelectCompanionSelected(companions: [TRPCompanion])
    func createTripSelectCompanionCreateNew()
}

class CreateTripSelectCompanionVC: TRPBaseUIViewController {

    @IBOutlet weak var tableView: EvrTableView!
    @IBOutlet weak var addTravelerView: UIView?
    @IBOutlet weak var addTravelerLbl: UILabel!
    
    var viewModel: CreateTripSelectCompanionViewModel!
    public weak var delegate: CreateTripSelectCompanionVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.start()
        
    }
    
    override func setupViews() {
        super.setupViews()
        addTravelerView?.addShadow(withRadius: 27)
        addTravelerView?.isHidden = viewModel.selectedItems.isEmpty
        addTravelerLbl.textColor = trpTheme.color.tripianBlack
        addTravelerLbl.font = trpTheme.font.header2
        addTravelerLbl.text = TRPLanguagesController.shared.getLanguageValue(for: "add_travelers")
        setupTableView()
    }

    @IBAction func addTravelersAction(_ sender: Any) {
        delegate?.createTripSelectCompanionSelected(companions: viewModel.selectedItems)
        dismiss(animated: true)
    }
}
// MARK: - TableView & SearchBar Delegates
extension CreateTripSelectCompanionVC: UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, EvrTableViewDelegate {
    
    public func evrTableViewLabelClicked() {
        delegate?.createTripSelectCompanionCreateNew()
        dismiss(animated: true)
    }
    
    fileprivate func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.emptyDelegate = self
        tableView.separatorStyle = .none
        tableView.contentInset.bottom = 100
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getDataCount()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripSelectableCell", for: indexPath) as! CreateTripSelectableCell
        let cellInfo = viewModel.getItem(indexPath: indexPath)
        cell.label.text = cellInfo.name
        cell.itemSelected = viewModel.isItemSelected(cellInfo)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let companion = viewModel.getItem(indexPath: indexPath)
        viewModel.itemSelectionToggled(companion)
        tableView.reloadData()
        
    }
}


extension CreateTripSelectCompanionVC: CreateTripSelectCompanionViewModelDelegate {
    
    public override func viewModel(dataLoaded: Bool) {
        DispatchQueue.main.async {
            if self.viewModel.getDataCount() < 1 {
                let typeAttributeStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
                let mainAttribute = NSMutableAttributedString(string: "\(TRPLanguagesController.shared.getLanguageValue(for: "user.travelCompanions.emptyMessage"))\n \(TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.travelerInfo.companion.title"))", attributes: typeAttributeStyle)
                let subTypeAttributeStyle = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
                let subTypeAttribute = NSMutableAttributedString(string: " + ", attributes: subTypeAttributeStyle)
                mainAttribute.append(subTypeAttribute)
                self.tableView?.setEmptyText(mainAttribute)
            } else {
                self.tableView?.setEmptyText("")
            }
            self.tableView?.reloadData()
        }
    }
    
    func selectedItemsChanged(isEmpty: Bool) {
        guard let addTravelerView = addTravelerView else {
            return
        }
        addTravelerView.isHidden = isEmpty
    }
}
