//
//  TRPBaseCoordinatorProtocol.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.11.2025.
//

import Foundation
import UIKit


protocol TRPBaseCoordinatorProtocol: AnyObject {
    func openMenu()
    func showCreateTrip()
    func showDateRangeSelection(preselected: (Date, Date)?, maxDays: Int, viewController: UIViewController)
    func showDateSelection(preselected: Date?, viewController: UIViewController)
    func showStartEndTimeSelection(startTime: String?, endTime: String?, viewController: UIViewController)
    func showCityDestinationSelection(viewController: UIViewController)
    func showCreateTripWithActivity(_ model: TRPCreateTimelineFromActivityModel)
    func showSelectAddressVC(_ viewController: UIViewController, city: TRPCity)
}
