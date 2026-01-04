//
//  Array+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 12.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
extension Array {
    func unique<T:Hashable>(by: ((Element) -> (T)))  -> [Element] {
        var set = Set<T>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() //keeping the unique list of elements but ordered
        for value in self {
            if !set.contains(by(value)) {
                set.insert(by(value))
                arrayOrdered.append(value)
            }
        }
        
        return arrayOrdered
    }
    
    public func toString(_ separator:String? = nil) -> String {
        let arrayToString = self.map{"\($0)"}
        return arrayToString.joined(separator: separator != nil ? separator! : ",")
    }
    
}
extension Array where Element: Equatable {
    
    /// Remove first collection element that is equal to the given `object` or `element`:
    mutating func remove(element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        }
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

extension RangeReplaceableCollection where Element: Equatable {
    @discardableResult
    mutating func appendIfNotContains(_ element: Element) -> (appended: Bool, memberAfterAppend: Element) {
        if let index = firstIndex(of: element) {
            return (false, self[index])
        } else {
            append(element)
            return (true, element)
        }
    }
}
