//
//  TRPTripModeViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 13.11.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit
import MapboxDirections
import TRPDataLayer
import CoreLocation
import TRPProvider

public protocol TRPTripModeViewModelDelegate: ViewModelDelegate {
    
    func viewModel(rotaPois: [TRPPoi])
    func viewModel(alternativePois: [TRPPoi])
    func viewModel(searchThisArea: [TRPPoi], isOffer: Bool)
    
    /// Hold a data than have a route that about TripPlan
    /// - Parameter drawRoute: Route
    /// - Parameter wayPoints: Place Point
    func viewModel(drawRoute: Route?, wayPoints: [TRPLocation])
    
    
    
    //Itinerary için kullanılıyor. Note: Taşınabilir?
    func viewMode(steps: [TRPStep])
    func viewModelShowInfoMessage(_ message: String)
    func viewModelCleanAnnotation()
    func viewModelCurrentDayChanged(_ currentDay: TRPPlan, order: Int)
    func viewModelNoReccomendationAlert(_ message: String)
    func viewModelRoutingError(_ message: String, mapBoxError: String)
    
    func setDestinationIdAndEngName(_ id: Int, cityEngName: String)
    
}

public struct StepInfoForListOfRouting {
    
    var dailyPlanId: Int
    var stepOrder: Int
    var time: TimeInterval
    var distance: Float
    
    init(planId: Int, stepOrder: Int, time: TimeInterval, distance: Float) {
        self.dailyPlanId = planId
        self.stepOrder = stepOrder
        self.time = time
        self.distance = distance
    }
}

public struct DriveInfoForListOfRouting {
    var dailyPlanId: Int
    var driveOrder: Int
    var time: TimeInterval
    var distance: Float
    
    init(planId: Int, driveOrder: Int, time: TimeInterval, distance: Float) {
        self.dailyPlanId = planId
        self.driveOrder = driveOrder
        self.time = time
        self.distance = distance
    }
}


public struct DayList {
    public var day: Int
    public var planId: Int
    public var date: String
}

public class TRPTripModeViewModel {
    
    public weak var delegate: TRPTripModeViewModelDelegate?
    private(set) var destinationId: Int = 0
    private(set) var cityEngName: String = ""
    private(set) var tripHash: String
    private(set) var city: TRPCity
    private(set) var trip: TRPTrip?
    private(set) var alternatives: [TRPPoi] = []
    private(set) var dailyPlan: TRPPlan?{
        didSet {
            guard let plan = dailyPlan else {return}
            fetchAlternativePois()
            self.delegate?.viewModelCleanAnnotation()
            self.delegate?.viewModel(rotaPois: plan.steps.compactMap { $0.poi })
            self.delegate?.viewMode(steps: plan.steps)
            self.delegate?.viewModelCurrentDayChanged(plan, order: getDayOrderInTrip(planId: plan.id))
        }
    }
    
    
    //  USE CASE
    public var fetchTripUseCase: FetchTripUseCase?
    public var tripModelObserverUseCase: ObserveTripModeUseCase?
    public var changeDayUseCase: ChangeDailyPlanUseCase?
    public var addStepUseCase: AddStepUseCase?
    public var removeStepUseCase: DeleteStepUseCase?
    public var editPlanHourUseCase: EditPlanHoursUseCase?
    public var fetchStepAlternative: FetchStepAlternative?
    public var fetchPlanAlternative: FetchPlanAlternative?
    public var reOrderStepUseCase: ReOrderStepUseCase?
    public var searchThisAreaUseCase: FetchBoundsPoisUseCase?
    public var fetchPoiUseCase: FetchPoiUseCase?
    public var tripObserverUseCase: ObserveTripEventStatusUseCase?
    public var fetchReactionUseCase: FetchUserReactionUseCase?
    public var observeUserReaction: ObserveUserReactionUseCase?
    public var addReactionUseCase: AddUserReactionUseCase?
    public var updateReactionUseCase: UpdateUserReactionUseCase?
    public var deleteReactionUseCase: DeleteUserReactionUseCase?
    ///offers
    public var fetchOfferUseCase: FetchOfferUseCase?
    public var fetchOptInOfferUseCase: FetchOptInOfferUseCase?
    public var observeOptInOfferUseCase: ObserveOptInOfferUseCase?
    
    public var exportItineraryUseCase: ExportItineraryUseCase?
    
    
    var mapRouteUseCases: MapRouteUseCases?
    
    public init(tripHash: String, city: TRPCity) {
        self.tripHash = tripHash
        self.city = city
        fetchDestinationId()
    }
    
    var startLocation: TRPLocation {
        return city.coordinate
    }
    
    func start() {
        addObservers()
        if !tripIsExistInRepository() {
            fetchTripUseCase?.executeFetchTrip(tripHash: tripHash, completion: nil)
        }
    }
 
    private func tripIsExistInRepository() -> Bool {
        guard let trip = tripModelObserverUseCase?.trip.value else {return false}
        return trip.tripHash == tripHash
    }
    
    
    private func setDay() {
        if let first = trip?.plans.first {
            changeDay(planId: first.id)
        }
    }
    
    public func changeDay(planId id: Int) {
        delegate?.viewModel(showPreloader: true)
        changeDayUseCase?.executeChangeDailyPlan(id: id, completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            if case .failure(let error) = result {
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    public func getDayList() -> [DayList] {
        var dates = [DayList]()
        if let plans = trip?.plans {
            for (index, plan) in plans.enumerated() {
                let day = DayList(day: index + 1, planId: plan.id, date: convertDateReadable(plan.date))
                dates.append(day)
            }
        }
        return dates
    }
    
    private func getDayOrderInTrip(planId: Int) -> Int {
        guard let index = trip?.plans.firstIndex(where: {$0.id == planId}) else {return 0}
        return index
    }
    
    private func convertDateReadable(_ date: String) -> String {
        if let convertedDate = date.toDate(format: "YYYY-MM-dd") {
            return convertedDate.toString(dateStyle: DateFormatter.Style.medium)
        }
        return ""
    }
    
    public func getPoiInRoute() -> [TRPPoi] {
        return dailyPlan?.steps.map({$0.poi}) ?? []
    }
    
    public func isCurrentDay(planId: Int) -> Bool {
        guard let currentDailyPlanId = dailyPlan?.id else {return false}
        return currentDailyPlanId == planId
    }
    
    func getPoiInfo(_ poiId: String, completion: ((_ poi: TRPPoi?) -> Void)?) {
        if poiId == TRPPoi.ACCOMMODATION_ID {
            return
        }
        fetchPoiUseCase?.executeFetchPoi(id: poiId, completion: { [weak self] result in
            switch result {
            case .success(let poi):
                completion?(poi)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    func getStepAlternatives(_ step: TRPStep, completion: @escaping (_ pois:[TRPPoi]) -> Void) {
        fetchStepAlternative?.executeFetchStepAlternative(stepId: step.id, completion: { result in
            switch result {
            case .success(let pois):
                completion(pois)
            case .failure(let error):
                print("[Error] \(error.localizedDescription)")
            }
        })
    }
    
    func exportPlan(completion: @escaping (_ url: TRPExportItinerary) -> Void) {
        delegate?.viewModel(showPreloader: true)
        
        exportItineraryUseCase?.executeFetchExportItinerary(tripHash: tripHash, completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let url):
                completion(url)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    
    public func isPoiInRoute(poiId: String) -> Bool {
        return getPoiInRoute().contains(where: { (poi) -> Bool in
            if poi.id == poiId {return true}
            return false
        })
    }
    
    public func isHotelInTrip() -> Bool {
        //return interactor.isHotel
        return false
    }
    
    public func searchThisArea(boundaryNorthEast ne:TRPLocation, boundarySouthWest sw:TRPLocation, typeId: [Int]? = nil) {
        delegate?.viewModel(showPreloader: true)
        searchThisAreaUseCase?.executeFetchNearByPois(northEast: ne, southWest: sw, categoryIds: typeId, completion: { [weak self] result, pagination in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let pois):
                self?.delegate?.viewModel(searchThisArea: pois, isOffer: false)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    public func removePoiInRoute(poiId: String) {
        if let step = getStep(poiId: poiId) {
            delegate?.viewModel(showPreloader: true)
            removeStepUseCase?.executeDeleteStep(id: step.id, completion: { [weak self] result in
                self?.delegate?.viewModel(showPreloader: false)
            
                if case .failure(let error) = result {
                    self?.delegate?.viewModel(error: error)
                }
            })
        }
    }
    
    public func addPoiInRoute(poiId: String) {
        delegate?.viewModel(showPreloader: true)
        addStepUseCase?.executeAddStep(poiId: poiId, completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
        
            if case .failure(let error) = result {
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    public func stepReOrder(stepId id: Int, newOrder: Int) {
        delegate?.viewModel(showPreloader: true)
        reOrderStepUseCase?.execureReOrderStep(id: id, order: newOrder, completion: {  [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
        
            if case .failure(let error) = result {
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    private func getStep(poiId: String) -> TRPStep? {
        guard let plan = dailyPlan else {return nil}
        return plan.steps.first(where: {$0.poi.id == poiId})
    }
    

    
    // Bu fonsiyon şu anda kullanılmuyor. selim abiden algoritma geldiğinde kullanılacak.
    fileprivate func arrayParserForRouting(_ ar: [TRPLocation],_ range: Int) -> [[TRPLocation]]{
        var tempAr = [TRPLocation]()
        var mainAr = [[TRPLocation]]()
        for element in ar {
            if tempAr.count != range {
                tempAr.append(element)
            }else {
                mainAr.append(tempAr)
                let oldAr = tempAr
                tempAr = []
                if let last = oldAr.last {
                    tempAr.append(last)
                }
                tempAr.append(element)
            }
        }
        if tempAr.count > 1 {
            mainAr.append(tempAr)
        }
        return mainAr
    }
    
    public func updateDailyPlanHour(start:String, end:String) {
        delegate?.viewModel(showPreloader: true)
        editPlanHourUseCase?.executeEditPlanHours(startTime: start, endTime: end, completion: { [weak self] result in
            
            switch result {
            case .success(let plan):
                if plan.generatedStatus == 1 {
                    self?.delegate?.viewModel(showPreloader: false)
                }
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    private func fetchAlternativePois() {
        fetchPlanAlternative?.executeFetchPlanAlternative(completion: { [weak self] (result, pagination) in
            switch result {
            case .success(let result):
                self?.alternatives = result
                self?.delegate?.viewModel(alternativePois: result)
            case .failure(let error):
                print("[Error] Fetch Alternative: \(error.localizedDescription)")
            }
        })
    }
    
    deinit {
        removeObservers()
        Log.deInitialize()
    }
    
    func getDestinationId() -> Int {
        return destinationId
    }
    
    func fetchDestinationId() {
        TripianCommonApi().getDestinationIdFromCity(city.id, completion: { result in
            switch result {
            case .success(let result):
                guard let result else {return}
                self.destinationId = result.zoneId ?? 0
                self.cityEngName = result.cityName ?? self.city.name
                self.delegate?.setDestinationIdAndEngName(self.destinationId, cityEngName: self.cityEngName)
            case .failure(let error):
                print("[Error] Fetch destination: \(error.localizedDescription)")
            }
        })
    }
}

//MARK: - Map Functions
extension TRPTripModeViewModel {
    
    
    public func getRouteWayPoints() -> [Waypoint] {
        guard let plan = dailyPlan else {return []}
        
        return plan.steps.map { step -> Waypoint in
            let poi = step.poi
            let coordinate = CLLocationCoordinate2D(latitude: poi.coordinate.lat, longitude: poi.coordinate.lon)
            return Waypoint(coordinate: coordinate, name: poi.name)
        }
    }
    
    public func calculateRouteForRotutinPoi(_ pois: [TRPPoi]) {
        let latLon = pois.map { (poi) -> TRPLocation in
            return poi.coordinate
        }
        if latLon.count < 2 {return}
        fetchRouteFromMapBoxServer(pois: latLon)
    }
 
    
    ///  MapBox dan rota alır.
    ///  Plandaki mekanlar için rota oluşturur.
    /// - Parameter pois: Poi listesi
    private func fetchRouteFromMapBoxServer(pois: [TRPLocation]) {
        guard let currentDailyPlanId = dailyPlan?.id else {return}
        guard let accessToken = TRPApiKeyController.getKey(TRPApiKeys.mglMapboxAccessToken) else {
            Log.e("MapBox access code is empty")
            return
        }
        let calculater = TRPRouteCalculator(providerApiKey: accessToken, wayPoints: pois, dailyPlanId: currentDailyPlanId)
        calculater.calculateRoute { (route, error, location, id) in
            if let error = error {
                let errorMessage = TRPLanguagesController.shared.getLanguageValue(for: "routing_error")
                let mData = self.poiToString(pois: pois)
                
                let customUserInfo = ["error":error.localizedDescription, "data": mData]
                NotificationCenter.default.post(name: .TRPMapBoxRoutingError, object: self, userInfo:customUserInfo)
                self.delegate?.viewModelRoutingError(errorMessage, mapBoxError: error.localizedDescription)
                return
            }
            
            guard let route = route else {return}
            var steps = [StepInfoForListOfRouting]()
            //todo: - manuel sort için bu alana ekleme yapılacak.
            for (index, element) in route.legs.enumerated() {
                steps.append(StepInfoForListOfRouting(planId: 0, stepOrder: index, time: element.expectedTravelTime, distance: Float(element.distance)))
            }
            DispatchQueue.main.async {
                self.mapRouteUseCases?.stepInfoData.value = steps
                self.delegate?.viewModel(drawRoute: route, wayPoints: pois)
            }
        }
    }
    
    private func poiToString(pois: [TRPLocation]) -> String {
        var pText = ""
        for p in pois {
            pText += "\(p.lat),\(p.lon) "
        }
        return pText
    }
    
    
    /// Belirli konumlar arasında rota oluşturur.
    ///  Search this arae için kıllanılır.
    /// - Parameters:
    ///   - locations: PoiList
    ///   - completion:
    public func fetchRoutes(locations: [TRPLocation], completion: @escaping (_ drawRoute: Route?, _ locations:[TRPLocation], _ error: Error?) -> () ) {
        guard let accessToken = TRPApiKeyController.getKey(TRPApiKeys.mglMapboxAccessToken) else {
            Log.e("MapBox access code is empty")
            return
        }
        let calculater = TRPRouteCalculator(providerApiKey: accessToken, wayPoints: locations, dailyPlanId: 0)
        calculater.calculateRoute { (route, error, location, id) in
            if let error = error {
                completion(nil,locations,error)
                return
            }
            guard let route = route else {return}
            DispatchQueue.main.async {
                completion(route,locations,nil)
            }
        }
    }
}

extension TRPTripModeViewModel: ObserverProtocol {
    
    func addObservers() {
        tripModelObserverUseCase?.trip.addObserver(self, observer: { [weak self] trip in
            self?.trip = trip
            if self?.dailyPlan == nil {
                self?.setDay()
            }
            self?.fetchOptInOffers()
        })
        delegate?.viewModel(showPreloader: true)
        tripModelObserverUseCase?.dailyPlan.addObserver(self, observer: { [weak self] dailyPlan in
            guard let strongSelf = self else {return}
            if dailyPlan.generatedStatus != 0 {
                strongSelf.delegate?.viewModel(showPreloader: false)
            }
            if strongSelf.isDailyPlanEmptyOrOnlyHome(dailyPlan) {
                if let trip = self?.trip {
                    if trip.isFirstPlan(planId: dailyPlan.id) && dailyPlan.generatedStatus == -1 {
                        strongSelf.delegate?.viewModelShowInfoMessage(TRPLanguagesController.shared.getLanguageValue(for: "no_recommendations_arrival"))
                    }else if trip.isLastPlan(planId: dailyPlan.id) && dailyPlan.generatedStatus == -1 {
                        strongSelf.delegate?.viewModelShowInfoMessage(TRPLanguagesController.shared.getLanguageValue(for: "no_recommendations_departure"))
                    }
                }
            }
            strongSelf.dailyPlan = dailyPlan
        })
        
        
        tripObserverUseCase?.showLoader.addObserver(self, observer: { [weak self] result in
            guard let result = result else {return}
            if result.type == .editStep {
                self?.delegate?.viewModel(showPreloader: result.showLoader)
            }
            
            
        })
        
        tripObserverUseCase?.error.addObserver(self, observer: { [weak self] result in
            guard let result = result else {return}
            if result.type == .editStep {
                self?.delegate?.viewModel(error: result.error)
            }
        })
        
//        observeOptInOfferUseCase?.values.addObserver(self, observer: { [weak self] result in
//            if result.isEmpty {
//                
//            }
//        })
        
    }
    
    private func isDailyPlanEmptyOrOnlyHome(_ plan: TRPPlan) -> Bool {
        if plan.steps.count == 0 {
            return true
        }
        if plan.steps.count == 1, let first = plan.steps.first?.poi, first.placeType == .hotel {
            return true
        }
        return false
    }
    
    func removeObservers() {
        tripObserverUseCase?.showLoader.removeObservers()
        tripObserverUseCase?.error.removeObservers()
        tripModelObserverUseCase?.trip.removeObserver(self)
        tripModelObserverUseCase?.dailyPlan.removeObserver(self)
        observeOptInOfferUseCase?.values.removeObservers()
    }
    
}

//MARK: - Offers
extension TRPTripModeViewModel {
    private func fetchOptInOffers() {
//        if let dateFrom = self.trip?.getArrivalDate()?.toDate, let dateTo = self.trip?.getDepartureDate()?.toDate {
//
//        }
        fetchOptInOfferUseCase?.executeOptInOffers(dateFrom: self.trip?.getArrivalDate()?.date, dateTo: self.trip?.getDepartureDate()?.date) {  (result) in
            switch result {
            case .success( _):
                break
            case .failure(let error):
                print("[Error] Fetch OptInOffers: \(error.localizedDescription)")
            }
        }
    }
    
    public func searchOffers(boundaryNorthEast ne:TRPLocation, boundarySouthWest sw:TRPLocation) {
        delegate?.viewModel(showPreloader: true)
        fetchOfferUseCase?.executeOffers(dateFrom: self.trip?.tripProfile.arrivalDate?.date, dateTo: self.trip?.tripProfile.departureDate?.date, northEast: ne, southWest: sw, typeId: nil, excludeOptIn: false) { [weak self] (result) in
            switch result {
            case .success(let offers):
                let poiIds = offers.map { $0.poiId}
                self?.searchPoisWithOffers(poiIds: poiIds)
            case .failure(let error):
                self?.delegate?.viewModel(showPreloader: false)
                self?.delegate?.viewModel(error: error)
            }
        }
    }
        
    private func searchPoisWithOffers(poiIds: [String]) {
        
        fetchPoiUseCase?.executeFetchPoi(ids: poiIds) { [weak self] result, pagination in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let pois):
                self?.delegate?.viewModel(searchThisArea: pois, isOffer: true)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        }
    }
}
