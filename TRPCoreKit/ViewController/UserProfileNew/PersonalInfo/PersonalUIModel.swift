//
//  PersonalUIModel.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-05-14.
//

import Foundation

struct PersonalUIModel{
    let name: String
    let lastName: String
    let email: String
    let dateOfBirth: String
    let answers: [Int]
}

extension PersonalUIModel {
    
    init(_ response: TRPUser) {
        name = response.firstName ?? ""
        lastName = response.lastName ?? ""
        email = response.email
        dateOfBirth = response.dateOfBirth ?? ""
        answers = response.answers ?? []
    }
}
