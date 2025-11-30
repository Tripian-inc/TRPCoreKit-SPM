//
//  TRPCompanionServices.swift
//  TRPRestKit
//
//  Created by Rozeri Dağtekin on 6/26/19.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation



//TODO: - TRPCompanionsJsonModel - TRPParentJsonModel OLARAK GÜNCELLENECEK

internal class TRPGetCompanionServices: TRPRestServices<TRPGenericParser<[TRPCompanionModel]>> {
    
    public override func requestMode() -> TRPRequestMode {
        return .get
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.companion.link
    }
}

internal class TRPCompanionPutPostServices: TRPRestServices<TRPGenericParser<TRPCompanionModel>> {
    
    let name: String
    let answers: [Int]?
    let age: Int?
    var companionId: Int?
    var title: String?
    
    //Companion Id varsa edit yapılacak anlamına gelir ve Put uygulanır.
    //Companion Id yoksa yeni oluşturulacak anlamına gelir Post ugyulanır.
    
    init(companionId: Int? = nil,
         name: String,
         answers: [Int]?,
         title: String?,
         age: Int? = nil ) {
        self.companionId = companionId
        self.name = name
        self.title = title
        self.answers = answers
        self.age = age
    }
       
    public override func requestMode() -> TRPRequestMode {
        if companionId != nil {
            return .put
        }
        return .post
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    override func bodyParameters() -> [String : Any]? {
        var params = [String: Any]()
        params["name"] = name
        
        if let answers = answers {
        params["answers"] = answers
        }
        
        if let age = age {
            params["age"] = age
        }
        if let title = title {
            params["title"] = title
        }
        return params
    }
    
    public override func path() -> String {
        var url = TRPConfig.ApiCall.companion.link
        if let companion = companionId {
            url += "/\(companion)"
        }
        return url
    }
}

internal class TRPCompanionDeleteServices: TRPRestServices<TRPParentJsonModel> {
    let id: Int
    
    init(id: Int) {
        self.id = id
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.companion.link + "/\(id)"
    }
    
    override func requestMode() -> TRPRequestMode {
        return .delete
    }
}
