//
//  TRPTimelineItineraryVC+Setup.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Setup and configuration methods extracted from main VC
//

import UIKit
import TRPFoundationKit

// MARK: - Setup Methods

extension TRPTimelineItineraryVC {

    internal func registerCells() {
        tableView.register(TRPTimelineBookedActivityCell.self, forCellReuseIdentifier: TRPTimelineBookedActivityCell.reuseIdentifier)
        tableView.register(TRPTimelineReservedActivityCell.self, forCellReuseIdentifier: TRPTimelineReservedActivityCell.reuseIdentifier)
        tableView.register(TRPTimelineFlexibleActivityCell.self, forCellReuseIdentifier: TRPTimelineFlexibleActivityCell.reuseIdentifier)
        tableView.register(TRPTimelineManualPoiCell.self, forCellReuseIdentifier: TRPTimelineManualPoiCell.reuseIdentifier)
        tableView.register(TRPTimelineActivityStepCell.self, forCellReuseIdentifier: TRPTimelineActivityStepCell.reuseIdentifier)
        tableView.register(TRPTimelineRecommendationsCell.self, forCellReuseIdentifier: TRPTimelineRecommendationsCell.reuseIdentifier)
        tableView.register(TRPTimelineEmptyStateCell.self, forCellReuseIdentifier: TRPTimelineEmptyStateCell.reuseIdentifier)
        tableView.register(TRPTimelineSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: TRPTimelineSectionHeaderView.reuseIdentifier)
        tableView.register(TRPTimelineSectionFooterView.self, forHeaderFooterViewReuseIdentifier: TRPTimelineSectionFooterView.reuseIdentifier)

        poiPreviewCollectionView.register(TRPTimelineMapPOIPreviewCell.self, forCellWithReuseIdentifier: TRPTimelineMapPOIPreviewCell.reuseIdentifier)
    }

    internal func setupTimelineNavigationBar() {
        guard customNavigationBar == nil else { return }

        let title = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.navigationTitle)
        customNavigationBar = setupCustomNavigationBar(title: title, height: 44)
        customNavigationBar.delegate = self
    }

    internal func setupSavedPlansButton() {
        guard savedPlansButton.superview == nil else { return }

        view.addSubview(savedPlansButton)

        NSLayoutConstraint.activate([
            savedPlansButton.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 12),
            savedPlansButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            savedPlansButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            savedPlansButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    internal func setupDayFilterView() {
        guard dayFilterView.superview == nil else { return }

        view.addSubview(dayFilterView)

        // Defaults below the nav bar since the saved-plans button is hidden by default.
        dayFilterViewTopConstraint = dayFilterView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 12)

        NSLayoutConstraint.activate([
            dayFilterViewTopConstraint!,
            dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 74)
        ])
    }

    internal func updateDayFilterViewConstraints() {
        let newConstraint: NSLayoutConstraint

        if savedPlansButton.isHidden {
            newConstraint = dayFilterView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 12)
        } else {
            newConstraint = dayFilterView.topAnchor.constraint(equalTo: savedPlansButton.bottomAnchor, constant: 12)
        }

        dayFilterViewTopConstraint?.isActive = false
        dayFilterViewTopConstraint = newConstraint
        dayFilterViewTopConstraint?.isActive = true
    }

    internal func setupTableView() {
        // The conflict banner rides as `tableHeaderView` (scrolls with the list); host installs/removes it in `updateConflictWarningVisibility()`.
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    internal func setupMapView() {
        view.addSubview(mapContainerView)

        NSLayoutConstraint.activate([
            mapContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            mapContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    internal func setupPOIPreviewCards() {
        view.addSubview(poiPreviewContainerView)
        poiPreviewContainerView.addSubview(poiPreviewCollectionView)

        poiPreviewBottomConstraint = poiPreviewContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: expandedOffset)

        NSLayoutConstraint.activate([
            poiPreviewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            poiPreviewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            poiPreviewContainerView.heightAnchor.constraint(equalToConstant: collectionViewHeight),
            poiPreviewBottomConstraint!,

            poiPreviewCollectionView.topAnchor.constraint(equalTo: poiPreviewContainerView.topAnchor),
            poiPreviewCollectionView.leadingAnchor.constraint(equalTo: poiPreviewContainerView.leadingAnchor),
            poiPreviewCollectionView.trailingAnchor.constraint(equalTo: poiPreviewContainerView.trailingAnchor),
            poiPreviewCollectionView.bottomAnchor.constraint(equalTo: poiPreviewContainerView.bottomAnchor)
        ])

        // cancelsTouchesInView = false so collection view cells still receive taps.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePreviewContainerTap))
        tapGesture.cancelsTouchesInView = false
        poiPreviewContainerView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePreviewContainerPan(_:)))
        poiPreviewContainerView.addGestureRecognizer(panGesture)
    }

    @objc private func handlePreviewContainerTap() {
        if !isCollectionViewExpanded {
            expandCollectionView()
        }
    }

    @objc private func handlePreviewContainerPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .changed:
            let currentOffset = isCollectionViewExpanded ? expandedOffset : collapsedOffset
            var newOffset = currentOffset - translation.y

            newOffset = max(expandedOffset, min(collapsedOffset, newOffset))
            poiPreviewBottomConstraint?.constant = newOffset

        case .ended, .cancelled:
            let shouldExpand: Bool
            if abs(velocity.y) > 500 {
                shouldExpand = velocity.y < 0  // Swipe up = expand
            } else {
                let midpoint = (expandedOffset + collapsedOffset) / 2
                shouldExpand = (poiPreviewBottomConstraint?.constant ?? 0) < midpoint
            }

            if shouldExpand {
                expandCollectionView()
            } else {
                collapseCollectionView()
            }

        default:
            break
        }
    }

    internal func setupMainViewButton() {
        view.addSubview(mainViewButton)

        NSLayoutConstraint.activate([
            mainViewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainViewButton.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 16)
        ])
    }

    internal func setupFloatingButtons() {
        view.addSubview(mapFloatingButton)
        view.addSubview(addPlanFloatingButton)

        addPlanButtonBottomConstraint = addPlanFloatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)

        // One map-button constraint each for list view, map view, and empty days.
        mapFloatingButtonBottomToAddPlanConstraint = mapFloatingButton.bottomAnchor.constraint(equalTo: addPlanFloatingButton.topAnchor, constant: -16)
        mapFloatingButtonBottomToPreviewConstraint = mapFloatingButton.bottomAnchor.constraint(equalTo: poiPreviewContainerView.topAnchor, constant: -16)
        mapFloatingButtonBottomToSafeAreaConstraint = mapFloatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)

        NSLayoutConstraint.activate([
            mapFloatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            mapFloatingButtonBottomToAddPlanConstraint!,

            addPlanFloatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            addPlanButtonBottomConstraint!
        ])
    }

    internal func setupNoCityView() {
        view.addSubview(noCityView)

        NSLayoutConstraint.activate([
            noCityView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor),
            noCityView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noCityView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noCityView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
