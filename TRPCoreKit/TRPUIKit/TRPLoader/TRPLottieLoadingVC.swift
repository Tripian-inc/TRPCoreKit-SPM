//
//  TRPLottieLoadingVC.swift
//  TRPCoreKit
//
//  Full-screen loading view with Lottie animation and rotating text labels.
//
//  Created by Cem Çaygöz on 24.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit
import Lottie

public class TRPLottieLoadingVC: UIViewController {

    // MARK: - Constants
    private let textRotationInterval: TimeInterval = 2.0
    private let animationName = "loading_animation"

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

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRotatingTexts()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAnimation()
        startTextRotation()
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

        // Animation view constraints (centered, slightly above center)
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            animationView.widthAnchor.constraint(equalToConstant: 120),
            animationView.heightAnchor.constraint(equalToConstant: 120)
        ])

        // Text label constraints (below animation)
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 24),
            textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func loadRotatingTexts() {
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

    /// Shows the loading view controller modally over the specified view controller
    /// Finds the topmost presented view controller to avoid presentation conflicts
    @discardableResult
    public static func show(over presenter: UIViewController) -> TRPLottieLoadingVC {
        // Find topmost presented controller to avoid "already presenting" error
        var topVC = presenter
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let loadingVC = TRPLottieLoadingVC()
        loadingVC.modalPresentationStyle = .overFullScreen
        loadingVC.modalTransitionStyle = .crossDissolve
        topVC.present(loadingVC, animated: true)
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
