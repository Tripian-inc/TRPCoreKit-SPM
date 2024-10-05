//
//  TRPDefaultSettings.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 18.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation

import UIKit
public class TRPAppearanceSettings {
    
    public class Providers {
        public static let uber = true
    }
    
    
    public class PaginView {
        public static var menuItemSize = CGSize(width: 70, height: 50)
        public static var textColor = TRPColor.lightGrey
        public static var selectedTextColor = TRPColor.darkGrey
        public static var indicatorColor = TRPColor.darkGrey
    }
    
    
    public class TabBar {
        public static var placeImage: String?
        public static var experienceImage: String?
        public static var itineraryImage: String?
        public static var favoritesImage: String?
        public static var bookingImage: String?
    }
    
    
    public class Common {
        public static var navigationBarTintColor = UIColor.black
        public static var navigationTintColor = UIColor.white
        public static var navigationTitleTextColor = UIColor.white
        public static var closeButtonImage: String?
        public static var closeButtonWithShadowImage: String?
        public static var closeBlackButtonImage: String?
        public static var closeWithCircleButtonImage: String?
        public static var userButtonImage: String?
        public static var addButtonImage: String?
        public static var removeButtonImage: String?
        public static var navigationButtonImage: String?
        public static var alternativePoiButtonImage: String?
        public static var inRoutePoiButtonImage: String?
//        public static var setTimeTextInAlertView = "Set Time".toLocalized()
//        public static var ApplyButtonTitle = "Apply".toLocalized()
//        public static var continueButtonTitle = "Continue".toLocalized()
//        public static var createATripButtonTitle = "Create a Trip".toLocalized()
//        public static var doneButtonTitle = "Done".toLocalized()
        public static var barButtonForInputButtonColor = TRPColor.pink
        public static var cancelButtonColor = TRPColor.pink
        public static var continueButtonColor = TRPColor.pink
    }
    
    
    public class MyTrip {
        public static var leftBarButtonItems: [TRPBarButtonItem] = [TRPBarButtonItem(type: .close)] //[TRPBarButtonItem(type: .createTrip),TRPBarButtonItem(type: .dismiss)]
        public static var rightBarButtonItems: [TRPBarButtonItem] = [TRPBarButtonItem(type: .createTrip)]
        public static var addTripImage: String?
        public static var removeTripImage: String?
        public static var dotsImage: String?
        public static var editTripImage: String?
//        public static var title: String = "My Trips".toLocalized()
//        public static var upcomingString: String = "Upcoming trips".toLocalized()
//        public static var pastTripString: String = "Past trips".toLocalized()
        public static var cellCityEmptyImageColor: UIColor = TRPColor.darkGrey
        public static var cellCityNameColor: UIColor = UIColor.white
        public static var cellCityNameFontSize: CGFloat = 18
        public static var cellDateColor: UIColor = UIColor.white
        public static var cellDateFontSize: CGFloat = 15
        public static var cellCenterViewBorderColor: UIColor = UIColor.white
        public static var cellCenterViewBorderWidth: CGFloat = 3
        public static var cellCenterViewBorderRadius: CGFloat = 6
        public static var cellCenterViewSize: CGSize = CGSize(width: 250, height: 72)
        public static var cellSeparatorHeight: CGFloat = 10
        public static var cellSeparatorColor: UIColor = TRPColor.lightBlue
    }
    
    
    public class SelectCity {
//        public static var title: String = "Select City".toLocalized();
        public static var headerBgColor: UIColor = TRPColor.lightBlueGrey
        public static var headerHeight: CGFloat =  61
        public static var headerTextColor: UIColor =  TRPColor.darkGrey
        public static var headerFontSize: CGFloat = 14
        public static var cellTextColor: UIColor = TRPColor.lightGrey
        public static var cellFontSize: CGFloat = 16
        public static var cellHeight: CGFloat =  50
    }
    
    
    public class Calendar {
        public static var departureMaxDate = 14
//        public static var title = "Flight Details".toLocalized()
        //Arrival
//        public static var arrivalDateHeader = "Arrival Date".toLocalized()
//        public static var selectDatePlaceHolder = "Date".toLocalized()
//        public static var arrivalDatePlaceHolder = "Time (Default 9:00)".toLocalized()
        //Departure
//        public static var departureDateHeader = "Departure Date".toLocalized()
//        public static var departureDatePlaceHolder = "Time (Default 21:00)".toLocalized()
    }
    
    public class SelectDate {
//        public static var title = "Select Date".toLocalized()
//        public static var adultsTitle = "Adults".toLocalized()
//        public static var adultCountPlaceHolder = "Adults Count (Default 1)".toLocalized()
//        public static var adultsAgeRatioPlaceHolder = "Adults Age Ratio".toLocalized()
//        public static var adultsAgePlaceHolder = "How old are you?".toLocalized()
//        public static var childrenTitle = "Children".toLocalized()
//        public static var childrenCountPlaceHolder = "Children Count (Default 0)".toLocalized()
//        public static var childrenAgeRatioPlaceHolder = "Children Age Ratio".toLocalized()
//        
//        public static var setAdultAgeInKeyboard = "Set Adult Age".toLocalized()
//        public static var setChildrenAgeInKeyboard = "Set Children Age".toLocalized()
//        public static var setChildCountInKeyboard = "Set Child Count".toLocalized()
    }
    
    public class StayAddress {
//        public static var title = "Where Will You Stay?".toLocalized()
//        public static var searchBarPlaceHolder = "Type The Address".toLocalized()
    }
    
    public class TripQuestion {
//        public static var title = "Trip Details".toLocalized()
    }
    
    
    public class TripModeMapView {
        public static var searchInTopBarImage: String?
        public static var backInTopBarImage: String?
        public static var circleMenuOpenImage: String?
        public static var circleMenuCloseImage: String?
        public static var eatAndDrinkImage: String?
        public static var attractionsImage: String?
        public static var savedPlacesImage: String?
        public static var searchImage: String?
        public static var userLocationNormalImage: String?
        public static var userLocationSelectedImage: String?
        public static var timeFrameImage: String?
        public static var favoriteImage: String?
        public static var notificationImage: String?
//        public static var eatAndDrinkMenu = "Eat & Drink".toLocalized();
//        public static var attractionsMenu = "Attractions".toLocalized();
//        public static var savedPlacesMenu = "Favorites".toLocalized();
//        public static var searchMenu = "Search".toLocalized();
//        public static var searchThisAreaButtonTitle = "Search This Area".toLocalized()
//        public static var cleanResaultButtonTitle = "Clear Results".toLocalized()
    }
    
    
    public class ListOfRouting {
//        public static var title = "ITINERARY".toLocalized()
        public static var titleTextColor: UIColor =  TRPColor.darkerGrey
        public static var titleFontSize: CGFloat = 14
        public static var alternativeImage: String?
        public static var removeImage: String?
        public static var walkingImage: String?
        public static var poiTitleTextColor: UIColor =  TRPColor.darkerGrey
        public static var poiDetailTextColor: UIColor =  TRPColor.darkerGrey
        public static var orderCircleBGColor: UIColor = TRPColor.darkerGrey
        public static var orderCircleTextColor: UIColor = TRPColor.darkerGrey
    }
    
    public class AddPlace {
//        public static var recommendedPoiListTextIsEmpty = "No recommendations.".toLocalized()
//        public static var nearByPoiListTextIsEmpty = "Your current location is not ".toLocalized()
//        public static var noAvaliablePoi = "No recommendations.".toLocalized()
    }
    
    public class EatAndDrink {
//        public static var title = "Eat & Drink".toLocalized()
    }
    
    public class Attraction {
//        public static var title = "Attraction".toLocalized()
    }
    
    
    
    public class FavoriteVC {
//        public static var title = "Favorites".toLocalized()
        public static var cellTitleTextColor: UIColor =  TRPColor.darkerGrey
        public static var cellFontSize: CGFloat = 16
    }
    
    public class SearchPlaces {
//        public static var title = "Search".toLocalized()
        
    }
    
    
    public class AddPoi {
        public static var filterButtonImage: String?
        public static var alternativePoiIcon: String?
        public static var poiTitleColor: UIColor = UIColor.red
        public static var poiCellHeight: CGFloat = 200
        public static var sortingButtonImage: String?
    }
    
    
    public class MapAnnotations {
        public enum IconType {
            case normal, route, offer
        }
        public typealias ImageAndTag = (imageName: String, tag:String)
        
        
        public static var iceCream =    ImageAndTag("black_ice_cream","IceCream")
        public static var burger =      ImageAndTag("black_burger","Burger")
        public static var bakery =      ImageAndTag("black_bakery","Bakery")
        public static var attraction =  ImageAndTag("black_attractions","Attraction")
        public static var shop =        ImageAndTag("black_shop","Shop")
        public static var flag =        ImageAndTag("black_flag","Flag")
        public static var bbq =         ImageAndTag("black_","Bbq")
        public static var pizza =       ImageAndTag("black_pizza","Pizza")
        public static var restaurant =  ImageAndTag("black_restaurant","Restaurant")
        public static var synagogue =   ImageAndTag("black_synagogue","Synagogue")
        public static var mosque =      ImageAndTag("black_mosque","Mosque")
        public static var church =      ImageAndTag("black_chruch","Church")
        public static var bar =         ImageAndTag("black_bar","Bar")
        public static var wineBar =     ImageAndTag("black_wine_bar","WineBar")
        public static var pub =         ImageAndTag("black_pub","Pub")
        public static var artGallery =  ImageAndTag("black_art","ArtGallery")
        public static var museum =      ImageAndTag("black_museum","Museum")
        public static var cafe =        ImageAndTag("black_coffee","Cafe")
        public static var dessert =     ImageAndTag("black_dessert","Dessert")
        public static var homebase =     ImageAndTag("black_homebase","Homebase")
        public static var clustersImage = ImageAndTag("black_circle","clusterImage")
        
        //Offer
        public static var iceCreamWithOffer =    ImageAndTag("ice_cream_with_offer","IceCreamWithOffer")
        public static var burgerWithOffer =      ImageAndTag("burger_with_offer","BurgerWithOffer")
        public static var bakeryWithOffer =      ImageAndTag("bakery_with_offer","BakeryWithOffer")
        public static var attractionWithOffer =  ImageAndTag("attractions_with_offer","AttractionWithOffer")
        public static var shopWithOffer =        ImageAndTag("shop_with_offer","ShopWithOffer")
        public static var flagWithOffer =        ImageAndTag("flag_with_offer","FlagWithOffer")
        public static var bbqWithOffer =         ImageAndTag("","BbqWithOffer")
        public static var pizzaWithOffer =       ImageAndTag("pizza_with_offer","PizzaWithOffer")
        public static var restaurantWithOffer =  ImageAndTag("restaurant_with_offer","RestaurantWithOffer")
        public static var synagogueWithOffer =   ImageAndTag("synagogue_with_offer","SynagogueWithOffer")
        public static var mosqueWithOffer =      ImageAndTag("mosque_with_offer","MosqueWithOffer")
        public static var churchWithOffer =      ImageAndTag("chruch_with_offer","ChurchWithOffer")
        public static var barWithOffer =         ImageAndTag("bar_with_offer","BarWithOffer")
        public static var wineBarWithOffer =     ImageAndTag("wine_bar_with_offer","WineBarWithOffer")
        public static var pubWithOffer =         ImageAndTag("pub_with_offer","PubWithOffer")
        public static var artGalleryWithOffer =  ImageAndTag("art_with_offer","ArtGalleryWithOffer")
        public static var museumWithOffer =      ImageAndTag("museum_with_offer","MuseumWithOffer")
        public static var cafeWithOffer =        ImageAndTag("coffee_with_offer","CafeWithOffer")
        public static var dessertWithOffer =     ImageAndTag("dessert_with_offer","DessertWithOffer")
        public static var homebaseWithOffer =    ImageAndTag("homebase_with_offer","HomebaseWithOffer")
        
        
        public static func getIcon(tag: String, type: IconType) -> String {
            var icons: [ImageAndTag]?
            if type == .normal {
                icons = getAllIcon(IconType.normal)
            }else if type == .offer{
                icons = getAllIcon(IconType.offer)
            }else {
                icons = getAllIcon(IconType.route)
            }
            var imageName = flag.imageName
            icons!.forEach { (image,iconTag) in
                if  iconTag == tag  {
                    imageName = image
                }
            }
            return imageName
        }
        
        public static func getAllIcon(_ type: IconType) -> [ImageAndTag] {
            if type == .offer {
                return [iceCreamWithOffer, burgerWithOffer, bakeryWithOffer, attractionWithOffer, shopWithOffer, flagWithOffer, bbqWithOffer, pizzaWithOffer, restaurantWithOffer, synagogueWithOffer, mosqueWithOffer, churchWithOffer, barWithOffer, wineBarWithOffer, pubWithOffer, artGalleryWithOffer, museumWithOffer, cafeWithOffer, dessertWithOffer, homebaseWithOffer]
            }
            return [iceCream, burger, bakery, attraction, shop, flag, bbq, pizza, restaurant, synagogue, mosque, church, bar, wineBar, pub, artGallery, museum, cafe, dessert, homebase, clustersImage, iceCreamWithOffer, burgerWithOffer, bakeryWithOffer, attractionWithOffer, shopWithOffer, flagWithOffer, bbqWithOffer, pizzaWithOffer, restaurantWithOffer, synagogueWithOffer, mosqueWithOffer, churchWithOffer, barWithOffer, wineBarWithOffer, pubWithOffer, artGalleryWithOffer, museumWithOffer, cafeWithOffer, dessertWithOffer, homebaseWithOffer]
        }
    }
    
    
    public class PoiDetail {
        public static var imageLoadingImage: String?
        public static var favoritePoiImage: String?
        public static var selectedFavoritePoiImage: String?
        
        public static var narrovingTagInListImage: String?
        public static var phoneInListImage: String?
        public static var mustTryListImage: String?
        public static var webInListImage: String?
        public static var descriptionImage: String?
        public static var calendarInListImage: String?
        public static var tagInListImage: String?
        public static var moneyInListImage: String?
        
        public static var cuisineInListImage: String?
        public static var featuresInListImage: String?
        public static var locationInListImage: String?
        
        public static var sharedPoiUrl: String = "https://trial.tripian.com/place/"
    }
    
    
    public class Butterfly {
        
//        public static var title = "Itinerary Planner"
        
        public static var thumbsUpImage: String?
        public static var thumbsUpGreenImage: String?
        
        public static var topLabelTextColor: UIColor = UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        public static var topLabelFont: UIFont = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.bold)
        
        public static var placeNameTextColor: UIColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        public static var placeNameTextFont: UIFont = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        
        public static var subLabelTextColor: UIColor = UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        public static var subLabelFont: UIFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        
        public static var subTextColor: UIColor = TRPColor.darkGrey
        public static var subTextFontSize: CGFloat = 24
        
        public static var headerTextColor: UIColor = TRPColor.darkGrey
        public static var headerFontSize: CGFloat = 24
        
        public static var cellTitleTextColor: UIColor = TRPColor.darkGrey
        public static var cellTitleFontSize: CGFloat = 20
        
        public static var matchRateTextColor: UIColor = UIColor.white
        public static var matchRateFont: UIFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        public static var matchRateBGColor: UIColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0);
        
        public static var imageHeight: CGFloat = 228
        public static var collectionCellHeight: CGFloat = 387
        public static var collectionCellWidth: CGFloat = 250
        
        public static var explaineCellBg = UIColor(red: 249.0/255.0, green: 249.0/255.0, blue: 249.0/255.0, alpha: 1.0);
        public static var explaineTextColor = UIColor.black
        public static var explaineFont: UIFont = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
    }
    
    
    public class ShowRating {
        public static var type: [TRPPoiCategory] = [.attractions,
                                                    .restaurants,
                                                    .nightLife,
                                                    .coolFinds,
                                                    .cafes,
                                                    .bar,
                                                    .religiousPlaces,
                                                    .theater,
                                                    .cinema,
                                                    .stadium,
                                                    .civicCenter,
                                                    .museum,
                                                    .bar,
                                                    .artGallery,
                                                    .shoppingCenter,
                                                    .bakery,
                                                    .brewery,
                                                    .dessert,
                                                    
        ]
    }
    
    
    public class ItineraryUserDistance{
        public static var walkingMan: String?
        public static var taxi: String?
    }
    
    public class Companion{
//        public static var title = "Companion Preferences".toLocalized()
    }
    
    
    
    public class DateAndTravellerVC {
        public static var addButtonColor: UIColor = TRPColor.pink
    }
    
}
