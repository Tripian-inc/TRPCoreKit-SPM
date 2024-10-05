//
//  CompanionMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

final class CompanionMapper {
    
    func map(_ restModel: TRPCompanionModel) -> TRPCompanion {
        return TRPCompanion(id: restModel.id,
                            name: restModel.name,
                            answers: restModel.answers,
                            title: restModel.title,
                            age: restModel.age)
    }
    
    func map(_ restModels: [TRPCompanionModel]) -> [TRPCompanion] {
        return restModels.map { map($0)}
    }
    
}
