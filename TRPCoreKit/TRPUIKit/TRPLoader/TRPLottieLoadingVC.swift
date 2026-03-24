//
//  TRPLottieLoadingVC.swift
//  TRPCoreKit
//
//  Loading view with Lottie animation.
//  Supports full-screen (rotating texts) and bottom sheet (single text) modes.
//
//  Created by Cem Çaygöz on 24.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit
import Lottie

// MARK: - Presentation Mode

/// Defines how the Lottie loading view should be presented
public enum LottieLoadingPresentationMode {
    /// Full-screen modal with rotating text labels (for long operations)
    case fullScreen
    /// Bottom sheet with single static text (for short operations)
    case bottomSheet(text: String)
}

// MARK: - TRPLottieLoadingVC

public class TRPLottieLoadingVC: UIViewController {

    // MARK: - Constants
    private let textRotationInterval: TimeInterval = 2.0
    private let animationName = "loading_animation"

    // Layout constants for different modes
    private let fullScreenAnimationSize: CGFloat = 120
    private let bottomSheetAnimationSize: CGFloat = 80
    private let bottomSheetTopPadding: CGFloat = 32
    private let bottomSheetBottomPadding: CGFloat = 32

    // MARK: - UI Components
    private lazy var animationView: LottieAnimationView = {
        // Load animation using file path for reliable SPM resource loading
        let animationView: LottieAnimationView

        // Try multiple paths for SPM resource bundle compatibility
        if let url = Bundle.module.url(forResource: animationName, withExtension: "json", subdirectory: "Animations"),
           let animation = LottieAnimation.filepath(url.path) {
            // Found in Animations subdirectory
            animationView = LottieAnimationView(animation: animation)
        } else if let url = Bundle.module.url(forResource: animationName, withExtension: "json"),
                  let animation = LottieAnimation.filepath(url.path) {
            // Found at root level
            animationView = LottieAnimationView(animation: animation)
        } else if let animation = LottieAnimation.named(animationName, bundle: Bundle.module) {
            // Fallback: use named method
            animationView = LottieAnimationView(animation: animation)
        } else {
            // Final fallback: empty animation view
            animationView = LottieAnimationView()
            print("Warning: Could not load Lottie animation '\(animationName)'")
        }

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        return animationView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(18)
        label.textColor = TRPColor.darkGrey
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Properties
    private var rotatingTexts: [String] = []
    private var currentTextIndex: Int = 0
    private var textRotationTimer: Timer?

    /// Presentation mode (full-screen or bottom sheet)
    private var presentationMode: LottieLoadingPresentationMode = .fullScreen

    /// Constraint references for dynamic layout
    private var animationWidthConstraint: NSLayoutConstraint?
    private var animationHeightConstraint: NSLayoutConstraint?
    private var animationCenterYConstraint: NSLayoutConstraint?
    private var animationTopConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRotatingTexts()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAnimation()

        // Only start text rotation for full-screen mode
        if case .fullScreen = presentationMode {
            startTextRotation()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
        stopTextRotation()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white
        overrideUserInterfaceStyle = .light

        view.addSubview(animationView)
        view.addSubview(textLabel)

        // Common constraints
        animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        textLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 16).isActive = true

        // Mode-specific layout
        switch presentationMode {
        case .fullScreen:
            setupFullScreenLayout()
        case .bottomSheet(let text):
            setupBottomSheetLayout(text: text)
        }
    }

    private func setupFullScreenLayout() {
        // Animation: 120x120, centered slightly above center
        animationWidthConstraint = animationView.widthAnchor.constraint(equalToConstant: fullScreenAnimationSize)
        animationHeightConstraint = animationView.heightAnchor.constraint(equalToConstant: fullScreenAnimationSize)
        animationCenterYConstraint = animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40)

        animationWidthConstraint?.isActive = true
        animationHeightConstraint?.isActive = true
        animationCenterYConstraint?.isActive = true
    }

    private func setupBottomSheetLayout(text: String) {
        // Animation: 80x80, top-aligned with padding
        animationWidthConstraint = animationView.widthAnchor.constraint(equalToConstant: bottomSheetAnimationSize)
        animationHeightConstraint = animationView.heightAnchor.constraint(equalToConstant: bottomSheetAnimationSize)
        animationTopConstraint = animationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: bottomSheetTopPadding)

        animationWidthConstraint?.isActive = true
        animationHeightConstraint?.isActive = true
        animationTopConstraint?.isActive = true

        // Set static text (no rotation)
        textLabel.text = text
    }

    private func loadRotatingTexts() {
        // Only load rotating texts for full-screen mode
        guard case .fullScreen = presentationMode else { return }

        rotatingTexts = LoadingLocalizationKeys.allRotatingTexts()
        if !rotatingTexts.isEmpty {
            textLabel.text = rotatingTexts[0]
        }
    }

    // MARK: - Animation Control

    private func startAnimation() {
        animationView.play()
    }

    private func stopAnimation() {
        animationView.stop()
    }

    // MARK: - Text Rotation

    private func startTextRotation() {
        guard rotatingTexts.count > 1 else { return }

        textRotationTimer = Timer.scheduledTimer(
            withTimeInterval: textRotationInterval,
            repeats: true
        ) { [weak self] _ in
            self?.rotateText()
        }
    }

    private func stopTextRotation() {
        textRotationTimer?.invalidate()
        textRotationTimer = nil
    }

    private func rotateText() {
        currentTextIndex = (currentTextIndex + 1) % rotatingTexts.count

        UIView.transition(
            with: textLabel,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [weak self] in
            guard let self = self else { return }
            self.textLabel.text = self.rotatingTexts[self.currentTextIndex]
        }
    }

    // MARK: - Presentation Helpers

    /// Shows the loading view controller as full-screen modal over the specified view controller
    /// Finds the topmost presented view controller to avoid presentation conflicts
    /// - Parameter presenter: The view controller to present from
    /// - Returns: The loading view controller for dismissal
    @discardableResult
    public static func show(over presenter: UIViewController) -> TRPLottieLoadingVC {
        // Find topmost presented controller to avoid "already presenting" error
        var topVC = presenter
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let loadingVC = TRPLottieLoadingVC()
        loadingVC.presentationMode = .fullScreen
        loadingVC.modalPresentationStyle = .overFullScreen
        loadingVC.modalTransitionStyle = .crossDissolve
        topVC.present(loadingVC, animated: true)
        return loadingVC
    }

    /// Shows the loading view controller as a bottom sheet with single static text
    /// - Parameters:
    ///   - presenter: The view controller to present from
    ///   - text: The text to display (localized string or direct text)
    /// - Returns: The loading view controller for dismissal
    @discardableResult
    public static func showAsSheet(over presenter: UIViewController, text: String) -> TRPLottieLoadingVC {
        // Find topmost presented controller to avoid "already presenting" error
        var topVC = presenter
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let loadingVC = TRPLottieLoadingVC()
        loadingVC.presentationMode = .bottomSheet(text: text)

        // Present as bottom sheet with dynamic height
        topVC.presentVCWithDynamicHeight(
            loadingVC,
            prefersGrabberVisible: false,
            isDimmed: true,
            disableSwipeToDismiss: true
        )
        return loadingVC
    }

    /// Dismisses the loading view controller
    public func hide(completion: (() -> Void)? = nil) {
        dismiss(animated: true, completion: completion)
    }

    // MARK: - Availability Check

    /// Checks if the Lottie animation file is available in the bundle
    public static func isAvailable() -> Bool {
        return Bundle.module.url(
            forResource: "loading_animation",
            withExtension: "json",
            subdirectory: "Animations"
        ) != nil
    }
}

// MARK: - DynamicHeightPresentable

extension TRPLottieLoadingVC: DynamicHeightPresentable {
    /// Returns the preferred height for bottom sheet presentation
    /// Calculated as: top padding + animation + spacing + text + bottom padding
    public var preferredContentHeight: CGFloat {
        // Only applicable for bottom sheet mode
        guard case .bottomSheet = presentationMode else {
            return UIScreen.main.bounds.height
        }

        // Calculate height: top padding + animation + spacing + estimated text height + bottom padding
        // 32 (top) + 80 (animation) + 16 (spacing) + 50 (text estimate) + 32 (bottom)
        return bottomSheetTopPadding + bottomSheetAnimationSize + 16 + 50 + bottomSheetBottomPadding
    }
}
