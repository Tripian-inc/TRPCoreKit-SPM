//
//  Storyboard+extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-19.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
import Foundation
import UIKit
enum Storyboard: String {
    case myTrip = "MyTrip"
    case action = "Action"
    case favorite = "Favorite"
    case tripMode = "TripMode"
    case addPlace = "AddPlace"
    case itinerary = "Itinerary"
    case createTripSelectCity = "CreateTripSelectCity"
    case companion = "Companion"
    case createTripSelectDate = "CreateTripSelectDate"
    case createTripStayAddress = "CreateTripStayAddress"
    case createTripQuestions = "CreateTripQuestions"
    case createTripOverview = "CreateTripOverview"
    case poiDetail = "PoiDetail"
    case userProfile = "UserProfile"
    case myOffers = "MyOffers"
    case createTrip = "CreateTrip"
    case createTripTripInformation = "CreateTripTripInformation"
    case createTripStayShare = "CreateTripStayShare"
    case createTripPickedInformation = "CreateTripPickedInformation"
    case createTripPersonalizeTrip = "CreateTripPersonalizeTrip"
    case experience = "Experience"
    case popup = "Popup"
}

extension UIStoryboard {
    
    static func load(from storyBoard: Storyboard, identifier: String)  -> UIViewController {
        let bundle = Bundle(identifier: "com.tripian.TRPCoreKit")!
        let board = UIStoryboard(name: storyBoard.rawValue, bundle: bundle)
        return board.instantiateViewController(withIdentifier: identifier)
    }
    
    
    class func makeMyTripTableView() -> MyTripTableViewVC {
        return load(from: .myTrip, identifier: "MyTripTableViewVC") as! MyTripTableViewVC
    }
    
    class func actionViewController() -> ActionViewController {
        let vc = load(from: .action, identifier: "ActionViewController") as! ActionViewController
        vc.modalPresentationStyle = .pageSheet
        return vc
    }
    
    class func makeFavoriteViewController() -> FavoritesVC {
        return load(from: .favorite, identifier: "FavoritesVC") as! FavoritesVC
    }
    
    class func makeTripMode() -> TRPTripModeVC {
        return load(from: .tripMode, identifier: "TRPTripModeVC") as! TRPTripModeVC
    }
    
    class func makeAddPlacesContainer() -> AddPlacesContainerViewController {
        return load(from: .addPlace, identifier: "AddPlacesContainerViewController") as! AddPlacesContainerViewController
    }
    
    class func makeMustTryContainer() -> MustTryTableViewViewController {
        return load(from: .addPlace, identifier: "MustTryTableViewViewController") as! MustTryTableViewViewController
    }
    
    class func makeAddPlaceViewController() -> AddPoiTableViewVC {
        return load(from: .addPlace, identifier: "AddPoiTableViewVC") as! AddPoiTableViewVC
    }
    
    class func makeItineraryViewController() -> ItineraryViewController {
        return load(from: .itinerary, identifier: "ItineraryViewController") as! ItineraryViewController
    }
    
    class func makeSelectCityViewController() -> SelectCityVC {
        return load(from: .createTripSelectCity, identifier: "SelectCityVC") as! SelectCityVC
    }
    
    class func makeSelectCompanionViewController() -> SelectCompanionVC {
        return load(from: .companion, identifier: "SelectCompanionVC") as! SelectCompanionVC
    }
    
    class func makeCompanionDetailViewController() -> CompanionDetailVC {
        let vc = load(from: .companion, identifier: "CompanionDetailVC") as! CompanionDetailVC
        vc.modalPresentationStyle = .overCurrentContext
        return vc
    }
    
    class func makeSelectDateViewController() -> DateAndTravellerCountVC {
        return load(from: .createTripSelectDate, identifier: "DateAndTravellerCountVC") as! DateAndTravellerCountVC
    }
    
    class func makeTripQuestionsViewController() -> TripQuestionsViewController {
        return load(from: .createTripQuestions, identifier: "TripQuestionsViewController") as! TripQuestionsViewController
    }
    
    class func makeSelectTravalerCountViewController() -> SelectTravalerCountVC {
        let vc = load(from: .createTripSelectDate, identifier: "SelectTravalerCountVC") as! SelectTravalerCountVC
        vc.modalPresentationStyle = .overCurrentContext
        return vc
    }
    
    class func makeSelectStayAddressViewController() -> StayAddressVC {
        let vc = load(from: .createTripStayAddress, identifier: "StayAddressVC") as! StayAddressVC
        return vc
    }
    
    class func makeOverviewContainerViewController() -> OverviewContainerVC {
        let vc = load(from: .createTripOverview, identifier: "OverviewContainerVC") as! OverviewContainerVC
        return vc
    }
    
    class func makeOverviewViewController() -> OverviewViewController {
        let vc = load(from: .createTripOverview, identifier: "OverviewViewController") as! OverviewViewController
        return vc
    }
    
    class func makePoiDetailViewController() -> PoiDetailViewController {
        let vc = load(from: .poiDetail, identifier: "PoiDetailViewController") as! PoiDetailViewController
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
 
    class func makeUserProfileViewController() -> UserProfileViewController {
        return load(from: .userProfile, identifier: "UserProfileViewController") as! UserProfileViewController
    }
    
    class func makePersonalInfoViewController() -> PersonalInfoViewController {
        return load(from: .userProfile, identifier: "PersonalInfoViewController") as! PersonalInfoViewController
    }
    
    class func makeChangePasswordViewController() -> ChangePasswordViewController {
        let vc = load(from: .userProfile, identifier: "ChangePasswordViewController") as! ChangePasswordViewController
        vc.modalPresentationStyle = .overCurrentContext
        return vc
        
    }
    
    class func makeMyOffersViewController() -> MyOffersVC {
        return load(from: .myOffers, identifier: "MyOffersVC") as! MyOffersVC
    }
    
    class func makeCreateTripViewController() -> CreateTripContainerVC {
        return load(from: .createTrip, identifier: "CreateTripContainerVC") as! CreateTripContainerVC
    }
    
    class func makeCreateTripTripInformationViewController() -> CreateTripTripInformationVC {
        return load(from: .createTripTripInformation, identifier: "CreateTripTripInformationVC") as! CreateTripTripInformationVC
    }
    
    class func makeCreateTripSelectDateViewController() -> CreateTripSelectDateVC {
        return load(from: .createTripTripInformation, identifier: "CreateTripSelectDateVC") as! CreateTripSelectDateVC
    }
    
    class func makeCreateTripSelectTimeViewController() -> CreateTripSelectTimeVC {
        return load(from: .createTripTripInformation, identifier: "CreateTripSelectTimeVC") as! CreateTripSelectTimeVC
    }
    
    class func makeCreateTripStayShareViewController() -> CreateTripStayShareVC {
        return load(from: .createTripStayShare, identifier: "CreateTripStayShareVC") as! CreateTripStayShareVC
    }
    
    class func makeCreateTripSelectCompanionViewController() -> CreateTripSelectCompanionVC {
        return load(from: .createTripStayShare, identifier: "CreateTripSelectCompanionVC") as! CreateTripSelectCompanionVC
    }
    
    class func makeCreateTripPickedInformationViewController() -> CreateTripPickedInformationVC {
        return load(from: .createTripPickedInformation, identifier: "CreateTripPickedInformationVC") as! CreateTripPickedInformationVC
    }
    
    class func makeCreateTripSelectRestaurantPreferViewController() -> CreateTripSelectRestaurantPreferVC {
        return load(from: .createTripPickedInformation, identifier: "CreateTripSelectRestaurantPreferVC") as! CreateTripSelectRestaurantPreferVC
    }
    
    class func makeCreateTripPersonalizeTripViewController() -> CreateTripPersonalizeTripVC {
        return load(from: .createTripPersonalizeTrip, identifier: "CreateTripPersonalizeTripVC") as! CreateTripPersonalizeTripVC
    }
    
    class func makeExperienceViewController() -> ExperiencesViewController {
        return load(from: .experience, identifier: "ExperiencesViewController") as! ExperiencesViewController
    }
    
    //MARK: Popup
    class func getPopup() -> PopupAlert {
        let vc = load(from: .popup, identifier: "PopupAlert") as! PopupAlert
        vc.modalPresentationStyle = .overFullScreen
        return vc
    }
    
}
