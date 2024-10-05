//
//  MyTripTableViewViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 16.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation




public struct TripCellModel {
    public var id:Int
    public var date: String
    public var hash: String
    public var tripName: String
    public var cityModel: TRPCity
    public var arrivalDate:String
    public var departureDate:String
    public var startDate:String
    
    public var profile: TRPTripProfile
}

public protocol MyTripTableViewDelegate: ViewModelDelegate {
    func viewModelRemovedTrip(id:Int, status: Bool)
}

public class MyTripTableViewViewModel: TableViewViewModelProtocol {
    
    public typealias T = TripCellModel
    public var cellViewModels: [TripCellModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.viewModel(dataLoaded: true)
            }
        }
    }
    
    private let timeType: MyTripType
    public weak var delegate: MyTripTableViewDelegate?
    public var fetchUpcomingTripUseCase: FetchUserUpcomingTripUseCase?
    public var fetchPastTripUseCase: FetchUserPastTripUseCase?
    public var deleteTripUseCase: DeleteUserTripUseCase?
    public var observeUpcomingTripUseCase: ObserveUserUpcomingTripsUseCase?
    public var observePastTripUseCase: ObserveUserPastTripsUseCase?
    
    public var numberOfCells: Int { return cellViewModels.count }
    
    public init(timeType: MyTripType) {
        self.timeType = timeType
    }
    
    public func start() {
        
        addObservers()
        
        if timeType == .upcomingTrip {
            fetchUpcomingTripUseCase?.executeUpcomingTrip(completion: tripResult(_:))
        }else {
            fetchPastTripUseCase?.executePastTrip(completion: tripResult(_:))
        }
        
    }
    
    private func tripResult(_ result: Result<[TRPUserTrip], Error>) {
        if case .failure(let error) = result {
            self.delegate?.viewModel(error: error)
        }
    }
    
    public func getCellViewModel(at indexPath: IndexPath) -> TripCellModel {
        return cellViewModels[indexPath.row]
    }
    
    public func getTripIndex(id:Int) -> Int? {
        for i in 0..<numberOfCells {
            if cellViewModels[i].id == id {
                return i
            }
        }
        return nil
    }
    
    public func getType() -> MyTripType {
        return timeType
    }
    
    public func getImageUrl(at indexPath: IndexPath, width: Int, height: Int) -> URL? {
        let link = getCellViewModel(at: indexPath).cityModel.image
        guard let mlink = TRPImageResizer.generate(withUrl: link, standart: .myTrip, type: "Places") else { return nil }
        if let url = URL(string: mlink) {
            return url
        }
        return nil
    }
    
    public func removeTrip(tripHash: String) {
        delegate?.viewModel(showPreloader: true)
        deleteTripUseCase?.executeDeleteTrip(tripHash: tripHash, completion: { [weak self] result in
            switch result {
            case .success(_):
                self?.delegate?.viewModel(showPreloader: false)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
                print("Trip Error \(error.localizedDescription)")
            }
        })
    }
    
    public func reFetchData() {
        if timeType == .upcomingTrip {
            fetchUpcomingTripUseCase?.executeUpcomingTrip(completion: tripResult(_:))
        }else {
            fetchPastTripUseCase?.executePastTrip(completion: tripResult(_:))
        }
    }
    
    private var currentDate: String {
        return Date().toString(format: "YYYY-MM-dd")
    }
    
    deinit {
        removeObservers()
        Log.deInitialize()
    }
}

extension MyTripTableViewViewModel: ObserverProtocol {
    
    func addObservers() {
        if timeType == .upcomingTrip {
            observeUpcomingTripUseCase?.upcomingTrips.addObserver(self, getDefaultValues: false, observer: { [weak self](trips) in
                let converted = trips.compactMap { self?.cellModelMapper($0) }
                self?.cellViewModels = converted
            })
        }else {
            observePastTripUseCase?.pastTrips.addObserver(self, getDefaultValues: false, observer: { [weak self](trips) in
                let converted = trips.compactMap { self?.cellModelMapper($0) }
                self?.cellViewModels = converted
            })
        }
    }
    
    func removeObservers() {
        observePastTripUseCase?.pastTrips.removeObserver(self)
        observeUpcomingTripUseCase?.upcomingTrips.removeObserver(self)
    }
    
    
}




extension MyTripTableViewViewModel {
    
    private func cellModelMapper(_ ref: TRPUserTrip) -> TripCellModel {
        
        var departureDate = ""
        var arrivalDate = ""
        var startDate = ""
        var dayCount = 0
        
        if let wrappedDeparture = ref.tripProfile.departureDate, let departureTime = wrappedDeparture.toDate, let wrappedArrival = ref.tripProfile.arrivalDate, let arrivalTime = wrappedArrival.toDate {
            departureDate = departureTime.toString(dateStyle: DateFormatter.Style.medium)
            arrivalDate = arrivalTime.toString(dateStyle: DateFormatter.Style.medium)
            startDate = arrivalTime.toString(format: "dd.MM")
            dayCount = arrivalTime.numberOfDaysBetween(departureTime)
        }
        
        let daysString = dayCount > 1 ? TRPLanguagesController.shared.getLanguageValue(for: "trips.days") : TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.day")
        
        let tripName = "\(dayCount) \(daysString) \(ref.city.name)"
        
        return TripCellModel(id: ref.id,
                             date: "\(arrivalDate) - \(departureDate)",
                             hash: ref.tripHash,
                             tripName: tripName,
                             cityModel: ref.city,
                             arrivalDate: arrivalDate,
                             departureDate: departureDate,
                             startDate: startDate,
                             profile: ref.tripProfile)
    }
}
