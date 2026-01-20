//
//  TRPTimelineItineraryVC+TableView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - TableView DataSource and Delegate methods extracted from main VC
//

import UIKit
import TRPFoundationKit

// MARK: - UITableViewDataSource

extension TRPTimelineItineraryVC: UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellType = viewModel.cellType(at: indexPath) else {
            return UITableViewCell()
        }
        return configureCell(for: cellType, at: indexPath, in: tableView)
    }

    /// Configure cell using TimelineCellType with pre-computed cell data
    internal func configureCell(for cellType: TimelineCellType, at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        switch cellType {
        case .bookedActivity(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineBookedActivityCell.reuseIdentifier, for: indexPath) as? TRPTimelineBookedActivityCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            return cell

        case .reservedActivity(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineBookedActivityCell.reuseIdentifier, for: indexPath) as? TRPTimelineBookedActivityCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            return cell

        case .manualPoi(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineManualPoiCell.reuseIdentifier, for: indexPath) as? TRPTimelineManualPoiCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            return cell

        case .activityStep(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineActivityStepCell.reuseIdentifier, for: indexPath) as? TRPTimelineActivityStepCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData.step, order: cellData.step.order)
            cell.delegate = self
            return cell

        case .recommendations(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineRecommendationsCell.reuseIdentifier, for: indexPath) as? TRPTimelineRecommendationsCell else {
                return UITableViewCell()
            }
            // Set delegate BEFORE configure so route calculation delegate calls work
            cell.delegate = self
            cell.configure(with: cellData, indexPath: indexPath)

            // Apply any pre-calculated distances
            if let distances = calculatedDistances[indexPath] {
                for (index, distanceData) in distances {
                    cell.updateDistance(at: index, distance: distanceData.distance, time: distanceData.time)
                }
            }

            return cell

        case .emptyState:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineEmptyStateCell.reuseIdentifier, for: indexPath) as? TRPTimelineEmptyStateCell else {
                return UITableViewCell()
            }
            cell.configure()
            cell.delegate = self
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerData = viewModel.headerData(for: section)

        // Don't show header if shouldShowHeader is false
        guard headerData.shouldShowHeader else {
            return nil
        }

        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TRPTimelineSectionHeaderView.reuseIdentifier) as? TRPTimelineSectionHeaderView else {
            return nil
        }

        headerView.configure(with: headerData)
        headerView.delegate = self
        return headerView
    }
}

// MARK: - UITableViewDelegate

extension TRPTimelineItineraryVC: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let headerData = viewModel.headerData(for: section)

        // Return 0 height if header should not be shown
        guard headerData.shouldShowHeader else {
            return 0
        }

        // Return automatic dimension for header
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        let headerData = viewModel.headerData(for: section)

        // Return 0 estimated height if header should not be shown
        guard headerData.shouldShowHeader else {
            return 0
        }

        // Return estimated height for header
        return 80
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Don't show footer for empty state
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return nil
        }

        // Don't show footer after the last section
        guard section < viewModel.numberOfSections() - 1 else {
            return nil
        }

        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TRPTimelineSectionFooterView.reuseIdentifier) as? TRPTimelineSectionFooterView else {
            return nil
        }

        return footerView
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Don't show footer for empty state
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return 0
        }

        // Don't show footer after the last section
        guard section < viewModel.numberOfSections() - 1 else {
            return 0
        }

        return 60
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        // Don't show footer for empty state
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return 0
        }

        // Don't show footer after the last section
        guard section < viewModel.numberOfSections() - 1 else {
            return 0
        }

        return 60
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let cellType = viewModel.cellType(at: indexPath) else {
            return
        }

        switch cellType {
        case .bookedActivity(let cellData):
            delegate?.timelineItineraryDidSelectBookedActivity(self, segment: cellData.segment)

        case .reservedActivity(let cellData):
            delegate?.timelineItineraryDidSelectBookedActivity(self, segment: cellData.segment)

        case .manualPoi:
            // Manual POI cell handles selection internally via TRPTimelineManualPoiCellDelegate
            break

        case .activityStep(let cellData):
            delegate?.timelineItineraryDidSelectStep(self, step: cellData.step)

        case .recommendations:
            // Recommendations cell handles selection internally
            break

        case .emptyState:
            // Empty state cell handles selection internally via button
            break
        }
    }
}
