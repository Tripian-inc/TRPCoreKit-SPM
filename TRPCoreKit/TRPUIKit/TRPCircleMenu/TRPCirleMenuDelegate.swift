//
//  TRPCirleMenuDelegate.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 28.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
import UIKit
public protocol TRPCirleMenuDelegate: AnyObject {
    func circleMenu(_ circleMenu: TRPCircleMenu, onPress button: UIButton, atIndex: Int)
    func circleMenu(_ circleMenu: TRPCircleMenu, changedState state: TRPCircleMenu.CurrentState)
}
