//
//  TRPCheckUpdateJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 27.06.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
//NOT USED NOW
/**
public class TRPCheckUpdateJsonModel: TRPParentJsonModel {
    
    public var data: [String:TRPCheckUpdateInfoModel]?;
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let datas = try? values.decodeIfPresent([String:TRPCheckUpdateInfoModel].self, forKey: .data) {
            self.data = datas
        }
        try super.init(from: decoder);
    }
    
}

public class TRPCheckUpdateInfoModel:NSObject, Decodable {
    
    public var added: Int?;
    public var updated: Int?;
    public var deleted: Int?;
    public var url: String?;
    
    private enum CodingKeys: String, CodingKey {
        case added
        case updated
        case deleted
        case url
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self);
        self.added = try values.decodeIfPresent(Int.self, forKey: .added);
        self.updated = try values.decodeIfPresent(Int.self, forKey: .updated);
        self.deleted = try values.decodeIfPresent(Int.self, forKey: .deleted);
        self.url = try values.decodeIfPresent(String.self, forKey: .url);
    }
} */
