//
//  UIFont+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 10.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
extension UIFont {

    func withTraits(_ traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor
            .withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits).union(self.fontDescriptor.symbolicTraits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    func withoutTraits(_ traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor
            .withSymbolicTraits(  self.fontDescriptor.symbolicTraits.subtracting(UIFontDescriptor.SymbolicTraits(traits)))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    func bold() -> UIFont {
        return withTraits( .traitBold)
    }

    func italic() -> UIFont {
        return withTraits(.traitItalic)
    }

    func noItalic() -> UIFont {
        return withoutTraits(.traitItalic)
    }
    func noBold() -> UIFont {
        return withoutTraits(.traitBold)
    }
}
