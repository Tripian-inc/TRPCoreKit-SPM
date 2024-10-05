//
//  PoiDetailImageGallery.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 28.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
final class PoiDetailImageGallery: UIView {
    
    private var pageControl: UIPageControl?
    private var collectionView: UICollectionView?
    private var collectionViewLayout: UICollectionViewFlowLayout?
    private var cellImages: [PagingImage] = []
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        setupCollectionConstraints()
    }
    
    public func setImageData(_ data: [PagingImage]) {
        cellImages = data
        setNumberOfPages(cellImages.count)
        collectionView?.reloadData()
    }
    
    public func setNumberOfPages(_ value: Int) {
        pageControl?.numberOfPages = value
        pageControl?.customPageControl()
    }
}

extension PoiDetailImageGallery {
    
    func setupCollectionConstraints() {
        self.collectionViewLayout = UICollectionViewFlowLayout()
        guard self.collectionViewLayout != nil else {return}
        self.collectionViewLayout!.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.collectionViewLayout!.scrollDirection = .horizontal
        self.collectionViewLayout!.itemSize = CGSize(width: self.frame.width, height: self.frame.height)

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout!)
        guard self.collectionView != nil else {return}
        self.collectionView!.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView!.dataSource = self
        self.collectionView!.delegate = self
        self.collectionView!.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCollectionViewCell")
        self.collectionView!.showsHorizontalScrollIndicator = false
        self.collectionView!.isPagingEnabled = true
        self.collectionView!.backgroundColor = UIColor.systemPink
        addSubview(self.collectionView!)
        let screen = UIScreen.main.bounds
        NSLayoutConstraint.activate([
            self.collectionView!.topAnchor.constraint(equalTo: topAnchor),
            self.collectionView!.bottomAnchor.constraint(equalTo: bottomAnchor),
                                        self.collectionView!.heightAnchor.constraint(equalToConstant: screen.width * 3/4 ),
            self.collectionView!.leftAnchor.constraint(equalTo: leftAnchor),
            self.collectionView!.rightAnchor.constraint(equalTo: rightAnchor)])
        
        pageControl = UIPageControl(frame: .zero)
        guard self.pageControl != nil  else {return}
        addSubview(pageControl!)
        
        pageControl?.translatesAutoresizingMaskIntoConstraints = false
        pageControl!.centerXAnchor.constraint(equalTo: collectionView!.centerXAnchor).isActive = true
        pageControl!.bottomAnchor.constraint(equalTo: collectionView!.bottomAnchor, constant: 0).isActive = true
    }
}

//MARK: Collection View Data Source
extension PoiDetailImageGallery: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellImages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath as IndexPath) as! ImageCollectionViewCell
        let cellImage = cellImages[indexPath.row]
        cell.item = cellImage
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: self.frame.width, height: self.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
        let index = scrollView.contentOffset.x / witdh
        let roundedIndex = round(index)
        self.pageControl?.currentPage = Int(roundedIndex)
    }
}
