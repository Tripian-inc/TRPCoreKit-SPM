//
//  BookingListViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

import SDWebImage

final class BookingListViewController: TRPBaseUIViewController {
    
    private var viewModel: BookingListViewModel
    private var tableView: EvrTableView = EvrTableView()
    private var selectedCellModel: BookingCellModel?
    private var isViewAppear = false
    
    init(viewModel: BookingListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookings" //TRPAppearanceSettings.FavoriteVC.title
//        navigationController?.navigationBar.prefersLargeTitles = true
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil) 
    }
    
    override func setupViews() {
        super.setupViews()
        addCloseButton(position: .left)
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewModel.checkMyBookingsStatus()
    }
    
    @objc func applicationWillEnterForeground(_ notification: NSNotification) {
        if let cellModel = selectedCellModel {
            viewModel.checkMyBookigStatus(bookingId: cellModel.id)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension BookingListViewController: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 72;
        tableView.register(cellClass: BookingListViewCell.self)
        
        tableView.setEmptyText("No bookings yet.")
        tableView.separatorStyle = .none
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: BookingListViewCell.self, forIndexPath: indexPath)
        let model = viewModel.getCellViewModel(at: indexPath)
        cell.index = indexPath.row
        cell.titleLabel.text = model.title
        
        if let provider = viewModel.getProvider(at: indexPath), let time = viewModel.getTimeDate(at: indexPath) {
            cell.addSubtitle(provider: provider, dateTime: time)
        }
        
        let imageUrl = viewModel.getImageUrl(at: indexPath, width: 0, height: 0)
        cell.getImageView().sd_setImage(with: imageUrl, completed: .none)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getCellViewModel(at: indexPath)
        selectedCellModel = model
        openUrl(url: model.confirmUrl)
    }
 
    public func openUrl(url: URL?) {
        guard let url = url else {
            print("[ERROR] URL İS NİL")
            return
        }
        UIApplication.shared.open(url)
    }
    
}

extension BookingListViewController {
    
    override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
}
