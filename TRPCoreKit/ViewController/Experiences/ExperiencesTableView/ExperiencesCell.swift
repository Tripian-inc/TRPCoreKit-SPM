//
//  ExperiencesCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

import SDWebImage
import UIKit


class ExperiencesCell: UITableViewCell {
    
    let collectionHeight: CGFloat = 300
    public var selectedTourAction: ((_ tourId: Int) -> Void)?
    
    public lazy var titleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.text = "TİTLE"
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 230, height: collectionHeight)
        flowLayout.minimumLineSpacing = 20.0
        flowLayout.minimumInteritemSpacing = 5.0
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collection.backgroundColor = UIColor.white
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        return collection
    }()
    
    private var tours: [GYGTour] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    private func setup() {
        
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        
        addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ExperiencesCollectionCell.self, forCellWithReuseIdentifier: "collectionCell")
        
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: collectionHeight).isActive = true
        collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: collectionHeight + 20).isActive = true
        
        contentView.isHidden = true
    }
    
    public func updateData(_ data: [GYGTour]) {
        self.tours = data
    }
    
}


extension ExperiencesCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tours.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! ExperiencesCollectionCell
        let model = tours[indexPath.row]
        cell.titleLabel.text = model.title
        
        if let category = model.categories?.first {
            cell.typeLabel.text = category.name
        }
        
        //TODO: $ gelen veriden çekilecek
        if let price = model.price?.values?.amount {
            cell.priceLabel.text = "$\(price)"
        }else {
            cell.priceLabel.text = ""
        }
        
        if let first = model.pictures?.first,  let url = URL(string: first.url?.replacingOccurrences(of: "[format_id]", with: "21") ?? "") {
            cell.imageView.sd_setImage(with: url, completed: nil)
        }
        
        cell.bestSeller.isHidden = !(model.bestseller ?? false)
        
        if model.numberOfRatings == 0 {
            cell.showRating(false)
        }else {
            cell.showRating(true)
            let starCount = String(format: "%.1f", model.overallRating ?? 0)
            cell.ratingCountLabel.text = "(\(model.numberOfRatings ?? 0)) reviews"
            cell.starCountLabel.text = "\(starCount)"
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedTourAction?(tours[indexPath.row].tourID)
    }
}
