//
//  PlaceDetailVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 4.09.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit
import CoreText
import SDWebImage
import TRPRestKit
import TRPFoundationKit




 public var dayChangedPoi:(day: Date, selected: Bool) = (Date(), false)

public protocol PlaceDetailVCProtocol: AnyObject {
    
    func placeDetail(navigation place:TRPPoi)
    func placeDetail(favoriteChanged: Bool, place: TRPPoi)
    func placeDetail(addRemoveStatus: AddRemovePoiStatus, place: TRPPoi)
    func closeParent(parentVc: UIViewController?)
    func placeDetailMakeAReservation(_ viewController: UIViewController, booking: TRPBooking?, poi: TRPPoi)
    
}

extension PlaceDetailVCProtocol {
    
    public func placeDetail(favoriteChanged: Bool, place: TRPPoi) {}
    public func placeDetail(navigation place:TRPPoi) {}
    public func placeDetail(addRemoveStatus: AddRemovePoiStatus, place: TRPPoi) {}
    public func closeParent(parentVc: UIViewController?) {}
    public func placeDetailMakeAReservation(_ viewController: UIViewController, booking: TRPBooking?, poi: TRPPoi) {}
    
}

public class PlaceDetailVC: TRPBaseUIViewController {
    
    private let viewModel: PlaceDetailViewModel1
    private var bottomConstraint: NSLayoutConstraint?
    public weak var delegate: PlaceDetailVCProtocol?
    private var tableView: UITableView?
    private let cellControllerFactory = PlaceDetailCellControllerFactory()
    
    private var cellControllers: [TableCellController] = []
    private var cellImages: [PagingImage] = []
    public var closeParent: UIViewController?
    
    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        if let image = TRPImageController().getImage(inFramework: "close_btn_with_shadow_icon", inApp: TRPAppearanceSettings.Common.closeButtonWithShadowImage) {
            btn.setImage(image, for: UIControl.State.normal)
        }
        btn.addTarget(self, action: #selector(closeBtnPressed), for: UIControl.Event.touchDown)
        return btn
    }()
    
    private var favoriteBtn: UIButton?
    
    private var addRemoveBtn: UIButton?
    
    public init(viewModel: PlaceDetailViewModel1){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func setupViews() {
        super.setupViews()
        setupTableView()
        setCloseButton()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.loadInfoViews()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func setCloseButton(){
        view.addSubview(closeBtn)
        closeBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        closeBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        if #available(iOS 11.0, *) {
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true
        } else {
            closeBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
        }
    }
    
    private func loadInfoViews() {
        //Fixme: -  DÜzenleneccek
        var data: [FeedElement] = []
        
        let imageWidth = Int(UIScreen.main.bounds.size.width)
        let imageHeight = Int(UIScreen.main.bounds.size.width * 3/4)
        
        cellImages = viewModel.getGalleryWithResizered(imageWidth: imageWidth, imageHeight: imageHeight)
        data.insert(.image(ImageCellModel(title: viewModel.place.name, isFavorite: viewModel.isFavorite, images: cellImages)), at: 0)
        
        //fixme: kesinlike ViewModel e taşınacak
        
        let explainText = viewModel.dayAndMatchExplainText
        
        data.append(.title(TitleCellModel(title: viewModel.place.name,
                                          sdkModeType: viewModel.mode,
                                          
                                          globalRating: viewModel.isRatingAvaliable,
                                          starCount: viewModel.starCount,
                                          reviewCount: viewModel.place.ratingCount ?? 0,
                                          explainText: explainText )))
        
        
//        let isAttraction = viewModel.place.categories.contains { (type) -> Bool in
//            for typeId in AddPlaceMenu.attractions.addPlaceType().subTypes {
//                if type.id == typeId {
//                    return true
//                }
//            }
//            return false
//        }
        
        
        if let price = viewModel.place.price, price != 0 {
            data.append(.customTagsCell(CustomTagsCellModel(title: "", price: price, status: .money)))
        }
        
        if let mustTry = viewModel.getMustTryText() {
            data.append(.customTagsCell(CustomTagsCellModel(title: mustTry, status: .mustTry)))
        }
        
        if let cuisines = viewModel.place.cuisines, !cuisines.isEmpty {
            data.append(.customTagsCell(CustomTagsCellModel(title: cuisines, status: .cuisines)))
        }
        
        if !viewModel.place.tags.isEmpty {
            data.append(.customTagsCell(CustomTagsCellModel(title: viewModel.place.tags.toString(), status: .feautures)))
        }
        
        if let desc = viewModel.place.description, !desc.isEmpty {
            data.append(.description(DescriptionCellModel(title: desc)))
        }
        
        if let openingHours = viewModel.place.hours, !openingHours.isEmpty {
            data.append(.openingHours(OpeningHoursCellModel(title: openingHours)))
        }
        
        if let callNumber = viewModel.place.phone, !callNumber.isEmpty{
            data.append(.customTagsCell(CustomTagsCellModel(title: callNumber, status: .phone)))
        }
        
        if let website = viewModel.place.webUrl, !website.isEmpty{
            data.append(.customTagsCell(CustomTagsCellModel(title: website, status: .web)))
        }
        
        if let address = viewModel.place.address, !address.isEmpty{
            data.append(.customTagsCell(CustomTagsCellModel(title: address, status: .address)))
        }
        
        //TODO: TÜM RESTAURANTLARDA BOOKİNG GÖRÜNMESİ İÇİN KONTROL KAPATILDI
        /*if let _ = viewModel.getBookingModel(withId: 2) {
            let isReserved = viewModel.isAvaliableInReservation()
            let explaineText = isReserved ? "Cancel Your Reservation" : "Make a Reservation"
            data.append(.button(ButtonCellModel(title: explaineText)))
        }*/
        
        //DEMO RESTAURANT REZERVASYONU İÇİN KULLANILIYOR, SİLİNECEK
        if viewModel.place.categories.contains(where: {$0.id == 3}) {
            let isReserved = viewModel.isAvaliableInReservation()
            let explaineText = isReserved ? TRPLanguagesController.shared.getLanguageValue(for: "cancel_reservation") : TRPLanguagesController.shared.getLanguageValue(for: "make_reservation")
            data.append(.button(ButtonCellModel(title: explaineText)))
        }
        
        let location = TRPLocation(lat: viewModel.place.coordinate .lat, lon: viewModel.place.coordinate .lon)
        data.append(.map(MapCellModel(location: location)))
        
        tableView?.reloadData()
        
    }
    
    @objc func closeBtnPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc func applicationWillEnterForeground(_ notification: NSNotification) {
        if !viewModel.isAvaliableInReservation() {return}
        if let reservation = viewModel.getReservation() {
            viewModel.checkMyBookigStatus(bookingId: reservation.id)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            Log.deInitialize()
        }
    }
}

extension PlaceDetailVC:  PlaceDetailVMDelegate {
    
    
    public func viewModel(favoriteError: String) {
        self.favoriteBtn?.isUserInteractionEnabled = true
        EvrAlertView.showAlert(contentText: favoriteError, type: .error)
    }
    
    public func viewModel(problemCategory: [TRPProblemCategoriesInfoModel]?) {
        if let data = problemCategory {
            showReportAProblem(data)
        }
    }
    
    public func viewModel(changedButtonStatus: AddRemoveNavButtonStatus) {
        DispatchQueue.main.async {
            let status = changedButtonStatus == AddRemoveNavButtonStatus.add ? AddRemovePoiStatus.add : AddRemovePoiStatus.remove
            self.delegate?.placeDetail(addRemoveStatus: status, place: self.viewModel.place)
            self.setAddRemoveBtnStyle(self.viewModel.addRemoveState)
        }
    }
    
    private func setAddRemoveBtnStyle(_ type: AddRemoveNavButtonStatus) {
        var image: UIImage?
        switch type {
        case .add:
            image = TRPImageController().getImage(inFramework: "add_btn", inApp: TRPAppearanceSettings.Common.addButtonImage)
        case .remove:
            image = TRPImageController().getImage(inFramework: "remove_btn", inApp: TRPAppearanceSettings.Common.removeButtonImage)
        case .navigation:
            image = TRPImageController().getImage(inFramework: "navigation_btn", inApp: TRPAppearanceSettings.Common.navigationButtonImage)
        case .alternative:
            image = TRPImageController().getImage(inFramework: "alternative_poi_icon", inApp: TRPAppearanceSettings.Common.alternativePoiButtonImage)
        default:
            ()
        }
        self.addRemoveBtn?.setImage(image, for: UIControl.State.normal)
    }
    
    
    public override func viewModel(dataLoaded: Bool) {
        DispatchQueue.main.async {
            self.loadInfoViews()
        }
    }

    public func viewModel(favoriteUpdated: Bool, isFavorite:Bool) {
        self.favoriteBtn?.isUserInteractionEnabled = true
        if favoriteUpdated {
            self.delegate?.placeDetail(favoriteChanged: isFavorite, place: self.viewModel.place)
            self.sendAnalytics(favoriteChanged: isFavorite, place: self.viewModel.place)
        }
    }
    
    private func sendAnalytics(favoriteChanged: Bool, place: TRPPoi?){
        guard let place = place else {return}
        let favoriteInfo = [Notification.FavoriteStatusKeys.isFavorite: viewModel.isFavorite,
                            Notification.FavoriteStatusKeys.place: place] as [Notification.FavoriteStatusKeys : Any]
        NotificationCenter.default.post(name: .favoriteStatusChanged, object: nil, userInfo: favoriteInfo)
    }
    
}

// MARK: - TableView
extension PlaceDetailVC: UITableViewDataSource, UITableViewDelegate {
    
    fileprivate func setupTableView() {
        tableView = UITableView(frame: CGRect.zero)
        guard let tableView = tableView else {return}
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.layoutMargins = .zero
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        tableView.contentInset = insets
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorColor = .clear
        cellControllerFactory.registerCells(on: tableView)
        cellControllerFactory.delegate = self
        
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellControllers.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellControllers[indexPath.row].cellFromReusableCellHolder(tableView, forIndexPath: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellControllers[indexPath.row].cellSize()
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cellControllers[indexPath.row].didSelectCell()
        cellControllers[indexPath.row].updateCell(tableView: tableView)
    }
}

extension PlaceDetailVC:  PlaceDetailCellControllerFactoryDelegate{
    //MARK: Favorite Button
    public func favPressed(cell: ImageCarouselTableViewCell?) {
//        if let cell = cell{
            /*self.favoriteBtn = cell.favoriteBtn
            cell.favoriteBtn.isUserInteractionEnabled = false
            viewModel.setFavorite(!viewModel.isFavorite) */
//        }
    }
    
    //TODO: -  YAPI DEĞİŞTİRİLECEK
    //MARK: Add Remove Button
    func addRemoveBtnPressed(_ addRemoveButtonStatus: AddRemoveNavButtonStatus?, _ addRemoveBtn: UIButton?) {
        self.addRemoveBtn = addRemoveBtn
        if viewModel.mode == SdkModeType.Localy {
            
            dismiss(animated: true, completion: nil)
            self.delegate?.placeDetail(navigation: viewModel.place)
            
        }else {
            
            switch viewModel.addRemoveState {
            case .add:
                viewModel.addStep()
            case .remove:
                viewModel.deleteStep()
            case .alternative:
                viewModel.changeWithAlternative()
            default: ()
                
            }
            
            dismiss(animated: true) {
                /*let model = AddRemovePoiNotificationModel(id: self.viewModel.place.id,
                                                          willStatus: willStatus,
                                                          refPoiId:self.viewModel.alternativeRefPoiId)
                NotificationCenter.default.post(name: .TRPAddRemovePoi, object: self, userInfo:["object":model]) */
            }
        }
    }
    
    //MARK: Navigation Button
    func navigationBtnPressed() {
        dismiss(animated: true, completion: nil)
        self.delegate?.placeDetail(navigation: viewModel.place)
        self.delegate?.closeParent(parentVc: closeParent)
    }
    
    func makeAReservationPressed() {
        if viewModel.isAvaliableInReservation() {
            let confirmUrl = viewModel.reservationCancellUrl()
            openUrl(url: confirmUrl)
        }else {
            self.delegate?.placeDetailMakeAReservation(self, booking: viewModel.getBookingModel(withId: 2), poi: viewModel.place)
        }
        
    }
    
    public func openUrl(url: URL?) {
        guard let url = url else { return }
        UIApplication.shared.open(url)
    }
}

//MARK: Report A Problem
extension PlaceDetailVC{
    
    func reportAProblemPressed() {
        viewModel.fetchProblemCategory()
    }
    
    func showReportAProblem(_ data: [TRPProblemCategoriesInfoModel]) {
        let alertContorller = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: UIAlertController.Style.actionSheet)
        let actionButtonHandler = { (problem: TRPProblemCategoriesInfoModel) in
        { (action: UIAlertAction!) -> Void in
            if problem.name.lowercased() == "other" {
                //self.openInputTextForProblem(problem)
                self.openInputTextForProblem(problem)
            }else {
                self.sendProblem(categoryName: problem.name, poiId: self.viewModel.place.id, message: nil)
            }
            }
        }
        
        for problem in data {
            let alertButton = UIAlertAction(title: problem.name, style: UIAlertAction.Style.default, handler: actionButtonHandler(problem))
            
            alertContorller.addAction(alertButton)
        }
        
        
        let cancelButton = UIAlertAction(title: TRPLanguagesController.shared.getCancelBtnText(), style: UIAlertAction.Style.cancel, handler: nil)
        cancelButton.setValue(TRPAppearanceSettings.Common.cancelButtonColor, forKey: "titleTextColor")
        alertContorller.addAction(cancelButton)
        present(alertContorller, animated: true, completion: nil)
    }
    
    func openInputTextForProblem(_ problem: TRPProblemCategoriesInfoModel) {
        let alertController = UIAlertController.init(title: "Other", message: "", preferredStyle: .alert)
        let cancel = UIAlertAction.init(title: TRPLanguagesController.shared.getCancelBtnText(), style: .cancel, handler: {_ in })
        
        let save = UIAlertAction.init(title: "Send", style: .default, handler: {[weak self] action in
            guard let strongSelf = self else {return}
            
            if let textField = alertController.textFields?[0]  {
                if let text = textField.text {
                    if text.count < 3 {
                        EvrAlertView.showAlert(contentText: "Report couldn't send", type: .error)
                        return
                    }
                    strongSelf.sendProblem(categoryName: problem.name, poiId: strongSelf.viewModel.place.id, message: textField.text!)
                    
                }
                
            }
        })
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter report"
        }
        
        alertController.addAction(cancel)
        alertController.addAction(save)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func sendProblem(categoryName name: String, poiId: String,  message: String?) {
        viewModel.reportAProblem(categoryName: name, message: message, poiId: poiId) { result in
            if result {
                EvrAlertView.showAlert(contentText: "Thank you for letting us know.", type: .info)
            }else {
                EvrAlertView.showAlert(contentText: "Report couldn't send", type: .error)
            }
        }
    }
}
