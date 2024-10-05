//
//  ReusableCellHolder.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/17/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

// MARK: - ReusableCell
public protocol ReusableCell: AnyObject {
    associatedtype CellHolder: ReusableCellHolder
}

extension UITableViewCell: ReusableCell {
    public typealias CellHolder = UITableView
}

// MARK: - ReusableCellHolder
public protocol ReusableCellHolder: AnyObject {
    associatedtype CellType: ReusableCell where CellType.CellHolder == Self

    func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String)
    func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> CellType
    func cellForItem(at indexPath: IndexPath) -> CellType?
}

extension UITableView: ReusableCellHolder {
    
    @objc(registerClass:forCellWithReuseIdentifier:)
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        register(cellClass, forCellReuseIdentifier: identifier)
    }

    public func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
        return dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    }

    public func cellForItem(at indexPath: IndexPath) -> UITableViewCell? {
        return cellForRow(at: indexPath)
    }

}
