//
//  EvrAlertView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-07.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
public enum EvrAlertLevel {
    case success
    case error
    case warning
    case info
    
    func getImage() -> UIImage? {
        var imageName: String = ""
        switch self {
        case .error:
            imageName = "alert_error"
        case .info:
            imageName = "alert_info"
        case .success:
            imageName = "alert_success"
        case .warning:
            imageName = "alert_warning"
        }
        return TRPImageController().getImage(inFramework: imageName, inApp: nil)
    }
}
public class EvrAlertView {
    
    public static func showAlert(
        contentText: String,
        type: EvrAlertLevel = .error,
        bottomSpace: CGFloat = 60,
        showTime:TimeInterval = 3,
        showAnimation: TimeInterval = 0.7)
    {
        
        guard let topViewController = UIApplication.getTopViewController() else {
            print("[Error] TopViewController is nil")
            return
        }
        
        DispatchQueue.main.async {
            let container = UIView()
            topViewController.view.addSubview(container)
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = UIColor(red: 32/255, green: 33/255, blue: 38/255, alpha: 1)
            container.layer.cornerRadius = 24
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.3
            container.layer.shadowOffset = CGSize(width: 0, height: 4)
            container.layer.shadowRadius = 10
            container.alpha = 0
            
            let label = UILabel()
            container.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.systemFont(ofSize: 15)
            label.textColor = UIColor.white
            label.numberOfLines = 0
            label.text = contentText
            
            
            let image = UIImageView()
            container.addSubview(image)
            image.translatesAutoresizingMaskIntoConstraints = false
            image.contentMode = .scaleAspectFit
            image.image = type.getImage()
            image.alpha = 0.8
            
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: topViewController.view.leadingAnchor, constant: 8),
                container.trailingAnchor.constraint(equalTo: topViewController.view.trailingAnchor, constant: -8),
                container.bottomAnchor.constraint(equalTo: topViewController.view.bottomAnchor, constant: bottomSpace * -1),
                
                image.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                image.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                image.widthAnchor.constraint(equalToConstant: 24),
                image.heightAnchor.constraint(equalToConstant: 24),
                
                label.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
            ])
            container.transform = CGAffineTransform(translationX: 0, y: 40)
            
            UIView.animate(withDuration: showAnimation,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.8,
                           options: .curveEaseOut) {
                container.alpha = 1
                container.transform = .identity
            } completion: { completed in
                
            }
            
            
            
            Timer.scheduledTimer(withTimeInterval: showTime + showAnimation, repeats: false) { _ in
                UIView.animate(withDuration: showAnimation,
                               delay: 0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 0.8,
                               options: .curveEaseIn) {
                    container.alpha = 0
                    container.transform = CGAffineTransform(translationX: 0, y: 40)
                } completion: { completed in
                    if completed {
                        container.removeFromSuperview()
                    }
                }
                
            }
        }
        
    }    
    
}
