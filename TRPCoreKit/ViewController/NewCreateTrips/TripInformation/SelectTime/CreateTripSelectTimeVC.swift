//
//  CreateTripSelectTimeVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 2.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit

protocol CreateTripSelectTimeVCDelegate: AnyObject {
    func createTripSelectTimeVCArrivalSelected(hour: String)
    func createTripSelectTimeVCDepartureSelected(hour: String)
}
@objc(SPMCreateTripSelectTimeVC)
class CreateTripSelectTimeVC: TRPBaseUIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    public weak var delegate: CreateTripSelectTimeVCDelegate?
    public var viewModel: CreateTripSelectTimeViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
//        tableView.isPagingEnabled = true
    }
    
    override func setupViews() {
        super.setupViews()
        tableView.allowsMultipleSelection = false
        tableView.separatorStyle = .none
        
        titleLabel.font = trpTheme.font.header2
        titleLabel.text = viewModel.getTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        
        scrollToSelectedHour()
    }
}

extension CreateTripSelectTimeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.getRowCount()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CreateTripSelectTimeCell", for: indexPath) as! CreateTripSelectTimeCell
        let hour = viewModel.getHour(indexPath: indexPath)
        cell.setText(text: hour, isSelected: viewModel.isSelectedHour(hour: hour))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? CreateTripSelectTimeCell{
            cell.isSelectedTime = true
        }
        self.setSelectedHour(indexPath: indexPath)
    }
    
    private func scrollToSelectedHour() {
        let indexPath = viewModel.getSelectedHourIndexPath()
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}

extension CreateTripSelectTimeVC {
    
    private func setSelectedHour(indexPath: IndexPath) {
        let selectedHour = viewModel.getHour(indexPath: indexPath)
        if viewModel.isArrival {
            self.delegate?.createTripSelectTimeVCArrivalSelected(hour: selectedHour)
        } else {
            self.delegate?.createTripSelectTimeVCDepartureSelected(hour: selectedHour)
        }
        self.dismiss(animated: true)
    }
}
