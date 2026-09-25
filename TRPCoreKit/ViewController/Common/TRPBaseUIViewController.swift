//
//  TRPBaseUIViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 6.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPRestKit

public class TRPBaseUIViewController: UIViewController {
    
    
    public enum CloseButtonPosition {
        case left, right
    }
    
    //MARK: UI
    public var loader: TRPLoaderView?
    /// Active bottom-sheet Lottie loader presented by the current screen (one at a time).
    /// Tracked as a weak reference so dismissal cleans itself up if anything else dismissed
    /// the sheet first.
    private weak var activeLottieBottomSheet: TRPLottieLoadingVC?
    /// Active embedded (child VC) Lottie loader inside the current screen's view.
    private weak var activeEmbeddedLottie: TRPLottieLoadingVC?

    /// Captured `isModalInPresentation` value from before an `.inView` Lottie was shown,
    /// so we can restore the host sheet's swipe-to-dismiss state after the loader hides.
    private var preEmbedIsModalInPresentation: Bool?
    /// Captured grabber visibility from before an `.inView` Lottie was shown.
    private var preEmbedPrefersGrabberVisible: Bool?

    private var isPopupOnView = false
    
    public var applyButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Apply", for: .normal)
        btn.backgroundColor = TRPColor.pink
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(applyButtonPressed), for: UIControl.Event.touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        btn.layer.cornerRadius = 6
        return btn
    }()
    
    
    private lazy var alertView: PopupAlert = {
        let vc = UIStoryboard.getPopup()
        vc.delegate = self
        return vc
    }()
  
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        overrideUserInterfaceStyle = .light

        // Force light mode on window for system UI components (date pickers, etc.)
        if let window = view.window ?? UIApplication.currentUIWindow() {
            window.overrideUserInterfaceStyle = .light
        }

        setupViews()
        hideKeyboardWhenTappedAround()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure window is set to light mode (in case it wasn't available in viewDidLoad)
        if let window = view.window ?? UIApplication.currentUIWindow() {
            window.overrideUserInterfaceStyle = .light
        }
    }
    
    public func setupViews() {
        loader = TRPLoaderView(superView: view)
    }
    
    @objc func applyButtonPressed() {}
    
    @objc func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func backButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    func showWarningIfOffline() -> Bool {
        /*if ReachabilityUseCases.shared.isOnline == false {
            let alert = UIAlertController(title: "Ups", message: "This feature needs internet connection", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return true
        }*/
        return false
    }
    
}

//MARK: - Custom UI
extension TRPBaseUIViewController {
    
    public func addApplyButton() {
        view.addSubview(applyButton)
        applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        if #available(iOS 11.0, *) {
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        }else {
            applyButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16).isActive = true
        }
    }
    
    public func addCloseButton(position: CloseButtonPosition) {
        guard let image = TRPImageController().getImage(inFramework: "btn_create_trip_back", inApp: TRPAppearanceSettings.Common.closeButtonImage) else {
            print("[Error] Close Button image can not found")
            return
        }
        
        let navButton = UIBarButtonItem(image: image.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(closeButtonPressed))
       
        
        switch position {
        case .left:
            navigationItem.leftBarButtonItem = navButton
        case .right:
            navigationItem.rightBarButtonItem = navButton
        }
    }
    
    public func addBackButton(position: CloseButtonPosition) {
        guard let image = TRPImageController().getImage(inFramework: "btn_create_trip_back", inApp: TRPAppearanceSettings.Common.closeButtonImage) else {
            print("[Error] Close Button image can not found")
            return
        }
        
        let navButton = UIBarButtonItem(image: image.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(backButtonPressed))
       
        
        switch position {
        case .left:
            navigationItem.leftBarButtonItem = navButton
        case .right:
            navigationItem.rightBarButtonItem = navButton
        }
    }
    
    public func addNavigationBarCustomView(view: UIView) {
        let barButtonItem = UIBarButtonItem(customView: view)
        self.navigationItem.rightBarButtonItem = barButtonItem
    }

    /// Sets up a custom navigation bar with title and back button
    /// - Parameters:
    ///   - title: The title to display
    ///   - height: Navigation bar height (default: 56)
    /// - Returns: The configured navigation bar (set delegate on it for back button action)
    @discardableResult
    func setupCustomNavigationBar(title: String, height: CGFloat = 56) -> TRPTimelineCustomNavigationBar {
        let navBar = TRPTimelineCustomNavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.setTitle(title)

        view.addSubview(navBar)
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: height)
        ])

        return navBar
    }

    public func showConfirmAlert(title: String, message: String, confirmTitle: String, cancelTitle: String = "Cancel", attributedMessage: NSAttributedString? = nil, btnConfirmAction: (() -> Void)? = nil, btnCancelAction: (() -> Void)? = nil) {
        if !isPopupOnView {
            self.alertView.configForConfirm(title: title, message: message, btnTitle: confirmTitle, btnCancelTitle: cancelTitle, attributedMessage: attributedMessage, btnConfirmAction: btnConfirmAction, btnCancelAction: btnCancelAction)
            self.alertView.show()
            isPopupOnView = true
        }
    }
    
    public func showOkAlert(title: String = "", message: String, subContent: String = "", btnTitle: String? = nil) {
        if !isPopupOnView {
            self.alertView.config(title: title, message: message, subContent: subContent, btnTitle: btnTitle)
            self.alertView.show()
            isPopupOnView = true
        }
    }

    public func showOkAlertWithCompletion(title: String = "", message: String, subContent: String = "", btnTitle: String? = nil, completion: @escaping () -> Void) {
        if !isPopupOnView {
            self.alertView.configWithCompletion(title: title, message: message, subContent: subContent, btnTitle: btnTitle, completion: completion)
            self.alertView.show()
            isPopupOnView = true
        }
    }
    
}

extension TRPBaseUIViewController:  ViewModelDelegate {
    
    @objc nonisolated public func viewModel(error: Error) {
        // Check for refresh token error - notify host app and dismiss SDK
        if let trpError = error as? TRPErrors {
            switch trpError {
            case .refreshTokenError:
                DispatchQueue.main.async {
                    // Notify host app
                    TRPCoreKit.shared.delegate?.trpCoreKitDidFailWithAuthError()
                    // Dismiss SDK
                    TRPCoreKit.dismiss(animated: true)
                }
                return
            default:
                break
            }
        }
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    @objc public func viewModel(showPreloader: Bool) {
        if showPreloader {
            loader?.show()
        }else {
            loader?.remove()
        }
    }

    /// Show a Lottie loader at the requested `presentation` (full-screen window overlay,
    /// modal bottom sheet, or embedded child VC). The `textMode` controls what (if
    /// anything) is rendered next to the animation. Marshals to the main thread since
    /// callers are typically on a network completion. `completion` fires after the show
    /// animation begins.
    public func viewModel(showLottie presentation: LottieLoaderPresentation,
                          textMode: LottieLoadingTextMode,
                          completion: (() -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { completion?(); return }
            switch presentation {
            case .fullScreen:
                TRPLottieLoadingVC.shared.showOnWindow(textMode: textMode)
                completion?()
            case .bottomSheet:
                self.activeLottieBottomSheet = TRPLottieLoadingVC.showAsSheet(
                    over: self,
                    textMode: textMode
                )
                completion?()
            case .inView:
                // Lock the host sheet (if any) while the embedded loader is up:
                //   • disable swipe-to-dismiss (`isModalInPresentation = true`)
                //   • hide the grabber so the sheet reads as non-interactive
                // The previous values are captured here and restored in `hideLottie`.
                self.preEmbedIsModalInPresentation = self.isModalInPresentation
                self.isModalInPresentation = true
                if #available(iOS 15.0, *), let sheet = self.sheetPresentationController {
                    self.preEmbedPrefersGrabberVisible = sheet.prefersGrabberVisible
                    sheet.prefersGrabberVisible = false
                }
                self.activeEmbeddedLottie = TRPLottieLoadingVC.embed(
                    in: self,
                    textMode: textMode
                )
                completion?()
            }
        }
    }

    /// Hide the active Lottie loader at the requested `presentation`. No-op if no loader
    /// of that kind is currently showing — `completion` still fires.
    public func viewModel(hideLottie presentation: LottieLoaderPresentation,
                          completion: (() -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { completion?(); return }
            switch presentation {
            case .fullScreen:
                TRPLottieLoadingVC.shared.hideFromWindow(completion: completion)
            case .bottomSheet:
                if let sheet = self.activeLottieBottomSheet {
                    self.activeLottieBottomSheet = nil
                    sheet.hide(completion: completion)
                } else {
                    completion?()
                }
            case .inView:
                // Restore the host sheet's interaction state captured by `showLottie`.
                // No-op if the loader was never shown.
                if let previous = self.preEmbedIsModalInPresentation {
                    self.isModalInPresentation = previous
                    self.preEmbedIsModalInPresentation = nil
                }
                if #available(iOS 15.0, *),
                   let previous = self.preEmbedPrefersGrabberVisible,
                   let sheet = self.sheetPresentationController {
                    sheet.prefersGrabberVisible = previous
                }
                self.preEmbedPrefersGrabberVisible = nil

                if let lottie = self.activeEmbeddedLottie {
                    self.activeEmbeddedLottie = nil
                    lottie.unembed(completion: completion)
                } else {
                    completion?()
                }
            }
        }
    }
    
    nonisolated public func viewModel(showMessage: String, type: EvrAlertLevel) {
        EvrAlertView.showAlert(contentText: showMessage, type: type)
    }
    
    @objc nonisolated public func viewModel(dataLoaded: Bool) {}
    
}

extension TRPBaseUIViewController {
    
    @objc func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

extension TRPBaseUIViewController {
    public func showError(_ error: Error, bottomSpace: CGFloat = 60) {
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error, bottomSpace: bottomSpace)
    }
    
    public func showMessage(_ message: String, type: EvrAlertLevel, bottomSpace: CGFloat = 60) {
        EvrAlertView.showAlert(contentText: message, type: type, bottomSpace:bottomSpace)
    }
    
    public func showLoader(_ show: Bool) {
        if show {
            loader?.show()
        }else {
            loader?.remove()
        }
    }
}

extension TRPBaseUIViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
//        if let nav = navigationController?.viewControllers {
//            return nav.count > 1
//        }
//        return false
    }
}

extension TRPBaseUIViewController:  PopupAlertDelegate {
    @objc func closedPopup() {
        isPopupOnView = false
    }
}

