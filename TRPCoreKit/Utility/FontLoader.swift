//
//  FontLoader.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 9.07.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//


import UIKit
import CoreText

public enum TRPFonts {
    private static var didRegister = false

    /// Call this once early (e.g., at app launch).
    @discardableResult
    public static func registerAll() -> [String] {
        guard !didRegister else { return postScriptNames() }
        didRegister = true

        for ext in ["ttf", "otf"] {
            let urls = Bundle.module.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") ?? []
            for url in urls {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        return postScriptNames()
    }

    /// Helpful to log the exact names `UIFont`/`Font.custom` expect.
    public static func postScriptNames() -> [String] {
        var result: [String] = []
        for ext in ["ttf", "otf"] {
            let urls = Bundle.module.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") ?? []
            for url in urls {
                guard let data = try? Data(contentsOf: url),
                      let provider = CGDataProvider(data: data as CFData),
                      let cgFont = CGFont(provider),
                      let ps = cgFont.postScriptName as String? else { continue }
                result.append(ps)
            }
        }
        return result
    }
}
