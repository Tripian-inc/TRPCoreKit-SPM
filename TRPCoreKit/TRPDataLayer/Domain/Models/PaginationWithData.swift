//
//  PaginationWithData.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 18.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public class DataWithPagination<T> {
    
    var data: T
    var pagination: TRPPagination?
    
    init(data: T, pagination: TRPPagination? = nil) {
        self.data = data
        self.pagination = pagination
    }
}
