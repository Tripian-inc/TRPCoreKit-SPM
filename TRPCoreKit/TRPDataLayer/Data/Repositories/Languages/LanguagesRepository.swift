//
//  LanguagesRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 8.09.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public protocol LanguagesRepository {
    var results: TRPLanguagesInfoModel? {get set}
    var currentLanguageResults: [String: Any] {get set}
    
    func fetchLanguages(completion: @escaping ((Result<TRPLanguagesInfoModel, Error>) -> Void))
}
