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


public class ExperiencesViewController: TRPBaseUIViewController {
    
    @IBOutlet weak var tableView: EvrTableView!
    var viewModel: ExperiencesViewModel?
    public weak var delegate: ExperiencesViewControllerDelegate?
    
    func setViewModel(viewModel: ExperiencesViewModel) {
        self.viewModel = viewModel
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Experiences"
        
    }
    
    public override func setupViews() {
        super.setupViews()
        addCloseButton(position: .left)
        setupTableView()
        viewModel?.start()
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
        tableView.setEmptyText("No experiences yet.")
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
            if let url = URL(string: model.image){
                cell.imgTOur.sd_setImage(with: url, placeholderImage: nil)
            }
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
