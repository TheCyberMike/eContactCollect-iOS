//
//  ATHMultiSelectionControlSegmentButton.swift
//  Pods
//
//  Created by Athanasios Theodoridis on 06/06/16.
//  https://github.com/attheodo/ATHMultiSelectionSegmentedControl
//
/*
 Copyright (c) 2016 attheodo <at@atworks.gr>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */
//
import Foundation
import UIKit

import QuartzCore

internal class ATHMultiSelectionControlSegmentButton: UIButton {

    // MARK: - Private Properties
    fileprivate var _isButtonSelected: Bool = false
    fileprivate var _isButtonEnabled: Bool = true
    
    // MARK: - Public Properties
    /// Whether the button is currently in a selected state
    internal var isButtonSelected: Bool {
        return _isButtonSelected
    }
    /// Whether the button
    internal var isButtonEnabled: Bool {
        return _isButtonEnabled
    }
    /// The color of the text when selected
    internal var titleColorSelected: UIColor?       // !!! MMM
    override var isHighlighted: Bool {
        
        didSet {
            
            // ignore highlighting if button is disabled
            if !_isButtonEnabled { return }
            
            if isHighlighted {
                backgroundColor = tintColor.withAlphaComponent(0.2)
            } else {
                
                if _isButtonSelected {
                    backgroundColor = tintColor
                } else {
                    backgroundColor = UIColor.clear
                }
                
            }
            
        }
    }
    
    // MARK: - Initialisers
    override init(frame: CGRect) {
        super.init(frame: frame)
        _configureButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Private Methods
    /**
     Configures the initial style of the button
     - Sets title color
     - Clears background color
     - Adds a border of 0.5 px
     */
    fileprivate func _configureButton() {
        
        setTitleColor(tintColor, for: .normal)
        
        backgroundColor = UIColor.clear
        
        layer.borderWidth = 0.5
        layer.borderColor = tintColor.cgColor
        
    }
    
    /**
     Styles the button as selected
     */
    fileprivate func _setSelectedState() {
        
        layer.borderColor = self.titleColorSelected?.cgColor    // !!! MMM
        let t = tintColor
        backgroundColor = tintColor
        setTitleColor(self.titleColorSelected ?? UIColor.white, for: .normal)   // !!! MMM
        
    }
    
    /**
     Styles the button as deselected
     */
    fileprivate func _setDeselectedState() {
        
        backgroundColor = UIColor.clear
        setTitleColor(tintColor, for: .normal)
        layer.borderColor = tintColor.cgColor
        
    }
    
    // MARK: - Public Methods
    /**
     Toggles the receiver's selection state and styles it appropriately
     */
    internal func setButtonSelected(_ isSelected: Bool) {
        
        _isButtonSelected = isSelected
        _isButtonSelected ? _setSelectedState() : _setDeselectedState()
        
    }
    
    /**
     Toggles the receiver's enabled/disabled state and styles it appropriately
     */
    internal func setButtonEnabled(_ isEnabled: Bool) {
        
        if isEnabled {
            _setDeselectedState()
        } else {
            setTitleColor(UIColor.gray, for: .normal)
            backgroundColor = UIColor.clear
        }
        
        _isButtonEnabled = isEnabled
        
    }
    
}
