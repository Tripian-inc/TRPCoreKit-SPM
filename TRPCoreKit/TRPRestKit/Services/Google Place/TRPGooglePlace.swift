//
//  TRPGooglePlace.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 5.02.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation

/// Google Place Model that provides use information
open class TRPGooglePlace: NSObject {
    
    /// A String value. Id of place
    public let id: String
    /// A String value. Address of place.
    public let mainAddress: String
    /// A String value. Detail of place's address.
    public let secondaryAddress: String
    
    /// An String value. Readable address format.
    override open var description: String {
        return "\(mainAddress), \(secondaryAddress)"
    }
    
    /// Initializes a new object with id, mainAdress and secondaryAddress.
    ///
    /// - Parameter decoder: Json decoder
    init(id: String, mainAddress: String, secondaryAddress: String) {
        self.id = id
        self.mainAddress = mainAddress
        self.secondaryAddress = secondaryAddress
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    convenience init(prediction: [String: Any]) {
        let structuredFormatting = prediction["structured_formatting"] as? [String: Any]
        self.init(
            id: prediction["place_id"] as? String ?? "",
            mainAddress: structuredFormatting?["main_text"] as? String ?? "",
            secondaryAddress: structuredFormatting?["secondary_text"] as? String ?? ""
        )
    }
}
