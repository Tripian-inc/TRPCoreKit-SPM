//
//  ExperienceDetailViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 17.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPUIKit
import TRPProvider
import TRPFoundationKit

public protocol ExperienceDetailViewControllerDelegate: AnyObject {
    func experienceDetailVCOpenReviews(_ navigationController: UINavigationController?, viewController: UIViewController, tourId: Int)
    func experienceDetailVCOpenAvailability(_ navigationController: UINavigationController?, viewController: UIViewController, tourId: Int)
    
    func experienceDetailVCOpenMoreInfo(_ navigationController: UINavigationController?, viewController: UIViewController, tour: GYGTour)
}


public class ExperienceDetailViewController: TRPBaseUIViewController {
    
    public weak var delegate: ExperienceDetailViewControllerDelegate?
    private var tableView: EvrTableView = EvrTableView()
    private var bottomView: ExperienceBottomView?
    private let viewModel: ExperienceDetailViewModel
//    private var loader: TRPLoaderView?
    public var useCases: TRPMakeBookingUseCases?
    
    
    public init(viewModel: ExperienceDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        title = "Tour details"
        
        setupTableView()
        setupViews()
        if viewModel.isFromTrip() {
            addCloseButton(position: .left)
        } else {
            addBackButton(position: .left)
        }
//        loader = TRPLoaderView(superView: view)
        //setupView()
        viewModel.start()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
//        navigationController?.setNavigationBarHidden(false, animated: false)
//        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
//    private func setupViews() {
//        super.setupViews()
//    }
    
    @objc func reservationPressed() {
        //useCases?.tour = viewModel.tour
        //delegate?.experienceDetailVCOpenAvailability(navigationController, viewController: self, tourId: viewModel.tourId)
        if let gygURL = viewModel.tour?.url, let url = URL(string: gygURL) {
            openURL(url)
        }else {
            print("[Error] GYG URL NOT FOUND")
        }
    }
    
    func readAllReviewPressed() {
        delegate?.experienceDetailVCOpenReviews(self.navigationController, viewController: self, tourId: viewModel.tourId)
    }
    
    func prepareForActivityPressed() {
        guard let tour = viewModel.tour else {return}
        delegate?.experienceDetailVCOpenMoreInfo(self.navigationController, viewController: self, tour: tour)
    }
    
    private func openURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:])
    }
}

extension ExperienceDetailViewController: UITableViewDelegate, UITableViewDataSource{
    
    fileprivate func setupTableView() {
    
        tableView = EvrTableView(frame: CGRect.zero)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomView = ExperienceBottomView(frame: .zero)
        view.addSubview(bottomView!)
        bottomView!.translatesAutoresizingMaskIntoConstraints = false
        bottomView!.reservationButton.addTarget(self, action: #selector(reservationPressed), for: .touchDown)
        
        NSLayoutConstraint.activate([
            bottomView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomView!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomView!.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomView!.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.register(cellClass: UITableViewCell.self)
        tableView.register(cellClass: ExperienceImageGalleryCell.self)
        tableView.register(cellClass: ExperienceDetailTextCell.self)
        tableView.register(cellClass: ExperienceDetailTitleAndReviewCell.self)
        tableView.register(cellClass: ExperienceHeaderCell.self)
        tableView.register(cellClass: ReviewsCell.self)
        tableView.register(cellClass: ExperienceDetailSubTitleTextCell.self)
        tableView.register(cellClass: ExperienceDetailAllReviewCell.self)
        tableView.register(cellClass: ExperienceBasicCell.self)
        tableView.register(cellClass: ExperienceDetailButtonCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorStyle = .none
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = viewModel.getCellViewModel(at: indexPath)
        if model.type == .imageGallery {
            return makeImageGalleryCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .titleAndReview {
            return makeTitleAndReviewCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .header {
            return makeHeaderCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .reviews {
            return makeReviewCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .readAllReview || model.type == .moreInfo {
            return makeButton(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .subTitleText {
            return makeSubTitleTextCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .dot {
            return makeDotCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .abstract {
            return makeBasicCell(tableView, cellForRowAt: indexPath, model: model)
        }
        return makeDetailTitleCell(tableView, cellForRowAt: indexPath, model: model)
    }
    
    
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getCellViewModel(at: indexPath)
        if model.type == .reviews {
            delegate?.experienceDetailVCOpenReviews(self.navigationController, viewController: self, tourId: viewModel.tourId)
        }
    }
    
}

//MARK: - Make Cell
extension ExperienceDetailViewController {
    
    private func makeImageGalleryCell(_ tableView: UITableView,
                                      cellForRowAt indexPath: IndexPath,
                                      model: ExperienceDetailCellModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: ExperienceImageGalleryCell.self, forIndexPath: indexPath)
        
        if let content = model.data as? [String] {
            cell.cellImages = content
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeReviewCell(_ tableView: UITableView,
                                cellForRowAt indexPath: IndexPath,
                                model: ExperienceDetailCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ReviewsCell.self, forIndexPath: indexPath)
        if let content = model.data as? GYGReview {
            cell.reviewLbl.text = content.comment
            cell.userNameLbl.text = content.reviewerName
            
            if let textToTime = TRPTime(dateTime: content.reviewDate), let date = textToTime.toDate {
                cell.starAndDateLbl.text = "\(content.reviewRating) • \(date.toString(dateStyle: .medium))"
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeHeaderCell(_ tableView: UITableView,
                                cellForRowAt indexPath: IndexPath,
                                model: ExperienceDetailCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceHeaderCell.self, forIndexPath: indexPath)
        
        if let content = model.data as? ExperienceHeaderCellModel {
            cell.headerLabel.text = content.header
            if content.showSeperater {
                cell.addSeparator(at: .top, color: UIColor.lightGray, weight: 0.5, insets: UIEdgeInsets(top: 14, left: 20, bottom: 0, right: 0))
            }else {
                cell.removeSeperator()
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeTitleAndReviewCell(_ tableView: UITableView,
                                        cellForRowAt indexPath: IndexPath,
                                        model: ExperienceDetailCellModel) -> UITableViewCell {
        
        let cell = tableView.dequeue(cellClass: ExperienceDetailTitleAndReviewCell.self, forIndexPath: indexPath)
        
        if let converted = model.data as? ExperienceDetailTitleCellModel {
            cell.titleLabel.text = converted.title
            cell.setStarAndRating(star: converted.starCount, review: converted.ratingCount)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeBasicCell(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath,
                               model: ExperienceDetailCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceBasicCell.self, forIndexPath: indexPath)
        if let textContent = model.data as? String {
            cell.contentLabel.text = textContent
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeDetailTitleCell(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath,
                               model: ExperienceDetailCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceDetailTextCell.self, forIndexPath: indexPath)
        
        cell.titleLabel.text = viewModel.getCellViewModel(at: indexPath).type.rawValue
        if let textContent = model.data as? String {
            cell.contentLabel.text = textContent
        }
        cell.selectionStyle = .none
        return cell
    }
    
    private func makeButton(_ tableView: UITableView,
                                        cellForRowAt indexPath: IndexPath,
                                        model: ExperienceDetailCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceDetailButtonCell.self, forIndexPath: indexPath)
        cell.selectionStyle = .none
        cell.button.setTitle(model.type.rawValue, for: .normal)
        cell.action = {
            if model.type == .readAllReview {
                self.readAllReviewPressed()
                
            }else if model.type == .moreInfo {
                self.prepareForActivityPressed()
            }
        }
     
        
        return cell
    }
    
    
    private func makeSubTitleTextCell(_ tableView: UITableView,
                                      cellForRowAt indexPath: IndexPath,
                                      model: ExperienceDetailCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ExperienceDetailSubTitleTextCell.self, forIndexPath: indexPath)
        
        if let content = model.data as? ExperienceSubTitleText {
            cell.set(title: content.title, content: content.content)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    
    private func makeDotCell(_ tableView: UITableView,
                             cellForRowAt indexPath: IndexPath,
                             model: ExperienceDetailCellModel) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: UITableViewCell.self, forIndexPath: indexPath)
        
        if let text = model.data as? String {
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.attributedText = setDotText(content: text)
        }
        
        cell.accessoryType = .none
        cell.selectionStyle = .none
        return cell
    }
    
    public func setDotText(content: String) -> NSMutableAttributedString{
        let _title = " • "
        let attributed = _title.addStyle([.foregroundColor: TRPColor.pink, .font: UIFont.systemFont(ofSize: 20, weight: .bold)])
        attributed.addString(content, syle: [.foregroundColor: TRPColor.darkGrey, .font: UIFont.systemFont(ofSize: 15)])
        return attributed
    }
}



extension ExperienceDetailViewController: ExperienceDetailViewModelDelegate {
    
    public override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
//        if let bottomView = bottomView, let price = viewModel.getPrice() {
//            let description = price.description == "individual" ? "per person" : price.description
//            bottomView.setPrice(price: "$\(price.values.amount)", description: description)
//            bottomView.setDiscount(savings: price.values.special?.savings)
//        }
    }
}
