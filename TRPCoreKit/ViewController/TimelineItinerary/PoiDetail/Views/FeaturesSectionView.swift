//
//  FeaturesSectionView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Features section view extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit

class FeaturesSectionView: UIView {

    private let headerLabel: UILabel
    private let tagsCollectionView: UICollectionView
    private var tags: [String] = []
    private var collectionHeightConstraint: NSLayoutConstraint!

    init(headerLabel: UILabel, tags: [String]) {
        self.headerLabel = headerLabel
        self.tags = tags

        let layout = TagsFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16

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

        addSubview(headerLabel)
        addSubview(tagsCollectionView)

        // Create height constraint for collection view
        collectionHeightConstraint = tagsCollectionView.heightAnchor.constraint(equalToConstant: 100)

        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Tags CollectionView
            tagsCollectionView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            tagsCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tagsCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tagsCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            collectionHeightConstraint
        ])
    }

    func updateTags(_ newTags: [String]) {
        tags = newTags
        tagsCollectionView.reloadData()

        // Force layout and update height after reload
        tagsCollectionView.layoutIfNeeded()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let contentHeight = self.tagsCollectionView.collectionViewLayout.collectionViewContentSize.height
            self.collectionHeightConstraint.constant = contentHeight
            self.layoutIfNeeded()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension FeaturesSectionView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCell.reuseIdentifier, for: indexPath) as? TagCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: tags[indexPath.item])
        return cell
    }
}
