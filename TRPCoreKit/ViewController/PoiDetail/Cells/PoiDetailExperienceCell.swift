//
//  PoiDetailExperienceCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-10-30.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import Foundation

import SDWebImage
import UIKit



class PoiDetailExperienceCell: UITableViewCell {
    
    let collectionHeight: CGFloat = 300
    public var selectedTourAction: ((_ product: TRPBookingProduct) -> Void)?
    
    public lazy var titleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.text = TRPLanguagesController.shared.getLanguageValue(for: "buy_tickets_tours")
        return label
    }()
    
    public lazy var subLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = TRPColor.pink
        label.numberOfLines = 1
        label.text = ""
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
    
    private var products: [TRPBookingProduct] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var isSubAdded = false
    var bottomConstraint: NSLayoutConstraint?
    var collectionTopConstraint: NSLayoutConstraint?
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    
    
    private func setup() {
        
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
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
        collectionTopConstraint = collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10)
        bottomConstraint = bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: collectionHeight + 50)
        bottomConstraint?.isActive = true
        collectionTopConstraint?.isActive = true
        contentView.isHidden = true
    }
    
    public func updateData(_ data: [TRPBookingProduct]) {
        self.products = data
    }
    
    
    public func addSubLabel(text: String) {
        guard let bottomCont = bottomConstraint else {return}
        guard let collectionTop = collectionTopConstraint else {return}
        if !isSubAdded {
            isSubAdded.toggle()
            bottomCont.constant = collectionHeight + 80
            collectionTop.constant = 30
            addSubview(subLabel)
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0).isActive = true
            subLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
           
        }
        subLabel.text = text
    }
    
    
}


extension PoiDetailExperienceCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! ExperiencesCollectionCell
        let model = products[indexPath.row]
        cell.titleLabel.text = model.title
        
        if let first = model.image,  let url = URL(string: first.replacingOccurrences(of: "http://", with: "https://")) {
            cell.imageView.sd_setImage(with: url, completed: nil)
        }
        cell.bestSeller.isHidden = true
        
        if let price = model.price {
            cell.priceLabel.text = "\(price)$"
        }else {
            cell.priceLabel.text = ""
        }
        
        if let ratingCount = model.ratingCount, let rating = model.rating, ratingCount != 0 {
            cell.showRating(true)
            let starCount = String(format: "%.1f", rating)
            cell.ratingCountLabel.text = "(\(ratingCount))"
            cell.starCountLabel.text = "\(starCount)"
        }else {
            cell.showRating(false)
        }
     
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = products[indexPath.row]
        
        selectedTourAction?(model)
    }
}
