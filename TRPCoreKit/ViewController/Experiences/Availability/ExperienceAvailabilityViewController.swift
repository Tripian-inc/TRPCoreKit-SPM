//
//  ExperienceAvailabilityViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit




protocol ExperienceAvailabilityViewControllerDelegate: AnyObject {
    func experienceAvailabilityOpenBilling(_ navigationController: UINavigationController?, viewController: UIViewController)
    func experienceAvailabilityOpenBooking(_ navigationController: UINavigationController?, viewController: UIViewController, bookingParameters:  [GYGBookingParameter], language: GYGCondLanguage?, pickUp:String?)
}

class ExperienceAvailabilityViewController: UIViewController {
    
    private var tableView: EvrTableView = EvrTableView()
    private let viewModel: ExperienceAvailabilityViewModel
    private var loader: TRPLoaderView?
    weak var delegate: ExperienceAvailabilityViewControllerDelegate?
    private var selectedOption: TourOptionUIModel?
    
    
    public init(viewModel: ExperienceAvailabilityViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        title = "Tour Date"
        setupTableView()
        loader = TRPLoaderView(superView: view)
        viewModel.start()
    }
    
}

extension ExperienceAvailabilityViewController: UITableViewDelegate, UITableViewDataSource{
    
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
        tableView.estimatedRowHeight = 72
        tableView.register(cellClass: UITableViewCell.self)
        tableView.register(cellClass: TRPCalendarTableViewCell.self)
        tableView.register(cellClass: TRPPeopleCountTableViewCell.self)
        tableView.register(cellClass: ExperienceAvailabilityTableViewCell.self)
        tableView.register(cellClass: TRPBigTitleTableViewCell.self)
        tableView.register(cellClass: ExperienceAvailabilityPeopleCell.self)
        
        tableView.separatorStyle = .none
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = viewModel.getCellViewModel(at: indexPath)
        if model.type == .date {
           return makeDateCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .peopleCount {
            return makePeopleCountCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .options {
            return makeOptions(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .bigTitle {
            return makeBigTitle(tableView, cellForRowAt: indexPath, model: model)
        }
        
        return tableView.dequeue(cellClass: UITableViewCell.self, forIndexPath: indexPath)
    }
    
    private func makeDateCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ExperienceAvailabilityCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: TRPCalendarTableViewCell.self, forIndexPath: indexPath)
        cell.inputText.text = viewModel.selectedOptionDate
        cell.titleLabel.text = "Date"
            cell.dateChangeHandler = { [weak self] date in
                self?.viewModel.updateSelectedDate(selectedDate: date)
            }
            cell.findATableHandler = { [weak self] date in
                self?.viewModel.checkAvaliability()
            }
            cell.inputText.addTarget(self, action: #selector(dateEditingEndingEnd), for: .editingDidEnd)
        
        cell.addSeparator(at: .bottom, color: UIColor.lightGray, insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0))
        cell.selectionStyle = .none
        return cell
    }
    
    private func makePeopleCountCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ExperienceAvailabilityCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceAvailabilityPeopleCell.self, forIndexPath: indexPath)
        //cell.adultInputText.text = "1"
        if let uiModel = model.data as? ExpericePeopleCellModel {
            cell.setModel(uiModel)
            cell.titleLabel.text = uiModel.title
            cell.subTitleLabel.text = uiModel.explaine
            let mCount = viewModel.selectedPeopleCount.first(where: {$0.name.lowercased() == uiModel.title.lowercased()})?.count
            cell.peopleCount = mCount ?? 0
        }
        cell.action = { peopleModel in
            self.viewModel.updateSelectedPeople(peopleModel)
        }
        cell.selectionStyle = .none
         
        cell.addSeparator(at: .bottom, color: UIColor.lightGray, insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0))
        return cell
    }
    
    private func makeBigTitle(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ExperienceAvailabilityCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: TRPBigTitleTableViewCell.self, forIndexPath: indexPath)
        cell.titleLabel.text = model.title
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeOptions(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ExperienceAvailabilityCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceAvailabilityTableViewCell.self, forIndexPath: indexPath)
        
        if let option = model.data as? TourOptionUIModel {
            cell.titleLabel.text = option.title
            let price = option.calculatePrice(viewModel.selectedPeopleCount)
            cell.clearProperties()
            cell.setPeople(viewModel.selectedPeopleCount)
            //Duration
            if let duration = option.duration {
                cell.addProperty(title: "Duration", property: duration)
            }
            
            //Times
            if let times = option.startTimes, !times.isEmpty{
                cell.addProperty(title: "Starting Times", property: times.toString(", "))
            }
            
            cell.setPrice(price: price, description: option.priceType ?? "")
            cell.discountLabel.text = option.discount ?? ""
            cell.reservationAction = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.reservationActionPressed(option)
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func reservationActionPressed(_ uiModel: TourOptionUIModel) {
        
        if viewModel.isSelectedPeopleEmpty() {
            viewModel(showWarning: "Please select a participant")
            return
        }
        
        selectedOption = uiModel
        if let startTimes = uiModel.startTimes, startTimes.count > 1 {
            openSelectTimeAction(times: startTimes, optionId: uiModel.optionId)
            return
        }
        if let firstTime = uiModel.startTimes?.first! {
            viewModel.setTime(firstTime, optionId: uiModel.optionId)
        }
        openAnotherViewController()
    }
    
    private func openSelectTimeAction(times: [String], optionId: Int) {
        let actionController = UIAlertController(title: "Select Starting Time", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let actionButtonHandler = {(time: String) in
            { (action: UIAlertAction!) -> Void in
                self.viewModel.setTime(time, optionId: optionId)
                self.openAnotherViewController()
            }
        }
        times.forEach { time in
            let actionButton = UIAlertAction(title: time, style: .default, handler: actionButtonHandler(time))
            actionController.addAction(actionButton)
        }
        present(actionController, animated: true, completion: nil)
    }
    
    private func openAnotherViewController() {
        guard let uiModel = selectedOption else {return}
        viewModel.setDataInUseCases(uiModel)
        if uiModel.isExistBookingParametes {
            delegate?.experienceAvailabilityOpenBooking(navigationController,
                                                        viewController: self,
                                                        bookingParameters: viewModel.getBookingParameters(optionId: uiModel.optionId),
                                                        language: viewModel.getLanguage(optionId: uiModel.optionId),
                                                        pickUp: viewModel.getPickUpInfo(optionId: uiModel.optionId))
        }else {
            delegate?.experienceAvailabilityOpenBilling(navigationController, viewController: self)
        }
    }
    
    @objc fileprivate func dateEditingEndingEnd() {
        viewModel.clearATable()
    }
}


extension ExperienceAvailabilityViewController: ExperienceAvailabilityViewModelDelegate {
    func viewModel(showWarning: String) {
        EvrAlertView.showAlert(contentText: showWarning, type: .info)
    }
    
    func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
    func viewModel(error: Error) {
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    func viewModel(showPreloader: Bool) {
        if showPreloader {
            loader?.show()
        }else {
            loader?.remove()
        }
    }
    
    
}
