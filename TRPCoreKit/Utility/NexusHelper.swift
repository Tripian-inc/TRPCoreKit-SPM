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
        let customQueryItems = [
            URLQueryItem(name: "startDate", value: startDate),
            URLQueryItem(name: "utm_source", value: "nexusapp"),
            URLQueryItem(name: "utm_medium", value: "tripian")
        ]
        var queryItems = components.queryItems ?? []
        for customQueryItem in customQueryItems {
            if !queryItems.contains(where: { $0.name == customQueryItem.name }) {
                queryItems.append(customQueryItem)
            }
        }
        components.queryItems = queryItems
        return components.url
    }
}
