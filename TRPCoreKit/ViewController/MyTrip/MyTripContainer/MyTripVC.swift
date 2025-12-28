//
//  MyTripVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 16.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit

import Parchment




public protocol MyTripVCDelegate: AnyObject {
    func createNewTripPressed(_ myTrip: MyTripVC, city: TRPCity?, destinationId: Int?)
    func myTripOpenTrip(hash: String, city: TRPCity, arrival:String, departure:String)
    func myTripEditTrip(tripHash: String, profile: TRPTripProfile, city: TRPCity)
    func myTripVCDidAppear()
    func myTripVCDismissButtonPressed()
    func myTripVCOpenUserProfile(nav: UINavigationController?, vc: UIViewController)
    func myTripVCCustomNavigationButtonPressed(_ item: TRPBarButtonItem, vc: UIViewController)
}

public class MyTripVC: TRPBaseUIViewController {
    
    private var viewModel: MyTripViewModel
    private var viewControllers = [UIViewController]()
    public var delegate: MyTripVCDelegate?
    private var isViewDidLoad: Bool = true
    fileprivate var myTrip: TRPSDKCoordinater?
    private var isAlertMessageShowed = false
    public var alertMessage: (title: String?, message: String)?
    private let pagingViewController = PagingViewController()
    public var canBack: Bool = true
    public var bookingDetailUrl: String = ""
    public var isNexus: Bool = true
    
    public init(viewModel: MyTripViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
//        self.title = TRPAppearanceSettings.MyTrip.title
        setupNavigationBar()
        viewModel.setupDetailUrl(bookingDetailUrl)
    }
    
    private func setupNavigationBar() {
        showNavigationBar()
        self.navigationController?.navigationBar.setNexusBar()
        
        let logoName = isNexus ? "ic_nexus_logo" : "ic_tripian_new_logo"
        let logo = TRPImageController().getImage(inFramework: logoName, inApp: TRPAppearanceSettings.MyTrip.addTripImage)
        let imageView = UIImageView(frame: CGRectMake(0, 0, 40, 30))// UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        imageView.image = logo
        
        self.navigationItem.titleView = imageView
        NSLayoutConstraint.activate([self.navigationItem.titleView!.heightAnchor.constraint(equalToConstant: 30),self.navigationItem.titleView!.widthAnchor.constraint(equalToConstant: 128)])

        checkAlertMessage()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    
    public override func setupViews() {
        super.setupViews()
        setNavigationBarItems()
        setupPagination()
        hiddenBackButtonTitle()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        delegate?.myTripVCDidAppear()
    }
    
    public func addViewControllerInPagination(_ viewController: UIViewController) {
        viewControllers.append(viewController)
        
    }
    
    public func reloadPagination() {
        pagingViewController.reloadData()
    }
    
    
    private func setNavigationBarItems() {
        var leftItems = [UIBarButtonItem]()
        var rightItems = [UIBarButtonItem]()
        if canBack {
            for itemInfo in TRPAppearanceSettings.MyTrip.leftBarButtonItems {
                if let btn = createNavBarButton(item: itemInfo) {
                    leftItems.append(btn)
                }
            }
        } else {
            if let btn = createNavBarButton(item: TRPBarButtonItem(type: .profile)) {
                leftItems.append(btn)
            }
            
        }
        for itemInfo in TRPAppearanceSettings.MyTrip.rightBarButtonItems {
            if let btn = createNavBarButton(item: itemInfo) {
                rightItems.append(btn)
            }
        }
        navigationItem.rightBarButtonItems = rightItems
        navigationItem.leftBarButtonItems = leftItems
    }
    
    private func checkAlertMessage() {
        guard let alertMessage = alertMessage else {return }
        if !isAlertMessageShowed {
            isAlertMessageShowed = true
            showOkAlert(title: alertMessage.title ?? "", message: alertMessage.message)
//            let alert = UIAlertController(title: alertMessage.title, message: alertMessage.message,preferredStyle: UIAlertController.Style.alert)
//            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
        }
    }
    
    deinit {
        DispatchQueue.main.async {
            Log.deInitialize()
        }
    }
    
    override func closeButtonPressed() {
        super.closeButtonPressed()
        self.delegate?.myTripVCDismissButtonPressed()
    }
    
}

//NavigationBarButtonItems
extension MyTripVC {
    
    private func createNavBarButton(item: TRPBarButtonItem) -> UIBarButtonItem?{
        switch item.type {
        case .createTrip:
            if let image = TRPImageController().getImage(inFramework: "ic_add_trip", inApp: TRPAppearanceSettings.MyTrip.addTripImage) {
                return UIBarButtonItem(image: image.withRenderingMode(.alwaysOriginal),
                                       style: UIBarButtonItem.Style.plain,
                                       target: self,
                                       action: #selector(createNewTripPressed))
            }
        case .dismiss:
            if let image = TRPImageController().getImage(inFramework: "close_btn_icon",
                                                         inApp: TRPAppearanceSettings.Common.closeButtonImage) {
                return UIBarButtonItem(image: image,
                                       style: .done,
                                       target: self,
                                       action: #selector(dismissNavigationButtonClicked))
            }
        case .custom:
            guard let image = item.image else {return nil}
            let itemButton = UIBarButtonItem(image: image,
                                             style: .done,
                                             target: self, action: #selector(customNavigationButtonClicked(sender:)))
            if let tag = item.id {
                itemButton.tag = tag
            }
            return itemButton
        case .profile:
            if let image = TRPImageController().getImage(inFramework: "nav_user",
                                                         inApp: TRPAppearanceSettings.Common.userButtonImage) {
                return UIBarButtonItem(image: image.withRenderingMode(.alwaysOriginal),
                                       style: .plain,
                                       target: self,
                                       action: #selector(openUserProfileVCButtonPressed))
            }
        case .close:
            if let image = TRPImageController().getImage(inFramework: "btn_create_trip_close", inApp: TRPAppearanceSettings.MyTrip.addTripImage) {
                return UIBarButtonItem(image: image.withRenderingMode(.alwaysOriginal),
                                       style: UIBarButtonItem.Style.done,
                                       target: self,
                                       action: #selector(closeButtonPressed))
            }
        }
        
        return nil
    }
    
    @objc func createNewTripPressed() {
        delegate?.createNewTripPressed(self, city: nil, destinationId: nil)
    }
    
    @objc func customNavigationButtonClicked(sender: UIBarButtonItem) {
        var items = [TRPBarButtonItem]()
        items.append(contentsOf: TRPAppearanceSettings.MyTrip.leftBarButtonItems)
        items.append(contentsOf: TRPAppearanceSettings.MyTrip.rightBarButtonItems)
        
        for item in items {
            if let id = item.id, id == sender.tag{
                self.delegate?.myTripVCCustomNavigationButtonPressed(item, vc: self)
            }
        }
    }
    
    @objc func dismissNavigationButtonClicked() {
        self.delegate?.myTripVCDismissButtonPressed()
    }
    
    @objc func openUserProfileVCButtonPressed() {
        self.delegate?.myTripVCOpenUserProfile(nav: navigationController, vc: self)
    }
}

// MARK: - PagingView Setter
extension MyTripVC:  PagingViewControllerDelegate,  PagingViewControllerDataSource {
    
    fileprivate func setupPagination() {
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        
        pagingViewController.menuInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        pagingViewController.backgroundColor = trpTheme.color.extraBG
        pagingViewController.selectedBackgroundColor = trpTheme.color.extraBG
        pagingViewController.menuBackgroundColor = trpTheme.color.extraBG
        pagingViewController.borderColor = trpTheme.color.extraBG
        pagingViewController.selectedTextColor = trpTheme.color.tripianPrimary
        pagingViewController.textColor = trpTheme.color.tripianTextPrimary
        pagingViewController.selectedFont = trpTheme.font.header2
        pagingViewController.font = trpTheme.font.header2
        pagingViewController.indicatorColor = trpTheme.color.tripianPrimary
        pagingViewController.indicatorOptions = .visible(height: 1, zIndex: Int.max, spacing: .init(top: 0, left: 0, bottom: 10, right: 0),insets: .zero)
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        view.constrainToEdges(pagingViewController.view, topSpacing: 12)
        pagingViewController.didMove(toParent: self)
    }
    
    public func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        viewModel.getPagingNumber()
    }
    
    public func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        return viewControllers[index]
    }
    
    public func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        let title = viewModel.getPagingTitle(index: index)
        return PagingIndexItem(index: index, title: title)
    }
    
    public func pagingViewController<T>(_ pagingViewController: PagingViewController, widthForPagingItem pagingItem: T, isSelected: Bool) -> CGFloat?{
        guard let item = pagingItem as? PagingIndexItem else { return 0 }
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: pagingViewController.menuItemSize.height)
        let attributes = [NSAttributedString.Key.font: pagingViewController.font]
        
        let rect = item.title.boundingRect(with: size,
                                           options: .usesLineFragmentOrigin,
                                           attributes: attributes,
                                           context: nil)
        
        let width = ceil(rect.width) + insets.left + insets.right
        
        let fullWidth = CGFloat(viewModel.getPagingNumber()) * width
        let windowsWidth = self.view.frame.width
        if fullWidth < windowsWidth {
            return windowsWidth / CGFloat(viewModel.getPagingNumber())
        }
        
        if isSelected {
            return width * 1.5
        } else {
            return width
        }
    }
 
}

extension MyTripVC:  MyTripTableViewVCDelegate {
    
    public func myTripTableViewVCSelectedTrip(hash: String, city: TRPCity, arrival: String, departure: String) {
        delegate?.myTripOpenTrip(hash: hash,
                                 city: city,
                                 arrival: arrival,
                                 departure: departure)
    }
    
    public func myTripTableViewVCCreateANewTrip() {
        createNewTripPressed()
    }
    
    public func myTripTableViewVCEditTrip(tripHash: String, profile: TRPTripProfile, city: TRPCity) {
        delegate?.myTripEditTrip(tripHash: tripHash,
                                 profile: profile,
                                 city: city)
    }
}

extension MyTripVC:  MyTripViewModelDelegate {
    public func callCreateTripWithDestination(city: TRPCity, destinationId: Int) {
        self.delegate?.createNewTripPressed(self, city: city, destinationId: destinationId)
    }
}
