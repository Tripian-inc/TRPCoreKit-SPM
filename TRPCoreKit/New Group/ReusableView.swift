//
//  ReusableView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 11.02.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
public protocol ReusableView: AnyObject { }

extension ReusableView where Self: UIView {
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
}
