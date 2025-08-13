//
//  TRPRestKit.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 22.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//
//
import Foundation


/// The TRPRestKit is a framework that provides access Tripian Api.
///
///  Framework provide you;
///  * Retrieve personal infromation of the given user
///  * Information of City
///  * Type of Cİty
///  * Information of Place
///  * Question of trip
///  * Take a recommendation
///  * User login/register/info
///  * User's trip
///  * Daily Plan
///  * Plan's place
///  * Travel details
///  * NearBy services, and more.
///
/// - See Also: [How to use](https://github.com/Tripian-inc/TRPRestKit)
/// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine)
///
///
/// ```
///
///     TRPClient.start(enviroment: .test, apiKey: <#yourApiKey>)
///
///     TRPRestKit().city(withId:completion:)
///
/// ```
///
/// A `TRPRestKit()` object  defines a single object that user can follow to operate below functions.
/// Typically you do not create instances of this class directly,
/// instead you receive object in completion handler form when you request a call
/// such as `TRPRestKit().city(withId:completion:)` method. However assure that you have provided tripian api key first.
///
// swiftlint:disable all
public class TRPRestKit {
    
    /// **CompletionHandler** is a typealias that provides result and error when the request is completed.
    /// - Parameters:
    ///   - result: Any Object that will be returned when the result comes.
    ///   - error: NSError that will be returned when there is an error.
    public typealias CompletionHandler = (_ result: Any?, _ error: NSError?) -> Void
    
    /// **CompletionHandlerWithPagination** is a typealias that provides result and error and pagination when the request is completed.
    /// - Parameters:
    ///   - result: Any Object that will be returned when the result comes.
    ///   - error: NSError that will be returned when there is an error.
    ///   - pagination: Pagination object that will be returned to give whether requested operation is completed or continued.
    public typealias CompletionHandlerWithPagination = (_ result: Any?, _ error: NSError?, _ pagination: Pagination?) -> Void
    
    private var completionHandler: CompletionHandler?
    private var completionHandlerWithPagination: CompletionHandlerWithPagination?
    private(set) var queue: DispatchQueue = .main
    
    
    fileprivate func postData(result: Any?, pagination: Pagination? = Pagination.completed) {
        queue.async {
            if let comp = self.completionHandler {
                comp(result, nil)
            } else if let withPagination = self.completionHandlerWithPagination {
                withPagination(result, nil, pagination)
            }
        }
    }
    
    fileprivate func postError(error: NSError?, pagination: Pagination? = Pagination.completed) {
        queue.async {
            if let error = error, error.description.contains("is expired") {
                return
            }
            if let comp = self.completionHandler {
                comp(nil, error)
            } else if let full = self.completionHandlerWithPagination {
                full(nil, error, pagination)
            }
        }
    }
    
    private func parseAndPost<T: Decodable>(_ parser: T.Type, _ result: Any?, _ error: NSError?, _ pagination: Pagination?) {
        if let error = error {
            self.postError(error: error)
            return
        }
        if let serviceResult = result as? T{
            self.postData(result: serviceResult)
        }else {
            self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
        }
    }
    
    private func genericParseAndPost<T: Decodable>(_ parser: T.Type, _ result: Any?, _ error: NSError?, _ pagination: Pagination?) {
        if let error = error {
            self.postError(error: error)
            return
        }
        if let serviceResult = result as? TRPGenericParser<T>, let data = serviceResult.data{
            self.postData(result: data)
        }else {
            self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
        }
    }
    
    
    public init(queue: DispatchQueue = .main) {
        self.queue = queue
    }
    
}

// MARK: - Cities Services
extension TRPRestKit {
    //TODO: Cities -> Burada completion handler larin isminin hep ayni olmasi lazim
    
    /// Obtain the list of all available cities with given limit, isAutoPagination(Optional) and completionHandler parameters.
    ///
    /// - Parameters:
    ///     - limit: Number of city that will be given.
    ///     - isAutoPagination: Boolean value whether pagination is required, default value is true.
    ///     - completion: A closer in the form of CompletionHandlerWithPagination will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPCityInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#get-all-available-cities)
    public func cities(limit: Int? = nil, isAutoPagination: Bool? = true, completion: @escaping CompletionHandlerWithPagination) {
        //Fixme: - autoPagination eklenebilir.
        self.completionHandlerWithPagination = completion
        citiesServices(id: nil, limit: limit, autoPagination: isAutoPagination)
    }
    
    /// Obtain the list of all available shorex cities with given limit, isAutoPagination(Optional) and completionHandler parameters.
    ///
    /// - Parameters:
    ///     - limit: Number of city that will be given.
    ///     - isAutoPagination: Boolean value whether pagination is required, default value is true.
    ///     - completion: A closer in the form of CompletionHandlerWithPagination will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPCityInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#get-all-available-cities)
    public func shorexCities(completion: @escaping CompletionHandlerWithPagination) {
        //Fixme: - autoPagination eklenebilir.
        self.completionHandlerWithPagination = completion
        citiesServices(isShorex: true)
    }
    
    /// Obtain the requested city with given cityId and completion parameters.
    ///
    /// Obtain information (such as ) on a specific city. Returned results include city_id, featured image, coordinates, country and continent.
    ///
    /// - Parameters:
    ///     - id: City Id that will be the id of required city.
    ///     - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPCityInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#get-details-of-a-city)
    public func city(with id: Int, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        citiesServices(id: id)
    }
    
    /// Obtain the requested city with given user location and completionHandler parameters.
    ///
    /// The nearest city is found by requested location will be returned. Returned results include city_id, featured image, coordinates, country and continent.
    ///
    /// - Parameters:
    ///   - location: TRLocation object that will be given.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPCityInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#find-city-by-coordinates)
    public func city(with location: TRPLocation, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        citiesServices(location: location)
    }
    
    /// Obtain the list of all available cities with given url and completion parameters.
    ///
    /// All the available cities from the requested url will be given in the form of CompletionHandlerWithPagination.
    ///
    /// - Parameters:
    ///   - url: url that returned from Pagination
    ///   - completion: A closer in the form of CompletionHandlerWithPagination will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPCityInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#get-all-available-cities)
    public func cities(url: String, completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        citiesServices(id: nil, url: url)
    }
    
    /// A services which will be used in cities services, manages all task connecting to remote server.
    ///
    /// - Parameters:
    ///   - id: Id of the city (Optional).
    ///   - url: url that will be returned from Pagination (Optional).
    ///   - location: User's current location (Optional).
    ///   - limit: number of city list to display (Optional).
    ///   - autoPagination: bool value to declare whether pagination is requested or not (Optional).
    private func citiesServices(id: Int? = nil,
                                url: String? = nil,
                                location: TRPLocation? = nil,
                                limit: Int? = nil,
                                autoPagination: Bool? = true,
                                isShorex: Bool = false) {
        
        let cityService = createCitiesServices(id: id, link: url, location: location, limit: limit, autoPagination: autoPagination, isShorex: isShorex)
        guard let service = cityService else {return}
        if let autoPagination = autoPagination {
            service.isAutoPagination = autoPagination
        }
        service.completion = { (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPCityJsonModel {
                if let cities = serviceResult.data {
                    if id != nil || location != nil {
                        if let city = cities.first {
                            self.postData(result: city, pagination: pagination)
                            return
                        }
                    } else {
                        self.postData(result: cities, pagination: pagination)
                        return
                    }
                }
            }
            self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
        }
        
        if let link = url {
            service.connection(link)
        } else {
            service.connection()
        }
    }
    
    private func createCitiesServices(id: Int? = nil,
                                      link: String? = nil,
                                      location: TRPLocation? = nil,
                                      limit: Int? = 1000,
                                      autoPagination: Bool? = true,
                                      isShorex: Bool = false) -> TRPCities? {
        var cityService: TRPCities?
        if id == nil && location == nil && link == nil {
            cityService = TRPCities()
        } else if let id = id {
            cityService = TRPCities(cityId: id)
        } else if let location = location {
            cityService = TRPCities(location: location)
        } else if limit != nil {
            cityService = TRPCities()
        }
        cityService?.limit = limit
        if isShorex {
            cityService?.setForShorex()
        }
        return cityService
    }
    
}

// MARK: - Poi Categories Services
extension TRPRestKit {
    
    /// Obtain the list of all categories, such as attractions, restaurants, cafes, bars,
    /// religious places, cool finds, shopping centers, museums, bakeries and art galleries. Returned results include category ids.
    ///
    /// Poi Category is used during Add Place List operations (such as: Eat&Drink, Attractions, ...etc.).
    /// PoiCategory can be matched with **Place.categories**.
    ///
    /// - Parameters:
    ///     - completion: A closer in the form of CompletionHandlerWithPagination will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPCategoryInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine-places-of-interest)
    public func poiCategory(completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        poiCategoryServices(id: nil)
    }
    
    /// A services which will be used in place of interests category services, manages all task connecting to remote server.
    ///
    /// - Parameters:
    ///     - id: id of the Category (Optional).
    private func poiCategoryServices(id: Int?) {
        let poiService = TRPPoiCategoryService()
        poiService.completion = {   (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            guard let serviceResult = result as? TRPPoiCategoryJsonModel, let types = serviceResult.data else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
                return
            }
            self.postData(result: types, pagination: pagination)
        }
        poiService.connection()
    }
}

// MARK: - Poi Services
extension TRPRestKit {
    
    
    public func poi(poiId: String,
                    completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        
        poiServices(poiId: poiId)
        
    }
    
    
    public func poi(cityId: Int,
                    search: String? = nil,
                    poiIds: [String]? = nil,
                    poiCategoies: [Int]? = nil,
                    mustTryIds: [Int]? = nil,
                    distance: Float? = nil,
                    bounds: LocationBounds? = nil,
                    limit: Int? = nil,
                    page: Int? = nil,
                    autoPagination: Bool = false,
                    completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        
        poiServices(cityId: cityId,
                    search: search,
                    poiIds: poiIds,
                    poiCategoies: poiCategoies,
                    mustTryIds: mustTryIds,
                    distance: distance,
                    bounds: bounds,
                    limit: limit,
                    page: page,
                    autoPagination: autoPagination)
        
    }
    
    public func poi(coordinate: TRPLocation,
                    cityId: Int? = nil,
                    search: String? = nil,
                    poiIds: [String]? = nil,
                    poiCategoies: [Int]? = nil,
                    mustTryIds: [Int]? = nil,
                    distance: Float? = nil,
                    bounds: LocationBounds? = nil,
                    limit: Int? = nil,
                    page: Int? = nil,
                    autoPagination: Bool = false,
                    completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        
        poiServices(cityId:cityId,
                    coordinate: coordinate,
                    search: search,
                    poiIds: poiIds,
                    poiCategoies: poiCategoies,
                    mustTryIds: mustTryIds,
                    distance: distance,
                    bounds: bounds,
                    limit: limit,
                    page: page,
                    autoPagination: autoPagination)
    }
    
    
    public func poi(url: String, limit: Int? = nil, page: Int? = nil, completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        
        poiServices(url: url)
    }
    
    
    /// A services which will be used in place of interests services, manages all task connecting to remote server.
    ///
    /// - Parameters:
    ///   - placeIds: Place id
    ///   - cities: cities Id
    ///   - limit:  number of record to display
    ///   - location: user current location
    ///   - distance: limit that location and distance between
    ///   - typeId: CategoryId
    ///   - typeIds: CategoriesIds
    ///   - url: url for Pagination
    ///   - searchText: Search text parameter for tags or places name
    ///   - cityId: CityId
    ///   - autoPagination: AutoCompletion patameter
    private func poiServices(poiId: String? = nil,
                             cityId: Int? = nil,
                             coordinate: TRPLocation? = nil,
                             search: String? = nil,
                             poiIds: [String]? = nil,
                             poiCategoies: [Int]? = nil,
                             mustTryIds: [Int]? = nil,
                             distance: Float? = nil,
                             bounds: LocationBounds? = nil,
                             limit: Int? = nil,
                             page: Int? = nil,
                             autoPagination: Bool = false,
                             url: String? = nil
    ) {
        
        var services: TRPPoiService?
        if let poiId = poiId {
            services = TRPPoiService(poiId: poiId)
        }else if let coordinate = coordinate {
            services = TRPPoiService(coordinate: coordinate)
        }else if let cityId = cityId {
            services = TRPPoiService(cityId: cityId)
        }else if url != nil {
            services = TRPPoiService()
        }
        
        guard let service = services else {return}
        service.cityId = cityId
        service.bounds = bounds
        service.coordinate = coordinate
        service.distance = distance
        service.searchText = search
        service.placeIds = poiIds
        service.mustTryIds = mustTryIds
        service.poiCategories = poiCategoies
        if let limit, let page {
            service.limit = limit
            service.page = page
        }
        
        
        service.isAutoPagination = autoPagination
        service.completion = {    (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPPoiJsonModel {
                if let places = serviceResult.data {
                    self.postData(result: places, pagination: pagination)
                    return
                }
            }
            self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
        }
        
        if let link = url {
            service.connection(link)
        } else {
            service.connection()
        }
    }
    
    
    
}

// MARK: - Question Services
extension TRPRestKit {
    
    /// Returns question array which will be used when creating a trip by requested city Id.
    ///
    /// - Parameters:
    ///   - cityId: Id of the requested City.
    ///   - type: type is an enumaration value that can be `trip` or `profile`.
    ///   Both `trip` and `profile` types are used when creating a trip. `profile` type  is used in user's profile questions.
    ///   - language: language is a String value to declare returned questions language (Optional).
    ///   Currently `French` and `English` are available.
    ///   - completion: A closer in the form of CompletionHandlerWithPagination will be called after request is completed.
    ///  - Important: Completion Handler is an any object which needs to be converted to **[TRPTripQuestionInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine-trip-planner)
    public func questions(withCityId cityId: Int,
                          type: TRPQuestionCategory? = .trip,
                          completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        questionServices(cityId: cityId, type: type)
    }
    
    /// Returns question array with type, language and completion handler parameters which will be used during creating trips.
    ///
    /// - Parameters:
    ///   - cityId: Id of the requested City.
    ///   - type: type is an enumaration value that can be `trip` or `profile`.
    ///   Both `trip` and `profile` types are used when creating a trip. `profile` type  is used in user's profile questions.
    ///   - language: language is a String value to declare returned questions language (Optional).
    ///   Currently `French` and `English` are available.
    ///   - completion: A closer in the form of CompletionHandlerWithPagination will be called after request is completed.
    ///  - Important: Completion Handler is an any object which needs to be converted to **[TRPTripQuestionInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine-trip-planner)
    public func questions(type: TRPQuestionCategory? = .profile,
                          completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        questionServices(type: type)
    }
    
    /// A services which will be used in question services, manages all task connecting to remote server.
    ///
    /// - Parameters:
    ///   - cityId: id of city
    ///   - questionId: id of question
    ///   - type: type of request. You can use Profile when opening add place in localy mode. You have to use Profile and Trip when creating a trip.
    private func questionServices(cityId: Int? = nil,
                                  type: TRPQuestionCategory? = nil) {
        
        var questionService: TRPQuestionService?
        if let cityId = cityId {
            questionService = TRPQuestionService(cityId: cityId)
        } else {
            questionService = TRPQuestionService(tripType: type ?? .trip)
        }
        
        guard let services = questionService else {return}
        services.tripType = type ?? .trip
        services.completion = {   (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            guard let serviceResult = result as? TRPQuestionJsonModel, let questions = serviceResult.data else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
                return
            }
            
            self.postData(result: questions, pagination: pagination)
        }
        services.connection()
    }
    
}

// MARK: - Quick Recommendation
extension TRPRestKit {
    
    /// Returns TRPRecommendationInfoJsonModel list generated by requested TRPRecommendationSettings object.
    ///
    /// `TRPRecommendationSettings(cityId:)` declaration can be used in `Localy Mode`.
    ///  However, in `Trip Mode`,  usage with `TRPRecommendationSettings(hash:)` declaration is suggested.
    ///
    /// - Parameters:
    ///      - settings: A TRPRecommendationSettings object which is retrieved by Recommendation Engine.
    ///      - autoPagination: bool value to declare whether pagination is requested or not (Optional), in a detailed manner,
    ///      if the autopagination is set to `true`, next url will be continued.
    ///      If autopagination is set to `false`, next url will not be continued.
    ///      To call **poi(url:complation:)**, `pagination.nextlink` must be used.
    ///      - completion: A closer in the form of CompletionHandlerWithPagination will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPRecommendationInfoJsonModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine-quick-recommendations)
    public func quickRecommendation(settings: TRPRecommendationSettings, autoPagination: Bool = true, completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        recommendationServices(settings: settings, autoPagination: autoPagination)
    }
    
    /// A services which will be used in recommendation services, manages all task connecting to remote server.
    private func recommendationServices(settings: TRPRecommendationSettings, autoPagination: Bool) {
        let recommendationService = TRPRecommendation(settings: settings)
        recommendationService.isAutoPagination = autoPagination
        recommendationService.completion = { (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            recommendationService.completion = { result, error, pagination in
                self.genericParseAndPost([TRPRecommendationInfoJsonModel].self, result, error, pagination)
            }
        }
        recommendationService.connection()
    }
    
}

// MARK: - USER
// MARK: Login
extension TRPRestKit {
    
    /// Obtain the access token for API calls that require user identification.
    /// When login operation is successful, TRPUserPersistent object is saved in user accessToken.
    ///
    ///
    /// - Parameters:
    ///   - userName: Username of the user
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPLoginInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-login-as-a-user-)
    public func login(withUserName userName: String, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        let params = ["username": userName]
        loginServices(parameters: params)
    }
    
    /// Obtain the access token for API calls that require user identification.
    /// When login operation is successful, TRPUserPersistent object is saved in user accessToken.
    ///
    ///
    /// - Parameters:
    ///   - parameters: Custom user parameters such as ["username": "abcd", "password":"1234"], it depend on server type.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPLoginInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-login-as-a-user-)
    public func login(with parameters: [String: String], completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        loginServices(parameters: parameters)
    }
    
    public func login(withEmail email: String,
                      password: String,
                      device: TRPDevice? = nil,
                      completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        var params = [String: Any]()
        params["email"] = email
        params["password"] = password
        var _device: TRPDevice
        if device == nil {
            _device = TRPDeviceModel().convertToTRPDevice()
        } else {
            _device = device!
        }
        params["device"] = _device.params()
        loginServices(parameters: params)
    }
    
    private func loginServices(parameters: [String: Any]) {
        let loginService: TRPLogin? = TRPLogin(parameters: parameters)
        guard let service = loginService else {return}
        service.completion = {    (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPGenericParser<TRPLoginInfoModel> {
                if let data = serviceResult.data {
                    self.saveToken(TRPToken(login: data))
                }
                self.postData(result: serviceResult.data, pagination: pagination)
            } else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        service.connection()
    }
    
    /// User logout. TRPUserPersistent removes all accessToken.
    public func logout(completion: @escaping CompletionHandler) {
        completionHandler = completion
        logoutService()
    }
    
    private func logoutService() {
        let logoutService = TRPLogOutServices()
        logoutService.completion = { (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPParentJsonModel {
                TRPUserPersistent.remove()
                self.postData(result: serviceResult, pagination: pagination)
            } else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        logoutService.connection()
    }
    
}

// MARK: Guest Login
extension TRPRestKit {
    public func guestLogin(firstName: String = "Guest",
                           lastName: String = "User",
                           email: String? = nil,
                           password: String = "Tripian1234",
                           device: TRPDevice? = nil,
                           completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        var _device = device
        var _email: String
        if device == nil {
            _device = TRPDeviceModel().convertToTRPDevice()
        }
        if email == nil {
            _email = "\(TRPDeviceModel.getUUID())@tripianguest.com"
        } else {
            _email = email!
        }
        
        guestLoginServices(email: _email, password: password, firstName: firstName, lastName: lastName, device: _device)
    }
    
    private func guestLoginServices(email: String,
                                    password: String,
                                    firstName: String,
                                    lastName: String,
                                    device: TRPDevice? = nil) {
        let services = TRPGuestLogin(email: email,
                                     password: password,
                                     firstName: firstName,
                                     lastName: lastName,
                                     device: device)
        
        services.completion = { (result, error, _) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let registerResult = result as? TRPLoginJsonModel {
                self.saveToken(TRPToken(login: registerResult.data))
                self.postData(result: registerResult.data)
            }else if let serviceResult = result as? TRPTestUserInfoJsonModel {
                self.postData(result: serviceResult.data)
            } else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        services.connection()
    }
}

// MARK: Social Login
extension TRPRestKit {
    public func socialLogin(device: TRPDevice? = nil,
                            completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        var params = [String: Any]()
        if let device = device, let deviceParams = device.params() {
            params["device"] = deviceParams
        }
        socialLoginServices(parameters: params)
        
    }
    
    private func socialLoginServices(parameters: [String: Any]) {
        let socialLoginService: TRPSocialLogin? = TRPSocialLogin(parameters: parameters)
        guard let service = socialLoginService else {return}
        service.completion = {    (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPGenericParser<TRPSocialLoginInfoModel> {
                TRPUserPersistent.saveSocialLogin()
                self.postData(result: serviceResult.data, pagination: pagination)
            } else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        service.connection()
    }
}

// MARK: User Register
extension TRPRestKit {
    
    /// Create a new user (customer) by posting the required parameters indicated below. No extra step needed to active the new user.
    /// Tripian Api generates a `userName` automatically refer to user's email address.
    ///
    /// - Parameters:
    ///   - email: Username of the user which usually refers to email address of the user.
    ///   - password: Password of the user.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPRegisterUserInfo** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-register-a-user-)
    public func register(userName: String, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
//        userRegisterServices(userName: userName)
    }
    
    //RETURN TRPUserInfoModel
    public func register(email: String,
                         password: String,
                         firstName: String,
                         lastName: String,
                         age: Int? = nil,
                         answers: [Int]? = nil,
                         dateOfBirth: String? = nil,
                         device: TRPDevice? = nil,
                         completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        userRegisterServices(email: email, password: password, firstName: firstName, lastName: lastName, age: age, answers: answers, dateOfBirth: dateOfBirth, device: device)
    }
    
    /// Obtain personal user information (must be logged in with access token), such as user id, e-mail, and preferences.
    ///
    /// - Parameters:
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPUserInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-get-current-user-information)
    public func userInfo(completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        userInfoServices(type: .getInfo)
    }
    
    /// A services which will be used in user register services, manages all task connecting to remote server.
    
    private func userRegisterServices(email: String,
                                      password: String,
                                      firstName: String,
                                      lastName: String,
                                      age: Int? = nil,
                                      answers: [Int]? = nil,
                                      dateOfBirth: String? = nil,
                                      device: TRPDevice? = nil) {
//        var services: TRPUserRegister?
//        if userName != nil {
//            services = TRPUserRegister(userName: userName)
//        }else if let email = email, let password = password {
        let services = TRPUserRegister(email: email,
                                       password: password,
                                       firstName: firstName,
                                       lastName: lastName,
                                       answers: answers,
                                       age: age,
                                       dateOfBirth: dateOfBirth,
                                       device: device)
//        }
        
//        guard let mServices = services else { return }
        services.completion = { (result, error, _) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let registerResult = result as? TRPLoginJsonModel {
                self.saveToken(TRPToken(login: registerResult.data))
                self.postData(result: registerResult.data)
            }else if let serviceResult = result as? TRPTestUserInfoJsonModel {
                self.postData(result: serviceResult.data)
            } else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        services.connection()
    }
    
}

// MARK: Refresh Token
extension TRPRestKit {
    public func refreshToken(_ refreshToken: String, device: TRPDevice? = nil, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        refreshTokenService(refreshToken, device: device)
    }
    ///RETURN TRPRefreshTokenInfoModel
    private func refreshTokenService(_ refreshToken: String, device: TRPDevice? = nil) {
        let service = TRPRefreshTokenService(refreshToken: refreshToken, device: device)
        service.completion = {result, error, _ in
            if let error = error {
                self.postError(error: error)
                return
            }
            
            if let result = result as? TRPGenericParser<TRPRefreshTokenInfoModel>, let data = result.data {
                
                var tokenInfo = TRPToken(refresh: data)
                tokenInfo.refreshToken = refreshToken
                self.saveToken(tokenInfo)
                self.postData(result: data)
            } else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        service.connection()
    }
}

// MARK: Update User Info
extension TRPRestKit {
    
    /// Update user information (must be logged in with access token), such as user id, e-mail, and preferences.
    /// So that, the updated answers will effect the recommendation engine's work upon user's preferences.
    /// After updating user info, future trips of the user will be affected.
    ///
    /// - Parameters:
    ///   - firstName: A String which refers to first name of the user (Optional).
    ///   - lastName: A String which refers to last name of the user (Optional).
    ///   - age: An Integer which refers to age of the user (Optional).
    ///   - answers: An Integer array which refers to User preferences (Optional).
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPUserInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-update-current-user-information)
    public func updateUserInfo(firstName: String? = nil,
                               lastName: String? = nil,
                               password: String? = nil,
                               dateOfBirth: String? = nil,
                               answers: [Int]? = nil,
                               completion: @escaping CompletionHandler) {
        completionHandler = completion
        userInfoServices(firstName: firstName,
                         lastName: lastName,
                         dateOfBirth: dateOfBirth,
                         answers: answers,
                         password: password,
                         type: .updateInfo)
    }
    
    /// Update user preferences (must be logged in with access token).
    /// So that, the updated answers will effect the recommendation engine's work upon user's preferences.
    /// After updating user info, future trips of the user will be affected.
    ///
    /// This method is used in editing only user preferences, first name and last name of the user will not be affected.
    ///
    /// - Parameters:
    ///   - answers: An Integer array which refers to User preferences.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPUserInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-update-current-user-information)
    public func updateUserAnswer(answers: [Int], completion: @escaping CompletionHandler) {
        completionHandler = completion
        userInfoServices(answers: answers, type: .updateAnswer)
    }
    
    /// A services which will be used in user info services, manages all task connecting to remote server.
    private func userInfoServices(firstName: String? = nil,
                                  lastName: String? = nil,
                                  dateOfBirth: String? = nil,
                                  answers: [Int]? = nil,
                                  password: String? = nil,
                                  type: TRPUserInfoServices.ServiceType) {
        var infoService: TRPUserInfoServices?
        
        if type == .getInfo {
            infoService = TRPUserInfoServices(type: .getInfo)
        } else if type == .updateAnswer {
            if let answers = answers {
                infoService = TRPUserInfoServices(answers: answers)
            }
        } else if type == .updateInfo {
            infoService = TRPUserInfoServices(firstName: firstName,
                                              lastName: lastName,
                                              dateOfBirth: dateOfBirth,
                                              password: password,
                                              answers: answers)
        }
        
        guard let services = infoService else {return}
        
        services.completion = { (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPUserInfoJsonModel {
                TRPUserPersistent.saveUserEmail(serviceResult.data.email)
                self.postData(result: serviceResult.data, pagination: pagination)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        
        services.connection()
    }
    
}

//MARK: User Delete
extension TRPRestKit {
    public func deleteUser(completion: @escaping CompletionHandler) {
        completionHandler = completion
        deleteUserService()
    }
    
    private func deleteUserService() {
        let deleteService = TRPUserDeleteServices()
        deleteService.completion = { result, error, pagination in
//            self.parseAndPost(TRPParentJsonModel.self, result, error, pagination)
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPParentJsonModel {
                TRPUserPersistent.remove()
                self.postData(result: serviceResult, pagination: pagination)
            } else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        deleteService.connection()
    }
}

//MARK: Reset Password
extension TRPRestKit {
    public func sendEmailForResetPassword(email: String, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        self.resetPasswordService(email: email)
    }
    public func resetPassword(password: String, hash: String,completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        self.resetPasswordService(password: password, hash: hash)
    }
    
    private func resetPasswordService(email: String? = nil, password: String? = nil, hash: String? = nil) {
        var service: TRPResetPasswordServices?
        if let email = email {
            service = TRPResetPasswordServices(email: email)
        } else if let password = password, let hash = hash {
            service = TRPResetPasswordServices(password: password, hash: hash)
        }
        guard let service = service else { return }

        service.completion = { result, error, pagination in
            self.parseAndPost(TRPParentJsonModel.self, result, error, pagination)
        }
        service.connection()
    }
}

// MARK: - Companions.
extension TRPRestKit {
    
    /// Add companion by adding name(Optional), age(Optional), Answers(Optional) and completion parameters.
    ///
    ///
    /// - Parameters:
    ///   - name: A String that refers to name of the companion
    ///   - answers: An Integer array that refers to preferences of the companion
    ///   - age: An Integer that refers to age of the companion (Optional).
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPCompanionModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-add-companion)
    public func addCompanion(name: String,
                             answers: [Int],
                             age: Int,
                             title: String?,
                             completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        companionPutPostService(name: name, title: title, answers: answers, age: age)
    }
    
    /// Update companion information (must be logged in with access token), such as name and answers
    ///
    /// - Parameters:
    ///   - id: An Integer that refers to id of the given companion.
    ///   - name: A String that refers to name of the given companion (Optional).
    ///   - age: An Integer that refers to age of the given companion (Optional).
    ///   - answers: An Integer array that refers to preferences of the given companion (Optional).
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPCompanionModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-update-companion)
    public func updateCompanion(id: Int,
                                name: String,
                                answers: [Int]?,
                                age: Int?,
                                title: String?,
                                completion: @escaping CompletionHandler) {
    self.completionHandler = completion
        companionPutPostService(id: id, name: name, title: title, answers: answers, age: age)
    }
    
    /// Delete companion by adding companionId and completion parameters.
    ///
    /// - Parameters:
    ///   - companionId: An Integer that refers to id of the given companion that is going to be deleted.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPCompanionModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-update-companion)
    public func removeCompanion(companionId: Int, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        companionDeleteService(id: companionId)
    }
    
    private func companionDeleteService(id: Int) {
        let service = TRPCompanionDeleteServices(id: id)
        service.completion = { result, error, pagination in
            self.parseAndPost(TRPParentJsonModel.self, result, error, pagination)
        }
        service.connection()
    }
    
    /// Obtain user companions (must be logged in with access token), such as companion name, answers.
    ///
    /// - Parameters:
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important:Completion Handler is an any object which needs to be converted to **[TRPCompanionModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-get-companions)
    public func getUsersCompanions(completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        getCompanionService()
    }
    
    internal func getCompanionService() {
        let service = TRPGetCompanionServices()
        service.completion = { result, error, pagination in
            self.genericParseAndPost([TRPCompanionModel].self, result, error, pagination)
        }
        service.connection()
    }
    
    private func companionPutPostService(id: Int? = nil, name: String, title: String?, answers: [Int]?, age:Int? = nil) {
        let service = TRPCompanionPutPostServices(companionId: id, name: name, answers: answers,title: title, age: age)
        service.completion = { result, error, pagination in
            self.genericParseAndPost(TRPCompanionModel.self, result, error, pagination)
        }
        service.connection()
    }
    
}

// MARK: - Favorites of User's Poi.
extension TRPRestKit {
    
    /// Add user's favorite Place of Interest.
    ///
    /// - Parameters:
    ///   - cityId: An Integer that refers to Id of city where the poi is located.
    ///   - poiId: A String that refers to Id of the given place.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPFavoritesInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-add-delete-favorite)
    public func addUserFavorite(poiId: String, completion: @escaping CompletionHandler) {
        completionHandler = completion
        userFavoriteServices(poiId: poiId, mode: .add)
    }
    
    /// Get user all favorite place of interests list
    ///
    /// - Parameters:
    ///   - cityId: An Integer that refers to Id of city where the poi is located.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPFavoritesInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-get-user-favorites)
    public func getUserFavorite(cityId: Int, completion: @escaping CompletionHandler) {
        completionHandler = completion
        userFavoriteServices(cityId: cityId, mode: .get)
    }
    
    /// Delete user's favorite Place of Interest.
    ///
    /// - Parameters:
    ///   - cityId: An Integer that refers to Id of city where the poi is located.
    ///   - poiId: A String that refers to Id of the given place.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPParentJsonModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#how-to-add-delete-favorite)
    public func deleteUserFavorite(favoriteId: Int, completion: @escaping CompletionHandler) {
        completionHandler = completion
        userFavoriteServices(favoriteId: favoriteId, mode: .delete)
    }
    
    /// A services which will be used in users favorite place of interests, manages all task connecting to remote server.
    private func userFavoriteServices(cityId: Int? = nil, poiId: String? = nil, favoriteId: Int? = nil, mode: TRPUserFavorite.Mode) {
        
        var favoriteService: TRPUserFavorite?
        if mode == .add {
            if let poi = poiId {
                favoriteService = TRPUserFavorite(poiId: poi, type: mode)
            }
        } else if let cityId = cityId, mode == .get{
            favoriteService = TRPUserFavorite(cityId: cityId)
        } else if mode == .delete {
            if let fav = favoriteId {
                favoriteService = TRPUserFavorite(favoriteId: fav)
            }
        }
        
        guard let services = favoriteService else {return}
        services.completion = {   (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            
            if mode == .delete {
                if let resultService = result as? TRPParentJsonModel {
                    self.postData(result: resultService)
                    return
                }
            } else {
                if let resultService = result as? TRPFavoritesJsonModel {
                    if mode == .add {
                        if let first = resultService.data?.first {
                            self.postData(result: first)
                        }else {
                            self.postData(result: resultService.data)
                        }
                        
                        return
                        
                    } else {
                        self.postData(result: resultService.data, pagination: pagination)
                        return
                    }
                }
            }
            
            self.postError(error: TRPErrors.wrongData as NSError)
        }
        services.connection()
    }
}

// MARK: - User Trips
extension TRPRestKit {
    
    /// Obtain the list of user trips with given limit, and completionHandler parameters.
    ///
    /// - Parameters:
    ///   - limit: An Integer value that refers to the number of trips which will be presented(Optional, default value is 100).
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPUserTripInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#see-details-of-a-trip)
    public func userTrips(limit: Int? = 100, completion: @escaping CompletionHandlerWithPagination) {
        completionHandlerWithPagination = completion
        userTripsServices(limit: limit ?? 100)
    }
    
    public func userTrips(from: String? = nil, to: String? = nil, completion: @escaping CompletionHandlerWithPagination) {
        completionHandlerWithPagination = completion
        userTripsServices(from: from, to: to, limit: 100)
    }
    
    /// A services which will be used in users trips, manages all task connecting to remote server.
    private func userTripsServices(from:String? = nil, to: String? = nil, limit: Int) {
        var tripService: TRPUserTripsServices?
        if let from = from {
            tripService = TRPUserTripsServices(from: from)
        }else if let to = to {
            tripService = TRPUserTripsServices(to: to)
        }
        
        if tripService == nil {
            tripService = TRPUserTripsServices()
        }
        
        tripService!.limit = limit
        tripService!.completion = { result, error, pagination in
            self.genericParseAndPost([TRPUserTripInfoModel].self, result, error, pagination)
        }
        tripService!.connection()
    }
    
}

// MARK: - Constants
extension TRPRestKit {
    
    /// Obtain the list of constants that are used in Tripian Mobile Apps such as required max day between trips.
    ///
    /// - Parameters:
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    public func getConstants(completion: @escaping CompletionHandler) {
        completionHandler = completion
        constantServices()
    }
    
    /// A services which will be used in constant services, manages all task connecting to remote server.
    private func constantServices() {
        let constantsService = TRPConstantsServices()
        constantsService.completion = {   (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceReuslt = result as? TRPConstantsParentJsonModel {
                self.postData(result: serviceReuslt.data?.constants)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        constantsService.connection()
    }
    
}

// MARK: - Version
extension TRPRestKit {
    
    /// Obtain the list of versions that are used in Tripian Mobile Apps such as required min frameworks.
    ///
    /// - Parameters:
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    public func getVersion(completion: @escaping CompletionHandler) {
        completionHandler = completion
        versionServices()
    }
    
    /// A services which will be used in version services, manages all task connecting to remote server.
    private func versionServices() {
        let constantsService = TRPConstantsServices()
        constantsService.completion = {   (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPConstantsParentJsonModel {
                self.postData(result: serviceResult.data?.version)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        constantsService.connection()
    }
    
}

// MARK: - Trip
extension TRPRestKit {
    
    /// Create a trip with given settings and completion handler parameters.
    ///
    /// Values and meanings of generate attribute in of dayplans; 0=not generated yet, 1=generated and recommended, -1=generated but not recommended.
    ///
    /// - Parameters:
    ///   - settings: TRPTripSettings object that includes settings for the trip.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPTripInfoModel** object. You can only generate trips for next two years.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#see-details-of-a-trip)
    public func createTrip(settings: TRPTripSettings, completion: @escaping CompletionHandler) {
        completionHandler = completion
        if let city = settings.cityId, city != 0 {
            createOrEditTripServices(settings: settings)
        }else {
            print("[Error] City Id hash must not be empty")
        }
    }
    
    /// Update trip with given settings and completion handler parameters.
    ///
    /// - Parameters:
    ///   - settings: TRPTripSettings object that includes settings for the updating trip.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPTripInfoModel** object. You can only generate trips for next two years.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#update-a-trip)
    public func editTrip(settings: TRPTripSettings, completion: @escaping CompletionHandler) {
        completionHandler = completion
        if let hash = settings.hash, !hash.isEmpty {
            createOrEditTripServices(settings: settings)
        }else {
            print("[Error] Trip hash must not be empty")
        }
    }
    
    /// A services which will be used for both creating and editing services, manages all task connecting to remote server.
    private func createOrEditTripServices(settings: TRPTripSettings) {
        let programService = TRPProgram(setting: settings)
        programService.completion = { result, error, pagination in
            self.genericParseAndPost(TRPTripModel.self, result, error, pagination)
        }
        programService.connection()
    }
    
    /// Get trip info with given trip hash and completion handler parameters.
    ///
    /// - Parameters:
    ///   - hash: A String value that refers to trip hash.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPTripModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#see-details-of-a-trip)
    public func getTrip(withHash hash: String, completion: @escaping CompletionHandler) {
        completionHandler = completion
        getTripServices(hash: hash)
    }
    
    /// A services which will be used forgetting trip info services, manages all task connecting to remote server.
    private func getTripServices(hash: String) {
        
        let getProgramService = TRPGetTripServices(hash: hash)
        getProgramService.completion = { result, error, pagination in
            self.genericParseAndPost(TRPTripModel.self, result, error, pagination)
        }
        getProgramService.connection()
    }
    
    /// Delete trip info with given trip hash and completion handler parameters.
    ///
    /// - Parameters:
    ///   - hash: A String value that refers to foretold deleting trip hash.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPParentJsonModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#delete-a-trip)
    public func deleteTrip(hash: String, completion: @escaping CompletionHandler) {
        completionHandler = completion
        deleteTripServices(hash: hash)
    }
    
    /// A services which will be used in delete trip services, manages all task connecting to remote server.
    private func deleteTripServices(hash: String) {
        let deleteService = TRPDeleteProgram(hash: hash)
        deleteService.completion = { result, error, pagination in
            self.genericParseAndPost(TRPDeleteUserTripInfo.self, result, error, pagination)
        }
        deleteService.connection()
    }
    
}

// MARK: - Daily Plan
extension TRPRestKit {
    
    /// Obtain daily plan with given daily plan id, and completion parameters.
    ///
    /// Values and meanings of generate attribute in of dayplans; 0=not generated yet, 1=generated and recommended, -1=generated but not recommended.
    ///
    /// - Parameters:
    ///   - id: An Integer value that refers to id of the daily plan.
    ///   - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPDailyPlanInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#day-plans-of-a-trip)
    public func dailyPlan(id: Int, completion: @escaping CompletionHandler) {
        completionHandler = completion
        dailyPlanServices(id: id)
    }
    
    /// A services which will be used in daily plan services, manages all task connecting to remote server.
    private func dailyPlanServices(id: Int) {
        let dailyPlanServices = TRPDailyPlanServices(id: id)
        dailyPlanServices.completion = {   (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPDayPlanJsonModel {
                self.postData(result: serviceResult.data)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        dailyPlanServices.connection()
    }
    
}

// MARK: - NearBy Services
extension TRPRestKit {
    
    /// Obtain plan poi alternative list with given trip hash and completion parameters.
    ///
    /// - Parameters:
    ///    - withHash: A String value that refers to foretold trip hash.
    ///    - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPPlanPointAlternativeInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#alternative-places-suggested-for-trip)
    public func stepAlternatives(withHash hash: String, completion: @escaping CompletionHandler) {
        completionHandler = completion
        planPointAlternative(hash: hash)
    }
    
    /// Obtain plan poi alternative list with given trip hash and completion parameters.
    ///
    /// - Parameters:
    ///    - withDailyPlanId: An Integer that refers to Id of the daily plan.
    ///    - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPPlanPointAlternativeInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#alternative-places-suggested-for-trip)
    public func stepAlternatives(withPlanId id: Int, completion: @escaping CompletionHandler) {
        completionHandler = completion
        planPointAlternative(planId: id)
    }
    
    public func stepAlternatives(stepId id: Int, completion: @escaping CompletionHandler) {
        completionHandler = completion
        planPointAlternative(stepId: id)
    }
    
    /// A services which will be used in plan poi alternative services, manages all task connecting to remote server.
    private func planPointAlternative(hash: String? = nil, stepId: Int? = nil, planId: Int? = nil) {
        var poiAlternativeService: TRPStepAlternativesServices?
        
        if let hash = hash {
            poiAlternativeService = TRPStepAlternativesServices(hash: hash)
        }else if let stepId = stepId {
            poiAlternativeService = TRPStepAlternativesServices(stepId: stepId)
        }else if let planId = planId {
            poiAlternativeService = TRPStepAlternativesServices(planId: planId)
        }
        
        guard let service = poiAlternativeService else {return}
        
        service.completion = { (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPPlanPointAlternativeJsonModel, let data = serviceResult.data {
                self.postData(result: data, pagination: pagination)
                return
            }
            self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
        }
        service.connection()
    }
    
}

// MARK: - Google Auto Complete
extension TRPRestKit {
    
    /// Obtain google place list with given key, text, centerForBoundary,  radiusForBoundary and completion parameters.
    ///
    /// - Parameters:
    ///    - key: A String value that refers to the API Key of Google.
    ///    - text: A String value that refers to search term.
    ///    - center: A TRPLocation object that refers to boundary of City.
    ///    - radius: A Double value which refers to radius for the search area limit.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPGooglePlace]** object.
    public func googleAutoComplete(key: String,
                                   text: String,
                                   centerForBoundary center: TRPLocation? = nil,
                                   radiusForBoundary radius: Double? = nil,
                                   completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        googlePlaceAutoCompleteService(key: key,
                                       text: text,
                                       centerForBoundary: center,
                                       radiusForBoundary: radius)
    }
    public func googleAutoComplete(key: String,
                                   text: String,
                                   boundarySW: TRPLocation?,
                                   boundaryNE: TRPLocation?,
                                   completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        googlePlaceAutoCompleteService(key: key,
                                       text: text,
                                       boundarySW: boundarySW,
                                       boundaryNE: boundaryNE)
    }
    
    /// A services which will be used in google place auto complete services, manages all task connecting to remote server.
    private func googlePlaceAutoCompleteService(key: String,
                                                text: String,
                                                centerForBoundary center: TRPLocation? = nil,
                                                boundarySW: TRPLocation? = nil,
                                                boundaryNE: TRPLocation? = nil,
                                                radiusForBoundary radius: Double? = nil) {
        let autoCOmpleteService = TRPGoogleAutoComplete(key: key, text: text)
        autoCOmpleteService.centerLocationForBoundary = center
        autoCOmpleteService.radiusForBoundary = radius
        autoCOmpleteService.boundarySW = boundarySW
        autoCOmpleteService.boundaryNE = boundaryNE
        autoCOmpleteService.start { (data, error) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let data = data as? [TRPGooglePlace] {
                self.postData(result: data)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
    }
    
}

// MARK: - Google Place
extension TRPRestKit {
    
    ///  Obtain infromation of a place from Google Server with given key, placeId and completion parameters.
    ///
    ///  This function does not require to use Tripian Server. //TODO: Bunu yazmak dogrumu?
    ///
    /// - Parameters:
    ///    - key: A String value that refers to the API Key of Google.
    ///    - id: An Integer value which refers to the Id of Place that registered in Google.
    ///    - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPGooglePlaceLocation** object.
    public func googlePlace(key: String, id: String, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        googlePlaceServices(key: key, placeId: id)
    }
    
    /// A services which will be used in google place services, manages all task connecting to remote server.
    private func googlePlaceServices(key: String, placeId: String) {
        let googlePlaceService = TRPGooglePlaceService(key: key, placeId: placeId)
        googlePlaceService.start { (data, error) in
            if let error = error {
                self.postError(error: error)
                return
            }
            
            if let result = data as? TRPGooglePlaceLocation {
                self.postData(result: result)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
    }
    
}

// MARK: - Problem Categories
extension TRPRestKit {
    
    /// Obtain problem categories, such as incorrect location, incorrect name etc..., with completion handler parameter.
    ///
    /// - Parameters:
    ///    - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **[TRPProblemCategoriesInfoModel]** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#problem-categories)
    public func problemCategories(completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        problemCategoriesService()
    }
    
    /// A services which will be used in problem categories services, manages all task connecting to remote server.
    private func problemCategoriesService() {
        let categoryService = TRPProblemCategories()
        categoryService.completion = { (result, error, _) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPProblemCategoriesJsonModel {
                self.postData(result: serviceResult.datas)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        categoryService.connection()
    }
    
}

// MARK: - Report A problem
extension TRPRestKit {
    
    /// Obtain problem categories, such as incorrect location, incorrect name etc..., with completion handler parameter.
    ///
    /// - Parameters:
    ///    - category: A String value which refers to the category name of the place.
    ///    - message: A String value which refers to the message for the problem of the place.
    ///    - poiId: A String value which refers to the id of the given place.
    ///    - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPReportAProblemInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#report-a-problem)
    public func reportaProblem(category name: String,
                               message msg: String?,
                               poiId poi: String?,
                               completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        reportaProblemService(categoryName: name, message: msg, poiId: poi)
    }
    
    /// A services which will be used in report a problem services, manages all task connecting to remote server.
    private func reportaProblemService(categoryName: String, message: String?, poiId: String?) {
        let reportAProblemService = TRPReportAProblemServices(categoryName: categoryName,
                                                              message: message,
                                                              poiId: poiId)
        reportAProblemService.completion = { result, error, _ in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPReportAProblemJsonModel {
                self.postData(result: serviceResult.data ?? nil)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        reportAProblemService.connection()
    }
}

// MARK: - Update Daily Plan
extension TRPRestKit {
    
    /// Update daily plan hour with given daily plan Id, start time, end time and completion parameters.
    ///
    /// - Parameters:
    ///    - dailyPlanId: An Integer value that refers to the daily plan Id.
    ///    - start: A String value which refers to start time of the daily plan.
    ///    - end: A String value which refers to end time of the daily plan.
    ///    - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPDailyPlanInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#update-daily-plan)
    public func updateDailyPlanHour(dailyPlanId: Int, start: String, end: String, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        updateDailyPlanService(dailyPlanId: dailyPlanId, start: start, end: end)
    }
    
    public func updateDailyPlanStepOrders(dailyPlanId: Int, stepOrders: [Int], completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        updateDailyPlanService(dailyPlanId: dailyPlanId, stepOrders: stepOrders)
    }
    
    /// A services which will be used in daily plan hour services, manages all task connecting to remote server.
    private func updateDailyPlanService(dailyPlanId: Int, start: String? = nil, end: String? = nil, stepOrders: [Int]? = nil) {
        var dailyPlanService = TRPDailyPlanServices(id: dailyPlanId)
        if let start, let end {
            dailyPlanService = TRPDailyPlanServices(id: dailyPlanId, startTime: start, endTime: end)
        }
        if let stepOrders {
            dailyPlanService = TRPDailyPlanServices(id: dailyPlanId, stepOrders: stepOrders)
        }
        dailyPlanService.completion = {   (result, error, pagination) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPDayPlanJsonModel {
                self.postData(result: serviceResult.data)
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        dailyPlanService.connection()
    }
    
}

// MARK: - Export Daily Plan
extension TRPRestKit {
    
    /// Update daily plan hour with given daily plan Id, start time, end time and completion parameters.
    ///
    /// - Parameters:
    ///    - dailyPlanId: An Integer value that refers to the daily plan Id.
    ///    - start: A String value which refers to start time of the daily plan.
    ///    - end: A String value which refers to end time of the daily plan.
    ///    - completion: A closer in the form of CompletionHandler will be called after request is completed.
    /// - Important: Completion Handler is an any object which needs to be converted to **TRPDailyPlanInfoModel** object.
    /// - See Also: [Api Doc](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#update-daily-plan)
    public func exportPlanMap(planId: Int, tripHash: String, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        exportPlanMapService(planId: planId, tripHash: tripHash)
    }
    
    /// A services which will be used in daily plan hour services, manages all task connecting to remote server.
    private func exportPlanMapService(planId: Int, tripHash: String) {
        let exportPlanService = TRPExportPlanServices(planId: planId, tripHash: tripHash)
        exportPlanService.completion = {   (result, error, pagination) in
            self.genericParseAndPost(TRPExportPlanJsonModel.self, result, error, pagination)
        }
        exportPlanService.connection()
    }
    
}

// MARK: - Steps
extension TRPRestKit {
    //Burası silinen Add Plan Poit kısmının yeni hali, ordan alınabiliri
    
    /// Add Plan POI to the daily plan.
    public func addStep(planId: Int, poiId: String, order: Int? = nil, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        stepService(planId: planId, poiId: poiId, order: order)
    }
    
    public func addCustomStep(planId: Int, name: String, address: String, description: String, photoUrl: String?, web: String?, latitude: Double?, longitude: Double?, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        customStepService(planId: planId, name: name, address: address, description: description, photoUrl: photoUrl, web: web, latitude: latitude, longitude: longitude)
    }
    
    public func editStep(stepId: Int,
                         poiId: String,
                         completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        stepService(poiId: poiId, stepId: stepId)
    }
    
    public func editStep(stepId: Int,
                         order: Int,
                         completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        stepService(order: order, stepId: stepId)
    }
    
    public func editStep(stepId: Int,
                         startTime: String,
                         endTime: String,
                         completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        stepService(stepId: stepId, startTime: startTime, endTime: endTime)
    }
    
    public func editStep(stepId: Int,
                         poiId: String,
                         order: Int,
                         completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        stepService(poiId: poiId, order: order, stepId: stepId)
    }
    
    //TODO: - burası doldurulacak
    public func deleteStep(stepId: Int, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        stepDeleteService(stepId: stepId)
    }
    
    private func stepService(planId: Int? = nil, poiId: String? = nil, order:Int? = nil, stepId: Int? = nil, startTime: String? = nil, endTime: String? = nil) {
        var service: TRPStepServices?
        //Edit Step
        if let step = stepId {
            service = TRPStepServices(stepId: step, poiId: poiId, order: order, startTime: startTime, endTime: endTime)
        }else if let planId = planId, let poiId = poiId { //Add Step In Plan
            service = TRPStepServices(planId: planId, poiId: poiId, order: order)
        }
        guard let stepService = service else {
            print("[Error] StepService mustn't be nil")
            return
        }
        stepService.completion = { result, error, pagination in
            self.genericParseAndPost(TRPStepInfoModel.self, result, error, pagination)
        }
        stepService.connection()
    }
    
    private func customStepService(planId: Int, name: String? = nil, address: String? = nil, description: String? = nil, photoUrl: String? = nil, web: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        let service = TRPCustomStepServices(planId: planId, name: name, address: address, description: description, photoUrl: photoUrl, web: web, latitude: latitude, longitude: longitude)
        service.completion = { result, error, pagination in
            self.genericParseAndPost(TRPStepInfoModel.self, result, error, pagination)
        }
        service.connection()
    }
    
    private func stepDeleteService(stepId: Int) {
        let service = TRPDeleteStepService(stepId: stepId)
        service.completion = { result, error, pagination in
            self.parseAndPost(TRPParentJsonModel.self, result, error, pagination)
        }
        service.connection()
    }
    
}

// MARK: - User Reaction
extension TRPRestKit {
    
    // return [TRPReactionModel]
    public func getUserReaction(withTripHash hash: String, completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        getUserReactionService(tripHash: hash)
    }
    
    private func getUserReactionService(tripHash hash: String) {
        let service = TRPGetUserReactionServices(tripHash: hash)
        service.completion = { result, error, pagination in
            self.genericParseAndPost([TRPReactionModel].self, result, error, pagination)
        }
        service.connection()
    }
    
    public func addUserReaction(poiId: String, stepId: Int, reaction: UserReactionType? = nil, comment: String? = nil, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        userReactionService(poiId: poiId, stepId: stepId, reaction: reaction, comment: comment)
    }
    
    public func updateUserReaction(id: Int,
                                   poiId: String? = nil,
                                   stepId: Int? = nil,
                                   reaction: UserReactionType? = nil,
                                   comment: String? = nil,
                                   completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        userReactionService(id: id, poiId: poiId, stepId: stepId, reaction: reaction, comment: comment)
    }
    
    private func userReactionService(id: Int? = nil, poiId: String? = nil, stepId: Int? = nil, reaction: UserReactionType? = nil, comment: String? = nil) {
        var services: TRPUserReactionServices?
        //Update
        if let id = id {
            services = TRPUserReactionServices(id: id, stepId: stepId, poiId: poiId, reaction: reaction, comment: comment)
        } else if let poiId = poiId, let step = stepId {
        //Add
            services = TRPUserReactionServices(stepId: step, poiId: poiId, reaction: reaction, comment: comment)
        }
        guard let service = services else {return}
        service.completion = { result, error, pagination in
            self.genericParseAndPost(TRPReactionModel.self, result, error, pagination)
        }
        service.connection()
    }
    
    public func deleteUserReaction(id: Int, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        deleteUserReactionService(id)
    }
    
    private func deleteUserReactionService(_ reactionId: Int) {
        let deleteService = TRPDeleteUserReactionServices(id: reactionId)
        deleteService.completion = { result, error, pagination in
            self.parseAndPost(TRPParentJsonModel.self, result, error, pagination)
        }
        deleteService.connection()
    }
}

//MARK: - User Reservation
extension TRPRestKit {
    
    // [TRPReservationInfoModel]
    public func getUserReservation(cityId: Int, from: String? = nil, to: String? = nil, provider: String? = nil, limit: Int? = nil, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        getUserReservationServices(cityId: cityId, from: from, to: to, provider: provider, limit: limit)
    }
    
    // [TRPReservationInfoModel]
    public func getUserReservation(tripHash: String, from: String? = nil, to: String? = nil, provider: String? = nil, limit: Int? = nil, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        getUserReservationServices(tripHash: tripHash, from: from, to: to, provider: provider, limit: limit)
    }
    
    // [TRPReservationInfoModel]
    public func getUserReservation(poiId: String, from: String? = nil, to: String? = nil, provider: String? = nil, limit: Int? = nil, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        getUserReservationServices(poiId: poiId, from: from, to: to, provider: provider, limit: limit)
    }
    
    private func getUserReservationServices(cityId: Int? = nil,
                                            tripHash: String? = nil,
                                            poiId: String? = nil,
                                            from: String? = nil,
                                            to: String? = nil,
                                            provider: String? = nil,
                                            limit: Int? = nil) {
        let services = TRPUserReservationServices()
        if let cityId = cityId, cityId != 0 {
            services.cityId = cityId
        }
        
        services.tripHash = tripHash
        services.poiId = poiId
        services.from = from
        services.to = to
        services.provider = provider
        services.limit = limit
        services.completion = { (result, error, pagination) in
            self.genericParseAndPost([TRPReservationInfoModel].self, result, error, pagination)
        }
        services.connection()
    }
    
    //Add
    public func addUserReservation(key: String, provider: String, tripHash: String? = nil, poiId: String? = nil, value: [String : Any]? = nil, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        addUserReservationServices(key: key, provider: provider, tripHash: tripHash, poiId: poiId,value: value)
    }
    
    private func addUserReservationServices(key: String, provider: String, tripHash: String? = nil, poiId: String? = nil, value:[String : Any]? = nil) {
        let service = TRPAddUpadateUserReservationServices(key: key, provider: provider, tripHash: tripHash, poiId: poiId,value: value)
        service.completion = { result, error, pagination in
            self.genericParseAndPost(TRPReservationInfoModel.self, result, error, pagination)
        }
        service.connection()
    }
    
    //Update
    public func updateUserReservation(id: Int,
                                      key: String,
                                      provider: String,
                                      tripHash: String? = nil,
                                      poiId: String? = nil,
                                      value: [String : Any]? = nil,
                                      completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        let service = TRPAddUpadateUserReservationServices(reservationId:id,
                                                           key: key,
                                                           provider: provider,
                                                           tripHash: tripHash,
                                                           poiId: poiId,
                                                           value: value)
        service.completion = { result, error, pagination in
            self.genericParseAndPost(TRPReservationInfoModel.self, result, error, pagination)
        }
        service.connection()
    }
    
    //Delete
    public func deleteUserReservation(id: Int, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        deletePutUserReservationServices(id: id)
    }
    
    private func deletePutUserReservationServices(id: Int) {
        let service = TRPUserReservationDeletePutServices(id: id)
        service.completion = { result, error, pagination in
            self.parseAndPost(TRPParentJsonModel.self, result, error, pagination)
        }
        service.connection()
    }
    
}


//MARK: - Token Controller
extension TRPRestKit {
    public func saveToken(_ token: TRPToken) {
        TripianTokenController().saveTokenInfo(token)
    }
}

//MARK: - Offers
extension TRPRestKit {
    
    public func getOffers(dateFrom: String,
                          dateTo: String,
                          poiIds: [String]?,
                          typeId: [Int]?,
                          boundary: LocationBounds? = nil,
                          page: Int?,
                          limit: Int?,
                          excludeOptIn: Bool?,
                          completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        getOffersService(dateFrom: dateFrom, dateTo: dateTo, poiIds: poiIds, typeId: typeId, boundary: boundary, page: page, limit: limit, excludeOptIn: excludeOptIn)
    }
    
    public func getOffer(id: Int, completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        getOffersService(offerId: id)
    }
    
    private func getOffersService(offerId: Int? = nil,
                                  dateFrom: String? = nil,
                                  dateTo: String? = nil,
                                  poiIds: [String]? = nil,
                                  typeId: [Int]? = nil,
                                  boundary: LocationBounds? = nil,
                                  page: Int? = 1,
                                  limit: Int? = 50,
                                  excludeOptIn: Bool? = false) {
        var service = TRPGetOfferServices()
        if let offerId = offerId {
            service = TRPGetOfferServices(offerId: offerId)
        }
        if let dateFrom = dateFrom, let dateTo = dateTo {
            service = TRPGetOfferServices(dateFrom: dateFrom, dateTo: dateTo)
        }
        service.poiIds = poiIds
        service.typeId = typeId
        service.boundary = boundary
        service.page = page
        service.limit = limit
        service.excludeOptIn = excludeOptIn
        service.completion = { result, error, pagination in
            self.genericParseAndPost([TRPOfferInfoModel].self, result, error, pagination)
        }
        service.connection()
    }
}

//MARK: - Opt-In Offers
extension TRPRestKit {
    
    public func getOptInOffers(dateFrom: String?,
                               dateTo: String?,
                               page: Int?,
                               limit: Int?,
                               completion: @escaping CompletionHandlerWithPagination) {
        self.completionHandlerWithPagination = completion
        getOptInOffersService(dateFrom: dateFrom, dateTo: dateTo, page: page, limit: limit)
    }
    
    private func getOptInOffersService(dateFrom: String? = nil,
                                       dateTo: String? = nil,
                                       page: Int? = 1,
                                       limit: Int? = 50) {
        let service = TRPGetOptInOfferServices(dateFrom: dateFrom, dateTo: dateTo, page: page, limit: limit)
        service.completion = { result, error, pagination in
            self.genericParseAndPost([TRPPoiInfoModel].self, result, error, pagination)
        }
        service.connection()
    }
    
    public func addOptInOffer(offerId: Int,
                              claimDate: String?,
                              completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        optInOffersService(offerId: offerId, claimDate: claimDate, mode: .add)
    }
    
    public func deleteOptInOffer(offerId: Int,
                                 completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        optInOffersService(offerId: offerId, mode: .delete)
    }
    
    private func optInOffersService(offerId: Int,
                                    claimDate: String? = nil,
                                    mode: TRPUserFavorite.Mode) {
        
        var service: TRPOptInOfferServices?
        if mode == .add {
            service = TRPOptInOfferServices(offerId: offerId, claimDate: claimDate)
        } else {
            service = TRPOptInOfferServices(offerId: offerId)
        }
        guard let service = service else {
            return
        }
        
        service.completion = { result, error, pagination in
            self.parseAndPost(TRPParentJsonModel.self, result, error, pagination)
        }
        service.connection()
    }
}


//MARK: - Language Texts
extension TRPRestKit {
    public func getFrontendLanguages(completion: @escaping CompletionHandler) {
        self.completionHandler = completion
        languagesServices()
    }
    
    private func languagesServices() {
        let langugaesService = TRPLanguagesServices()
        langugaesService.completion = {   (result, error, _) in
            if let error = error {
                self.postError(error: error)
                return
            }
            if let serviceResult = result as? TRPLanguagesInfoModel {
                self.postData(result: serviceResult.translations[TRPClient.shared.language])
            }else {
                self.postError(error: TRPErrors.emptyDataOrParserError as NSError)
            }
        }
        langugaesService.connection()
    }
}
