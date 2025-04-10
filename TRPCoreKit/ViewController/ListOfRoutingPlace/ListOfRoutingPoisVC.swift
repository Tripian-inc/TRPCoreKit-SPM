//
//  ListOfRoutingPlaces.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.12.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation

import SDWebImage
import UIKit


public protocol ListOfRoutingPoisVCDelegate:AnyObject {
    func listOfRoutingOpenPoiDetail(poiId: String)
    func listOfRoutingShowStepAlternative(step: TRPStep)
    func listOfRoutingStepReOrder(_ step: TRPStep, newOrder:Int)
    func listOfRoutingRemoveStep(_ step: TRPStep)
    func listOfRoutingTimeFramePressed()
}


public class ListOfRoutingPoisVC: UIView {
    
    public let viewModel: ListOfRoutingPoisViewModel
    public weak var delegate: ListOfRoutingPoisVCDelegate?
    
    fileprivate var permissionForScrollClose = true

    private lazy var dragableArea: UIView = {
        let dragabel = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: tapDragableSpace))
        dragabel.backgroundColor = UIColor.clear
        return dragabel
    }()
    
    private lazy var topGraficView: UIView = {
        let width: CGFloat = 50
        let lineView = UIView(frame: CGRect(x: (self.frame.width - width) / 2,
                                            y: 10,
                                            width: width,
                                            height: 3))
        lineView.backgroundColor = TRPColor.lightGrey
        lineView.layer.cornerRadius = 2
        return lineView
    }()
    
    private lazy var titleLabel: UILabel = {
        let lbl = UILabel(frame: CGRect(x: 0, y: 20, width: self.frame.width, height: 20))
        lbl.text = TRPLanguagesController.shared.getLanguageValue(for: "itinerary")
        lbl.font = UIFont.systemFont(ofSize: TRPAppearanceSettings.ListOfRouting.titleFontSize)
        lbl.textAlignment = .center
        lbl.textColor = TRPAppearanceSettings.ListOfRouting.titleTextColor
        return lbl
    }()
    
    private lazy var seperaterLine: CAShapeLayer = {
        var path = UIBezierPath()
        let positionY = tableViewStartY - 1
        let marginX: CGFloat = 0
        path.move(to: CGPoint(x: marginX, y: positionY))
        path.addLine(to: CGPoint(x: frame.width - marginX * 2, y: positionY))
        var shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = TRPColor.lightGrey.cgColor
        shape.lineWidth = 0.5
        shape.opacity = 0.2
        return shape
    }()
    
    private lazy var timeFrameBtn: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(changeTimePressed), for: .touchDown)
        return btn
    }()
    
    private var bottomPosition: CGFloat {
        get {
            let parentHeight = parentView?.height ?? 600
            return parentHeight - tapDragableSpace - closeShowHeight
        }
    }
    
    
    private var tapDragableSpace: CGFloat = 55
    private let tableViewStartY: CGFloat = 50
    private var parentView:CGRect?
    public var horizontalSpace:CGFloat = 10
    public var closeShowHeight: CGFloat = 0
    //private var tableView: MovementList?
    //FOR PAN ANIM
    private let panRecognzier = InstantPanGestureRecognizer()
    var animation = UIViewPropertyAnimator();
    var isOpen = false {
        didSet {
            guard let tableView = tableView else {return }
            if isOpen == false {
                tableView.setContentOffset(CGPoint.zero, animated: false)
            }
        }
    }
    private var closedTransform = CGAffineTransform.identity
    private var animationProgress: CGFloat = 0;
    
    private var tableView: EvrTableView?
    
 
    
    @PriceIconWrapper
    private var priceDolarSign = 0
    
    public init(rect: CGRect, closeShowHeight: CGFloat, viewModel: ListOfRoutingPoisViewModel) {
        self.viewModel = viewModel
        super.init(frame: rect)
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom ?? 0
            self.closeShowHeight = closeShowHeight + bottomPadding
        }else {
            self.closeShowHeight = closeShowHeight
        }
        sharedInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func sharedInit() {
        self.layer.cornerRadius = 30
        self.backgroundColor = UIColor.white
        self.addSubview(dragableArea)
        self.addSubview(titleLabel)
        self.addSubview(topGraficView)
        
        closedTransform = CGAffineTransform(translationX: 0, y: self.frame.height  - closeShowHeight)
        transform = closedTransform
        addPanRecognizer()
        setupTableView()
        //addTimeFrame()
    }
    
    func setEmptyAlert(_ message: String) {
        if let tb = tableView {
            tb.setEmptyText(message)
        }
    }
    
    private func addTimeFrame() {
        let timeFrame = TRPImageController().getImage(inFramework: "timeframe", inApp: TRPAppearanceSettings.TripModeMapView.timeFrameImage)
        guard let timeFrameImage = timeFrame?.maskWithColor(color: UIColor.darkGray) else {return}
        addSubview(timeFrameBtn)
        timeFrameBtn.setImage(timeFrameImage, for: .normal)
        timeFrameBtn.trailingAnchor.constraint(equalTo: dragableArea.trailingAnchor, constant: -16).isActive = true
        timeFrameBtn.topAnchor.constraint(equalTo: dragableArea.topAnchor, constant: 8).isActive = true
        timeFrameBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        timeFrameBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    @objc func changeTimePressed() {
        delegate?.listOfRoutingTimeFramePressed()
    }
    
}

extension ListOfRoutingPoisVC: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTableView() {
        tableView = EvrTableView(frame: CGRect(x: 0,
                                               y: tableViewStartY,
                                               width: self.frame.width, height: self.frame.height - tableViewStartY))
        addSubview(tableView!)
        tableView!.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView!.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView!.frame.size.width, height: 1))
        tableView!.register(cellClass: ItineraryBaseCell.self)
        tableView!.register(cellClass: ItineraryPoiCell.self)
        tableView!.register(cellClass: ItineraryClosedPoiCell.self)
        tableView!.register(cellClass: ItineraryHotelCell.self)
        
        
        tableView!.dataSource = self
        tableView!.delegate = self
        tableView!.allowsSelectionDuringEditing = true
        tableView!.isEditing = false
        tableView!.separatorStyle = .none
        //tableView!.rowHeight = UITableView.automaticDimension
        //tableView!.estimatedRowHeight = 120
    }
    
    //NOTE: self cell resizer hata alındığı için kapatıldı. ileride bakılacak.
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // return UITableView.automaticDimension
        return viewModel.getCellHeight(index: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataCount
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let info = viewModel.getStep(index: indexPath)
        if info.poi.status == false {
            return createClosedPoiCell(tableView, indexPath: indexPath, model: info)
        }else if info.poi.placeType == .hotel {
            return createHotelCell(tableView, indexPath: indexPath, model: info)
        }
        return createPlaceCell(tableView, indexPath: indexPath, model: info)
    }
    
    private func createHotelCell(_ tableView: UITableView, indexPath: IndexPath, model: TRPStep) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ItineraryHotelCell.self, forIndexPath: indexPath)
        let place = model.poi
        var cellName = place.name
        if cellName.isEmpty {
            cellName = place.address ?? ""
        }
        cell.poiNameLabel.text = cellName
        cell.orderlabel.text = "\(indexPath.row + 1)"
        cell.selectionStyle = .none
        let distanceInfo = viewModel.getStepDistanceContent(index: indexPath)
        if let distance = distanceInfo.readableDistance,
            let time = distanceInfo.readableTime  {
            let userCar = distanceInfo.userCar
            cell.distanceInfoLabel.text = userCar ? "\(distance) km " : "\(distance) km - \(time) min "
            
            let distanceImage = userCar ? ItineraryDistanceType.car : ItineraryDistanceType.walking
            cell.setDistanceImage(type: distanceImage)
        }else {
            cell.setDistanceImage(type: .none)
        }
        
        if let homeImage = TRPImageController().getImage(inFramework: "home_base", inApp: nil) {
            cell.poiImage.image = homeImage
            cell.poiImage.contentMode = UIView.ContentMode.center
        }
        
        if TRPAppearanceSettings.Providers.uber {
            cell.uberHandler = { [weak self] in
                guard let strongSelf = self else {return}
                if let uberModel = strongSelf.viewModel.createUberInfo(indexPath: indexPath){
                    strongSelf.openUberDeepLink(uberModel)
                }
            }
        }
        
        return cell
    }
    
    private func createPlaceCell(_ tableView: UITableView, indexPath: IndexPath, model: TRPStep) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ItineraryPoiCell.self, forIndexPath: indexPath)
        let place = model.poi
        cell.poiNameLabel.text = place.name
        cell.orderlabel.text = "\(indexPath.row + 1)"
        
        if let category = place.categories.first {
            cell.poiTypeLabel.text = category.name
        }
        if let imageUrl = viewModel.getPlaceImage(indexPath: indexPath) {
            cell.poiImage.sd_setImage(with: imageUrl, placeholderImage: nil)
        }
        
        if let price = place.price, price > 0{
            priceDolarSign = price
            cell.priceRangeLabel.attributedText = addPrefixInDolar($priceDolarSign.generateDolarSign())
        }
        cell.showGlobalRating = place.isRatingAvailable()
        if place.isRatingAvailable() {
            cell.setRating(starCount: Int((place.rating ?? 0).rounded()), review: place.ratingCount ?? 0)
        }
        
        let distanceInfo = viewModel.getStepDistanceContent(index: indexPath)
        if let distance = distanceInfo.readableDistance, let time = distanceInfo.readableTime  {
            let userCar = distanceInfo.userCar
            cell.distanceInfoLabel.text = userCar ? "\(distance) km " : "\(distance) km - \(time) min "
            let distanceImage = userCar ? ItineraryDistanceType.car : ItineraryDistanceType.walking
            cell.setDistanceImage(type: distanceImage)
        }
        
        if viewModel.showThumbsReactions(index: indexPath) {
            cell.reactionView.isHidden = false
            cell.reactionView.isUserInteractionEnabled = true
        }else {
            cell.reactionView.isHidden = true
            cell.reactionView.isUserInteractionEnabled = false
        }
        
        cell.action = {  [weak self] action in
            switch action {
            case .remove:
                self?.delegate?.listOfRoutingRemoveStep(model)
            case .replace:
                if let step = self?.viewModel.getStep(index: indexPath) {
                    self?.delegate?.listOfRoutingShowStepAlternative(step: step)
                }
            case .thumbsUp:
                self?.viewModel.sendThumbUpReaction(step: model)
            case .thumbsDown:
                self?.viewModel.sendThumbDownReaction(step: model)
            case .undo:
                self?.viewModel.sendUndo(step: model)
            }
        }
        
        if let reaction = viewModel.getReactions(step: model) {
            if reaction == .thumbsUp {
                cell.reactionView.reactionState = .thumbsUp
            }else if reaction == .thumbsDown {
                cell.reactionView.reactionState = .thumbsDown
            }
            
        }else {
            cell.reactionView.reactionState = .unSelected
        }
        
        if TRPAppearanceSettings.Providers.uber {
            cell.uberHandler = { [weak self] in
                guard let strongSelf = self else {return}
                if let uberModel = strongSelf.viewModel.createUberInfo(indexPath: indexPath){
                    strongSelf.openUberDeepLink(uberModel)
                }
            }
        }
        cell.alternativeHandler = { [weak self] in
            if let step = self?.viewModel.getStep(index: indexPath) {
                self?.delegate?.listOfRoutingShowStepAlternative(step: step)
            }
        }
        //Note: - Time Step kapatıldı daha sonra açılacak
        /*if let timeStep = model.readableTime {
         cell.timeStepLabel.text = timeStep
         }*/
        cell.selectionStyle = .none
        //cell.layoutIfNeeded()
        return cell
    }
    
    private func createClosedPoiCell(_ tableView: UITableView, indexPath: IndexPath, model: TRPStep) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ItineraryClosedPoiCell.self, forIndexPath: indexPath)
        let place = model.poi
        cell.poiNameLabel.text = place.name
        cell.orderlabel.text = "\(indexPath.row + 1)"
        cell.explaineText.text = "This place is no longer available. Please remove it from your itinerary."
        if let imageUrl = viewModel.getPlaceImage(indexPath: indexPath) {
            cell.poiImage.sd_setImage(with: imageUrl, placeholderImage: nil)
        }
        
        let distanceInfo = viewModel.getStepDistanceContent(index: indexPath)
        if let distance = distanceInfo.readableDistance, let time = distanceInfo.readableTime  {
            let userCar = distanceInfo.userCar
            cell.distanceInfoLabel.text = userCar ? "\(distance) km " : "\(distance) km - \(time) min "
            let distanceImage = userCar ? ItineraryDistanceType.car : ItineraryDistanceType.walking
            cell.setDistanceImage(type: distanceImage)
        }
        
        if viewModel.isExistAlternative(step: model) {
            cell.alternativeButton.isHidden = false
            cell.alternativeButton.isUserInteractionEnabled = true
        }
        cell.poiImage.alpha = 0.2
        cell.alternativeHandler = { [weak self] in
            if let step = self?.viewModel.getStep(index: indexPath) {
                self?.delegate?.listOfRoutingShowStepAlternative(step: step)
            }
        }
    
        if TRPAppearanceSettings.Providers.uber {
            cell.uberHandler = { [weak self] in
                guard let strongSelf = self else {return}
                if let uberModel = strongSelf.viewModel.createUberInfo(indexPath: indexPath){
                    strongSelf.openUberDeepLink(uberModel)
                }
            }
        }
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let info = viewModel.getStep(index: indexPath).poi
        if info.placeType == .hotel {
            return false
        }
        return true
    }
    
    func openUberDeepLink(_ model: UberModel) {
        if let uberLink = URL(string: "uber://"), let deepLink = viewModel.createUberDeepLink(model, canOpenLink: UIApplication.shared.canOpenURL(uberLink)) {
            UIApplication.shared.open(deepLink)
        }
    }
    
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        let info = viewModel.getStep(index: indexPath).poi
        if info.placeType == .hotel {
            return false
        }
        return true
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y > 250 {
            closeWithScroll()
        }
    }
    
    private func closeWithScroll() {
        if permissionForScrollClose {
            permissionForScrollClose  = false
            startAnimatorIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.00, execute: {
                self.permissionForScrollClose = true
            })
        }
    }
    
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if  sourceIndexPath.row == destinationIndexPath.row { return }
        let isHotelExist = viewModel.isHotelExist
        let sourceModel = viewModel.getStep(index: sourceIndexPath)
        tableView.isEditing = false
        viewModel.cleanStepInfoData()
        let newOrder = calculateOrder(destinationIndexPath: destinationIndexPath, isHotelExist: isHotelExist)
        self.delegate?.listOfRoutingStepReOrder(sourceModel, newOrder: newOrder)
    }
    
    private func calculateOrder(destinationIndexPath: IndexPath, isHotelExist: Bool) -> Int {
        var newOrder = isHotelExist ? destinationIndexPath.row - 1 : destinationIndexPath.row
        //Hotel e geldiğinde -1 olduğu için 0 a eşitledik
        newOrder = newOrder == -1 ? 0 : newOrder
        return newOrder
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing == false {return}
        let info = viewModel.getStep(index: indexPath).poi
        if info.placeType == .poi {
            self.delegate?.listOfRoutingOpenPoiDetail(poiId: info.id)
        }
    }
    
    private func addPrefixInDolar(_ dolarSign: NSAttributedString) -> NSMutableAttributedString {
        let largeAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10),.foregroundColor: UIColor.darkGray]
        let mainAttribute = NSMutableAttributedString(string: " - ", attributes: largeAttributes)
        mainAttribute.append(dolarSign)
        return mainAttribute
    }
    
}


//Pan Animation
extension ListOfRoutingPoisVC {
    
    fileprivate func addPanRecognizer() {
        panRecognzier.addTarget(self, action: #selector(addPanned(recognizer:)))
        dragableArea.addGestureRecognizer(panRecognzier)
    }
    
    func startAnimatorIfNeeded() {
        if animation.isRunning {return}
        let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: CGVector(dx: 0.4, dy: 0.4))
        animation = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
        //animation = UIViewPropertyAnimator(duration: 10, curve: .easeIn)
        animation.addAnimations { [weak self] in
            guard let strongSelf = self else {return}
            strongSelf.transform = strongSelf.isOpen ? strongSelf.closedTransform : .identity
        }
        animation.addCompletion { [weak self] position in
            guard let strongSelf = self else {return}
            if position == .end { strongSelf.isOpen = !strongSelf.isOpen }
        }
        animation.startAnimation()
    }
    
    public func openMenu() {
        startAnimatorIfNeeded()
        animation.pauseAnimation()
        animationProgress = animation.fractionComplete
        animation.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
    
    @objc func addPanned(recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
        case .began:
            startAnimatorIfNeeded()
            animation.pauseAnimation()
            animationProgress = animation.fractionComplete
            break
        case .ended, .cancelled:
            let yVelocity = recognizer.velocity(in: self).y
            let shouldClose = yVelocity > 0 // todo: should use projection instead
            if yVelocity == 0 {
                animation.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            if isOpen {
                if !shouldClose && !animation.isReversed { animation.isReversed = !animation.isReversed }
                if shouldClose && animation.isReversed { animation.isReversed = !animation.isReversed }
            } else {
                if shouldClose && !animation.isReversed { animation.isReversed = !animation.isReversed }
                if !shouldClose && animation.isReversed { animation.isReversed = !animation.isReversed }
            }
            let fractionRemaining = 1 - animation.fractionComplete
            let distanceRemaining = fractionRemaining * closedTransform.ty
            if distanceRemaining == 0 {
                animation.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            let relativeVelocity = min(abs(yVelocity) / distanceRemaining, 30)
            let timingParameters = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: CGVector(dx: relativeVelocity, dy: relativeVelocity))
            let preferredDuration = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters).duration
            let durationFactor = CGFloat(preferredDuration / animation.duration)
            animation.continueAnimation(withTimingParameters: timingParameters, durationFactor: durationFactor)
            break
        case .changed:
            var fraction = -recognizer.translation(in: self).y / closedTransform.ty
            if isOpen { fraction *= -1 }
            if animation.isReversed { fraction *= -1 }
            
            animation.fractionComplete = fraction + animationProgress
            break
        default: break
        }
    }
    
}

extension ListOfRoutingPoisVC: ListOfRoutingPoisViewModelDelete{
    public func viewModel(dataLoaded: Bool) {
        tableView?.reloadData()
        tableView?.isEditing = true
    }
    
    public func viewModel(error: Error) {
        
    }
    
    public func viewModel(showPreloader: Bool) {
        
    }
    
    func showEmptyMessage(_ message: String) {
        tableView?.isHiddenEmptyText = false
        tableView?.emptyText.text = message
    }
    
    func clearEmptyMessage() {
        tableView?.isHiddenEmptyText = true
        tableView?.emptyText.text = ""
    }
}
