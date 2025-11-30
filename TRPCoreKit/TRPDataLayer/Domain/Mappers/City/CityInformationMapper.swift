//
//  CityInformationMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 4.09.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import TRPRestKit

public class CityInformationMapper {
    
    public func map(_ restModel: TRPCityInformationDataJsonModel) -> TRPCityInformationData {
        
        let wifiInfo = TRPCityWifiInformation(mobile: restModel.information?.wifiInformation?.mobile,
                                              broadband: restModel.information?.wifiInformation?.broadband)
        
        let lifeQualityIndices = getLifeQualityIndices(restModel.information?.lifeQualityIndices)
        
        let emergencyNumbers = TRPCityEmergencyNumbers(fire: restModel.information?.emergencyNumbers?.fire,
                                                       police: restModel.information?.emergencyNumbers?.police,
                                                       ambulance: restModel.information?.emergencyNumbers?.ambulance,
                                                       notes: restModel.information?.emergencyNumbers?.notes)
        
        let powerInformation = TRPCityPowerInformation(plugs: restModel.information?.powerInformation?.plugs,
                                                       voltage: restModel.information?.powerInformation?.voltage,
                                                       frequency: restModel.information?.powerInformation?.frequency)
        
        let bestTimeToVisit = getBestTimeToVisit(restModel.information?.bestTimeToVisit)
        
        
        let cityInfo = TRPCityInformation(wifiInformation: wifiInfo,
                                          lifeQualityIndices: lifeQualityIndices,
                                          emergencyNumbers: emergencyNumbers,
                                          powerInformation: powerInformation,
                                          bestTimeToVisit: bestTimeToVisit)
        
        let newModel = TRPCityInformationData(id: restModel.id, information: cityInfo)
        return newModel
    }
    
    private func getBestTimeToVisit(_ restModel: TRPCityBestTimeToVisitJsonModel?) -> TRPCityBestTimeToVisit {
        var bestTimeToVisit: TRPCityBestTimeToVisit
        
        let restOffSeason = restModel?.offSeason
        let offSeason = TRPCitySeason(description: restOffSeason?.description,
                                      months: restOffSeason?.months)
        let restPeakSeason = restModel?.peakSeason
        let peakSeason = TRPCitySeason(description: restPeakSeason?.description,
                                       months: restPeakSeason?.months)
        let restShoulderSeason = restModel?.shoulderSeason
        let shoulderSeason = TRPCitySeason(description: restShoulderSeason?.description,
                                           months: restShoulderSeason?.months)
        
        bestTimeToVisit = TRPCityBestTimeToVisit(notes: restModel?.notes,
                                                 offSeason: offSeason,
                                                 peakSeason: peakSeason,
                                                 shoulderSeason: shoulderSeason)
        return bestTimeToVisit
    }
    
    private func getLifeQualityIndices(_ restModel: TRPCityLifeQualityIndicesJsonModel?) -> TRPCityLifeQualityIndices? {
        var lifeQualityIndices: TRPCityLifeQualityIndices?
        if let restLifeQualityIndices = restModel {
            let restSafetyIndex = restLifeQualityIndices.safetyIndex
            let safetyIndex = TRPCityQualityIndex(rating: restSafetyIndex?.rating,
                                                  value: restSafetyIndex?.value)
            let restHealthCareIndex = restLifeQualityIndices.healthCareIndex
            let healthCareIndex = TRPCityQualityIndex(rating: restHealthCareIndex?.rating,
                                                      value: restHealthCareIndex?.value)
            let restPropertyPriceToIncomeRatio = restLifeQualityIndices.propertyPriceToIncomeRatio
            let propertyPriceToIncomeRatio = TRPCityQualityIndex(rating: restPropertyPriceToIncomeRatio?.rating,
                                                                 value: restPropertyPriceToIncomeRatio?.value)
            let restTrafficCommuteTimeIndex = restLifeQualityIndices.trafficCommuteTimeIndex
            let trafficCommuteTimeIndex = TRPCityQualityIndex(rating: restTrafficCommuteTimeIndex?.rating,
                                                              value: restTrafficCommuteTimeIndex?.value)
            let restPurchasingPowerIndex = restLifeQualityIndices.purchasingPowerIndex
            let purchasingPowerIndex = TRPCityQualityIndex(rating: restPurchasingPowerIndex?.rating,
                                                           value: restPurchasingPowerIndex?.value)
            let restQualityOfLifeIndex = restLifeQualityIndices.qualityOfLifeIndex
            let qualityOfLifeIndex = TRPCityQualityIndex(rating: restQualityOfLifeIndex?.rating,
                                                         value: restQualityOfLifeIndex?.value)
            let restclimateIndex = restLifeQualityIndices.climateIndex
            let climateIndex = TRPCityQualityIndex(rating: restclimateIndex?.rating,
                                                   value: restclimateIndex?.value)
            let restPollutionIndex = restLifeQualityIndices.pollutionIndex
            let pollutionIndex = TRPCityQualityIndex(rating: restPollutionIndex?.rating,
                                                     value: restPollutionIndex?.value)
            let restCostOfLivingIndex = restLifeQualityIndices.costOfLivingIndex
            let costOfLivingIndex = TRPCityQualityIndex(rating: restCostOfLivingIndex?.rating,
                                                        value: restCostOfLivingIndex?.value)
            
            lifeQualityIndices = TRPCityLifeQualityIndices(safetyIndex: safetyIndex,
                                                           healthCareIndex: healthCareIndex,
                                                           propertyPriceToIncomeRatio: propertyPriceToIncomeRatio,
                                                           trafficCommuteTimeIndex: trafficCommuteTimeIndex,
                                                           purchasingPowerIndex: purchasingPowerIndex,
                                                           qualityOfLifeIndex: qualityOfLifeIndex,
                                                           climateIndex: climateIndex,
                                                           pollutionIndex: pollutionIndex,
                                                           costOfLivingIndex: costOfLivingIndex)
        }
        return lifeQualityIndices
    }
}
