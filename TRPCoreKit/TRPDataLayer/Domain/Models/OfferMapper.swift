//
//  OfferMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 9.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation


final class OfferMapper {
    
    func map(_ restModel: TRPOfferInfoModel) -> TRPOffer {
        var newModel = TRPOffer(offerId: restModel.id)
        newModel.poiId = restModel.poiId
        newModel.businessId = restModel.businessId
        newModel.title = restModel.title
        newModel.description = restModel.description
        
        let currency: OfferCurrencyType = OfferCurrencyType(rawValue: restModel.currency) ?? .usd
        newModel.currency = currency
        
        newModel.caption = restModel.caption
        newModel.productName = restModel.productName ?? ""
        newModel.threshold = restModel.threshold ?? 0.0
        newModel.discount = restModel.discount ?? 0.0
        newModel.discountedProductCount = restModel.discountedProductCount ?? 0
        newModel.quantity = restModel.quantity ?? 0
        
        newModel.timeframe = OfferTimeFrameMapper().map(restModel.timeframe)
        newModel.imageUrl = restModel.imageUrl
        
        newModel.productType = OfferProductTypeMapper().map(restModel.productType)
        
        let offerType: OfferType = OfferType(rawValue: restModel.offerType ?? "") ?? .quantity
        newModel.offerType = offerType
        
        newModel.usage = restModel.usage ?? 0
        newModel.optIn = restModel.optIn ?? false
        newModel.optInClaimDate = restModel.optInClaimDate ?? ""
        
        let status: OfferStatus = OfferStatus(rawValue: restModel.status ?? "") ?? .active
        newModel.status = status
        return newModel
    }
    
    func map(_ restModels: [TRPOfferInfoModel]) -> [TRPOffer] {
        return restModels.compactMap{ map($0) }
    }
}
