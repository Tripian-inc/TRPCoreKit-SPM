//
//  TRPCoordinateModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

public struct TRPAdditionalDataModel: Decodable {
    
    public var bookingUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case bookingUrl
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bookingUrl = try values.decodeIfPresent(String.self, forKey: .bookingUrl)
    }
}

public final class AdditionalDataMapper {
    func map(_ restModel: TRPAdditionalDataModel?) -> TRPAdditionalData? {
        guard let restModel else { return nil }
        return TRPAdditionalData(bookingUrl: restModel.bookingUrl)
    }
}
