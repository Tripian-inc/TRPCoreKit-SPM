//
//  ProblemCategoriesHolder.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 28.03.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation

public class ProblemCategoriesHolder {
    
    public static let shared = ProblemCategoriesHolder()
    private var data = [TRPProblemCategoriesInfoModel]()
    
    public func categories(completion: @escaping (_ data: [TRPProblemCategoriesInfoModel]?,
        _ error: NSError? ) -> Void) {
        if !data.isEmpty {
            completion(data,nil)
            return
        }
        TRPRestKit().problemCategories {[weak self] (data, error) in
            guard let strongSelf = self else {return}
            if let error = error {
                completion(nil, error)
                return
            }
            if let data = data as? [TRPProblemCategoriesInfoModel] {
                strongSelf.data = data
                completion(data,nil)
            }
        }
    }
    
}
