//
//  AddPlacesContainerViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 25.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import Parchment
import UIKit

public protocol AddPlacesContainerViewControllerDelegate: AnyObject {
    func addPlaceSelectCategory(_ navigationController: UINavigationController, viewController: UIViewController, selectedCategories: [TRPPoiCategory]?)
    func addPlaceOpenPlace(_ viewController: UIViewController, poi: TRPPoi)
}

@objc(SPMAddPlacesContainerViewController)
public class AddPlacesContainerViewController: TRPBaseUIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tfCategories: TRPTextFieldNew!
    @IBOutlet weak var tableView: EvrTableView!
    private var requestWorkItem: DispatchWorkItem?
    public var viewModel: AddPlacesContainerViewModel!
    
    public weak var delegate: AddPlacesContainerViewControllerDelegate?
    private var selectedButton: TRPAddPlaceFilterVC.ButtonType = .recommendation
    private var contentType: AddPlaceListContentType = .recommendation
    private var refreshControl: UIRefreshControl?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.places")
        viewModel.start()
    }
    
    public override func setupViews() {
        super.setupViews()
        setupSearchBar()
        setupNavigation()
        
        setupTableView()
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: TRPLanguagesController.shared.getLanguageValue(for: "pull_to_refresh"))
        refreshControl!.addTarget(self, action: #selector(refreshData), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl!)
        
        tfCategories.setPlaceholder(text: TRPLanguagesController.shared.getLanguageValue(for: "select_category"))
        tfCategories.addTarget(self, action: #selector(showPoiCategories), for: .editingDidBegin)

        showPoiCategories()
    }
    
    @objc private func refreshData() {
        viewModel.fetchData()
    }
    
    @objc func showPoiCategories() {
        dismissKeyboard()
        delegate?.addPlaceSelectCategory(navigationController!, viewController: self, selectedCategories: viewModel.getSelectedCategories())
    }
    
    func setupSearchBar() {
        //To remove borders
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = trpTheme.color.extraBG
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.showsCancelButton = false
        searchBar.delegate = self
        searchBar.placeholder = TRPLanguagesController.shared.getSearchText()
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = trpTheme.color.extraBG
        }
    }
    
    
    private func setupNavigation() {
        addCloseButton(position: .left)
    }
    
    fileprivate func showNoDataWarning() {
        tableView.setEmptyText(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.exploreMore.noResultsFound"))
    }
    
}

extension AddPlacesContainerViewController: PoiCategoryVCDelegate {
    func poiCategoryAllCategories(_ categories: [TRPPoiCategory]) {
        viewModel.isNotFiltered = true
        viewModel.selectedCategories = categories
        tfCategories.text = ""
    }
    
    func poiCategorySelectedCategories(_ selectedCategories: [TRPPoiCategory]) {
        if selectedCategories.isEmpty {
            tableView.setEmptyText(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.exploreMore.selectCategory"))
            return
        }
        viewModel.isNotFiltered = false
        viewModel.selectedCategories = selectedCategories
        tfCategories.text = selectedCategories.map(\.name!).joined(separator: ", ")
    }
}

extension AddPlacesContainerViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        requestWorkItem?.cancel()
        let newRequest = DispatchWorkItem { [weak self] in
            self?.viewModel.searchText(searchText)
        }
        
        
        requestWorkItem = newRequest
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(650), execute: newRequest)
    }
}

extension AddPlacesContainerViewController: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.getPlaceCount()
        if count > 0 {
            self.tableView.setEmptyText("")
        }
        return count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: AddPlaceCell2.self, forIndexPath: indexPath)
        let model = viewModel.getPlace(index: indexPath.row)
        let title = viewModel.getTitle(indexPath: indexPath)
        let cellModel = AddPlaceCellModel(title: title)
        cellModel.index = indexPath.row
        cellModel.isSuggestion = viewModel.isSuggestedByTripian(id: model.id)
        cellModel.explaineText = viewModel.getExplainText(placeId: model.id)
        
        if let distance = viewModel.getDistanceFromUserLocation(toPoiLat: model.coordinate.lat, toPoiLon: model.coordinate.lon), distance < 50000 {
            cellModel.distance = Int(distance).reableDistance()
        }
        
        if let imageUrl = viewModel.getPlaceImage(indexPath: indexPath) {
            cellModel.image = imageUrl
        }
        
//        if indexPath.row == viewModel.getPlaceCount() - 1 {
//            viewModel.loadNextPage()
//        }
        
        cell.config(cellModel)
        cell.selectionStyle = .none
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = viewModel.getPlace(index: indexPath.row)
        delegate?.addPlaceOpenPlace(self, poi: place)
    }
    
    public override func viewModel(dataLoaded: Bool) {
        if refreshControl != nil {
            refreshControl!.endRefreshing()
        }
        tableView.reloadData()
    }
    
    public override func viewModel(error: Error) {
        super.viewModel(error: error)
        DispatchQueue.main.async {
            if self.refreshControl != nil {
                self.refreshControl!.endRefreshing()
            }
        }
    }
}
