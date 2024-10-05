//
//  CustomPagingOverviewCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 15.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Parchment
import UIKit
struct CustomOverviewPagingItem: PagingItem, Hashable, Comparable {
    static func < (lhs: CustomOverviewPagingItem, rhs: CustomOverviewPagingItem) -> Bool {
        return lhs.date < rhs.date
    }
    
    let title: String
    let date: String

    init(title: String, date: String) {
        self.title = title
        self.date = date
    }
}
class CustomPagingOverviewCell: PagingCell {
    
    private var options: PagingOptions?
    
    lazy var titleLabel: UILabel = {
        let dateLabel = UILabel(frame: .zero)
        dateLabel.font = trpTheme.font.header2
        dateLabel.textAlignment = .center
        return dateLabel
    }()

    lazy var dateLabel: UILabel = {
        let dateLabel = UILabel(frame: .zero)
        dateLabel.font = trpTheme.font.body3
        dateLabel.textAlignment = .center
        dateLabel.textColor = UIColor.lightGray
        return dateLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        titleLabel.frame = CGRect(
            x: 0,
            y: insets.top,
            width: contentView.bounds.width,
            height: 24
        )
        dateLabel.frame = CGRect(
            x: 0,
            y: 26,
            width: contentView.bounds.width,
            height: 20
        )

    }

    fileprivate func configure() {
        dateLabel.backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(dateLabel)
    }

    fileprivate func updateSelectedState(selected: Bool) {
        guard let options = options else { return }
        if selected {
            titleLabel.textColor = options.selectedTextColor
        } else {
            titleLabel.textColor = options.textColor
        }
    }

    override func setPagingItem(_ pagingItem: PagingItem, selected: Bool, options: PagingOptions) {
        self.options = options
        
        let item = pagingItem as! CustomOverviewPagingItem
        titleLabel.text = item.title
        dateLabel.text = item.date
        updateSelectedState(selected: selected)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
       
    }
}
