//
//  ColorSwatchCell.swift
//  EurekaColorPicker
//
//  Created by Mark Alldritt on 2016-11-20.
//  Copyright © 2017 Late Night Software Ltd. All rights reserved.
//
//  https://github.com/EurekaCommunity/ColorPickerRow
/*
 The MIT License (MIT)
 
 Copyright (c) 2017 Mark Alldritt and Late Night Software Ltd.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

class ColorSwatchCell: UICollectionViewCell {
    var swatchView : ColorSwatchView
    
    override init(frame: CGRect) {
        swatchView = ColorSwatchView(frame: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height))
        
        super.init(frame: frame)
        
        contentView.addSubview(swatchView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var colorSpec : ColorSpec? {
        didSet {
            swatchView.color = colorSpec?.color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            swatchView.isSelected = isSelected
        }
    }
}