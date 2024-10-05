//
//  SelectCompanionVC.swift
//  TRPCoreKit
//
//  Created by Rozeri Dağtekin on 6/28/19.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit
import TRPRestKit
import TRPDataLayer


public protocol SelectCompanionVCDelegate: AnyObject {
    func companionsSelected(_ vc: SelectCompanionVC,
                            selectedCompanion: [TRPCompanion])
    func openAddCompanion(_ navigationController: UINavigationController?,
                          viewController: UIViewController)
    func openEditCompanion(_ navigationController: UINavigationController?,
                           viewController: UIViewController, companion: TRPCompanion)
}

public class SelectCompanionVC: TRPBaseUIViewController {
    //MARK: - Properties
    
    @IBOutlet weak var tableView: EvrTableView!
    @IBOutlet weak var recommendationLabel: UILabel!
    @IBOutlet weak var applyBtn: UIButton!
    
    @IBAction func applyButtonPressed(_ sender: Any) {
        self.delegate?.companionsSelected(self, selectedCompanion: self.viewModel.selectedItem)
        self.backButtonPressed()
    }
    
    //MARK: - Variables
    public var selectedCells:[Int] = []
    fileprivate var addBtn: UIBarButtonItem?
    var viewModel: SelectCompanionVM!
    public weak var delegate: SelectCompanionVCDelegate?
    
//    fileprivate var closeBtn: UIBarButtonItem?
    
    //MARK: - LyfeCycles
    public override func viewDidLoad() {
        super.viewDidLoad()
        if viewModel.fromSDK {
            title = "Travel Companions".toLocalized()
        } else if viewModel.fromProfile {
            title = "Travel Companions".toLocalized()
        } else {
            title = "Select Companions".toLocalized()
        }
        applyBtn.isHidden = viewModel.fromProfile
        hiddenBackButtonTitle()
        viewModel.start()
    }
    
    public override func setupViews() {
        super.setupViews()
        addBackButton(position: .left)
        setUpAddCompanion()
        setupTableView()
        setupLabel()
    }
    
    override func backButtonPressed() {
        if viewModel.fromSDK || viewModel.fromProfile {
            self.dismiss(animated: true, completion: nil)
        } else {
            super.backButtonPressed()
        }
    }
}


//MARK: - Functions
extension SelectCompanionVC{
    
    func setupLabel() {
        recommendationLabel.font = trpTheme.font.body3
        recommendationLabel.textColor = trpTheme.color.tripianTextPrimary
        recommendationLabel.text = "Recommendations will based on all selected profiles".toLocalized()
    }
   
    func setUpAddCompanion(){
        if let image = TRPImageController().getImage(inFramework: "btn_add", inApp: TRPAppearanceSettings.MyTrip.addTripImage) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: image.withRenderingMode(.alwaysOriginal), style: UIBarButtonItem.Style.done, target: self, action: #selector(addCompanionPressed))
        }
    }
    
    func updateApplyButtonTitle(){
        if self.viewModel.selectedItem.count == 0 && !viewModel.fromSDK && !viewModel.fromProfile{
            self.applyBtn.setTitle("Continue".toLocalized(), for: .normal)
        }else{
            self.applyBtn.setTitle("Apply".toLocalized(), for: .normal)
        }
    }
    
    @objc private func addCompanionPressed(){
        delegate?.openAddCompanion(self.navigationController, viewController: self)
    }
    
    private func editCompanion(companion: TRPCompanion) {
        delegate?.openEditCompanion(self.navigationController, viewController: self, companion: companion)
    }
}



// MARK: - TableView & SearchBar Delegates
extension SelectCompanionVC: UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, EvrTableViewDelegate {
    
    public func evrTableViewLabelClicked() {
        addCompanionPressed()
    }
    
    fileprivate func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.emptyDelegate = self
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getDataCount()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "SelectCompanionCell", for: indexPath) as! SelectCompanionCell
        let cellInfo = viewModel.getItem(indexPath: indexPath)
        cell.titleLabel.text = cellInfo.name
        cell.setSelectedState(isSelected: viewModel.isItemSelected(cellInfo))
        if viewModel.fromSDK || viewModel.fromProfile {
            cell.setTravelCompanionStyle()
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let companion = viewModel.getItem(indexPath: indexPath)
        if viewModel.fromSDK || viewModel.fromProfile {
            editCompanion(companion: companion)
            return
        }
        
        viewModel.itemSelectionToggled(companion)
        updateApplyButtonTitle()
        tableView.reloadData()
        
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
            -> UISwipeActionsConfiguration? {
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
                self.viewModel.deleteCompanion(indexPath: indexPath)
            }
            deleteAction.image = TRPImageController().getImage(inFramework: "btn_delete", inApp: nil) ?? UIImage()
            deleteAction.backgroundColor = .white
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
    }
}


extension SelectCompanionVC {
    
    public override func viewModel(dataLoaded: Bool) {
        DispatchQueue.main.async {
            self.updateApplyButtonTitle()
            if self.viewModel.getDataCount() < 1 {
                let typeAttributeStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
                let mainAttribute = NSMutableAttributedString(string: "No companions yet.\n Create a new companion".toLocalized(), attributes: typeAttributeStyle)
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
    
}
