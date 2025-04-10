//
//  NexusHelper.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 3.04.2025.
//

import Foundation

public class NexusHelper {
    
    public static func getCustomPoiUrl(url: String, startDate: String) -> URL? {
        guard var components = URLComponents(string: url.replacingOccurrences(of: "/en/", with: "/\(TRPClient.shared.language)/")) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(contentsOf: [
            URLQueryItem(name: "startDate", value: startDate),
            URLQueryItem(name: "utm_source", value: "nexusapp"),
            URLQueryItem(name: "utm_medium", value: "tripian"),
            //                URLQueryItem(name: "endDate", value: endDate)
        ])
        components.queryItems = queryItems
        return components.url
    }
}
