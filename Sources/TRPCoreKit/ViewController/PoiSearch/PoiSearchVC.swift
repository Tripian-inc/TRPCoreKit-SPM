//
//  PoiSearchVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.02.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import Parchment
import TRPUIKit
import TRPDataLayer

enum ScopeButton: String {
    case recommended = "Recommended"
    case nearBy = "Nearby"
}
public protocol PoiSearchVCDelegate: AnyObject{
    func poiSearchOpenPlaceDetail(viewController:UIViewController, poi: TRPPoi)
}

public class PoiSearchVC: TRPBaseUIViewController {
    
    private let viewModel: PoiSearchVM
    private let modelType: SdkModeType
    fileprivate var searchController: UISearchController = UISearchController(searchResultsController: nil)
    fileprivate var tableView: UITableView?
    fileprivate var requestWorkItem: DispatchWorkItem?
    public weak var delegate: PoiSearchVCDelegate?
    private lazy var searchBar:UISearchBar = UISearchBar()
    private var benchMark = BenchMark()
    
    init(viewModel: PoiSearchVM, modeType: SdkModeType = .Trip) {
        self.viewModel = viewModel
        self.modelType = modeType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = TRPLanguagesController.shared.getLanguageValue(for: "search")
    }
    
    public override func setupViews() {
        super.setupViews()
        setupSearchController()
        setupTableView()
        navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
    
    @objc func closedPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension PoiSearchVC: UISearchBarDelegate {
    
    fileprivate func setupSearchController() {
        searchController.searchBar.sizeToFit()
//        searchController.searchBar.placeholder = TRPAppearanceSettings.StayAddress.searchBarPlaceHolder
        
        if viewModel.isUserInCity == true {
            searchController.searchBar.scopeButtonTitles = [ScopeButton.recommended.rawValue, ScopeButton.nearBy.rawValue]
        }
        
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        var placeHolder = TRPLanguagesController.shared.getLanguageValue(for: "search")
        
//        if let type = viewModel.categoryType {
//            placeHolder = type.description
//        }
        
        searchController.searchBar.placeholder = placeHolder
        searchController.searchBar.delegate = self
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.showLastSearch = true
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchPoi(searchBar)
    }
    
    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.clearResult()
        searchPoi(searchBar)
    }
    
    private func searchPoi(_ searchBar: UISearchBar) {
        
        guard let content = searchBar.text else {return}
        
        if content.count >= 1 {
            viewModel.showLastSearch = false
        }
        if content.count < 2 {
            return
        }
        
        requestWorkItem?.cancel()
        
        let newRequest = DispatchWorkItem { [weak self] in
            let scope: ScopeButton = searchBar.selectedScopeButtonIndex == 0 ? .recommended : .nearBy
            self?.viewModel.search(text: content, scope: scope)
        }
        
        requestWorkItem = newRequest
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(650), execute: newRequest)
    }
    
}

extension PoiSearchVC: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        tableView = UITableView(frame: CGRect.zero)
        tableView!.dataSource = self
        tableView!.delegate = self
        view.addSubview(self.tableView!)
        tableView!.register(cellClass: PoiSearchCell.self)
        tableView!.register(cellClass: PoiLastSearchCell.self)
        tableView!.translatesAutoresizingMaskIntoConstraints = false
        tableView!.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        tableView!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        tableView!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        tableView!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        tableView!.rowHeight = UITableView.automaticDimension
        tableView!.estimatedRowHeight = 100
        
        //tableView!.tableHeaderView = searchController.searchBar
        
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.showLastSearch {
            return makeLastSearchCell(tableView, cellForRowAt: indexPath)
        }
        
        return makePoiCell(tableView, cellForRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if viewModel.showLastSearch {
            if let lastSearch = viewModel.getLastSearch(indexPath: indexPath) {
                searchController.searchBar.text = lastSearch.title
                searchController.isActive = true
                searchBar(searchController.searchBar, textDidChange: lastSearch.title)
            }
        }else {
            if let model = viewModel.getPoi(indexPath: indexPath) {
                delegate?.poiSearchOpenPlaceDetail(viewController: self, poi: model.poi)
            }
        }
        
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
}

//MARK: Make Cell
extension PoiSearchVC {
    
    private func makePoiCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PoiSearchCell.self, forIndexPath: indexPath)
        
        guard let modelWithLocation = viewModel.getPoi(indexPath: indexPath) else {return cell}
        let model = modelWithLocation.poi
        cell.poiNameLabel.text = model.name
        // TODO: - APİ V3
        //cell.poiSubTypeLabel.text = model.subCategory
        if let type = model.categories.first?.name {
            cell.setTypeAndPrice(type: type, priceCount: model.price ?? 0)
        }
        
        if viewModel.isUserInCity, let dis = modelWithLocation.distance {
            let tempDis = Int(dis)
            cell.distanceLabel.text = tempDis.reableDistance()
        }else {
            cell.distanceLabel.text = ""
        }
        
        let raitingIsShow = TRPAppearanceSettings.ShowRating.type.contains { (category) -> Bool in
            guard let categories = model.categories.first else {return false}
            if category.getId() == categories.id {
                return true
            }
            return false
        }
        if raitingIsShow {
            cell.setRatingAndStar(rating: model.ratingCount ?? 0, starCount: (model.rating ?? 0).rounded())
        }
        cell.showGlobalRating = raitingIsShow
        if indexPath.row == viewModel.numberOfCells - 1 {
            viewModel.loadNextPage()
        }
        return cell
    }
    
    private func makeLastSearchCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PoiLastSearchCell.self, forIndexPath: indexPath)
        
        let model = viewModel.getLastSearch(indexPath: indexPath)
        
        
        if let image =  TRPImageController().getImage(inFramework: model?.image, inApp: nil) {
            cell.icon.image = image
        }
        
        
        cell.titleLabel.text = model?.title
        return cell
    }
}

extension PoiSearchVC {
   
    public override func viewModel(dataLoaded: Bool) {
        guard let tb = tableView else { return }
        DispatchQueue.main.async {
            tb.reloadData()
        }
    }
    
}

