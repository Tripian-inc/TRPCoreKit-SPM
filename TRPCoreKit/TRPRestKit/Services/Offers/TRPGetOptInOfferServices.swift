//
//  TRPGetOptedInOfferServices.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPGetOptInOfferServices: TRPRestServices<TRPGenericParser<[TRPPoiInfoModel]>> {
    
    private var dateFrom: String?
    private var dateTo: String?
    var page: Int?
    var limit: Int?
    
    init(dateFrom: String?, dateTo: String?, page: Int?, limit: Int?) {
        self.dateFrom = dateFrom
        self.dateTo = dateTo
        self.page = page
        self.limit = limit
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.optInOffers.link
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .get
    }
    
    override func parameters() -> [String: Any]? {
        var params = [String: Any]()
        
        if let dateFrom = dateFrom {
            params["dateFrom"] = dateFrom
        }
        
        if let dateTo = dateTo {
            params["dateTo"] = dateTo
        }
        
        if let page = page {
            params["page"] = page
        }
        
        if let limit = limit {
            params["limit"] = limit
        }
        
        return params
    }
    
}
