//
//  UseCase.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 20.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol UseCase {
    @discardableResult
    func start() -> Cancellable?
}
