//
//  NexusHelper.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 3.04.2025.
//

import Foundation

public class NexusHelper {
    
    public static func getCustomPoiUrl(url: String, startDate: String) -> URL? {
        return createCustomPoiUrl(url: url, customQueryItems: getStaticQueryItems(startDate: startDate))
    }
    
    public static func getCustomPoiUrl(destinationZone: String, startDate: String, productCode: String, adultCount: Int = 1, childCount: Int = 0) -> URL? {
        let url = "https://www.nexustours.com/services/details.aspx"
        let productInfo = getProductIdAndType(productCode: productCode)
        var queryItems = getStaticQueryItems(startDate: startDate)
        let customQueryItems = [
            URLQueryItem(name: "destinationID", value: destinationZone),
            URLQueryItem(name: "productId", value: productInfo.productId),
            URLQueryItem(name: "prov", value: productInfo.prov),
            URLQueryItem(name: "productType", value: productInfo.productType)
        ]
        queryItems.append(contentsOf: customQueryItems)
        return createCustomPoiUrl(url: url, customQueryItems: queryItems)
    }
    
    private static func createCustomPoiUrl(url: String, customQueryItems: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(string: url) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        for customQueryItem in customQueryItems {
            if !queryItems.contains(where: { $0.name == customQueryItem.name }) {
                queryItems.append(customQueryItem)
            }
        }
        components.queryItems = queryItems
        return components.url
    }
    
    private static func getStaticQueryItems(startDate: String) -> [URLQueryItem] {
        [URLQueryItem(name: "startDate", value: startDate),
         URLQueryItem(name: "utm_source", value: "nexusapp"),
         URLQueryItem(name: "lang", value: TRPClient.shared.language),
         URLQueryItem(name: "utm_medium", value: "tripian")]
    }
    
    private static func getProductIdAndType(productCode: String) -> (productId: String, prov: String, productType: String) {
        
        let parts = productCode.split(separator: "¬", omittingEmptySubsequences: false)

        guard parts.count > 1, let productIdPart = parts.first else {
            return (productCode, "TKT", "TKT")
        }
        
        let productId = String(productIdPart)
        
        if let productTypePart = parts[1].split(separator: "#", omittingEmptySubsequences: false).first {
            let productTypeStr = String(productTypePart)
            let productType = productTypeStr == "SGN" ? "TKT" : productTypeStr
            let prov = productType == "TKT" ? "SGN" : productType
            return (productId, prov, productType)
        }
        return (productId, "TKT", "TKT")
    }
}
