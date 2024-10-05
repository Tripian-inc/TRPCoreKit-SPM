//
//  UIApplication+extensions.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 28.08.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
extension UIApplication {
    
    public class func getTopViewController() -> UIViewController? {
        let keyWindow = currentUIWindow()
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
    private class func currentUIWindow() -> UIWindow? {
        let connectedScenes = UIApplication.shared.connectedScenes
            .filter({
                $0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
        
        let window = connectedScenes.first?
            .windows
            .first { $0.isKeyWindow }

        return window
        
    }
}
