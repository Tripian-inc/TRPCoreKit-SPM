//
//  CreateTripSelectedItemTagCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 9.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

class CreateTripSelectedItemTagCell: UITableViewCell {
    @IBOutlet weak var collectionView: DynamicHeightCollectionView!
    
    public var viewModel: CreateTripSelectedItemTagViewModel!
    
    public var removeAction: ((Int) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let layout = TagFlowLayout()
        layout.estimatedItemSize = CGSize(width: 140, height: 40)
        collectionView.collectionViewLayout = layout
    }
    
    func configure() {
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }
}

extension CreateTripSelectedItemTagCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedItemTagCell", for: indexPath) as? SelectedItemTagCell else { return SelectedItemTagCell()
        }
        let cellInfo = viewModel.cellInfo(indexPath)
        cell.label.text = cellInfo.title
        cell.removeAction = {
            self.removeAction?(cellInfo.id)
        }
        return cell
    }
}
