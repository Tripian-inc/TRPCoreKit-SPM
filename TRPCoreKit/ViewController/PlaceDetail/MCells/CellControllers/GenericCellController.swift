//
//  GenericCellController.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/16/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

public typealias TableCellController = CellController<UITableView>

class GenericCellController<T: ReusableCell> : CellController<T.CellHolder> {
    final let width = UIScreen.main.bounds.width * 0.83
    
    public final override class var cellClass: AnyClass {
        return T.self
    }
    
    public final override func configureCell(_ cell: T.CellHolder.CellType) {
        let cell = cell as! T
        configureCell(cell)
    }
    
    public final func currentCell() -> T? {
        return innerCurrentCell() as? T
    }
    
    public final override func willDisplayCell(_ cell: T.CellHolder.CellType) {
        let cell = cell as! T
        willDisplayCell(cell)
    }
    
    public final override func didEndDisplayingCell(_ cell: T.CellHolder.CellType) {
        let cell = cell as! T
        didEndDisplayingCell(cell)
    }
    
    func configureCell(_ cell: T) {}
    
    func willDisplayCell(_ cell: T) {}
    
    func didEndDisplayingCell(_ cell: T) {}
    
    override func cellSize() -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func estimatedCellSize(reusableCellHolder: T) -> CGFloat { return UITableView.automaticDimension}
    
    func getLinesArrayOfString(in label: UILabel) -> [String] {
        
        /// An empty string's array
        var linesArray = [String]()
        
        guard let text = label.text, let font = label.font else {return linesArray}
        
        let rect = UIScreen.main.bounds.width * 0.64
        
        let myFont: CTFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        let attStr = NSMutableAttributedString(string: text)
        attStr.addAttribute(kCTFontAttributeName as NSAttributedString.Key, value: myFont, range: NSRange(location: 0, length: attStr.length))
        
        let frameSetter: CTFramesetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
        let path: CGMutablePath = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: rect, height: CGFloat.greatestFiniteMagnitude), transform: .identity)
        
        let frame: CTFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        guard let lines = CTFrameGetLines(frame) as? [Any] else {return linesArray}
        
        for line in lines {
            let lineRef = line as! CTLine
            let lineRange: CFRange = CTLineGetStringRange(lineRef)
            let range = NSRange(location: lineRange.location, length: lineRange.length)
            let lineString: String = (text as NSString).substring(with: range)
            linesArray.append(lineString)
        }
        return linesArray
    }
    
    //To calculate height for label based on text size and width
    func heightForView(text:String, font:UIFont, width: CGFloat? = nil) -> CGFloat {
        var _widht = self.width
        if width != nil {
            _widht = width!
        }
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: _widht, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
}
