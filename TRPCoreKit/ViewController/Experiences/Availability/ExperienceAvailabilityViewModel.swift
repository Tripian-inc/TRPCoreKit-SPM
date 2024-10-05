//
//  ExperienceAvailabilityViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


enum ExperienceAvailabilityCellType {
    case date
    case peopleCount
    case availability
    case options
    case bigTitle
}

struct ExperienceAvailabilityCellModel {
    var type: ExperienceAvailabilityCellType
    var title: String
    var data: Any
    var input: Any?
}

class TourOptionUIModel {
    
    struct CategoryPeople {
        var id: Int
        var peopleCount: Int
        var name:String
    }
    
    var optionId: Int
    var title: String
    var duration: String? = nil
    var discount: String? = nil
    var price: String? = nil
    var priceType: String? = nil
    var isExistBookingParametes = false
    
    var startTimes: [String]?
    var endTime: String?
    var optionPrice: GYGOptionPricing?
    private(set) var totalReatilPrice: Double?
    
    private(set) var selectedPeopleWithCategory: [CategoryPeople] = []
    
    
    
    init(optionId: Int, title: String) {
        self.optionId = optionId
        self.title = title
    }
    
    func calculatePrice(_ people: [ExperinceSelectedPeople]) -> String {
        guard let optionPrices = optionPrice else { return price ?? "0"}
        var tempCategory: [CategoryPeople] = []
        var mPrice: String = price ?? "0"
//        var totalPrice:Double = 0
//        people.forEach { person in
//            if let priceCategory = optionPrices.categories.first(where: {$0.name.lowercased() == person.name.lowercased()}) {
//                priceCategory.scale.forEach { pricingScale in
//                    if let minParticipants = pricingScale.minParticipants, let maxParticipants = pricingScale.maxParticipants {
//                        if minParticipants <= person.count &&  person.count <= maxParticipants {
//                            let cP = CategoryPeople(id: priceCategory.id, peopleCount: person.count, name: priceCategory.name )
//                            tempCategory.append(cP)
//                            let netPrice: Double = Double(person.count) * (pricingScale.retailPrice ?? 0)
//                            totalPrice += netPrice
//                        }
//                    }
//                }
//            }
//        }
//        selectedPeopleWithCategory = tempCategory
//        totalReatilPrice = totalPrice
//        mPrice = String(format: "%.2f", totalPrice)
        return mPrice
    }
    
}

struct ExpericePeopleCellModel {
    var id: Int
    var title: String
    var explaine:String
    var defaultValue: Int
}

class ExperinceSelectedPeople {
    
    var name: String
    var count: Int
    
    init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

protocol ExperienceAvailabilityViewModelDelegate: ViewModelDelegate {
    func viewModel(showWarning: String)
}


//TODO: ÖNCE AVALİABLE ÇEKİLEBİLİR. KONTROL ETMEK LAZIM
final class ExperienceAvailabilityViewModel: TableViewViewModelProtocol {
    
    typealias T = ExperienceAvailabilityCellModel
    
    weak var delegate: ExperienceAvailabilityViewModelDelegate?
    
    var cellViewModels: [ExperienceAvailabilityCellModel] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    var numberOfCells: Int {
        return cellViewModels.count
    }
    
    private var availabilities: [GYGAvailability] = []
    private var tourOptions: [GYGTourOption] = []
    private var optionsPricing: [GYGOptionPricing] = []
    private var isCategoriesLoaded: Bool = false
    private let tourId: Int
    public var selectedOptionDate: String = ""
    private var selectedDate: String?
    var selectedPeopleCount: [ExperinceSelectedPeople] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    //--- USE CASES
    public var fetchTourOption: FetchTourOptionsUseCase?
    public var bookingOptionUseCase: BookingOptionsUseCase?
    
    /// <#Description#>
    /// - Parameters:
    ///   - tourId: Tourİd
    ///   - date: Date - d MMM yyyy
    init(tourId: Int, date: String? = nil) {
        self.tourId = tourId
        self.selectedOptionDate = date != nil ? date! : Date().toString(format: "d MMM yyyy", dateStyle: nil, timeStyle: nil)
    }
    
    public func start() {
        let dateCell = ExperienceAvailabilityCellModel(type: .date, title: "Date", data: "")
        cellViewModels.append(dateCell)
        checkAvaliability()
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ExperienceAvailabilityCellModel {
        return cellViewModels[indexPath.row]
    }
    
    func updateSelectedDate(selectedDate: Date) {
        let readable = selectedDate.toString(format: "d MMM yyyy", dateStyle: nil, timeStyle: nil)
        selectedOptionDate = readable
    }
    
    
    func checkAvaliability() {
        guard let selectedDate = selectedOptionDate.toDate(format: "d MMM yyyy"),
              let start = selectedDate.setHour(0, minutes: 0),
              let added7day = start.addDay(7),
              let end = added7day.setHour(23, minutes: 59) else {return}
        
        let startDate = start.toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
        let startTime = start.toString(format: "HH:mm:ss", dateStyle: nil, timeStyle: nil)
        let fromDate = "\(startDate)T\(startTime)"
        self.selectedDate = startDate
        let endDate = end.toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
        let endTime = end.toString(format: "HH:mm:ss", dateStyle: nil, timeStyle: nil)
        let toDate = "\(endDate)T\(endTime)"
        
        fetchTourAvailability(fromDate: fromDate, toDate: toDate)
    }
    
    public func clearATable() {
        var cells = [ExperienceAvailabilityCellModel]()
        for cell in cellViewModels {
            if cell.type != .options && cell.type != .bigTitle{
                cells.append(cell)
            }
        }
        cellViewModels = cells
    }
    
    
    //TODO: OPTİON PRİCE ÇEKİLEREK İŞLEM YAPILACAK.
    public func getOptionalTime(_ optional: GYGTourOption) -> String? {
        guard let firstAvailability = availabilities.first else {return nil}
//        let array =  firstAvailability.startTime.components(separatedBy: "T")
//        if array.count == 2 {
//            if let converted = array[1].toDate(format: "HH:mm:ss")?.toString(format: "HH:mm", dateStyle: nil, timeStyle: nil) {
//                return converted
//            }
//            return array[1]
//        }
        return nil
    }
    
    public func getBookingParameters(optionId: Int) ->  [GYGBookingParameter] {
        tourOptions.first(where: {$0.optionID == optionId})?.bookingParameter ?? []
    }
    
    public func getLanguage(optionId: Int) -> GYGCondLanguage?{
        return tourOptions.first(where: {$0.optionID == optionId})?.condLanguage
    }
    
    public func getPickUpInfo(optionId: Int) -> String? {
        return tourOptions.first(where: {$0.optionID == optionId})?.pickUp
    }
    
    public func updateSelectedPeople(_ people: ExperinceSelectedPeople) {
        if let firts = selectedPeopleCount.first(where: {$0.name.lowercased() == people.name.lowercased()}) {
            if firts.count != people.count {
                firts.count = people.count
                delegate?.viewModel(dataLoaded: true)
            }
        }else {
            selectedPeopleCount.append(people)
        }
    }
    
    
    public func setDataInUseCases(_ uiModel: TourOptionUIModel) {
//        bookingOptionUseCase?.setBookinOptionId(id: uiModel.optionId)
//        if let price = uiModel.totalReatilPrice {
//            bookingOptionUseCase?.setBookingPrice(price)
//        }
//        let categories = uiModel.selectedPeopleWithCategory.compactMap({GYGBookingCategoryPropety(categoryId: $0.id, name: $0.name,numberOfParticipants: $0.peopleCount)})
//        bookingOptionUseCase?.setBookingCategories(categories)
    }
    
    public func setTime(_ time: String, optionId: Int? = nil) {
        guard let date = selectedDate else {
            print("[Error] Selected date is nil")
            return
        }
        let dateTime = "\(date)T\(time):00"
        bookingOptionUseCase?.setBookingDate(dateTime)
    }
    
    /// Tum veriler çekildiğinde eğer hiç user seçilmediyse onu manuel seçer
    private func selectAnAdultIfNotExist() {
        if isSelectedPeopleEmpty() {
            self.cellViewModels.forEach { cell in
                if cell.type == .peopleCount,
                   let peopleCell = cell.data as? ExpericePeopleCellModel,
                   peopleCell.title.lowercased() == "Adults".lowercased() {
                    let oneAdult = ExperinceSelectedPeople( name: peopleCell.title, count: 1)
                    updateSelectedPeople(oneAdult)
                }
            }
            
        }
    }
    
    public func isSelectedPeopleEmpty() -> Bool {
        var isEmpty = true
        selectedPeopleCount.forEach { model in
            if model.count != 0 {
                isEmpty = false
            }
        }
        return isEmpty
    }
}

extension ExperienceAvailabilityViewModel {
    
    private func getOnlyDate(_ date: String) -> String? {
        return date.components(separatedBy: "T").first
        
    }
    
    private func tryToDate(_ strDate: String) -> String {
        guard let date = strDate.toDate(format: "yyyy-MM-dd") else {return strDate}
        return "Try \(date.toString(format: "MMM d", dateStyle: nil, timeStyle: nil))"
    }
}

//MARK: - APİ CALLS
extension ExperienceAvailabilityViewModel {
    
    private func fetchTourAvailability(fromDate: String, toDate: String) {
        delegate?.viewModel(showPreloader: true)
//        fetchTourOption?.tourAvailabilities(id: tourId, fromDate: fromDate, toDate: toDate) { [weak self] result in
//            self?.delegate?.viewModel(showPreloader: false)
//            switch result {
//            case .success(let availabilities):
//                
//                if availabilities.isEmpty {
//                    self?.delegate?.viewModel(showWarning: "Sorry, there is no availability for the selected date.")
//                    return
//                }
//                
//                guard let referans = self?.getOnlyDate(fromDate) else {
//                    self?.delegate?.viewModel(showWarning: "Something went wrong")
//                    return
//                }
//                
//                var isMatched = false
//                for item in availabilities {
//                    if let time = self?.getOnlyDate(item.startTime), referans == time {
//                        isMatched = true
//                    }
//                }
//                if isMatched {
//                    self?.availabilities = availabilities
//                    self?.fetchOptions()
//                }else {
//                    if let first = availabilities.first, let firstDate = self?.getOnlyDate(first.startTime), let tryTo = self?.tryToDate(firstDate) {
//                        self?.delegate?.viewModel(showWarning: "Sorry, there is no availability for the selected date.\(tryTo)")
//                        return
//                    }
//                    self?.delegate?.viewModel(showWarning: "Sorry, there is no availability for the selected date.")
//                }
//            case .failure(let error):
//                self?.delegate?.viewModel(error: error)
//            }
//        }
    }
    
    private func fetchOptions() {
        delegate?.viewModel(showPreloader: true)
        fetchTourOption?.tourOptions(tourId: tourId, fromDate: nil, toDate: nil) { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let tourOption):
                self?.tourOptions = tourOption
                self?.cellViewModels.append(.init(type: .bigTitle, title: "Available Options", data: ""))
                tourOption.forEach { option in
                    let data = self?.createOptionUI(option: option)
                    self?.cellViewModels.append(.init(type: .options, title: "", data: data))
                    self?.fetchOptionsPrices(optionId: option.optionID)
                }
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        }
    }
    
    private func createOptionUI(option: GYGTourOption) ->  TourOptionUIModel {
        
        let uiModel = TourOptionUIModel(optionId: option.optionID, title: option.title)
//        uiModel.duration = "\(option.duration.clean) \(option.durationUnit)"
//        
//        if let price = option.price {
//            let description = price.description == "individual" ? "per person" : price.description
//            uiModel.price = "$\(price.values.amount)"
//            uiModel.priceType = description
//            if let special = price.values.special, let savings = special.savings {
//                uiModel.discount = "\(Int(savings))% discount"
//            }else {
//                uiModel.discount = ""
//            }
//        }
//        uiModel.isExistBookingParametes = existBookingsParameters(option)
        return uiModel
    }
    
    
    private func existBookingsParameters(_ option: GYGTourOption) -> Bool {
        if option.bookingParameter.isEmpty {
            return false
        }
        if option.bookingParameter.count == 1 {
            if option.bookingParameter.first!.name == "language" {
                if let lang = getLanguage(optionId: option.optionID) {
                    let totalLang = lang.languageAudio.count + lang.languageLive.count + lang.languageBooklet.count
                    return totalLang > 1
                }
            }
        }
        return true
    }
    
}

extension ExperienceAvailabilityViewModel {
    
    private func fetchOptionsPrices(optionId: Int) {
//        delegate?.viewModel(showPreloader: true)
//        fetchTourOption?.optionPricings(optionId: optionId) { [weak self] result in
//            self?.delegate?.viewModel(showPreloader: false)
//            switch result {
//            case .success(let priceOption):
//                if let category = priceOption.first?.categories {
//                    self?.createPeopleCell(categories: category)
//                }
//                if let strongSelf = self {
//                    strongSelf.optionsPricing.append(contentsOf: priceOption)
//                }
//                self?.margePriceCellAndAvaliablity(optionId: optionId, prices: priceOption)
//                self?.selectAnAdultIfNotExist()
//            case .failure(let error):
//                self?.delegate?.viewModel(error: error)
//            }
//        }
    }
    
//    private func createPeopleCell(categories: [PricingCategory]) {
//        guard isCategoriesLoaded == false else {return}
//        
//        if !categories.isEmpty {
//            isCategoriesLoaded.toggle()
//        }
//        
//        var tempModels = [ExperienceAvailabilityCellModel]()
//        
//        categories.forEach { (category) in
//            var explaine = ""
//            if let max = category.maxAge, let min = category.minAge {
//                explaine =  "(Age \(min)-\(max))"
//            }
//            if let max = category.maxAge, category.minAge == nil {
//                explaine =  "(Age <\(max))"
//            }
//            let defaultValue = category.name.lowercased() == "adult" ? 1 : 0
//            
//            let cellModel = ExpericePeopleCellModel(id: category.id,
//                                                    title: category.name,
//                                                    explaine: explaine,
//                                                    defaultValue: defaultValue)
//            
//            let peopleCout = ExperienceAvailabilityCellModel(type: .peopleCount, title: "", data: cellModel)
//            tempModels.append(peopleCout)
//        }
//        cellViewModels.insert(contentsOf: tempModels, at: 1)
//    }
    
    
    
    private func margePriceCellAndAvaliablity(optionId: Int, prices: [GYGOptionPricing]) {
//        prices.forEach { price in
//            // Availities ile first ü düzeltilecek.
//            var times = [String]()
//            var optionPricing: GYGOptionPricing?
//            availabilities.forEach { availability in
//                if let time = self.getOnlyDate(availability.startTime),
//                   selectedDate == time,
//                   availability.pricingID == price.pricingID {
//                    optionPricing = price
//                    
//                    if let mDate = availability.startTime.toDateWithoutUTC(format: "yyyy-MM-dd'T'HH:mm:ss") {
//                        let start = "\(mDate.toStringWithoutTimeZone(format: "HH:mm", dateStyle: nil, timeStyle: nil))"
//                        times.append(start)
//                    }
//                }
//            }
//            
//            if !times.isEmpty {
//                updateCellModelWithTime(optionId: optionId, times: times, price: optionPricing)
//            }
//        }
    }
    
    private func updateCellModelWithTime(optionId: Int, times: [String], price: GYGOptionPricing?) {
        cellViewModels.forEach { cell in
            if let uimodel = cell.data as? TourOptionUIModel, uimodel.optionId == optionId {
                (cell.data as! TourOptionUIModel).startTimes = times
                (cell.data as! TourOptionUIModel).optionPrice = price
            }
        }
        delegate?.viewModel(dataLoaded: true)
    }
    
}
