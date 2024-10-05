//
//  DescriptionTableViewCellController.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/17/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit
/*
final class DescriptionTableViewCellController: GenericCellController<DescriptionTableViewCell> {
    private let item: DescriptionCellModel
    
    private var wholeString: String?
    private var labelLines:Int?
    
    private var cell: DescriptionTableViewCell?
    private var cellHeight = UITableView.automaticDimension
    
    private var isDescinMinHeight: Bool = true
    
    init(descriptionCellModel: DescriptionCellModel) {
        self.item = descriptionCellModel
    }
    
    override func configureCell(_ cell: DescriptionTableViewCell) {
        self.cell = cell
        wholeString = item.title
        cell.descLabel.text = wholeString
        self.labelLines = countLabelLines(label: cell.descLabel)
        setDescMinTitle(cell.descLabel, item.title)
    }
    
    override func didSelectCell() {
        setDescHeight()
    }
    
    override func updateCell(tableView: UITableView) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func cellSize() -> CGFloat {
        return cellHeight
    }
    
}

//MARK: Actions
extension DescriptionTableViewCellController{
    
    private func setDescHeight(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: { [weak self] in
            guard let strongSelf = self else {return}
            if strongSelf.isDescinMinHeight{
                if strongSelf.labelLines ?? 0 > 2{
                    strongSelf.maxifyTitle()
                }
            }else{
                guard let cell = strongSelf.cell, let wholeString = strongSelf.wholeString else {return}
                strongSelf.setDescMinTitle(cell.descLabel, wholeString)
            }
            strongSelf.isDescinMinHeight.toggle()
            }, completion: nil)
    }
    
    private func setDescMinTitle(_ descLabel: UILabel, _ wholeTitle: String){
        if labelLines == 1 {
            cellHeight = 40
        }else{
            cellHeight = 60
        }
        descLabel.text = wholeTitle
        setSize(descLabel, wholeTitle)
        guard let cell = cell else {return}
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }
    
    private func setSize(_ descLabel: UILabel, _ wholeTitle: String){
        if labelLines ?? 0 < 3{
            descLabel.text = wholeTitle
        }else{
            //More ... koymak icin
            var lines: [String] = getLinesArrayOfString(in: descLabel)
            
            if lines.count > 2{
                let strMore = " more...   "
                lines[1] = String(lines[1]) + strMore
                let cuttedStr = lines[0] + lines[1]
                let range = (cuttedStr as NSString).range(of: strMore)
                let attribute = NSMutableAttributedString.init(string: cuttedStr)
                attribute.addAttribute(NSAttributedString.Key.foregroundColor, value: TRPColor.blue , range: range)
                descLabel.attributedText = attribute
            }
        }
    }
    
    private func maxifyTitle(){
        guard let cell = cell else {return}
        cell.descLabel.numberOfLines = 0
        cell.descLabel.text = wholeString
        cellHeight = heightForView(text: wholeString ?? "", font: UIFont.systemFont(ofSize: 16))
    }
    
    //MARK: - Functions
    func countLabelLines(label: UILabel?) -> Int {
        guard let label = label else {return 0}
        guard let myText = label.text else {return 0}
        let rect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = myText.boundingRect(with: rect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [NSAttributedString.Key.font: label.font ?? UIFont.systemFontSize], context: nil)
        
        return Int(ceil(CGFloat(labelSize.height) / label.font.lineHeight))
    }
    
}
*/
