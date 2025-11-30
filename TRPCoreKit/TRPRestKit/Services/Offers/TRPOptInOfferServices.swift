//
//  TRPOptInOfferServices.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPOptInOfferServices: TRPRestServices<TRPParentJsonModel> {
    
    public enum Mode {
        case add, delete
    }
    
    private let type: Mode
    private var offerId: Int
    private var claimDate: String?
    
    init(offerId: Int, claimDate: String?) {
        self.type = .add
        self.offerId = offerId
        self.claimDate = claimDate
    }
    
    init(offerId: Int) {
        self.type = .delete
        self.offerId = offerId
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.offers.link + "/\(self.offerId)"
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        if type == .add {
            return .put
        }
        return .delete
    }
    
    override func parameters() -> [String: Any]? {
        var params = [String: Any]()
        
        if let claimDate = claimDate {
            params["offerClaimDate"] = claimDate
        }
        
        return params
    }
    override func bodyParameters() -> [String : Any]? {
        var params = [String: Any]()
        
        if let claimDate = claimDate {
            params["offerClaimDate"] = claimDate
        }
        
        return params
    }
}
