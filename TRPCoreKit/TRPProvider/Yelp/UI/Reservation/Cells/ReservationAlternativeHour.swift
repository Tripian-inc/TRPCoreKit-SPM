//
//  ReservationAlternativeHour.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 7.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit

class ReservationAlternativeHour: ReservationBaseCell {
    
    
    var alternativeSelectedHandler: ((_ hour: String) -> Void)?
    var selectedHour: String?
    var selectedCellIndex: IndexPath?
    var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 70, height: 30)
        flowLayout.minimumLineSpacing = 10.0
        flowLayout.minimumInteritemSpacing = 5.0
        let collection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collection.backgroundColor = UIColor.white
        return collection
    }()
    
    private(set) var hours = [String]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override func setupCustom(stack: UIStackView) {
        stack.addArrangedSubview(collectionView)
        setupCollectionView()
    }
    
    public func updateHours(_ hours: [String]) {
        self.hours = hours
    }
    
    public func setSelectedHour(_ hour: String) {
        self.selectedHour = hour
    }
    
    
    func setSelectedCellCenter() {
        for (row, _) in hours.enumerated() {
            let time = hours[row]
            if let selectedHour = selectedHour, time == selectedHour {
                let indexPath = IndexPath(row: row, section: 0)
                _ = collectionView.cellForItem(at: indexPath)
                //cell.isSelected = true
                collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
            }
        }
    }
    
    
    
}

extension ReservationAlternativeHour: UICollectionViewDataSource, UICollectionViewDelegate {
    
    private func setupCollectionView() {
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.register(ReservationAlternatviceHourCollectionCell.self, forCellWithReuseIdentifier: "collectionCell")
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        self.collectionView.widthAnchor.constraint(equalTo: horizontalStackView.widthAnchor ).isActive = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hours.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! ReservationAlternatviceHourCollectionCell
        let time = hours[indexPath.row]
        
        if let selectedHour = selectedHour, time == selectedHour {
            //cell.backView.backgroundColor = UIColor.darkGray
            //cell.timeLabel.textColor = UIColor.black
            //selectedCellIndex = indexPath
        }else {
            //cell.backView.backgroundColor = UIColor.blue
            //cell.timeLabel.textColor = UIColor.white
        }
        cell.timeLabel.text = time
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedHour = hours[indexPath.row]
        alternativeSelectedHandler?(selectedHour)
    }
}
