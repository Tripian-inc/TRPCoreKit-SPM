//
//  TRPNetworkError.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 2.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// A type representing an error value that can be thrown.
///
/// - undefined: Undifened error
/// - httpResult: HTTP error that was send from Tripian server
/// - wrongData: Wrond data type
/// - emptyData: Empdty data
/// - emptyDataOrParserError: Json parser problem
/// - objectIsNil: Object is nil
/// - someThingWronk: Undifened error with message
public enum TRPErrors: Error {
    case undefined
    case httpResult(code: Int, des: String, info: [String:Any])
    case wrongData
    case emptyData
    case emptyDataOrParserError
    case objectIsNil(name: String)
    case someThingWronk(_ message: String)
    case jsonParserError(code: Int)
}

extension TRPErrors: LocalizedError {
    
    /// Return Error Message Description using NSLocalizedString
    public var errorDescription: String? {
        switch self {
        case .httpResult(_, let message, _):
            return NSLocalizedString(message, comment: "")
        case .undefined:
            return NSLocalizedString("Undefined error", comment: "")
        case .wrongData:
            return NSLocalizedString("Wrong Data", comment: "")
        case .emptyData:
            return NSLocalizedString("Empty Data", comment: "")
        case .emptyDataOrParserError:
            return NSLocalizedString("Empty data or couldn't parse json", comment: "")
        case .objectIsNil(let name):
            return NSLocalizedString("\(name) is a nil", comment: "")
        case .jsonParserError(let code):
            return NSLocalizedString("Empty data or couldn't parse json. Code: \(code)", comment: "")
        case .someThingWronk(let message):
            return NSLocalizedString("\(message)", comment: "")
        }
    }
}

extension TRPErrors: CustomNSError {
    
    /// Framework Domain
    public static var errorDomain: String {
        return "com.tripian.TRPClientError"
    }
    
    /// When a Http Error is occered, error code returns it.
    public var errorCode: Int {
        switch self {
        case .httpResult(let code, _, _):
            return code
        default:
            return 999
        }
    }
    
}

extension TRPErrors {
    
    /// This method is parse a Tripian Json Model
    ///
    /// - Parameters:
    ///   - json: Json Model
    ///   - link: Url
    init?(json: JSON, link: String?) {
        if let status = json["success"] as? Bool {
            if status == false {
                guard let message = json["message"] as? String,
                    let status = json["status"] as? Int else {
                        self = .undefined
                        return nil
                }
                var info = [String: Any]()
                info["description"] = message
                info["code"] = status
                if let link = link {
                    info["link"] = link
                }
                self = .httpResult(code: status, des: message, info:info)
                return
            }
        }
        return nil
    }
    
}
