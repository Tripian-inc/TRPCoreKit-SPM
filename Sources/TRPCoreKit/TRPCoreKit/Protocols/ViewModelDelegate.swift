//
//  ViewModelDelegate.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 17.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
public protocol ViewModelDelegate: AnyObject {
    func viewModel(dataLoaded:Bool)
    func viewModel(error: Error)
    func viewModel(showPreloader:Bool)
    func viewModel(showMessage: String, type: EvrAlertLevel)
}

extension ViewModelDelegate {
    public func viewModel(dataLoaded: Bool) {}
    public func viewModel(error: Error) {}
    public func viewModel(showPreloader: Bool) {}
    public func viewModel(showMessage: String, type: EvrAlertLevel) {}
}
