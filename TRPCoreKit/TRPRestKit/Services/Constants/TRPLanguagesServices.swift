//
//  TRPLanguagesServices.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 8.09.2024.
//  Copyright © 2024 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPLanguagesServices: TRPRestServices<TRPLanguagesInfoModel> {
    
    internal override init() {}
    
    override func path() -> String {
        return "misc/frontend-translations"
    }
    
    override func requestMode() -> TRPRequestMode {
        return .get
    }
    
}
