//
//  InlineColorPickerRow.swift
//  ColorPicker
//
//  Created by Mark Alldritt on 2018-01-07.
//  Copyright © 2018 Late Night Software Ltd. All rights reserved.
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


public final class InlineColorPickerCell : Cell<UIColor>, CellType {
    
    var swatchView : ColorSwatchView
    var isCircular = false {
        didSet {
            swatchView.isCircular = isCircular
        }
    }
    
    private var dynamicConstraints = [NSLayoutConstraint]()
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        swatchView = ColorSwatchView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        swatchView.translatesAutoresizingMaskIntoConstraints = false
        swatchView.isSelected = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
    }
    
    public override func setup() {
        super.setup()
        
        swatchView.color = row.value
        selectionStyle = .default
        accessoryView = swatchView
    }
}

// MARK: InlineColorPickerRow
public class _InlineColorPickerRow: Row<InlineColorPickerCell> {
    
    open var isCircular = false {
        didSet {
            guard let _ = section?.form else { return }
            updateCell()
        }
    }
    
    open var showsPaletteNames = true {
        didSet {
            guard let _ = section?.form else { return }
            updateCell()
        }
    }
    
    open var palettes : [ColorPalette] = [iOS().palette,
                                          Solarised().palette,
                                          WP8().palette,
                                          Flat().palette,
                                          Material().palette,
                                          Metro().palette]
    
    override open func updateCell() {
        super.updateCell()
        cell.isCircular = isCircular
        cell.swatchView.color = value
        cell.selectionStyle = isDisabled ? .none : .default
    }
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

public final class InlineColorPickerRow: _InlineColorPickerRow, RowType, InlineRowType {
    public func setupInlineRow(_ inlineRow: ColorPickerRow) {
        inlineRow.value = value
        inlineRow.isCircular = isCircular
        inlineRow.showsCurrentSwatch = false
        inlineRow.cell.palettes = palettes
        inlineRow.showsPaletteNames = showsPaletteNames
        
        if value != nil, let indexPath = inlineRow.cell.indexPath(forColor: value!) {
            inlineRow.cell.colorsView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        }
    }
    
    public typealias InlineRow = ColorPickerRow
    
    required public init(tag: String?) {
        super.init(tag: tag)
        onExpandInlineRow { cell, row, _ in
            row.deselect()
        }
        onCollapseInlineRow { cell, row, _ in
            row.deselect()
        }
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            toggleInlineRow()
            
            if isExpanded {
                if value != nil, let indexPath = inlineRow?.cell.indexPath(forColor: value!) {
                    inlineRow?.cell.colorsView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                }
            }
        }
    }
}
