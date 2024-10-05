//
//  ExperienceImageGalleryCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 6.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final class ExperienceImageGalleryCell: UITableViewCell {
    
    private let imageWidth: CGFloat = UIScreen.main.bounds.size.width
    private let imageHeight: CGFloat = CGFloat(UIScreen.main.bounds.size.width * 3/4)
    private var pageController: UIPageControl?
    private var collectionView: UICollectionView?
    public var cellImages: [String] = [] {
        didSet {
            pageController?.numberOfPages = cellImages.count
            pageController?.customPageControl()
            collectionView?.reloadData()
        }
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupViews(){
        contentView.isHidden = true
        setupCollectionView()
        setupPageController()
    }
 
    
    private func setupPageController() {
        let pageControl = UIPageControl(frame: .zero)
        addSubview(pageControl)
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        pageControl.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: collectionView!.bottomAnchor, constant: 0).isActive = true
        
        self.pageController = pageControl
    }
    
}
extension ExperienceImageGalleryCell {
    
    private func getCollectionViewLayout(_ size: CGSize) -> UICollectionViewFlowLayout {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = size
        return collectionViewLayout
    }
    
    private func setupCollectionView() {
        
        let viewLayout = getCollectionViewLayout(CGSize(width: frame.width, height: frame.height))
        
        collectionView = UICollectionView(frame: frame, collectionViewLayout: viewLayout)
        collectionView!.translatesAutoresizingMaskIntoConstraints = false
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.register(ExperienceDetailImageCell.self, forCellWithReuseIdentifier: "cell")
        collectionView!.showsHorizontalScrollIndicator = false
        collectionView!.isPagingEnabled = true
        collectionView!.backgroundColor = UIColor.clear
        collectionView!.sizeToFit()
        addSubview(collectionView!)
        
        
        NSLayoutConstraint.activate([
            collectionView!.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            collectionView!.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView!.leftAnchor.constraint(equalTo: leftAnchor),
            collectionView!.rightAnchor.constraint(equalTo: rightAnchor),
            collectionView!.heightAnchor.constraint(equalToConstant: imageHeight)
            ])
    }
}


extension ExperienceImageGalleryCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellImages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! ExperienceDetailImageCell
        
        let cellImage = cellImages[indexPath.row]
        
        if let url = URL(string: cellImage) {
            cell.topImageView.sd_setImage(with: url, completed: nil)
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: imageWidth, height: imageHeight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let witdh = imageWidth - (scrollView.contentInset.left*2)
        let index = scrollView.contentOffset.x / witdh
        let roundedIndex = round(index)
        self.pageController?.currentPage = Int(roundedIndex)
    }
    
    
    
}
