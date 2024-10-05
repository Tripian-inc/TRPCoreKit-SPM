//
//  PoiDetailImageAndTitle.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 28.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit
final public class PoiDetailImageAndTitle: UITableViewCell {
    
    private var cellImages: [PagingImage] = []
    @IBOutlet weak var galleryCollection: UICollectionView!
    @IBOutlet weak var pageController: UIPageControl!
    
    var thisWidth: CGFloat = 0
    @IBOutlet weak var edgeView: EdgeView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var globalRatingLabel: UILabel!
    @IBOutlet weak var starView: TRPStar2!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var subTitleView: UIView!
    @IBOutlet weak var explaineLabel: UILabel!
    @IBOutlet weak var explaineLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var subTitleViewHeightConstraint: NSLayoutConstraint!
    
    @PriceIconWrapper
    private var priceDolarSign = 0
    
    
    var bottomConstraint: NSLayoutConstraint?
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        thisWidth = CGFloat(self.frame.width)
        edgeView.fillColor = UIColor.white
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        self.setup()
        backgroundColor = UIColor.white
        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        backgroundColor = UIColor.white
        layoutIfNeeded()
    }
    
    public func setImageData(_ data: [PagingImage]) {
        cellImages = data
        setupGallery()
    }
    
    func setup() {
        self.selectionStyle = .none
//        setupCollectionConstraints()
        setupLabels()
    }
    
    private func setupLabels() {
        titleLabel.font = trpTheme.font.header2
        titleLabel.textColor = trpTheme.color.tripianBlack
        
        globalRatingLabel.font = trpTheme.font.body3
        globalRatingLabel.textColor = trpTheme.color.tripianTextPrimary
    }
    
    public func showSubTitle(starCount: Int, reviewCount: Int, price: Int, explainText: NSAttributedString?) {
        if starCount > 0 && reviewCount > 0 {
            subTitleViewHeightConstraint.constant = 28
            showRating(starCount, reviewCount, price)
        } else {
            subTitleView.isHidden = true
            subTitleViewHeightConstraint.constant = 0
        }
        
        if let explaine = explainText {
            if explaine.length < 1 {
                explaineLabel.text = ""
                explaineLabelHeightConstraint.constant = 0
            } else {
                explaineLabelHeightConstraint.constant = 21
                explaineLabel.attributedText = explaine
            }
        }
        self.contentView.layoutIfNeeded()
    }
}


//MARK: - Show Rating
extension PoiDetailImageAndTitle {
    
    private func showRating(_ starCount: Int, _ reviewCount: Int, _ price: Int) {
        
        globalRatingLabel.text = "\(TRPLanguagesController.shared.getLanguageValue(for: "global_rating")): (\(reviewCount))"
        starView.starRate(starCount)
        
        if price != 0 {
            priceDolarSign = price
            priceLabel.attributedText = $priceDolarSign.generateDolarSign()
        } else {
            priceLabel.text = ""
        }
    }
   
}


//MARK: - UI Design
extension PoiDetailImageAndTitle {
    
    func setupGallery() {
        galleryCollection.delegate = self
        galleryCollection.dataSource = self
        galleryCollection.reloadData()
        
        if #available(iOS 14.0, *) {
            pageController.backgroundStyle = .minimal
        }
        pageController.numberOfPages = cellImages.count
        pageController.currentPageIndicatorTintColor = trpTheme.color.tripianPrimary
        pageController.pageIndicatorTintColor = trpTheme.color.tripianPrimary.withAlphaComponent(0.5)
    }
    
}

//MARK: Collection View Data Source
extension PoiDetailImageAndTitle: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellImages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCollectionViewCell", for: indexPath as IndexPath) as! GalleryCollectionViewCell
        let cellImage = cellImages[indexPath.row]
        cell.setImage(cellImage)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.contentView.frame.width, height: self.contentView.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.pageController.currentPage = 0
        }else{
            self.pageController.currentPage = indexPath.row % cellImages.count
        }
    }
    
//    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
//        let index = scrollView.contentOffset.x / witdh
//        let roundedIndex = round(index)
//        setImageCountLabel(index: Int(roundedIndex))
//    }
    
}

