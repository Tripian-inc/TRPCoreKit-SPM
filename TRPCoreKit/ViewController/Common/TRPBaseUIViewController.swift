//
//  TRPBaseUIViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 6.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit


public class TRPBaseUIViewController: UIViewController {
    
    
    public enum CloseButtonPosition {
        case left, right
    }
    
    //MARK: UI
    public var loader: TRPLoaderView?
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
        setupViews()
        hideKeyboardWhenTappedAround()
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
    
}

extension TRPBaseUIViewController:  ViewModelDelegate {
    
    @objc nonisolated public func viewModel(error: Error) {
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
    }
    
    @objc public func viewModel(showPreloader: Bool) {
        if showPreloader {
            loader?.show()
        }else {
            loader?.remove()
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

