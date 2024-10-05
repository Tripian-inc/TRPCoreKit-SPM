//
//  AddPlacesContainerViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 10.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation



public class AddPlacesContainerViewModel: NSObject {
    
    //Her section için gösterilecek isimler
    private var childPlaceTitles: [String] = []
    
    //Varsa section için kullanılacak placeTypes
    private var childPlaceType: [AddPlaceTypes] = []
    
    public func addChildPlaceType(_ type: AddPlaceTypes) {
        childPlaceType.append(type)
        childPlaceTitles.append(type.name)
    }
    
    public func addChildPlaceType(_ types: [AddPlaceTypes]) {
        let names = types.compactMap({$0.name})
        
        childPlaceType.append(contentsOf: types)
        childPlaceTitles.append(contentsOf: names)
    }
    
    public func addChildTypeOnlyTitle(_ title: String) {
        childPlaceTitles.append(title)
    }
    
    /// Kac tane pagination yaratılacaksa, o sayısı dondurur
    ///
    /// - Returns: toplam paging sayısı
    public func getPagingNumber() -> Int {
        return childPlaceTitles.count
    }
    
    
    /// Paging başlığı
    ///
    /// - Parameter index: pagingin indexi
    /// - Returns: paging title'ı
    public func getPagingTitle(index:Int) -> String{
        return childPlaceTitles[index]
    }
    
    public func getPlaceTypes(title: String) -> AddPlaceTypes? {
        return childPlaceType.first(where: {$0.name.lowercased() == title.lowercased()})
    }
}
