//
//  TRPTheme.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-19.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

protocol TRPFontStyle {
    var display: UIFont {get}
    var header1: UIFont {get}
    var header2: UIFont {get}
    var body1: UIFont {get}
    var body2: UIFont {get}
    var body3: UIFont {get}
    var regular14: UIFont {get}
    var regular24: UIFont {get}
    
    var caption: UIFont {get}
//    var header1: UIFont {get}
//    var header2: UIFont {get}
    var header3: UIFont {get}
    var title0: UIFont {get}
    var title1: UIFont {get}
    var title2: UIFont {get}
    var title3: UIFont {get}
//    var body1: UIFont {get}
//    var body2: UIFont {get}
//    var body3: UIFont {get}
    var semiBold12: UIFont {get}
    var medium14: UIFont {get}
    var medium12: UIFont {get}
    var regular28: UIFont {get}
    var regular22: UIFont {get}
    var regular10: UIFont {get}
}

protocol TRPColorStyle {
    var goldAccent: UIColor {get}
//    var violet: UIColor {get}
    var deepPink: UIColor {get}
    var shadeGold: UIColor {get}
    var shadeViolent: UIColor {get}
    var shadePink: UIColor {get}
    
//    var textHead: UIColor {get}
    var textBody: UIColor {get}
    
    var extraMain: UIColor {get}
    var shadowMain: UIColor {get}
    var subMain: UIColor {get}
    var extraSub: UIColor {get}
    var extraShadow: UIColor {get}
    var extraBG: UIColor {get}
    var bg1: UIColor {get}
    var bg2: UIColor {get}
    
    var tabbarColor: UIColor {get}
    
    var tripianPrimary: UIColor {get}
    var tripianLightGrey: UIColor {get}
    var tripianBlack: UIColor {get}
    var tripianTextPrimary: UIColor {get}
}

protocol TRPStyleProtocol {
    
    var font: TRPFontStyle {get}
    
    var color: TRPColorStyle {get}
}


class TRPTheme1: TRPStyleProtocol {
    var font: TRPFontStyle {
        TRPFont1()
    }
    
    var color: TRPColorStyle {
        return TRPColor1()
    }
    
}
class TRPFont1: TRPFontStyle {
    let semiBold = "Poppins-SemiBold"
    let bold = "Poppins-Bold"
    let regular = "Poppins-Regular"
    
    var button: UIFont {
        return UIFont(name: semiBold, size: 14)!
    }
    
    var display: UIFont {
        return UIFont(name: semiBold, size: 20)!
    }
    
    var header1: UIFont {
        return UIFont(name: semiBold, size: 18)!
    }
    
    var header2: UIFont {
        return UIFont(name: semiBold, size: 16)!
    }
    
    var header3: UIFont {
        return UIFont(name: semiBold, size: 22)!
    }
    
    var title0: UIFont {
        return UIFont(name: semiBold, size: 18)!
    }
    
    var title1: UIFont {
        return UIFont(name: semiBold, size: 16)!
    }
    
    var title2: UIFont {
        return UIFont(name: bold, size: 16)!
    }
    
    var title3: UIFont {
        return UIFont(name: semiBold, size: 14)!
    }
    
    var body1: UIFont {
        
        return UIFont(name: regular, size: 16)!
    }
    
    var body2: UIFont {
        return UIFont(name: semiBold, size: 14)!
    }
    
    var body3: UIFont {
        return UIFont(name: regular, size: 12)!
    }
    
    var regular14: UIFont {
        return UIFont(name: regular, size: 14)!
    }
        
    var regular24: UIFont {
        return UIFont(name: regular, size: 24)!
    }
    
    var caption: UIFont {
        return UIFont(name: regular, size: 12)!
    }
    
    var semiBold12: UIFont {
        return UIFont(name: semiBold, size: 12)!
    }
    
    var medium14: UIFont {
        return UIFont(name: bold, size: 14)!
    }
    
    var medium12: UIFont {
        return UIFont(name: bold, size: 12)!
    }
    
    var regular28: UIFont {
        return UIFont(name: regular, size: 28)!
    }
    
    var regular22: UIFont {
        return UIFont(name: regular, size: 22)!
    }
    
    var regular10: UIFont {
        return UIFont(name: regular, size: 10)!
    }
    
}

class TRPColor1: TRPColorStyle {
    
    var extraShadow: UIColor = UIColor(named: "extra_shadow", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var tabbarColor: UIColor = UIColor(named: "tabbar_color", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var goldAccent: UIColor = UIColor(named: "gold_accent", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var violet: UIColor = UIColor(named: "violent", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var deepPink: UIColor = UIColor(named: "deep_pink", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var shadeGold: UIColor = UIColor(named: "shade_gold", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var shadeViolent: UIColor = UIColor(named: "shade_violent", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var shadePink: UIColor = UIColor(named: "shade_pink", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var textHead: UIColor = UIColor(named: "text_header", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var textBody: UIColor = UIColor(named: "text_body", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!

    var extraMain: UIColor = UIColor(named: "extra_main", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var shadowMain: UIColor = UIColor(named: "extra_shadow", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var extraSub: UIColor = UIColor(named: "extra_sub", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var extraBG: UIColor = UIColor.white
    
    //TODO
    var subMain: UIColor = UIColor(named: "text_header", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var bg1: UIColor = UIColor(named: "bg1", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    //TODO
    var bg2: UIColor = UIColor(named: "text_header", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var tripianPrimary: UIColor = UIColor(named: "tripian_primary", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var tripianLightGrey: UIColor = UIColor(named: "tripian_light_grey", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var tripianBlack: UIColor = .black // UIColor(named: "tripian_light_grey", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
    var tripianTextPrimary: UIColor = UIColor(named: "tripian_text_primary", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
    
}
