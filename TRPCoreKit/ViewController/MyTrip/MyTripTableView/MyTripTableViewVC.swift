//
//  MyTripTableViewVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 16.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit


import SDWebImage


public protocol MyTripTableViewVCDelegate: AnyObject {
    func myTripTableViewVCSelectedTrip(hash: String, city: TRPCity, arrival:String, departure:String)
    func myTripTableViewVCEditTrip(tripHash: String, profile: TRPTripProfile, city: TRPCity)
    func myTripTableViewVCCreateANewTrip()
}

public enum MyTripType: String{
    case pastTrip, upcomingTrip
}
@objc(SPMMyTripTableViewVC)
public class MyTripTableViewVC: TRPBaseUIViewController {
    
    public var viewModel: MyTripTableViewViewModel!
    
    @IBOutlet var tb: EvrTableView!
    private var heightUpdated: Bool = false
    private var isDataLoaded = false {
        didSet {
            self.setTableViewEmptyText()
        }
    }
    
    private var isViewShowNow = false {
        didSet {
            if isViewShowNow {
                tb.reloadData()
            }
        }
    }
    private var lastShownIndex = -1
    private var myTripRefreshControl: UIRefreshControl?
    public weak var delegate: MyTripTableViewVCDelegate?;
    private var isBusyCell: [Int] = []
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        self.view.backgroundColor = .clear
    }
    
    public override func setupViews() {
        super.setupViews()
        myTripRefreshControl = UIRefreshControl()
        myTripRefreshControl!.attributedTitle = NSAttributedString(string: TRPLanguagesController.shared.getLanguageValue(for: "pull_to_refresh"))
        myTripRefreshControl!.addTarget(self, action: #selector(refreshData), for: UIControl.Event.valueChanged)
        setupTableView()
//        setTableViewEmptyText()
        tb.addSubview(myTripRefreshControl!);
    }
    
    @objc private func refreshData() {
        viewModel.reFetchData()
    }
    
    override public func viewDidLayoutSubviews() {
        if !heightUpdated {
            heightUpdated = true
            tb.frame = CGRect(x: 0, y: 0, width: tb.frame.width, height: self.view.frame.height)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        isViewShowNow = true
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        isViewShowNow = false
    }
    
    fileprivate func showRemoveAlert(_ cell: TripCellModel) {
        showConfirmAlert(
            title: TRPLanguagesController.shared.getLanguageValue(for: "trips.deleteTrip.title"),
            message: TRPLanguagesController.shared.getLanguageValue(for: "trips.deleteTrip.question"),
            confirmTitle: TRPLanguagesController.shared.getLanguageValue(for: "trips.deleteTrip.submit"),
            cancelTitle: TRPLanguagesController.shared.getCancelBtnText(),
            btnConfirmAction: {
                self.isBusyCell.append(cell.id)
                self.viewModel.removeTrip(tripHash: cell.hash)
                
            })
    }
    
//    fileprivate func showSelectedTripMenuHandler(selectedTrip: TripCellModel) {
//        if showWarningIfOffline() { return }
//        showEditTripMenu(selectedTrip)
//    }
    
    fileprivate func unSelectedCell(id: Int) {
        if let index = viewModel.getTripIndex(id: id) {
            if let cell = tb.cellForRow(at: IndexPath(row: 0, section: index)) as? MyTripTableViewCell{
                cell.isBusy = false
                if let index = isBusyCell.firstIndex(of: id) {
                    isBusyCell.remove(at: index)
                }
            }
        }
    }
    
    deinit {
        Log.deInitialize()
    }
}

extension MyTripTableViewVC: MyTripTableViewDelegate {
    
    public func viewModelRemovedTrip(id: Int, status: Bool) {
        if status == false {
            unSelectedCell(id: id)
        }
    }
    
    public override func viewModel(dataLoaded: Bool) {
        if myTripRefreshControl != nil {
            myTripRefreshControl!.endRefreshing()
        }
        isDataLoaded = true
        if isViewShowNow {
            tb.reloadData()
        }
    }
    
    public override func viewModel(error: Error) {
        if myTripRefreshControl != nil {
            myTripRefreshControl!.endRefreshing()
        }
        //Undefined error için
        if viewModel.numberOfCells == 0 {
            //TODO: - AÇILACAK. OFFLİNE DA BUG OLUŞTURDU
            //tb.setEmptyText(error.localizedDescription)
        }
        EvrAlertView.showAlert(contentText: error.localizedDescription.toLocalizedFromServer(), type: .error)
        
    }
    
    func setTableViewEmptyText() {
        if tb == nil {
            return
        }
        if isDataLoaded == false {
            tb.setEmptyText(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.offers.qrWriter.loading"))
        }else {
            if viewModel.getType() == .pastTrip {
                tb.setEmptyText(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.pastTrips.emptyMessage"))
            }else {
                tb.setEmptyText(createNewTripText())
            }
        }
    }
    
}

extension MyTripTableViewVC: UITableViewDelegate, UITableViewDataSource, EvrTableViewDelegate {
    
    
    fileprivate func setupTableView() {
        tb.tableFooterView = UIView()
//        tb.emptyDelegate = self
        tb.accessibilityIdentifier = viewModel.getType().rawValue
        tb.separatorStyle = .none
    }
    
    private func createNewTripText() -> NSMutableAttributedString{
        let typeAttributeStyle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
        let mainAttribute = NSMutableAttributedString(string: "\(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.upComingTrips.emptyMessage"))\n \(TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.title"))", attributes: typeAttributeStyle)
        let subTypeAttributeStyle = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
        let subTypeAttribute = NSMutableAttributedString(string: " + ", attributes: subTypeAttributeStyle)
        mainAttribute.append(subTypeAttribute)
        return mainAttribute
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: MyTripTableViewCell.self, forIndexPath: indexPath)
        let info = viewModel.getCellViewModel(at: indexPath)
        cell.accessibilityIdentifier = "MyTrip\(info.id)"
        cell.tripNameLbl.text = info.tripName
        cell.cityNameLbl.text = "\(info.cityModel.name), \(info.cityModel.countryName)"
        cell.dateLbl.text = info.startDate
        cell.tripId = info.id
        cell.showSelectedTripEditHandler = {[weak self] status in
            self?.delegate?.myTripTableViewVCEditTrip(tripHash: info.hash,
                                                     profile: info.profile,
                                                     city: info.cityModel)
        }
        cell.showSelectedTripDeleteHandler = {[weak self] status in
            self?.showRemoveAlert(info)
        }
        cell.selectionStyle = .none
        
        if let imageUrl = viewModel.getImageUrl(at: indexPath, width: 0, height: 0) {
            cell.cityImage.sd_setImage(with: imageUrl, completed: {image,_,_,_ in
                if self.viewModel.getType() == .pastTrip {
                    cell.cityImage.image = image?.convertToGrayScale()
                }
            })
        }else {
            cell.cityImage.image = nil
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if lastShownIndex >= indexPath.row { return }
    
        let tranform = CATransform3DTranslate(CATransform3DIdentity, 0, 50, 0)
        cell.layer.transform = tranform
        cell.alpha = 0
        let delay = Double(indexPath.row - lastShownIndex) * 0.5
        
        UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseOut, animations: {
            cell.alpha = 1
            cell.layer.transform = CATransform3DIdentity
        })
        
        lastShownIndex = indexPath.row 
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO: - isBusy kontrolu koyulacak
        let info = viewModel.getCellViewModel(at: indexPath)
        if !isBusyCell.contains(info.id) {
            delegate?.myTripTableViewVCSelectedTrip(hash: info.hash,
                                                    city: info.cityModel,
                                                    arrival: info.arrivalDate,
                                                    departure: info.departureDate)
        }else {
            Log.w("You can't open because \(info.id) is bussy")
        }
    }
    
    public func evrTableViewLabelClicked() {
        self.delegate?.myTripTableViewVCCreateANewTrip()
    }
}


