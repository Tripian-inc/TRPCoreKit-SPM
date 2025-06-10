//
//  ItineraryViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-25.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit


protocol ItineraryViewControllerDelegate:AnyObject {
    
    func itineraryViewControllerPoiDetail(_ viewController: ItineraryViewController, poi: TRPPoi, parentStep: TRPStep?)
    func itineraryViewControllerChangeStepHour(_ viewController: ItineraryViewController, step: TRPStep?)
}

@objc(SPMItineraryViewController)
class ItineraryViewController: TRPBaseUIViewController {
    @IBOutlet weak var tb: EvrTableView!
    var viewModel: ListOfRoutingPoisViewModel!
    weak var delegate: ItineraryViewControllerDelegate?
    
    public override func setupViews() {
        super.setupViews()
        viewModel.start()
        title = TRPLanguagesController.shared.getLanguageValue(for: "itinerary")
        addCloseButton(position: .left)
        tb.separatorStyle = .none
        tb.allowsSelectionDuringEditing = true
        tb.isEditing = true
    }
    
}

extension ItineraryViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataCount
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let model = viewModel.getStep(index: indexPath).poi
//        if model.placeType == .poi {
            return makePoiCell(tableView, cellForRowAt: indexPath)
//        }else {
//            return makeHotelCell(tableView, cellForRowAt: indexPath)
//        }
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        /*let info = viewModel.getStep(index: indexPath).poi
        if info.placeType == .hotel {
            return false
        }
        return true */
        return false
    }
    
    func makePoiCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withReuseIdentifier: "NewItineraryTableViewCell", for: indexPath) as! NewItineraryTableViewCell
        let distanceInfo = viewModel.getStepDistanceContent(index: indexPath)
        let model = viewModel.getStep(index: indexPath)
        
        let cellModel = ItineraryUIModel(step: model, order: indexPath.row)
        cellModel.image = viewModel.getPlaceImage(indexPath: indexPath)
        cellModel.readableDistance = distanceInfo.readableDistance
        cellModel.readableTime = distanceInfo.readableTime
        cellModel.userCar = distanceInfo.userCar
        cellModel.canReplace = !model.alternatives.isEmpty
        
        cellModel.reaction = .none
        if model.poi.placeType == .poi {
            if let reaction = viewModel.getReactions(step: model) {
                if reaction == .thumbsUp {
                    cellModel.reaction = .thumbsUp
                } else if reaction == .thumbsDown {
                    cellModel.reaction = .thumbsDown
                }
            }
        }
        
        cell.config(cellModel)
        
        cell.action = {  [weak self] action in
            switch action {
            case .remove: ()
                self?.viewModel.removePoiInRoute(stepId: model.id)
            case .replace:
                 if let step = self?.viewModel.getStep(index: indexPath) {
                    self?.listOfRoutingShowStepAlternative(step: step)
                }
            ()
            case .thumbsUp:
                self?.viewModel.sendThumbUpReaction(step: model)
            case .thumbsDown:
                self?.viewModel.sendThumbDownReaction(step: model)
            case .undo:
                self?.viewModel.sendUndo(step: model)
            }
        }
        cell.bookARide = { [weak self] in
            guard let strongSelf = self else {return}
            if let uberModel = strongSelf.viewModel.createUberInfo(indexPath: indexPath){
                strongSelf.openUberDeepLink(uberModel)
            }
        }
        cell.buyTicket = { [weak self] in
            guard let strongSelf = self else {return}
            var url: String?
            if cellModel.isProduct {
                url = cellModel.bookingUrl
            } else {
                url = cellModel.bookingProduct?.url
            }
            strongSelf.openUrl(url: url)
        }
        
        cell.changeTime = { [weak self] in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.itineraryViewControllerChangeStepHour(strongSelf, step: model)
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if  sourceIndexPath.row == destinationIndexPath.row { return }
//        let isHotelExist = viewModel.isHotelExist
        let sourceModel = viewModel.getStep(index: sourceIndexPath)
        tableView.isEditing = false
        viewModel.cleanStepInfoData()
//        let newOrder = calculateOrder(destinationIndexPath: destinationIndexPath, isHotelExist: isHotelExist)
        viewModel.stepReOrder(step: sourceModel, newOrder: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing == false {return}
        let info = viewModel.getStep(index: indexPath).poi
        if info.placeType == .poi {
            if info.isCustomPoi() {
                if let url = viewModel.getCustomPoiUrl(poi: info) {
                    UIApplication.shared.open(url)
                }
                return
            }
            delegate?.itineraryViewControllerPoiDetail(self, poi: info, parentStep: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let info = viewModel.getStep(index: indexPath).poi
        if info.placeType == .hotel {
            return false
        }
        return true
    }
    
    private func openUrl(url: String?) {
        guard let tourUrl = url,
              let url = URL(string: tourUrl) else {return}
        
        UIApplication.shared.open(url)
    }
    
    func openUberDeepLink(_ model: UberModel) {
        if let uberLink = URL(string: "uber://"), let deepLink = viewModel.createUberDeepLink(model, canOpenLink: UIApplication.shared.canOpenURL(uberLink)) {
            UIApplication.shared.open(deepLink)
        }
    }
    
    private func calculateOrder(destinationIndexPath: IndexPath, isHotelExist: Bool) -> Int {
        var newOrder = isHotelExist ? destinationIndexPath.row - 1 : destinationIndexPath.row
        //Hotel e geldiğinde -1 olduğu için 0 a eşitledik
        newOrder = newOrder == -1 ? 0 : newOrder
        return newOrder
    }
    
}
extension ItineraryViewController {
    public func listOfRoutingShowStepAlternative(step: TRPStep) {
        
        viewModel(showPreloader: true)
        viewModel.getStepAlternatives(step) {[weak self] pois in
            guard let strongSelf = self else {return}
            strongSelf.viewModel(showPreloader: false)
            let poiNames = pois.map {$0.name}
            let title = TRPLanguagesController.shared.getLanguageValue(for: "alternative_locations") + " \(step.poi.name)"
            let actionVC = UIStoryboard.actionViewController()
            let model = ActionModel(title, nil, poiNames, TRPLanguagesController.shared.getCancelBtnText())
            actionVC.config(model)
            
            actionVC.btnAction  = {
                actionVC.dismissView(completion: nil)
            }
            
            actionVC.itemAction = { item in
                strongSelf.delegate?.itineraryViewControllerPoiDetail(strongSelf, poi: pois[item], parentStep: step)
            }
            if #available(iOS 15.0, *) {
                if let sheet = actionVC.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                }
            }
            
            self?.present(actionVC, animated: false, completion: nil)
        }
    }
}

extension ItineraryViewController: ListOfRoutingPoisViewModelDelete{
    
    public override func viewModel(dataLoaded: Bool) {
        tb?.reloadData()
        tb?.isEditing = true
    }
    
    public override func viewModel(error: Error) {
        super.viewModel(error: error)
    }
    
    public override func viewModel(showPreloader: Bool) {
        super.viewModel(showPreloader: showPreloader)
    }
    
    func showEmptyMessage(_ message: String) {
        tb?.isHiddenEmptyText = false
        tb?.emptyText.text = message
    }
    
    func clearEmptyMessage() {
        tb?.isHiddenEmptyText = true
        tb?.emptyText.text = ""
    }
}

extension ItineraryViewController: ItineraryChangeTimeViewModelDelegate {
    func itineraryChangeTimeForStep(_ step: TRPStep?) {
        viewModel.changeStepTime(step: step)
    }
}
