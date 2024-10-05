//
//  TRPFileErrors.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 19.06.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation

public enum TRPFileErrors:Error{
    case bundleNotFound(name: String)
    case fileNotFound(name:String)
}

extension TRPFileErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bundleNotFound(let name):
            return NSLocalizedString("TRPCoreKit: Bundle not found. Bundle name: \(name)", comment: "");
        case .fileNotFound(let name):
            return NSLocalizedString("TRPCoreKit: File not found. File name: \(name)", comment: "");
        }
    }
}

extension TRPFileErrors: CustomNSError {
    
    public static var errorDomain: String {
        return "TRPClientError";
    }
    
    public var errorCode: Int {
        switch self {
        default:
            return 999
        }
    }
    public var errorUserInfo: [String : Any]{
        switch self {
        default:
            return [:];
        }
    }
    
}
