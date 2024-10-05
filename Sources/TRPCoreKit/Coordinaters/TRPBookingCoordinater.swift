//
//  TRPBookingCoordinater.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-31.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPDataLayer
import TRPProvider

final class TRPExperiencesCoordinater {
    
    enum ViewState {
        case experince, review(tourId: Int), experienceDetail, requiredParameter, billing, card
    }
    
    private let navigationController: UINavigationController
    private let cityName: String
    public var tripModeUseCases: TRPTripModeUseCases?
    private(set) var currentViewState: ViewState = .experince {
        didSet {
            self.applyViewState(self.currentViewState)
        }
    }
    private lazy var tourOptionsUseCases: TRPTourOptionsUseCases = {
       return TRPTourOptionsUseCases()
    }()
    
    private lazy var bookingUseCases: TRPMakeBookingUseCases = {
        let useCases = TRPMakeBookingUseCases()
        useCases.optionDataHolder = tourOptionsUseCases
        return useCases
    }()
    
    init(navigationController: UINavigationController, cityName: String) {
        self.navigationController = navigationController
        self.cityName = cityName
    }
    
    func start() {
        
    }
    
    
    
    private func applyViewState(_ state: ViewState) {
        var viewController: UIViewController?
        switch state {
        case .experince:
            viewController = makeExperience()
        case .review(let tourId):
            ()
        case .experienceDetail:
            ()
        case .requiredParameter:
            ()
        case .billing:
            ()
        case .card:
            ()
        }
        
        if let vc = viewController {
            navigationController.pushViewController(vc, animated: true)
        }
    }
    
}

//MARK: - Experiences VC
extension TRPExperiencesCoordinater: ExperiencesViewControllerDelegate {
    
    private func makeExperience() -> UIViewController? {
        let viewModel = ExperiencesViewModel(cityName: cityName)
        viewModel.tripModeUseCase = tripModeUseCases
        let viewController = ExperiencesViewController(viewModel: viewModel)
        viewModel.delegate = viewController
        viewController.delegate = self
        return viewController
    }
    
    func experiencesVCOpenTour(_ navigationController: UINavigationController?, viewController: UIViewController, tourId: Int) {
        
    }
}

extension TRPExperiencesCoordinater: ExperienceDetailViewControllerDelegate {
    
    private func makeExperienceDetail(tourId: Int) -> UIViewController {
        let viewModel = ExperienceDetailViewModel(tourId: tourId)
        let viewController = ExperienceDetailViewController(viewModel: viewModel)
        viewController.useCases = bookingUseCases
        viewModel.delegate = viewController
        viewController.delegate = self
        return viewController
    }
    
    func experienceDetailVCOpenReviews(_ navigationController: UINavigationController?, viewController: UIViewController, tourId: Int) {
        
    }
    
    func experienceDetailVCOpenAvailability(_ navigationController: UINavigationController?, viewController: UIViewController, tourId: Int) {
        
    }
    
    func experienceDetailVCOpenMoreInfo(_ navigationController: UINavigationController?, viewController: UIViewController, tour: GYGTour) {
        
    }
    
    private func makeReviewsView(tourId id: Int) -> UIViewController {
        let viewModel = ReviewsViewModel(tourId: id)
        let viewController = ReviewsViewController(viewModel: viewModel)
        viewModel.delegate = viewController
        return viewController
    }
}
