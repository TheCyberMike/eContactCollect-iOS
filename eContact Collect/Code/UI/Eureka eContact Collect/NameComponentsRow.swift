//
//  NameComponentsRow.swift
//  Eureka
//
//  Created by Yo on 11/4/18.
//

// struct holding the return values for a NameComponentsRow
public struct NameComponentsValues {
    public var nameHonorPrefix: String?
    public var nameFirst: String?
    public var nameMiddle: String?
    public var nameLast: String?
    public var nameHonorSuffix: String?
}

/*public func == (lhs: NameComponentsValues, rhs: NameComponentsValues) -> Bool {
    return lhs.nameHonorPrefix == rhs.nameHonorPrefix && lhs.nameFirst == rhs.nameFirst && lhs.nameMiddle == rhs.nameMiddle && lhs.nameLast == rhs.nameLast && lhs.nameHonorSuffix == rhs.nameHonorSuffix
}*/

// the following fields can selectively be shown by this Row;
// their tags, formatters, and placeholders can optionally be set or overriden
// fields are composed and shown in the order presented below (shown ordering cannot be changed)
public struct NameComponentsShown {
    public var nameHonorPrefix = NameHonorPrefix()
    public var nameFirst = NameFirst()
    public var nameMiddle = NameMiddle()
    public var nameLast = NameLast()
    public var nameHonorSuffix = NameHonorSuffix()
    
    public struct NameHonorPrefix {
        public var shown:Bool = true
        public var tag:String? = "NamePrefix"
        public var placeholder:String? = "Prefix"
        public var formatter:Formatter? = nil
        public var namePrefixCodes:[CodePair]? = nil
        public var retainObject:Any? = nil
    }
    public struct NameFirst {
        public var shown:Bool = true
        public var tag:String? = "NameFirst"
        public var placeholder:String? = "First"
        public var formatter:Formatter? = nil
    }
    public struct NameMiddle {
        public var shown:Bool = true
        public var tag:String? = "NameMiddle"
        public var placeholder:String? = "Middle"
        public var onlyMiddleInitial:Bool = false
        public var formatter:Formatter? = nil
    }
    public struct NameLast {
        public var shown:Bool = true
        public var tag:String? = "NameLast"
        public var placeholder:String? = "Last"
        public var formatter:Formatter? = nil
    }
    public struct NameHonorSuffix {
        public var shown:Bool = true
        public var tag:String? = "NameSuffix"
        public var placeholder:String? = "Suffix"
        public var formatter:Formatter? = nil
        public var nameSuffixCodes:[CodePair]? = nil
        public var retainObject:Any? = nil
    }
    
    public init() {}
    
    public func requiresRelayout(comparedTo:NameComponentsShown) -> Bool {
        if  self.nameHonorPrefix.shown != comparedTo.nameHonorPrefix.shown ||
            self.nameFirst.shown != comparedTo.nameFirst.shown ||
            self.nameMiddle.shown != comparedTo.nameMiddle.shown ||
            self.nameLast.shown != comparedTo.nameLast.shown ||
            self.nameHonorSuffix.shown != comparedTo.nameHonorSuffix.shown ||
            self.nameMiddle.onlyMiddleInitial != comparedTo.nameMiddle.onlyMiddleInitial { return true }
        return false
    }
}

// Base class row for Eureka
public final class NameComponentsRow: _NameComponentsRow, RowType {
    private var cTag:String = "EuRNC"
    
    required public init(tag: String?) {
        super.init(tag: tag)
        // set the cellProvider to default (which means the fields are constructed by the Cell
        //cellProvider = CellProvider<nameComponentsCell>()
    }
}

// Subclass row for Eureka
open class _NameComponentsRow : Row<NameComponentsCell> {
    private var cTag:String = "EuR_NC"
    public var title2:String? = nil
    
    open var nameComponentsShown:NameComponentsShown {
        set (newValue) {
            let needsRelayout:Bool = _nameComponentsShown.requiresRelayout(comparedTo: newValue)
            _nameComponentsShown = newValue
            if _cell != nil && needsRelayout {
                cell.relayout()
                updateCell()
            }
        }
        get {
            return _nameComponentsShown
        }
    }
    open var nameComponentsValues:NameComponentsValues {
        set (newValue) {
            _nameComponentsValues = newValue
            super.value = self.makeValues()
            if _cell != nil { updateCell() }
        }
        get {
            return _nameComponentsValues
        }
    }
    
    override open var value:[String:String?]? {
        set (newValue) {
            self.extractFromValues(values: newValue)
            super.value = newValue
        }
        get {
            return super.value
        }
    }
    
    open var countryCodeFinishedEditing:((NameComponentsCell, _NameComponentsRow) -> Void) = { _,_ in }
    
    internal var _nameComponentsShown:NameComponentsShown = NameComponentsShown()
    internal var _nameComponentsValues:NameComponentsValues = NameComponentsValues()
    
    required public init(tag: String?) {
        super.init(tag: tag)
        super.value = self.makeValues()
    }
    
    override open func beingRemovedFromForm() {
        cell.beingRemovedFromForm()
        super.beingRemovedFromForm()
    }
    
    // make the "value" [String:String?] pairs for all the current values in the row
    internal func makeValues() -> [String:String?]  {
        var result:[String:String?] = [String:String?]()
        if self._nameComponentsShown.nameHonorPrefix.shown {
            result[self._nameComponentsShown.nameHonorPrefix.tag ?? "NamePrefix"] = _nameComponentsValues.nameHonorPrefix
        }
        if self._nameComponentsShown.nameFirst.shown {
            result[self._nameComponentsShown.nameFirst.tag ?? "NameFirst"] = _nameComponentsValues.nameFirst
        }
        if self._nameComponentsShown.nameMiddle.shown {
            result[self._nameComponentsShown.nameMiddle.tag ?? "NameMiddle"] = _nameComponentsValues.nameMiddle
        }
        if self._nameComponentsShown.nameLast.shown {
            result[self._nameComponentsShown.nameLast.tag ?? "NameLast"] = _nameComponentsValues.nameLast
        }
        if self._nameComponentsShown.nameHonorSuffix.shown {
            result[self._nameComponentsShown.nameHonorSuffix.tag ?? "NameSuffix"] = _nameComponentsValues.nameHonorSuffix
        }
        
        return result
    }
    
    // extract the current values from pairs or a single pair
    private func extractFromValues(values:[String:String?]?) {
        if values == nil {
            _nameComponentsValues.nameHonorPrefix = nil
            _nameComponentsValues.nameFirst = nil
            _nameComponentsValues.nameMiddle = nil
            _nameComponentsValues.nameLast = nil
            _nameComponentsValues.nameHonorSuffix = nil
        } else {
            _nameComponentsValues.nameHonorPrefix = values![self._nameComponentsShown.nameHonorPrefix.tag ?? "NamePrefix"] as? String
            _nameComponentsValues.nameFirst = values![self._nameComponentsShown.nameFirst.tag ?? "Apt/NameFirst"] as? String
            _nameComponentsValues.nameMiddle = values![self._nameComponentsShown.nameMiddle.tag ?? "NameMiddle"] as? String
            _nameComponentsValues.nameLast = values![self._nameComponentsShown.nameLast.tag ?? "NameLast"] as? String
            _nameComponentsValues.nameHonorSuffix = values![self._nameComponentsShown.nameHonorSuffix.tag ?? "NameSuffix"] as? String
        }
    }
}

// Base class cell for Eureka
public class NameComponentsCell: Cell<[String:String?]>, CellType, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    private var cTag:String = "EuCAC"
    
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var namePrefixTextField: UITextField?
    @IBOutlet public weak var nameFirstTextField: UITextField?
    @IBOutlet public weak var nameMiddleTextField: UITextField?
    @IBOutlet public weak var nameLastTextField: UITextField?
    @IBOutlet public weak var nameSuffixTextField: UITextField?
    
    internal var setupCompleted:Bool = false
    private var awakeFromNibInvoked:Bool = false
    private var _height:CGFloat = 46.0
    private var verticalPad:Int = 10
    open var textFieldTabOrder:[UITextField] = []
    private var composedLayout:ComposedLayout = ComposedLayout(contentView: nil, row: nil, cellHasManualHeight: true)
    private var dynamicConstraints = [NSLayoutConstraint]()
    
    lazy public var prefixPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.tag = 4006
        picker.delegate = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    lazy public var suffixPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.tag = 4007
        picker.delegate = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    // cell object instance initialization;
    // via Eureka this usually gets called first at tableView(...estimatedHeightForRowAt:...)
    //            then in Eureka via the cellProvider be set to its default
    // called if a NIB or Storyboard is NOT used; // this will only ever get called once for the life of the row object instance;
    // do NOT put here any initializations that need to be done for both NIB-created or Dynamic-created;
    // all in-Form override { $0.xxx = ... } will be performed immediately after this and before setup() below
    // note: the cell's row property has NOT yet been set; row-property dependent init's cannot be done
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // create all the UI object that are needed
        self.titleLabel = self.textLabel
        self.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel?.setContentHuggingPriority(UILayoutPriority.hugPriTextLabel, for: .horizontal)
        self.titleLabel?.setContentCompressionResistancePriority(UILayoutPriority.compressPriMoreLikely, for: .horizontal)
        
        let tf1 = UITextField()
        self.namePrefixTextField = tf1
        
        let tf2 = UITextField()
        self.nameFirstTextField = tf2
        
        let tf3 = UITextField()
        self.nameMiddleTextField = tf3
        
        let tf4 = UITextField()
        self.nameLastTextField = tf4
        
        let tf5 = UITextField()
        self.nameSuffixTextField = tf5
        
        // for convenience place all the fields for now in the tab order
        // pre-setup all the text field's; they can be overriden later by user of in-Form overrides
        self.contentView.addSubview(titleLabel!)
        self.textFieldTabOrder = [self.namePrefixTextField!, self.nameFirstTextField!, self.nameMiddleTextField!, self.nameLastTextField!, self.nameSuffixTextField!]
        for textField in self.textFieldTabOrder {
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.setContentHuggingPriority(UILayoutPriority.hugPriStandardField, for: .horizontal)
            textField.borderStyle = UITextField.BorderStyle.bezel
            textField.autocapitalizationType = .words
            textField.textAlignment = .left
            textField.clearButtonMode = .never
            textField.isHidden = true
            textField.isEnabled = false
            textField.delegate = self
            textField.font = .preferredFont(forTextStyle: UIFont.TextStyle.body)
            textField.addTarget(self, action: #selector(NameComponentsCell.textFieldDidChange(_:)), for: .editingChanged)
            self.contentView.addSubview(textField)
        }
        self.namePrefixTextField!.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
        self.nameSuffixTextField!.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
        
        if #available(iOSApplicationExtension 10.0, *) {
            self.namePrefixTextField?.textContentType = .namePrefix
            self.nameFirstTextField?.textContentType = .givenName
            self.nameMiddleTextField?.textContentType = .middleName
            self.nameLastTextField?.textContentType = .familyName
            self.nameSuffixTextField?.textContentType = .nameSuffix
        }
        
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.relayout()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // our contentView layout was provided by NIB rather than to-be-built dynamically
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.awakeFromNibInvoked = true
    }
    
    public func beingRemovedFromForm() {
        self.composedLayout.clear()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    // called by Eureka immediately after init() and all in-Form overrides { $0.xxx = ... }
    // which means this normally is called during the larger iOS process at tableView(...estimatedHeightForRowAt:...)
    // this will only ever get called once for the life of the row object instance;
    // the cell's row property has been set; so row-property dependent init's need be done here;
    // (but only inits that cannot be changed by the Form mainline)
    public override func setup() {
        super.setup()
        
        self.composeLayout(fieldsHeight: 0.0)
        
        accessoryView = nil
        height = { return self._height }
        
        self.setupCompleted = true
    }
    
    // called for the first time by Eureka as a part of the TableView(...cellForRowAt:...) during initial TableViewCell creation;
    // it will also get called upon rotation;
    // however this is also called by the Form mainline whenever it or the Developer want a Row to be refreshed in terms of its
    // settings (title), contents (value), or display/configuration items; most configuration belongs here
    // the first time this is called by TableView(...cellForRowAt:...) the TableViewCell's frame, bounds, and contentView are NOT properly sized
    // iOS TableView scrolling and Eureka's implementation is buggy in regards to variable height cells; need to not perform relayouts unless utterly necessary
    public override func update() {
        super.update()
        let nameRow = self.row as! _NameComponentsRow
        var potentialLayoutChanges:Bool = false
        
        detailTextLabel?.text = nil
        textLabel?.text = nil
        
        if (row.title ?? "").isEmpty {
            if self.titleLabel!.text != nil { potentialLayoutChanges = true }
            self.titleLabel!.text = nil
        } else {
            if (nameRow.title2 ?? "").isEmpty {
                if self.titleLabel!.text != row.title! || self.titleLabel!.numberOfLines != 1 { potentialLayoutChanges = true }
                self.titleLabel!.numberOfLines = 1
                self.titleLabel!.text = row.title!
            } else {
                if self.titleLabel!.text != row.title! + "\n" + nameRow.title2! || self.titleLabel!.numberOfLines != 2 { potentialLayoutChanges = true }
                self.titleLabel!.numberOfLines = 2
                self.titleLabel!.text = row.title! + "\n" + nameRow.title2!
            }
            if !row.isValid { self.titleLabel!.textColor = UIColor.red }
            else if row.isHighlighted { self.titleLabel!.textColor = tintColor }
        }
        
        if nameRow._nameComponentsShown.nameHonorPrefix.shown {
            self.namePrefixTextField?.text = nameRow._nameComponentsValues.nameHonorPrefix
            if !(nameRow._nameComponentsShown.nameHonorPrefix.placeholder ?? "").isEmpty {
                self.namePrefixTextField?.placeholder = nameRow._nameComponentsShown.nameHonorPrefix.placeholder!
            }
        }
        if nameRow._nameComponentsShown.nameFirst.shown {
            self.nameFirstTextField?.text = nameRow._nameComponentsValues.nameFirst
            if !(nameRow._nameComponentsShown.nameFirst.placeholder ?? "").isEmpty {
                self.nameFirstTextField?.placeholder = nameRow._nameComponentsShown.nameFirst.placeholder!
            }
        }
        if nameRow._nameComponentsShown.nameMiddle.shown {
            self.nameMiddleTextField?.text = nameRow._nameComponentsValues.nameMiddle
            if !(nameRow._nameComponentsShown.nameMiddle.placeholder ?? "").isEmpty {
                self.nameMiddleTextField?.placeholder = nameRow._nameComponentsShown.nameMiddle.placeholder!
            }
        }
        if nameRow._nameComponentsShown.nameLast.shown {
            self.nameLastTextField?.text = nameRow._nameComponentsValues.nameLast
            if !(nameRow._nameComponentsShown.nameLast.placeholder ?? "").isEmpty {
                self.nameLastTextField?.placeholder = nameRow._nameComponentsShown.nameLast.placeholder!
            }
        }
        if nameRow._nameComponentsShown.nameHonorSuffix.shown {
            self.nameSuffixTextField?.text = nameRow._nameComponentsValues.nameHonorSuffix
            if !(nameRow._nameComponentsShown.nameHonorSuffix.placeholder ?? "").isEmpty {
                self.nameSuffixTextField?.placeholder = nameRow._nameComponentsShown.nameHonorSuffix.placeholder!
            }
        }
        
        if nameRow._nameComponentsShown.nameHonorPrefix.shown && (nameRow._nameComponentsShown.nameHonorPrefix.namePrefixCodes?.count ?? 0) > 0 {
            self.namePrefixTextField?.inputView = self.prefixPicker
        } else {
            self.namePrefixTextField?.inputView = nil
        }
        
        if nameRow._nameComponentsShown.nameHonorSuffix.shown && (nameRow._nameComponentsShown.nameHonorSuffix.nameSuffixCodes?.count ?? 0) > 0 {
            self.nameSuffixTextField?.inputView = self.suffixPicker
        } else {
            self.nameSuffixTextField?.inputView = nil
        }
        
        if potentialLayoutChanges { self.relayout() }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Name Honor Prefix and Suffix code picker handlers
    /////////////////////////////////////////////////////////////////////////
    
    open func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let nameRow = self.row as! _NameComponentsRow
        if pickerView.tag == 4006 {
            return nameRow.nameComponentsShown.nameHonorPrefix.namePrefixCodes?.count ?? 0
        } else if pickerView.tag == 4007 {
            return nameRow.nameComponentsShown.nameHonorSuffix.nameSuffixCodes?.count ?? 0
        }
        return 0
        
    }
    
    open func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let nameRow = self.row as! _NameComponentsRow
        if pickerView.tag == 4006 {
            guard (nameRow.nameComponentsShown.nameHonorPrefix.namePrefixCodes?.count ?? 0) > 0 else {
                return nil
            }
            return nameRow.nameComponentsShown.nameHonorPrefix.namePrefixCodes![row].valueString + " (" + nameRow.nameComponentsShown.nameHonorPrefix.namePrefixCodes![row].codeString + ")"
        } else if pickerView.tag == 4007 {
            guard (nameRow.nameComponentsShown.nameHonorSuffix.nameSuffixCodes?.count ?? 0) > 0 else {
                return nil
            }
            return nameRow.nameComponentsShown.nameHonorSuffix.nameSuffixCodes![row].valueString + " (" + nameRow.nameComponentsShown.nameHonorSuffix.nameSuffixCodes![row].codeString + ")"
        }
        return nil
    }
    
    open func pickerView(_ pickerView: UIPickerView, didSelectRow rowNumber: Int, inComponent component: Int) {
        let nameRow = self.row as! _NameComponentsRow
        if pickerView.tag == 4006 {
            guard (nameRow.nameComponentsShown.nameHonorPrefix.namePrefixCodes?.count ?? 0) > 0 else {
                return
            }
            nameRow._nameComponentsValues.nameHonorPrefix = nameRow.nameComponentsShown.nameHonorPrefix.namePrefixCodes![rowNumber].codeString
            update()
        } else if pickerView.tag == 4007 {
            guard (nameRow.nameComponentsShown.nameHonorSuffix.nameSuffixCodes?.count ?? 0) > 0 else {
                return
            }
            nameRow._nameComponentsValues.nameHonorSuffix = nameRow.nameComponentsShown.nameHonorSuffix.nameSuffixCodes![rowNumber].codeString
            update()
        }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Layout the Cell's textFields and controls, and update constraints
    /////////////////////////////////////////////////////////////////////////
    
    // called whenever all the fields should be positioned (either first time or because nameComponentsShown was changed or because of rotation);
    // this is called BEFORE update() above;  constraint updating after this relayout will occur during layoutSubviews() which is iOS invoked
    internal func relayout() {
//debugPrint("\(self.cTag).relayout STARTED contentView.frame.size=\(contentView.frame.size)")
        let nameRow = self.row as! _NameComponentsRow

//debugPrint("\(self.cTag).relayout titleLabel.size=\(self.titleLabel!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout namePrefixTextField.size=\(self.namePrefixTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout nameFirstTextField.size=\(self.nameFirstTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout nameMiddleTextField.size=\(self.nameMiddleTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout nameLastTextField.size=\(self.nameLastTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout nameSuffixTextField.size=\(self.nameSuffixTextField!.layer.frame.size)")
        
        
        var fieldsHeight:CGFloat = 0.0
        self.textFieldTabOrder = []
        if nameRow._nameComponentsShown.nameHonorPrefix.shown {
            if self.namePrefixTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.namePrefixTextField!.layer.frame.size.height }
            self.namePrefixTextField?.isHidden = false
            self.namePrefixTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.namePrefixTextField!)
        } else { self.namePrefixTextField?.isHidden = true; self.namePrefixTextField?.isEnabled = false }
        if nameRow._nameComponentsShown.nameFirst.shown {
            if self.nameFirstTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.nameFirstTextField!.layer.frame.size.height }
            self.nameFirstTextField?.isHidden = false
            self.nameFirstTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.nameFirstTextField!)
        } else { self.nameFirstTextField?.isHidden = true; self.nameFirstTextField?.isEnabled = false }
        if nameRow._nameComponentsShown.nameMiddle.shown {
            if self.nameMiddleTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.nameMiddleTextField!.layer.frame.size.height }
            self.nameMiddleTextField?.isHidden = false
            self.nameMiddleTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.nameMiddleTextField!)
        } else { self.nameMiddleTextField?.isHidden = true; self.nameMiddleTextField?.isEnabled = false }
        if nameRow._nameComponentsShown.nameLast.shown {
            if self.nameLastTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.nameLastTextField!.layer.frame.size.height }
            self.nameLastTextField?.isHidden = false
            self.nameLastTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.nameLastTextField!)
        } else { self.nameLastTextField?.isHidden = true; self.nameLastTextField?.isEnabled = false }
        if nameRow._nameComponentsShown.nameHonorSuffix.shown {
            if self.nameSuffixTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.nameSuffixTextField!.layer.frame.size.height }
            self.nameSuffixTextField?.isHidden = false
            self.nameSuffixTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.nameSuffixTextField!)
        } else { self.nameSuffixTextField?.isHidden = true; self.nameSuffixTextField?.isEnabled = false }
        
        self.composeLayout(fieldsHeight: fieldsHeight)
        
        var newHeight:CGFloat = 0.0
        if !(nameRow.title ?? "").isEmpty {
            newHeight = self.composedLayout.getTitlesBoundsSize().height
        } else { self.textLabel!.text = nil }
        
        if self.composedLayout.linesCount() > 0 && fieldsHeight > 0.0 {
            let workHeight:CGFloat = self.composedLayout.getFieldsBoundsSize().height
            if workHeight > newHeight { newHeight = workHeight }
        }
        
        // calculate a final height estimate
        if self._height != newHeight { setNeedsLayout() }   // force the tableview to know this cell's height needs changing
        self._height = newHeight
        contentView.frame.size.height = self.height!()
//debugPrint("\(self.cTag).relayout New Height contentView.frame.size=\(contentView.frame.size)")
        
        // just set that constraints need updating, but do not trigger that yet
        setNeedsUpdateConstraints()
    }
    
    // compose the dynamic layout
    private func composeLayout(fieldsHeight:CGFloat) {
        let nameRow = self.row as! _NameComponentsRow
        let newComposedLayout = ComposedLayout(contentView: self.contentView, row: row, cellHasManualHeight: true, titleAreaRatioWidthToMove: 0.2)

        if !(nameRow.title ?? "").isEmpty {
            newComposedLayout.addTextTitleFirstControl(forControl: ComposedLayoutControl(controlName: "titleLabel", control: self.titleLabel!))
        }
        
        // first line;
        if nameRow._nameComponentsShown.nameHonorPrefix.shown {
            let nameHonorPrefixCLC = ComposedLayoutControl(controlName: "namePrefixTextField", control: self.namePrefixTextField!, isFixedWidthOrLess: true)
            newComposedLayout.addControlToCurrentLine(forControl: nameHonorPrefixCLC)
        }
        if nameRow._nameComponentsShown.nameFirst.shown {
            newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "nameFirstTextField", control: self.nameFirstTextField!))
        }
        if nameRow._nameComponentsShown.nameMiddle.shown {
            if nameRow._nameComponentsShown.nameMiddle.onlyMiddleInitial {
                let nameMiddleCLC = ComposedLayoutControl(controlName: "nameMiddleTextField", control: self.nameMiddleTextField!, isFixedWidthOrLess: true)
                newComposedLayout.addControlToCurrentLine(forControl: nameMiddleCLC)
            } else {
                let nameMiddleCLC = ComposedLayoutControl(controlName: "nameMiddleTextField", control: self.nameMiddleTextField!)
                newComposedLayout.moveToNextLine()
                newComposedLayout.addControlToCurrentLine(forControl: nameMiddleCLC)
            }
        }
        
        // second line
        newComposedLayout.moveToNextLine()
        if nameRow._nameComponentsShown.nameLast.shown {
            newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "nameLastTextField", control: self.nameLastTextField!))
        }
        if nameRow._nameComponentsShown.nameHonorSuffix.shown {
            let nameHonorSuffixCLC = ComposedLayoutControl(controlName: "nameSuffixTextField", control: self.nameSuffixTextField!, isFixedWidthOrLess: true)
            newComposedLayout.addControlToCurrentLine(forControl: nameHonorSuffixCLC)
        }
        newComposedLayout.done()
        let _ = newComposedLayout.assessTitleMove(contentView: contentView, noBottomsOrEnds: (fieldsHeight == 0.0))
        
        // only replace the composedLayout if it has changed; this is necessary to prevent infinite loops with doing auto-title moving
        if self.composedLayout.isEmpty() {
            self.composedLayout = newComposedLayout
            setNeedsUpdateConstraints()
        } else if self.composedLayout != newComposedLayout {
            self.composedLayout = newComposedLayout
            setNeedsUpdateConstraints()
        }
    }
    
    // iOS Auto-Layout system FIRST calls updateConstraints() so that proper contraints can be put into place before doing actual layout
    open override func updateConstraints() {
//debugPrint("\(self.cTag).updateConstraints STARTED contentView.frame.size=\(contentView.frame.size), bounds=\(bounds.size)")
        if self.awakeFromNibInvoked {
            // since the NIB did the layout and the contraints, we do nothing dynamically
            super.updateConstraints()
            return
        }
        
        // remove all existing dynamic contraints and prepare
        contentView.removeConstraints(self.dynamicConstraints)
        self.dynamicConstraints = []
        let nameRow = self.row as! _NameComponentsRow
        var views:[String: AnyObject] = [:]
        
        // build up the necessary pre-information depending on what is supposed to be shown
        var fieldsWidth:CGFloat = contentView.frame.size.width - 40.0
        var titleHeight:CGFloat = 0.0
        var hasTitleLines = 0
        if !(nameRow.title ?? "").isEmpty {
            if titleLabel!.layer.frame.size.height > titleHeight { titleHeight = titleLabel!.layer.frame.size.height }
//debugPrint("\(self.cTag).updateConstraints titleLabel.frame.size=\(titleLabel!.layer.frame.size)")
            fieldsWidth = fieldsWidth - titleLabel!.layer.frame.size.width - 5.0
            if (nameRow.title2 ?? "").isEmpty { hasTitleLines = 1 }
            else { hasTitleLines = 2 }
        }
        
        var fieldsHeight:CGFloat = 0.0
        if self.namePrefixTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.namePrefixTextField!.layer.frame.size.height }
        if self.nameFirstTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.nameFirstTextField!.layer.frame.size.height }
        if self.nameMiddleTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.nameMiddleTextField!.layer.frame.size.height }
        if self.nameLastTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.nameLastTextField!.layer.frame.size.height }
        if self.nameSuffixTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.nameSuffixTextField!.layer.frame.size.height }
        
        // got anything to create?
        if hasTitleLines == 0 && (self.composedLayout.linesCount() == 0 || self.composedLayout.controlsCount(inLine: 0) <= 0)  { return }
        
        // yes, generate the bulk of the constraints
        (views, self.dynamicConstraints) = self.composedLayout.generateDynamicConstraints(contentView: contentView, noBottomsOrEnds: (fieldsHeight == 0.0))
        
        // additional specific constraints
        if nameRow._nameComponentsShown.nameHonorPrefix.shown {
            self.dynamicConstraints += [NSLayoutConstraint(item: self.namePrefixTextField!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 75)]
        }
        if nameRow._nameComponentsShown.nameHonorSuffix.shown {
            self.dynamicConstraints += [NSLayoutConstraint(item: self.nameSuffixTextField!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 75)]
        }
        if nameRow._nameComponentsShown.nameMiddle.onlyMiddleInitial {
            self.nameMiddleTextField!.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
            self.dynamicConstraints += [NSLayoutConstraint(item: self.nameMiddleTextField!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)]
        } else {
            self.nameMiddleTextField!.setContentHuggingPriority(UILayoutPriority.hugPriStandardField, for: .horizontal)
        }
        
        contentView.addConstraints(self.dynamicConstraints)
        super.updateConstraints()
    }
    
    // iOS Auto-Layout system SECOND calls layoutSubviews() after constraints are in-place and relative positions and sizes of all elements
    // have been decided by auto-layout
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // perform a final relayout using the actual sizes of the contentView and bounds
        self.relayout()
        
        if !self.awakeFromNibInvoked {
            // As titleLabel is the textLabel, iOS may re-layout without updating constraints, for example:
            // swiping, showing alert or actionsheet from the same section.
            // thus we need forcing update to use customConstraints()
            // this can create a nasty loop if constraint failures cause a re-invoke of layoutSubviews()
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Support for the tab functions between fields and beyond
    /////////////////////////////////////////////////////////////////////////
    
    open override func cellCanBecomeFirstResponder() -> Bool {
        return !row.isDisabled && (
                namePrefixTextField?.canBecomeFirstResponder == true ||
                nameFirstTextField?.canBecomeFirstResponder == true ||
                nameMiddleTextField?.canBecomeFirstResponder == true ||
                nameLastTextField?.canBecomeFirstResponder == true ||
                nameSuffixTextField?.canBecomeFirstResponder == true
        )
    }
    
    open override func cellBecomeFirstResponder(withDirection direction: Direction) -> Bool {
        return direction == .down ? self.textFieldTabOrder.first?.becomeFirstResponder() ?? false : self.textFieldTabOrder.last?.becomeFirstResponder() ?? false
    }
    
    open override func cellResignFirstResponder() -> Bool {
        return namePrefixTextField?.resignFirstResponder() ?? true
            && nameFirstTextField?.resignFirstResponder() ?? true
            && nameMiddleTextField?.resignFirstResponder() ?? true
            && nameLastTextField?.resignFirstResponder() ?? true
            && nameSuffixTextField?.resignFirstResponder() ?? true
    }
    
    override open var inputAccessoryView: UIView? {
        if let v = formViewController()?.inputAccessoryView(for: row) as? NavigationAccessoryView {
            guard let first = self.textFieldTabOrder.first, let last = self.textFieldTabOrder.last, first != last else { return v }
            
            let n = NavigationAccessoryView()
            n.doneClosure = v.doneClosure
            
            if first.isFirstResponder == true {
                n.previousClosure = v.previousClosure
                n.nextClosure = { [weak self] in
                    self?.internalGotoNext()
                }
            }
            else if last.isFirstResponder == true {
                n.previousClosure = { [weak self] in
                    self?.internalGotoPrevious()
                }
                n.nextClosure = v.nextClosure
            }
            else {
                n.previousClosure = { [weak self] in
                    self?.internalGotoPrevious()
                }
                n.nextClosure = { [weak self] in
                    self?.internalGotoNext()
                }
            }
            return n
        }
        return super.inputAccessoryView
    }
    
    @objc func internalGotoPrevious() {
        self.internalNavigationAction(direction: .up)
    }
    @objc func internalGotoNext() {
        self.internalNavigationAction(direction: .down)
    }
    func internalNavigationAction(direction: Direction) {
        guard let _ = inputAccessoryView as? NavigationAccessoryView else { return }
        
        var index = 0
        for field in self.textFieldTabOrder {
            if field.isFirstResponder == true {
                let _ = direction == .up ? self.textFieldTabOrder[index-1].becomeFirstResponder() : self.textFieldTabOrder[index+1].becomeFirstResponder()
                break
            }
            index += 1
        }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Override Eureka's default TextFieldDelegate handlers and handle any changed fields to make the row.value
    /////////////////////////////////////////////////////////////////////////
    
    open func textFieldDidBeginEditing(_ textField: UITextField) {
        formViewController()?.beginEditing(of: self)
        formViewController()?.textInputDidBeginEditing(textField, cell: self)
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        formViewController()?.endEditing(of: self)
        formViewController()?.textInputDidEndEditing(textField, cell: self)
        textFieldDidEndEditing_handler(textField)
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldReturn(textField, cell: self) ?? true
    }
    
    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return formViewController()?.textInputShouldEndEditing(textField, cell: self) ?? true
    }
    
    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldBeginEditing(textField, cell: self) ?? true
    }
    
    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldClear(textField, cell: self) ?? true
    }
    
    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldEndEditing(textField, cell: self) ?? true
    }
    
    @objc open func textFieldDidChange(_ textField: UITextField) {
        let nameRow = self.row as! _NameComponentsRow
        switch textField {
        case let field1 where field1 == self.namePrefixTextField:
            if (field1.text ?? "").isEmpty {
                nameRow._nameComponentsValues.nameHonorPrefix = nil
            } else {
                nameRow._nameComponentsValues.nameHonorPrefix = field1.text
            }
            break
            
        case let field2 where field2 == self.nameFirstTextField:
            if (field2.text ?? "").isEmpty {
                nameRow._nameComponentsValues.nameFirst = nil
            } else {
                nameRow._nameComponentsValues.nameFirst = field2.text
            }
            break
            
        case let field3 where field3 == self.nameMiddleTextField:
            if (field3.text ?? "").isEmpty {
                nameRow._nameComponentsValues.nameMiddle = nil
            } else {
                nameRow._nameComponentsValues.nameMiddle = field3.text
            }
            break
            
        case let field4 where field4 == self.nameLastTextField:
            if (field4.text ?? "").isEmpty {
                nameRow._nameComponentsValues.nameLast = nil
            } else {
                nameRow._nameComponentsValues.nameLast = field4.text
            }
            break
            
        case let field5 where field5 == self.nameSuffixTextField:
            if (field5.text ?? "").isEmpty {
                nameRow._nameComponentsValues.nameHonorSuffix = nil
            } else {
                nameRow._nameComponentsValues.nameHonorSuffix = field5.text
            }
            break
    
        default:
            break
        }
        nameRow.value = nameRow.makeValues()
    }
    
    // our custom handler for textField changes when the textField loses FirstResponder
    @objc open func textFieldDidEndEditing_handler(_ textField : UITextField) {
        let nameRow = self.row as! _NameComponentsRow
        var formatter:Formatter? = nil
        var formatter_field:UITextField? = nil
        
        self.textFieldDidChange(textField)
        
        switch textField {
        case let field1 where field1 == self.namePrefixTextField:
            if !(field1.text ?? "").isEmpty && nameRow._nameComponentsShown.nameHonorPrefix.formatter != nil {
                formatter = nameRow._nameComponentsShown.nameHonorPrefix.formatter!
                formatter_field = field1
            }
            break
            
        case let field2 where field2 == self.nameFirstTextField:
            if !(field2.text ?? "").isEmpty && nameRow._nameComponentsShown.nameFirst.formatter != nil {
                formatter = nameRow._nameComponentsShown.nameFirst.formatter!
                formatter_field = field2
            }
            break
            
        case let field3 where field3 == self.nameMiddleTextField:
            if !(field3.text ?? "").isEmpty && nameRow._nameComponentsShown.nameMiddle.formatter != nil {
                formatter = nameRow._nameComponentsShown.nameMiddle.formatter!
                formatter_field = field3
            }
            break
            
        case let field4 where field4 == self.nameLastTextField:
            if !(field4.text ?? "").isEmpty && nameRow._nameComponentsShown.nameLast.formatter != nil {
                formatter = nameRow._nameComponentsShown.nameLast.formatter!
                formatter_field = field4
            }
            break
            
        case let field5 where field5 == self.nameSuffixTextField:
            if !(field5.text ?? "").isEmpty && nameRow._nameComponentsShown.nameHonorSuffix.formatter != nil  {
                formatter = nameRow._nameComponentsShown.nameHonorSuffix.formatter!
                formatter_field = field5
            }
            break

        default:
            break
        }
        
        if formatter != nil, formatter_field != nil, formatter_field!.text != nil {
            let sourceText = formatter_field!.text!
            let unsafePointer = UnsafeMutablePointer<AnyObject?>.allocate(capacity: 1)
            defer {
                unsafePointer.deallocate()
            }
            let formattedText:AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(unsafePointer)         
            let errorDesc:AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            let didFormat:Bool = formatter!.getObjectValue(formattedText, for: sourceText, errorDescription: errorDesc)
            switch formatter_field {
            case let field1 where field1 == self.namePrefixTextField:
                if didFormat {
                    nameRow._nameComponentsValues.nameHonorPrefix = formattedText.pointee as? String
                    self.namePrefixTextField!.text = nameRow._nameComponentsValues.nameHonorPrefix
                } else { nameRow._nameComponentsValues.nameHonorPrefix = sourceText }
                break
            case let field2 where field2 == self.nameFirstTextField:
                if didFormat {
                    nameRow._nameComponentsValues.nameFirst = formattedText.pointee as? String
                    self.nameFirstTextField!.text = nameRow._nameComponentsValues.nameFirst
                } else { nameRow._nameComponentsValues.nameFirst = sourceText }
                break
            case let field3 where field3 == self.nameMiddleTextField:
                if didFormat {
                    nameRow._nameComponentsValues.nameMiddle = formattedText.pointee as? String
                    self.nameMiddleTextField!.text = nameRow._nameComponentsValues.nameMiddle
                } else { nameRow._nameComponentsValues.nameMiddle = sourceText }
                break
            case let field4 where field4 == self.nameLastTextField:
                if didFormat {
                    nameRow._nameComponentsValues.nameLast = formattedText.pointee as? String
                    self.nameLastTextField!.text = nameRow._nameComponentsValues.nameLast
                } else { nameRow._nameComponentsValues.nameLast = sourceText }
                break
            case let field5 where field5 == self.nameSuffixTextField:
                if didFormat {
                    nameRow._nameComponentsValues.nameHonorSuffix = formattedText.pointee as? String
                    self.nameSuffixTextField!.text = nameRow._nameComponentsValues.nameHonorSuffix
                } else { nameRow._nameComponentsValues.nameHonorSuffix = sourceText }
                break
            default:
                break
            }
            nameRow.value = nameRow.makeValues()
        }
    }
}

