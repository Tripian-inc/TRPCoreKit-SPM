//
//  AddPoisTableViewVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 11.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit
import TRPFoundationKit
import SDWebImage
import TRPDataLayer


public protocol AddPoiTableViewVCDelegate:AnyObject {
    func addPlaceTableViewViewControllerOpenPlace(_ viewController: UIViewController, poi: TRPPoi)
}

class AddPoiTableViewVC: TRPBaseUIViewController {
    
    public var viewModel: AddPoisTableViewViewModel!
    private var heightUpdated = false
    weak var delegate: AddPoiTableViewVCDelegate?
    @IBOutlet weak var tb: EvrTableView!
    
    fileprivate var isViewAppear = false
    //TODO: USECASE E ALINACAK
    var isUserInCity = TRPUserLocationController.UserStatus.inCity
    private var refreshControl: UIRefreshControl?
    private var lastShownIndex = -1
    
    
    override func viewDidLayoutSubviews() {
        if !heightUpdated {
            heightUpdated = true
            tb.frame = CGRect(x: 0, y: 0, width: tb.frame.width, height: self.view.frame.height)
        }
    }
   
    public func clearDataForNearBy() {
        viewModel.changeContentMode(.nearBy)
    }
    
    override func setupViews() {
        super.setupViews()
        
        //TODO: USE CASE
        TRPUserLocationController.shared.isUserInCity { [weak self] (cityId, status, location) in
            guard let strongSelf = self else {return}
            strongSelf.isUserInCity = status
        }
        setupTableView()
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh".toLocalized())
        refreshControl!.addTarget(self, action: #selector(refreshData), for: UIControl.Event.valueChanged)
        tb.addSubview(refreshControl!)
        
        viewModel.start()
    }
    
    @objc private func refreshData() {
        viewModel.fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if viewModel.isDataFetched && viewModel.getPlaceCount() == 0{
            showNoDataWarning()
        }
    }
    
    fileprivate func showNoDataWarning() {
        if viewModel.contentMode == .recommendation  {
            tb.setEmptyText(TRPAppearanceSettings.AddPlace.recommendedPoiListTextIsEmpty)
        }else {
            if isUserInCity == .outCity {
                var name: String = ""
                if let city = viewModel.getCity() {
                    name = city.name
                }
                let alertName = "\(TRPAppearanceSettings.AddPlace.nearByPoiListTextIsEmpty)\(name)"
                tb.setEmptyText(alertName)
            }else {
                tb.setEmptyText(TRPAppearanceSettings.AddPlace.recommendedPoiListTextIsEmpty)
            }
        }
    }
   
    public func changeContentMode(_ mode: AddPlaceListContentType) {
        viewModel.updateContentMode(mode)
    }
    
    deinit {
        Log.deInitialize()
    }
    
}


extension AddPoiTableViewVC: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        tb.delegate = self
        tb.dataSource = self
        tb.separatorStyle = .none
        tb.keyboardDismissMode = .onDrag
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getPlaceCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
        if indexPath.row == viewModel.getPlaceCount() - 1 {
            viewModel.loadNextPage()
        }
        
        cell.config(cellModel)
        cell.selectionStyle = .none
        return cell
    }
    
    /*func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: AddPlaceListTableViewCell.self, forIndexPath: indexPath)
        let model = viewModel.getPlace(index: indexPath.row)
        let title = viewModel.getTitle(indexPath: indexPath)
        cell.setTitle(title)
        cell.index = indexPath.row
        cell.isSuggestedByTripian = viewModel.isSuggestedByTripian(id: model.id)
        //TODO: - Performans için çok kötü refactor edilmek zorunda
        //50000
        if let distance = viewModel.getDistanceFromUserLocation(toPoiLat: model.coordinate.lat, toPoiLon: model.coordinate.lon) {
            if distance < 50000 {
                let tempDis = Int(distance)
                cell.distanceLabel.text = tempDis.reableDistance()
            }
        }
        
        let explain = viewModel.getExplainText(placeId: model.id)
        cell.setExplaintText(text: explain)
        
        if let imageUrl = viewModel.getPlaceImage(indexPath: indexPath) {
            cell.getImageView().sd_setImage(with: imageUrl)
        }else {
            cell.getImageView().image = nil
        }
        if indexPath.row == viewModel.getPlaceCount() - 1 {
            viewModel.loadNextPage()
        }
        
        cell.isSuggestedByTripian = viewModel.isSuggestedByTripian(id: model.id)
        
        return cell
    }*/
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = viewModel.getPlace(index: indexPath.row)
        delegate?.addPlaceTableViewViewControllerOpenPlace(self, poi: place)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if lastShownIndex >= indexPath.row { return }
        
        let tranform = CATransform3DTranslate(CATransform3DIdentity, 0, 20, 0)
        cell.layer.transform = tranform
        cell.alpha = 0
        let delay = Double(indexPath.row - lastShownIndex) * 0.5
        UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseOut, animations: {
            cell.alpha = 1
            cell.layer.transform = CATransform3DIdentity
        })
        
        lastShownIndex = indexPath.row
    }
}

extension AddPoiTableViewVC: AddPoiTableViewVMDelegate {
    
    func viewModelShowNoDataWarning() {
        showNoDataWarning()
    }
    
    override func viewModel(dataLoaded: Bool) {
        if refreshControl != nil {
            refreshControl!.endRefreshing()
        }
        tb.reloadData()
    }
    
    override func viewModel(error: Error) {
        DispatchQueue.main.async {
            if self.refreshControl != nil {
                self.refreshControl!.endRefreshing()
            }
            EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
        }
    }
  
}


class AddPlaceCellModel {
    var title: String
    var image: URL? = nil
    var distance: String? = nil
    var explaineText: NSAttributedString? = nil
    var isSuggestion: Bool = false
    var index: Int = 0
    init(title: String) {
        self.title = title
    }
}
