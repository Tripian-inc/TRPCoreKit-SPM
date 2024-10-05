//
//  FavoritesVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 3.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit
import SDWebImage
import TRPDataLayer

public protocol FavoritesVCDelegate:AnyObject {
    func favoriteVCOpenPlaceDetail(viewController:UIViewController, poi: TRPPoi)
}

public class FavoritesVC: TRPBaseUIViewController {
    
    @IBOutlet weak var tb: EvrTableView!
    public var viewModel: FavoritesViewModel!
    private let modeType: SdkModeType = .Trip
    public weak var delegate: FavoritesVCDelegate?
    
   
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = TRPAppearanceSettings.FavoriteVC.title
    }
    
    public override func setupViews() {
        super.setupViews()
        addCloseButton(position: .left)
        setupTableView()
        viewModel.start()
    }
    
    
    
}

extension FavoritesVC: UITableViewDelegate, UITableViewDataSource{
    
    fileprivate func setupTableView() {
        tb.setEmptyText("No favorites yet.".toLocalized())
        tb.separatorStyle = .none
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: FavoritesTableViewCell.self, forIndexPath: indexPath)
        let model = viewModel.getCellViewModel(at: indexPath)
        
        cell.index = indexPath.row
        cell.titleLbl.text = model.name
        
        if let imageUrl = viewModel.getImageUrl(at: indexPath, width: 0, height: 0) {
            cell.placeImage.sd_setImage(with: imageUrl)
        }else {
            cell.placeImage.image = nil
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = viewModel.getCellViewModel(at: indexPath)
        delegate?.favoriteVCOpenPlaceDetail(viewController: self, poi: place)
    }
    
}

extension FavoritesVC: FavoritesVMDelegate {
    
    public override func viewModel(dataLoaded: Bool) {
        tb.reloadData()
    }

}
