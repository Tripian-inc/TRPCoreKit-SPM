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

/// Defines how the Lottie loading view should be presented. Text content is controlled
/// independently via `LottieLoadingTextMode` for both modes.
public enum LottieLoadingPresentationMode {
    /// Full-screen modal — animation centered, optional text below.
    case fullScreen
    /// Bottom sheet — animation top-aligned within the sheet, optional text below.
    case bottomSheet
}

// MARK: - Text Mode

/// Configures what (if anything) is rendered next to the Lottie animation in full-screen mode.
public enum LottieLoadingTextMode {
    /// Animation only — no text label is shown.
    case none
    /// A single static line of text.
    case single(String)
    /// A list of texts that cycle every ~2s with a cross-dissolve transition.
    case rotating([String])

    /// Convenience: the default rotating texts from `LoadingLocalizationKeys`
    /// (used by long-running flows like timeline create/fetch).
    public static var defaultRotating: LottieLoadingTextMode {
        .rotating(LoadingLocalizationKeys.allRotatingTexts())
    }
}

// MARK: - TRPLottieLoadingVC

public class TRPLottieLoadingVC: UIViewController {

    // MARK: - Constants
    /// How long each rotating message is shown before advancing. The last message stays
    /// on screen until the loader is dismissed (no infinite loop).
    private let textRotationInterval: TimeInterval = 3.5
    private let animationName = "loader"

    // Layout constants for different modes
    private let fullScreenAnimationSize: CGFloat = 120
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

    /// Text rendering mode — applies to both full-screen and bottom sheet presentations.
    private var textMode: LottieLoadingTextMode = .defaultRotating

    /// Constraint references for dynamic layout
    private var animationWidthConstraint: NSLayoutConstraint?
    private var animationHeightConstraint: NSLayoutConstraint?
    private var animationCenterYConstraint: NSLayoutConstraint?
    private var animationTopConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyInitialTextContent()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAnimation()

        // Text rotation applies to any presentation mode with `.rotating` text mode.
        if case .rotating(let texts) = textMode, texts.count > 1 {
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
        case .bottomSheet:
            setupBottomSheetLayout()
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

    private func setupBottomSheetLayout() {
        // Animation: same size as full-screen (120x120), top-aligned within the sheet.
        // Text content (if any) is set by `applyInitialTextContent()` based on `textMode`.
        animationWidthConstraint = animationView.widthAnchor.constraint(equalToConstant: fullScreenAnimationSize)
        animationHeightConstraint = animationView.heightAnchor.constraint(equalToConstant: fullScreenAnimationSize)
        animationTopConstraint = animationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: bottomSheetTopPadding)

        animationWidthConstraint?.isActive = true
        animationHeightConstraint?.isActive = true
        animationTopConstraint?.isActive = true
    }

    /// Applies the initial text content based on the current `textMode`. Applies to both
    /// full-screen and bottom sheet presentations.
    private func applyInitialTextContent() {
        switch textMode {
        case .none:
            textLabel.isHidden = true
            rotatingTexts = []
        case .single(let text):
            textLabel.isHidden = false
            textLabel.text = text
            rotatingTexts = []
        case .rotating(let texts):
            rotatingTexts = texts
            if let first = texts.first {
                textLabel.isHidden = false
                textLabel.text = first
            } else {
                textLabel.isHidden = true
            }
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
        let nextIndex = currentTextIndex + 1
        guard nextIndex < rotatingTexts.count else {
            // Defensive: timer should already be stopped after reaching the last message.
            stopTextRotation()
            return
        }

        currentTextIndex = nextIndex
        UIView.transition(
            with: textLabel,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [weak self] in
            guard let self = self else { return }
            self.textLabel.text = self.rotatingTexts[self.currentTextIndex]
        }

        // Last message stays on screen until the loader is hidden — no infinite loop.
        if currentTextIndex == rotatingTexts.count - 1 {
            stopTextRotation()
        }
    }

    // MARK: - Presentation Helpers

    /// Shows the loading view controller as a full-screen modal over the specified view controller.
    /// Finds the topmost presented view controller to avoid presentation conflicts.
    /// - Parameters:
    ///   - presenter: The view controller to present from.
    ///   - textMode: Controls the label content — animation only, single text, or rotating list.
    ///     Defaults to the rotating timeline texts (preserves the prior default behavior).
    /// - Returns: The loading view controller for dismissal.
    @discardableResult
    public static func show(over presenter: UIViewController,
                            textMode: LottieLoadingTextMode = .defaultRotating) -> TRPLottieLoadingVC {
        // Find topmost presented controller to avoid "already presenting" error
        var topVC = presenter
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let loadingVC = TRPLottieLoadingVC()
        loadingVC.presentationMode = .fullScreen
        loadingVC.textMode = textMode
        loadingVC.modalPresentationStyle = .overFullScreen
        loadingVC.modalTransitionStyle = .crossDissolve
        topVC.present(loadingVC, animated: true)
        return loadingVC
    }

    /// Shows the loading view controller as a bottom sheet. The visual layout matches the
    /// full-screen variant (centered animation, optional text below) — only the presentation
    /// differs.
    /// - Parameters:
    ///   - presenter: The view controller to present from.
    ///   - textMode: Controls the label content — animation only, single text, or rotating list.
    ///     Defaults to `.none` (animation only).
    /// - Returns: The loading view controller for dismissal via `hide(completion:)`.
    @discardableResult
    public static func showAsSheet(over presenter: UIViewController,
                                    textMode: LottieLoadingTextMode = .none) -> TRPLottieLoadingVC {
        // Find topmost presented controller to avoid "already presenting" error
        var topVC = presenter
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let loadingVC = TRPLottieLoadingVC()
        loadingVC.presentationMode = .bottomSheet
        loadingVC.textMode = textMode

        // Present as bottom sheet with dynamic height
        topVC.presentVCWithDynamicHeight(
            loadingVC,
            prefersGrabberVisible: false,
            isDimmed: true,
            disableSwipeToDismiss: true
        )
        return loadingVC
    }

    /// Backward-compatible bottom sheet helper — wraps `showAsSheet(over:textMode:)` with a
    /// `.single(text)` text mode.
    @discardableResult
    public static func showAsSheet(over presenter: UIViewController, text: String) -> TRPLottieLoadingVC {
        return showAsSheet(over: presenter, textMode: .single(text))
    }

    /// Dismisses the loading view controller
    public func hide(completion: (() -> Void)? = nil) {
        dismiss(animated: true, completion: completion)
    }

    // MARK: - Shared instance (window-attached, TRPLoader-style reuse)

    /// Shared instance for window-attached display. Mirrors the `TRPLoaderVC` pattern —
    /// callers reuse this one VC instead of constructing a fresh one per screen.
    public static let shared = TRPLottieLoadingVC()

    /// Show as a full-screen overlay attached to the key window. Idempotent: calling
    /// while already visible just refreshes the text mode and brings the view forward.
    public func showOnWindow(textMode: LottieLoadingTextMode = .defaultRotating) {
        guard let window = UIApplication.currentUIWindow() else { return }
        loadViewIfNeeded()

        // Refresh text content for this presentation
        self.textMode = textMode
        applyInitialTextContent()
        currentTextIndex = 0
        stopTextRotation()

        if view.superview !== window {
            view.removeFromSuperview()
            view.alpha = 1
            view.frame = window.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubview(view)
        }
        window.bringSubviewToFront(view)

        startAnimation()
        if case .rotating(let texts) = textMode, texts.count > 1 {
            startTextRotation()
        }
    }

    /// Remove the window-attached lottie. Default fade-out for a smooth dismiss.
    public func hideFromWindow(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard view.superview != nil else {
            completion?()
            return
        }

        let cleanup: () -> Void = { [weak self] in
            guard let self = self else { completion?(); return }
            self.stopAnimation()
            self.stopTextRotation()
            self.view.removeFromSuperview()
            self.view.alpha = 1   // reset for next show
            completion?()
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.view.alpha = 0
            }, completion: { _ in cleanup() })
        } else {
            cleanup()
        }
    }

    // MARK: - Embed in host view (child VC)

    /// Embed a fresh Lottie loader into the given host VC's view as a child VC.
    /// Use when the host is itself already presented modally (e.g. a bottom sheet)
    /// and stacking another sheet would feel wrong — the loader appears inline,
    /// covering only the host's bounds. Returns the embedded VC for `unembed(...)`.
    @discardableResult
    public static func embed(in host: UIViewController,
                             textMode: LottieLoadingTextMode = .defaultRotating) -> TRPLottieLoadingVC {
        let lottieVC = TRPLottieLoadingVC()
        lottieVC.presentationMode = .fullScreen
        lottieVC.textMode = textMode

        host.addChild(lottieVC)
        lottieVC.view.translatesAutoresizingMaskIntoConstraints = false
        lottieVC.view.alpha = 0
        host.view.addSubview(lottieVC.view)
        NSLayoutConstraint.activate([
            lottieVC.view.topAnchor.constraint(equalTo: host.view.topAnchor),
            lottieVC.view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            lottieVC.view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            lottieVC.view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor)
        ])
        host.view.bringSubviewToFront(lottieVC.view)
        lottieVC.didMove(toParent: host)

        UIView.animate(withDuration: 0.2) {
            lottieVC.view.alpha = 1
        }
        return lottieVC
    }

    /// Reverse of `embed(in:textMode:)`. Fades out (default) and removes the loader
    /// from its parent view controller. Safe to call when not embedded — completion
    /// fires immediately in that case.
    public func unembed(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard parent != nil else {
            completion?()
            return
        }

        let cleanup: () -> Void = { [weak self] in
            guard let self = self else { completion?(); return }
            self.stopAnimation()
            self.stopTextRotation()
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
            self.view.alpha = 1
            completion?()
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.view.alpha = 0
            }, completion: { _ in cleanup() })
        } else {
            cleanup()
        }
    }

    // MARK: - Availability Check

    /// Checks if the Lottie animation file is available in the bundle
    public static func isAvailable() -> Bool {
        return Bundle.module.url(
            forResource: "loader",
            withExtension: "json",
            subdirectory: "Animations"
        ) != nil
    }
}

// MARK: - DynamicHeightPresentable

extension TRPLottieLoadingVC: DynamicHeightPresentable {
    /// Returns the preferred height for bottom sheet presentation. Height varies by `textMode`:
    /// `.none` → padding + animation + padding; `.single`/`.rotating` add spacing + estimated text height.
    public var preferredContentHeight: CGFloat {
        guard case .bottomSheet = presentationMode else {
            return UIScreen.main.bounds.height
        }

        let baseHeight = bottomSheetTopPadding + fullScreenAnimationSize + bottomSheetBottomPadding
        switch textMode {
        case .none:
            return baseHeight
        case .single, .rotating:
            let spacing: CGFloat = 16
            let estimatedTextHeight: CGFloat = 50
            return baseHeight + spacing + estimatedTextHeight
        }
    }
}
