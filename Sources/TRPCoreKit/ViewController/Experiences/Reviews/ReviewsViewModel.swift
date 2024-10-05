//
//  ReviewsViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 24.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPProvider
public enum ReviewSorting {
    case newestFirst, highestRated, lowestRated
}
public class ReviewsViewModel: TableViewViewModelProtocol {
    
    public typealias T = GYGReview
    public weak var delegate: ViewModelDelegate?
    public var cellViewModels: [GYGReview] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    public var numberOfCells: Int { return cellViewModels.count }
    private var tourId: Int
    
    
    public init(tourId: Int) {
        self.tourId = tourId
    }
    
    public func start() {
        fetchReviews()
    }
    
    public func getCellViewModel(at indexPath: IndexPath) -> GYGReview {
        return cellViewModels[indexPath.row]
    }
    
    
    public func fetchDataWithSort(_ sortBy: ReviewSorting) {
        switch sortBy {
        case .highestRated:
            fetchReviews(sort: .desc)
        case .lowestRated:
            fetchReviews(sort: .asc)
        case .newestFirst:
            fetchReviews(sort: nil)
        }
    }
    
}
 
extension ReviewsViewModel {
    
    private func fetchReviews(sort: GYGSortDirection? = nil) {
        delegate?.viewModel(showPreloader: true)
        let sortField: GYGSortField? = sort != nil ? GYGSortField.rating : nil
        let sortDirection: GYGSortDirection? = sort
        GetYourGuideApi().reviews(tourId: tourId, sortfield: sortField, sortDirection: sortDirection, limit: 50) { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let reviews):
                strongSelf.cellViewModels = reviews.reviewItems
            case .failure(let error):
                strongSelf.delegate?.viewModel(error: error)
            }
        }
    }
    
}
