//
//  MustTryDetailViewController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit
import TRPDataLayer

public protocol MustTryDetailVCDelegate: AnyObject {
    func mustTryDetailVCDelegateOpenPlaceDetail(_ viewController: UIViewController, poi: TRPPoi)
}


class MustTryDetailViewController: TRPBaseUIViewController {
    
    private var tableView: EvrTableView = EvrTableView()
    
    private var headerImageView: UIImageView = {
        var imageView = UIImageView()
        imageView.backgroundColor = UIColor.gray
        return imageView
    }()
    
    private var foodTitle: UILabel = {
        var lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 32, weight: .semibold).italic()
        lbl.text = ""
        lbl.textColor = UIColor.white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.layer.shadowColor = UIColor.black.cgColor
        lbl.layer.shadowRadius = 3.0
        lbl.layer.shadowOpacity = 0.4
        lbl.layer.shadowOffset = CGSize(width: 4, height: 4)
        lbl.layer.masksToBounds = false
        
        return lbl
    }()
    
    
    private let viewModel: MustTryDetailViewModel
    private var isDataLoaded = false
    private let imageHeight: CGFloat = 200
    public weak var delegate: MustTryDetailVCDelegate?
    
    
    init(viewModel: MustTryDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func setupViews() {
        super.setupViews()
        setupTableView()
        
        headerImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: imageHeight )
        view.addSubview(headerImageView)
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.sd_setImage(with: viewModel.getHeaderImage())
        
        view.addSubview(foodTitle)
        foodTitle.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor, constant: 16).isActive = true
        foodTitle.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor, constant: -16).isActive = true
        foodTitle.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: -16).isActive = true
        foodTitle.text = viewModel.taste.name.uppercased()
        
        addCloseButton(position: .left)
    }
    
    
    public override func viewDidAppear(_ animated: Bool) {
        if !isDataLoaded {
            isDataLoaded.toggle()
            viewModel.start()
        }
    }
   
    
    deinit {
        print("MustTryDeinit")
    }
}

extension MustTryDetailViewController: UITableViewDelegate, UITableViewDataSource{
    
    fileprivate func setupTableView() {
        tableView = EvrTableView(frame: CGRect.zero)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.register(cellClass: MustTryDetailDescriptionCell.self)
        tableView.register(cellClass: AddPlaceListTableViewCell.self)
        tableView.register(cellClass: MustTryDetailWhereToTryCell.self)
        tableView.contentInset = UIEdgeInsets(top: imageHeight, left: 0, bottom: 0, right: 0)
        tableView.separatorStyle = .none
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = viewModel.getCellViewModel(at: indexPath)
        if model.type == .description {
            return makeDescriptionCell(tableView, cellForRowAt: indexPath, model: model)
        }else if model.type == .whereToTrys{
            return makeWhereToTryCell(tableView, cellForRowAt: indexPath, model: model)
        }else {
            return makePoiCell(tableView, cellForRowAt: indexPath, model: model)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getCellViewModel(at: indexPath)
        if model.type == .poi, let poi = model.data as? TRPPoi{
            delegate?.mustTryDetailVCDelegateOpenPlaceDetail(self, poi: poi)
        }
    }
    
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yPos: CGFloat = -scrollView.contentOffset.y
        changeImageFrameWithScroll(scrollY: yPos)
    }
    
    private func changeImageFrameWithScroll( scrollY: CGFloat) {
        if scrollY > 0 {
            var imgRect: CGRect? = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: imageHeight )
            imgRect?.size.height = imageHeight + scrollY  - imageHeight
            headerImageView.frame = imgRect!
        }
    }
}

extension MustTryDetailViewController {
    
    private func makeDescriptionCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: MustTryCellModel) -> UITableViewCell{
        
        let cell = tableView.dequeue(cellClass: MustTryDetailDescriptionCell.self, forIndexPath: indexPath)
        if let model = model.data as? String {
            cell.label.text = model
        }
        return cell
    }
    
    private func makeWhereToTryCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: MustTryCellModel) -> UITableViewCell{
        
        let cell = tableView.dequeue(cellClass: MustTryDetailWhereToTryCell.self, forIndexPath: indexPath)
        if let model = model.data as? String {
            cell.label.text = model
        }
        return cell
    }
    
    
    private func makePoiCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: MustTryCellModel) -> UITableViewCell{
        let cell = tableView.dequeue(cellClass: AddPlaceListTableViewCell.self, forIndexPath: indexPath)
        
        if let model = model.data as? TRPPoi {
            
            cell.setTitle(model.name)
            cell.index = indexPath.row
            cell.setExplaintText(text: nil)
            cell.isSuggestedByTripian = false//viewModel.isSuggestedByTripian(id: model.id)
            //TODO: - Performans için çok kötü refactor edilmek zorunda
            //50000
            if let distance = viewModel.getDistanceFromUserLocation(toPoiLat: model.coordinate.lat, toPoiLon: model.coordinate.lon) {
                if distance < 50000 {
                    let tempDis = Int(distance)
                    cell.distanceLabel.text = tempDis.reableDistance()
                }
            }
            
            let explain = viewModel.getExplainText(placeId: model.id)
            cell.setExplaintText(text: explain)
            
            if let imageUrl = viewModel.getPlaceImage(indexPath: indexPath) {
                cell.getImageView().sd_setImage(with: imageUrl)
            }else {
                cell.getImageView().image = nil
            }
            /*if indexPath.row == viewModel.getPlaceCount() - 1 {
             viewModel.loadNextPage()
             } */
        }
        
        return cell
    }
}


extension MustTryDetailViewController: MustTryDetailViewModelDelegate {
    public override func viewModel(dataLoaded: Bool) {
        tableView.reloadData()
    }
    
}
