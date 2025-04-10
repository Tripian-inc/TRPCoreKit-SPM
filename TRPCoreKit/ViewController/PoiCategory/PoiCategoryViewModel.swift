//
//  CreateTripQuestionsViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 14.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

class PoiCategoryUIModel {
    var id: Int = -1
    var order: Int = -1
    var name: String = ""
    var isCategoryGroup: Bool = false
    var parentName: String = ""
    var isSelected: Bool = false
}

protocol PoiCategoryViewModelDelegate: ViewModelDelegate {
    func selectedAllCategoriesForFirstInit()
}

class PoiCategoryViewModel {
    
    public weak var delegate: PoiCategoryViewModelDelegate?
    
    private var isEditing: Bool = false
    
    public var poiCategoriesUseCase: FetchPoiCategoriesUseCase?
    
    private var poiCategoryGroups: [TRPPoiCategoyGroup] = []
    private var selectedCategories: [TRPPoiCategory] = []
    private var allCategories: [TRPPoiCategory] = []
    
    private var cellModels: [PoiCategoryUIModel] = []
    
    private var forAddPlace: Bool = false
    
    init(selectedCategories: [TRPPoiCategory], forAddPlace: Bool = false) {
        self.selectedCategories = selectedCategories
        self.forAddPlace = forAddPlace
    }
    
    public func start() {
        fetchPoiCategories()
    }
    
    public func getCellCount(section: Int) -> Int {
        cellModels.count
    }
    
    public func getCellModel(at indexPath: IndexPath) -> PoiCategoryUIModel {
        return cellModels[indexPath.row]
    }
    
    public func getSelectedCategories() -> [TRPPoiCategory] {
        selectedCategories
    }
    
    public func getAllCategories() -> [TRPPoiCategory] {
        allCategories
    }
    
    open func selectCell(at indexPath: IndexPath) {
        let model = getCellModel(at: indexPath)
        if model.isCategoryGroup {
            updateSelectedCategoriesForGroup(groupName: model.name, isSelected: !model.isSelected)
        } else {
            if model.isSelected {
                cellModels.first(where: {$0.name == model.parentName})?.isSelected = false
            }
            cellModels[indexPath.row].isSelected.toggle()
        }
        setSelectedCategories()
        if !model.isSelected {
            checkAllCategoriesSelected(groupName: model.parentName)
        }
        delegate?.viewModel(dataLoaded: true)
    }
    
    private func setSelectedCategories() {
        selectedCategories = []
        if let selectedCatIds = cellModels.filter({ $0.isSelected }).compactMap((\.id)) as? [Int] {
            poiCategoryGroups.forEach { group in
                selectedCategories.append(contentsOf: (group.categories?.filter {selectedCatIds.contains($0.id)} ?? []))
            }
        }
    }
    
    private func updateSelectedCategoriesForGroup(groupName: String, isSelected: Bool) {
        cellModels.first(where: {$0.name == groupName})?.isSelected = isSelected
        if let categoryGroup = poiCategoryGroups.first(where: { $0.name == groupName }) {
            categoryGroup.categories?.forEach { category in
                cellModels.first(where: {$0.id == category.id})?.isSelected = isSelected
            }
        }
    }
    
    private func checkAllCategoriesSelected(groupName: String) {
        if let categoryGroup = poiCategoryGroups.first(where: { $0.name == groupName }) {
            if let allSelected = categoryGroup.categories?.allSatisfy({cat in selectedCategories.contains(where: {$0.id == cat.id})}), allSelected {
                cellModels.first(where: {$0.name == groupName})?.isSelected = true
            }
        }
    }
    
}

extension PoiCategoryViewModel {
    
    func fetchPoiCategories() {
        delegate?.viewModel(showPreloader: true)
        poiCategoriesUseCase?.executeFetchPoiCategories(completion: { [weak self] result in
            guard let strongSelf = self else {return}
            switch(result) {
            case .success(let poiCategoryGroups):
                strongSelf.poiCategoryGroups = poiCategoryGroups
                strongSelf.convertToCellModels(isFirstInit: strongSelf.selectedCategories.isEmpty)
            case .failure(let error):
                strongSelf.delegate?.viewModel(showPreloader: false)
                strongSelf.delegate?.viewModel(error: error)
            }
        })
    }
    
    private func convertToCellModels(isFirstInit: Bool) {
        var order = 1
        cellModels.removeAll()
        allCategories.removeAll()
        poiCategoryGroups.forEach { group in
            let model = PoiCategoryUIModel()
            model.isCategoryGroup = true
            model.name = group.name ?? ""
            model.order = order
            order += 1
            cellModels.append(model)
            group.categories?.forEach { cat in
                let model = PoiCategoryUIModel()
                model.id = cat.id
                model.isCategoryGroup = false
                model.name = cat.name ?? ""
                model.order = order
                model.parentName = group.name ?? ""
                model.isSelected = selectedCategories.contains(where: {$0.id == cat.id})
                order += 1
                allCategories.append(cat)
                cellModels.append(model)
            }
            checkAllCategoriesSelected(groupName: model.name)
        }
        if isFirstInit {
            delegate?.selectedAllCategoriesForFirstInit()
        }
        delegate?.viewModel(showPreloader: false)
        delegate?.viewModel(dataLoaded: true)
        
    }
}
