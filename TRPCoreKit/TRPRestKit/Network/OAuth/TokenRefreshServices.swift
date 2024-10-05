//
//  TokenRefreshServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 28.04.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public class TokenRefreshServices {
    
    public typealias Handler = (_ token: String) -> Void
    
    public static var shared = TokenRefreshServices()
    
    private var services: [Handler] = []
    private var isFetching = false
    
    public func handler(isRefresh: Bool, _ handler: @escaping Handler) {
        
        guard let token = TripianTokenController().token else {
            handler("")
            return
        }
        
        if TripianTokenController().isTokenValid || isRefresh {
            handler(token)
            return
        }
        
        services.append(handler)
        print("Token zaman aşımında")
        fetchNewRefreshToken { (newToken) in
            for service in self.services {
                service(newToken)
            }
            self.services.removeAll()
        }
        
    }
 
    private func fetchNewRefreshToken(_ completion: @escaping(_ token: String) -> Void) {
        guard !isFetching else {return}
        isFetching = true
        print("-------------- YENİ TOKEN ÇEKİLİYOR")
        
        guard let refresh = TripianTokenController().refreshToken else {return}
        
        TRPRestKit().refreshToken(refresh) { (_, error) in
            self.isFetching = false
            if let error = error {
                //TODO: BURASI KESINLİKLE GERI DONDURULECEK.
                //FIXME: KESİN İŞLEM YAPILACAK
                print("Refresh Error \(error.localizedDescription)")
                return
            }
            if let newToken = TripianTokenController().token {
                completion(newToken)
            }else {
                print("New Refresh is Nil")
            }
        }
    }
    
}
