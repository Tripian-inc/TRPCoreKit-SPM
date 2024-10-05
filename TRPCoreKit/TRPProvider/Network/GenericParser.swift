//
//  GenericParser.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 3.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
internal class GenericParser<T: Decodable> {
    
    let decoder: JSONDecoder
    
    internal init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    internal func parse(data: Data?, completion: @escaping (Result<T?, Error>) -> Void) {
        guard let data = data else {return }
        do {
            let result = try decoder.decode(T.self, from: data)
            completion(.success(result))
        }catch(let error) {
            print("Json Parser Error \(error)")
            
            completion(.failure(error))
        }
    }
    
}
