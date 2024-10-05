//
//  TRPConfig.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 9.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal struct TRPConfig {

    internal static func getBaseUrl() -> String {
        return TRPClient.shared.baseUrl.baseUrl
    }
    
    internal static func getBaseUrlPath() -> String {
        return TRPClient.shared.baseUrl.basePath
    }
    
    internal static func getApiLink() -> String {
        return "https://\(TRPConfig.getBaseUrl())/\(TRPConfig.getBaseUrlPath())/"
    }
    
    internal enum ApiCall: String {
        case city
        case shorexCities
        
        case poiCategory
        case poi
        case questions
        case recommendations
        case routes
        case routesResult
        case gRouteReuslt
        case stepAlternative
        case tags
        case checkDataUpdates
        case refresh
        case login
        case user
        case userTrips
        case trip
        case dailyPlan
        case userPreferences
        case dailyPlanPoi
        case register
        case guestLogin
        case favorite
        case step
        case companion
        case userReaction
        case userReservation
        case socialLogin
        case logout
        case resetPassword
        case notifications
        case offers
        case optInOffers
        case exportItinerary
        var link: String {
            switch self {
            case .city:
                return getNewLink() ?? "cities"
            case .poiCategory:
                return getNewLink() ?? "poi-categories"
            case .poi:
                return getNewLink() ?? "pois"
            case .questions:
                return getNewLink() ?? "trip/questions"
            case .recommendations:
                return getNewLink() ?? "recommendations"
            case .routes:
                return getNewLink() ?? "routes"
            case .routesResult:
                return getNewLink() ?? "routeresult"
            case .gRouteReuslt:
                return getNewLink() ?? "grouteresult"
            case .stepAlternative:
                return getNewLink() ?? "step/alternatives"
            case .tags:
                return getNewLink() ?? "tags"
            case .checkDataUpdates:
                return getNewLink() ?? "check-data-updates"
            case .login:
                return getNewLink() ?? "auth/login"
            case .user:
                return getNewLink() ?? "user"
            case .userTrips:
                return getNewLink() ?? "trips"
            case .trip:
                return getNewLink() ?? "trips"
            case .dailyPlan:
                return getNewLink() ?? "plans"
            case .userPreferences:
                return getNewLink() ?? "user/preferences"
            case .dailyPlanPoi:
                return getNewLink() ?? "dailyplanpoi"
            case .register:
                return getNewLink() ?? "auth/register"
            case .favorite:
                return getNewLink() ?? "favorites"
            case .companion:
                return getNewLink() ?? "companions"
            case .refresh:
                return getNewLink() ?? "auth/refresh-token"
            case .step:
                return getNewLink() ?? "steps"
            case .userReaction:
                return getNewLink() ?? "reactions"
            case .userReservation:
                return getNewLink() ?? "bookings"
            case .socialLogin:
                return getNewLink() ?? "auth/login-social"
            case .logout:
                return "auth/logout"
            case .resetPassword:
                return "auth/reset-password"
            case .notifications:
                return "notifications"
            case .offers:
                return "offers"
            case .optInOffers:
                return "offers/opt-in"
            case .exportItinerary:
                return "misc/export-itinerary"
            case .shorexCities:
                return "shorex-cities"
            case .guestLogin:
                return "auth/guest-login"
            }
        }
        
        private func getNewLink() -> String? {
            return nil
        }
    }
    
}
