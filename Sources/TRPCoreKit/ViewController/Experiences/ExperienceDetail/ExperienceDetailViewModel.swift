//
//  ExperienceDetailViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 17.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPProvider
enum ExperienceDetailCellType: String {
    case titleAndReview = "Title"
    case price = "Price"
    case description = "Description"
    case abstract = " "
    case duration = "Duration"
    case highlights = "Highlights"
    case whatIsIncluded = "What's included"
    case whatIsExcluded = "What's not included"
    case cancellationPolicy = "Cancellation Policy"
    
    case header = "Header"
    case reviews = "Reviews"
    case subTitleText = "SubTitleText"
    case dot = "Dot"
    case readAllReview = "Read All Reviews"
    case moreInfo = "Read More Info"
    case imageGallery = "Image Gallery"
    
}

public struct ExperienceDetailTitleCellModel {
    var title: String
    var starCount: Double?
    var ratingCount: Int?
}

public struct ExperienceHeaderCellModel {
    var showSeperater: Bool
    var header: String
    
    init(header: String, seperater: Bool = true) {
        self.header = header
        self.showSeperater = seperater
    }
}

public struct ExperienceSubTitleText {
    var title: String
    var content: String
}

public struct ExperienceDetailCellModel {
    var type: ExperienceDetailCellType
    var data: Any
}

public protocol ExperienceDetailViewModelDelegate: ViewModelDelegate {
    
}

public class ExperienceDetailViewModel: TableViewViewModelProtocol {
    
    public typealias T = ExperienceDetailCellModel
    
    public weak var delegate: ExperienceDetailViewModelDelegate?
    public var cellViewModels: [ExperienceDetailCellModel] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    private(set) var tour: GYGTour?
    private var reviews: [GYGReview] = []
    private(set) var tourId: Int
    private let reviewsLimit = 3
    public var numberOfCells: Int { return cellViewModels.count }
    private var isFromTripDetail = false
    
    public init(tourId: Int, isFromTripDetail: Bool) {
        self.tourId = tourId
        self.isFromTripDetail = isFromTripDetail
    }
    
    func start() {
        fetchTourData()
    }
    
    
    public func getCellViewModel(at indexPath: IndexPath) -> ExperienceDetailCellModel {
        return cellViewModels[indexPath.row]
    }
    
//    public func getGallery() -> [String] {
//        return tour?.pictures.map({$0.url.replacingOccurrences(of: "[format_id]", with: "21")}) ?? []
//    }
    
    public func getPrice() -> GYGPrice? {
        return tour?.price
    }
    
    public func isFromTrip() -> Bool {
        return isFromTripDetail
    }
}

extension ExperienceDetailViewModel {
    
    private func fetchTourData() {
        GetYourGuideApi().tour(id: tourId) { [weak self] result in
            guard let strongSelf = self else {return}
            switch result {
            case .success(let tour):
                strongSelf.tour = tour
                strongSelf.cellViewModels = strongSelf.tourToCellModel(tour: tour)
                strongSelf.fetchReviews()
            case .failure(let error):
                strongSelf.delegate?.viewModel(error: error)
            }
        }
    }
    
    private func tourToCellModel(tour: GYGTour) -> [ExperienceDetailCellModel]{
        var cells = [ExperienceDetailCellModel]()
        
//        let titleModel = ExperienceDetailTitleCellModel(title: tour.title,
//                                                        starCount: tour.overallRating,
//                                                        ratingCount: tour.numberOfRatings)
//        cells.append(.init(type: .imageGallery, data: getGallery()))
        
//        cells.append(.init(type: .titleAndReview, data: titleModel))
        
        //GENERAL
        cells.append(.init(type: .header, data: ExperienceHeaderCellModel(header: "About this activity", seperater: false)))
        
        
        if let durations = tour.durations {
            let wrappedDurations = durations.compactMap { duration -> String? in
                if let time = duration.duration, let unit = duration.unit {
                    return "\(time.clean) \(unit)"
                }
                return nil
            }
            cells.append(.init(type: .subTitleText, data: ExperienceSubTitleText(title: "Duration", content: wrappedDurations.toString(" - "))))
        }
        
//        let readableLanguages = tour.condLanguage.compactMap{ readableLanguage(code: $0) }
//        if readableLanguages.count > 0 {
//            cells.append(.init(type: .subTitleText, data: ExperienceSubTitleText(title: "Live tour guide", content: readableLanguages.toString(", "))))
//        }
        
        if let cancellation = tour.cancellationText {
            cells.append(.init(type: .subTitleText, data: ExperienceSubTitleText(title: "Cancellation", content: cancellation)))
        }
        
        //DETAIL
        cells.append(.init(type: .header, data: ExperienceHeaderCellModel(header: "Detail & highlights")))
        cells.append(.init(type: .abstract, data: tour.abstract))
        if let highlights = tour.highlights {
            highlights.forEach { content in
                cells.append(.init(type: .dot, data: content))
            }
        }
        if let inclusion = tour.inclusions {
            cells.append(.init(type: .whatIsIncluded, data: inclusion))
        }
        
        if let exclusion = tour.exclusions {
            cells.append(.init(type: .whatIsExcluded, data: exclusion))
        }
        
        cells.append(.init(type: .moreInfo, data: ""))
        
        return cells
    }
    
    
    
    private func readableLanguage(code: String) -> String? {
        let locale = NSLocale(localeIdentifier: "en")
        return locale.displayName(forKey: NSLocale.Key.identifier, value: code)
    }
    
}


//MARK: - Reviews
extension ExperienceDetailViewModel {
    
    private func fetchReviews() {
        GetYourGuideApi().reviews(tourId: tourId) { [weak self] result in
            guard let strongSelf = self else {return}
            switch result {
            case .success(let reviews):
                
                let filtered = strongSelf.filterReviews(reviews.reviewItems)
                
                if filtered.count > 0 {
                    strongSelf.cellViewModels.append(.init(type: .header, data: ExperienceHeaderCellModel(header: "Reviews")))
                    filtered.forEach { reviewItem in
                        strongSelf.cellViewModels.append(.init(type: .reviews, data: reviewItem))
                    }
                    
                    strongSelf.reviews = filtered
                    if reviews.reviewItems.count > 3 {
                        strongSelf.cellViewModels.append(.init(type: .readAllReview, data: "Read All Reviews"))
                    }
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func filterReviews(_ data: [GYGReview]) -> [GYGReview] {
        let filtered = data.filter { (review) -> Bool in
            if review.comment != nil && review.comment!.count > 1 {
                return true
            }
            return false
        }
        
        if filtered.count > reviewsLimit {
            return Array(filtered[0..<reviewsLimit])
        }
        return filtered
    }
}
