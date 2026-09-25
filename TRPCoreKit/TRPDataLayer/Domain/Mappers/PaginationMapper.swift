//
//  PaginationMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 18.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class PaginationMapper {

    func map(_ restModel: Pagination) -> TRPPagination {
        switch restModel {
        case .completed:
            return TRPPagination.completed
        case .continues(let paginationJsonModel):
            let info = TRPPaginationInfo(
                total: paginationJsonModel.total,
                count: paginationJsonModel.count,
                perPage: paginationJsonModel.perPage,
                currentPage: paginationJsonModel.currentPage,
                totalPages: paginationJsonModel.totalPages
            )
            return TRPPagination.continues(info)
        }
    }
}
