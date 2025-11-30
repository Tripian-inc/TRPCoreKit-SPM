//
//  PoiDetailViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 22.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPFoundationKit



protocol PoiDetailViewControllerDelegate: AnyObject {
    func poiDetailVCOpenTourDetail(_ navigationController: UINavigationController?,
                                   viewController: UIViewController,
                                   bookingProduct: TRPBookingProduct)
    
    func poiDetailOpenMakeAReservation(_ viewController: UIViewController, booking: TRPBooking?, poi: TRPPoi)
    func poiDetailDrawNavigation(_ viewController: UIViewController, place:TRPPoi)
    func poiDetailCloseParentViewController(_ viewController: UIViewController, parentViewController: UIViewController?)
}

@objc(SPMPoiDetailViewController)
class PoiDetailViewController: TRPBaseUIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: PoiDetailViewModel!
//    private var tableView: UITableView = UITableView()
    public var closeParent: UIViewController?
    private var openHourController = OpenHourCellController()
    private var discriptionController = DescriptionCellController()
//    private var imageGallery = PoiDetailImageGallery(frame: .zero)
//    private lazy var closeButton = UIButton()
    private var laoderVC: TRPLoaderVC = TRPLoaderVC()
    private var isLoaderShowing = false
    public weak var delegate: PoiDetailViewControllerDelegate?
    
    
    let datePicker = UIDatePicker()
    let fakeTextField = UITextField()
    var pickerOfferId: Int?
    
    public init(viewModel: PoiDetailViewModel){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
    }
    
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = UIColor.white
        setupTableView()
//        addCloseButton()
        hideNavigationBar()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewModel.start()
       // EvrAlertView.showAlert(content: "Some warnings will be added here")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        hideNavigationBar()
    }
    @IBAction func backButtonAction(_ sender: Any) {
        closeBtnPressed()
    }
    
    @objc func closeBtnPressed() {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: - TableView
extension PoiDetailViewController: UITableViewDelegate,
                                   UITableViewDataSource{
    
    private func setupTableView() {
        tableView.backgroundColor = UIColor.clear
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.register(cellClass: UITableViewCell.self)
        tableView.register(cellClass: ImageCarouselTableViewCell.self)
        tableView.register(cellClass: TitleTableViewCell.self)
        tableView.register(cellClass: PlaceDetailCustomTagsCell.self)
        tableView.register(cellClass: ExpandableTableViewCell.self)
        tableView.register(cellClass: OpeningHoursCell.self)
        tableView.register(cellClass: PoiDetailExperienceCell.self)
        tableView.register(cellClass: ButtonTableViewCell.self)
        tableView.register(cellClass: MapTableViewCell.self)
//        tableView.register(cellClass: PoiDetailOfferCell.self)
        
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = viewModel.getCellViewModel(at: indexPath)
        
        switch model.type {
        case .titleAndAction:
            return makeTitleCell(tableView, cellForRowAt: indexPath, model: model)
        case .galleryTitle:
            return makeGalleryWithTitleCell(tableView, cellForRowAt: indexPath, model: model)
        case .description, .tag:
            return makeExpandableCell(tableView, cellForRowAt: indexPath, model: model)
        case .openCloseHour:
            return makeOpenCloseCell(tableView, cellForRowAt: indexPath, model: model)
        case .actions:
            return makeActionsCell(tableView, cellForRowAt: indexPath, model: model)
        case.gygTours:
            return makeGygToursCell(tableView, cellForRowAt: indexPath, model: model)
        case.yelp:
            return makeMakeAReservationCell(tableView, cellForRowAt: indexPath, model: model)
        case.openTable:
            return makeMakeAReservationCell(tableView, cellForRowAt: indexPath, model: model)
        case .map:
            return makeMapCell(tableView, cellForRowAt: indexPath, model: model)
        case .offer:
            return makeOfferCell(tableView, cellForRowAt: indexPath, model: model)
        default:
            return makeBasicCell(tableView, cellForRowAt: indexPath, model: model)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getCellViewModel(at: indexPath)
        
        if model.type == .openCloseHour {
            tableView.beginUpdates()
            openHourController.didSelectCell()
            tableView.endUpdates()
        }else if model.type == .description || model.type == .tag{
            tableView.beginUpdates()
            discriptionController.didSelectCell()
            tableView.endUpdates()
        }
    }
    
    
}

extension PoiDetailViewController {
    
    private func makeBasicCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PlaceDetailCustomTagsCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiDetailBasicCellModel {
            cell.customLabel.text = cellModel.content
            if !cellModel.icon.isEmpty {
                cell.setIcon(inFramework: cellModel.icon, inApp: "")
            }
            if model.type == .safety {
                cell.setImageSize(w: 20, h: 20)
            }
            
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeTitleCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: TitleTableViewCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? TitleCellModel {
            cell.titleLabel.text = cellModel.title
            cell.showSubTitle(starCount: cellModel.globalRating ? cellModel.starCount : 0,
                              reviewCount: cellModel.globalRating ? cellModel.reviewCount : 0,
                              explainText: cellModel.explainText)
        }
        cell.selectionStyle = .none
        return cell
    }
 
    private func makeGalleryWithTitleCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PoiDetailImageAndTitle.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiImageWithTitleModel {
            cell.setup()
            cell.setImageData(viewModel.getImageGallery())
            cell.titleLabel.text = cellModel.title
            cell.showSubTitle(starCount: cellModel.globalRating ? cellModel.starCount : 0,
                              reviewCount: cellModel.globalRating ? cellModel.reviewCount : 0,
                              price: cellModel.price,
                              explainText: cellModel.explainText)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeExpandableCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExpandableTableViewCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiDetailBasicCellModel {
            if !cellModel.icon.isEmpty {
                cell.setIcon(inFramework: cellModel.icon, inApp: "")
            }
            
            discriptionController.configureCell(cell, model: cellModel.content)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    
    private func makeOpenCloseCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: OpeningHoursCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiDetailBasicCellModel {
            openHourController.configureCell(cell, model: cellModel.content)
            if !cellModel.icon.isEmpty {
                cell.setIcon(inFramework: cellModel.icon, inApp: "")
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeActionsCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PoiDetailActionsCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiDetailActions {
            cell.setupViews()
            cell.setAddRemoveStatus(cellModel.addRemoveButtonStatus)
            cell.setFavorite(cellModel.isFavorite)
            cell.addRemoveButton.addTarget(self, action: #selector(addRemoveButtonPressed), for: .touchUpInside)
            cell.replaceButton.addTarget(self, action: #selector(addRemoveButtonPressed), for: .touchUpInside)
            cell.navigationButton.addTarget(self, action: #selector(navigationButtonPressed), for: .touchUpInside)
            cell.favoriteButton.addTarget(self, action: #selector(favoriteButtonPressed), for: .touchUpInside)
            cell.shareButton.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeGygToursCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PoiDetailExperienceCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? [TRPBookingProduct] {
            cell.updateData(cellModel)
            
            cell.selectedTourAction = { [weak self] product in
                guard let strongSelf = self,
                      let url = NexusHelper.getCustomPoiUrl(destinationZone: String(strongSelf.viewModel.destinationId),
                                                            startDate: strongSelf.viewModel.planDate,
                                                            productCode: product.id) else {return}
                
                UIApplication.shared.open(url)
            }
            cell.addSubLabel(text:"\(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.poi.tourTicket.tour.covering")) \(viewModel.place.name)")
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    
    private func makeMakeAReservationCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ButtonTableViewCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? String {
            cell.button.setTitle(cellModel, for: .normal)
            cell.action = {
                
                if model.type == .openTable {
                    self.openUrl(url: self.viewModel.getOpenTableUrl())
                }else {
                    if self.viewModel.isAvaliableInReservation() {
                        let confirmUrl = self.viewModel.reservationCancellUrl()
                        self.openUrl(url: confirmUrl)
                    }else {
                        self.delegate?.poiDetailOpenMakeAReservation(self,
                                                                     booking: self.viewModel.getBookingModel(withId: 2),
                                                                     poi: self.viewModel.place)
                    }
                }
                
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    
    
    private func makeMapCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: MapTableViewCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? TRPLocation {
            cell.setMapView(cellModel)
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeOfferCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: PoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PoiDetailOfferCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiOfferCellModel {
            cell.configurate(cellModel)
            if #available(iOS 13.0, *) {
                let action = UIAction(handler: { action in
                    self.viewModel.offerToggle(cellModel)
                })
                if #available(iOS 14.0, *) {
                    cell.imInBtn.addAction(action, for: .touchUpInside)
                }
            } else {
                cell.imInBtn.tag = indexPath.row
                cell.imInBtn.addTarget(self, action: #selector(self.offerOptInAction), for: .touchUpInside)
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    @objc private func offerOptInAction(sender: UIButton) {
        if let offerModel = viewModel.cellViewModels[sender.tag].data as? PoiOfferCellModel {
            self.viewModel.offerToggle(offerModel)
        }
    }
    
    public func openUrl(url: URL?) {
        guard let url = url else { return }
        UIApplication.shared.open(url)
    }
}

extension PoiDetailViewController {
    private func showUserLocationAlert() {
        
        var name: String = ""
        
        if let city = viewModel.tripModelUseCases?.trip.value?.city.name {
            name = city
        }
        let alertName = TRPLanguagesController.shared.getLanguageValue(for: "your_current_location_is_not_in_city")
        EvrAlertView.showAlert(contentText: alertName, type: .warning)
    }
    
    
    private func locationPermission() {
        EvrAlertView.showAlert(contentText: TRPLanguagesController.shared.getLanguageValue(for: "location_permission_denied"), type: .warning)
    }
    
    
}

//Mark: - Actions
extension PoiDetailViewController {
    
    @objc func addRemoveButtonPressed() {
        if viewModel.isParentAvailabile() {
            self.dismiss(animated: true) {
                self.viewModel.addRemoveButtonPressed()
            }
        }else {
            viewModel.addRemoveButtonPressed()
        }
    }
    
    @objc func navigationButtonPressed() {
        self.viewModel.navigateToPoi()
//        if viewModel.userInCity == .inCity {
//            self.viewModel.navigateToPoi()
////            dismiss(animated: true) {
////                self.delegate?.poiDetailDrawNavigation(self, place: self.viewModel.place)
////                self.delegate?.poiDetailCloseParentViewController(self, parentViewController: self.closeParent)
////            }
//        }else if viewModel.userInCity == .outCity{
//            showUserLocationAlert()
//        }else if viewModel.userInCity == .locationProblem{
//            locationPermission()
//        }
        
         
    }
    
    @objc func favoriteButtonPressed() {
        viewModel.favoriteButtonPressed()
    }
    
    @objc func shareButtonPressed() {
        if let url = viewModel.getSharedPoiUrl() {
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
            present(vc, animated: true)
        }
    }
    
}


extension PoiDetailViewController: PoiDetailViewModelDelegate {
    func viewModel(favoriteUpdated: Bool, isFavorite: Bool) {}
    
    
    override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
//        imageGallery.setImageData(viewModel.getImageGallery())
    }
    
    override func viewModel(showPreloader: Bool) {
        DispatchQueue.main.async {
            if showPreloader {
                if self.isLoaderShowing == false {
                    self.isLoaderShowing = true
                    self.laoderVC.modalPresentationStyle = .overCurrentContext
                    self.present(self.laoderVC, animated: false, completion: nil)
                    self.laoderVC.show()
                }
            }else {
                self.isLoaderShowing = false
                self.laoderVC.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func openSelectDateForOffer(start: Date, end: Date, offerId: Int) {
        self.pickerOfferId = offerId
        createDatePicker(start,endDate: end)
    }
}

//MARK: - Offer
extension PoiDetailViewController {
    private func createDatePicker(_ startDate: Date, endDate: Date) {
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.datePickerMode = .date
        datePicker.minimumDate = startDate
        datePicker.maximumDate = endDate
        datePicker.backgroundColor = UIColor.white
        
        fakeTextField.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        fakeTextField.inputView = datePicker
        view.addSubview(fakeTextField)
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(calendarDoneBtn))
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self,action: #selector(calendarCancel))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancel, flexSpace, doneBtn], animated: false)
        
        doneBtn.tintColor = trpTheme.color.tripianPrimary
        cancel.tintColor = trpTheme.color.tripianPrimary
        
        fakeTextField.inputAccessoryView = toolBar
        fakeTextField.inputView = datePicker
        
        fakeTextField.becomeFirstResponder()
    }
    
    @objc func calendarCancel() {
        view.endEditing(true)
    }
    
    @objc func calendarDoneBtn() {
        view.endEditing(true)
        guard let offerId = pickerOfferId else {return}
        let date = datePicker.date.toStringWithoutTimeZone(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
        viewModel.addMyOffer(offerId: offerId, date: date)
        view.endEditing(true)
    }
}

