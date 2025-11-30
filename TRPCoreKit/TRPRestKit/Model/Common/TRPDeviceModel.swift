//
//  TRPDeviceModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 11.08.2024.
//  Copyright © 2024 Evren Yaşar. All rights reserved.
//

import Foundation
import UIKit


public struct TRPDeviceModel: Decodable, Encodable {
    
    public var deviceId: String?
    public var deviceOs: String = "iOS"
    public var osVersion: String?
    public var bundleId: String?
    public var firebaseToken: String? = "xx_nexus_app"
    
    private enum CodingKeys: String, CodingKey {
        case deviceId = "deviceId"
        case deviceOs = "deviceOs"
        case osVersion = "osVersion"
        case firebaseToken = "serviceToken"
        case bundleId = "bundleId"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.deviceId = try values.decodeIfPresent(String.self, forKey: .deviceId)
        self.deviceOs = try values.decodeIfPresent(String.self, forKey: .deviceOs) ?? "iOS"
        self.osVersion = try values.decodeIfPresent(String.self, forKey: .osVersion)
        self.bundleId = try values.decodeIfPresent(String.self, forKey: .bundleId)
        self.firebaseToken = try values.decodeIfPresent(String.self, forKey: .firebaseToken)
    }
    
    public init(deviceId: String,
                deviceOS: String? = nil,
                osVersion: String? = nil,
                bundleId: String? = nil,
                firebaseToken: String? = nil) {
        
        self.deviceId = deviceId
        self.osVersion = osVersion
        if let dOs = deviceOS {
            self.deviceOs = dOs
        }
        self.bundleId = bundleId
        self.firebaseToken = firebaseToken
    }
    
    public init(device: UIDevice = .current,
                bundleId: String? = nil,
                firebaseToken: String? = nil) {
        self.deviceId = TRPDeviceModel.getUUID()
        self.deviceOs = UIDevice.current.systemName
        self.osVersion = UIDevice.current.systemVersion
        self.firebaseToken = firebaseToken
        self.bundleId = bundleId
    }
    
    public init() {
        var uuid = TRPDeviceModel.getUUID()
        self.deviceId = uuid
        self.deviceOs = UIDevice.current.systemName
        self.osVersion = UIDevice.current.systemVersion
        self.bundleId = Bundle.main.bundleIdentifier
        
        if !TRPClient.shared.firebaseToken.isEmpty {
            self.firebaseToken = TRPClient.shared.firebaseToken
        }
    }
    
    public func params() -> [String: String]? {
        var params = [String: String]()
        
        params[CodingKeys.deviceId.rawValue] = deviceId
        
        params[CodingKeys.deviceOs.rawValue] = deviceOs
        
        if let osVersion = osVersion {
            params[CodingKeys.osVersion.rawValue] = osVersion
        }
        
        if let firebase = firebaseToken, !firebase.isEmpty {
            params[CodingKeys.firebaseToken.rawValue] = firebase
        }
        
        if let bundleId = bundleId {
            params[CodingKeys.bundleId.rawValue] = bundleId
        }
        
        return params
    }
}

extension TRPDeviceModel {
    public func convertToTRPDevice() -> TRPDevice {
        var trpDevice = TRPDevice()
        trpDevice.firebaseToken = self.firebaseToken
        trpDevice.bundleId = self.bundleId
        trpDevice.deviceId = TRPDeviceModel.getUUID()
        trpDevice.deviceOs = self.deviceOs
        trpDevice.osVersion = self.osVersion
        return trpDevice
    }
}

extension TRPDeviceModel {
    public static func getUUID() -> String {
        if let uuid = UserDefaults.standard.string(forKey: "generated_uuid") {
            return uuid
        }
        var uuid = ""
        if let uuidString = UIDevice.current.identifierForVendor?.uuidString {
            uuid = uuidString
        } else {
            uuid = UUID().uuidString
        }
        UserDefaults.standard.set(uuid, forKey: "generated_uuid")
        return uuid
    }
}
