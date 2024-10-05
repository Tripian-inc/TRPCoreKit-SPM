//
//  OverviewContainerVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 15.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Parchment
import UIKit

protocol OverviewContainerVCDelegate: AnyObject {
    func overviewContainerVCDidAppear(_ viewController: UIViewController)
    func overviewContainerVCContinuePressed()
}

class OverviewContainerVC: TRPBaseUIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var doneBtn: TRPBlackButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    weak var delegate: OverviewContainerVCDelegate?
    public var viewModel: OverviewContainerViewModel!
    private let pagingViewController = PagingViewController()
    private var childViewController = [OverviewViewController]() {
        didSet {
            pagingViewController.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPagination()
        viewModel.start()
        title = "Overview"
        addBackButton(position: .left)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        delegate?.overviewContainerVCDidAppear(self)
    }
    
    public override func setupViews() {
        super.setupViews()
        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
        }
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        doneBtn.setTitle("Done".toLocalized(), for: .normal)
        
        setupLoadingNavigationView()
    }
    
//    private func setupStepView() {
//        let view = CreateTripStepView()
//        view.setStep(step: viewModel.getCurrentStep())
//        addNavigationBarCustomView(view: view)
//    }
    
    private func setupLoadingNavigationView() {
        
        let loading = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            loading.style = UIActivityIndicatorView.Style.medium
        }
        loading.startAnimating()
        loading.hidesWhenStopped = true
        addNavigationBarCustomView(view: loading)
        
    }
    
    @IBAction func doneBtnPressed(_ sender: Any) {
        delegate?.overviewContainerVCContinuePressed()
    }
    
}
extension OverviewContainerVC: PagingViewControllerDelegate,  PagingViewControllerDataSource{
    
    fileprivate func setupPagination() {
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pagingViewController)
        containerView.addSubview(pagingViewController.view)
        NSLayoutConstraint.activate([
            pagingViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pagingViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        pagingViewController.didMove(toParent: self)
        pagingViewController.register(CustomPagingOverviewCell.self, for: CustomOverviewPagingItem.self)
        pagingViewController.dataSource = self
        pagingViewController.menuItemSize = .selfSizing(estimatedWidth: 100, height: 52)
//        pagingViewController.menuInsets = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        pagingViewController.delegate = self
        //pagingViewController.sizeDelegate = self
        pagingViewController.backgroundColor = trpTheme.color.extraBG
        pagingViewController.selectedBackgroundColor = trpTheme.color.extraBG
        pagingViewController.menuBackgroundColor = trpTheme.color.extraBG
        pagingViewController.borderColor = trpTheme.color.extraBG
        pagingViewController.selectedTextColor = UIColor.black
        pagingViewController.selectedFont = trpTheme.font.display
        pagingViewController.font = trpTheme.font.display
        pagingViewController.textColor = UIColor.lightGray
        pagingViewController.indicatorColor = trpTheme.color.tripianPrimary
        pagingViewController.indicatorOptions = .visible(height: 1, zIndex: Int.max, spacing: .init(top: 0, left: 0, bottom: 10, right: 0),insets: .zero)
    }
    
    public func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        childViewController.count
    }
    
    public func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        return childViewController[index]
    }
    
    public func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        let title = viewModel.getSectionTitle(index: index)
        let date = viewModel.getPagingDate(index: index)
        
        return CustomOverviewPagingItem(title: title, date: date)
    }
    
    public func pagingViewController(_: PagingViewController, widthForPagingItem pagingItem: PagingItem, isSelected: Bool) -> CGFloat {
        guard let item = pagingItem as? PagingIndexItem else { return 0 }

        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: pagingViewController.menuItemSize.height)

        let attributes = [NSAttributedString.Key.font: pagingViewController.font]

        let rect = item.title.boundingRect(with: size,
                                           options: .usesLineFragmentOrigin,
                                           attributes: attributes,
                                           context: nil)

        let width = ceil(rect.width) + insets.left + insets.right
        //let fullWidth = CGFloat(viewModel.getPagingNumber()) * width

        let pagingNumber = childViewController.count

        let fullWidth = CGFloat(pagingNumber) * width
        let windowsWidth = self.view.frame.width
        if fullWidth < windowsWidth {
            return windowsWidth / CGFloat(pagingNumber)
        }
        
        return width
    }
    
    
}


extension OverviewContainerVC:  OverviewContainerViewModelDelegate {
    
   
    public override func viewModel(dataLoaded: Bool) {
        
        DispatchQueue.main.async {
            self.pagingViewController.reloadData()
            if self.viewModel.dataIsLoaded {
                self.addNavigationBarCustomView(view: UIView())
            }
        }
    }
    func childOverviewVCLoaded(childVCs: [OverviewViewController]) {
        
        DispatchQueue.main.async {
            self.childViewController = childVCs
            self.pagingViewController.reloadData()
        }
    }

}
