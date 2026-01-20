//
//  ProductsSectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Products section view extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit

class ProductsSectionView: UIView {

    private let headerView: UIView
    private let collectionView: UICollectionView
    private var collectionHeightConstraint: NSLayoutConstraint!

    init(headerView: UIView, collectionView: UICollectionView) {
        self.headerView = headerView
        self.collectionView = collectionView

        super.init(frame: .zero)
        setupView()
        observeCollectionViewContentSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerView)
        addSubview(collectionView)

        // Create dynamic height constraint
        collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 280)

        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // CollectionView
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionHeightConstraint,
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    private func observeCollectionViewContentSize() {
        collectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let newSize = change?[.newKey] as? CGSize {
                collectionHeightConstraint.constant = newSize.height
            }
        }
    }

    deinit {
        collectionView.removeObserver(self, forKeyPath: "contentSize")
    }
}
