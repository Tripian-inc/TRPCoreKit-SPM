//
//  QuestionMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 30.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class QuestionMapper {
    
    func map(_ restModels: [TRPQuestionInfoModel]) -> [TRPQuestion] {
        return restModels.compactMap { map($0) }
    }
    
    func map(_ restModel: TRPQuestionInfoModel) -> TRPQuestion? {
        guard let answers = restModel.answers else {return nil}
        let converted = answers.map { map($0) }
        
        let convertedType = category(restModel.category)
        
        return TRPQuestion(id: restModel.id,
                           stepId: restModel.stepId,
                           skippable: restModel.skippable,
                           selectMultiple: restModel.selectMultiple,
                           name: restModel.name,
                           title: restModel.title,
                           iconUrl: restModel.iconUrl,
                           description: restModel.description,
                           theme: restModel.theme,
                           category: convertedType,
                           order: restModel.order,
                           answers: converted)
    }
    
    
    func map(_ restModel: TRPQuestionOptionsJsonModel) -> TRPQuestionAnswer {
        var subAnswers: [TRPQuestionAnswer]?
        
        if let restSubAnswers = restModel.subAnswers{
            subAnswers = restSubAnswers.map({map($0)})
        }
        
        return TRPQuestionAnswer(id: restModel.id,
                                 name: restModel.name,
                                 subAnswers: subAnswers,
                                 description: restModel.description)
    }
    
    private func category(_ category: TRPQuestionCategory) -> QuestionCategory {
        switch category {
        case .companion:
            return .companion
        case .profile:
            return .profile
        case .trip:
            return .trip
        }
    }
    
    
}
