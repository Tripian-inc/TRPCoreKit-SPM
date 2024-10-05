//
//  ExperiencesCollectionCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 16.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit


class ExperiencesCollectionCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        var imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "ist")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.clipsToBounds = true
        return imageView
    }()
    
    public lazy var titleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold).italic()
        label.textColor = UIColor.black
        label.numberOfLines = 2
        label.text = "Hash Marihuana & Hemp Museum "
        return label
    }()
    
    public lazy var priceLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.text = ""
        return label
    }()
    
    public lazy var typeLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.text = "Activity"
        return label
    }()
    
    
    private lazy var starUI: UIImageView = {
        let star = UIImageView()
        if let image = TRPImageController().getImage(inFramework: "star", inApp: nil) {
            star.image = image
        }
        star.contentMode = .scaleAspectFit
        star.translatesAutoresizingMaskIntoConstraints = false
        return star
    }()
    
    public lazy var starCountLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = TRPColor.orange
        label.numberOfLines = 0
        label.text = "4.3"
        return label
    }()
    
    public lazy var ratingCountLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = TRPColor.lightGrey
        label.numberOfLines = 0
        label.text = "(60)"
        return label
    }()
    
    public lazy var bestSeller: TRPPaddingLabel = {
        let lbl = TRPPaddingLabel(4, 4, 8, 8)
        lbl.text = "Best Seller"
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = UIColor.white
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.backgroundColor = TRPColor.green
        lbl.layer.cornerRadius = 4
        lbl.clipsToBounds = true
        lbl.sizeToFit()
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(){
        
        addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 228).isActive = true
    
        addSubview(bestSeller)
        bestSeller.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 16).isActive = true
        bestSeller.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 16).isActive = true
        
        
        addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
        
        addSubview(priceLabel)
        priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
        
        
        addSubview(starUI)
        starUI.widthAnchor.constraint(equalToConstant: 14).isActive = true
        starUI.heightAnchor.constraint(equalToConstant: 14).isActive = true
        starUI.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        starUI.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor).isActive = true
        
        
        addSubview(starCountLabel)
        starCountLabel.leadingAnchor.constraint(equalTo: starUI.trailingAnchor, constant: 2).isActive = true
        starCountLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor).isActive = true
        
        
        addSubview(ratingCountLabel)
        ratingCountLabel.leadingAnchor.constraint(equalTo: starCountLabel.trailingAnchor, constant: 4).isActive = true
        ratingCountLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor).isActive = true
        
        //bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12).isActive = true
        backgroundColor = UIColor.white
    }
    
    
    public func showRating(_ status: Bool){
        starCountLabel.isHidden = !status
        ratingCountLabel.isHidden = !status
        starUI.isHidden = !status
    }
    
}
/*
private func setupOldView(){
    
    addSubview(imageView)
    imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    imageView.addOverlay(color: .black, alpha: 0.3)
    
    addSubview(titleLabel)
    titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
    titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -100).isActive = true
    
    
    addSubview(starUI)
    starUI.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
    starUI.widthAnchor.constraint(equalToConstant: 14).isActive = true
    starUI.heightAnchor.constraint(equalToConstant: 14).isActive = true
    starUI.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    
    addSubview(starCountLabel)
    starCountLabel.leadingAnchor.constraint(equalTo: starUI.trailingAnchor, constant: 2).isActive = true
    starCountLabel.centerYAnchor.constraint(equalTo: starUI.centerYAnchor, constant: 0).isActive = true
    
    addSubview(ratingCountLabel)
    ratingCountLabel.leadingAnchor.constraint(equalTo: starCountLabel.trailingAnchor, constant: 4).isActive = true
    ratingCountLabel.centerYAnchor.constraint(equalTo: starCountLabel.centerYAnchor, constant: 0).isActive = true
    
    
    addSubview(priceLabel)
    addSubview(typeLabel)
    priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
    priceLabel.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor, constant: 0).isActive = true
    
    
    typeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
    typeLabel.bottomAnchor.constraint(equalTo: starUI.topAnchor, constant: -12).isActive = true
    typeLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -12).isActive = true
    
    backgroundColor = UIColor.white
}
*/
