//
//  CreateTripTripInformationViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation





protocol CreateTripTripInformationViewModelDelegate: ViewModelDelegate {
}

class CreateTripTripInformationViewModel {
    var sectionModels: [CreateTripTripInformationSectionModel] = []
    
    weak var delegate: CreateTripTripInformationViewModelDelegate?
    
    private var tripProfile: TRPTripProfile
    private var oldTripProfile: TRPTripProfile?
    private var maxTripDays: Int = 3
    
    //Arrival date in tutulduğu değer
    private var selectedArrivalDate: Date = (Date().addDay(1)?.setHour(for: "00:00"))!
    //Departure date in tutulduğu değer
    private var selectedDepartureDate: Date = (Date().addDay(1)?.setHour(for: "00:00"))!
    private var selectedArrivalHour = "09:00"
    private var selectedDepartureHour = "21:00"
    private var selectedCity: TRPCity?
    public var isEditing: Bool = false
    
    private final let times: [String] = ["00:00", "00:30", "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30"]
    
    public enum CellContentType {
        case destination, arrivalDate, departureDate, arrivalHour, departureHour
    }
        
    init(tripProfile: TRPTripProfile, oldTripProfile: TRPTripProfile? = nil, maxTripDays: Int = 3, loadedCity: TRPCity? = nil) {
        self.tripProfile = tripProfile
        self.oldTripProfile = oldTripProfile
        self.maxTripDays = maxTripDays
        if let loadedCity = loadedCity {
            self.selectedCity = loadedCity
            self.isEditing = true
        }
        implementTripProfile(oldTripProfile)
        sectionModels = createData()
    }
    
    func getSectionCount() -> Int{
        return sectionModels.count
    }
    
    func getCellCount(section: Int) -> Int{
        return sectionModels[section].cells.count
    }
    
    func getSectionTitle(section: Int) -> String {
        return sectionModels[section].title
    }
    
    func getSectionIsRequired(section: Int) -> Bool {
        return sectionModels[section].isRequired
    }
    
    func getCellModel(at indexPath: IndexPath) -> CreateTripTripInformationCellModel {
        return sectionModels[indexPath.section].cells[indexPath.row]
    }
    
    public func setNexusTripInformation(startDate: String, endDate: String, city: TRPCity) {
        if let startDate = startDate.toDate(format: "yyyy-MM-dd") {
            if isDatePast(startDate) {
                let (date, time) = Date.getNearestAvailableDateAndTimeForCreateTrip()
                selectedArrivalDate = date
                selectedArrivalHour = time
            } else {
                setSelectedArrivalDate(startDate)
            }
        }
        if let endDate = endDate.toDate(format: "yyyy-MM-dd") {
            if isDatePast(endDate) {
                let (date, time) = Date.getNearestAvailableDateAndTimeForCreateTrip()
                selectedArrivalDate = date
                selectedArrivalHour = time
            } else {
                setSelectedDepartureDate(endDate)
            }
        }
        setSelectedCity(city: city)
    }
    
    public func getSelectedCity() -> TRPCity {
        return selectedCity!
    }
    
    private func isDatePast(_ date: Date) -> Bool {
        return Date() > date
    }
        
}

extension CreateTripTripInformationViewModel {
    
    private func createData() -> [CreateTripTripInformationSectionModel]{
        var sections = [CreateTripTripInformationSectionModel]()
        let destinationCell = CreateTripTripInformationCellModel(title: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.destination.city.placeholder"), contentType: .destination)
        sections.append(CreateTripTripInformationSectionModel(title: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.destination.city.label"), cells: [destinationCell], isRequired: true))
        let arrivalDateCell = CreateTripTripInformationCellModel(title: TRPLanguagesController.shared.getLanguageValue(for: "arrival"), contentType: .arrivalDate)
        let departureDateCell = CreateTripTripInformationCellModel(title: TRPLanguagesController.shared.getLanguageValue(for: "departure"), contentType: .departureDate)
        sections.append(CreateTripTripInformationSectionModel(title: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.destination.dates"), cells: [arrivalDateCell, departureDateCell]))
        let arrivalHourCell = CreateTripTripInformationCellModel(title: TRPLanguagesController.shared.getLanguageValue(for: "arrival"), contentType: .arrivalHour)
        let departureHourCell = CreateTripTripInformationCellModel(title: TRPLanguagesController.shared.getLanguageValue(for: "departure"), contentType: .departureHour)
        sections.append(CreateTripTripInformationSectionModel(title: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.destination.hours"), cells: [arrivalHourCell, departureHourCell]))
        return sections
    }
}

extension CreateTripTripInformationViewModel {
    
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
    }
}

//MARK: - Destination City
extension CreateTripTripInformationViewModel {
    
    func setSelectedCity(city: TRPCity) {
        selectedCity = city
        delegate?.viewModel(dataLoaded: true)
//        maxTripDays = city.maxTripDays
    }
    
    func getSelectedCityName() -> String {
        return selectedCity?.name ?? ""
    }
}

//MARK: - Flight Dates
extension CreateTripTripInformationViewModel {
    func getArrivalDateModel() -> CreateTripDateModel {
        return CreateTripDateModel(minimumDate: Date(), selectedDate: selectedArrivalDate)
    }
    
    func getDepartureDateModel() -> CreateTripDateModel {
        return CreateTripDateModel(minimumDate: selectedArrivalDate, maximumDate: getMaximumDateRange(), selectedDate: selectedDepartureDate)
    }
    
    func getSelectedArrivalDate() -> String {
        return selectedArrivalDate.toString(format: "dd MMM yyyy")
    }
    
    func getSelectedDepartureDate() -> String {
        return selectedDepartureDate.toString(format: "dd MMM yyyy")
    }
    
    func setSelectedArrivalDate(_ date: Date) {
        self.selectedArrivalDate = date
        setupDepartureDateForArrival()
    }
    
    func setSelectedDepartureDate(_ date: Date) {
        self.selectedDepartureDate = date
        self.delegate?.viewModel(dataLoaded: true)
    }
    
    func getSelectedDate(isArrival: Bool) -> String {
        if isArrival {
            return getSelectedArrivalDate()
        } else {
            return getSelectedDepartureDate()
        }
    }
    
    private func getMaximumDateRange() -> Date {
        return selectedArrivalDate.addDay(selectedCity?.maxTripDays ?? 13)!
    }
    
    private func setupDepartureDateForArrival() {
        if selectedArrivalDate.isToday() {
            let (date, time) = Date.getNearestAvailableDateAndTimeForCreateTrip()
            selectedArrivalDate = date
            selectedArrivalHour = time
//            selectedDepartureDate = date
        } else {
            selectedArrivalHour = "09:00"
            selectedDepartureDate = selectedArrivalDate
        }
        self.delegate?.viewModel(dataLoaded: true)
    }
    
    private func isArrivalDateEqualsDeparture() -> Bool {
        return selectedArrivalDate.toString(format: "dd.MM.yyyy") == selectedDepartureDate.toString(format: "dd.MM.yyyy")
    }
}

//MARK: - Flight Hours
extension CreateTripTripInformationViewModel {
    
    func getSelectedArrivalHour() -> String {
        return selectedArrivalHour
    }
    
    func getSelectedDepartureHour() -> String {
        return selectedDepartureHour
    }
    
    func setSelectedArrivalHour(_ hour: String) {
        self.selectedArrivalHour = hour
        setupDepartureHourForArrival()
    }
    
    func setSelectedDepartureHour(_ hour: String) {
        self.selectedDepartureHour = hour
        self.delegate?.viewModel(dataLoaded: true)
    }
    
    func getSelectedHour(isArrival: Bool) -> String {
        if isArrival {
            return getSelectedArrivalHour()
        } else {
            return getSelectedDepartureHour()
        }
    }
    
    func getMinimumHour() -> String? {
        if isArrivalDateEqualsDeparture() {
            return getSelectedArrivalHour()
        } else {
            return nil
        }
    }
    
    private func setupDepartureHourForArrival() {
        self.checkDepartureHourIsLower()
        self.delegate?.viewModel(dataLoaded: true)
    }
    
    private func checkDepartureHourIsLower() {
        if let departureHourIndex = times.firstIndex(of: selectedDepartureHour),
            let arrivalHourIndex = times.firstIndex(of: selectedArrivalHour) {
            if isArrivalDateEqualsDeparture() {
                if departureHourIndex < arrivalHourIndex {
                    let newDepartureHourIndex = min(arrivalHourIndex + 2, times.count - 1)
                    selectedDepartureHour = times[newDepartureHourIndex]
                }
            }
        }
    }
}

extension CreateTripTripInformationViewModel {
    public func canContinue() -> Bool {
        guard let selectedCity = selectedCity else {
            self.delegate?.viewModel(showMessage: TRPLanguagesController.shared.getLanguageValue(for: "select_destination_city"), type: .error)
            return false
        }
        tripProfile.cityId = selectedCity.id
        setTripHours()
        return true
    }
        
    private func setTripHours() {
    
        guard let arrivalDateWithHour = selectedArrivalDate.setHour(for: selectedArrivalHour),
            let departureDateWithHour = selectedDepartureDate.setHour(for: selectedDepartureHour) else {return}
        
        tripProfile.arrivalDate = TRPTime(date: arrivalDateWithHour)
        tripProfile.departureDate = TRPTime(date: departureDateWithHour)
    }
}


public struct CreateTripDateModel {
    var minimumDate: Date
    var maximumDate: Date?
    var selectedDate: Date
}

struct CreateTripTripInformationSectionModel {
    var title: String
    var cells: [CreateTripTripInformationCellModel]
    var isRequired: Bool = false
}
struct CreateTripTripInformationCellModel {
    var title: String
    var contentType: CreateTripTripInformationViewModel.CellContentType
}
