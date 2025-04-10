//
//  CreateTripSelectTimeVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 2.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit

protocol ItineraryChangeTimeVCDelegate: AnyObject {
    func createTripSelectTimeVCArrivalSelected(hour: String)
    func createTripSelectTimeVCDepartureSelected(hour: String)
}

@objc(SPMItineraryChangeTimeVC)
class ItineraryChangeTimeVC: TRPBaseUIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tblTimeFrom: UITableView!
    @IBOutlet weak var tblTimeTo: UITableView!
    @IBOutlet weak var btnApply: UIButton!
    @IBOutlet weak var lblEstimatedTime: UILabel!
    
    public weak var delegate: ItineraryChangeTimeVCDelegate?
    public var viewModel: ItineraryChangeTimeViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.start()
    }
    
    override func setupViews() {
        super.setupViews()
        tblTimeFrom.allowsMultipleSelection = false
        tblTimeFrom.separatorStyle = .none
        tblTimeTo.allowsMultipleSelection = false
        tblTimeTo.separatorStyle = .none
        
        titleLabel.font = trpTheme.font.header2
        titleLabel.text = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.customPoiModal.visitTime.title")
        
        lblEstimatedTime.font = trpTheme.font.caption
        lblEstimatedTime.text = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.addToItinerary.estimatedDuration") + ": " + viewModel.getEstimatedTime()
        
        btnApply.backgroundColor = trpTheme.color.tripianPrimary
        btnApply.layer.cornerRadius = 10
        btnApply.setTitle(TRPLanguagesController.shared.getApplyBtnText(), for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        
        scrollToSelectedHour()
    }
    
    @IBAction func applyAction(_ sender: Any) {
        viewModel.applyChanges()
        dismiss(animated: true)
    }
}

extension ItineraryChangeTimeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tblTimeFrom {
            return viewModel.getFromRowCount()
        } else {
            return viewModel.getToRowCount()
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripSelectTimeCell", for: indexPath) as! CreateTripSelectTimeCell
        var hour = ""
        var isSelected = false
        if tableView == tblTimeFrom {
            hour = viewModel.getFromHour(indexPath: indexPath)
            isSelected = viewModel.isSelectedFromHour(hour: hour)
        } else {
            hour = viewModel.getToHour(indexPath: indexPath)
            isSelected = viewModel.isSelectedToHour(hour: hour)
        }
        cell.setText(text: hour, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? CreateTripSelectTimeCell{
            cell.isSelectedTime = true
        }
        if tableView == tblTimeFrom {
            viewModel.setSelectedFromHour(indexPath: indexPath)
        } else {
            viewModel.setSelectedToHour(indexPath: indexPath)
        }
        tblTimeFrom.reloadData()
        tblTimeTo.reloadData()
    }
    
    private func scrollToSelectedHour() {
        tblTimeFrom.scrollToRow(at: viewModel.getSelectedFromHourIndexPath(), at: .top, animated: true)
        tblTimeTo.scrollToRow(at: viewModel.getSelectedToHourIndexPath(), at: .top, animated: true)
    }
}
