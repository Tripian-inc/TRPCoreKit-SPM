//
//  BookingListViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation





final class BookingListViewModel: TableViewViewModelProtocol {
    
    typealias T = BookingCellModel
    public weak var delegate: ViewModelDelegate?
    private(set) var cellViewModels: [BookingCellModel] = []
    
    internal var numberOfCells: Int { return cellViewModels.count }
    
    
    //Use case
    public var observerReservationUseCase: ObserveReservationUseCase?
    public var deleteReservartionUseCase: DeleteReservationUseCase?
    public var updateReservationUseCase: UpdateReservationUseCase?
    
    public init() {}
    
    public func start() {
        addObservers()
    }
    
    
    func getCellViewModel(at indexPath: IndexPath) -> BookingCellModel {
        return cellViewModels[indexPath.row]
    }
    
    func getImageUrl(at indexPath: IndexPath, width: Int, height: Int) -> URL? {
        
        return getCellViewModel(at: indexPath).image
    }
    
    func getProvider(at indexPath: IndexPath) -> String? {
        getCellViewModel(at: indexPath).provider
    }
    
    func getTimeDate(at indexPath: IndexPath) -> String? {
        var timeDate: String = ""
        if let date = getCellViewModel(at: indexPath).date {
            timeDate += date
        }
        if let time = getCellViewModel(at: indexPath).time {
            timeDate += " "
            timeDate += time
        }
        return timeDate
    }
    
    
    /// Tek bir BookingIn durumunu kontrol eder
    /// - Parameter bookingId: Tripian Booking Id
    public func checkMyBookigStatus(bookingId: Int) {
        guard let bookings = observerReservationUseCase?.reservations.value else {return}
        
        if let bookingModel = bookings.first(where: {$0.id == bookingId}), let yelpModel = bookingModel.yelpModel {
            checkBooking(yelpReservationId: yelpModel.reservationID, tripianReservationId: bookingId)
        }
    }
    
    
    public func checkMyBookingsStatus() {
        guard let bookings = observerReservationUseCase?.reservations.value else {return}
        for (index, booking) in bookings.enumerated() {
            if let yelp = booking.yelpModel {
                DispatchQueue.global().asyncAfter(deadline: .now() + Double(index) * 0.2) {
                    self.checkBooking(yelpReservationId: yelp.reservationID, tripianReservationId: booking.id)
                }
            }
        }
    }
    
    func checkBooking(yelpReservationId id: String, tripianReservationId: Int) {
        YelpApi(isProduct: false).reservationStatus(reservationId: id) { [weak self] (result) in
            switch(result) {
            case .success(let model):
                
                //TODO: UPDATE USER RESERVATİON
                self?.updateUserReservation(yelpReservationId: id, yelpStatus: model)
                print("[INFO] CheckBooking \(model)")
            case .failure(let error):
                if let converted = error as? YelpNetworkError, converted == YelpNetworkError.reservationCanceled {
                    self?.deleteBookingInServer(bookingId: tripianReservationId)
                }
                
                print("[Error] CheckBookingError \(error.localizedDescription)")
            }
        }
    }
    
    private func updateUserReservation(yelpReservationId: String, yelpStatus: YelpStatus) {
        
        guard let reservations = observerReservationUseCase?.reservations.value else {return}
        guard let reservation = reservations.first(where: { reservation -> Bool in
            if let id = reservation.yelpModel?.reservationID {
                return id == yelpReservationId
            }
            return false
            
        }) else {return}
        
        guard  var yelp = reservation.yelpModel, yelp.reservationDetail != nil else {return}
        //TODO: kontrol yapılacak
        
        if !isYelpStatusChanged(detail: yelp.reservationDetail, status: yelpStatus) {return}
        
        yelp.reservationDetail?.date = yelpStatus.date
        yelp.reservationDetail?.covers = yelpStatus.covers
        yelp.reservationDetail?.time = yelpStatus.time
        delegate?.viewModel(showPreloader: true)
        
        updateReservationUseCase?.executeUpdateReservation(id: reservation.id,
                                                           key: reservation.key,
                                                           provider: reservation.provider,
                                                           tripHash: reservation.tripHash,
                                                           poiId: reservation.poiID,
                                                           values: yelp.getParams(),
                                                           completion: { [weak self] result in
                                                            self?.delegate?.viewModel(showPreloader: false)
                                                            self?.delegate?.viewModel(dataLoaded: false)
                                                            if case .failure(let error) = result {
                                                                self?.delegate?.viewModel(error: error)
                                                            }
                                                            
                                                           })
    }
    
    private func isYelpStatusChanged(detail: TRPYelpReservationDetail?, status: YelpStatus) -> Bool {
        guard let detail = detail else {return true}
        if detail.date != status.date || detail.time != status.time || detail.covers != status.covers {return true}
        return false
    }
    
    private func deleteBookingInServer(bookingId id: Int) {
        deleteReservartionUseCase?.executeDeleteReservation(id: id, completion: nil)
    }
    
    deinit {
        removeObservers()
    }
}


extension BookingListViewModel: ObserverProtocol {
    
    func addObservers() {
        delegate?.viewModel(showPreloader: true)
        observerReservationUseCase?.reservations.addObserver(self, observer: { [weak self] reservations in
            let yelp = reservations.compactMap { self?.convertForYelp($0) }
            let gyg = reservations.compactMap{ self?.convertForGYG($0) }
            self?.delegate?.viewModel(showPreloader: false)
            self?.cellViewModels.append(contentsOf: yelp)
            self?.cellViewModels.append(contentsOf: gyg)
            self?.delegate?.viewModel(dataLoaded: true)
            
        })
    }
    
    func removeObservers() {
        observerReservationUseCase?.reservations.removeObserver(self)
    }
    
    private func convertForYelp(_ items: TRPReservation) ->  BookingCellModel? {
        guard let yelpModel = items.yelpModel else {return nil}
        return BookingCellModel(reservation: items, yelp: yelpModel)
    }
    
    private func convertForGYG(_ item: TRPReservation) -> BookingCellModel? {
        guard let model = item.gygModel else {return nil}
        return BookingCellModel(reservation: item, gyg: model)
    }
}
