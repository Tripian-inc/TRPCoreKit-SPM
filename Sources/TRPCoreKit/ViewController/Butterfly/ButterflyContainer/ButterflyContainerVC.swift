//
//  ButterflyContainerVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.05.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPUIKit
import TRPDataLayer

public protocol ButterFlyContainerVCProtocol: AnyObject {
    func butterflyContainerOpenPlaceDetail(place: TRPPoi)
    func butterflyContainerCompleted(hash: String)
    func butterflyContainerViewDidAppear(_ vc: UIViewController)
}

extension ButterFlyContainerVCProtocol {
    public func butterflyContainerViewDidAppear(_ vc: UIViewController) {}
}

class ButterFlyContainerVC: TRPBaseUIViewController {
    
    private let viewModel: ButterflyContainerVM
    private var butterflyTableView = UITableView(frame: .zero)
    public weak var delegate: ButterFlyContainerVCProtocol?
    
    init(viewModel: ButterflyContainerVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = TRPAppearanceSettings.Butterfly.title
        viewModel.start()
    }
    
    override func setupViews() {
        super.setupViews()
        addApplyButton()
        setupTableView()
        applyButton.setTitle("Create My Trip", for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        delegate?.butterflyContainerViewDidAppear(self)
    }
 
    override func applyButtonPressed() {
        delegate?.butterflyContainerCompleted(hash: viewModel.tripHash)
    }
    
}

//MARK: - UITableView Delegate&DataSource
extension ButterFlyContainerVC: UITableViewDelegate, UITableViewDataSource {
    
    private func setupTableView() {
        butterflyTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(butterflyTableView)
        
        let constraint = [
            butterflyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            butterflyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            butterflyTableView.topAnchor.constraint(equalTo: view.topAnchor),
            butterflyTableView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -16)
        ]
        NSLayoutConstraint.activate(constraint)
        butterflyTableView.dataSource = self
        butterflyTableView.delegate = self
        butterflyTableView.register(cellClass: ButterflyContainerCell.self)
        butterflyTableView.register(cellClass: ExplaineCell.self)
        butterflyTableView.register(cellClass: UITableViewCell.self)
        butterflyTableView.rowHeight = UITableView.automaticDimension
        butterflyTableView.estimatedRowHeight = TRPAppearanceSettings.Butterfly.collectionCellHeight + 84
        butterflyTableView.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = viewModel.getCellViewModel(at: indexPath)
        
        if model.type == .explain, let message = model.data as? String {
            return makeExplaine(tableView, cellForRowAt: indexPath, data: message)
        }else if model.type == .butterfly, let ourPickModel = model.data as? ButterflyCollectionModel {
            return makeOurPickCell(tableView, cellForRowAt: indexPath, data:ourPickModel)
        }
        
        let cell = tableView.dequeue(cellClass: UITableViewCell.self, forIndexPath: indexPath)
        return cell
    }
    
    /*func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TRPAppearanceSettings.Butterfly.collectionCellHeight + 84
    } */
    
    func reloadSubVC(){}
    
}

//MARK: - Cell maker
extension ButterFlyContainerVC {
    
    private func makeOurPickCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, data: ButterflyCollectionModel)-> ButterflyContainerCell {
        let cell = tableView.dequeue(cellClass: ButterflyContainerCell.self, forIndexPath: indexPath)
        cell.setupCell(containerVC: self, cellModel: data)
        cell.categoryTitle.text = data.title
        cell.selectionStyle = .none
        cell.openPlaceHandler = { [weak self] place in
            guard let stronSelf = self else {return}
            stronSelf.delegate?.butterflyContainerOpenPlaceDetail(place: place)
        }
        return cell
    }
    
    private func makeExplaine(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, data: String)-> ExplaineCell {
        let cell = tableView.dequeue(cellClass: ExplaineCell.self, forIndexPath: indexPath)
        cell.explaineLabel.text = data
        cell.selectionStyle = .none
        cell.closePressedHandler = {[weak self] in
            guard let strongSelf = self else {return}
            strongSelf.viewModel.removeCell(at: indexPath)
        }
        return cell
    }
}


extension ButterFlyContainerVC: ButterflyContainerVMDelegate {
    
    func butterflyContainerVMStepsEmpty() {
        delegate?.butterflyContainerCompleted(hash: viewModel.tripHash)
    }
    
    override func viewModel(dataLoaded: Bool) {
        butterflyTableView.reloadData()
    }
    
}
