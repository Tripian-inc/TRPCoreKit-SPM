//
//  MyTripTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 16.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit

@objc(SPMMyTripTableViewCell)
class MyTripTableViewCell: UITableViewCell {
    @IBOutlet weak var editTripBtn: UIButton!
    @IBOutlet weak var deleteTripBtn: UIButton!
    
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var cityNameLbl: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cityImage: UIImageView!
    @IBOutlet weak var tripNameLbl: UILabel!
    
    typealias showSelectedTripMenuClick = (_ status:Bool) -> Void
    public var isBusy = false {
        didSet {
            if isBusy {
                self.alpha = 0.7
            }else {
                self.alpha = 1
            }
        }
    }
    
    public var tripId:Int?
    private var loaded: Bool = false
    public var showSelectedTripEditHandler: showSelectedTripMenuClick?
    public var showSelectedTripDeleteHandler: showSelectedTripMenuClick?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addClearSelectedBackground()
        setupUI()
    }
    
    
    
    private func addClearSelectedBackground() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.clear
        self.selectedBackgroundView = backgroundView
    }
    
    private func setupUI() {
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: -2, height: 2)
        layer.shadowRadius = 20
//        cityImage.layer.cornerRadius = 20
//        containerView.layer.cornerRadius = 20
//        cityImage.contentMode = .scaleToFill
//        cityImage.clipsToBounds = true
        
        tripNameLbl.font = trpTheme.font.title1
        tripNameLbl.textColor = trpTheme.color.tabbarColor
        
        cityNameLbl.font = trpTheme.font.regular14
        cityNameLbl.textColor = trpTheme.color.tabbarColor
        
        dateLbl.font = trpTheme.font.title1
        dateLbl.textColor = .white
        dateLbl.backgroundColor = trpTheme.color.tripianPrimary
        
        dateLbl.roundCorners(corners: .allCorners, radius: 10)
        
        editTripBtn.addShadow(withRadius: 20)
        deleteTripBtn.addShadow(withRadius: 20)
    
        containerView.layer.shadowColor = UIColor.lightGray.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowRadius = 5
        containerView.layer.cornerRadius = 20
    }
   
    
    @IBAction func deleteBtnPressed(_ sender: Any) {
        showSelectedTripDeleteHandler?(true)
    }
    @IBAction func editBtnPressed(_ sender: Any) {
        showSelectedTripEditHandler?(true)
    }
}
