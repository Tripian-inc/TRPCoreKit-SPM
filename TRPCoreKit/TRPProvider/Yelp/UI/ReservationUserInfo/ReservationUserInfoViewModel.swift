//
//  ReservationUserInfoViewModel.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 8.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

struct ReservationUserInfoCellModel {
    var title: String
    var contentType: ReservationUserInfoViewModel.CellContentType
}

public protocol ReservationUserInfoViewModelDelegate:AnyObject {
    func reservationUserInfoViewModel(showLoader: Bool)
    func reservationUserInfoViewModel(error: Error)
    func reservationUserInfoViewModel(message: String)
    func reservationUserInfoViewModelCompleted(reservation: Reservation, result: YelpReservation)
}

public class ReservationUserInfoViewModel {
    
    enum CellContentType {
        case userName, lastName, email, phone
    }
    
    weak var delegate: ReservationUserInfoViewModelDelegate?
    
    //Data of UI
    var numberOfCells: Int { return cellViewModels.count }
    var cellViewModels: [ReservationUserInfoCellModel] = []
    var userName: String? {
        didSet {
            reservation?.firstName = userName
        }
    }
    var lastName: String? {
        didSet {
            reservation?.lastName = lastName
        }
    }
    var email: String? {
        didSet {
            reservation?.email = email
        }
    }
    var phone: String? {
        didSet {
            reservation?.phone = phone
        }
    }
    private(set) var reservation: Reservation?
    
    public init(reservation: Reservation) {
        self.reservation = reservation
        self.userName = reservation.firstName
        self.lastName = reservation.lastName
        self.email = reservation.email
        self.phone = reservation.phone
    }
   
    
    public func start() {
        createData()
    }
    
    private func createData() {
        var cells = [ReservationUserInfoCellModel]()
        cells.append(.init(title: "Name", contentType: .userName))
        cells.append(.init(title: "Last Name", contentType: .lastName))
        cells.append(.init(title: "Email", contentType: .email))
        cells.append(.init(title: "Phone", contentType: .phone))
        cellViewModels = cells
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ReservationUserInfoCellModel {
        return cellViewModels[indexPath.row]
    }
    
    private func isValuesValid() -> Bool {
        if !isValueValid(userName) {
            showError("First name can`t be empty")
            return false
        }
        
        if !isValueValid(lastName) {
            showError("Last name can`t be empty")
            return false
        }
        
        if !isValueValid(email) {
            showError("Email name can`t be empty")
            return false
        }else if let mail = email, !mail.isValidEmail{
            showError("Email format is not valid")
            return false
        }
        
        if !isValueValid(phone) {
            showError("Mobile number can`t be empty")
            return false
        }
        return true
    }
    
    private func isValueValid(_ value: String?) -> Bool{
        guard let value = value else {return false}
        return !value.isEmpty
    }
    
    private func showError(_ message: String) {
        delegate?.reservationUserInfoViewModel(message: message)
    }
    
    func makeAReservation() {
        if !isValuesValid() {return}
        guard let reservation = reservation else {return}
        delegate?.reservationUserInfoViewModel(showLoader: true)
        YelpApi(isProduct: false).reservations(reservation: reservation) {[weak self] (result) in
            self?.delegate?.reservationUserInfoViewModel(showLoader: false)
            switch(result) {
            case .success(let yelpModel):
                self?.delegate?.reservationUserInfoViewModelCompleted(reservation: reservation, result: yelpModel)
            case .failure(let error):
                self?.delegate?.reservationUserInfoViewModel(error: error)
            }
        }
    }
    
}
