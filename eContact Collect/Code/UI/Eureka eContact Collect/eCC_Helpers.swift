//  Adapted from:
//  Section.swift
//  Eureka ( https://github.com/xmartlabs/Eureka )
//
//  Copyright (c) 2016 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

extension NSLayoutConstraint {
    /**
     Change multiplier constraint
     
     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        
        NSLayoutConstraint.deactivate([self])
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem as Any,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        self.identifier = nil
        
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}

extension UIFont {
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    public func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    public func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
    
    public func boldItalic() -> UIFont {
        return withTraits(traits: [.traitBold, .traitItalic])
    }

    private func withTraits(traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        if descriptor == nil { return self }
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }
}

extension UILayoutPriority {
    // UIControl.setContentHuggingPriority
    // the larger the number, the more likely compared to other fields it will remain its smallest instrinsic size rather than grow
    public static let hugPriTextLabel:UILayoutPriority = UILayoutPriority(rawValue: 350)
    public static let hugPriSmallField:UILayoutPriority = UILayoutPriority(rawValue: 300)
    public static let hugPriDefault:UILayoutPriority = UILayoutPriority(rawValue: 250)
    public static let hugPriStandardField:UILayoutPriority = UILayoutPriority(rawValue: 250)
    
    // UIControl.setContentCompressionResistancePriority
    // the larger the number, the less likely it will shrink to the point that it truncates content
    public static let compressPriNoCompress:UILayoutPriority = UILayoutPriority(rawValue: 1000)
    public static let compressPriLessLikely:UILayoutPriority = UILayoutPriority(rawValue: 850)
    public static let compressPriDefault:UILayoutPriority = UILayoutPriority(rawValue: 750)
    public static let compressPriMoreLikely:UILayoutPriority = UILayoutPriority(rawValue: 650)
    
    // NSLayoutConstraint UIControl.width priority assuming UIControl.setContentCompressionResistancePriority = default
    public static let widthPriTextLabel:UILayoutPriority = UILayoutPriority(rawValue: 850)
    public static let widthPriSmallField:UILayoutPriority = UILayoutPriority(rawValue: 750)
    public static let widthPriStandardField:UILayoutPriority = UILayoutPriority(rawValue: 750)
}

public struct CodePair {
    public var codeString:String
    public var valueString:String
    
    public init(_ code:String, _ value:String) {
        self.codeString = code
        self.valueString = value
    }
    
    public mutating func setValue(newValue:String) {
        self.valueString = newValue
    }
    
    public static func codeExists(pairs:[CodePair], givenCode:String) -> Bool {
        for pair in pairs {
            if givenCode == pair.codeString { return true }
        }
        return false
    }
    public static func findCode(pairs:[CodePair], givenValue:String) -> String? {
        for pair in pairs {
            if givenValue == pair.valueString { return pair.codeString }
        }
        return nil
    }
    public static func findValue(pairs:[CodePair], givenCode:String) -> String? {
        for pair in pairs {
            if givenCode == pair.codeString { return pair.valueString }
        }
        return nil
    }
}

extension Form {
    /**
     *  This method detects whether a partial tag already exists.
     */
    public func rowBy(tagLeading: String) -> BaseRow? {
        for (tag,row) in rowsByTag {
            if tag.starts(with: tagLeading) {
                return row
            }
        }
        return nil
    }
}

extension Section /* Helpers */ {
    
    /**
     *  This method inserts a row after another row.
     *  It is useful if you want to insert a row after a row that is currently hidden. Otherwise use `insert(at: Int)`.
     *  It throws an error if the old row is not in this section.
     */
    public func insert(row newRow: BaseRow, before previousRow: BaseRow) throws {
        guard let rowIndex = (kvoWrapper._allRows as [BaseRow]).firstIndex(of: previousRow) else {
            throw EurekaError.rowNotInSection(row: previousRow)
        }
        kvoWrapper._allRows.insert(newRow, at: rowIndex )
        show(row: newRow)
        newRow.wasAddedTo(section: self)
    }
    
}

public final class PhoneRowExt: _PhoneRow, RowType {
    public var withFormatRegion:String? {
        didSet {
            if (withFormatRegion ?? "").isEmpty {
                self.formatter = nil
            } else if withFormatRegion! == "-" {
                self.formatter = nil
            } else {
                self.formatter = PhoneFormatter_ECC(forRegion: withFormatRegion!)
            }
        }
    }
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public struct RulePhone_ECC<T: Equatable>: RuleTypeExt {
    
    public init(id: String? = nil) {
        self.id = id
    }
    
    public var acceptableRegions:[String] = ["NANP","US","CA","MX","UK","GB"]
    public var id: String?
    public var validationError:ValidationError = ValidationError(msg: NSLocalizedString("Phone number is invalid", comment:"") + " (NANP)")
    
    public func isValid(value: T?) -> ValidationError? {
        return ValidationError(msg: "$$$APP INTERNAL ERROR!!")
    }
    
    public func isValidExt(row:BaseRow, value: T?) -> ValidationError? {
        let phoneRow = row as! PhoneRowExt
        if (phoneRow.withFormatRegion ?? "").isEmpty { return nil }
        if phoneRow.withFormatRegion! == "-" { return nil }
        
        if let valueString = value as? String {
            var valid:Bool
            switch phoneRow.withFormatRegion! {
            case "NANP":
                valid = RulePhone_ECC.testIsValid_NANP(phoneString: valueString)
                break
            case "US":
                valid = RulePhone_ECC.testIsValid_NANP(phoneString: valueString)
                break
            case "CA":
                valid = RulePhone_ECC.testIsValid_NANP(phoneString: valueString)
                break
            case "UK":
                valid = RulePhone_ECC.testIsValid_UK(phoneString: valueString)
                break
            case "GB":
                valid = RulePhone_ECC.testIsValid_UK(phoneString: valueString)
                break
            case "MX":
                valid = RulePhone_ECC.testIsValid_MX(phoneString: valueString)
                break
            default:
                valid = true
                break
            }
            if !valid { return validationError }
        }
        return nil
    }
    
    public static func testIsValid(formatRegion:String?, phoneString:String) -> Bool {
        if (formatRegion ?? "").isEmpty { return true }
        switch formatRegion {
        case "-":
            return true
        case "NANP":
            return RulePhone_ECC.testIsValid_NANP(phoneString: phoneString)
        case "US":
            return RulePhone_ECC.testIsValid_NANP(phoneString: phoneString)
        case "CA":
            return RulePhone_ECC.testIsValid_NANP(phoneString: phoneString)
        case "UK":
            return RulePhone_ECC.testIsValid_UK(phoneString: phoneString)
        case "GB":
            return RulePhone_ECC.testIsValid_UK(phoneString: phoneString)
        case "MX":
            return RulePhone_ECC.testIsValid_MX(phoneString: phoneString)
        default:
            return true
        }
    }
    
    private static func testIsValid_NANP(phoneString:String) -> Bool {
        if phoneString.isEmpty { return true }
        let digitChars:CharacterSet = CharacterSet(charactersIn:"1234567890")
        let phoneChars:CharacterSet = CharacterSet(charactersIn:"1234567890#*()- ")
        
        if phoneString.rangeOfCharacter(from: digitChars.inverted) == nil {
            // has only digits
            if phoneString.count == 7 || phoneString.count == 10 {
                // phone numbers are 7 digits local without the area code, or 10 digits with the area code;
                // in many areas a full 10 digits is manditory
                return true
            }
            
        } else if phoneString.rangeOfCharacter(from: phoneChars.inverted) == nil {
            // has acceptable phone characters and is likely formatted
            // ?? FUTURE validate the formatted phone#
            return true
            
        } else {
            // has non-phone characters
        }
        return false
    }
    
    private static func testIsValid_UK(phoneString:String) -> Bool {
        if phoneString.isEmpty { return true }
        let digitChars:CharacterSet = CharacterSet(charactersIn:"1234567890")
        let phoneChars:CharacterSet = CharacterSet(charactersIn:"1234567890#*() ")  // dash is not normally used in formatted phone numbers
        
        if phoneString.rangeOfCharacter(from: digitChars.inverted) == nil {
            // has only digits
            if phoneString.prefix(1) == "0" {
                // a NSN has 10 or 11 digits including the leading zero
                if phoneString.count == 10 || phoneString.count == 11 {
                    return true
                }
            } else {
                // non-NSN local phone#s can vary from 3 to 9 digits
                if phoneString.count >= 3 && phoneString.count <= 10 {
                    return true
                }
            }
            
        } else if phoneString.rangeOfCharacter(from: phoneChars.inverted) == nil {
            // has acceptable phone characters and is likely formatted
            // ?? FUTURE validate the formatted phone#
            return true
            
        } else {
            // has non-phone characters
        }
        return false
    }
    
    private static func testIsValid_MX(phoneString:String) -> Bool {
        if phoneString.isEmpty { return true }
        let digitChars:CharacterSet = CharacterSet(charactersIn:"1234567890")
        let phoneChars:CharacterSet = CharacterSet(charactersIn:"1234567890#*()- ")
        
        if phoneString.rangeOfCharacter(from: digitChars.inverted) == nil {
            // has only digits
            if phoneString.count == 10 {
                // as of 2019 Aug 3; all regular phone#s include the area code and are 10 digits total; no more local-only numbers
                return true
            }
            
        } else if phoneString.rangeOfCharacter(from: phoneChars.inverted) == nil {
            // has acceptable phone characters and is likely formatted
            // ?? FUTURE validate the formatted phone#
            return true
            
        } else {
            // has non-phone characters
        }
        return false
    }
}

// used for ComposedLayout below
public struct ComposedLayoutControl {
    public var controlName:String
    public var control:UIView
    public var isFixedWidthOrLess:Bool = false
    
    internal var _noTrail:Bool = false          // this will be computed upon each call to generateDynamicConstraints()
    
    // 'controlName' as would be used in "views" for creating dynamic constraints;
    // 'isFixedWidthOrLess' is for controls that have a constraint that fixes their width, or limits their with (.lessThanOrEqual)
    init (controlName:String, control:UIView, isFixedWidthOrLess:Bool=false, _noTrail:Bool=false) {
        self.controlName = controlName
        self.control = control
        self.isFixedWidthOrLess = isFixedWidthOrLess
        self._noTrail = _noTrail
    }
}

// store a layout for use in dynamic Row layouts with dynamic constraints generation
public class ComposedLayout: Equatable {
    public var horiLeadingPad:Int = -1      // -1 indicate default pad aka "H:|-[...]..."
    public var horiInterItemPad:Int = 5     // -1 indicate default pad aka "H:|...[...]-[...]..."
    public var horiTrailingPad:Int = -1     // -1 indicate default pad aka "H:...[...]-|"; -2 indicates no pad aka "H:...[...]"
    public var vertTopPad:Int = -1          // -1 indicate default pad aka "V:|-[...]..."
    public var vertInterItemPad:Int = 5     // -1 indicate default pad aka "V:|...[...]-[...]..."
    public var vertBottomPad:Int = -1       // -1 indicate default pad aka "V:...[...]-|"; -2 indicates no pad aka "V:...[...]"
    public var mCellHasManualHeight:Bool = false

    public var _horiLeadingPad:CGFloat = 8.0
    public var _horiInterItemPad:CGFloat = 5.0
    public var _horiTrailingPad:CGFloat = 8.0
    public var _vertTopPad:CGFloat = 8.0
    public var _vertInterItemPad:CGFloat = 5.0
    public var _vertBottomPad:CGFloat = 8.0

    private var mCTAG:String = "EuHCL"
    private weak var mContentView:UIView? = nil
    private weak var mRow:BaseRow? = nil
    private var mMovedToFirst:Bool = false
    private var mtitleAreaRatioWidthToMove:CGFloat = 0.0
    private var mTextTitleFirstControl:ComposedLayoutControl? = nil
    private var mImageTitleFirstControl:ComposedLayoutControl? = nil
    private var mComposedLayoutArray:[[ComposedLayoutControl]] {
        get {
            if mMovedToFirst { return _mMovedComposedLayoutArray }
            else { return _mUnmovedComposedLayoutArray }
        }
    }
    private var _mUnmovedComposedLayoutArray:[[ComposedLayoutControl]] = []
    private var _mMovedComposedLayoutArray:[[ComposedLayoutControl]] = []
    private var mCurrentLine:[ComposedLayoutControl] = []
    
    // initializaer; 'contentView' and eureka 'row' are needed;
    // optionally set 'titleAreaRatioWidthToMove' to allow the ComposedLayout mechanism to move imageTitle and textTitle to a new first Line
    // if the imageTitle + textTitle is larger than the percentage of TableViewCell width than specified, or if the size of the fields column
    // computes to be larger than the remainder percentage of TableViewCell width;
    // note this is a ratio between 0.0 and 1.0; set to zero to disable;
    // if set to 1.0 then effectively the will always be auto-moved so it would be better to just place them as the first Line
    init(contentView:UIView?, row:BaseRow?, cellHasManualHeight:Bool, titleAreaRatioWidthToMove:CGFloat=0.0) {
        self.mContentView = contentView
        self.mRow = row
        self.mCellHasManualHeight = cellHasManualHeight
        if titleAreaRatioWidthToMove <= 0.0 { self.mtitleAreaRatioWidthToMove = 0.0 }
        else if titleAreaRatioWidthToMove >= 1.0 { self.mtitleAreaRatioWidthToMove = 1.0 }
        else { self.mtitleAreaRatioWidthToMove = titleAreaRatioWidthToMove }
    }
    
    // compare two instances of ComposedLayout for equality of controlNames and layout structure as will be shown;
    // thus it accounts for auto-title movement changes
    public static func == (lhs: ComposedLayout, rhs: ComposedLayout) -> Bool {
        if (lhs.mImageTitleFirstControl?.controlName ?? "") != (rhs.mImageTitleFirstControl?.controlName ?? "") { return false }
        if (lhs.mTextTitleFirstControl?.controlName ?? "") != (rhs.mTextTitleFirstControl?.controlName ?? "") { return false }
        if lhs.mComposedLayoutArray.count != rhs.mComposedLayoutArray.count { return false }
        if lhs.mComposedLayoutArray.count > 0 {
            for line in 0...lhs.mComposedLayoutArray.count - 1 {
                if lhs.mComposedLayoutArray[line].count != rhs.mComposedLayoutArray[line].count { return false }
                if lhs.mComposedLayoutArray[line].count > 0 {
                    for ctrl in 0...lhs.mComposedLayoutArray[line].count - 1 {
                        if lhs.mComposedLayoutArray[line][ctrl].controlName != rhs.mComposedLayoutArray[line][ctrl].controlName { return false }
                    }
                }
            }
        }
        return true
    }
    
    // clear out the Composed Layout so it will deinit()
    public func clear() {
        self.removeAll()
        self.mContentView = nil
        self.mRow = nil
        self.mTextTitleFirstControl = nil
        self.mImageTitleFirstControl = nil
    }
    
    // remove all ComposedLayout content; eliminates Unmoved and Moved; however the object can be re-used
    public func removeAll() {
        self.mImageTitleFirstControl = nil
        self.mTextTitleFirstControl = nil
        self._mUnmovedComposedLayoutArray = []
        self._mMovedComposedLayoutArray = []
        self.mCurrentLine = []
        self.mMovedToFirst = false
    }
    
    // is the layout empty including title fields?  this needs to be the base unmoved composed layout array
    public func isEmpty() -> Bool {
        if self._mUnmovedComposedLayoutArray.count == 0 && self.mImageTitleFirstControl == nil && self.mTextTitleFirstControl == nil { return true }
        return false
    }
    
    // move to the next working "current" Line (which appends the entire last Line to the composition
    public func moveToNextLine() {
        if self.mCurrentLine.count > 0 { self._mUnmovedComposedLayoutArray.append(self.mCurrentLine) }
        self.mCurrentLine = []
    }
    
    // must be called when entirely done with the composition process (when all addControlToCurrentLine are complete)
    public func done() {
        if self.mCurrentLine.count > 0 { self._mUnmovedComposedLayoutArray.append(self.mCurrentLine) }
        self.mCurrentLine = []
    }
    
    // get the number of Lines in the base non-moved composition
    public func nonMovedLinesCount() -> Int {
        return self._mUnmovedComposedLayoutArray.count
    }

    // These methods operate on the active layout (either Unmoved or Moved)
    // get the number of Lines in the composition
    public func linesCount() -> Int {
        return self.mComposedLayoutArray.count
    }
    
    // get the number of controls present in the working "current" Line
    public func controlsCountCurrentLine() -> Int {
        return self.mCurrentLine.count
    }
    
    // get the number of controls present in a specified Line in the composition
    public func controlsCount(inLine: Int) -> Int {
        if inLine < 0 || inLine >= self.mComposedLayoutArray.count { return -1 }
        return self.mComposedLayoutArray[inLine].count
    }
    
    // record an ImageView as the leftmost column
    public func addImageTitleFirstControl(forControl:ComposedLayoutControl) {
        self.mImageTitleFirstControl = forControl
    }
    
    // record an UILabel as the leftmost or second leftmost column
    public func addTextTitleFirstControl(forControl:ComposedLayoutControl) {
        self.mTextTitleFirstControl = forControl
    }
    
    // append a new control to the working "current" Line
    public func addControlToCurrentLine(forControl:ComposedLayoutControl) {
        self.mCurrentLine.append(forControl)
    }
    
    // for the "fields" column, compute its composed intrinsic size as it will be layed out; inter-item pads are included;
    // note that of course, every control, label, and image needs be preset with its content and placeholders
    public func getFieldsInstrinsicSize() -> CGSize {
        if self.mComposedLayoutArray.count == 0 { return CGSize.zero }
        self.getLayoutMargins()
        var maxLineWidth:CGFloat = 0.0
        var maxLineHeight:CGFloat = 0.0
        for line in 0...self.mComposedLayoutArray.count - 1 {
            if self.mComposedLayoutArray[line].count > 0 {
                var lineWidth:CGFloat = 0.0
                var lineHeight:CGFloat = 0.0
                for ctrl in 0...self.mComposedLayoutArray[line].count - 1  {
                    lineWidth = lineWidth + self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.width
                    if ctrl > 0 { lineWidth = lineWidth + self._horiInterItemPad }
                    if self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.height > lineHeight {
                        lineHeight = self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.height
                    }
                }
                if lineWidth > maxLineWidth { maxLineWidth = lineWidth }
                maxLineHeight = maxLineHeight + lineHeight
                if line > 0 { maxLineHeight = maxLineHeight + self._vertInterItemPad }
            }
        }
        return CGSize(width: maxLineWidth, height: maxLineHeight)
    }
    
    // for the Titles area, compute its theoretical intrinsic size; inter-item pads are included;
    // note that of course, every control, label, and image needs be preset with its content and placeholders
    public func getTitlesInstrinsicSize() -> CGSize {
        self.getLayoutMargins()
        var maxLineWidth:CGFloat = 0.0
        var maxLineHeight:CGFloat = 0.0
        if self.mImageTitleFirstControl != nil && !self.mMovedToFirst {
            if self.mImageTitleFirstControl!.control.intrinsicContentSize.height > maxLineHeight {
                maxLineHeight = self.mImageTitleFirstControl!.control.intrinsicContentSize.height
            }
            maxLineWidth = maxLineWidth + self.mImageTitleFirstControl!.control.intrinsicContentSize.width
        }
        if self.mTextTitleFirstControl != nil && !self.mMovedToFirst {
            let label:UILabel = self.mTextTitleFirstControl!.control as! UILabel
            let workingSize = (label.text?.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: label.font.fontName , size: label.font.pointSize)!]))!
            var height = self.mTextTitleFirstControl!.control.intrinsicContentSize.height
            if workingSize.height > height { height = workingSize.height }
            if height > maxLineHeight {
                maxLineHeight = self.mTextTitleFirstControl!.control.intrinsicContentSize.height
            }
            var width = self.mTextTitleFirstControl!.control.intrinsicContentSize.width
            if workingSize.width > width { width = workingSize.width }
            maxLineWidth = maxLineWidth + width
            if self.mImageTitleFirstControl != nil { maxLineWidth = maxLineWidth + self._horiInterItemPad }
        }
        return CGSize(width: maxLineWidth, height: maxLineHeight)
    }
    
    // is the text title width being under calculated?
    public func hasTextTitleLayoutWidthError() -> Bool {
        if self.mTextTitleFirstControl != nil && !self.mMovedToFirst {
            let label:UILabel = self.mTextTitleFirstControl!.control as! UILabel
            let workingSize = (label.text?.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: label.font.fontName , size: label.font.pointSize)!]))!
            if workingSize.width > self.mTextTitleFirstControl!.control.intrinsicContentSize.width { return true }
        }
        return false
    }
    
    // for the entire TableViewCell, compute its theoretical intrinsic size, including the imageTitle and textTitle if present;
    //  inter-item pads are included; note that of course, every control, label, and image needs be preset with its content and placeholders
    public func getLayoutInstrinsicSize() -> CGSize {
        if self.mComposedLayoutArray.count == 0 { return CGSize.zero }
        self.getLayoutMargins()
        var maxLineWidth:CGFloat = 0.0
        var maxLineHeight:CGFloat = 0.0
        for line in 0...self.mComposedLayoutArray.count - 1 {
            if self.mComposedLayoutArray[line].count > 0 {
                var lineWidth:CGFloat = 0.0
                var lineHeight:CGFloat = 0.0
                for ctrl in 0...self.mComposedLayoutArray[line].count - 1  {
                    lineWidth = lineWidth + self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.width
                    if ctrl > 0 { lineWidth = lineWidth + self._horiInterItemPad }
                    if self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.height > lineHeight {
                        lineHeight = self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.height
                    }
                }
                if lineWidth > maxLineWidth { maxLineWidth = lineWidth }
                maxLineHeight = maxLineHeight + lineHeight
                if line > 0 { maxLineHeight = maxLineHeight + self._vertInterItemPad }
            }
        }
        if self.mImageTitleFirstControl != nil && !self.mMovedToFirst {
            if self.mImageTitleFirstControl!.control.intrinsicContentSize.height > maxLineHeight {
                maxLineHeight = self.mImageTitleFirstControl!.control.intrinsicContentSize.height
            }
            maxLineWidth = maxLineWidth + self.mImageTitleFirstControl!.control.intrinsicContentSize.width
        }
        if self.mTextTitleFirstControl != nil && !self.mMovedToFirst {
            let label:UILabel = self.mTextTitleFirstControl!.control as! UILabel
            let workingSize = (label.text?.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: label.font.fontName , size: label.font.pointSize)!]))!
            if self.mTextTitleFirstControl!.control.intrinsicContentSize.height > maxLineHeight {
                maxLineHeight = self.mTextTitleFirstControl!.control.intrinsicContentSize.height
            }
            var width = self.mTextTitleFirstControl!.control.intrinsicContentSize.width
            if workingSize.width > width { width = workingSize.width }
            maxLineWidth = maxLineWidth + width
            if self.mImageTitleFirstControl != nil { maxLineWidth = maxLineWidth + self._horiInterItemPad }
        }
        return CGSize(width: maxLineWidth, height: maxLineHeight)
    }
    
    // for the "fields" column, compute its composed bounds size as it will be layed out;
    // note that of course, every control, label, and image needs be preset with its content and placeholders;
    // note too that this size can be inaccurate until iOS has triggered layoutSubviews();
    // to use before layoutSubview() one can utilize withMinFieldHeight to make a working estimate
    public func getFieldsBoundsSize(withMinFieldHeight:CGFloat=0.0) -> CGSize {
        if self.mComposedLayoutArray.count == 0 { return CGSize.zero }
        self.getLayoutMargins()
        var maxLineWidth:CGFloat = 0.0
        var maxLineHeight:CGFloat = 0.0
        for line in 0...self.mComposedLayoutArray.count - 1 {
            if self.mComposedLayoutArray[line].count > 0 {
                var lineWidth:CGFloat = 0.0
                var lineHeight:CGFloat = 0.0
                for ctrl in 0...self.mComposedLayoutArray[line].count - 1  {
                    var ctrlWidth = self.mComposedLayoutArray[line][ctrl].control.bounds.size.width
                    if ctrlWidth <= 0.0 { ctrlWidth = self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.width + 2.0 }
                    lineWidth = lineWidth + ctrlWidth
                    if ctrl > 0 { lineWidth = lineWidth + self._horiInterItemPad }
                    var ctrlHeight = self.mComposedLayoutArray[line][ctrl].control.bounds.size.height
                    if ctrlHeight <= 0.0 { ctrlHeight = self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.height + 2.0 }
                    if withMinFieldHeight > 0.0 { if ctrlHeight < withMinFieldHeight { ctrlHeight = withMinFieldHeight } }
                    if ctrlHeight > lineHeight { lineHeight = ctrlHeight }
                }
                if lineWidth > maxLineWidth { maxLineWidth = lineWidth }
                maxLineHeight = maxLineHeight + lineHeight
                if line > 0 { maxLineHeight = maxLineHeight + self._vertInterItemPad }
            }
        }
        maxLineWidth = maxLineWidth + self._horiLeadingPad + self._horiTrailingPad
        maxLineHeight = maxLineHeight + self._vertTopPad + self._vertBottomPad
        return CGSize(width: maxLineWidth, height: maxLineHeight)
    }
    
    // for the titles columns, compute their composed bounds size as it will be layed out;
    // note that of course, every control, label, and image needs be preset with its content and placeholders;
    // note too that this size can be inaccurate until iOS has triggered layoutSubviews();
    // to use before layoutSubview() one can utilize withMinFieldHeight to make a working estimate
    public func getTitlesBoundsSize() -> CGSize {
        self.getLayoutMargins()
        var maxLineWidth:CGFloat = 0.0
        var maxLineHeight:CGFloat = 0.0
        if self.mImageTitleFirstControl != nil && !self.mMovedToFirst {
            var ctrlHeight = self.mImageTitleFirstControl!.control.bounds.size.height
            if ctrlHeight <= 0.0 { ctrlHeight = self.mImageTitleFirstControl!.control.intrinsicContentSize.height + 2.0 }
            if ctrlHeight > maxLineHeight { maxLineHeight = ctrlHeight }
            var ctrlWidth = self.mImageTitleFirstControl!.control.bounds.size.width
            if ctrlWidth <= 0.0 { ctrlWidth = self.mImageTitleFirstControl!.control.intrinsicContentSize.width + 2.0 }
        }
        if self.mTextTitleFirstControl != nil && !self.mMovedToFirst {
            let label:UILabel = self.mTextTitleFirstControl!.control as! UILabel
            let workingSize = (label.text?.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: label.font.fontName , size: label.font.pointSize)!]))!
            var ctrlHeight = self.mTextTitleFirstControl!.control.bounds.size.height
            if ctrlHeight <= 0.0 { ctrlHeight = workingSize.height + 2.0 }
            if ctrlHeight > maxLineHeight { maxLineHeight = ctrlHeight }
            var ctrlWidth = self.mTextTitleFirstControl!.control.bounds.size.width
            if ctrlWidth <= 0.0 { ctrlWidth = workingSize.width + 2.0 }
            else if ctrlWidth <= workingSize.width + 2.0 { ctrlWidth = workingSize.width + 2.0 }
            if self.mImageTitleFirstControl != nil { maxLineWidth = maxLineWidth + self._horiInterItemPad }
        }
        maxLineWidth = maxLineWidth + self._horiLeadingPad + self._horiTrailingPad
        maxLineHeight = maxLineHeight + self._vertTopPad + self._vertBottomPad
        return CGSize(width: maxLineWidth, height: maxLineHeight)
    }
    
    // for the entire TableViewCell, compute its theoretical bounds size, including the imageTitle and textTitle if present;
    // note that of course, every control, label, and image needs be preset with its content and placeholders;
    // note too that this size can be inaccurate until iOS has triggered layoutSubviews();
    // to use before layoutSubview() one can utilize withMinFieldHeight to make a working estimate
    public func getLayoutBoundsSize(withMinFieldHeight:CGFloat=0.0) -> CGSize {
        if self.mComposedLayoutArray.count == 0 { return CGSize.zero }
        self.getLayoutMargins()
        var maxLineWidth:CGFloat = 0.0
        var maxLineHeight:CGFloat = 0.0
        for line in 0...self.mComposedLayoutArray.count - 1 {
            if self.mComposedLayoutArray[line].count > 0 {
                var lineWidth:CGFloat = 0.0
                var lineHeight:CGFloat = 0.0
                for ctrl in 0...self.mComposedLayoutArray[line].count - 1  {
                    var ctrlWidth = self.mComposedLayoutArray[line][ctrl].control.bounds.size.width
                    if ctrlWidth <= 0.0 { ctrlWidth = self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.width + 2.0 }
                    lineWidth = lineWidth + ctrlWidth
                    if ctrl > 0 { lineWidth = lineWidth + self._horiInterItemPad }
                    var ctrlHeight = self.mComposedLayoutArray[line][ctrl].control.bounds.size.height
                    if ctrlHeight <= 0.0 { ctrlHeight = self.mComposedLayoutArray[line][ctrl].control.intrinsicContentSize.height + 2.0 }
                    if withMinFieldHeight > 0.0 { if ctrlHeight < withMinFieldHeight { ctrlHeight = withMinFieldHeight } }
                    if ctrlHeight > lineHeight { lineHeight = ctrlHeight }
                }
                if lineWidth > maxLineWidth { maxLineWidth = lineWidth }
                maxLineHeight = maxLineHeight + lineHeight
                if line > 0 { maxLineHeight = maxLineHeight + self._vertInterItemPad }
            }
        }
        if self.mImageTitleFirstControl != nil && !self.mMovedToFirst {
            var ctrlHeight = self.mImageTitleFirstControl!.control.bounds.size.height
            if ctrlHeight <= 0.0 { ctrlHeight = self.mImageTitleFirstControl!.control.intrinsicContentSize.height + 2.0 }
            if ctrlHeight > maxLineHeight { maxLineHeight = ctrlHeight }
            var ctrlWidth = self.mImageTitleFirstControl!.control.bounds.size.width
            if ctrlWidth <= 0.0 { ctrlWidth = self.mImageTitleFirstControl!.control.intrinsicContentSize.width + 2.0 }
        }
        if self.mTextTitleFirstControl != nil && !self.mMovedToFirst {
            var ctrlHeight = self.mTextTitleFirstControl!.control.bounds.size.height
            if ctrlHeight <= 0.0 { ctrlHeight = self.mTextTitleFirstControl!.control.intrinsicContentSize.height + 2.0 }
            if ctrlHeight > maxLineHeight { maxLineHeight = ctrlHeight }
            var ctrlWidth = self.mTextTitleFirstControl!.control.bounds.size.width
            if ctrlWidth <= 0.0 { ctrlWidth = self.mTextTitleFirstControl!.control.intrinsicContentSize.width + 2.0 }
            if self.mImageTitleFirstControl != nil { maxLineWidth = maxLineWidth + self._horiInterItemPad }
        }
        maxLineWidth = maxLineWidth + self._horiLeadingPad + self._horiTrailingPad
        maxLineHeight = maxLineHeight + self._vertTopPad + self._vertBottomPad
        return CGSize(width: maxLineWidth, height: maxLineHeight)
    }
    
    // copies in the iOS default AutoLayout margins unless overriden
    private func getLayoutMargins() {
        if self.mContentView == nil { return }
        if self.horiLeadingPad < 0 { self._horiLeadingPad = self.mContentView!.layoutMargins.left }
        else { self._horiLeadingPad = CGFloat(self.horiLeadingPad) }
        if self.horiInterItemPad < 0 { self._horiInterItemPad = self.mContentView!.layoutMargins.left }
        else { self._horiInterItemPad = CGFloat(self.horiInterItemPad) }
        if self.horiTrailingPad == -2 { self._horiTrailingPad = 0.0 }
        else if self.horiTrailingPad < 0 { self._horiTrailingPad = self.mContentView!.layoutMargins.right }
        else { self._horiTrailingPad = CGFloat(self.horiTrailingPad) }
        
        if self.vertTopPad < 0 { self._vertTopPad = self.mContentView!.layoutMargins.top }
        else { self._vertTopPad = CGFloat(self.vertTopPad) }
        if self.vertInterItemPad < 0 { self._vertInterItemPad = self.mContentView!.layoutMargins.top }
        else { self._vertInterItemPad = CGFloat(self.vertInterItemPad) }
        if self.vertBottomPad == -2 { self._vertBottomPad = 0.0 }
        else if self.vertBottomPad < 0 { self._vertBottomPad = self.mContentView!.layoutMargins.bottom }
        else { self._vertBottomPad = CGFloat(self.vertBottomPad) }
    }
    
    // assess and move the title if more space is needed and is allowed;
    // going to use intrinsic sizes since we want to override AutoLayout's compressions
    public func assessTitleMove(contentView:UIView, noBottomsOrEnds:Bool=false) -> Bool {
        if self._mUnmovedComposedLayoutArray.count == 0 && self.mImageTitleFirstControl == nil && self.mTextTitleFirstControl == nil { return false }
        if self.mtitleAreaRatioWidthToMove <= 0.0 || noBottomsOrEnds { return false }
        
        let savedMovedToFirst = self.mMovedToFirst
        self.mMovedToFirst = false
        let fieldsIntrinsicSizes = self.getFieldsInstrinsicSize()
        let titlesIntrinsicSizes = self.getTitlesInstrinsicSize()
        self.mMovedToFirst = savedMovedToFirst
        
        let titlesMaxWidth:CGFloat = contentView.bounds.width * self.mtitleAreaRatioWidthToMove
        let fieldsAvailWidth:CGFloat = contentView.bounds.width - titlesMaxWidth
        
        if titlesIntrinsicSizes.width > titlesMaxWidth || fieldsIntrinsicSizes.width > fieldsAvailWidth {
            if !self.mMovedToFirst && (self.mImageTitleFirstControl != nil || self.mTextTitleFirstControl != nil) {
                self._mMovedComposedLayoutArray = self._mUnmovedComposedLayoutArray
                self.mCurrentLine = []
                if self.mImageTitleFirstControl != nil {
                    self.mCurrentLine.append(self.mImageTitleFirstControl!)
                }
                if self.mTextTitleFirstControl != nil {
                    self.mCurrentLine.append(self.mTextTitleFirstControl!)
                }
                self._mMovedComposedLayoutArray.insert(self.mCurrentLine, at: 0)
                self.mCurrentLine = []
                self.mMovedToFirst = true
//debugPrint("\(self.mCTAG).assessTitleMove MOVED TITLE TO TOP LINE")
                return true
            }
        } else {
            if self.mMovedToFirst {
                self._mMovedComposedLayoutArray = []
                self.mMovedToFirst = false
//debugPrint("\(self.mCTAG).assessTitleMove MOVED TITLE TO OWN COLUMN")
                return true
            }
        }
        return false
    }
    
    // generate the dynamic constraints;
    // for best results, all controls (title, image, fields) should be pre-initalized with their contents and placeholders and fonts etc
    // such that all their intrinsicContentSize are known and are close to their final values;
    // noBottoms is used if it is suspected that iOS Autolayout has provided false/default contentView frame sizes, so we dont want to allow
    // the AutoLayout system to shrink/grow any fields to a false contentView frame sizes;
    public func generateDynamicConstraints(contentView:UIView, noBottomsOrEnds:Bool=false) -> ([String:AnyObject], [NSLayoutConstraint]) {
        self.mContentView = contentView
        var views:[String:AnyObject] = [:]
        var dynamicConstraints:[NSLayoutConstraint] = []
        
        if self._mUnmovedComposedLayoutArray.count == 0 && self.mImageTitleFirstControl == nil && self.mTextTitleFirstControl == nil { return (views, dynamicConstraints) }
        
        // compose the views and assess any Equal or LessThanOrEqual width fields;
        if self.mImageTitleFirstControl != nil { views[self.mImageTitleFirstControl!.controlName] = self.mImageTitleFirstControl!.control }
        if self.mTextTitleFirstControl != nil { views[self.mTextTitleFirstControl!.controlName] = self.mTextTitleFirstControl!.control }
        if self._mUnmovedComposedLayoutArray.count > 0 {
            for line:Int in 0...self._mUnmovedComposedLayoutArray.count - 1 {
                if self._mUnmovedComposedLayoutArray[line].count > 0 {
                    var lineHasVariWidth:Bool = false
                    for ctrl in 0...self._mUnmovedComposedLayoutArray[line].count - 1 {
                        if !self._mUnmovedComposedLayoutArray[line][ctrl].isFixedWidthOrLess { lineHasVariWidth = true }
                        self._mUnmovedComposedLayoutArray[line][ctrl]._noTrail = false
                        views[self._mUnmovedComposedLayoutArray[line][ctrl].controlName] = self._mUnmovedComposedLayoutArray[line][ctrl].control
                    }
                    if !lineHasVariWidth {
                        let ctrl = self._mUnmovedComposedLayoutArray[line].count - 1
                        self._mUnmovedComposedLayoutArray[line][ctrl]._noTrail = true
                    }
                }
            }
        }
        if self._mMovedComposedLayoutArray.count > 0 {
            for line:Int in 0...self._mMovedComposedLayoutArray.count - 1 {
                if self._mMovedComposedLayoutArray[line].count > 0 {
                    var lineHasVariWidth:Bool = false
                    for ctrl in 0...self._mMovedComposedLayoutArray[line].count - 1 {
                        if !self._mMovedComposedLayoutArray[line][ctrl].isFixedWidthOrLess { lineHasVariWidth = true }
                        self._mMovedComposedLayoutArray[line][ctrl]._noTrail = false
                    }
                    if !lineHasVariWidth {
                        let ctrl = self._mMovedComposedLayoutArray[line].count - 1
                        self._mMovedComposedLayoutArray[line][ctrl]._noTrail = true
                    }
                }
            }
        }
        
        // do the generation now if not allowed to move the titles or if the layout sizings are likely false
        if self.mtitleAreaRatioWidthToMove <= 0.0 || noBottomsOrEnds || self.mContentView == nil {
            let _ = self.doGenerateDynamicConstraints(contentView: contentView, views: views, dynConstraints: &dynamicConstraints, noBottomsOrEnds: noBottomsOrEnds)
            return (views, dynamicConstraints)
        }

        // move the title if more space is needed
        if self.assessTitleMove(contentView: contentView, noBottomsOrEnds: noBottomsOrEnds) { self.mRow?.baseCell.setNeedsLayout() }
        
        dynamicConstraints = []
        let _ = self.doGenerateDynamicConstraints(contentView: contentView, views: views, dynConstraints: &dynamicConstraints, noBottomsOrEnds: noBottomsOrEnds)
        return (views, dynamicConstraints)
    }
    
    // generate constraints for the current layout; automatically uses either the Unmoved or Moved layout
    private func doGenerateDynamicConstraints(contentView:UIView, views:[String:AnyObject], dynConstraints:inout [NSLayoutConstraint], noBottomsOrEnds:Bool=false) -> Bool {
        // compose all the horizontal constraints; first insert any leading controls (title image and title text)
        var hasFirsts:Bool = false
        var vizH:String = "H:|"
        var nextHoriSep:String = "-"
        if self.horiLeadingPad >= 0 { nextHoriSep = nextHoriSep + "\(self.horiLeadingPad)-" }
        if self.mImageTitleFirstControl != nil && !self.mMovedToFirst {
            hasFirsts = true
            vizH = vizH + "\(nextHoriSep)[\(self.mImageTitleFirstControl!.controlName)]"
            nextHoriSep = "-"
            if self.horiInterItemPad >= 0 { nextHoriSep = nextHoriSep + "\(self.horiInterItemPad)-" }
        }
        if self.mTextTitleFirstControl != nil && !self.mMovedToFirst {
            hasFirsts = true
            vizH = vizH + "\(nextHoriSep)[\(self.mTextTitleFirstControl!.controlName)]"
            nextHoriSep = "-"
            if self.horiInterItemPad >= 0 { nextHoriSep = nextHoriSep + "\(self.horiInterItemPad)-" }
        }
        if hasFirsts {
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mRow?.title ?? "") Hori=\(vizH)")
            dynConstraints += NSLayoutConstraint.constraints(withVisualFormat: vizH, options: [], metrics: nil, views: views)
        }
        
        // compose all the horizontal lines and controls
        if self.mComposedLayoutArray.count > 0 {
            for line:Int in 0...self.mComposedLayoutArray.count - 1 {
                var hasHori:Bool = false
                var vizH:String = "H:|"
                var nextHoriSep:String = "-"
                if hasFirsts {
                    if self.mTextTitleFirstControl != nil { vizH = "[\(self.mTextTitleFirstControl!.controlName)]" }
                    else { vizH = "[\(self.mImageTitleFirstControl!.controlName))]" }
                    if self.horiInterItemPad >= 0 { nextHoriSep = nextHoriSep + "\(self.horiInterItemPad)-" }
                } else {
                    if self.horiLeadingPad >= 0 { nextHoriSep = nextHoriSep + "\(self.horiLeadingPad)-" }
                }
                if self.mComposedLayoutArray[line].count > 0 {
                    for ctrl in 0...self.mComposedLayoutArray[line].count - 1 {
                        hasHori = true
                        //if !self.mComposedLayoutArray[line][ctrl]._noLead { vizH = vizH + nextHoriSep }
                        vizH = vizH + nextHoriSep
                        vizH = vizH + "[\(self.mComposedLayoutArray[line][ctrl].controlName)]"
                        if self.mComposedLayoutArray[line][ctrl]._noTrail { nextHoriSep = "" }
                        else {
                            nextHoriSep = "-"
                            if self.horiInterItemPad >= 0 { nextHoriSep = nextHoriSep + "\(self.horiInterItemPad)-" }
                        }
                    }
                }
                if hasHori {
                    if self.horiTrailingPad >= -1 && !noBottomsOrEnds && !nextHoriSep.isEmpty {
                        if self.horiTrailingPad >= 0 { nextHoriSep = nextHoriSep + "\(self.horiTrailingPad)-|" }
                        else { vizH = vizH + "-|" }
                    }
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mRow?.title ?? "") Hori=\(vizH)")
                    dynConstraints += NSLayoutConstraint.constraints(withVisualFormat: vizH, options: [], metrics: nil, views: views)
                }
            }
        }
        
        // compose all the easy align-vertical-center constraints
        if self.mComposedLayoutArray.count > 0 {
            for line:Int in 0...self.mComposedLayoutArray.count - 1 {
                if self.mComposedLayoutArray[line].count > 1 {
                    for ctrl in 1...self.mComposedLayoutArray[line].count - 1 {
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mRow?.title ?? "") To-First CenterY: \(self.mComposedLayoutArray[line][ctrl].controlName) to \(self.mComposedLayoutArray[line][0].controlName)")
                        dynConstraints += [NSLayoutConstraint(item: self.mComposedLayoutArray[line][ctrl].control, attribute: .centerY, relatedBy: .equal, toItem: self.mComposedLayoutArray[line][0].control, attribute: .centerY, multiplier: 1, constant: 0)]
                    }
                }
            }
        }
        
        // compose the vertial constraints for the image title, text title, and first control in each line;
        // pick which is the largest height and use that to bound the TableViewCell; the others attempt to Center-Y;
        // note that the iOS layout system does Constraints first then determines control sizes so need to use intrinsicContentSize
        // which will be small than the ultimate controls bound's sizes
        var imageHeight:CGFloat = 0.0
        if self.mImageTitleFirstControl != nil {
            imageHeight = self.mImageTitleFirstControl!.control.intrinsicContentSize.height
        }
        var titleHeight:CGFloat = 0.0
        if self.mTextTitleFirstControl != nil {
            titleHeight = self.mTextTitleFirstControl!.control.intrinsicContentSize.height
        }
        var fieldsHeight:CGFloat = 0.0
        if self.mComposedLayoutArray.count > 0 {
            for line:Int in 0...self.mComposedLayoutArray.count - 1 {
                var ctrlHeight:CGFloat = self.mComposedLayoutArray[line][0].control.intrinsicContentSize.height
                if ctrlHeight <= 0.0 { ctrlHeight = self.mComposedLayoutArray[line][0].control.layer.frame.size.height }
                fieldsHeight = fieldsHeight + ctrlHeight
                if line > 0 { fieldsHeight = fieldsHeight + CGFloat(self.vertInterItemPad >= 0 ? self.vertInterItemPad : 10) }
            }
        }
        var highestHeight:CGFloat = imageHeight
        if titleHeight > highestHeight { highestHeight = titleHeight }
        if fieldsHeight > highestHeight { highestHeight = fieldsHeight }
        
        // height's obtained; now do verts for the image or text titles
        if self.mImageTitleFirstControl != nil && !self.mMovedToFirst {
            if imageHeight >= highestHeight {
                var vizV = "V:|-"
                if self.vertTopPad >= 0 { vizV = vizV + "\(self.vertTopPad)-" }
                vizV = vizV + "[\(self.mImageTitleFirstControl!.controlName)]"
                if self.vertBottomPad >= -1 && !noBottomsOrEnds && !self.mCellHasManualHeight {
                    if self.vertBottomPad >= 0 { vizV = vizV + "-\(self.vertBottomPad)-|" }
                    else { vizV = vizV + "-|" }
                }
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mRow?.title ?? "") Vert=\(vizV)")
                dynConstraints += NSLayoutConstraint.constraints(withVisualFormat: vizV, options: [], metrics: nil, views: views)
            } else {
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mRow?.title ?? "") CenterY: \(self.mImageTitleFirstControl!.controlName) to ContentView")
                dynConstraints += [NSLayoutConstraint(item: self.mImageTitleFirstControl!.control, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)]
            }
        }
        if self.mTextTitleFirstControl != nil && !self.mMovedToFirst {
            if titleHeight >= highestHeight {
                var vizV = "V:|-"
                if self.vertTopPad >= 0 { vizV = vizV + "\(self.vertTopPad)-" }
                vizV = vizV + "[\(self.mTextTitleFirstControl!.controlName)]"
                if self.vertBottomPad >= -1 && !noBottomsOrEnds && !self.mCellHasManualHeight {
                    if self.vertBottomPad >= 0 { vizV = vizV + "-\(self.vertBottomPad)-|" }
                    else { vizV = vizV + "-|" }
                }
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mRow?.title ?? "") Vert=\(vizV)")
                dynConstraints += NSLayoutConstraint.constraints(withVisualFormat: vizV, options: [], metrics: nil, views: views)
            } else {
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mRow?.title ?? "") CenterY: \(self.mTextTitleFirstControl!.controlName) to ContentView")
                dynConstraints += [NSLayoutConstraint(item: self.mTextTitleFirstControl!.control, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)]
            }
        }
        
        // now do verts for the field lines
        if self.mComposedLayoutArray.count == 1 && self.mCellHasManualHeight {
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mComposedLayoutArray[0][0].controlName) CenterY: \(self.mTextTitleFirstControl!.controlName) to ContentView")
            dynConstraints += [NSLayoutConstraint(item: self.mComposedLayoutArray[0][0].control, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)]
        } else {
            var hasVert:Bool = false
            var vizV:String = "V:|"
            var nextVertSep:String = "-"
            if self.vertTopPad >= 0 { nextVertSep = nextVertSep + "\(self.vertTopPad)-" }
            
            if self.mComposedLayoutArray.count > 0 {
                for line:Int in 0...self.mComposedLayoutArray.count - 1 {
                    hasVert = true
                    vizV = vizV + "\(nextVertSep)[\(self.mComposedLayoutArray[line][0].controlName)]"
                    nextVertSep = "-"
                    if self.vertInterItemPad >= 0 { nextVertSep = nextVertSep + "\(self.vertInterItemPad)-" }
                }
            }
            if fieldsHeight >= highestHeight && !noBottomsOrEnds && !self.mCellHasManualHeight {
                if self.vertBottomPad >= -1 && !self.mCellHasManualHeight {
                    if self.vertBottomPad >= 0 { vizV = vizV + "-\(self.vertBottomPad)-|" }
                    else { vizV = vizV + "-|" }
                }
            }
            if hasVert {
//debugPrint("\(self.mCTAG).generateDynamicConstraints.\(self.mRow?.title ?? "") Vert=\(vizV)")
                dynConstraints += NSLayoutConstraint.constraints(withVisualFormat: vizV, options: [], metrics: nil, views: views)
            }
        }
        return true
    }
}
