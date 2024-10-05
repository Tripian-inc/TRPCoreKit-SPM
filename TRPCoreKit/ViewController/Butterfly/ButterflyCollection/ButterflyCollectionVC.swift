//
//  ButterflyCollectionVC.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 22.01.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit



protocol ButterflyCollectionVCProtocol:AnyObject {
    func butterflyCollectionVCOpenPlace(_ place: TRPPoi)
}

class ButterflyCollectionVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let cellNotInterest = "KelebekHorizontalNotInterest"
    let viewModel: ButterflyCollectionVM
    let cellClass: AnyClass
    public weak var delegate: ButterflyCollectionVCProtocol?;
    
    init(layout: UICollectionViewLayout, viewModel: ButterflyCollectionVM, cellClass: AnyClass) {
        self.viewModel = viewModel
        self.cellClass = cellClass
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        view.backgroundColor = UIColor.white
    }
    
    private func setupCollectionView() {
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.backgroundColor = .white
        collectionView?.register(cellClass.self,
                                 forCellWithReuseIdentifier: "Cell")
        collectionView?.register(KelebekHorizontalCollectionViewNotInterestCell.self,
                                 forCellWithReuseIdentifier: cellNotInterest)
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: TRPAppearanceSettings.Butterfly.collectionCellWidth,
                      height: TRPAppearanceSettings.Butterfly.collectionCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellMaker(collectionView, indexPath: indexPath, model: viewModel.getCellViewModel(at: indexPath))
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.butterflyCollectionVCOpenPlace(viewModel.getCellViewModel(at: indexPath).step.poi)
    }
    
    private func cellMaker(_ collectionView :UICollectionView, indexPath: IndexPath, model: ButterflyCellStatus) -> UICollectionViewCell {
        if model.isUninterest {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellNotInterest,
                                                          for: indexPath) as! KelebekHorizontalCollectionViewNotInterestCell
            make(cell, model: model)
            return cell
        }else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                          for: indexPath) as! ButterflyHorizontalCardCell
            make(cell, model: model)
            return cell
        }
    }
    
    private func showTellUsWhyAlert(model: ButterflyCellStatus) {
        let optionMenu = UIAlertController(title: nil, message: "Tell Us Why?", preferredStyle: .actionSheet)
        
        let iHaveAlreadyVisit = UIAlertAction(title: TellUsWhy.iHaveAlreadyVisited.rawValue, style: .default) { [weak self] _ in
            guard let strongSelf = self else {return}
            strongSelf.viewModel.tellUsWhyAlert(model, userAnswer: .iHaveAlreadyVisited)
        }
        
        let idontLike = UIAlertAction(title: TellUsWhy.iDontLikePlace.rawValue, style: .default) { [weak self] _ in
            guard let strongSelf = self else {return}
            strongSelf.viewModel.tellUsWhyAlert(model, userAnswer: .iDontLikePlace)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        cancelAction.setValue(TRPAppearanceSettings.Common.cancelButtonColor, forKey: "titleTextColor")
        optionMenu.addAction(iHaveAlreadyVisit)
        optionMenu.addAction(idontLike)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
}

extension ButterflyCollectionVC {
    
    func make(_ cell: KelebekHorizontalCollectionViewNotInterestCell,
              model: ButterflyCellStatus)  {
        cell.undoPressedHandler = { [weak self] in
            guard let strongSelf = self else {return}
            strongSelf.collectionView.reloadData()
            strongSelf.viewModel.undoPressed(model)
        }
        cell.tellUsWhyPressedHandler = {[weak self] in
            guard let strongSelf = self else {return}
            strongSelf.showTellUsWhyAlert(model: model)
        }
        cell.removeCellPressedHandler = {[weak self] in
            guard let strongSelf = self else {return}
            strongSelf.viewModel.removeCellPressed(model)
        }
        
        cell.setupCollectionView()
    }
    
    func make(_ cell: ButterflyHorizontalCardCell, model: ButterflyCellStatus)  {
        let place = model.step.poi
        cell.placeTitle.text = "\(place.name) "
        
        if let matchRate = model.step.score {
            cell.matchRateLbl.text = "\(Int(matchRate))% match"
        }
        
        //Attraction Cell
        if let attractionCell = cell as? ButterflyAttractionCell {
            if let day = viewModel.getDay(stepId: model.step.id), viewModel.isFirstInSomeCategoryAndDay(cellModel: model) {
                attractionCell.dayInfoLabel.text = "Day \(day )"
            }else {
                attractionCell.dayInfoLabel.text = ""
            }
            
            if let category = place.categories.first {
                var categoryType = category.name.uppercased()
                if let single = getSingler(id: category.id) {
                    categoryType = single.uppercased()
                }
                attractionCell.setTopLabel(text: categoryType)
            }
            if let desc = place.description {
                attractionCell.setSubLabel(text: desc)
            }
            
            if let star = place.rating, let rating = place.ratingCount {
                attractionCell.setStarRating(star: Float(star), rating: rating, price: 0)
            }
        }
        
        //Cafe & Restaurant Cell
        if let cafeRestaurantCell = cell as? ButterflyRestaurantCell {
            
            let isCategoryBar = place.categories.contains { (category) -> Bool in
                return category.id == TRPPoiCategory.bar.getId()
            }
            
            if let day = viewModel.getDay(stepId: model.step.id), viewModel.isFirstInSomeCategoryAndDay(cellModel: model) {
                cafeRestaurantCell.dayInfoLabel.text = "Day \(day )"
            }else {
                cafeRestaurantCell.dayInfoLabel.text = ""
            }
            var _cuisines: String?
            var tags: String?
            
            if place.tags.count > 2 {
                tags = place.tags[0] + ", " + place.tags[1]
            }
            if  let cuisines = place.cuisines {
                if !isCategoryBar {
                    _cuisines =  getFirstCuisine(cuisines).uppercased()
                }
                
            }
            
            cafeRestaurantCell.setTopAndSubLabel(topContent: _cuisines, subContent: tags)
            
            
            
            if let star = place.rating, let rating = place.ratingCount, let price = place.price {
                cafeRestaurantCell.setStarRating(star: Float(star), rating: rating, price: price)
            }
            
            
        }
        
        if let img = viewModel.getImageUrl(model: model) {
            cell.mainImage.sd_setImage(with: img)
        }
        
        if model.isLiked {
            if model.isProgress {return}
            cell.isPlaceLiked = true
        }
        
        cell.thumbsDownPressedHandler = { [weak self] in
            guard let strongSelf = self else {return}
            strongSelf.collectionView.reloadData()
            strongSelf.viewModel.thumbsDownPressed(model)
        }
        cell.thumbsUpPressedHandler = { [weak self] current in
            guard let strongSelf = self else {return}
            
            cell.selectedAnimationFor(type: current)
            if current == .noSelect {
                strongSelf.viewModel.thumbsUpPressed(model)
            }else {
                strongSelf.viewModel.thumbsUpUnCheckPressed(model)
            }
        }
    }
    
    func getSingler(id: Int) -> String? {
        guard let type = TRPPoiCategory.idToType(id) else {
            return nil
        }
        return type.getSingler()
    }
    
    private func isFirstInPlaceInCategoryAndDay() {
        
    }
    
    func getFirstCuisine(_ value: String) -> String {
        let ar = value.split(separator: ",")
        if ar.first != nil {
            return "\(ar.first!)"
        }
        return value
    }
    
    public func setTopLable(text: String) {
        
    }
    
    public func setSubLable(text: String) {
        
    }
}

extension ButterflyCollectionVC: ViewModelDelegate {
    
    func viewModel(dataLoaded: Bool) {
        self.collectionView.reloadData()
    }
    
    func viewModel(error: Error) {
        
    }
    
    func viewModel(showPreloader: Bool) {
        
    }
    
    
}
