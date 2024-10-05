//
//  ButterflyContainerCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.05.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPDataLayer

class ButterflyContainerCell: UITableViewCell {
    
    private var subVC: ButterflyCollectionVC?
    public var openPlaceHandler: ((_ place: TRPPoi) -> Void)?
    
    lazy var categoryTitle: UILabel = {
        let lbl = UILabel()
        lbl.text = ""
        lbl.textColor = TRPAppearanceSettings.Butterfly.headerTextColor
        lbl.font = UIFont.systemFont(ofSize: TRPAppearanceSettings.Butterfly.headerFontSize, weight: .light)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public func setupCell(containerVC: ButterFlyContainerVC, cellModel: ButterflyCollectionModel) {
        addSubview(categoryTitle)
        categoryTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        categoryTitle.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
        let flowlayout = UICollectionViewFlowLayout()
        subVC = ButterflyCollectionVC(layout: flowlayout, viewModel: cellModel.viewModel, cellClass: cellModel.cellClass)
        subVC?.delegate = self
        cellModel.viewModel.delegate = subVC
        flowlayout.scrollDirection = .horizontal
        containerVC.addChild(subVC!)
        addSubview(subVC!.view)
        subVC!.didMove(toParent: containerVC)
        setupCollectionConstraints(collection: subVC!)
    }
    
    func setupCollectionConstraints(collection: UICollectionViewController) {
        collection.view.translatesAutoresizingMaskIntoConstraints = false
        collection.view.topAnchor.constraint(equalTo: categoryTitle.bottomAnchor, constant: 0).isActive = true
        collection.view.heightAnchor.constraint(equalToConstant: TRPAppearanceSettings.Butterfly.collectionCellHeight + 20).isActive = true
        collection.view.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        collection.view.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        bottomAnchor.constraint(equalTo: collection.view.bottomAnchor).isActive = true
    }
    
    func reloadSubCollection() {
        guard let horizontalCollection = subVC else {
            print("SunVC is a nill")
            return
        }
        horizontalCollection.collectionView.reloadData()
    }
    
}

extension ButterflyContainerCell: ButterflyCollectionVCProtocol {
    func butterflyCollectionVCOpenPlace(_ place: TRPPoi) {
        openPlaceHandler?(place)
    }
}
