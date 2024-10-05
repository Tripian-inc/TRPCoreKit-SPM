//
//  YelpCoordinater.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 13.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

import UIKit
public protocol YelpCoordinaterDelegate: AnyObject {
    func yelpCoordinaterReservationCompleted(_ viewController: UIViewController, reservation: Reservation, business: YelpBusiness?, result: YelpReservation)
}


public class YelpCoordinater {
    
    public var isProduct = false
    public var testBusinessId = "rC5mIHMNF5C1Jtpb2obSkA"
    private(set) var navigationController: UINavigationController
    private var reservationViewController: ReservationViewController?
    private(set) var reservation: Reservation
    private(set) var hold: YelpHolds?
    public weak var delegate: YelpCoordinaterDelegate?
    public var yelpBusiness: YelpBusiness?
    
    
    public init(navigationController: UINavigationController,  reservation: Reservation) {
        self.navigationController = navigationController
        self.reservation = reservation
    }
    
    public func start() {
        if isProduct == false {
            reservation.businessId = testBusinessId
        }
        openReservationVC()
    }
}

//MARK: - RESERVATİON
extension YelpCoordinater: ReservationViewControllerDelegate {
    
    private func openReservationVC() {
        let viewModel = ReservationViewModel(reservation: reservation)
        viewModel.isYelpApiProduct = isProduct
        reservationViewController = ReservationViewController(viewModel: viewModel)
        reservationViewController!.delegate = self
        viewModel.delegate = reservationViewController!
        viewModel.start()
        navigationController.pushViewController(reservationViewController!, animated: true)
    }
    
    
    public func reservationViewController(reservation: Reservation, hold: YelpHolds, business: YelpBusiness?) {
        self.reservation = reservation
        self.hold = hold
        self.yelpBusiness = business
        openUserInfoVC(reservation: reservation)
    }
}

//MARK: - USERINFO
extension YelpCoordinater: ReservationUserInfoViewControllerDelegate {
    
    private func openUserInfoVC(reservation: Reservation) {
        let viewModel = ReservationUserInfoViewModel(reservation: reservation)
        let viewController = ReservationUserInfoViewController(viewModel: viewModel)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    public func reservationUserInfoCompleted(_ viewController: UIViewController, reservation: Reservation, result: YelpReservation) {
        delegate?.yelpCoordinaterReservationCompleted(viewController, reservation: reservation, business: yelpBusiness, result: result)
    }
    
}


//MARK: - SUCCESS
extension YelpCoordinater {
    
}
