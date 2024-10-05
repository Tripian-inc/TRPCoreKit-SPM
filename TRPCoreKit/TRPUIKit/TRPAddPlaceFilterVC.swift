//
//  TRPAddPlaceFilterVC.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 14.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit

public class TRPAddPlaceFilterVC {
    
    public enum ButtonType {
        case recommendation, nearBy, cancel
    }
    
    private var mHandler: ((ButtonType) -> Swift.Void)? = nil
    private var selectedButton: ButtonType
    public var title:String? = nil
    public var message:String? = nil
    public var recommendataionText = "Recommendation"
    public var nearByText = "Nearby"
    
    public init(selectedButton: ButtonType, handler: ((ButtonType) -> Swift.Void)? = nil) {
        self.mHandler = handler
        self.selectedButton = selectedButton
    }
    
    public func getVC() -> UIViewController {
        let alertController = UIAlertController(title: title , message: message, preferredStyle: UIAlertController.Style.actionSheet)
        
        let recommendataion = UIAlertAction(title: recommendataionText, style: UIAlertAction.Style.default) { (action) in
            self.mHandler?(.recommendation)
        }
        let nearBy = UIAlertAction(title: nearByText, style: UIAlertAction.Style.default) { (_) in
            self.mHandler?(.nearBy)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (_) in}
        cancel.setValue(UIColor(red: 229.0/255.0, green: 78.0/255.0, blue: 83.0/255.0, alpha: 1.0), forKey: "titleTextColor")
        
        if selectedButton == .nearBy {
            nearBy.setValue(true, forKey: "checked")
        }else if selectedButton == .recommendation {
            recommendataion.setValue(true, forKey: "checked")
        }
        
        alertController.addAction(recommendataion)
        alertController.addAction(nearBy)
        alertController.addAction(cancel)
        return alertController
    }
}
