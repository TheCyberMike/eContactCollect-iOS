//
//  AddtlFieldRows.swift
//  Eureka
//
//  Created by Yo on 12/12/18.
//  Copyright © 2018 Xmartlabs. All rights reserved.
//

import Foundation

/// A String valued row where the user can enter an alphanumeric value; allows a-z, A-Z, 0-9, including space
public final class AlphanumericRow: _AlphanumericRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A String valued row where the user can enter a alphanumeric postal code: allows A-Z, 0-9, including space
public final class PostalCodeAlphaRow: _PostalCodeAlphaRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A String valued row where the user can enter digits 0-9, including space
public final class DigitsRow: _DigitsRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _AlphanumericRow: FieldRow<AlphanumericCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _PostalCodeAlphaRow: FieldRow<PostalCodeAlphaCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _DigitsRow: FieldRow<DigitsCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

open class AlphanumericCell: _FieldCell<String>, CellType {
    
    private let invalidChars:CharacterSet = CharacterSet(charactersIn:"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 ").inverted
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func setup() {
        super.setup()
        textField.keyboardType = .namePhonePad
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.delegate = self
    }
    
    open override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Attempt to find the range of invalid characters in the input string. This returns an optional if not nil then invalid char is present.
        let testRange = string.rangeOfCharacter(from: invalidChars)
        if testRange != nil { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString:string )
    }
}

open class PostalCodeAlphaCell: _FieldCell<String>, CellType {
    
    private let invalidChars:CharacterSet = CharacterSet(charactersIn:"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 ").inverted
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func setup() {
        super.setup()
        textField.keyboardType = .namePhonePad
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .allCharacters
        textField.delegate = self
        if #available(iOS 10,*) {
            textField.textContentType = .postalCode
        }
    }
    
    open override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Attempt to find the range of invalid characters in the input string. This returns an optional if not nil then invalid char is present.
        let testRange = string.rangeOfCharacter(from: invalidChars)
        if testRange != nil { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString:string )
    }
    
    @objc open override func textFieldDidChange(_ textField: UITextField) {
        textField.text = textField.text?.uppercased()
        super.textFieldDidChange(textField)
    }
}

open class DigitsCell: _FieldCell<String>, CellType {
    
    private let invalidChars:CharacterSet = CharacterSet(charactersIn:"1234567890 ").inverted
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func setup() {
        super.setup()
        textField.keyboardType = .numberPad
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.delegate = self
    }
    
    open override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Attempt to find the range of invalid characters in the input string. This returns an optional if not nil then invalid char is present.
        let testRange = string.rangeOfCharacter(from: invalidChars)
        if testRange != nil { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString:string )
    }
}
