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


//public protocol AddPlacesContainerViewControllerDelegate: AnyObject {
//    func addPlaceContainerViewControllerOpenSearchView(_ navigationController: UINavigationController, viewController: UIViewController, selectedType: AddPlaceTypes?)
//}

@objc(SPMAddPlacesContainerViewController)
public class AddPlacesContainerViewController: TRPBaseUIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var containerView: UIView!
    private var requestWorkItem: DispatchWorkItem?
    public var viewModel: AddPlacesContainerViewModel!
    private let pagingViewController = PagingViewController()
    private var childViewController = [UIViewController]() {
        didSet {
            pagingViewController.reloadData()
        }
    }
    
//    public weak var delegate: AddPlacesContainerViewControllerDelegate?
    private var selectedButton: TRPAddPlaceFilterVC.ButtonType = .recommendation
    private var contentType: AddPlaceListContentType = .recommendation
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.places")
    }
    
    public override func setupViews() {
        super.setupViews()
        setupSearchBar()
        setupPagination()
        setupNavigation()
    }
    
    func setupSearchBar() {
        //To remove borders
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = trpTheme.color.extraBG
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.showsCancelButton = false
        searchBar.delegate = self
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = trpTheme.color.extraBG
        }
    }
    
    
    public func addViewControllerInPagination(_ viewController: UIViewController, title: String) {
        viewModel.addChildTypeOnlyTitle(title)
        childViewController.append(viewController)
    }
    
    public func addViewControllerInPagination(_ viewController: UIViewController, type: AddPlaceTypes) {
        viewModel.addChildPlaceType(type)
        if let vc = viewController as? AddPoiTableViewVC {
            vc.containerDelegate = self
        }
        childViewController.append(viewController)
    }
    
    public func addViewControllerInPagination(_ viewControllers: [UIViewController], types: [AddPlaceTypes]) {
        viewModel.addChildPlaceType(types)
        childViewController.append(contentsOf: viewControllers)
    }
    
    
    
    private func setupNavigation() {
        /*let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButtonPressed))
        navigationItem.rightBarButtonItems = [searchButton]
        */
//        if let image =  TRPImageController().getImage(inFramework: "sorting_icon", inApp: TRPAppearanceSettings.AddPoi.filterButtonImage) {
//            let sorting = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(sortingButtonPressed))
//            navigationItem.rightBarButtonItems?.append(sorting)
//        }
        addCloseButton(position: .left)
    }
    
}

extension AddPlacesContainerViewController: PagingViewControllerDelegate, PagingViewControllerDataSource, PagingViewControllerSizeDelegate {
    
    fileprivate func setupPagination() {
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pagingViewController)
        containerView.addSubview(pagingViewController.view)
        NSLayoutConstraint.activate([
            pagingViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pagingViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            pagingViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        //let topBarHeight = self.navigationController?.navigationBar.frame.height ?? 0.0
//        view.constrainToEdges(pagingViewController.view, topSpacing: 10)
        pagingViewController.didMove(toParent: self)
        
        pagingViewController.dataSource = self
        pagingViewController.menuItemSize = .selfSizing(estimatedWidth: 80, height: 48)
        pagingViewController.delegate = self
        //pagingViewController.sizeDelegate = self
        pagingViewController.backgroundColor = trpTheme.color.extraBG
        
        pagingViewController.selectedBackgroundColor = trpTheme.color.extraBG
        pagingViewController.menuBackgroundColor = trpTheme.color.extraBG
        pagingViewController.borderColor = trpTheme.color.extraBG
        pagingViewController.selectedTextColor = trpTheme.color.tripianPrimary
        pagingViewController.selectedFont = trpTheme.font.display
        pagingViewController.font = trpTheme.font.display
        pagingViewController.textColor = trpTheme.color.tripianTextPrimary
        pagingViewController.indicatorColor = trpTheme.color.tripianPrimary
        pagingViewController.indicatorOptions = .visible(height: 1, zIndex: Int.max, spacing: .init(top: 0, left: 10, bottom: 0, right: 10),insets: .zero)
        
        view.bringSubviewToFront(pagingViewController.view)
    }
    
    public func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        childViewController.count
    }
    
    public func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        return childViewController[index]
    }
    
    public func pagingViewController(_: PagingViewController, willScrollToItem pagingItem: Parchment.PagingItem, startingViewController: UIViewController, destinationViewController: UIViewController) {
        print("[Info] Will Changed")
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchBar.text = ""
            searchBar.resignFirstResponder()
            getCurrentViewModel()?.updateContentMode(.recommendation)
        }
    }
    
    public func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        let title = viewModel.getPagingTitle(index: index)
        return PagingIndexItem(index: index, title: title)
    }
    
    public func pagingViewController(_: PagingViewController, widthForPagingItem pagingItem: PagingItem, isSelected: Bool) -> CGFloat {
        guard let item = pagingItem as? PagingIndexItem else { return 0 }
        
        let insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: pagingViewController.menuItemSize.height)
        
        let attributes = [NSAttributedString.Key.font: pagingViewController.font]
        
        let rect = item.title.boundingRect(with: size,
                                           options: .usesLineFragmentOrigin,
                                           attributes: attributes,
                                           context: nil)
        
        let width = ceil(rect.width) + insets.left + insets.right
        //let fullWidth = CGFloat(viewModel.getPagingNumber()) * width
        
        let pagingNumber = childViewController.count
        
        let fullWidth = CGFloat(pagingNumber) * width
        let windowsWidth = self.view.frame.width
        if fullWidth < windowsWidth {
            return windowsWidth / CGFloat(pagingNumber)
        }
        /*if isSelected {
            return width * 1.5
        } else {
            return width
        }*/
        return width
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if let currentVM = getCurrentViewModel() {
            searchBar.text = ""
            searchBar.resignFirstResponder()
            currentVM.cancelSearch()
        }
    }
    
    private func getCurrentViewModel() -> AddPoisTableViewViewModel? {
        if let indexItem = pagingViewController.state.currentPagingItem as? PagingIndexItem,
           let addPoiVC = childViewController[indexItem.index] as? AddPoiTableViewVC {
            return addPoiVC.viewModel
        }
        return nil
    }
    
}

extension AddPlacesContainerViewController {
    
    private func openSortViewController() {
        let vc = TRPAddPlaceFilterVC(selectedButton: selectedButton) { [weak self] (selected) in
            guard let strongSelf = self else {return}
            strongSelf.selectedButton = selected
            if selected == .nearBy {
                strongSelf.contentType = AddPlaceListContentType.nearBy
            }else if selected == .recommendation {
                strongSelf.contentType = AddPlaceListContentType.recommendation
            }
            /*if selected == .nearBy && strongSelf.isUserInCity == TRPUserLocationController.UserStatus.outCity {
                for listView in strongSelf.addPlacesListViews{
                    listView.value.clearDataForNearBy()
                }
                return
            }*/
            for child in strongSelf.childViewController{
                if let addPoiVc = child as? AddPoiTableViewVC {
                    let sorting: AddPlaceListContentType = selected == TRPAddPlaceFilterVC.ButtonType.nearBy ? .nearBy : .recommendation
                    
                    addPoiVc.changeContentMode(sorting)
                }
               
            }
        }
        vc.message = "Sort by".toLocalized()
        vc.recommendataionText = "Recommended".toLocalized()
        vc.nearByText = "Nearby".toLocalized()
        self.present(vc.getVC(), animated: true, completion: nil)
    }
    
}

extension AddPlacesContainerViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        requestWorkItem?.cancel()
        let newRequest = DispatchWorkItem { [weak self] in
            if let currentVM = self?.getCurrentViewModel() {
                if currentVM.contentMode != .search {
                    currentVM.changeContentMode(.search)
                }
                currentVM.searchText(searchText)
            }
        }
        
        requestWorkItem = newRequest
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(650), execute: newRequest)
    }
}

extension AddPlacesContainerViewController: AddPoiTableViewVCContainerDelegate {
    public func searchCleared() {
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchBar.text = ""
            getCurrentViewModel()?.updateContentMode(.recommendation)
        }
    }
    
    
}
