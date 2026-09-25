//
//  ItineraryStepPoiDetailViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit

enum ItineraryStepPoiDetailCellType {
    case galleryTitle
    case description
    case openCloseHour
    case phone
    case address
    case map
    case activities
}

struct ItineraryStepPoiDetailCellContent {
    var data: Any?
    var type: ItineraryStepPoiDetailCellType
}

protocol ItineraryStepPoiDetailViewModelDelegate: ViewModelDelegate {
}

final class ItineraryStepPoiDetailViewModel: TableViewViewModelProtocol {
    
    typealias T = ItineraryStepPoiDetailCellContent
    
    public var step: TRPStep
    public weak var delegate: ItineraryStepPoiDetailViewModelDelegate?
    public var numberOfCells: Int { return cellViewModels.count }
    public var cellViewModels: [ItineraryStepPoiDetailCellContent] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    public init(step: TRPStep) {
        self.step = step
    }

    public convenience init?(timelineStep: TRPTimelineStep) {
        guard let poi = timelineStep.poi else {
            return nil
        }

        let planId: Int?
        if let planIdString = timelineStep.planId, let convertedId = Int(planIdString) {
            planId = convertedId
        } else {
            planId = nil
        }

        let step = TRPStep(
            id: timelineStep.id,
            planId: planId,
            poi: poi,
            order: timelineStep.order,
            score: Float(timelineStep.score ?? 0.0),
            times: nil,
            alternatives: timelineStep.alternatives ?? []
        )

        self.init(step: step)
    }
    
    public func start() {
        createCellData()
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ItineraryStepPoiDetailCellContent {
        return cellViewModels[indexPath.row]
    }
    
    public func getImageGallery() -> [PagingImage] {
        guard let gallery = step.poi.gallery else { return [] }
        return gallery.compactMap { image -> PagingImage? in
            guard let converted = self.getPlaceImage(url: image?.url ?? "") else { return nil }
            return PagingImage(imageUrl: converted, picOwner: image?.imageOwner)
        }
    }
    
    public func getPlaceImage(url: String) -> String? {
        return TRPImageResizer.generate(withUrl: url, standart: .placeDetail)
    }
}

// MARK: - PREPARE DATA
extension ItineraryStepPoiDetailViewModel {
    
    private func createCellData() {
        var tempCells = [ItineraryStepPoiDetailCellContent]()
        let poi = step.poi
        
        var gallery: [PagingImage] = []
        if let placeGallery = poi.gallery, !placeGallery.isEmpty {
            gallery = placeGallery.compactMap { image -> PagingImage? in
                guard let converted = self.getPlaceImage(url: image?.url ?? "") else { return nil }
                return PagingImage(imageUrl: converted, picOwner: image?.imageOwner)
            }
        }
        
        let titleCell = PoiImageWithTitleModel(
            gallery: gallery,
            title: poi.name,
            sdkModeType: .Trip,
            globalRating: showRating(),
            starCount: starCount(),
            reviewCount: poi.ratingCount ?? 0,
            price: poi.price ?? 0,
            explainText: nil
        )
        let titleCellModel = ItineraryStepPoiDetailCellContent(data: titleCell, type: .galleryTitle)
        tempCells.append(titleCellModel)

        if let description = poi.description, !description.isEmpty {
            let data = PoiDetailBasicCellModel(icon: "icon_attraction", content: description)
            let cellModel = ItineraryStepPoiDetailCellContent(data: data, type: .description)
            tempCells.append(cellModel)
        }

        if let hours = poi.hours, !hours.isEmpty {
            let data = PoiDetailBasicCellModel(icon: "icon_clock", content: hours)
            let cellModel = ItineraryStepPoiDetailCellContent(data: data, type: .openCloseHour)
            tempCells.append(cellModel)
        }

        if let phone = poi.phone {
            let data = PoiDetailBasicCellModel(icon: "icon_phone", content: phone)
            let cellModel = ItineraryStepPoiDetailCellContent(data: data, type: .phone)
            tempCells.append(cellModel)
        }

        if let address = poi.address {
            let data = PoiDetailBasicCellModel(icon: "icon_location", content: address)
            let cellModel = ItineraryStepPoiDetailCellContent(data: data, type: .address)
            tempCells.append(cellModel)
        }

        if let coordinate = poi.coordinate {
            let mapModel = ItineraryStepPoiDetailCellContent(data: coordinate, type: .map)
            tempCells.append(mapModel)
        }

        print("📱 [ItineraryStepPoiDetailViewModel] Created \(tempCells.count) cells for POI: \(poi.name)")
        cellViewModels = tempCells
    }
    
    private func showRating() -> Bool {
        return step.poi.isRatingAvailable()
    }
    
    private func starCount() -> Int {
        guard let rating = step.poi.rating else { return 0 }
        return Int(rating.rounded())
    }
}

