//
//  PartOfDayMatch.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 16.04.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit

struct PartOfDayMatch {
    
    public static func createExplaineText(partOfDay: [Int]? = nil,
                                          matchRate: Int? = nil) -> NSMutableAttributedString{
        let matchRateStyle = [NSAttributedString.Key.font: trpTheme.font.body2, .foregroundColor: trpTheme.color.tripianPrimary]
        let partOfDayStyle = [NSAttributedString.Key.font: trpTheme.font.body3, .foregroundColor: trpTheme.color.extraMain]
        
        let mainSentence = NSMutableAttributedString(string: "", attributes: nil)
        
        
        if let matchRate = matchRate {
            let match = NSMutableAttributedString(string: "\(matchRate)% match", attributes: matchRateStyle)
            mainSentence.append(match)
        }
        
        if let partOfDayNumber = partOfDay, !partOfDayNumber.isEmpty {
            let exp = arrayToStringWithAnd(ar: partOfDayNumber)
            var text = ""
            if matchRate != nil {
                text += " - "
            }
            text += "Part of day \(exp)"
            let partOfDaySentence = NSMutableAttributedString(string: text, attributes: partOfDayStyle)
            mainSentence.append(partOfDaySentence)
        }
        return mainSentence
    }
    
    static func arrayToStringWithAnd(ar: [Int]) -> String {
        let sonIki = ar.suffix(2)
        var metin = Array(sonIki).toString(" and ")
        if ar.count - 2 > 0 {
            let diger = ar.prefix(ar.count - 2)
            metin = Array(diger).toString(", ") + ", " + metin
        }
        return metin
    }
}
