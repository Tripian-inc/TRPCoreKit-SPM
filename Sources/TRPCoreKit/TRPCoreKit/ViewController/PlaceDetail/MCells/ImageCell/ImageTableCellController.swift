//
//  ImageTableViewController.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/28/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//
import TRPUIKit

protocol ImageTableViewControllerDelegate: AnyObject {
    func favPressed(cell: ImageCarouselTableViewCell?)
}

final class ImageTableCellController: GenericCellController<ImageCarouselTableViewCell> {
    private let item: ImageCellModel
    public weak var delegate: ImageTableViewControllerDelegate?
   
    private var cell: ImageCarouselTableViewCell?
    private var isFavorite = false {
        didSet {
            guard let cell = cell else {return}
            if !isFavorite {
                if let image = TRPImageController().getImage(inFramework: "favorite_places_detail_empty", inApp: TRPAppearanceSettings.PoiDetail.favoritePoiImage) {
                   // cell.favoriteBtn.setImage(image, for: UIControl.State.normal)
                }
            }else {
                if let image = TRPImageController().getImage(inFramework: "favorite_places_detail", inApp: TRPAppearanceSettings.PoiDetail.selectedFavoritePoiImage) {
                  //  cell.favoriteBtn.setImage(image.maskWithColor(color: TRPColor.pink), for: UIControl.State.normal)
                }
            }
        }
    }
    
    init(imageCellModel: ImageCellModel) {
        self.item = imageCellModel
    }
    
    override func configureCell(_ cell: ImageCarouselTableViewCell) {
        NotificationCenter.default.addObserver(self, selector: #selector(favoriteNotificaion), name: .TRPPlaceFavorite, object: nil)
      //  cell.favoriteBtn.addTarget(self, action: #selector(favoriteBtnPressed), for: UIControl.Event.touchDown)
        self.cell = cell
        self.isFavorite = item.isFavorite ?? false
        setCollectionViewDataSourceDelegate(cell: cell)
    }
    
    override func didSelectCell() {
        
    }
    
    override func cellSize() -> CGFloat {
        return UIScreen.main.bounds.size.width * 3/4
    }
    
    @objc func favoriteNotificaion(_ notification:Notification) {
        if let userInfo = notification.userInfo, let data = userInfo["object"] as? Bool{
            self.isFavorite = data
            
        }
    }
    
    deinit {
        print("Notification kapatıldı")
        NotificationCenter.default.removeObserver(self)
    }
    
}

//MARK: Calculations
extension ImageTableCellController{
    
    func setCollectionViewDataSourceDelegate(cell: ImageCarouselTableViewCell) {
        /*cell.cellImages = item.images
        cell.collectionView?.delegate = cell
        cell.collectionView?.dataSource = cell
        cell.collectionView?.reloadData()
        cell.setNumberOfPages(item.images.count) */
    }
    
}

//MARK: Actions
extension ImageTableCellController{
    @objc func favoriteBtnPressed() {
        self.delegate?.favPressed(cell: self.cell)
    }
}
