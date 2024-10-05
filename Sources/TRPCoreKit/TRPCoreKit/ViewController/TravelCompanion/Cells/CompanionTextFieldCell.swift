//
//  CompanionTextFieldCell.swift
//  TRPAddTravelCompanionsKit
//
//  Created by Evren Yaşar on 25.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit
//MARK: TableViewCell
public protocol CompanionTextFieldCellProtocol: AnyObject{
    func setTextFieldVal(text: String, val: Int)
    func saveChanges()
}

public class CompanionTextFieldCell: UITableViewCell {
    
    weak var cellDelegate: CompanionTextFieldCellProtocol?
    @IBOutlet weak var textField: TRPTextFieldNew!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
    }
    
    @IBAction func textFieldDidChange(_ sender: Any) {
        if let text = textField.text{
            self.cellDelegate?.setTextFieldVal(text: text, val: textField.tag)
        }
    }
}
//MARK: - TextFieldDelegate
extension CompanionTextFieldCell: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        return false
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return textField.tag == 1 ? true : count <= 2
    }
}
