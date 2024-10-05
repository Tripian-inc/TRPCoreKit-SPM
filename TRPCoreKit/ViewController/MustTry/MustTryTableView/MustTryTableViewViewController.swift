//
//  MustTryTableViewViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

import SDWebImage
import UIKit


public protocol MustTryTableViewViewControllerDelegate:AnyObject {
    func mustTryTableViewVCOpenTasteDetail(_ navigationController: UINavigationController?, viewController: UIViewController, taste: TRPTaste)
}


public class MustTryTableViewViewController: TRPBaseUIViewController {
    
    @IBOutlet weak var tableView: EvrTableView!
//    private var tableView: EvrTableView = EvrTableView()
    public var viewModel: MustTryTableViewViewModel!
//    private var loader: TRPLoaderView?
    public weak var delegate: MustTryTableViewViewControllerDelegate?
    
//    public init(viewModel: MustTryTableViewViewModel) {
//        self.viewModel = viewModel
//        super.init(nibName: nil, bundle: nil)
//    }
    
//    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.poi.mustTry.title")
        setupTableView()
    }
    
    @objc func closedPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension MustTryTableViewViewController: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
//        tableView = EvrTableView(frame: CGRect.zero)
//        view.addSubview(tableView)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 90;
//        tableView.setEmptyText("No must try yet.".toLocalized())
        tableView.separatorStyle = .none
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: FavoritesTableViewCell.self, forIndexPath: indexPath)
//        let cell = tableView.dequeue(cellClass: MustTryTableViewCell.self, forIndexPath: indexPath)
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
        let taste = viewModel.getCellViewModel(at: indexPath)
        
        delegate?.mustTryTableViewVCOpenTasteDetail(parent?.navigationController,
                                                    viewController: self, taste: taste)
        
    }
    
}
