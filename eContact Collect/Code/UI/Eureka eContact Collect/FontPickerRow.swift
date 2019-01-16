//  Adapted From:
//
//  SplitRow.swift
//  Valletti
//
//  Created by Marco Betschart on 01.12.17.
//  Copyright © 2017 MANDELKIND. All rights reserved.
//
//  https://github.com/EurekaCommunity/SplitRow
//

public var SystemFontPrefix:String = ".SF"

public final class FontPickerRow: _FontPickerRow, RowType {}

open class _FontPickerRow: Row<FontPickerCell> {
    
    open override var section: Section?{
        get{ return super.section }
        set{
            rowLeft?.section = newValue
            rowRight?.section = newValue
            
            super.section = newValue
        }
    }

    open override var value: UIFont? {
        get{ return super.value }
        set{
            if let newValue = newValue {
                if newValue != super.value {
                    var familyName = newValue.familyName
                    if familyName.starts(with: SystemFontPrefix) { familyName = "-System" }
                    self.rowRight?.value = familyName
                    
                    self.rowLeft?.value = FontPickerSubRowValue(size: Double(newValue.pointSize), isBold: newValue.isBold, isItalic: newValue.isItalic)
                }
                
            }
            super.value = newValue
        }
    }
    
    internal var rowLeft: FontPickerSubRow?
    internal var rowRight: PushRow<String>?
    private var systemFontName:String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
        self.systemFontName = UIFont.systemFont(ofSize: 17.0).familyName
        cellProvider = CellProvider<FontPickerCell>()
        
        rowRight = PushRow<String>() {
            var opts:[String] = UIFont.familyNames
            opts.append("-System")
            $0.options = opts.sorted()
            $0.onPresent({ sourceFVC, presentVC in
                presentVC.selectableRowCellUpdate = { vcCell, vcRow in
                    if vcRow.title! == "-System" { vcCell.textLabel?.font = UIFont.systemFont(ofSize: 17.0)}
                    else { vcCell.textLabel?.font = UIFont(name:vcRow.title!, size: 17.0) }
                }
            })
        }
        subscribe(onChange: rowRight!)
        subscribe(onCellHighlightChanged: rowRight!)
        
        rowLeft = FontPickerSubRow()
        subscribe(onChange: rowLeft!)
        subscribe(onCellHighlightChanged: rowLeft!)

        self.value = UIFont.systemFont(ofSize: 17.0)
    }
    
    open func subscribe<T: RowType>(onChange row: T) where T: BaseRow{
        row.onChange{ [weak self] row in
            guard let strongSelf = self else { return }
            
            strongSelf.cell?.update()  //TODO: This should only be done on cells which need an update. e.g. PushRow etc.

            var useFontName:String = "-System"
            var useSize:CGFloat = 17.0
            var useItalic:Bool = false
            var useBold:Bool = false
            if !(strongSelf.rowRight!.value ?? "").isEmpty { useFontName = strongSelf.rowRight!.value! }
            if strongSelf.rowLeft!.value != nil {
                useSize = CGFloat(strongSelf.rowLeft!.value!.size)
                useItalic = strongSelf.rowLeft!.value!.isItalic
                useBold = strongSelf.rowLeft!.value!.isBold
            }
            
            if useFontName == "-System" {
                strongSelf.value = UIFont.systemFont(ofSize: useSize)
            } else {
                strongSelf.value = UIFont(name: useFontName, size: useSize)
            }
            if useBold && useItalic { strongSelf.value = strongSelf.value!.boldItalic() }
            else if useBold { strongSelf.value = strongSelf.value!.bold() }
            else if useItalic { strongSelf.value = strongSelf.value!.italic() }
        }
    }
    
    open func subscribe<T: RowType>(onCellHighlightChanged row: T) where T: BaseRow{
        row.onCellHighlightChanged{ [weak self] cell, row in
            guard let strongSelf = self,
                let splitRowCell = strongSelf.cell,
                let formViewController = strongSelf.cell.formViewController()
                else { return }
            
            if cell.isHighlighted || row.isHighlighted {
                formViewController.beginEditing(of: splitRowCell)
            } else {
                formViewController.endEditing(of: splitRowCell)
            }
        }
    }
    
    open override func updateCell() {
        super.updateCell()
        
        self.rowLeft?.updateCell()
        self.rowLeft?.cell?.selectionStyle = .none
        
        self.rowRight?.updateCell()
        self.rowRight?.cell?.selectionStyle = .none
    }
}

open class FontPickerCell: Cell<UIFont>, CellType {
    var tableViewLeft: SplitRowCellTableView<FontPickerSubRow>!
    var tableViewRight: SplitRowCellTableView<PushRow<String>>!
    
    open override var isHighlighted: Bool {
        get { return super.isHighlighted || (tableViewLeft.row?.cell?.isHighlighted ?? false) || (tableViewRight.row?.cell?.isHighlighted ?? false) }
        set { super.isHighlighted = newValue }
    }
    
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.tableViewLeft = SplitRowCellTableView()
        tableViewLeft.separatorStyle = .none
        tableViewLeft.leftSeparatorStyle = .none
        tableViewLeft.translatesAutoresizingMaskIntoConstraints = false
        
        self.tableViewRight = SplitRowCellTableView()
        tableViewRight.separatorStyle = .none
        tableViewRight.leftSeparatorStyle = .singleLine
        tableViewRight.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(tableViewLeft)
        contentView.addSubview(tableViewRight)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func setup(){
        selectionStyle = .none
        
        //ignore Xcode Cast warning here, it works!
        guard let row = self.row as? _FontPickerRow else{ return }
        
        //TODO: If we use UITableViewAutomaticDimension instead of 44.0 we encounter constraint errors :(
        /*let maxRowHeight = max(row.rowLeft?.cell?.height?() ?? 44.0, row.rowRight?.cell?.height?() ?? 44.0)
        if maxRowHeight != UITableView.automaticDimension{
            self.height = { maxRowHeight }
            row.rowLeft?.cell?.height = self.height
            row.rowRight?.cell?.height = self.height
        }*/
        self.height = { UITableView.automaticDimension }
        
        tableViewLeft.row = row.rowLeft
        tableViewLeft.isScrollEnabled = false
        tableViewLeft.setup()
        
        tableViewRight.row = row.rowRight
        tableViewRight.isScrollEnabled = false
        tableViewRight.setup()
        
        setupConstraints()
    }
    
    open override func update(){
        tableViewRight.row!.title = (self.row.title ?? "") + NSLocalizedString(" Name", comment:"")
        tableViewRight.row!.selectorTitle = NSLocalizedString("Choose one", comment:"")
        tableViewRight.update()
        
        tableViewLeft.row!.title = NSLocalizedString(" Size", comment:"")
        tableViewLeft.update()
    }
    
    private func setupConstraints(){
        contentView.addConstraint(NSLayoutConstraint(item: tableViewRight, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0.0))
        contentView.addConstraint(NSLayoutConstraint(item: tableViewRight, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: 0.0))
        contentView.addConstraint(NSLayoutConstraint(item: tableViewRight, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 0.0))

        contentView.addConstraint(NSLayoutConstraint(item: tableViewLeft, attribute: .top, relatedBy: .equal, toItem: tableViewRight, attribute: .bottom, multiplier: 1.0, constant: 0.0))

        contentView.addConstraint(NSLayoutConstraint(item: tableViewLeft, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: 0.0))
        contentView.addConstraint(NSLayoutConstraint(item: tableViewLeft, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 0.0))
        contentView.addConstraint(NSLayoutConstraint(item: tableViewLeft, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        
        self.contentView.addConstraint(NSLayoutConstraint(item: tableViewRight, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .height, multiplier: 1.0, constant: 29.0))
        self.contentView.addConstraint(NSLayoutConstraint(item: tableViewLeft, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .height, multiplier: 1.0, constant: 44.0))

        //self.contentView.addConstraint(NSLayoutConstraint(item: tableViewLeft, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: row.rowLeftPercentage, constant: 0.0))
        //self.contentView.addConstraint(NSLayoutConstraint(item: tableViewRight, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: row.rowRightPercentage, constant: 0.0))
    }
    
    private func rowCanBecomeFirstResponder(_ row: BaseRow?) -> Bool{
        guard let row = row else{ return false }
        return false == row.isDisabled && row.baseCell?.cellCanBecomeFirstResponder() ?? false
    }
    
    open override var isFirstResponder: Bool{
        guard let row = self.row as? _FontPickerRow else{ return false }
        
        let rowLeftFirstResponder = row.rowLeft?.cell.findFirstResponder()
        let rowRightFirstResponder = row.rowRight?.cell?.findFirstResponder()
        
        return rowLeftFirstResponder != nil || rowRightFirstResponder != nil
    }
    
    open override func cellCanBecomeFirstResponder() -> Bool{
        guard let row = self.row as? _FontPickerRow else{ return false }
        guard false == row.isDisabled else{ return false }
        
        let rowLeftFirstResponder = row.rowLeft?.cell.findFirstResponder()
        let rowRightFirstResponder = row.rowRight?.cell?.findFirstResponder()
        
        if rowLeftFirstResponder == nil && rowRightFirstResponder == nil{
            return rowCanBecomeFirstResponder(row.rowLeft) || rowCanBecomeFirstResponder(row.rowRight)
            
        } else if rowLeftFirstResponder == nil{
            return rowCanBecomeFirstResponder(row.rowLeft)
            
        } else if rowRightFirstResponder == nil{
            return rowCanBecomeFirstResponder(row.rowRight)
        }
        
        return false
    }
    
    open override func cellBecomeFirstResponder(withDirection: Direction) -> Bool {
        guard let row = self.row as? _FontPickerRow else{ return false }
        
        let rowLeftFirstResponder = row.rowLeft?.cell.findFirstResponder()
        let rowLeftCanBecomeFirstResponder = rowCanBecomeFirstResponder(row.rowLeft)
        var isFirstResponder = false
        
        let rowRightFirstResponder = row.rowRight?.cell?.findFirstResponder()
        let rowRightCanBecomeFirstResponder = rowCanBecomeFirstResponder(row.rowRight)
        
        if withDirection == .down{
            if rowLeftFirstResponder == nil, rowLeftCanBecomeFirstResponder{
                isFirstResponder = row.rowLeft?.cell?.cellBecomeFirstResponder(withDirection: withDirection) ?? false
                
            } else if rowRightFirstResponder == nil, rowRightCanBecomeFirstResponder{
                isFirstResponder = row.rowRight?.cell?.cellBecomeFirstResponder(withDirection: withDirection) ?? false
            }
            
        } else if withDirection == .up{
            if rowRightFirstResponder == nil, rowRightCanBecomeFirstResponder{
                isFirstResponder = row.rowRight?.cell?.cellBecomeFirstResponder(withDirection: withDirection) ?? false
                
            } else if rowLeftFirstResponder == nil, rowLeftCanBecomeFirstResponder{
                isFirstResponder = row.rowLeft?.cell?.cellBecomeFirstResponder(withDirection: withDirection) ?? false
            }
        }
        
        if isFirstResponder {
            formViewController()?.beginEditing(of: self)
        }
        
        return isFirstResponder
    }
    
    open override func cellResignFirstResponder() -> Bool{
        guard let row = self.row as? _FontPickerRow else{ return false }
        
        let rowLeftResignFirstResponder = row.rowLeft?.cell?.cellResignFirstResponder() ?? false
        let rowRightResignFirstResponder = row.rowRight?.cell?.cellResignFirstResponder() ?? false
        let resignedFirstResponder = rowLeftResignFirstResponder && rowRightResignFirstResponder
        
        if resignedFirstResponder {
            formViewController()?.endEditing(of: self)
        }
        
        return resignedFirstResponder
    }
}

//  Adapted From:
//
//  StepperRow.swift
//  Eureka
//
//  Created by Andrew Holt on 3/4/16.
//  Copyright © 2016 Xmartlabs. All rights reserved.
//

public struct FontPickerSubRowValue: Equatable {
    public var size:Double = 17.0
    public var isBold:Bool = false
    public var isItalic:Bool = false
    
    public static func == (lhs: FontPickerSubRowValue, rhs: FontPickerSubRowValue) -> Bool {
        return lhs.size == rhs.size && lhs.isBold == rhs.isBold && lhs.isItalic == rhs.isItalic
    }
}

public final class FontPickerSubRow: _FontPickerSubRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _FontPickerSubRow: Row<FontPickerSubCell> {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

open class FontPickerSubCell: Cell<FontPickerSubRowValue>, CellType {
    
    @IBOutlet public weak var stepper: UIStepper!
    @IBOutlet public weak var valueLabel: UILabel?
    @IBOutlet public weak var segmentedControl: MultiSelectionSegmentedControl?
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let segmentedControl = MultiSelectionSegmentedControl(items: nil)
        //segmentedControl.frame = contentView.frame
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.setContentHuggingPriority(UILayoutPriority.hugPriDefault, for: .horizontal)
        // insert the segments in reverse order
        segmentedControl.insertSegment(NSLocalizedString("Italic", comment:""), at: 0, animated: false)
        segmentedControl.insertSegment(NSLocalizedString("Bold", comment:""), at: 0, animated: false)
        self.segmentedControl = segmentedControl
        
        /*guard let textLabel = self.textLabel else { return }
        textLabel.text = NSLocalizedString(" Size", comment:"")
        textLabel.numberOfLines = 1
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.setContentHuggingPriority(UILayoutPriority.hugPriTextLabel, for: .horizontal)*/
        
        let valueLabel = UILabel()
        valueLabel.numberOfLines = 1
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
        self.valueLabel = valueLabel

        let stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.setContentHuggingPriority(UILayoutPriority.hugPriDefault, for: .horizontal)
        self.stepper = stepper
        
        addSubview(stepper)
        addSubview(valueLabel)
        addSubview(segmentedControl)
        
        addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left,
                                         multiplier: 1.0, constant: 20))
        addConstraint(NSLayoutConstraint(item: stepper, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right,
                                         multiplier: 1.0, constant: -20))
        addConstraint(NSLayoutConstraint(item: valueLabel, attribute: .right, relatedBy: .equal, toItem: stepper, attribute: .left,
                                         multiplier: 1.0, constant: -5))
        //addConstraint(NSLayoutConstraint(item: textLabel, attribute: .right, relatedBy: .equal, toItem: valueLabel, attribute: .left,
        //                                 multiplier: 1.0, constant: -5))
        addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY,
                                         multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: stepper, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY,
                                         multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: valueLabel, attribute: .centerY, relatedBy: .equal, toItem: stepper, attribute: .centerY,
                                         multiplier: 1.0, constant: 0))
        //addConstraint(NSLayoutConstraint(item: textLabel, attribute: .centerY, relatedBy: .equal, toItem: stepper, attribute: .centerY,
        //                                 multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .height, relatedBy: .equal, toItem: stepper, attribute: .height,
                                         multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .width, relatedBy: .equal, toItem: stepper, attribute: .width,
                                         multiplier: 1.0, constant: 0))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func setup() {
        super.setup()
        selectionStyle = .none
        stepper.addTarget(self, action: #selector(FontPickerSubCell.valueChanged), for: .valueChanged)
        segmentedControl!.addTarget(self, action: #selector(FontPickerSubCell.valueChanged), for: .valueChanged)
    }
    
    deinit {
        stepper.removeTarget(self, action: nil, for: .allEvents)
    }
    
    open override func update() {
        super.update()
        detailTextLabel?.text = nil
        textLabel?.text = nil

        stepper.isEnabled = !row.isDisabled
        stepper.alpha = row.isDisabled ? 0.3 : 1.0
        segmentedControl!.isEnabled = !row.isDisabled
        segmentedControl!.alpha = row.isDisabled ? 0.3 : 1.0
        valueLabel?.textColor = tintColor
        valueLabel?.alpha = row.isDisabled ? 0.3 : 1.0

        if row.value != nil {
            stepper.value = row.value!.size
            valueLabel?.text = DecimalFormatter().string(from: NSNumber(value: row.value!.size))
            var selInxs:[Int] = []
            if row.value!.isBold { selInxs.append(0) }
            if row.value!.isItalic { selInxs.append(1) }
            segmentedControl!.selectedSegmentIndices = selInxs
        } else {
            stepper.value = 17.0
            valueLabel?.text = "17.0"
            segmentedControl!.selectedSegmentIndices = []
        }
    }
    
    @objc func valueChanged() {
        var newValue = FontPickerSubRowValue()
        newValue.size = stepper.value
        for aSegInx in segmentedControl!.selectedSegmentIndices {
            switch aSegInx {
            case 0:
                newValue.isBold = true
                break
            case 1:
                newValue.isItalic = true
                break
            default:
                break
            }
        }
        row.value = newValue
        row.updateCell()
    }
}

//  Adapted From:
//  PickerInlineRow.swift
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

public final class FontPickerInlineRow : _FontPickerInlineRow, RowType, InlineRowType {
    
    required public init(tag: String?) {
        super.init(tag: tag)
        
        onExpandInlineRow { cell, row, _ in
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            toggleInlineRow()
        }
    }
    
    public func setupInlineRow(_ inlineRow: InlineRow) {
        inlineRow.value = self.value
        inlineRow.cell.height = { UITableView.automaticDimension }
    }
}

open class _FontPickerInlineRow : Row<FontPickerInlineCell>, NoValueDisplayTextConformance {
    
    public typealias InlineRow = FontPickerRow
    open var noValueDisplayText: String?
    internal var systemFontName:String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
        
        self.value = UIFont.systemFont(ofSize: 17.0)
        self.systemFontName = UIFont.systemFont(ofSize: 17.0).familyName
        
        self.displayValueFor = { value in
            guard let value = value else { return nil }
            var familyName = value.familyName
            if familyName.starts(with: SystemFontPrefix) { familyName = "-System" }
            var styles:String = ""
            if value.isBold { styles = styles + "B" }
            if value.isItalic { styles = styles + "I" }
            return "\(familyName) \(styles) \(value.pointSize)"
        }
    }
    
    override open func updateCell() {
        super.updateCell()
        cell.detailTextLabel?.text = self.displayValueFor!(value)
        cell.selectionStyle = isDisabled ? .none : .default
    }
}

open class FontPickerInlineCell: Cell<UIFont>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func setup() {
        super.setup()
        accessoryType = .none
        editingAccessoryType =  .none
    }
    
    open override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
        self.detailTextLabel?.text = self.row.displayValueFor!(row.value)
    }
    
    open override func didSelect() {
        super.didSelect()
        row.deselect()
    }
}
