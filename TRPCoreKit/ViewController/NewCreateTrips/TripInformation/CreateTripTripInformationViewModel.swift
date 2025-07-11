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
    private var maxTripDays: Int = 5
    
    //Arrival date in tutulduğu değer
//    private var selectedArrivalDate: Date = (Date().localDate().addDay(1))!
    private var selectedArrivalDate: String = (Date().localDate().addDay(1))!.getDate()
    private var selectedDepartureDate: String = (Date().localDate().addDay(5))!.getDate()
    //Departure date in tutulduğu değer
//    private var selectedDepartureDate: Date = (Date().localDate().addDay(1))!
    private var selectedArrivalHour = "09:00"
    private var selectedDepartureHour = "21:00"
    private var selectedCity: TRPCity?
    public var isEditing: Bool = false
    
    private final let times: [String] = ["00:00", "00:30", "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30"]
    
    public enum CellContentType {
        case destination, arrivalDate, departureDate, arrivalHour, departureHour
    }
        
    init(tripProfile: TRPTripProfile, oldTripProfile: TRPTripProfile? = nil, maxTripDays: Int = 5, loadedCity: TRPCity? = nil) {
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
        if startDate.contains("T") {
            selectedArrivalDate = startDate.toDate(format: String.fullDateFormat)?.getDate() ?? ""
        } else {
            selectedArrivalDate = startDate
        }
        if let startDateTime = startDate.toDate(format: String.fullDateFormat) {
            if startDateTime.isDatePast() {
                selectedArrivalDate = Date.getTomorrowDate()
            } else {
                setSelectedArrivalDate(selectedArrivalDate, forNexusTrip: true)
            }
        }
        if let endDateTime = endDate.toDate(format: String.fullDateFormat) {
            if !endDateTime.isDatePast() {
                setSelectedDepartureDate(endDateTime.getDate())
//            } else {
//                setSelectedArrivalDate(startDate, forNexusTrip: true)
            }
        }
        setSelectedCity(city: city)
    }
    
    public func getSelectedCity() -> TRPCity {
        return selectedCity!
    }
        
}

extension CreateTripTripInformationViewModel {
    
    private func createData() -> [CreateTripTripInformationSectionModel]{
        var sections = [CreateTripTripInformationSectionModel]()
        let destinationCell = CreateTripTripInformationCellModel(
            title: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.destination.city.placeholder"),
            contentType: .destination)
        sections.append(CreateTripTripInformationSectionModel(
            title: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.destination.city.label"),
            cells: [destinationCell],
            isRequired: true)
        )
        let arrivalDateCell = CreateTripTripInformationCellModel(
            title: TRPLanguagesController.shared.getLanguageValue(for: "arrival"),
            contentType: .arrivalDate
        )
        let departureDateCell = CreateTripTripInformationCellModel(
            title: TRPLanguagesController.shared.getLanguageValue(for: "departure"),
            contentType: .departureDate
        )
        sections.append(CreateTripTripInformationSectionModel(
            title: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.destination.dates"),
            cells: [arrivalDateCell, departureDateCell]))
        let arrivalHourCell = CreateTripTripInformationCellModel(title: TRPLanguagesController.shared.getLanguageValue(for: "arrival"), contentType: .arrivalHour)
        let departureHourCell = CreateTripTripInformationCellModel(title: TRPLanguagesController.shared.getLanguageValue(for: "departure"), contentType: .departureHour)
        sections.append(CreateTripTripInformationSectionModel(title: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.destination.hours"), cells: [arrivalHourCell, departureHourCell]))
        return sections
    }
}

extension CreateTripTripInformationViewModel {
    
    private func implementTripProfile(_ tripProfile: TRPTripProfile?) {
        
        guard let profile = tripProfile else {return}
        
        if let arrivalDate = profile.arrivalDate?.date, let arrival = profile.arrivalDate?.toDate {
            let hour = arrival.toString(format: "HH:mm", dateStyle: nil, timeStyle: nil)
            if !hour.isEmpty{
                selectedArrivalHour = hour
            }
                        
            self.selectedArrivalDate = arrivalDate
        }
        
        if let departureDate = profile.departureDate?.date, let departure = profile.departureDate?.toDate {
            let hour = departure.toStringWithoutTimeZone(format: "HH:mm", dateStyle: nil, timeStyle: nil)
            if !hour.isEmpty{
                selectedDepartureHour = hour
            }
            
            self.selectedDepartureDate = departureDate
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
        return CreateTripDateModel(minimumDate: getMinimumDateRange(), selectedDate: selectedArrivalDate)
    }
    
    func getDepartureDateModel() -> CreateTripDateModel {
        return CreateTripDateModel(minimumDate: selectedArrivalDate, maximumDate: getMaximumDateRange(), selectedDate: selectedDepartureDate)
    }
    
    func getSelectedArrivalDate() -> String {
        return selectedArrivalDate.toDate()?.toString(format: "dd MMM yyyy") ?? selectedArrivalDate
    }
    
    func getSelectedDepartureDate() -> String {
        return selectedDepartureDate.toDate()?.toString(format: "dd MMM yyyy") ?? selectedDepartureDate
    }
    
    func setSelectedArrivalDate(_ date: String, forNexusTrip: Bool = false) {
        self.selectedArrivalDate = date
        setupDepartureDateForArrival(forNexusTrip: forNexusTrip)
    }
    
    func setSelectedDepartureDate(_ date: String) {
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
    
    private func getMaximumDateRange() -> String {
        return selectedArrivalDate.toDate()?.addDay(selectedCity?.maxTripDays ?? 13)?.toString() ?? Date().localDate().toString(format: String.defaultDateFormat)
    }
    
    private func getMinimumDateRange() -> String {
//        var date = Date.getNearestDate()// Date().localDate().getDateWithZeroHour(forLocal: true)
//        if date.isTodayLocal() {
//            date = Date.getNearestDate()
//        }
        return Date.getNearestDate()
    }
    
    private func setupDepartureDateForArrival(forNexusTrip: Bool = false) {
        if selectedArrivalDate.toDateWithoutUTC()?.isTodayLocal() == true {
            let maxHourForNearTime = forNexusTrip ? 16 : 21
            let (date, time) = Date.getNearestAvailableDateAndTimeForCreateTrip(maxHour: maxHourForNearTime)
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
        return selectedArrivalDate == selectedDepartureDate
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
    
//        guard let arrivalDateWithHour = selectedArrivalDate.setHour(for: selectedArrivalHour),
//            let departureDateWithHour = selectedDepartureDate.setHour(for: selectedDepartureHour) else {return}
        
        tripProfile.arrivalDate = TRPTime(date: selectedArrivalDate, time: selectedArrivalHour + ":00")
        tripProfile.departureDate = TRPTime(date: selectedDepartureDate, time: selectedDepartureHour + ":00")
    }
}


public struct CreateTripDateModel {
    var minimumDate: String
    var maximumDate: String?
    var selectedDate: String
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
