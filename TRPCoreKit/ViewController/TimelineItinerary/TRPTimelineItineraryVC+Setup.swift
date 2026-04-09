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
        tableView.register(TRPTimelineManualPoiCell.self, forCellReuseIdentifier: TRPTimelineManualPoiCell.reuseIdentifier)
        tableView.register(TRPTimelineActivityStepCell.self, forCellReuseIdentifier: TRPTimelineActivityStepCell.reuseIdentifier)
        tableView.register(TRPTimelineRecommendationsCell.self, forCellReuseIdentifier: TRPTimelineRecommendationsCell.reuseIdentifier)
        tableView.register(TRPTimelineEmptyStateCell.self, forCellReuseIdentifier: TRPTimelineEmptyStateCell.reuseIdentifier)
        tableView.register(TRPTimelineSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: TRPTimelineSectionHeaderView.reuseIdentifier)
        tableView.register(TRPTimelineSectionFooterView.self, forHeaderFooterViewReuseIdentifier: TRPTimelineSectionFooterView.reuseIdentifier)

        // POI preview cell for map view
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

        // Initial constraint: below navigation bar (since button is hidden by default)
        dayFilterViewTopConstraint = dayFilterView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 12)

        NSLayoutConstraint.activate([
            dayFilterViewTopConstraint!,
            dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 74)
        ])
    }

    internal func updateDayFilterViewConstraints() {
        // Update day filter view position based on saved plans button visibility
        let newConstraint: NSLayoutConstraint

        if savedPlansButton.isHidden {
            // Button is hidden: attach to navigation bar
            newConstraint = dayFilterView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 12)
        } else {
            // Button is visible: attach to button
            newConstraint = dayFilterView.topAnchor.constraint(equalTo: savedPlansButton.bottomAnchor, constant: 12)
        }

        // Deactivate old constraint and activate new one
        dayFilterViewTopConstraint?.isActive = false
        dayFilterViewTopConstraint = newConstraint
        dayFilterViewTopConstraint?.isActive = true
    }

    internal func setupTableView() {
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

        // Make map full screen (covers entire view)
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

        // Use bottom constraint to slide in/out
        poiPreviewBottomConstraint = poiPreviewContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: expandedOffset)

        NSLayoutConstraint.activate([
            // Container - fixed height, slides up/down via bottom constraint
            poiPreviewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            poiPreviewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            poiPreviewContainerView.heightAnchor.constraint(equalToConstant: collectionViewHeight),
            poiPreviewBottomConstraint!,

            // Collection View
            poiPreviewCollectionView.topAnchor.constraint(equalTo: poiPreviewContainerView.topAnchor),
            poiPreviewCollectionView.leadingAnchor.constraint(equalTo: poiPreviewContainerView.leadingAnchor),
            poiPreviewCollectionView.trailingAnchor.constraint(equalTo: poiPreviewContainerView.trailingAnchor),
            poiPreviewCollectionView.bottomAnchor.constraint(equalTo: poiPreviewContainerView.bottomAnchor)
        ])

        // Add tap gesture to expand when collapsed
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePreviewContainerTap))
        poiPreviewContainerView.addGestureRecognizer(tapGesture)

        // Add pan gesture to drag up/down
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePreviewContainerPan(_:)))
        poiPreviewContainerView.addGestureRecognizer(panGesture)
    }

    @objc private func handlePreviewContainerTap() {
        // Expand when tapped in collapsed state
        if !isCollectionViewExpanded {
            expandCollectionView()
        }
    }

    @objc private func handlePreviewContainerPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .changed:
            // Calculate new bottom constraint based on drag
            let currentOffset = isCollectionViewExpanded ? expandedOffset : collapsedOffset
            var newOffset = currentOffset - translation.y

            // Clamp to valid range
            newOffset = max(expandedOffset, min(collapsedOffset, newOffset))
            poiPreviewBottomConstraint?.constant = newOffset

        case .ended, .cancelled:
            // Determine final state based on velocity and position
            let shouldExpand: Bool
            if abs(velocity.y) > 500 {
                // Fast swipe - use velocity direction
                shouldExpand = velocity.y < 0  // Swipe up = expand
            } else {
                // Slow drag - use position (midpoint threshold)
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
            // Centered horizontally, below day filter
            mainViewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainViewButton.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 16)
        ])
    }

    internal func setupFloatingButtons() {
        view.addSubview(mapFloatingButton)
        view.addSubview(addPlanFloatingButton)

        // Use constraint for add plan button bottom that we can animate
        addPlanButtonBottomConstraint = addPlanFloatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)

        // Map floating button constraints - one for list view, one for map view, one for empty days
        mapFloatingButtonBottomToAddPlanConstraint = mapFloatingButton.bottomAnchor.constraint(equalTo: addPlanFloatingButton.topAnchor, constant: -16)
        mapFloatingButtonBottomToPreviewConstraint = mapFloatingButton.bottomAnchor.constraint(equalTo: poiPreviewContainerView.topAnchor, constant: -16)
        mapFloatingButtonBottomToSafeAreaConstraint = mapFloatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)

        NSLayoutConstraint.activate([
            // Map floating button - bottom right
            mapFloatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            mapFloatingButtonBottomToAddPlanConstraint!, // Default: above add plan button (list view)

            // Add plan floating button - bottom right (constraint managed for animation)
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
