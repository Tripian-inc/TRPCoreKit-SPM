//
//  TRPConfigListParentJsonModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 26.09.2024.
//  Copyright © 2024 Evren Yaşar. All rights reserved.
//

import Foundation

//internal class TRPConfigListParentJsonModel: TRPParentJsonModel {
//    
//    public var data: TRPConfigListJsonModel?
//    
//    private enum CodingKeys: String, CodingKey {
//        case data
//    }
//    
//    required public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        self.data = try values.decodeIfPresent(TRPConfigListJsonModel.self, forKey: .data)
//        try super.init(from: decoder)
//    }
//}
//
//internal class TRPConfigListJsonModel: Decodable {
//    
//    public var  apiKey: String
//    public var  whiteLabels: WhiteLabels
//    public var  baseFeatures: BaseFeatures
//    public var  providers: Providers
//    public var  sbt: Sbt
//    public var  androidVersionCode: Int
//    public var  androidVersionName: String
//
//    private enum CodingKeys: String, CodingKey {
//        case version
//        case constants
//    }
//    
//    required init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        version = try values.decodeIfPresent(TRPVersionInfoModel.self, forKey: .version)
//        constants = try values.decodeIfPresent(TRPConstantsInfoModel.self, forKey: .constants)
//    }
//}
//
//internal class TRP
