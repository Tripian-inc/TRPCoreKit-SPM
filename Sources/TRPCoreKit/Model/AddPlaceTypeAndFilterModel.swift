//
//  AddPlaceTypeAndFilterModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
public struct AddPlaceTypes {
    public let id: Int
    public let name: String
    public let description: String
    public let condition: String
    public let order: Int
    //Bazı gruplarda birleştirme yapılıyor. Örneğin Bakery ile Dessert
    //SubType olarak biri eklenebilir
    public var subTypes:[Int] = []

    init(id:Int, name: String, description: String, condition: String, order: Int, subTypes: [Int] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.condition = condition
        self.order = order
        self.subTypes = subTypes
    }
}

public class AddPlaceGroups {
    public var id: Int
    public var name: String
    public var typeIds: [Int]
    public var types: [AddPlaceTypes]?
    
    init(id:Int, name: String, typesIds: [Int]) {
        self.id = id
        self.name = name
        self.typeIds = typesIds
    }
}
