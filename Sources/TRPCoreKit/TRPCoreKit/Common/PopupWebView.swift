//
//  EvrAlertView.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-05-04.
//

import Foundation
import UIKit
import WebKit
class PopupWebView {
    
    private let container = UIView()
    init() {
        
    }
    var btnAction: (() -> Void)?
    func show(url: String, parentViewController: UIViewController? = nil ) {
        
        guard let topViewController = getViewController(parentViewController) else {
            print("[Error] TopViewController is nil")
            return
        }

        DispatchQueue.main.async { [self] in
            topViewController.view.addSubview(container)
            container.translatesAutoresizingMaskIntoConstraints = false
            container.alpha = 0
            
            let backgroundView = UIView()
            container.addSubview(backgroundView)
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.backgroundColor = UIColor.darkGray
            backgroundView.alpha = 0.5
            backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(self.closeAction)))
            
            let webView = WKWebView()
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.load(URLRequest(url: URL(string: url)!))
            webView.allowsBackForwardNavigationGestures = true
            container.addSubview(webView)
            
            let closeBtn = UIButton()
            closeBtn.translatesAutoresizingMaskIntoConstraints = false
            closeBtn.setImage(UIImage(named: "nav_close"), for: .normal)
            closeBtn.isUserInteractionEnabled = true
            closeBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
            container.addSubview(closeBtn)
            
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: topViewController.view.topAnchor, constant: 0),
                container.leadingAnchor.constraint(equalTo: topViewController.view.leadingAnchor, constant: 0),
                container.trailingAnchor.constraint(equalTo: topViewController.view.trailingAnchor, constant: 0),
                container.bottomAnchor.constraint(equalTo: topViewController.view.bottomAnchor, constant: 0),
                
                backgroundView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
                backgroundView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
                backgroundView.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
                backgroundView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0),
                
                webView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                webView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                webView.topAnchor.constraint(equalTo: container.topAnchor, constant: 80),
                webView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
                
                closeBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                closeBtn.topAnchor.constraint(equalTo: container.topAnchor, constant: 35),
                closeBtn.widthAnchor.constraint(equalToConstant: 40),
                closeBtn.heightAnchor.constraint(equalToConstant: 40)
            ])
            container.transform = CGAffineTransform(translationX: 0, y: 40)
            
            container.bringSubviewToFront(closeBtn)
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.8,
                           options: .curveEaseOut) {
                self.container.alpha = 1
                self.container.transform = .identity
            } completion: { completed in
                
            }
        }
       
    }
    @objc func closeAction() {
        btnAction?()
    }
    
    public func closeView() {
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseIn) {
            self.container.alpha = 0
            self.container.transform = CGAffineTransform(translationX: 0, y: 40)
        } completion: { completed in
            if completed {
                self.container.removeFromSuperview()
            }
        }
    }
    
    
    private func getViewController(_ parent: UIViewController?) -> UIViewController? {
        if let parent = parent {
            return parent
        }
        return getTopViewController()
    }
    
    private func getTopViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}
