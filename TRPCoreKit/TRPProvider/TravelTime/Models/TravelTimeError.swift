//
//  TravelTimeError.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 16.06.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public struct TravelTimeError: Codable {
    public let httpStatus: Int
    public let errorCode: Int
    public let description: String?
    public let documentationLink: String?
    public let additionalInfo: TravelTimeErrorAdditionalInfo?
    
    enum CodingKeys: String, CodingKey {
        case httpStatus = "http_status"
        case errorCode = "error_code"
        case description = "description"
        case documentationLink = "documentation_link"
        case additionalInfo = "additional_info"
    }
}

public struct TravelTimeErrorAdditionalInfo: Codable {
    public let syntaxErrors: [String]?
    public let searchId: [String]?
    public let supportedContentTypes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case syntaxErrors = "syntax_errors"
        case searchId = "search_id"
        case supportedContentTypes = "supported_content_types"
    }
}
