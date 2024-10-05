//
//  ExperienceBillingViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-07.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol ExperienceBillingDelegate: AnyObject {
    func experienceBillingOpenPaymentVC(_ navigationController: UINavigationController?, viewController: UIViewController)
}
public class ExperienceBillingViewController: TRPBaseUIViewController {
    
    private var tableView: EvrTableView = EvrTableView()
    private var viewModel: ExperienceBillingViewModel
    public weak var delegate: ExperienceBillingDelegate?
    private var tableViewKeyboard: TableViewKeyboardController?
    
    init(viewModel: ExperienceBillingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableViewKeyboard = TableViewKeyboardController(tableView: tableView)
        title = "Billing"
        addBackButton(position: .left)
//        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    public override func setupViews() {
        super.setupViews()
        addApplyButton()
        setupTableView()
        
        applyButton.setTitle("Next", for: .normal)
        viewModel.start()
    }
    
    override func applyButtonPressed() {
        if viewModel.isValidInputs() {
            viewModel.sendBillingAndTravelInfo()
            delegate?.experienceBillingOpenPaymentVC(self.navigationController, viewController: self)
        }else {
            //TODO: - BİLGİLER EKSİK UYARISI
        }
    }
    
    
}

extension ExperienceBillingViewController: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        tableView = EvrTableView(frame: CGRect.zero)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -16).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.register(cellClass: TRPInputTableViewCell.self)
        tableView.register(cellClass: TRPBigTitleTableViewCell.self)
        tableView.register(cellClass: TRPCheckBoxTableViewCell.self)
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
        
        if model.cellType == .title {
            return makeTitleCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.cellType == .checkBox {
            return makeSwitchCell(tableView, cellForRowAt: indexPath, model: model)
        }
        
        return makeBasicCell(tableView, cellForRowAt: indexPath, model: model)
    }
    
}

extension ExperienceBillingViewController {
    
    private func makeBasicCell(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath,
                               model: ExperienceBillingModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: TRPInputTableViewCell.self, forIndexPath: indexPath)
        cell.inputText.placeholder = model.placeHolder
        cell.inputText.text = model.data != nil ? model.data! : nil
        cell.titleLabel.text = model.type.rawValue
        
        cell.action = { text in
            model.data = text
        }
        
        if model.type == .country {
            cell.beginEditingAction = { textField in
                textField.resignFirstResponder()
                self.openCountryList()
            }
        }else {
            cell.beginEditingAction = nil
        }
        
        if model.type == .firstName || model.type == .lastName {
            cell.inputText.keyboardType = .namePhonePad
        }else if model.type == .email {
            cell.inputText.keyboardType = .emailAddress
        }else if model.type == .phone {
            cell.inputText.keyboardType = .phonePad
        }
        cell.selectionStyle = .none
        return cell
    }
    
    
    
    private func makeTitleCell(_ tableView: UITableView,
                                cellForRowAt indexPath: IndexPath,
                                model: ExperienceBillingModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: TRPBigTitleTableViewCell.self, forIndexPath: indexPath)
        cell.titleLabel.text = model.placeHolder
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeSwitchCell(_ tableView: UITableView,
                                cellForRowAt indexPath: IndexPath,
                                model: ExperienceBillingModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: TRPCheckBoxTableViewCell.self, forIndexPath: indexPath)
        cell.titleLabel.text = model.placeHolder
        cell.switchButton.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.selectionStyle = .none
        return cell
    }
  
    @objc func switchChanged(_ sender: UISwitch) {
        viewModel.showTraveller(sender.isOn)
    }
    
}

extension ExperienceBillingViewController {
    
    public override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
}

extension ExperienceBillingViewController: CountryListViewControllerDelegate {
    
    private func openCountryList() {
        let countryList = CountryListViewController()
        countryList.delegate = self
        present(countryList, animated: true, completion: nil)
    }
    
    public func countryListViewControllerSelectedCountry(_ name: String, code: String) {
        viewModel.updateCountryCell(name, code)
    }
}
