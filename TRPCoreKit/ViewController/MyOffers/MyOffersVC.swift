//
//  MyOffersVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit

import SDWebImage


public protocol MyOffersVCDelegate:AnyObject {
    func myOffersVCOpenPlaceDetail(viewController: UIViewController, poi: TRPPoi)
}

class MyOffersVC: TRPBaseUIViewController {

    @IBOutlet weak var tableView: EvrTableView!
    public var viewModel: MyOffersViewModel!
    public weak var delegate: MyOffersVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Offers"

    }
    
    public override func setupViews() {
        super.setupViews()
        addCloseButton(position: .left)
        setupTableView()
        viewModel.start()
    }

}

extension MyOffersVC: UITableViewDelegate, UITableViewDataSource{
    
    fileprivate func setupTableView() {
        tableView.setEmptyText("No offers yet.".toLocalized())
        tableView.separatorStyle = .none
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = viewModel.getCellViewModel(at: indexPath)
        
        let cell = tableView.dequeue(cellClass: PoiDetailOfferCell.self, forIndexPath: indexPath)
        cell.configurate(cellModel)
        if #available(iOS 13.0, *) {
            let action = UIAction(handler: { action in
                self.viewModel.deleteMyOffer(offerId: cellModel.offerId)
            })
            if #available(iOS 14.0, *) {
                cell.imInBtn.addAction(action, for: .touchUpInside)
            }
        } else {
            cell.imInBtn.tag = indexPath.row
            cell.imInBtn.addTarget(self, action: #selector(self.offerOptInAction), for: .touchUpInside)
        }
        
        
        cell.selectionStyle = .none
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel = viewModel.getCellViewModel(at: indexPath)
        if let poi = cellModel.poi {
            delegate?.myOffersVCOpenPlaceDetail(viewController: self, poi: poi)
        }
    }
    
    @objc private func offerOptInAction(sender: UIButton) {
        let cellModel = viewModel.cellViewModels[sender.tag]
        self.viewModel.deleteMyOffer(offerId: cellModel.offerId)
    }
    
}

extension MyOffersVC: MyOffersVMDelegate {
    
    public override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }

}
