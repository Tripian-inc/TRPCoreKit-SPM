//
//  Bundle+Extensions.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 10.04.2023.
//  Copyright © 2023 Tripian Inc. All rights reserved.
//


extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
