//
//  TRPCheckDataUpdates.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 27.06.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
//NOT USED NOW
/*
internal class TRPCheckDataUpdates: TRPRestServices{
    
    var cityId:Int;
    var cityUpdate:Int
    var placeUpdate:Int?;
    var tagUpdate:Int?;
    
    internal init(cityId: Int, cityUpdate: Int) {
        self.cityId = cityId
        self.cityUpdate = cityUpdate
    }
    
    public override func servicesResult(data: Data?, error: NSError?) {
        if let error = error {
            self.Completion?(nil,error, nil);
            return
        }
        guard let data = data else {
            self.Completion?(nil, TRPErrors.wrongData as NSError, nil)
            return
        }
        let jsonDecode = JSONDecoder();
        do {
            let result = try jsonDecode.decode(TRPCheckUpdateJsonModel.self, from: data)
            let pag = paginationController(parentJson: result)
            self.Completion?(result, nil, pag);
        }catch let tryError {
            self.Completion?(nil, tryError as NSError, nil);
        }
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.CheckDataUpdates.link;
    }
    
    override func parameters() -> Dictionary<String, Any>? {
        var ar = [String:Any]()
        ar["city_id"] = cityId
        ar["city_lastupdate"] = cityUpdate
        
        if let tagUpdate = tagUpdate {
            ar["tag_lastupdate"] = tagUpdate
        }
        if let placeUpdate = placeUpdate {
            ar["place_lastupdate"] = placeUpdate
        }
        return ar
    }
}
 */
