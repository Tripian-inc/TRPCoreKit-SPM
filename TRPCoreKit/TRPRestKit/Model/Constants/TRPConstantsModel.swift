//
//  TRPConstantsModel.swift
//  TRPRestKit
//
//  Created by Rozeri Dağtekin on 7/30/19.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPConstantsParentJsonModel: TRPParentJsonModel {
    
    public var data: TRPConstantsJsonModel?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try values.decodeIfPresent(TRPConstantsJsonModel.self, forKey: .data)
        try super.init(from: decoder)
    }
}

/// Parent Json parser model for TRPConstants & TRPVersion model.
internal class TRPConstantsJsonModel: Decodable {
    
    /// Version model
    public var version: TRPVersionInfoModel?
    public var constants: TRPConstantsInfoModel?

    private enum CodingKeys: String, CodingKey {
        case version
        case constants
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decodeIfPresent(TRPVersionInfoModel.self, forKey: .version)
        constants = try values.decodeIfPresent(TRPConstantsInfoModel.self, forKey: .constants)
    }
}

/// This model provides you to use full information of version details.
public struct TRPVersionInfoModel: Decodable {
    
    /// A Bool value. Shows whether force update reqiured or not.
    public var forceUpdateRequired: Bool
    /// A String value. Version of the forced update.
    public var forceUpdateVersion: String?
    /// A String value. Force update message.
    public var forceUpdateMessage: TRPLocalizableMessageInfoModel?
    /// A String value. Store Url.
    public var forceUpdateStroreUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case forceUpdateRequired = "force_update_required"
        case forceUpdateVersion = "force_update_version"
        case forceUpdateMessage = "force_update_message"
        case forceUpdateStoreUrl = "force_update_store_url"
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.forceUpdateRequired = try values.decode(Bool.self, forKey: .forceUpdateRequired)
        self.forceUpdateVersion = try values.decodeIfPresent(String.self, forKey: .forceUpdateVersion)
        self.forceUpdateMessage = try values.decodeIfPresent(TRPLocalizableMessageInfoModel.self, forKey: .forceUpdateMessage)
        self.forceUpdateStroreUrl = try values.decode(String.self, forKey: .forceUpdateStoreUrl)
    }
}

/// This model provides you to use full information of constants.
public struct TRPConstantsInfoModel: Decodable {
    
    /// A String value. Shows read me link.
    public var readMe: String?
    /// An Int value. Shows max day between user trips can be.
    public var maxDayBetweenTrips: Int?
    public var alertMessage: TRPConstantMessageInfoModel?
    
    private enum CodingKeys: String, CodingKey {
        case readMe = "read_me"
        case maxDayBetweenTrips = "max_day_between_trips"
        case alertMessage = "alert_message"
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.readMe = try values.decodeIfPresent(String.self, forKey: .readMe)
        self.maxDayBetweenTrips = try values.decodeIfPresent(Int.self, forKey: .maxDayBetweenTrips)
        self.alertMessage = try values.decodeIfPresent(TRPConstantMessageInfoModel.self, forKey: .alertMessage)
    }
}

/// This model provides you localizable message info model.
public struct TRPLocalizableMessageInfoModel: Decodable {
    
    /// A String value. Shows english version of message.
    public var english: String?
    /// A String value. Shows french version of message.
    public var french: String?
    
    private enum CodingKeys: String, CodingKey {
        case english = "en"
        case french = "fr"
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.english = try values.decodeIfPresent(String.self, forKey: .english)
        self.french = try values.decodeIfPresent(String.self, forKey: .french)
    }
}

public struct TRPConstantMessageInfoModel: Decodable {
    public var title: String?
    public var message: String?
}
