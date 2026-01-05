//
//  ItineraryStepPoiDetailViewController.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPFoundationKit

@objc(SPMItineraryStepPoiDetailViewController)
class ItineraryStepPoiDetailViewController: TRPBaseUIViewController {
    
    // MARK: - Properties
    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return tableView
    }()
    
    var viewModel: ItineraryStepPoiDetailViewModel!
    private var openHourController = OpenHourCellController()
    private var discriptionController = DescriptionCellController()
    
    // MARK: - Initialization
    public init(viewModel: ItineraryStepPoiDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        view.backgroundColor = UIColor.white
        setupTableView()
        viewModel.delegate = self

        // Set navigation bar title
        title = viewModel.step.poi.name

        // Show navigation bar with back button
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func setupViews() {
        super.setupViews()
        view.backgroundColor = UIColor.white
        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - Setup
    private func setupTableView() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        
        // Register cells
        tableView.register(cellClass: UITableViewCell.self)
        tableView.register(cellClass: ImageCarouselTableViewCell.self)
        tableView.register(cellClass: TitleTableViewCell.self)
        tableView.register(cellClass: PlaceDetailCustomTagsCell.self)
        tableView.register(cellClass: ExpandableTableViewCell.self)
        tableView.register(cellClass: OpeningHoursCell.self)
        tableView.register(cellClass: ButtonTableViewCell.self)
        tableView.register(cellClass: MapTableViewCell.self)

        // Register PoiDetailImageAndTitle from XIB if available
        let bundle = Bundle(for: PoiDetailImageAndTitle.self)
        if let _ = bundle.path(forResource: "PoiDetailImageAndTitle", ofType: "nib") {
            let nib = UINib(nibName: "PoiDetailImageAndTitle", bundle: bundle)
            tableView.register(nib, forCellReuseIdentifier: String(describing: PoiDetailImageAndTitle.self))
        } else {
            // Fallback: register class (won't work with IBOutlets but prevents crash)
            tableView.register(cellClass: PoiDetailImageAndTitle.self)
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension ItineraryStepPoiDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getCellViewModel(at: indexPath)
        
        switch model.type {
        case .galleryTitle:
            return makeGalleryWithTitleCell(tableView, cellForRowAt: indexPath, model: model)
        case .description:
            return makeExpandableCell(tableView, cellForRowAt: indexPath, model: model)
        case .openCloseHour:
            return makeOpenCloseCell(tableView, cellForRowAt: indexPath, model: model)
        case .phone, .address:
            return makeBasicCell(tableView, cellForRowAt: indexPath, model: model)
        case .map:
            return makeMapCell(tableView, cellForRowAt: indexPath, model: model)
        case .activities:
            return makeBasicCell(tableView, cellForRowAt: indexPath, model: model)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getCellViewModel(at: indexPath)
        
        if model.type == .openCloseHour {
            tableView.beginUpdates()
            openHourController.didSelectCell()
            tableView.endUpdates()
        } else if model.type == .description {
            tableView.beginUpdates()
            discriptionController.didSelectCell()
            tableView.endUpdates()
        }
    }
}

// MARK: - Cell Creation
extension ItineraryStepPoiDetailViewController {
    
    private func makeBasicCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ItineraryStepPoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PlaceDetailCustomTagsCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiDetailBasicCellModel {
            cell.customLabel.text = cellModel.content
            if !cellModel.icon.isEmpty {
                cell.setIcon(inFramework: cellModel.icon, inApp: "")
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeGalleryWithTitleCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ItineraryStepPoiDetailCellContent) -> UITableViewCell {
        // Create a simple cell with image gallery programmatically
        // Since PoiDetailImageAndTitle requires XIB and we don't have it,
        // we'll create a basic cell with the POI name and rating

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "GalleryTitleCell")
        cell.selectionStyle = .none

        if let cellModel = model.data as? PoiImageWithTitleModel {
            cell.textLabel?.text = cellModel.title
            cell.textLabel?.font = FontSet.montserratSemiBold.font(18)
            cell.textLabel?.textColor = ColorSet.fg.uiColor

            // Show rating if available
            if cellModel.globalRating && cellModel.starCount > 0 {
                let ratingText = String(repeating: "⭐️", count: cellModel.starCount) + " (\(cellModel.reviewCount) reviews)"
                cell.detailTextLabel?.text = ratingText
                cell.detailTextLabel?.font = FontSet.montserratRegular.font(14)
                cell.detailTextLabel?.textColor = ColorSet.fgWeaker.uiColor
            }
        }

        return cell
    }
    
    private func makeExpandableCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ItineraryStepPoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExpandableTableViewCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiDetailBasicCellModel {
            if !cellModel.icon.isEmpty {
                cell.setIcon(inFramework: cellModel.icon, inApp: "")
            }
            discriptionController.configureCell(cell, model: cellModel.content)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeOpenCloseCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ItineraryStepPoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: OpeningHoursCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? PoiDetailBasicCellModel {
            openHourController.configureCell(cell, model: cellModel.content)
            if !cellModel.icon.isEmpty {
                cell.setIcon(inFramework: cellModel.icon, inApp: "")
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeMapCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ItineraryStepPoiDetailCellContent) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: MapTableViewCell.self, forIndexPath: indexPath)
        if let cellModel = model.data as? TRPLocation {
            cell.setMapView(cellModel, iconTag: viewModel.step.poi.icon ?? "")
        }
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - ViewModel Delegate
extension ItineraryStepPoiDetailViewController: ItineraryStepPoiDetailViewModelDelegate {
    
    override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
    override func viewModel(showPreloader: Bool) {
        // Handle preloader if needed
    }
}

