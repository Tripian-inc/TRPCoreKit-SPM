//
//  TRPGoogleAutoComplete.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 5.02.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation

class TRPGoogleAutoComplete {
    
    private var key: String
    private var text: String
    public var centerLocationForBoundary: TRPLocation?
    public var radiusForBoundary: Double?

    init(key: String, text: String) {
        self.key = key
        self.text = text
    }
    
    func start(completion: @escaping (_ result: Any?, _ error: NSError?) -> Void) {
        
        guard let escapedAddress = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {return}
        
        var link = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(escapedAddress)&key=\(key)"
        
        if let location = centerLocationForBoundary, let radius = radiusForBoundary {
            link += "&location=\(location.lat),\(location.lon)&radius=\(radius)&strictbounds=true"
        }
        let network = TRPNetwork(link: link)
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
                
                guard let predictions = object?["predictions"] as? [[String: Any]] else { return }
                let sonuc = predictions.map { TRPGooglePlace(prediction: $0) }
                completion(sonuc, nil)
            }
        }
    }
}
