//  Adapted From:
//  TextAreaRow.swift
//  Eureka ( https://github.com/xmartlabs/Eureka )
//
//  Copyright (c) 2016 Xmartlabs SRL ( http://xmartlabs.com )
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

open class _TextAreaCellExt<T> : Cell<T>, UITextViewDelegate, AreaCell where T: Equatable, T: InputTypeInitiable {
    
    @IBOutlet public weak var textView: UITextView!
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var placeholderLabel: UILabel?
    
    private var awakeFromNibCalled = false
    open var dynamicConstraints = [NSLayoutConstraint]()
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let textView = UITextView()
        self.textView = textView
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.keyboardType = .default
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets.zero
        contentView.addSubview(textView)
        
        let placeholderLabel = UILabel()
        self.placeholderLabel = placeholderLabel
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.numberOfLines = 0
        placeholderLabel.textColor = UIColor(white: 0, alpha: 0.22)
        placeholderLabel.font = textView.font
        contentView.addSubview(placeholderLabel)
        
        titleLabel = self.textLabel
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        awakeFromNibCalled = true
    }
    
    open override func setup() {
        super.setup()
        let textAreaRow = row as! TextAreaConformance
        switch textAreaRow.textAreaHeight {
        case .dynamic(_):
            height = { UITableView.automaticDimension }
            textView.isScrollEnabled = false
        case .fixed(_):
            height = { UITableView.automaticDimension }
        }
        
        textView.delegate = self
        selectionStyle = .none
        if !awakeFromNibCalled {
            imageView?.addObserver(self, forKeyPath: "image", options: [.new, .old], context: nil)
        }
        setNeedsUpdateConstraints()
    }
    
    deinit {
        textView?.delegate = nil
        if !awakeFromNibCalled {
            imageView?.removeObserver(self, forKeyPath: "image")
        }
    }
    
    open override func update() {
        super.update()
        let taRow = self.row as! AreaRowExt<TextAreaCellExt>
        textLabel?.text = nil
        detailTextLabel?.text = nil

        if (row.title ?? "").isEmpty {
            self.titleLabel!.text = nil
        } else {
            if (taRow.title2 ?? "").isEmpty {
                self.titleLabel!.numberOfLines = 1
                self.titleLabel!.text = row.title!
            } else {
                self.titleLabel!.numberOfLines = 2
                self.titleLabel!.text = row.title! + "\n" + taRow.title2!
            }
            if !row.isValid { self.titleLabel!.textColor = UIColor.red }
            else if row.isHighlighted { self.titleLabel!.textColor = tintColor }
        }
        
        textView.isEditable = !row.isDisabled
        textView.textColor = row.isDisabled ? .gray : .black
        textView.text = row.displayValueFor?(row.value)
        placeholderLabel?.text = (row as? TextAreaConformance)?.placeholder
        placeholderLabel?.isHidden = textView.text.count != 0
    }
    
    open override func cellCanBecomeFirstResponder() -> Bool {
        return !row.isDisabled && textView?.canBecomeFirstResponder == true
    }
    
    open override func cellBecomeFirstResponder(withDirection: Direction) -> Bool {
        // workaround to solve https://github.com/xmartlabs/Eureka/issues/887 UIKit issue
        textView?.perform(#selector(UITextView.becomeFirstResponder), with: nil, afterDelay: 0.0)
        return true
        
    }
    
    open override func cellResignFirstResponder() -> Bool {
        return textView?.resignFirstResponder() ?? true
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let obj = object as AnyObject?
        
        if let keyPathValue = keyPath, let changeType = change?[NSKeyValueChangeKey.kindKey], obj === imageView && keyPathValue == "image" &&
            (changeType as? NSNumber)?.uintValue == NSKeyValueChange.setting.rawValue, !awakeFromNibCalled {
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
    }
    
    //Mark: Helpers
    
    private func displayValue(useFormatter: Bool) -> String? {
        guard let v = row.value else { return nil }
        if let formatter = (row as? FormatterConformance)?.formatter, useFormatter {
            return textView?.isFirstResponder == true ? formatter.editingString(for: v) : formatter.string(for: v)
        }
        return String(describing: v)
    }
    
    // MARK: TextFieldDelegate
    
    open func textViewDidBeginEditing(_ textView: UITextView) {
        formViewController()?.beginEditing(of: self)
        formViewController()?.textInputDidBeginEditing(textView, cell: self)
        if let textAreaConformance = (row as? TextAreaConformance), let _ = textAreaConformance.formatter, textAreaConformance.useFormatterOnDidBeginEditing ?? textAreaConformance.useFormatterDuringInput {
            textView.text = self.displayValue(useFormatter: true)
        } else {
            textView.text = self.displayValue(useFormatter: false)
        }
    }
    
    open func textViewDidEndEditing(_ textView: UITextView) {
        formViewController()?.endEditing(of: self)
        formViewController()?.textInputDidEndEditing(textView, cell: self)
        textViewDidChange(textView)
        textView.text = displayValue(useFormatter: (row as? FormatterConformance)?.formatter != nil)
    }
    
    open func textViewDidChange(_ textView: UITextView) {
        
        if let textAreaConformance = row as? TextAreaConformance, case .dynamic = textAreaConformance.textAreaHeight, let tableView = formViewController()?.tableView {
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
        }
        placeholderLabel?.isHidden = textView.text.count != 0
        guard let textValue = textView.text else {
            row.value = nil
            return
        }
        guard let fieldRow = row as? FieldRowConformance, let formatter = fieldRow.formatter else {
            row.value = textValue.isEmpty ? nil : (T.init(string: textValue) ?? row.value)
            return
        }
        if fieldRow.useFormatterDuringInput {
            let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(UnsafeMutablePointer<T>.allocate(capacity: 1))
            let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            if formatter.getObjectValue(value, for: textValue, errorDescription: errorDesc) {
                row.value = value.pointee as? T
                guard var selStartPos = textView.selectedTextRange?.start else { return }
                let oldVal = textView.text
                textView.text = row.displayValueFor?(row.value)
                selStartPos = (formatter as? FormatterProtocol)?.getNewPosition(forPosition: selStartPos, inTextInput: textView, oldValue: oldVal, newValue: textView.text) ?? selStartPos
                textView.selectedTextRange = textView.textRange(from: selStartPos, to: selStartPos)
                return
            }
        } else {
            let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(UnsafeMutablePointer<T>.allocate(capacity: 1))
            let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            if formatter.getObjectValue(value, for: textValue, errorDescription: errorDesc) {
                row.value = value.pointee as? T
            }
        }
    }
    
    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return formViewController()?.textInput(textView, shouldChangeCharactersInRange: range, replacementString: text, cell: self) ?? true
    }
    
    open func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let textAreaRow = self.row as? _TextAreaRow, textAreaRow.textAreaMode == .readOnly {
            return false
        }
        return formViewController()?.textInputShouldBeginEditing(textView, cell: self) ?? true
    }
    
    open func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return formViewController()?.textInputShouldEndEditing(textView, cell: self) ?? true
    }
    
    open override func updateConstraints() {
        customConstraints()
        super.updateConstraints()
    }
    
    open func customConstraints() {
        guard !awakeFromNibCalled else { return }
        let taRow:AreaRowExt<TextAreaCellExt>? = self.row as? AreaRowExt<TextAreaCellExt>
        if taRow == nil { return }

        var newDynConstraints:[NSLayoutConstraint] = []
        var isFixedWidth:Bool = false
        switch taRow!.textAreaHeight {
        case .dynamic(let initialHeight):
            if initialHeight > 0.0 {
                self.textView.layer.frame.size.height = initialHeight
                newDynConstraints.append(NSLayoutConstraint(item: self.textView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: initialHeight))
            }
            break
        case .fixed(let fixedHeight):
            if fixedHeight > 0.0 {
                self.textView.layer.frame.size.height = fixedHeight
                newDynConstraints.append(NSLayoutConstraint(item: self.textView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: fixedHeight))
            }
            break
        }
        switch taRow!.textAreaWidth {
        case .dynamic(let initialWidth):
            if initialWidth > 0.0 {
                self.textView.layer.frame.size.width = initialWidth
                newDynConstraints.append(NSLayoutConstraint(item: self.textView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: initialWidth))
            }
            break
        case .fixed(let fixedWidth):
            if fixedWidth > 0.0 {
                isFixedWidth = true
                self.textView.layer.frame.size.width = fixedWidth
                newDynConstraints.append(NSLayoutConstraint(item: self.textView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: fixedWidth))
            }
            break
        }

        // prepare to compose the relatively simple dynamic layout
        let newComposedLayout = ComposedLayout(contentView: self.contentView, row: row, cellHasManualHeight: false, titleAreaRatioWidthToMove: 0.2)
        if let titleLabel = self.titleLabel, let text = titleLabel.text, !text.isEmpty {
            newComposedLayout.addTextTitleFirstControl(forControl: ComposedLayoutControl(controlName: "titleLabel", control: self.titleLabel!))
        }
        if let imageView = self.imageView, let _ = imageView.image {
            newComposedLayout.addImageTitleFirstControl(forControl: ComposedLayoutControl(controlName: "imageView", control: self.imageView!))
        }
        var textViewCLC = ComposedLayoutControl(controlName: "textView", control: self.textView)
        textViewCLC.isFixedWidthOrLess = isFixedWidth
        newComposedLayout.addControlToCurrentLine(forControl: textViewCLC)
        newComposedLayout.done()
        
        var views: [String: AnyObject] = [:]
        var moreDynConstraints:[NSLayoutConstraint] = []
        (views, moreDynConstraints) = newComposedLayout.generateDynamicConstraints(contentView: contentView)
        newComposedLayout.clear()

        newDynConstraints = newDynConstraints + moreDynConstraints
        if let placeholderLabel = placeholderLabel, let text = placeholderLabel.text, !text.isEmpty {
            views["placeholderLabel"] = placeholderLabel
            newDynConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[placeholderLabel]", options: [], metrics: nil, views: views))
            newDynConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-[placeholderLabel]-|", options: [], metrics: nil, views: views))
        }
        
        contentView.removeConstraints(self.dynamicConstraints)
        self.dynamicConstraints = newDynConstraints
        contentView.addConstraints(self.dynamicConstraints)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()

        if !self.awakeFromNibCalled {
            // As titleLabel is the textLabel, iOS may re-layout without updating constraints, for example:
            // swiping, showing alert or actionsheet from the same section.
            // thus we need forcing update to use customConstraints()
            // this can create a nasty loop if constraint failures cause a re-invoke of layoutSubviews()
            setNeedsUpdateConstraints()
        }
    }
}

public enum TextAreaWidth {
    case fixed(cellWidth: CGFloat)
    case dynamic(initialTextViewWidth: CGFloat)
}

open class TextAreaCellExt: _TextAreaCellExt<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

open class AreaRowExt<Cell: CellType>: FormatteableRow<Cell>, TextAreaConformance where Cell: BaseCell, Cell: AreaCell {
    
    open var title2:String?
    open var placeholder: String?
    open var textAreaHeight = TextAreaHeight.fixed(cellHeight: 110)
    open var textAreaWidth = TextAreaWidth.dynamic(initialTextViewWidth: 0.0)
    open var textAreaMode = TextAreaMode.normal
    
    /// The percentage of the cell that should be occupied by the remaining space to the left of the textArea. This is equivalent to the space occupied by a title in FieldRow, making the textArea aligned to fieldRows using the same titlePercentage. This behavior works only if the cell does not contain an image, due to its automatically set constraints in the cell.
    open var titlePercentage: CGFloat?  // ignored
    
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _TextAreaRowExt: AreaRowExt<TextAreaCellExt> {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A row with a UITextView where the user can enter large text.
public final class TextAreaRowExt: _TextAreaRowExt, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
