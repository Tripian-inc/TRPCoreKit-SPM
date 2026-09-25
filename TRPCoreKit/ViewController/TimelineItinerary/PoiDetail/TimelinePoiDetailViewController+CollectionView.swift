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
        } else if collectionView == productsCollectionView {
            if viewModel.isLoadingProducts {
                return Self.skeletonProductCount
            }
            return viewModel.getProducts().count + (viewModel.isLoadingMoreProducts ? 1 : 0)
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
        } else if collectionView == productsCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardCell.reuseIdentifier, for: indexPath) as? ProductCardCell else {
                return UICollectionViewCell()
            }

            let products = viewModel.getProducts()
            if indexPath.item < products.count {
                cell.configure(with: products[indexPath.item])
            } else {
                cell.configureSkeleton()
            }

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
            return CGSize(width: width, height: width)
        } else if collectionView == productsCollectionView {
            return CGSize(width: 253, height: 295)
        }
        return .zero
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == productsCollectionView {
            guard let product = viewModel.getProducts()[safe: indexPath.item] else { return }
            // `product.id` is the `C_{id}_{provider}` form; strip to the bare product id like every other callsite.
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: product.id.cleanedAsActivityId())
        }
    }
}

// MARK: - UIScrollViewDelegate

extension TimelinePoiDetailViewController: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == productsCollectionView {
            let paginationThreshold: CGFloat = 100
            let offsetX = scrollView.contentOffset.x
            let frameWidth = scrollView.frame.width
            let contentWidth = scrollView.contentSize.width

            if contentWidth > 0, offsetX + frameWidth >= contentWidth - paginationThreshold {
                viewModel.loadMoreProducts()
            }
            return
        }

        guard scrollView == imageCollectionView else { return }

        let pageWidth = scrollView.bounds.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)

        if currentPage != currentImageIndex {
            currentImageIndex = currentPage
            pageControl.currentPage = currentPage
        }
    }
}
