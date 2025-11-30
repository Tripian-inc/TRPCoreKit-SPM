//
//  TRPGooglePlaceService.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 5.02.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation


class TRPGooglePlaceService {
    
    private var key: String
    private var id: String
    
    init(key: String, placeId: String) {
        self.key = key
        self.id = placeId
    }
    
    func start(completion: @escaping (_ result: Any?, _ error: NSError?) -> Void) {
        let network = TRPNetwork(link: "https://maps.googleapis.com/maps/api/place/details/json")
        network.add(params: ["placeid": id, "key": key])
        network.add(mode: .post)
        network.build { (error, data) in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                let object: NSDictionary?
                do {
                    object = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                } catch {
                    object = nil
                    completion(nil, TRPErrors.wrongData as NSError)
                    return
                }
                if let errorMessage = object?["error_message"] as? String {
                    completion(nil, TRPErrors.someThingWronk(errorMessage) as NSError)
                    return
                }
                guard let result = object?["result"] as? [String: Any],
                    let geometry = result["geometry"] as? [String: Any],
                    let location = geometry["location"] as? [String: Any],
                    let lat = location["lat"] as? Double,
                    let lon = location["lng"] as? Double
                    else {
                        completion(nil, TRPErrors.wrongData as NSError)
                        return
                }
                //todo: otel adress aktif hale getirilecek
                var address = "Hotel"
                var name: String?
                if let value = result["name"] as? String {
                    name = value
                }
                
                if let formattedAddress = result["formatted_address"] as? String {
                     address = formattedAddress
                }
                
                let model = TRPGooglePlaceLocation(id: self.id, location: TRPLocation(lat: lat, lon: lon), hotelAddress: address, name: name)
                completion(model, nil)
            }
        }
        
    }
    
}
