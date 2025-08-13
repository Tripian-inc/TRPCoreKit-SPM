//
//  TRPClient.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 2.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// This class provide you to start TRPRestKit.
/// Class was written with Observer Dessing pattern
///
/// - seeAlso: [Request Api Key](https://www.tripian.com/request-api-key/)
///
/// ### Usage Example: ###
///  ````
///   TRPClient.provideApiKey(#<YourApiKey>#)
///  ````
@objc public class TRPClient: NSObject {
    
    internal static var shared = TRPClient()
    
    /// Allows link to be shown
    public var monitorUrl = false
    /// Allows Data to be shown
    public var monitorData = false
    
//    public var isReverseProxy = false
//    public var reverseProxyURL: String = ""
    
    internal var enviroment: Environment = .dev {
        didSet {
//            Log.i("Enviroment was changed: \(self.enviroment)")
            self.baseUrl = self.enviroment.baseUrl
        }
    }
    
    internal var baseUrl: BaseUrlCreater = Environment.test.baseUrl
    
    internal var firebaseToken: String = ""
    
    internal var language: String = "en"
    
    private override init() {}
    
    public static func start(enviroment: Environment, apiKey: String, language: String = "en") {
        TRPClient.shared.enviroment = enviroment
        TRPClient.shared.language = language
        TRPApiKey.setApiKey(apiKey)
    }
    
     public static func start(baseUrl: BaseUrlCreater, apiKey: String) {
        TRPClient.shared.baseUrl = baseUrl
        TRPApiKey.setApiKey(apiKey)
    }
    
     public static func start(baseUrl: BaseUrlCreater, apiKey: String, language: String) {
        TRPClient.shared.baseUrl = baseUrl
        TRPClient.shared.language = language
        TRPApiKey.setApiKey(apiKey)
    }
    
     public static func setFirebaseToken(_ token: String) {
        TRPClient.shared.firebaseToken = token
    }
    
     public static func monitor(data: Bool? = false, url: Bool? = false) {
        TRPClient.shared.monitorUrl = url ?? false
        TRPClient.shared.monitorData = data ?? false
    }
    
    ///Reverse proxy connection
     public static func start(baseUrl: BaseUrlCreater, apiKey: String, reverseProxyUrl: String) {
        TRPClient.shared.baseUrl = baseUrl
        TRPApiKey.setApiKey(apiKey)
        
//        TRPClient.shared.reverseProxyURL = reverseProxyUrl
//        TRPClient.shared.isReverseProxy = true
    }
    
}
