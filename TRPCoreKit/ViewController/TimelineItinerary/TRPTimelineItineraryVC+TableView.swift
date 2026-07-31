//
//  TRPTimelineItineraryVC+TableView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
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

    internal func configureCell(for cellType: TimelineCellType, at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        let isPastDay = viewModel.isSelectedDayPast
        switch cellType {
        case .bookedActivity(let cellData), .reservedActivity(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineActivityCell.reuseIdentifier, for: indexPath) as? TRPTimelineActivityCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            if isPastDay { cell.applyPastDayStyle() }
            return cell

        case .flexibleActivity(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineActivityCell.reuseIdentifier, for: indexPath) as? TRPTimelineActivityCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            if isPastDay { cell.applyPastDayStyle() }
            return cell

        case .manualPoi(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineManualPoiCell.reuseIdentifier, for: indexPath) as? TRPTimelineManualPoiCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            if isPastDay { cell.applyPastDayStyle() }
            return cell

        case .activityStep(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineActivityStepCell.reuseIdentifier, for: indexPath) as? TRPTimelineActivityStepCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData.step, order: cellData.step.order)
            cell.delegate = self
            if isPastDay { cell.applyPastDayStyle() }
            return cell

        case .recommendations(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineRecommendationsCell.reuseIdentifier, for: indexPath) as? TRPTimelineRecommendationsCell else {
                return UITableViewCell()
            }
            // Set delegate BEFORE configure so route calculation delegate calls work
            cell.delegate = self
            cell.configure(with: cellData, indexPath: indexPath)

            if let distances = calculatedDistances[indexPath] {
                for (index, distanceData) in distances {
                    cell.updateDistance(at: index, distance: distanceData.distance, time: distanceData.time)
                }
            }

            if isPastDay { cell.applyPastDayStyle() }
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

        guard headerData.shouldShowHeader else {
            return 0
        }

        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        let headerData = viewModel.headerData(for: section)

        guard headerData.shouldShowHeader else {
            return 0
        }

        return 80
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return nil
        }

        guard section < viewModel.numberOfSections() - 1 else {
            return nil
        }

        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TRPTimelineSectionFooterView.reuseIdentifier) as? TRPTimelineSectionFooterView else {
            return nil
        }

        return footerView
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return 0
        }

        guard section < viewModel.numberOfSections() - 1 else {
            return 0
        }

        // 8px top gap + top line (0.5) + 10px gap + bottom line (0.5).
        return 19
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return 0
        }

        guard section < viewModel.numberOfSections() - 1 else {
            return 0
        }

        return 19
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

        case .flexibleActivity(let cellData):
            delegate?.timelineItineraryDidSelectBookedActivity(self, segment: cellData.segment)

        case .manualPoi:
            break

        case .activityStep(let cellData):
            delegate?.timelineItineraryDidSelectStep(self, step: cellData.step)

        case .recommendations:
            break

        case .emptyState:
            break
        }
    }
}
