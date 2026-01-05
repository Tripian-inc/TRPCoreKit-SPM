//
//  ImageMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class ImageMapper {
    
    func map(_ restModel: TRPImageModel?) -> TRPImage? {
        guard let restModel else {
            return nil
        }
        var owner: TRPImageOwner?
        
        if let imageOwner = restModel.imageOwner {
            owner = ImageOwnerMapper().map(imageOwner)
        }
        
        return TRPImage(url: restModel.url ?? "",
                        imageOwner: owner,
                        width: restModel.width,
                        height: restModel.height)
    }
    
    
    func map(_ restModels: [TRPImageModel?]) -> [TRPImage?] {
        restModels.map {map($0)}
    }
}

final class ImageOwnerMapper {
    
    func map(_ restModel: TRPImageOwnerModel) -> TRPImageOwner {
        return TRPImageOwner(title: restModel.title, url: restModel.url, avatar: restModel.avatar)
    }
   
}
