//
//  ReviewsViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 24.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPFoundationKit




public class ReviewsViewController: UIViewController {
    
    private var tableView: EvrTableView = EvrTableView()
    private let viewModel: ReviewsViewModel
    private var loader: TRPLoaderView?
    
    
    public init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        title = "Reviews"
        setupTableView()
        loader = TRPLoaderView(superView: view)
        //setupView()
        viewModel.start()
        
        if let image = TRPImageController().getImage(inFramework: "sorting_icon", inApp: TRPAppearanceSettings.AddPoi.sortingButtonImage) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(sortingPressed))
        }
    }
    
    @objc func sortingPressed() {
        print("Sorting Pressed")
        showSortingAlertController()
    }
    
}

extension ReviewsViewController{
    private func showSortingAlertController() {
        
        let alertController = UIAlertController(title: "Sort by", message: nil, preferredStyle: .actionSheet)
        
        let sortingByDate = UIAlertAction(title: "Newest First", style: .default, handler: {[weak self] _  in
            self?.viewModel.fetchDataWithSort(.newestFirst)
        })
        
        let sortingByGood = UIAlertAction(title: "Highest Rated", style: .default, handler: { [weak self] _  in
            self?.viewModel.fetchDataWithSort(.highestRated)
        })
        
        let sortingByBad = UIAlertAction(title: "Lowest Rated", style: .default, handler: { [weak self]_  in
            self?.viewModel.fetchDataWithSort(.lowestRated)
        })
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(sortingByDate)
        alertController.addAction(sortingByGood)
        alertController.addAction(sortingByBad)
        alertController.addAction(cancelActionButton)
        
        present(alertController, animated: true, completion: nil)
    }
}


extension ReviewsViewController: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        tableView = EvrTableView(frame: CGRect.zero)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.register(cellClass: ReviewsCell.self)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ReviewsCell.self, forIndexPath: indexPath)
        
        let model = viewModel.getCellViewModel(at: indexPath)
        
        cell.reviewLbl.text = model.comment
        cell.userNameLbl.text = model.reviewerName
        
        if let textToTime = TRPTime(dateTime: model.reviewDate), let date = textToTime.toDate {
            cell.starAndDateLbl.text = "\(model.reviewRating) • \(date.toString(dateStyle: .medium))"
        }
    
        cell.selectionStyle = .none
        return cell
    }
    
}

extension ReviewsViewController: ViewModelDelegate {

    public func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
    public func viewModel(error: Error) {
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    public func viewModel(showPreloader: Bool) {
        if showPreloader {
            loader?.show()
        }else {
            loader?.remove()
        }
    }
}

