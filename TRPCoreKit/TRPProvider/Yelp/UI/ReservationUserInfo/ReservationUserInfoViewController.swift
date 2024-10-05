//
//  ReservationUserInfoViewController.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 8.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit


public protocol ReservationUserInfoViewControllerDelegate: AnyObject {
    func reservationUserInfoCompleted(_ viewController: UIViewController, reservation: Reservation, result: YelpReservation)
}

public class ReservationUserInfoViewController: UIViewController {
    
    private(set) var viewModel: ReservationUserInfoViewModel
    private(set) var tableView = UITableView()
    private var loader: TRPLoaderView?
    
    private var continueButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Apply", for: .normal)
        btn.backgroundColor = TRPColor.pink
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        btn.layer.cornerRadius = 6
        return btn
    }()
    
    public weak var delegate: ReservationUserInfoViewControllerDelegate?
    
    public init(viewModel: ReservationUserInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        loader = TRPLoaderView(superView: self.view)
        //Todo: -  Coordinater'a taşınacak
        viewModel.delegate = self
        viewModel.start()
        setupButtonUI()
        setupTableView()
    }
    
    private func setupButtonUI() {
        view.addSubview(continueButton)
        continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        if #available(iOS 11.0, *) {
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        }else {
            continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16).isActive = true
        }
        continueButton.addTarget(self, action: #selector(applyPressed), for: UIControl.Event.touchUpInside)
    }
    
    @objc func applyPressed() {
        viewModel.makeAReservation()
    }
    
}

extension ReservationUserInfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: continueButton.topAnchor).isActive = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(ReservationUserInfoCell.self, forCellReuseIdentifier: "userInfoCell")
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 95
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userInfoCell", for: indexPath) as! ReservationUserInfoCell
        let model = viewModel.getCellViewModel(at: indexPath)
        
        cell.titleLabel.text = model.title
        cell.inputText.addTarget(self, action: #selector(inputTextChanged(_:)), for: .editingChanged)
        if model.contentType == .userName {
            cell.inputText.placeholder = "User Name"
            cell.inputText.text = viewModel.userName
            cell.inputText.tag = 1
        }else if model.contentType == .lastName {
            cell.inputText.placeholder = "Last Name"
            cell.inputText.text = viewModel.lastName
            cell.inputText.tag = 2
        }else if model.contentType == .phone {
            cell.inputText.placeholder = "Phone Number"
            cell.inputText.text = viewModel.phone
            cell.inputText.tag = 3
            cell.inputText.keyboardType = .numberPad
        }else if model.contentType == .email {
            cell.inputText.placeholder = "E-Mail"
            cell.inputText.text = viewModel.email
            cell.inputText.tag = 4
            cell.inputText.keyboardType = .emailAddress
        }
        cell.selectionStyle = .none
        return cell
    }
    
    @objc func inputTextChanged(_ sender: UITextField) {
        switch sender.tag {
        case 1:
            viewModel.userName = sender.text
        case 2:
            viewModel.lastName = sender.text
        case 3:
            viewModel.phone = sender.text
        case 4:
            viewModel.email = sender.text
        default: ()
        }
    }
    
}

extension ReservationUserInfoViewController: ReservationUserInfoViewModelDelegate {
    
    public func reservationUserInfoViewModelCompleted(reservation: Reservation, result: YelpReservation) {
        delegate?.reservationUserInfoCompleted(self, reservation: reservation, result: result)
    }
    
    public func reservationUserInfoViewModel(error: Error) {
        TRPMessage(contentText: error.localizedDescription, type: .error, closeTime: 4).show()
    }
    
    public func reservationUserInfoViewModel(message: String) {
        TRPMessage(contentText: message, type: .error, closeTime: 4).show()
    }
    
    public func reservationUserInfoViewModel(showLoader: Bool) {
        if showLoader {
            loader?.show()
        }else {
            loader?.remove()
        }
    }
    
}
