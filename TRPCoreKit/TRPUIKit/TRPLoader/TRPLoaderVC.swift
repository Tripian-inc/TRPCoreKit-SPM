//
//  TRPLoaderVC.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 27.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit
public class TRPLoaderVC: UIViewController {
    
    var loader: TRPLoaderView?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        self.view.frame = UIScreen.main.bounds
        self.view.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .clear
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        guard let window: UIWindow = UIApplication.currentUIWindow() else { return }
        window.addSubview(view)
        window.bringSubviewToFront(view)
        view.frame = window.bounds
        
        if loader == nil {
            loader = TRPLoaderView(superView: view)
        }else {
            loader?.remove()
        }
        
        loader!.show()
    }
    
}

