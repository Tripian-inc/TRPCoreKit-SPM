//
//  ExperienceMoreInfoViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-07.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

public class ExperienceMoreInfoViewController: TRPBaseUIViewController {
    
    private var tableView: EvrTableView = EvrTableView()
    private var viewModel: ExperienceMoreInfoViewModel
    
    init(viewModel: ExperienceMoreInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "More Info"
        addBackButton(position: .left)
//        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    public override func setupViews() {
        super.setupViews()
       // addCloseButton(position: .left)
        setupTableView()
        viewModel.start()
    }
    
}

extension ExperienceMoreInfoViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        tableView.estimatedRowHeight = 200
        tableView.register(cellClass: ExperienceHeaderCell.self)
        tableView.register(cellClass: ExperienceBasicCell.self)
        tableView.setEmptyText("No data")
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.separatorStyle = .none
        tableView.isHiddenEmptyText = true
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = viewModel.getCellViewModel(at: indexPath)
        
        if model.type == .title {
            return makeHeaderCell(tableView, cellForRowAt: indexPath, model: model)
        }
        return makeBasicCell(tableView, cellForRowAt: indexPath, model: model)
    }
    
}

extension ExperienceMoreInfoViewController {
    private func makeBasicCell(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath,
                               model: ExperienceMoreInfoModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceBasicCell.self, forIndexPath: indexPath)
        cell.contentLabel.text = model.content
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeHeaderCell(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath,
                               model: ExperienceMoreInfoModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceHeaderCell.self, forIndexPath: indexPath)
        cell.headerLabel.text = model.content
        cell.selectionStyle = .none
        return cell
    }
}


extension ExperienceMoreInfoViewController {
    
    public override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
}
