//
//  QuestionsTableViewCell.swift
//  Wiserr
//
//  Created by Cem Çaygöz on 6.09.2021.
//

import UIKit

class QuestionsTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: DynamicHeightCollectionView!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    var viewModel: QuestionsVM!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {
            self.initViews()
        }
    }
    
    func initViews() {
        
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
    
//    func setCollectionViewHeight() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            let height = self.collectionView.collectionViewLayout.collectionViewContentSize.height
//            self.collectionViewHeight.constant = height
//            self.collectionView.layoutIfNeeded()
//        }
//    }

}

extension QuestionsTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCollectionViewCell", for: indexPath) as? TagCollectionViewCell else { return TagCollectionViewCell()
        }
        let cellInfo = viewModel.cellInfo(indexPath)
        cell.label.text = cellInfo.name
        cell.itemSelected = viewModel.isItemSelected(id: cellInfo.id)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let id = viewModel.cellInfo(indexPath).id
        let itemIsSelected = viewModel.isItemSelected(id: id)
        
        if itemIsSelected {
            viewModel.itemIsDeselected(id: id)
        }else {
            viewModel.clearSelections()
            viewModel.itemIsSelected(id: id)
        }
        configure()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        print("kind = \(kind)")
        if (kind == UICollectionView.elementKindSectionHeader) {
            if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "TagCollectionReusableView", for: indexPath) as? TagCollectionReusableView {
                sectionHeader.titleLabel.text = "\(viewModel.sectionTitle())"
                return sectionHeader
            }
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 40)
    }
}
