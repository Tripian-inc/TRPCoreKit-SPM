//
//  CompanionCollectionViewCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

@objc(SPMCompanionQuestionAnswersCell)
class CompanionQuestionAnswersCell: UITableViewCell {

    @IBOutlet weak var tableView: AutoResizeTableView!
    
    var viewModel: CompanionQuestionAnswersVM!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTableView()
    }
    
    func configure() {
        
        tableView.reloadData()
        tableView.layoutIfNeeded()
    }

}

extension CompanionQuestionAnswersCell: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withReuseIdentifier: "CheckboxCell", for: indexPath) as? CheckboxCell else { return CheckboxCell()
        }
        let cellInfo = viewModel.cellInfo(indexPath)
        cell.label.text = cellInfo.name
        cell.itemSelected = viewModel.isItemSelected(id: cellInfo.id)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = viewModel.cellInfo(indexPath).id
        let itemIsSelected = viewModel.isItemSelected(id: id)
        
        viewModel.itemSelectionToggled(id: id)
        configure()
    }
}

@objc(SPMAutoResizeTableView)
class AutoResizeTableView: UITableView {
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return self.contentSize
    }

    override var contentSize: CGSize {
        didSet{
            self.invalidateIntrinsicContentSize()
        }
    }

    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
}
