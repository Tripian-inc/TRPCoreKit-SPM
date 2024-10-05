//
//  CellController.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/16/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

public class CellController<T: ReusableCellHolder> {

    private weak var reusableCellHolder: T?
    public var indexPath: IndexPath?

    public init() {}

    class var cellClass: AnyClass {
        fatalError("Must be overriden by children.")
    }

    public static var cellIdentifier: String {
        return String(describing: cellClass)
    }

    public static func registerCell(on reusableCellHolder: T) {
        reusableCellHolder.register(cellClass, forCellWithReuseIdentifier: cellIdentifier)
    }

    public final func cellFromReusableCellHolder(_ reusableCellHolder: T, forIndexPath indexPath: IndexPath) -> T.CellType {
        self.reusableCellHolder = reusableCellHolder
        self.indexPath = indexPath

        let cell = reusableCellHolder.dequeueReusableCell(withReuseIdentifier: type(of: self).cellIdentifier, for: indexPath)
        configureCell(cell)

        return cell
    }

    public final func innerCurrentCell() -> T.CellType? {
        guard let indexPath = indexPath else { return nil }
        return reusableCellHolder?.cellForItem(at: indexPath)
    }

    func configureCell(_ cell: T.CellType) {}

    func willDisplayCell(_ cell: T.CellType) {}

    func didEndDisplayingCell(_ cell: T.CellType) {}

    func didSelectCell() {}
    
    func updateCell(tableView: UITableView){}

    func didDeselectCell() {}

    func shouldHighlightCell() -> Bool {
        return true
    }

    func didHightlightCell() {}

    func didUnhightlightCell() {}

    func cellSize() -> CGFloat { return UITableView.automaticDimension }

    func estimatedCellSize(_ reusableCellHolder: T) -> CGFloat {return UITableView.automaticDimension }
}
