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
    var bold20: UIFont {get}
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
    var blue: UIColor {get}
    
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
        return UIFont(name: semiBold, size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
    }
    
    var display: UIFont {
        return UIFont(name: semiBold, size: 20) ?? .systemFont(ofSize: 20, weight: .semibold)
    }
    
    var header1: UIFont {
        return UIFont(name: semiBold, size: 18) ?? .systemFont(ofSize: 18, weight: .semibold)
    }
    
    var header2: UIFont {
        return UIFont(name: semiBold, size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
    }
    
    var header3: UIFont {
        return UIFont(name: semiBold, size: 22) ?? .systemFont(ofSize: 22, weight: .semibold)
    }
    
    var title0: UIFont {
        return UIFont(name: semiBold, size: 18) ?? .systemFont(ofSize: 18, weight: .semibold)
    }
    
    var title1: UIFont {
        return UIFont(name: semiBold, size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
    }
    
    var title2: UIFont {
        return UIFont(name: bold, size: 16) ?? .systemFont(ofSize: 16, weight: .bold)
    }
    
    var title3: UIFont {
        return UIFont(name: semiBold, size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
    }
    
    var body1: UIFont {
        
        return UIFont(name: regular, size: 16) ?? .systemFont(ofSize: 16)
    }
    
    var body2: UIFont {
        return UIFont(name: semiBold, size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
    }
    
    var body3: UIFont {
        return UIFont(name: regular, size: 12) ?? .systemFont(ofSize: 12)
    }
    
    var regular14: UIFont {
        return UIFont(name: regular, size: 14) ?? .systemFont(ofSize: 14)
    }
        
    var regular24: UIFont {
        return UIFont(name: regular, size: 24) ?? .systemFont(ofSize: 24)
    }
    
    var caption: UIFont {
        return UIFont(name: regular, size: 12) ?? .systemFont(ofSize: 12)
    }
    
    var semiBold12: UIFont {
        return UIFont(name: semiBold, size: 12) ?? .systemFont(ofSize: 12, weight: .semibold)
    }
    
    var medium14: UIFont {
        return UIFont(name: bold, size: 14) ?? .systemFont(ofSize: 14, weight: .bold)
    }
    
    var medium12: UIFont {
        return UIFont(name: bold, size: 12) ?? .systemFont(ofSize: 12, weight: .bold)
    }
    
    var regular28: UIFont {
        return UIFont(name: regular, size: 28) ?? .systemFont(ofSize: 28)
    }
    
    var regular22: UIFont {
        return UIFont(name: regular, size: 22) ?? .systemFont(ofSize: 22)
    }
    
    var regular10: UIFont {
        return UIFont(name: regular, size: 10) ?? .systemFont(ofSize: 10)
    }
    
    var bold20: UIFont {
        return UIFont(name: bold, size: 20) ?? .systemFont(ofSize: 20)
    }
    
}

class TRPColor1: TRPColorStyle {
    
    var extraShadow: UIColor = UIColor(named: "extra_shadow", in: Bundle.module, compatibleWith: nil)!
    
    var tabbarColor: UIColor = UIColor(named: "tabbar_color", in: Bundle.module, compatibleWith: nil)!
    
    var goldAccent: UIColor = UIColor(named: "gold_accent", in: Bundle.module, compatibleWith: nil)!
    
    var violet: UIColor = UIColor(named: "violent", in: Bundle.module, compatibleWith: nil)!
    
    var deepPink: UIColor = UIColor(named: "deep_pink", in: Bundle.module, compatibleWith: nil)!
    
    var shadeGold: UIColor = UIColor(named: "shade_gold", in: Bundle.module, compatibleWith: nil)!
    
    var shadeViolent: UIColor = UIColor(named: "shade_violent", in: Bundle.module, compatibleWith: nil)!
    
    var shadePink: UIColor = UIColor(named: "shade_pink", in: Bundle.module, compatibleWith: nil)!
    
    var textHead: UIColor = UIColor(named: "text_header", in: Bundle.module, compatibleWith: nil)!
    
    var textBody: UIColor = UIColor(named: "text_body", in: Bundle.module, compatibleWith: nil)!

    var extraMain: UIColor = UIColor(named: "extra_main", in: Bundle.module, compatibleWith: nil)!
    
    var shadowMain: UIColor = UIColor(named: "extra_shadow", in: Bundle.module, compatibleWith: nil)!
    
    var extraSub: UIColor = UIColor(named: "extra_sub", in: Bundle.module, compatibleWith: nil)!
    
    var extraBG: UIColor = UIColor.white
    
    //TODO
    var subMain: UIColor = UIColor(named: "text_header", in: Bundle.module, compatibleWith: nil)!
    
    var bg1: UIColor = UIColor(named: "bg1", in: Bundle.module, compatibleWith: nil)!
    
    //TODO
    var bg2: UIColor = UIColor(named: "text_header", in: Bundle.module, compatibleWith: nil)!
    var blue: UIColor = UIColor(named: "blue", in: Bundle.module, compatibleWith: nil)!
    
    var tripianPrimary: UIColor = UIColor(named: "tripian_primary", in: Bundle.module, compatibleWith: nil)!
    
    var tripianLightGrey: UIColor = UIColor(named: "tripian_light_grey", in: Bundle.module, compatibleWith: nil)!
    
    var tripianBlack: UIColor = .black // UIColor(named: "tripian_light_grey", in: Bundle.module, compatibleWith: nil)!
    
    var tripianTextPrimary: UIColor = UIColor(named: "tripian_text_primary", in: Bundle.module, compatibleWith: nil)!
    
}

public enum ColorSet {
    case mainDark
    case mainGrayBg
    case strokeGrey20
    case strokeGrey10
    case textDark80
    case textDark64
    case textDark48
    case mainGreySidebar
    case white
    case additionalYellow100
    case additionalOrange
    case additionalRed
    
    public var uiColor: UIColor {
        switch self {
        case .white:
            return .white
        case .mainDark:
            return UIColor(named: "main_dark", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .mainGrayBg:
            return UIColor(named: "main_gray_bg", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .strokeGrey20:
            return UIColor(named: "stroke_grey_20", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .strokeGrey10:
            return UIColor(named: "stroke_grey_10", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .textDark64:
            return UIColor(named: "text_dark_64", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .textDark80:
            return UIColor(named: "text_dark_80", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .textDark48:
            return UIColor(named: "text_dark_48", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .mainGreySidebar:
            return UIColor(named: "main_gray_sidebar", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .additionalYellow100:
            return UIColor(named: "additional_yellow_100", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .additionalOrange:
            return UIColor(named: "additional_orange", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        case .additionalRed:
            return UIColor(named: "additional_red", in: Bundle(identifier: "com.tripian.TRPCoreKit")!, compatibleWith: nil)!
        }
    }
    
    // A new method to get the color with a specified alpha value.
    public func uiColor(alpha: CGFloat) -> UIColor {
        return self.uiColor.withAlphaComponent(alpha)
    }
    
    public static func getMapColors() -> [UIColor] {
        let blueColor = UIColor(red: 53/255.0, green: 152/255.0, blue: 218/255.0, alpha: 1.0)
        let greenColor = UIColor(red: 38/255.0, green: 202/255.0, blue: 28/255.0, alpha: 1.0)
        
        return [blueColor,
                trpTheme.color.shadeViolent,
                greenColor,
                trpTheme.color.deepPink,
                trpTheme.color.goldAccent,
                trpTheme.color.tripianBlack]
    }
}
