//
//  MustTryTableViewViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation




public class MustTryTableViewViewModel: TableViewViewModelProtocol {
    
    public typealias T = TRPTaste
    
    public var cellViewModels: [TRPTaste] = []
    
    public var numberOfCells: Int {
        return cellViewModels.count
    }
    
    
    init(tastes: [TRPTaste]) {
        self.cellViewModels = tastes
    }
    
    
    public func getCellViewModel(at indexPath: IndexPath) -> TRPTaste {
        cellViewModels[indexPath.row]
    }
    
    
    public func getImageUrl(at indexPath: IndexPath, width: Int, height: Int) -> URL? {
        guard let imageUrl = getCellViewModel(at: indexPath).image?.url else {return nil}
        guard let link = TRPImageResizer.generate(withUrl: imageUrl, standart: .small), let url = URL(string: link) else {
            return nil
        }
        return url
    }
}
