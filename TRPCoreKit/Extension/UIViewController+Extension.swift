//
//  UIViewController+Extension.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 8.07.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Dynamic Height Protocol
public protocol DynamicHeightPresentable: UIViewController {
    /// Returns the preferred content height for the sheet
    var preferredContentHeight: CGFloat { get }

    /// Called when the sheet height needs to be updated
    func updateSheetHeight()
}

extension DynamicHeightPresentable {
    /// Updates the sheet presentation controller's detent to match the preferred content height
    public func updateSheetHeight() {
        guard #available(iOS 16.0, *),
              let sheet = sheetPresentationController else { return }

        let height = preferredContentHeight
        let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("dynamicHeight")) { _ in
            return height
        }

        sheet.animateChanges {
            sheet.detents = [customDetent]
        }
    }
}

extension UIViewController {

    func hiddenBackButtonTitle() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    func hideNavigationBar(){
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func showNavigationBar() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func hideToolBar() {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    func showToolBar() {
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    func presentVCWithModal(_ vc: UIViewController,
                            onlyLarge: Bool = false,
                            prefersGrabberVisible: Bool = true,
                            prefersScrollingExpandsWhenScrolledToEdge: Bool = false,
                            isDimmed: Bool = true,
                            disableSwipeToDismiss: Bool = false) {
        vc.modalPresentationStyle = .pageSheet

        // Disable swipe-to-dismiss if requested (only close button can dismiss)
        if disableSwipeToDismiss {
            vc.isModalInPresentation = true
        }

        if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                if onlyLarge {
                    sheet.detents = [.large()]
                } else {
                    sheet.detents = [.medium(), .large()]
                }
                sheet.prefersGrabberVisible = prefersGrabberVisible
                sheet.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
                sheet.largestUndimmedDetentIdentifier = isDimmed ? nil : .large
            }
        }
        present(vc, animated: true)
    }

    /// Presents a view controller as a bottom sheet with dynamic height based on content
    /// - Parameters:
    ///   - vc: The view controller to present (should conform to DynamicHeightPresentable)
    ///   - prefersGrabberVisible: Whether to show the grabber handle
    ///   - isDimmed: Whether to dim the background
    ///   - disableSwipeToDismiss: Whether to disable swipe-to-dismiss (only close button can dismiss)
    func presentVCWithDynamicHeight(_ vc: UIViewController,
                                    prefersGrabberVisible: Bool = true,
                                    isDimmed: Bool = true,
                                    disableSwipeToDismiss: Bool = true) {
        vc.modalPresentationStyle = .pageSheet

        // Disable swipe-to-dismiss if requested (only close button can dismiss)
        if disableSwipeToDismiss {
            vc.isModalInPresentation = true
        }

        if #available(iOS 16.0, *) {
            if let sheet = vc.sheetPresentationController {
                // Get initial height from the VC if it conforms to DynamicHeightPresentable
                if let dynamicVC = vc as? DynamicHeightPresentable {
                    let height = dynamicVC.preferredContentHeight
                    let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("dynamicHeight")) { _ in
                        return height
                    }
                    sheet.detents = [customDetent]
                } else {
                    // Fallback to medium if not conforming
                    sheet.detents = [.medium(), .large()]
                }

                sheet.prefersGrabberVisible = prefersGrabberVisible
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.largestUndimmedDetentIdentifier = isDimmed ? nil : .medium
            }
        } else if #available(iOS 15.0, *) {
            // Fallback for iOS 15 - use medium detent
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = prefersGrabberVisible
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.largestUndimmedDetentIdentifier = isDimmed ? nil : .medium
            }
        }

        present(vc, animated: true)
    }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

extension UINavigationBar {
    
    func setNexusBar(_ barTintColor: UIColor = .white) {
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = barTintColor
            appearance.shadowColor = .clear
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: trpTheme.color.tripianPrimary]
            appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: trpTheme.color.tripianPrimary]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        
        self.barTintColor = barTintColor
        isTranslucent = false
        setBackgroundImage(UIImage(), for:.default)
        shadowImage = UIImage()
        layoutIfNeeded()
        barStyle = .default
    }

}
