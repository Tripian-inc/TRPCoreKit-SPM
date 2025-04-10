//
//  ExperiencesViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit


public protocol ExperiencesViewControllerDelegate: AnyObject {
    func experiencesVCOpenTour(_ navigationController: UINavigationController?, viewController: UIViewController, tourId: Int)
}

@objc(SPMExperiencesViewController)
public class ExperiencesViewController: TRPBaseUIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: EvrTableView!
    var viewModel: ExperiencesViewModel?
    public weak var delegate: ExperiencesViewControllerDelegate?
    
    func setViewModel(viewModel: ExperiencesViewModel) {
        self.viewModel = viewModel
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.experiences")
        
    }
    
    public override func setupViews() {
        super.setupViews()
        addCloseButton(position: .left)
        setFilterButton()
        
        setupSearchBar()
        setupTableView()
        viewModel?.start()
    }
    
    private func setFilterButton() {
        if let image = TRPImageController().getImage(inFramework: "ic_filter", inApp: nil) {
            let btn = UIBarButtonItem(image: image.withRenderingMode(.alwaysOriginal),
                                   style: UIBarButtonItem.Style.plain,
                                   target: self,
                                   action: #selector(filterPressed))
            navigationItem.rightBarButtonItem = btn
        }
    }
    
    @objc func filterPressed() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        let actionButtonHandler = { (category: String) in
            { [weak self](action: UIAlertAction!) -> Void in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.viewModel?.filterContentForCategory(category)
            }
        }
        
        for category in viewModel?.getTourCategories() ?? [] {
            let button = UIAlertAction(title: category, style: UIAlertAction.Style.default, handler: actionButtonHandler(category))
            alertController.addAction(button)
        }
        let cancelButton = UIAlertAction(title: TRPLanguagesController.shared.getCancelBtnText(), style: UIAlertAction.Style.cancel)
        cancelButton.setValue(TRPAppearanceSettings.Common.cancelButtonColor, forKey: "titleTextColor")
        alertController.addAction(cancelButton)
        present(alertController, animated: true, completion: nil)
    }
    
}

//MARK: Search Bar
extension ExperiencesViewController: UISearchBarDelegate{
    
    func setupSearchBar() {
        //To remove borders
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = trpTheme.color.extraBG
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = trpTheme.color.extraSub
        }
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel?.filterContentForSearchText(searchBar.text!)
    }
}

extension ExperiencesViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    public func updateSearchResults(for searchController: UISearchController) {
        viewModel?.filterContentForSearchText(searchController.searchBar.text!)
    }

}

extension ExperiencesViewController: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
//        tableView.register(cellClass: ExperiencesCell.self)
        tableView.setEmptyText(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.localExperiences.toursEmpty"))
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.separatorStyle = .none
        tableView.isHiddenEmptyText = true
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numberOfCells ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: JuniperExperiencesTVCell.self, forIndexPath: indexPath)
        
        if let model = viewModel?.getCellViewModel(at: indexPath) {
            cell.lblTitle.text = model.title
            cell.lblCategory.text = model.categories.joined(separator: ", ")
            if let url = URL(string: model.image){
                cell.imgTOur.sd_setImage(with: url, placeholderImage: nil)
            }
            cell.svPrice.isHidden = model.price.isEmpty
            cell.lblFrom.text = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.addToItinerary.from")
            cell.lblPerson.text = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.localExperiences.tourDetails.experience.perPerson")
            cell.lblPrice.text = model.price
            cell.selectionStyle = .none
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let productUrl = viewModel?.getProductUrl(at: indexPath) {
            UIApplication.shared.open(productUrl)
        }
    }
    
    private func selectedTour(_ tourId: Int) {
        delegate?.experiencesVCOpenTour(self.navigationController, viewController: self, tourId: tourId) 
    }
    
}


extension ExperiencesViewController: ExperiencesViewModelDelegate {
    
    public override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
    func experiencesViewModelShowEmptyWarning() {
        tableView.isHiddenEmptyText = false
    }
}
