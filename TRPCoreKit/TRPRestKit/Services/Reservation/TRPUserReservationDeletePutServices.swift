//
//  TRPUserReservationDeletePutServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 15.07.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPUserReservationDeletePutServices: TRPRestServices<TRPParentJsonModel> {
    
    private(set) var reservationId: Int
  
    init(id: Int) {
        self.reservationId = id
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.userReservation.link + "/\(reservationId)"
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .delete
    }
    
}
