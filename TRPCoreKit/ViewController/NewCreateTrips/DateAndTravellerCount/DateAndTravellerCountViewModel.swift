//
//  DateAndTravellerCountViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 19.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit




struct DateAndTravellerModel {
    var title: String
    var contentType: DateAndTravellerCountViewModel.CellContentType
}

protocol DateAndTravellerCountViewModelDelegate: ViewModelDelegate {
    func dateAndTravellerCountVMDepartureDate(day: Date?, hour:String?)
    func dateAndTravellerCountVMTravelCompanionsNotEqual()
}


class DateAndTravellerCountViewModel: TableViewViewModelProtocol {
    
    public typealias DatePickerModel = (minimumDate: Date, maximumDate: Date? , selectedDate: Date)
    
    enum CellContentType {
        case departure, arrival, adultCount, childCount, travelCompanion, hotelAdress, userAge
    }
    
    typealias T = DateAndTravellerModel
    weak var delegate: DateAndTravellerCountViewModelDelegate?
    
    
    public func getMainTitle() -> String {
        return TRPLanguagesController.shared.getLanguageValue(for: "trips.toursAndTickets.dates")
    }
    
    public func getCurrentStep() -> String {
        return "2"
    }
    
    //** Data Holder
    //Arrival date in tutulduğu değer
    private var selectedArrivalDate: Date = (Date().localDate().addDay(1)?.setHour(for: "09:00"))!
    //Departure date in tutulduğu değer
    private var selectedDepartureDate: Date = (Date().localDate().addDay(2)?.setHour(for: "21:00"))!
    private var selectedArrivalHour = "09:00"
    private var selectedDepartureHour = "21:00"
    private var selectedTravelCompanions: [TRPCompanion]? {
        didSet {
            checkTravelCompanionsEqualty()
        }
    }
    private var stayAddress: TRPAccommodation?
    private var isShowCompanionWarning = false
    private var maxTripDays: Int = 13
    //*** UI
    //Arrival date in Uı için hazırladığı değer. Üzerinde işlem yapılmaz, UI sadece okur.
    public var arrivalDate: DatePickerModel {
        return (minimumDate: Date().localDate(),
                maximumDate: nil,
                selectedDate: selectedArrivalDate.setHour(for: selectedArrivalHour)!)
    }
    //Departure date in Uı için hazırladığı değer. Üzerinde işlem yapılmaz, UI sadece okur. Veriler arrival date e bağımlıdır.
    public var departureDate: DatePickerModel {
        return (minimumDate: selectedArrivalDate,
                maximumDate: selectedArrivalDate.addDay(maxTripDays)!,
                selectedDate: selectedDepartureDate)
    }
    private(set) var adultCount = 1
    private(set) var childCount = 0
    private(set) var travelCompanionsNames: String?
    private(set) var askUserAge = false
    public var userAge: Int?
    public var addressName: String? {
        return stayAddress?.name
    }
    var numberOfCells: Int { return cellViewModels.count }
    var cellViewModels: [DateAndTravellerModel] = []
    private var tripProfile: TRPTripProfile
    private var oldTripProfile: TRPTripProfile?
     
    //USE CASES
    public var fetchCompanionUseCase: FetchCompanionUseCase?
    public var observeCompanionUseCases: ObserveCompanionUseCase?
    
    
    
    
    init(tripProfile: TRPTripProfile, oldTripProfile: TRPTripProfile? = nil, askUserAge: Bool = false, maxTripDays: Int = 13) {
        self.tripProfile = tripProfile
        self.oldTripProfile = oldTripProfile
        self.askUserAge = askUserAge
        self.maxTripDays = maxTripDays
        implementTripProfile(oldTripProfile)
        cellViewModels = createData()
    }
    
    func start() {
        observeCompanionUseCases?.values.addObserver(self, observer: { [weak self] companions in
            if let profile = self?.oldTripProfile {
                var selectedCompanions = [TRPCompanion]()
                for id in profile.companionIds {
                    if let companion = companions.first(where: {$0.id == id}) {
                        selectedCompanions.append(companion)
                    }
                }
                if !selectedCompanions.isEmpty {
                    self?.addTravellerCompanions(selectedCompanions)
                }
            }
        })
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> DateAndTravellerModel {
        return cellViewModels[indexPath.row]
    }
    
    private func createData() -> [DateAndTravellerModel]{
        var cells = [DateAndTravellerModel]()
        let arrivalDate = DateAndTravellerModel(title: "Arrival date", contentType: .arrival)
        let departureDate = DateAndTravellerModel(title: "Departure date", contentType: .departure)
        let adultCount = DateAndTravellerModel(title: "Adult", contentType: .adultCount)
        let howOldAreYou = DateAndTravellerModel(title: "How old are you?", contentType: .userAge)
        let travelCompanion = DateAndTravellerModel(title: "Who are you traveling with?", contentType: .travelCompanion)
        let stayAddress = DateAndTravellerModel(title: "Where will you stay?", contentType: .hotelAdress)
        cells.append(arrivalDate)
        cells.append(departureDate)
        cells.append(adultCount)
        if askUserAge {
            cells.append(howOldAreYou)
        }
        cells.append(travelCompanion)
        cells.append(stayAddress)
        return cells
    }
    
}

//MARK: - Arrival/Departure Datetime
extension DateAndTravellerCountViewModel {
    
    private func departureMaximumController() {
        guard let maximumDate = departureDate.maximumDate else {return}
        if selectedDepartureDate > maximumDate {
            selectedDepartureDate = maximumDate.setHour(for: selectedDepartureHour)!
        }
    }
    
    private func departureMinimumController() {
        let minimumDate = departureDate.minimumDate
        if selectedDepartureDate < minimumDate {
            selectedDepartureDate = (arrivalDate.selectedDate.addDay(1)?.setHour(for: selectedDepartureHour))!
        }
    }
    
    
    public func changeArrivalDate(_ day: Date, hours: String?) {
        if let hour = hours {
            selectedArrivalHour = hour
        }
        selectedArrivalDate = day.setHour(for: selectedArrivalHour)!
        departureMaximumController()
        departureMinimumController()
    }
    
    public func changeDepartureDate(_ day: Date, hours: String?) {
        if let hour = hours {
            selectedDepartureHour = hour
        }
        selectedDepartureDate = day.setHour(for: selectedDepartureHour)!
    }
    
    
    
    public func addStayAddress(_ address: TRPAccommodation?) {
        stayAddress = address
        delegate?.viewModel(dataLoaded: true)
    }
    
}

//MARK: - Travaler Count
extension DateAndTravellerCountViewModel {
    
    public func getTravelerTFText() -> String {
        let adultText = getAdultTravelerCountText()
        let childText = getChildTravelerCountText()
        
        return "\(adultText), \(childText)"
    }
    
    private func getAdultTravelerCountText() -> String {
        if self.adultCount == 0 {
            return "No adult"
        }
        if self.adultCount == 1 {
            return "1 adult"
        }
        return "\(self.adultCount) adults"
    }
    
    private func getChildTravelerCountText() -> String {
        if self.childCount == 0 {
            return "No children"
        }
        if self.childCount == 1 {
            return "1 child"
        }
        return "\(self.childCount) children"
    }
    
    public func setTravelersCount(adult: Int, child: Int) {
        self.adultCount = adult
        self.childCount = child
        delegate?.viewModel(dataLoaded: true)
    }
    
    public func setAdultCount(_ value: Int) {
        self.adultCount = value
    }
    
    public func setChildCount(_ value: Int) {
        self.childCount = value
    }
}

//MARK: - Companion
extension DateAndTravellerCountViewModel {
    
    public func addTravellerCompanions(_ selectedCompanion: [TRPCompanion]) {
        selectedTravelCompanions = selectedCompanion
        travelCompanionsNames = selectedCompanion.map({$0.name}).toString(", ")
        delegate?.viewModel(dataLoaded: true)
    }
    
    private func checkTravelCompanionsEqualty() {
        guard let companionCount = selectedTravelCompanions?.count else {return}
        let peopleCount = adultCount + childCount + 1
        if peopleCount < companionCount {
            if !isShowCompanionWarning {
                isShowCompanionWarning.toggle()
                delegate?.dateAndTravellerCountVMTravelCompanionsNotEqual()
            }
        }
    }
}


//MARK: - EDIT TRIP
extension DateAndTravellerCountViewModel {
    
    private func implementTripProfile(_ tripProfile: TRPTripProfile?) {
        
        guard let profile = tripProfile else {return}
        
        if let arrival = profile.arrivalDate?.toDate {
            let hour = arrival.toString(format: "HH:mm", dateStyle: nil, timeStyle: nil)
            if !hour.isEmpty{
                selectedArrivalHour = hour
            }
                        
            self.selectedArrivalDate = arrival
        }
        
        if let departure = profile.departureDate?.toDate {
            let hour = departure.toString(format: "HH:mm", dateStyle: nil, timeStyle: nil)
            if  !hour.isEmpty{
                selectedDepartureHour = hour
            }
            
            self.selectedDepartureDate = departure
        }
        
        self.childCount = profile.numberOfChildren
        self.adultCount = profile.numberOfAdults
        
        if let accommondation = profile.accommodation {
            stayAddress = accommondation
        }
    }
    
}



//MARK: - Prepatere trip
extension DateAndTravellerCountViewModel {
    
    public func setTripProperties() {
    
        guard let arrivalDateWithHour = selectedArrivalDate.setHour(for: selectedArrivalHour),
            let departureDateWithHour = selectedDepartureDate.setHour(for: selectedDepartureHour) else {return}
        
        tripProfile.arrivalDate = TRPTime(date: arrivalDateWithHour)
        tripProfile.departureDate = TRPTime(date: departureDateWithHour)
        tripProfile.numberOfAdults = adultCount
        tripProfile.numberOfChildren = childCount
        
        if let companions = selectedTravelCompanions {
            tripProfile.companionIds = companions.map{$0.id}
        }
        
        if let stayAddress = stayAddress {
            
            tripProfile.accommodation = TRPAccommodation(name: stayAddress.name,
                                                           referanceId: stayAddress.referanceId,
                                                           address: stayAddress.address,
                                                           coordinate: stayAddress.coordinate)
        }else {
            tripProfile.accommodation = nil
        }
    }
    
    
//    private func addHourInDate(day: Date, hours: String?) -> Date? {
//        guard let hours = hours else {return nil}
//        guard let convertedHour = hourToInt(hours) else {return day}
//
//        return day.setHour(convertedHour.hour, minutes: convertedHour.minute)
//    }
    
    private func hourToInt(_ hour: String) -> (hour: Int, minute: Int)? {
        let hourMinutes = hour.split(separator: ":")
        guard hourMinutes.count == 2 else {return nil}
        guard let _hours = Int(hourMinutes[0]), let _min = Int(hourMinutes[1]) else {return nil}
        return (_hours, _min)
    }
}
