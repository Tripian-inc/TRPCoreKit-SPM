//
//  Notification+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 28.11.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
extension Notification.Name {
    static let TRPAddRemovePoi = Notification.Name("TRPAddAndRemovePoiNotification")
    static let TRPAddRemovePoiState = Notification.Name("TRPAddAndRemovePoiStateNotification")
    static let TRPNetworkStatusChanged = Notification.Name("TRPNetworkStatusChanged")
    static let TRPMapBoxRoutingError = Notification.Name("TRPMapBoxRoutingError")
    static let TRPPlaceFavorite = Notification.Name("PlaceFavoriteStatusChanged")
    public static let tripCreated = Notification.Name("TRPAnalytics.tripCreated")
    public static let tripEdited = Notification.Name("TRPAnalytics.tripEdited")
    public static var tripDeleted = Notification.Name("TRPAnalytics.tripDeleted")
    public static var mapViewed = Notification.Name("TRPAnalytics.mapViewed")
    public static var userLocated = Notification.Name("TRPAnalytics.userLocated")
    public static var favoriteStatusChanged = Notification.Name("TRPAnalytics.favoriteStatusChanged")
}

extension Notification {
    public enum TripKeys: String {
        case tripInfoModel
    }
    
    public enum MapViewKeys: String {
        case hash
        case cityId
        case userLocation
    }
    
    public enum UserLocationKeys: String {
        case userLocation
        case userName
    }
    
    public enum FavoriteStatusKeys: String {
        case isFavorite
        case place
    }
}
