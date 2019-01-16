//
//  ColorSwatchView.swift
//  EurekaColorPicker
//
//  Created by Mark Alldritt on 2017-04-22.
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

extension UIColor {
    public func rgba() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let components = self.cgColor.components
        let numberOfComponents = self.cgColor.numberOfComponents
        
        switch numberOfComponents {
        case 4:
            return (components![0], components![1], components![2], components![3])
        case 2:
            return (components![0], components![0], components![0], components![1])
        default:
            // FIXME: Fallback to black
            return (0, 0, 0, 1)
        }
    }
    
    public func blackOrWhiteContrastingColor() -> UIColor {
        let rgbaT = rgba()
        let value = 1 - ((0.299 * rgbaT.r) + (0.587 * rgbaT.g) + (0.114 * rgbaT.b));
        return value < 0.65 ? UIColor.black : UIColor.white
    }
    
    public func blackOrGrayContrastingColor() -> UIColor {
        let rgbaT = rgba()
        let value = 1 - ((0.299 * rgbaT.r) + (0.587 * rgbaT.g) + (0.114 * rgbaT.b));
        return value < 0.75 ? UIColor.black : UIColor.lightGray
    }
}


class ColorSwatchView : UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
    var isCircular = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var color : UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    var isSelected = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        if let color = color {
            let swatchRect = bounds.insetBy(dx: 1.0, dy: 1.0)
            let path = isCircular ? UIBezierPath(ovalIn: swatchRect) : UIBezierPath(roundedRect: swatchRect, cornerRadius: CGFloat(Int(swatchRect.width * 0.2)))
            
            color.setFill()
            path.fill()
            
            if isSelected {
                let frameColor = color.blackOrGrayContrastingColor()
                let selectRect = bounds.insetBy(dx: 2.0, dy: 2.0)
                let selectPath = isCircular ? UIBezierPath(ovalIn: selectRect) : UIBezierPath(roundedRect: selectRect, cornerRadius: CGFloat(Int(selectRect.width * 0.2)))
                
                frameColor.setStroke()
                selectPath.lineWidth = 3.0
                selectPath.stroke()
                
                if frameColor == UIColor.white && false {
                    let outlinePath = isCircular ? UIBezierPath(ovalIn: bounds) : UIBezierPath(roundedRect: bounds, cornerRadius: CGFloat(Int(bounds.width * 0.2)))
                    UIColor.black.setStroke()
                    outlinePath.lineWidth = 0.5
                    outlinePath.stroke()
                }
            }
        }
    }
}
