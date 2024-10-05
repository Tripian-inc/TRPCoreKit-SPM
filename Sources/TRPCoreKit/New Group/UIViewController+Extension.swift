//
//  UIViewController+Extension.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 8.07.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
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
    
    func presentVCWithModal(_ vc : UIViewController, onlyLarge: Bool = false) {
        vc.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                if onlyLarge {
                    sheet.detents = [.large()]
                } else {
                    sheet.detents = [.medium(), .large()]
                }
            }
        }
        present(vc, animated: true)
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
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
