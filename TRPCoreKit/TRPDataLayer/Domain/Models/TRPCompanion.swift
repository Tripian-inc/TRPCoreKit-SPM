//
//  TRPCompanion.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct TRPCompanion {
    
    public var id: Int
    public var name: String
    public var answers: [Int]
    public var title: String?
    public var age: Int?
 
    public init(id: Int, name: String, answers: [Int], title: String?, age: Int?) {
        self.id = id
        self.name = name
        self.answers = answers
        self.title = title
        self.age = age
    }
    
}

extension TRPCompanion: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
}
