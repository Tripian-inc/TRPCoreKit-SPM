//
//  CreateTripContainer.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 15.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import UIKit
import Parchment
import TRPDataLayer

public protocol CreateTripContainerVCDelegate: AnyObject {
    func canContinue(currentStep: CreateTripSteps) -> Bool
    func createOrEditTrip()
}
class CreateTripContainerVC: TRPBaseUIViewController {

    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var previousTitle: UILabel!
    @IBOutlet weak var nextTitle: UILabel!
    @IBOutlet weak var previousView: UIView!
    @IBOutlet weak var nextView: UIView!
    @IBOutlet weak var continueBtn: UIButton!
    
    private let pagingViewController = PagingViewController()
    private var viewControllers = [UIViewController]()
    public var viewModel: CreateTripContainerViewModel!
    public var delegate: CreateTripContainerVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    public override func setupViews() {
        super.setupViews()
        setupPagination()
        hideNavigationBar()
        setupContinueBtn()
        setupTitles()
        setTitleTexts()
    }
    
    public func addViewControllerInPagination(_ viewController: UIViewController) {
        viewControllers.append(viewController)
        
    }
    
    public func reloadPagination() {
        pagingViewController.reloadData()
    }

    @IBAction func continueBtnPressed(_ sender: Any) {
        self.checkCanContinue()
    }
    @IBAction func closeBtnPressed(_ sender: Any) {
        self.closeButtonPressed()
    }
    @IBAction func backBtnPressed(_ sender: Any) {
        viewModel.backStepAction()
    }
    
    private func checkCanContinue() {
        if let canContinue = self.delegate?.canContinue(currentStep: viewModel.getCurrentStep()), canContinue {
            self.viewModel.goNextStep()
        }
    }
}

extension CreateTripContainerVC {
    private func setupTitles() {
        mainTitle.font = trpTheme.font.header2
        previousTitle.font = trpTheme.font.header2
        nextTitle.font = trpTheme.font.header2
        
        previousTitle.textColor = trpTheme.color.tripianBlack
        mainTitle.textColor = trpTheme.color.tripianPrimary
        nextTitle.textColor = .black.withAlphaComponent(0.2)
        
        continueBtn.setTitle(TRPLanguagesController.shared.getContinueBtnText(), for: .normal)
        
    }
    
    private func setupContinueBtn() {
        continueBtn.backgroundColor = trpTheme.color.tripianPrimary
        continueBtn.layer.cornerRadius = 10
    }
    
    private func hideBackButton() {
        backBtn.isHidden = true
    }
    
    private func showBackButton() {
        backBtn.isHidden = false
    }
    
    private func setTitleTexts() {
        let currentStep = viewModel.getCurrentStep()
        mainTitle.text = currentStep.getTitle()
        showBackButton()
        if let previousStep = currentStep.getPreviousStep() {
            previousTitle.text = previousStep.getTitle()
            previousView.isHidden = false
        } else {
            previousView.isHidden = true
            hideBackButton()
        }
        if let nextStep = currentStep.getNextStep() {
            nextTitle.text = nextStep.getTitle()
            nextView.isHidden = false
        } else {
            nextView.isHidden = true
        }
        
    }
}

// MARK: - PagingView Setter
extension CreateTripContainerVC:  PagingViewControllerDelegate, PagingViewControllerDataSource {
    
    fileprivate func setupPagination() {
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        
        pagingViewController.menuItemSize = .selfSizing(estimatedWidth: 80, height: 0)
        addChild(pagingViewController)
        containerView.addSubview(pagingViewController.view)
        containerView.constrainToEdges(pagingViewController.view, topSpacing: 0)
        pagingViewController.contentInteraction = .none
    }
    
    public func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        return viewControllers.count
    }
    
    public func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        return viewControllers[index]
    }
    
    public func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        let title = viewModel.getPagingTitle(index: index)
        return PagingIndexItem(index: index, title: title)
    }
 
}

extension CreateTripContainerVC: CreateTripContainerViewModelDelegate {
    func tripProcessCompleted() {
        delegate?.createOrEditTrip()
    }
    
    func stepChanged() {
        setTitleTexts()
        pagingViewController.select(index: viewModel.getCurrentStep().getIndex(), animated: true)
        let continueBtnTitle = viewModel.getButtonTitle()
        continueBtn.setTitle(continueBtnTitle, for: .normal)
    }
} 
