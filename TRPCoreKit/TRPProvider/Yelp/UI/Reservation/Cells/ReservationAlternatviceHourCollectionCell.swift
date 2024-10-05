//
//  ReservationAlternatviceHourCollectionCell.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 8.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit

class ReservationAlternatviceHourCollectionCell: UICollectionViewCell {
    
    var backView: UIView = {
        var view = UIView()
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = TRPColor.pink
        return view
    }()
    
    var timeLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor.white
        lbl.text = "07:00"
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.isHidden = true
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(){
        
        addSubview(backView)
        backView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        backView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        addSubview(timeLabel)
        timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        backgroundColor = UIColor.white
    }
}

