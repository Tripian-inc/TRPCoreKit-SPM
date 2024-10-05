//
//  LanguagesRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 8.09.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public protocol LanguagesRepository {
    var results: [String: Any] {get set}
    
    func fetchLanguages(completion: @escaping ((Result<[String : Any], Error>) -> Void))
}
