//
//  TRPTabBarIteme.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 26.07.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
public struct TRPTabBarItem {
    
    enum Style: Int {
        case normal, big
    }
    
    var style: Style = .normal
    public let id: Int
    let defaultImage: UIImage
    var selectedImage: UIImage?
    public let title: String
    
    
    init(style: Style = .normal,
         id:Int,
         title: String,
         defaultImage: UIImage,
         selectedImage: UIImage? = nil) {
        self.style = style
        self.id = id
        self.defaultImage = defaultImage
        self.selectedImage = selectedImage
        self.title = title
    }
    
}
