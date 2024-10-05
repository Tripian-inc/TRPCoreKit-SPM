//
//  Networking.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol NetworkSession {
    func load(from urlRequest: URLRequest, completionHandler: @escaping (Data?, NetworkResponse?, Error?) -> Void)
}


extension URLSession: NetworkSession {
    
    
    public func load(from urlRequest: URLRequest, completionHandler: @escaping (Data?, NetworkResponse?, Error?) -> Void) {
        
        
        let task = dataTask(with: urlRequest) { [weak self] (data, response, error) in
            
            var networkResponse: NetworkResponse?
            
            if let response = response, let httpResponse = response as? HTTPURLResponse {
                networkResponse = self?.handleNetworkResponse(httpResponse)
            }
            
            completionHandler(data, networkResponse, error)
            
        }
        task.resume()
    }
    
    
    /// HTTPResponse yanıtlarını readble hale getirir
    /// - Parameter response: HTTPResponse
    /// - Returns: NetworkReponse
    private func handleNetworkResponse(_ response: HTTPURLResponse) -> NetworkResponse {
        switch response.statusCode {
        case 200...299: return .success
        case 401...500: return .authenticationError
        case 500...599: return .badRequest
        case 600: return .outDated
        default: ()
        }
        return .failed
    }
}



public class Networking {
    
    
    private(set) var session: NetworkSession
    
    public init(session: NetworkSession = URLSession.shared) {
        
        self.session = session
    }
    
    public func load(url: URLRequest, completion: @escaping (Result<Data?, Error>) -> Void) {
        session.load(from: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }else {
                completion(.success(data))
            }
        }
    }
    
    
}
