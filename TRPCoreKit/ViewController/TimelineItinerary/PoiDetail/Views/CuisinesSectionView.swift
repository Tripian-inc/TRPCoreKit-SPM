//
//  CuisinesSectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 28.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Cuisines section view for Eat & Drink POIs
//

import UIKit
import TRPFoundationKit

class CuisinesSectionView: UIView {

    private let tagsCollectionView: UICollectionView
    private var cuisines: [String] = []
    private var collectionHeightConstraint: NSLayoutConstraint!

    init(cuisines: [String]) {
        self.cuisines = cuisines

        let layout = CenteredTagsFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12

        self.tagsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        tagsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        tagsCollectionView.backgroundColor = .clear
        tagsCollectionView.isScrollEnabled = false
        tagsCollectionView.dataSource = self
        tagsCollectionView.register(TagCell.self, forCellWithReuseIdentifier: TagCell.reuseIdentifier)

        addSubview(tagsCollectionView)

        collectionHeightConstraint = tagsCollectionView.heightAnchor.constraint(equalToConstant: 40)

        NSLayoutConstraint.activate([
            tagsCollectionView.topAnchor.constraint(equalTo: topAnchor),
            tagsCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tagsCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tagsCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            collectionHeightConstraint
        ])
    }

    func updateCuisines(_ newCuisines: [String]) {
        cuisines = newCuisines
        tagsCollectionView.reloadData()

        tagsCollectionView.layoutIfNeeded()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let contentHeight = self.tagsCollectionView.collectionViewLayout.collectionViewContentSize.height
            self.collectionHeightConstraint.constant = max(contentHeight, 30)
            self.layoutIfNeeded()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CuisinesSectionView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cuisines.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCell.reuseIdentifier, for: indexPath) as? TagCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: cuisines[indexPath.item])
        return cell
    }
}
