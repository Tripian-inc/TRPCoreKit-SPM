//
//  TRPUserFeedbackJsonModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 26.04.2023.
//  Copyright © 2023 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPUserFeedbackJsonModel: TRPParentJsonModel {
    
    ///Favorite's list
    internal var data: [TRPUserFeedbackInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required internal init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let data = try? values.decodeIfPresent(TRPUserFeedbackInfoModel.self, forKey: .data) {
            self.data = [data] as? [TRPUserFeedbackInfoModel]
        } else if let datas = try? values.decodeIfPresent([TRPUserFeedbackInfoModel].self, forKey: .data) {
            self.data = datas
        }
        try super.init(from: decoder)
    }
}

/// This model provides you information of Favorites Poi.
public struct TRPUserFeedbackInfoModel: Decodable {
    
    public var subjectId: Int
    public var desc: String
    public var isRead: Bool
    public var subjectType: String
    public var createdAt: String
    public var replies: [TRPUserFeedbackReplyModel]
    
    public var poiId: String?
    public var tripHash: String?
    
    private enum CodingKeys: String, CodingKey {
        case poiId = "poi_id"
        case subjectId = "subject_id"
        case subjectType = "subject_type"
        case replies
        case tripHash = "trip_hash"
        case desc
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.subjectId = try values.decode(Int.self, forKey: .subjectId)
        self.desc = try values.decode(String.self, forKey: .desc)
        self.isRead = try values.decode(Bool.self, forKey: .isRead)
        self.subjectType = try values.decode(String.self, forKey: .subjectType)
        self.createdAt = try values.decode(String.self, forKey: .createdAt)
        self.replies = try values.decode([TRPUserFeedbackReplyModel].self, forKey: .replies)
        self.poiId = try values.decodeIfPresent(String.self, forKey: .poiId)
        self.tripHash = try values.decodeIfPresent(String.self, forKey: .tripHash)
    }
}

public class TRPUserFeedbackReplyModel: NSObject, Decodable {
    
    /// An Int value. Unique id of a city.
    public var sender: String
    public var reply: String
    public var createdAt: String
    
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case sender
        case reply
        case createdAt = "created_at"
    }
    
}
