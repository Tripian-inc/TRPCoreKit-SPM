//
//  ReservationViewController.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 7.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit

public protocol ReservationViewControllerDelegate: AnyObject {
    func reservationViewController(reservation: Reservation, hold: YelpHolds, business: YelpBusiness?)
}

public class ReservationViewController: UIViewController {
    
    
    private(set) var viewModel: ReservationViewModel
    private var loader: TRPLoaderView?
    private(set) var tableView = UITableView()
    
    private var continueButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Make a Reservation", for: .normal)
        btn.backgroundColor = TRPColor.pink
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(applyPressed), for: UIControl.Event.touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        btn.layer.cornerRadius = 6
        return btn
    }()
    private var peopleLimit = 7
    public weak var delegate: ReservationViewControllerDelegate?
    
    public init(viewModel: ReservationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        title = viewModel.title
        loader = TRPLoaderView(superView: self.view)
        setupButtonUI()
        setupTableView()
        
        if let image = UIImage(named: "close_btn_icon", in: Bundle.init(for: type(of: self)), compatibleWith: nil) {
            navigationItem.leftBarButtonItem =  UIBarButtonItem(image: image, style: UIBarButtonItem.Style.done, target: self, action: #selector(closedPressed))
        }
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
    }
    
    @objc func applyPressed() {
        if viewModel.fetchNewHour {
            viewModel.findATable()
        }else {
            viewModel.makeAReservation()
            //delegate?.reservationViewControllerContinues()
        }
    }
    
    
    private func changeSelectedTimePositionInAlternativeTime() {
        for row in 0..<viewModel.numberOfCells {
            let index = IndexPath(row: row, section: 0)
            if let alternativeCell = tableView.cellForRow(at: index) as? ReservationAlternativeHour {
                alternativeCell.setSelectedCellCenter()
            }
        }
    }
    
    @objc func closedPressed() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension ReservationViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: continueButton.topAnchor).isActive = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(ReservationDatePickerCell.self, forCellReuseIdentifier: "datePicker")
        tableView.register(ReservationPeople.self, forCellReuseIdentifier: "people")
        tableView.register(ReservationAlternativeHour.self, forCellReuseIdentifier: "alternativeHour")
        tableView.register(ReservationExplainCell.self, forCellReuseIdentifier: "explainText")
        
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
        
        let model = viewModel.getCellViewModel(at: indexPath)
        
        if model.contentType == .date || model.contentType == .time{
            let dateCell = makeDateCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return dateCell
        }else if model.contentType == .people {
            let dateCell = makePeopleCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return dateCell
        }else if model.contentType == .alternativeTime {
            let dateCell = makeAlternaviteHourCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return dateCell
        }else if model.contentType == .explain {
            let dateCell = makeExplainCell(tableView: tableView, cellForRowAt: indexPath, model: model)
            return dateCell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = "IndexPath \(indexPath.row)"
        return cell
    }
    
}

extension ReservationViewController {
    
    private func makeDateCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ReservationCellModel) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "datePicker", for: indexPath) as! ReservationDatePickerCell
        cell.titleLabel.text = model.title
        cell.selectionStyle = .none
        if model.contentType == .date {
            cell.inputText.text = viewModel.date
            cell.dateChangeHandler = { [weak self] date in
                cell.inputText.text = date
                self?.viewModel.updateDate(date)
            }
            
            cell.findATableHandler = { [weak self] date in
                cell.inputText.text = date
                self?.viewModel.findATable()
            }
            cell.inputText.addTarget(self, action: #selector(dateEditingEndingEnd), for: .editingDidEnd)
            cell.inputText.isUserInteractionEnabled = true
        }else {
            cell.inputText.text = viewModel.time
            cell.inputText.isUserInteractionEnabled = false
        }
        return cell
    }
    
    private func makePeopleCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ReservationCellModel) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "people", for: indexPath) as! ReservationPeople
        cell.titleLabel.text = model.title
        cell.inputText.text = "\(viewModel.people)"
        cell.inputText.addTarget(self, action: #selector(peopleCountInputText(sender:)), for: .editingChanged)
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeAlternaviteHourCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ReservationCellModel) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "alternativeHour", for: indexPath) as! ReservationAlternativeHour
        cell.titleLabel.text = model.title
        cell.updateHours(viewModel.hours)
        cell.setSelectedHour(viewModel.time)
        cell.alternativeSelectedHandler = { [weak self] selected in
            self?.viewModel.time = selected
        }
        cell.setSelectedCellCenter()
        cell.selectionStyle = .none
        return cell
    }
    
    
    private func makeExplainCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ReservationCellModel) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "explainText", for: indexPath) as! ReservationExplainCell
        cell.titleLabel.text = model.title
        cell.explainLabel.text = viewModel.explainText
        cell.selectionStyle = .none
        return cell
    }
    
    
    @objc fileprivate func dateEditingEndingEnd() {
        if viewModel.fetchNewHour {
            viewModel.clearATable()
        }else {
            
        }
    }
    
    @objc func peopleCountInputText( sender: UITextField) {
        if let inputText = sender.text, let value = Int(inputText) {
            var inputValue = value
            if value > peopleLimit {
                inputValue = peopleLimit
            }
            sender.text = "\(inputValue)"
            viewModel.people = inputValue
        }
    }
}

extension ReservationViewController: ReservationViewModelDelegate {
    
    
    public func reservationVMAlternativeHoursLoaded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.changeSelectedTimePositionInAlternativeTime()
            print("UPDATE ALTERNATIVE HOUR")
        }
    }
    
    public func reservationVMChangeButtonStatus() {
        continueButton.setTitle(viewModel.buttonStatus.rawValue, for: .normal)
    }
    
    public func reservationVM(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
    public func reservationVM(showLoader: Bool) {
        if showLoader {
            loader?.show()
        }else {
            loader?.remove()
        }
    }
    
    public func reservationVM(error: Error) {
        TRPMessage(contentText: error.localizedDescription, type: .error).show()
    }
    
    public func reservationVMHold(_ hold: YelpHolds, reservation: Reservation,business: YelpBusiness?) {
        delegate?.reservationViewController(reservation: reservation, hold: hold, business: business)
    }
}
