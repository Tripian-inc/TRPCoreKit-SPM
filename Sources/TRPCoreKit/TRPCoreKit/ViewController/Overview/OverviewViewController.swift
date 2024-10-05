//
//  OverviewViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-02.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit
import SDWebImage
import TRPDataLayer


class OverviewViewController: TRPBaseUIViewController {
    
    @IBOutlet weak var tb: EvrTableView!
    public var viewModel: OverviewViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.start()
    }
    
    override func setupViews() {
        super.setupViews()
        setupTableView()
    }
}
extension OverviewViewController: UITableViewDelegate, UITableViewDataSource{
    
    fileprivate func setupTableView() {
        tb.delegate = self
        tb.dataSource = self
        tb.rowHeight = UITableView.automaticDimension;
        tb.estimatedRowHeight = 98
        tb.backgroundColor = UIColor.white
        tb.separatorStyle = .none
    }
    
    //Cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getStepCount()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OverviewVCTableViewCell", for: indexPath) as? OverviewVCTableViewCell else { return UITableViewCell()}
        
        let cellModel = viewModel.getCellModel(indexPath: indexPath)
        cell.configCell(with: cellModel)
        return cell
    }
    
}

extension OverviewViewController: OverviewViewModelDelegate {
   
    
    public override func viewModel(dataLoaded: Bool) {
        tb.reloadData()
    }

}
