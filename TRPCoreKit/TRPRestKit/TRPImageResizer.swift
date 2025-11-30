//
//  TRPImageResizer.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 30.10.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

public enum TRPImageSizeStandart {
    case small, small2, placeDetail, myTrip, listItem
    
    public var size: (width: Int, height: Int) {
        switch self {
        case .small:
            return (width: 64, height: 64)
        case .small2:
            return (width: 256, height: 256)
        case .listItem:
            return (width: 248, height: 192)
        case .placeDetail:
            return devices()
        case .myTrip:
            return devices()
        }
    }
    
    public func devices() -> (width: Int, height: Int) {
        /*if UIDevice().userInterfaceIdiom == .phone {
            return (width: 800, height: 600)
        }*/
        return (width: 800, height: 600)
    }
}

/// Provides new link to resizing Images
public struct TRPImageResizer {
    
    public init() {}

    /// Gorsellerin yeniden boyutlandırılacağı linkleri standartlar dahilinde oluşturur
    /// - Parameters:
    ///   - url: Gorselin Url i
    ///   - standart: daha önceden belirlenmiş boyutları içerir.
    public static func generate(withUrl url: String?, standart: TRPImageSizeStandart, type: String? = nil) -> String? {
        
        return generate(withUrl: url, width: standart.size.width, height: standart.size.height, type: type)
    }
    
    /// New link of image generater
    ///
    /// - Parameters:
    ///   - link: Image source link
    ///   - width: target width
    ///   - height: target height
    /// - Returns: new link 
    public static func generate(withUrl link: String?, width: Int, height: Int, type: String? = nil) -> String? {
        guard let url = link, let component = URLComponents(string: url) else {return nil}
        var path = component.path
        if let type = type, let range = path.range(of: "/\(type)/") {
            let substring = path[range.lowerBound...]
            path = String(substring)
        }
        return "https://d2v9cz8rnpdl6f.cloudfront.net/\(width)x\(height)\(path)"
    }
}
