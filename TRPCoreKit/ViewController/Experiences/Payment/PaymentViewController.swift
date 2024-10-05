//
//  PaymentViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-21.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit


public class PaymentViewController: TRPBaseUIViewController {
    
    private var tableView: EvrTableView = EvrTableView()
    private var viewModel: PaymentViewModel
    private var tableViewKeyboard: TableViewKeyboardController?
    
    init(viewModel: PaymentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableViewKeyboard = TableViewKeyboardController(tableView: tableView)
        title = "Payment"
//        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    public override func setupViews() {
        super.setupViews()
        addApplyButton()
        setupTableView()
        
        applyButton.setTitle("Pay now", for: .normal)
        viewModel.start()
    }
    
    override func applyButtonPressed() {
        //TODO: ERROR YAZILACAK
        if !viewModel.isValidInputValues() { return }
        viewModel.sendCardInfo()
    }
    
}

extension PaymentViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        tableView.register(cellClass: PaymentReviewCell.self)
        tableView.register(cellClass: PaymentCVCExpireCell.self)
        tableView.register(cellClass: PaymentCreditCardsCell.self)
        
        
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
        
        if model.cellType == .input {
            return makeInputCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.cellType == .doubleInput {
            return makeDoubleInputCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.cellType == .reviewOrder {
            return makeReviewOrder(tableView, cellForRowAt: indexPath, model: model)
        }else if model.cellType == .cardImages {
            return makeCardImagesCell(tableView, cellForRowAt: indexPath, model: model)
        }
        return makeTitleCell(tableView, cellForRowAt: indexPath, model: model)
    }
    
}

extension PaymentViewController {
    
    private func makeTitleCell(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath,
                               model: PaymentVieUIwModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: TRPBigTitleTableViewCell.self, forIndexPath: indexPath)
        cell.titleLabel.text = model.placeHolder
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeReviewOrder(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath,
                                 model: PaymentVieUIwModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PaymentReviewCell.self, forIndexPath: indexPath)
        if let data = model.data, let content = data as? PaymentReviewOrder {
            cell.configurate(content)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    
    private func makeInputCell(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath,
                               model: PaymentVieUIwModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: TRPInputTableViewCell.self, forIndexPath: indexPath)
        cell.inputText.placeholder = model.placeHolder
        cell.titleLabel.text = model.placeHolder
        cell.selectionStyle = .none
        
        if model.type == .cardName {
            cell.inputText.keyboardType = .namePhonePad
        }else if model.type == .cardNumber {
            cell.inputText.keyboardType = .numberPad
            cell.inputText.addTarget(self, action: #selector(creditCardWillBeChanged(_:)), for: .editingChanged)
        }
        
        cell.action = { [weak self] text in
            if model.type == .cardName {
                self?.viewModel.setHolderName(text)
                
            }else if model.type == .cardNumber {
                self?.viewModel.setCardNo(text.removeWhiteSpace())
            }
        }
        return cell
    }
    
    private func makeDoubleInputCell(_ tableView: UITableView,
                                     cellForRowAt indexPath: IndexPath,
                                     model: PaymentVieUIwModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: PaymentCVCExpireCell.self, forIndexPath: indexPath)
        cell.selectionStyle = .none
        cell.action = { [weak self] text, tag in
            if tag == PaymentCVCExpireCell.MMYYInputTag {
                self?.viewModel.setMMYY(text)
            }else if tag == PaymentCVCExpireCell.cvcInputTag {
                self?.viewModel.setCVC(text)
            }
        }
        return cell
    }
    
    
    private func makeCardImagesCell(_ tableView: UITableView,
                                     cellForRowAt indexPath: IndexPath,
                                     model: PaymentVieUIwModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: PaymentCreditCardsCell.self, forIndexPath: indexPath)
        if let cards = model.data as? [GYGCardType] {
            cell.setupCards(cards)
        }
        cell.selectionStyle = .none
        return cell
    }
    

    @objc func creditCardWillBeChanged(_ sender: UITextField) {
        sender.text = (sender.text ??  "").readableCreditCart()
    }

    private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
}


extension PaymentViewController: PaymentViewModelDelegate {
    func showSuccessMessage() {
        showOkAlert(title: "Your payments was successful",message: "You can see your reservations on My Bookings screen")
    }
    
    override func closedPopup() {
        self.dismissView()
    }
    
    func paymentViewModelPaymentSuccessfull(_ card: GYGPaymentResult?) {
        
    }
    
    public override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
}

