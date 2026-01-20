//
//  TimelinePoiDetailViewController+CollectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - CollectionView DataSource/Delegate extracted from main VC
//

import UIKit
import TRPFoundationKit

// MARK: - UICollectionViewDataSource

extension TimelinePoiDetailViewController: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == imageCollectionView {
            return viewModel.getImageUrls().count
        } else if collectionView == activitiesCollectionView {
            return viewModel.getProducts().count
        }
        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == imageCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PoiImageCell.reuseIdentifier, for: indexPath) as? PoiImageCell else {
                return UICollectionViewCell()
            }

            let imageUrl = viewModel.getImageUrls()[indexPath.item]
            cell.configure(with: imageUrl)

            return cell
        } else if collectionView == activitiesCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardCell.reuseIdentifier, for: indexPath) as? ProductCardCell else {
                return UICollectionViewCell()
            }

            let product = viewModel.getProducts()[indexPath.item]
            cell.configure(with: product)

            return cell
        }

        return UICollectionViewCell()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TimelinePoiDetailViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == imageCollectionView {
            let width = collectionView.bounds.width
            return CGSize(width: width, height: width) // 1:1 ratio
        } else if collectionView == activitiesCollectionView {
            let width: CGFloat = 280
            let height: CGFloat = 280 // Increased for dynamic content
            return CGSize(width: width, height: height)
        }
        return .zero
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == activitiesCollectionView {
            let product = viewModel.getProducts()[indexPath.item]
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: product.id)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension TimelinePoiDetailViewController: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == imageCollectionView else { return }

        let pageWidth = scrollView.bounds.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)

        if currentPage != currentImageIndex {
            currentImageIndex = currentPage
            pageControl.currentPage = currentPage
        }
    }
}
