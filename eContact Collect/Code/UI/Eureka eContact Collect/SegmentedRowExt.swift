//  Adapted from:
//  SegmentedRow.swift
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

// MARK: SegmentedRowExt

public final class SegmentedRowExt<T: Hashable>: _SegmentedRowExt<T, SegmentedCellExt<T,Set<T>>>, RowType {
    private var cTag:String = "EuRSE"
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _SegmentedRowExt<T, Cell: CellType>: GenericMultipleSelectorRow<T, Cell> where Cell: BaseCell, Cell.Value == Set<T> {
    public var title2:String? = nil
    public var allowMultiSelect:Bool = false
    public var otherRowUponChoosingOptionCode:String? = nil
    public weak var otherRow:BaseRow? = nil {
        didSet {
            if otherRow != nil {
                otherRow!.callbackOnChange = { [weak self] in
                    // otherRow's value has changed; so get it
                    (self!.cell as! SegmentedCellExt<T,Set<T>>).segmentedControlChanged()    // need to do a deep rebuild of row.value
                }
            }
        }
    }
    public var otherRowShouldHide:Bool = true
    
    private var cTag:String = "EuR_SE"
    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .show(controllerProvider: ControllerProvider.callback { [weak self] in
            let nvc = MultipleSelectorExtViewController< GenericMultipleSelectorRow<T,Cell> >()
            nvc.isMultiSelect = (self as! SegmentedRowExt<T>).allowMultiSelect
            return nvc
            }, onDismiss: { vc in
                // perform anything needed before the PushRow returns
        })
    }
}

// MARK: SegmentedCellExt

open class SegmentedCellExt<Tb: Hashable, T: Hashable> : Cell<T>, CellType {
    private enum LayoutMode:Int { case Invalid = 0, OneLineStd, TwoLinesStd, TwoLinesNoMargin, PushRow }
    private var cTag:String = "EuCSE"
    
    @IBOutlet public weak var segmentedControl:MultiSelectionSegmentedControl?
    @IBOutlet public weak var titleLabel:UILabel?
    
    private var dynamicConstraints = [NSLayoutConstraint]()
    private var isMulti:Bool = false
    private var layoutMode:LayoutMode = .Invalid
    private var layoutModeBasisFrameSize:CGSize = CGSize.zero
    private var _height:CGFloat = 75.0
    private var verticalPad:Int = 10
    fileprivate var observingTitleText = false
    private var awakeFromNibCalled = false
    private var disableTarget:Bool = false
    
    // cell object instance initialization;
    // via Eureka this usually gets called first at tableView(...estimatedHeightForRowAt:...)
    //            then in Eureka via the cellProvider be set to its default
    // called if a NIB or Storyboard is NOT used; // this will only ever get called once for the life of the row object instance;
    // do NOT put here any initializations that need to be done for both NIB-created or Dynamic-created;
    // all in-Form override { $0.xxx = ... } will be performed immediately after this and before setup() below
    // note: the cell's row property has NOT yet been set; row-property dependent init's cannot be done
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//debugPrint("\(self.cTag).init STARTED tableViewCell.frame.size=\(self.frame.size) bounds=\(self.bounds.size)")
//debugPrint("\(self.cTag).init STARTED   contentView.frame.size=\(contentView.frame.size) bounds=\(contentView.bounds.size)")
        
        self.titleLabel = self.textLabel
        self.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        //self.titleLabel?.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        
        let segmentedControl = MultiSelectionSegmentedControl(items:nil)
        segmentedControl.frame = contentView.frame
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .horizontal)    // ensure the segmentControl grows
        segmentedControl.tintColor = UIColor.black
        segmentedControl.backgroundColor = UIColor.white
        segmentedControl.isHidden = true
        segmentedControl.isEnabled = false
        self.segmentedControl = segmentedControl
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let me = self else { return }
            guard me.observingTitleText else { return }
            me.titleLabel?.removeObserver(me, forKeyPath: "text")
            me.observingTitleText = false
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let me = self else { return }
            guard !me.observingTitleText else { return }
            me.titleLabel?.addObserver(me, forKeyPath: "text", options: [.new, .old], context: nil)
            me.observingTitleText = true
        }
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.titleLabel = self?.textLabel
            self?.setNeedsUpdateConstraints()
        }
        
        contentView.addSubview(self.titleLabel!)
        contentView.addSubview(self.segmentedControl!)

        titleLabel?.addObserver(self, forKeyPath: "text", options: [.old, .new], context: nil)
        observingTitleText = true
        imageView?.addObserver(self, forKeyPath: "image", options: [.old, .new], context: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        awakeFromNibCalled = true
    }
    
    deinit {
        segmentedControl?.removeTarget(self, action: nil, for: .allEvents)
        if !awakeFromNibCalled {
            if observingTitleText {
                titleLabel?.removeObserver(self, forKeyPath: "text")
            }
            imageView?.removeObserver(self, forKeyPath: "image")
            NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
        }
    }
    
    // called by Eureka immediately after init() and all in-Form overrides { $0.xxx = ... }
    // which means this normally is called during the larger iOS process at tableView(...estimatedHeightForRowAt:...)
    // this will only ever get called once for the life of the row object instance;
    // the cell's row property has been set; so row-property dependent init's need be done here;
    // (but only inits that cannot be changed by the Form mainline)
    open override func setup() {
//debugPrint("\(self.cTag).setup STARTED \(row.title!)")
        super.setup()
        selectionStyle = .none
        self.height = { [weak self] in
            if self == nil {
                return UITableView.automaticDimension
            } else if self!.layoutMode != .Invalid {
//debugPrint("\(self.cTag).height GET=\(self._height)")
                return self!._height
            } else {
//debugPrint("\(self.cTag).height GET=automaticDimension")
                return UITableView.automaticDimension
            }
        }
        
        let seRow:SegmentedRowExt<Tb> = row as! SegmentedRowExt<Tb>
        
        if seRow.allowMultiSelect {
            self.isMulti = true
        } else {
            segmentedControl?.singleSelectionMode = true
        }
        segmentedControl!.addTarget(self, action: #selector(SegmentedCellExt.segmentedControlChanged), for: .valueChanged)
    }
    
    // called for the first time by Eureka as a part of the TableView(...cellForRowAt:...) during initial TableViewCell creation;
    // it will also get called upon rotation; and will get called when the PushRow returns after pre-setting row.value;
    // however this is also called by the Form mainline whenever it or the Developer want a Row to be refreshed in terms of its
    // settings (title), contents (value), or display/configuration items; most configuration belongs here
    // the first time this is called by TableView(...cellForRowAt:...) the TableViewCell's frame, bounds, and contentView are NOT properly sized
    // iOS TableView scrolling and Eureka's implementation is buggy in regards to variable height cells; need to not perform relayouts unless utterly necessary
    open override func update() {
//debugPrint("\(self.cTag).update STARTED \(row.title!) row.value=\(row.value)")
        // these checks for invalidations must be peformed before super.update() call
        let seRow:SegmentedRowExt<Tb> = row as! SegmentedRowExt<Tb>
        var needRelayout:Bool = false

        // check the segmented control elements
        var inx:Int = 0
        if let sRow = row as? SegmentedRowExt<String> {
            if sRow.options?.count != segmentedControl!.numberOfSegments { needRelayout = true }
            else if segmentedControl!.numberOfSegments > 0 {
                sRow.options?.forEach {
                    let wantTitle:String = sRow.displayValueFor?(Set([$0])) ?? ""
                    let hasTitle:String = segmentedControl!.titleForSegmentAtIndex(inx)!
                    if hasTitle != wantTitle { needRelayout = true }
                    inx = inx + 1
                }
            }
        } else if let iRow = row as? SegmentedRowExt<UIImage> {
            if iRow.options?.count != segmentedControl!.numberOfSegments { needRelayout = true }
            else if segmentedControl!.numberOfSegments > 0 {
                iRow.options?.forEach {
                    let wantImage:UIImage = $0
                    let hasImage:UIImage = segmentedControl!.imageForSegment(at: inx)!
                    if hasImage != wantImage { needRelayout = true }
                    inx = inx + 1
                }
            }
        }

        if needRelayout {
            self.layoutMode = .Invalid
            self.layoutModeBasisFrameSize = CGSize.zero
//debugPrint("\(self.cTag).update NEED RELAYOUT INVOKED")
        }
        super.update()      // updateContraints() will get auto-called
//debugPrint("\(self.cTag).update POST-SUPER STARTED")

        // update the title of the row
        if !(seRow.title ?? "").isEmpty {
            if (seRow.title2 ?? "").isEmpty {
                self.textLabel!.numberOfLines = 1
                self.textLabel!.text = seRow.title!
            } else {
                self.textLabel!.numberOfLines = 2
                self.textLabel!.text = seRow.title! + "\n" + seRow.title2!
            }
        } else { self.textLabel!.text = nil }

        if needRelayout {
            // update the segmented control buttons
            segmentedControl!.removeAllSegments()
            if let sRow = row as? SegmentedRowExt<String> {
                sRow.options?.reversed().forEach {
                    let title:String = sRow.displayValueFor?(Set([$0])) ?? ""
                    segmentedControl!.insertSegment(title, at: 0, animated: false)
                }
            } else if let iRow = row as? SegmentedRowExt<UIImage> {
                iRow.options?.reversed().forEach {
                    segmentedControl!.insertSegment($0, at: 0, animated: false)
                }
            }
            self.relayout()
        }
        
        // these updates do not require a relayout
        // set the segmented control buttons according to the current state of the row.value; especially needed upon return from PushRow
        // if in single selection mode, only the first row.value will be used
        self.disableTarget = true
        self.segmentedControl!.selectedSegmentIndices = selectedIndexesFromValue() ?? []  // will trigger the .valueChanged Target
        self.disableTarget = false
        self.checkRowValueForOtherness(viaSegCtrl:false)

        // enable or disable the segmented control if the row is enabled or disabled
        self.segmentedControl!.isEnabled = !row.isDisabled
        
        // indicate any validation rule error
        if !(seRow.title ?? "").isEmpty {
            if !row.isValid { self.titleLabel!.textColor = UIColor.red }
            else if row.isHighlighted { self.titleLabel!.textColor = tintColor }
        }
        
//debugPrint("\(self.cTag).update ENDED")
    }
    
    // parse the row.value to get the proper button segment to enable
    func selectedIndexFromValue() -> Int? {
        if row.value == nil { return nil }
        if let sRow:SegmentedRowExt<String> = (row as? SegmentedRowExt<String>) {
            for v in sRow.value! {
                let inx:Int = sRow.options?.index(of: v) ?? -1
                if inx >= 0 { return inx }
            }
        } else if let iRow:SegmentedRowExt<UIImage> = (row as? SegmentedRowExt<UIImage>) {
            for v in iRow.value! {
                let inx:Int = iRow.options?.index(of: v) ?? -1
                if inx >= 0 { return inx }
            }
        }
        return nil
    }
    
    // parse the row.value to get the proper button segment(s) to enable
    func selectedIndexesFromValue() -> [Int]? {
        if row.value == nil { return nil }
        var indexes:[Int] = []
        if let sRow:SegmentedRowExt<String> = (row as? SegmentedRowExt<String>) {
            for v in sRow.value! {
                let inx:Int = sRow.options?.index(of: v) ?? -1
                if inx >= 0 { indexes.append(inx) }
            }
        } else if let iRow:SegmentedRowExt<UIImage> = (row as? SegmentedRowExt<UIImage>) {
            for v in iRow.value! {
                let inx:Int = iRow.options?.index(of: v) ?? -1
                if inx >= 0 { indexes.append(inx) }
            }
        }
        return indexes
    }
    
    // action trigger that the segmentedControl has changed its state
    @objc public func segmentedControlChanged() {
        if self.disableTarget { return }
        if let sRow:SegmentedRowExt<String> = (row as? SegmentedRowExt<String>) {
            var results:Set<String> = Set()
            for inx in self.segmentedControl!.selectedSegmentIndices {
                let str:String = (sRow.options?[inx])!
                results.insert(str)
            }
            sRow.value = results
        } else if let iRow:SegmentedRowExt<UIImage> = (row as? SegmentedRowExt<UIImage>) {
            var results:Set<UIImage> = Set()
            for inx in self.segmentedControl!.selectedSegmentIndices {
                let img:UIImage = (iRow.options?[inx])!
                results.insert(img)
            }
            iRow.value = results
        } else {
            row.value = nil
        }
//debugPrint("\(self.cTag).segmentedControlChanged new row.value=\(row.value)")
        self.checkRowValueForOtherness(viaSegCtrl:true)
    }
    
    private func checkRowValueForOtherness(viaSegCtrl:Bool) {
        let seRow:SegmentedRowExt<Tb> = row as! SegmentedRowExt<Tb>
        guard seRow.otherRow != nil, (seRow.otherRowUponChoosingOptionCode?.count ?? 0) > 0 else { return }
        
        if let sesRow:SegmentedRowExt<String> = (row as? SegmentedRowExt<String>) {
            var found:Bool = false
            if sesRow.value != nil {
                for v in sesRow.value! {
                    if v == sesRow.otherRowUponChoosingOptionCode {
//debugPrint("\(self.cTag).checkRowValueForOtherness FOUND")
                        found = true
                        //let title:String? = sesRow.displayValueFor?(Set([sesRow.otherRowUponChoosingOptionCode!]))
                        //if title != nil { sesRow.otherRow!.title = title }
                        sesRow.otherRowShouldHide = false
                        if viaSegCtrl { sesRow.otherRow!.evaluateHidden() }
                        //sesRow.value!.remove(sesRow.otherRowUponChoosingOptionCode!)
                        self.newOtherValue()
                        break
                    }
                }
            }
            if !found {
                sesRow.otherRowShouldHide = true
                if viaSegCtrl { sesRow.otherRow!.evaluateHidden() }
            }
        }
    }
    
    public func newOtherValue() {
        let seRow:SegmentedRowExt<Tb> = row as! SegmentedRowExt<Tb>
        guard seRow.otherRow != nil, (seRow.otherRowUponChoosingOptionCode?.count ?? 0) > 0 else { return }
        
        if let sesRow:SegmentedRowExt<String> = (row as? SegmentedRowExt<String>) {
            // include only basic types which are typical from FieldsRow varients
            if sesRow.otherRow!.baseValue != nil {
                let otherValues = sesRow.otherRow!.baseValue!
                if let otherValueString:String = otherValues as? String {
                    sesRow.value!.insert(otherValueString)
                } else if let otherValueInt:Int = otherValues as? Int {
                    sesRow.value!.insert(String(otherValueInt))
                } else if let otherValueDouble:Double = otherValues as? Double {
                    sesRow.value!.insert(String(otherValueDouble))
                } else if let otherValueURL:URL = otherValues as? URL {
                    sesRow.value!.insert(otherValueURL.absoluteString)
                }
            }
//debugPrint("\(self.cTag).newOtherValue new row.value=\(sesRow.value!)")
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // Layout the Cell's textFields and controls, and update constraints
    /////////////////////////////////////////////////////////////////////////
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let obj = object as AnyObject?
        
        if let changeType = change, let _ = keyPath, ((obj === titleLabel && keyPath == "text") || (obj === imageView && keyPath == "image")) &&
            (changeType[NSKeyValueChangeKey.kindKey] as? NSNumber)?.uintValue == NSKeyValueChange.setting.rawValue, !awakeFromNibCalled {
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
    }
    
    // decide the layout to be used given the options and given the TableViewCell sizes;
    // this will first get called during layoutSubview(); however this can get re-called if the TableViewCell size is changed
    private func relayout() {
        if self.frame.size.width == self.layoutModeBasisFrameSize.width {
            // frame size remains the same as last time; no need to re-layout
//debugPrint("\(self.cTag).relayout STARTED BUT self.frame.size.width == self.layoutModeBasisFrameSize.width so skip")
            return
        }

        let priorLayoutMode = self.layoutMode
        let seRow:SegmentedRowExt<Tb> = row as! SegmentedRowExt<Tb>
        self.segmentedControl!.apportionsSegmentWidthsByContent = false
        
        var newHeight:CGFloat = 0.0
        let marginWidth:CGFloat = self.frame.size.width - 40.0
        var availableWidth:CGFloat = marginWidth
        if !(seRow.title ?? "").isEmpty {
            if !(seRow.title2 ?? "").isEmpty {
                // dual line
                if self.titleLabel!.intrinsicContentSize.height <= 0 { newHeight = 60.0 }
                else { newHeight = self.titleLabel!.intrinsicContentSize.height }
            } else {
                // single line
                if self.titleLabel!.intrinsicContentSize.height <= 0 { newHeight = 30.0 }
                else { newHeight = self.titleLabel!.intrinsicContentSize.height }
            }
            availableWidth = availableWidth - self.titleLabel!.intrinsicContentSize.width - 5.0
        }
        
/*debugPrint("\(self.cTag).relayout intermediate newHeight=\(newHeight)")
debugPrint("\(self.cTag).relayout maxWidth=\(contentView.frame.size.width), marginWidth=\(marginWidth), availWidth=\(availableWidth)")
        
debugPrint("\(self.cTag).relayout titleLabel.frame.size=\(titleLabel!.frame.size) bounds=\(titleLabel!.bounds.size) ic=\(titleLabel!.intrinsicContentSize)")
debugPrint("\(self.cTag).relayout segmentedControl.frame.size=\(segmentedControl!.frame.size) bounds=\(segmentedControl!.bounds.size) ic=\(segmentedControl!.intrinsicContentSize)")
*/

        let fullWidth:CGFloat = segmentedControl!.intrinsicContentSize.width
        if fullWidth <= availableWidth {
            self.layoutMode = .OneLineStd
            self.segmentedControl?.isHidden = false
            self.segmentedControl?.isEnabled = true
            self.detailTextLabel?.isHidden = true
            self.accessoryType = .none
            let updateHeight:CGFloat = segmentedControl!.intrinsicContentSize.height + 1.0
            if updateHeight > newHeight { newHeight = updateHeight }
            newHeight = newHeight + (CGFloat(self.verticalPad) * 2.0)
        } else {
            segmentedControl!.apportionsSegmentWidthsByContent = true
            let apportWidth:CGFloat = segmentedControl!.intrinsicContentSize.width
//debugPrint("\(self.cTag).relayout apportioned segmentedControl.frame.size=\(segmentedControl!.frame.size) bounds=\(segmentedControl!.bounds.size) ic=\(segmentedControl!.intrinsicContentSize)")
            if apportWidth <= availableWidth {
                self.layoutMode = .OneLineStd
                self.segmentedControl?.isHidden = false
                self.segmentedControl?.isEnabled = true
                self.detailTextLabel?.isHidden = true
                self.accessoryType = .none
                let updateHeight:CGFloat = segmentedControl!.intrinsicContentSize.height + 1.0
                if updateHeight > newHeight { newHeight = updateHeight }
                newHeight = newHeight + (CGFloat(self.verticalPad) * 2.0)
            } else if fullWidth <= marginWidth {
                segmentedControl!.apportionsSegmentWidthsByContent = false
                self.layoutMode = .TwoLinesStd
                self.segmentedControl?.isHidden = false
                self.segmentedControl?.isEnabled = true
                self.detailTextLabel?.isHidden = true
                self.accessoryType = .none
                newHeight = newHeight + segmentedControl!.intrinsicContentSize.height + 6.0 + (CGFloat(self.verticalPad) * 2.0)
            } else if apportWidth <= marginWidth {
                self.layoutMode = .TwoLinesStd
                self.segmentedControl?.isHidden = false
                self.segmentedControl?.isEnabled = true
                self.detailTextLabel?.isHidden = true
                self.accessoryType = .none
                newHeight = newHeight + segmentedControl!.intrinsicContentSize.height + 6.0 + (CGFloat(self.verticalPad) * 2.0)
            } else if fullWidth <= contentView.frame.size.width {
                segmentedControl!.apportionsSegmentWidthsByContent = false
                self.layoutMode = .TwoLinesNoMargin
                self.segmentedControl?.isHidden = false
                self.segmentedControl?.isEnabled = true
                self.detailTextLabel?.isHidden = true
                self.accessoryType = .none
                newHeight = newHeight + segmentedControl!.intrinsicContentSize.height + 6.0 + (CGFloat(self.verticalPad) * 2.0)
            } else if apportWidth <= contentView.frame.size.width {
                self.layoutMode = .TwoLinesNoMargin
                self.segmentedControl?.isHidden = false
                self.segmentedControl?.isEnabled = true
                self.detailTextLabel?.isHidden = true
                self.accessoryType = .none
                newHeight = newHeight + segmentedControl!.intrinsicContentSize.height + 6.0 + (CGFloat(self.verticalPad) * 2.0)
            } else {
                self.layoutMode = .PushRow
                self.segmentedControl?.isHidden = true
                self.segmentedControl?.isEnabled = false
                self.detailTextLabel?.isHidden = false
                self.accessoryType = .disclosureIndicator
                newHeight = newHeight + (CGFloat(self.verticalPad) * 2.0)
            }
        }

//debugPrint("\(self.cTag).relayout layoutMode=\(self.layoutMode)")
        
        // calculate a final height estimate
        self.layoutModeBasisFrameSize = self.frame.size
        let intHeight:Int = Int(round(newHeight))
        self._height = CGFloat(intHeight)
        self.frame.size.height = self._height + 0.3
        contentView.frame.size.height = self._height
//debugPrint("\(self.cTag).relayout New Height contentView.frame.size=\(contentView.frame.size)")
        
        // just set that constraints and layout need updating, but do not trigger them yet
        if self.layoutMode != priorLayoutMode {
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }
    
    // iOS Auto-Layout system FIRST calls updateConstraints() so that proper contraints can be put into place before doing actual layout
    open override func updateConstraints() {
        guard !awakeFromNibCalled else {
            super.updateConstraints()
            return
        }
        
/*debugPrint("\(self.cTag).updateConstraints STARTED  tableViewCell.frame.size=\(self.frame.size) bounds=\(self.bounds.size)")
debugPrint("\(self.cTag).updateConstraints STARTED    contentView.frame.size=\(contentView.frame.size) bounds=\(contentView.bounds.size)")
debugPrint("\(self.cTag).updateConstraints             titleLabel.frame.size=\(titleLabel!.frame.size) bounds=\(titleLabel!.bounds.size) ic=\(titleLabel!.intrinsicContentSize)")
debugPrint("\(self.cTag).updateConstraints segmentedControl.frame.size=\(segmentedControl!.frame.size) bounds=\(segmentedControl!.bounds.size) ic=\(segmentedControl!.intrinsicContentSize)")
*/

        if self.layoutMode == .Invalid {
//debugPrint("\(self.cTag).updateConstraints STARTED BUT layoutMode == .Invalid so skipped")
            if self.dynamicConstraints.count > 0 {
                self.removeConstraints(self.dynamicConstraints)
                self.dynamicConstraints = []
            }
            super.updateConstraints()
            return
        }
        if self.frame.size.width != self.layoutModeBasisFrameSize.width {
            // frame size has changed from the prior layout descision; need to make a new layout decision
//debugPrint("\(self.cTag).updateConstraints STARTED BUT self.frame.size.width != self.layoutModeBasisFrameSize.width so do a relayout()")
            self.relayout()
        }
        
        if self.dynamicConstraints.count > 0 {
            self.removeConstraints(self.dynamicConstraints)
            self.dynamicConstraints = []
        }
        var views: [String: AnyObject] = [:]
        
        var hasTitleLabel:Bool = false
        //var hasTitleLabelHeight:CGFloat = 0.0
        if !(self.titleLabel?.text ?? "").isEmpty {
            hasTitleLabel = true
            //hasTitleLabelHeight = titleLabel!.frame.size.height
        }
        views["titleLabel"] = self.titleLabel
        views["segmentedControl"] = self.segmentedControl

        self.frame.size.height = self._height + 0.3
        contentView.frame.size.height = self._height
        
        if hasTitleLabel {
            switch self.layoutMode {
            case .Invalid:
                // do nothing
                break
            case .OneLineStd:
//debugPrint("\(self.cTag).updateConstraints SET OneLineStd H:|-[titleLabel]-5-[segmentedControl]-|, CenterY: titleLabel, segmentedControl")
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]-5-[segmentedControl]-|", options: [], metrics: nil, views:
                    views)
                 self.dynamicConstraints += [NSLayoutConstraint(item: self.titleLabel!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]
                self.dynamicConstraints += [NSLayoutConstraint(item: self.segmentedControl!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]
                break
            case .TwoLinesStd:
//debugPrint("\(self.cTag).updateConstraints SET TwoLinesNoMargin H:|-[titleLabel]-|, H:|-[segmentedControl]-|, V:|-0-[titleLabel]-0-[segmentedControl]-|")
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]-|", options: [], metrics: nil, views: views)
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[segmentedControl]-|", options: [], metrics: nil, views: views)
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[titleLabel]-0-[segmentedControl]-|", options: [], metrics: nil, views: views)
                break
            case .TwoLinesNoMargin:
//debugPrint("\(self.cTag).updateConstraints SET TwoLinesNoMargin H:|-[titleLabel]-|, H:|-0-[segmentedControl]-0-|, V:|-0-[titleLabel]-0-[segmentedControl]-|")
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]-|", options: [], metrics: nil, views: views)
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[segmentedControl]-0-|", options: [], metrics: nil, views: views)
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[titleLabel]-0-[segmentedControl]-|", options: [], metrics: nil, views: views)
                break
            case .PushRow:
//debugPrint("\(self.cTag).updateConstraints SET PushRow H:|-[titleLabel]")
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]", options: [], metrics: nil, views: views)
                self.dynamicConstraints += [NSLayoutConstraint(item: self.titleLabel!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]
                break
            }
        } else {
            switch self.layoutMode {
            case .Invalid:
                // do nothing
                break
            case .OneLineStd:
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[segmentedControl]-|", options: [], metrics: nil, views: views)
                self.dynamicConstraints += [NSLayoutConstraint(item: self.segmentedControl!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]
                break
            case .TwoLinesStd:
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[segmentedControl]-|", options: [], metrics: nil, views: views)
                self.dynamicConstraints += [NSLayoutConstraint(item: self.segmentedControl!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]
                break
            case .TwoLinesNoMargin:
                self.dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[segmentedControl]-0-|", options: [], metrics: nil, views: views)
                self.dynamicConstraints += [NSLayoutConstraint(item: self.segmentedControl!, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)]
                break
            case .PushRow:
                // no constraints
                break
            }
        }
        
        self.addConstraints(dynamicConstraints)
        super.updateConstraints()
    }
    
    // iOS Auto-Layout system SECOND calls layoutSubviews() after constraints are in-place and relative positions and sizes of all elements
    // have been decided by auto-layout
    open override func layoutSubviews() {
        super.layoutSubviews()
        
/*debugPrint("\(self.cTag).layoutSubviews STARTED  tableViewCell.frame.size=\(self.frame.size) bounds=\(self.bounds.size)")
debugPrint("\(self.cTag).layoutSubviews STARTED    contentView.frame.size=\(contentView.frame.size) bounds=\(contentView.bounds.size)")
debugPrint("\(self.cTag).layoutSubviews             titleLabel.frame.size=\(titleLabel!.frame.size) bounds=\(titleLabel!.bounds.size) ic=\(titleLabel!.intrinsicContentSize)")
debugPrint("\(self.cTag).layoutSubviews segmentedControl.frame.size=\(segmentedControl!.frame.size) bounds=\(segmentedControl!.bounds.size) ic=\(segmentedControl!.intrinsicContentSize)")
*/
        
        // perform a final relayout using the actual sizes of the contentView and bounds
        self.relayout()     // the function will decide if it needs to be re-performed or not
        
        if !self.awakeFromNibCalled {
            // As titleLabel is the textLabel, iOS may re-layout without updating constraints, for example:
            // swiping, showing alert or actionsheet from the same section.
            // thus we need forcing update to use customConstraints()
            // this can create a nasty loop if constraint failures cause a re-invoke of layoutSubviews()
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
    }
}

/// Selector Controller that enables either single or multiple selection
open class MultipleSelectorExtViewController<OptionsRow: OptionsProviderRow>: MultipleSelectorViewController<OptionsRow> where OptionsRow.OptionsProviderType.Option: Hashable{
    
    public var isMultiSelect:Bool = false
    public var single_enableDeselection:Bool = true
    public var single_dismissOnSelection:Bool = true
    public var single_dismissOnChange:Bool = true
    private var cTag:String = "EUVCMSE"
    
    override public init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil
        {
            self.onDismissCallback?(self)
        }
    }

    override open func setupForm() {
//debugPrint("\(self.cTag).setupForm STARTED")
        let optProvider = optionsProviderRow.optionsProvider
        optProvider?.options(for: self) { [weak self] (options: [OptionsRow.OptionsProviderType.Option]?) in
            guard let strongSelf = self, let options = options else { return }
            strongSelf.optionsProviderRow.cachedOptionsData = options
            strongSelf.setupForm(with: options)
        }
    }
    
    override open func setupForm(with options: [OptionsRow.OptionsProviderType.Option]) {
        if let optionsBySections = optionsBySections(with: options) {
            for (sectionKey, options) in optionsBySections {
                form +++ overrideSection(with: options,
                                 header: sectionHeaderTitleForKey?(sectionKey),
                                 footer: sectionFooterTitleForKey?(sectionKey))
            }
        } else {
            form +++ overrideSection(with: options, header: row.title, footer: nil)
        }
    }
    
    func overrideSection(with options: [OptionsRow.OptionsProviderType.Option], header: String?, footer: String?) -> SelectableSection<ListCheckRow<OptionsRow.OptionsProviderType.Option>> {
        var section:SelectableSection<ListCheckRow<OptionsRow.OptionsProviderType.Option>>
        if self.isMultiSelect {
            section = SelectableSection<ListCheckRow<OptionsRow.OptionsProviderType.Option>>(header: header ?? "", footer: footer ?? "", selectionType: .multipleSelection) { section in
                section.onSelectSelectableRow = {  [weak self] _, selectableRow in
                    var newValue: Set<OptionsRow.OptionsProviderType.Option> = self?.row.value ?? []
                    if let selectableValue = selectableRow.value {
                        newValue.insert(selectableValue)
                    } else {
                        newValue.remove(selectableRow.selectableValue!)
                    }
                    self?.row.value = newValue
                }
            }
        } else {
            section = SelectableSection<ListCheckRow<OptionsRow.OptionsProviderType.Option>>(header: header ?? "", footer: footer ?? "", selectionType: .singleSelection(enableDeselection: single_enableDeselection)) { section in
                section.onSelectSelectableRow = { [weak self] _, selectableRow in
                    var newValue: Set<OptionsRow.OptionsProviderType.Option> = []
                    if let selectableValue = selectableRow.value {
                        newValue.insert(selectableValue)
                    }
                    let changed = self?.row.value != newValue
                    self?.row.value = newValue
                    
                    if let form = selectableRow.section?.form {
                        for section in form where section !== selectableRow.section {
                            let section = section as Any as! SelectableSection<ListCheckRow<OptionsRow.OptionsProviderType.Option>>
                            if let selectedRow = section.selectedRow(), selectedRow !== selectableRow {
                                selectedRow.value = nil
                                selectedRow.updateCell()
                            }
                        }
                    }
                    
                    if self?.single_dismissOnSelection == true || (changed && self?.single_dismissOnChange == true) {
                        self?.onDismissCallback?(self!)
                    }
                }
            }
        }
        
        for option in options {
            section <<< ListCheckRow.init { lrow in
                lrow.title = String(describing: option)
                lrow.selectableValue = option
                lrow.value = self.row.value?.contains(option) ?? false ? option : nil
                self.selectableRowSetup?(lrow)
                }.cellSetup { [weak self] cell, row in
                    self?.selectableRowCellSetup?(cell, row)
                }.cellUpdate { [weak self] cell, row in
                    self?.selectableRowCellUpdate?(cell, row)
            }
        }
        return section
    }
}

