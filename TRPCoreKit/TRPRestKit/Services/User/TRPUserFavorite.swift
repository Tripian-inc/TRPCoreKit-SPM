//
//  TRPUserFavorite.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 8.10.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPUserFavorite: TRPRestServices<TRPFavoritesJsonModel> {
    
    public enum Mode {
        case add, get, delete
    }
    
    private let type: Mode
    private var cityId: Int?
    private var poiId: String?
    private var favoriteId: Int?
    //ADD
    public init(poiId: String, type: Mode) {
        self.type = type
        
        self.poiId = poiId
    }
    
    //Delete
    public init(favoriteId: Int) {
        self.favoriteId = favoriteId
        self.type = .delete
    }
    
    //GET
    public init(cityId: Int) {
        self.type = .get
        self.cityId = cityId
    }
    
    override public func requestMode() -> TRPRequestMode {
        if type == .get {
            return .get
        } else if type == .add {
            return .post
        } else if type == .delete {
            return .delete
        }
        return .get
    }
    
    public override func path() -> String {
        var url = TRPConfig.ApiCall.favorite.link
        if type == .delete {
            if let id = favoriteId {
                url += "/\(id)"
            }
        }
        return url
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    override func bodyParameters() -> [String : Any]? {
        if type == .add, let poi = poiId {
            return ["poiId": poi]
        }
        return nil
    }
    
    public override func parameters() -> [String: Any]? {
        if type == .get {
            if let cityId = cityId {
                return ["cityId": "\(cityId)"]
            }
        }
        return nil
    }
}
