//
//  AddPlanContainerVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

public protocol AddPlanContainerVCDelegate: AnyObject {
    func addPlanContainerDidComplete(_ viewController: AddPlanContainerVC, data: AddPlanData)
    func addPlanContainerDidCancel(_ viewController: AddPlanContainerVC)
}

@objc(SPMAddPlanContainerVC)
public class AddPlanContainerVC: TRPBaseUIViewController {
    
    // MARK: - Properties
    public var viewModel: AddPlanContainerViewModel!
    public weak var delegate: AddPlanContainerVCDelegate?
    private var viewControllers: [UIViewController] = []
    private var currentChildVC: UIViewController?
    
    // MARK: - UI Components - Sticky Header
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let handleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        return button
    }()
    
    // MARK: - Content Container
    private let contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    // MARK: - Sticky Footer
    private let footerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var clearSelectionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.clearSelection), for: .normal)
        button.setTitleColor(ColorSet.fg.uiColor, for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(16)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }()
    
    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.continueButton), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white, for: .disabled)
        button.titleLabel?.font = FontSet.montserratSemiBold.font(16)
        button.backgroundColor = ColorSet.primary.uiColor
        button.layer.cornerRadius = 25
        button.isEnabled = false // Start disabled
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.start()
    }
    
    public override func setupViews() {
        super.setupViews()
        
        setupBackgroundView()
        setupContainerView()
        setupHeader()
        setupFooter()  // Add footer to hierarchy first
        setupContentContainer()  // Then set up content container (which references footer)
        setupActions()
    }
    
    // MARK: - Setup Methods
    private func setupBackgroundView() {
        view.backgroundColor = .clear
        view.addSubview(backgroundView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
    }
    
    private func setupContainerView() {
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9)
        ])
    }
    
    private func setupHeader() {
        containerView.addSubview(handleView)
        containerView.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            // Handle
            handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            
            // Header View
            headerView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            // Back Button
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Title
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -8),
            
            // Close Button
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -24),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 18),
            closeButton.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    private func setupContentContainer() {
        containerView.addSubview(contentContainerView)
        
        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            contentContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: footerView.topAnchor)
        ])
    }
    
    private func setupFooter() {
        containerView.addSubview(footerView)
        footerView.addSubview(buttonStackView)
        
        // Add buttons to stack view
        buttonStackView.addArrangedSubview(clearSelectionButton)
        buttonStackView.addArrangedSubview(continueButton)
        
        NSLayoutConstraint.activate([
            // Footer View
            footerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Stack View
            buttonStackView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -24),
            buttonStackView.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        clearSelectionButton.addTarget(self, action: #selector(clearSelectionTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Public Methods
    public func addViewController(_ viewController: UIViewController) {
        viewControllers.append(viewController)
    }
    
    public func setContinueButtonEnabled(_ enabled: Bool) {
        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled ? ColorSet.primary.uiColor : ColorSet.bgDisabled.uiColor
    }
    
    public func updateContinueButtonState() {
        let currentStep = viewModel.getCurrentStep()
        let canProceed = canContinue(currentStep: currentStep)
        setContinueButtonEnabled(canProceed)
    }
    
    private func showViewController(at index: Int) {
        guard index < viewControllers.count else {
            print("⚠️ No VC at index \(index), total VCs: \(viewControllers.count)")
            return
        }
        
        print("📱 Showing VC at index \(index)")
        
        // Remove current child VC
        if let currentVC = currentChildVC {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        
        // Add new child VC
        let newVC = viewControllers[index]
        addChild(newVC)
        
        // Load the view if it hasn't been loaded yet
        newVC.loadViewIfNeeded()
        
        contentContainerView.addSubview(newVC.view)
        
        // Use Auto Layout instead of frame
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
        
        newVC.didMove(toParent: self)
        
        currentChildVC = newVC
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        viewModel.backStepAction()
    }
    
    @objc private func closeButtonTapped() {
        delegate?.addPlanContainerDidCancel(self)
        dismiss(animated: true)
    }
    
    @objc private func backgroundTapped() {
        closeButtonTapped()
    }
    
    @objc private func clearSelectionTapped() {
        // Notify current step to clear
        if let currentVC = currentChildVC as? AddPlanSelectDayVC {
            currentVC.clearSelection()
        } else if let currentVC = currentChildVC as? AddPlanTimeAndTravelersVC {
            currentVC.clearSelection()
        } else if let currentVC = currentChildVC as? AddPlanCategorySelectionVC {
            currentVC.clearSelection()
        }
        
        // Update continue button state after clearing
        updateContinueButtonState()
    }
    
    @objc private func continueButtonTapped() {
        // Validate current step before continuing
        let currentStep = viewModel.getCurrentStep()
        
        if canContinue(currentStep: currentStep) {
            viewModel.goNextStep()
        }
    }
    
    private func canContinue(currentStep: AddPlanSteps) -> Bool {
        switch currentStep {
        case .selectDayAndCity:
            return viewModel.planData.selectedDay != nil && 
                   viewModel.planData.selectedCity != nil &&
                   viewModel.planData.selectedMode != .none
        case .timeAndTravelers:
            return viewModel.planData.startingPoint != nil &&
                   viewModel.planData.startTime != nil &&
                   viewModel.planData.endTime != nil &&
                   viewModel.planData.travelers > 0
        case .categorySelection:
            return !viewModel.planData.selectedCategories.isEmpty
        }
    }
    
    private func updateUI() {
        let currentStep = viewModel.getCurrentStep()
        
        // Update title
        titleLabel.text = currentStep.getTitle()
        
        // Update back button visibility
        backButton.isHidden = (currentStep.getPreviousStep() == nil)
        
        // Update clear selection button visibility - stack view will handle layout automatically
        let isFirstScreen = (currentStep == .selectDayAndCity)
        clearSelectionButton.isHidden = isFirstScreen
        
        // Update continue button title
        continueButton.setTitle(viewModel.getButtonTitle(), for: .normal)
        
        // Update continue button state based on current step validation
        let canProceed = canContinue(currentStep: currentStep)
        setContinueButtonEnabled(canProceed)
        
        // Show appropriate view controller
        showViewController(at: currentStep.getIndex())
    }
}

// MARK: - AddPlanContainerViewModelDelegate
extension AddPlanContainerVC: AddPlanContainerViewModelDelegate {
    public func stepChanged() {
        updateUI()
    }
    
    public func planCompleted(data: AddPlanData) {
        print("✅ Plan completed!")
        delegate?.addPlanContainerDidComplete(self, data: data)
        dismiss(animated: true)
    }
}
