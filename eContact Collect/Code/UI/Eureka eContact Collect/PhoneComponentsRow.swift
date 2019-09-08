///
//  PhoneComponentsRow.swift
//  eContact Collect
//
//  Created by Yo on 10/10/18.
//

// struct holding the return values for a PhoneComponentsRow
public struct PhoneComponentsValues {
    public var phoneInternationalPrefix: String?
    public var phoneNumber: String?
    public var phoneExtension: String?
}

/*public func == (lhs: PhoneComponentsValues, rhs: PhoneComponentsValues) -> Bool {
    return lhs.phoneInternationalPrefix == rhs.phoneInternationalPrefix && lhs.phoneNumber == rhs.phoneNumber && lhs.phoneExtension == rhs.phoneExtension
}*/

// the following fields can selectively be shown by this Row;
// their tags, formatters, and placeholders can optionally be set or overriden
// fields are composed and shown in the order presented below (shown ordering cannot be changed)
public struct PhoneComponentsShown {
    public var multiValued:Bool = true
    public var withFormattingRegion:String? = "NANP" {
        didSet {
            if (withFormattingRegion ?? "").isEmpty {
                self.phoneNumber.formatter = nil
            } else if withFormattingRegion! == "-" {
                self.phoneNumber.formatter = nil
            } else {
                self.phoneNumber.formatter = PhoneFormatter_ECC(forRegion: withFormattingRegion!)
            }
        }
    }
    public var phoneInternationalPrefix = PhoneInternationalPrefix()
    public var phoneNumber = PhoneNumber()
    public var phoneExtension = PhoneExtension()
    
    public struct PhoneInternationalPrefix {
        public var shown:Bool = true
        public var tag:String? = "PhoneIntl"
        public var placeholder:String? = "+"
        public var formatter:Formatter? = PhoneInternationalPrefixFormatter_ECC()
    }
    public struct PhoneNumber {
        public var shown:Bool = true
        public var tag:String? = "Phone"
        public var placeholder:String? = "#"
        public var formatter:Formatter? = PhoneFormatter_ECC(forRegion: "NANP")
    }
    public struct PhoneExtension {
        public var shown:Bool = true
        public var tag:String? = "PhoneExt"
        public var placeholder:String? = "Ext"
        public var formatter:Formatter? = nil
    }
    
    public init() {}
    
    public func requiresRelayout(comparedTo:PhoneComponentsShown) -> Bool {
        if  self.phoneInternationalPrefix.shown != comparedTo.phoneInternationalPrefix.shown ||
            self.phoneNumber.shown != comparedTo.phoneNumber.shown ||
            self.phoneExtension.shown != comparedTo.phoneExtension.shown { return true }
        return false
    }
}

// Base class row for Eureka
public final class PhoneComponentsRow: _PhoneComponentsRow, RowType {
    private var cTag:String = "EuRPC"
    
    required public init(tag: String?) {
        super.init(tag: tag)
        // set the cellProvider to default (which means the fields are constructed by the Cell
        //cellProvider = CellProvider<PhoneComponentsCell>()
    }
}

// Subclass row for Eureka
open class _PhoneComponentsRow : Row<PhoneComponentsCell> {
    private var cTag:String = "EuR_PC"
    public var title2:String? = nil
    
    open var phoneComponentsShown:PhoneComponentsShown {
        set (newValue) {
            let needsRelayout:Bool = _phoneComponentsShown.requiresRelayout(comparedTo: newValue)
            _phoneComponentsShown = newValue
            if _cell != nil && needsRelayout {
                cell.relayout()
                updateCell()
            }
        }
        get {
            return _phoneComponentsShown
        }
    }
    open var phoneComponentsValues:PhoneComponentsValues {
        set (newValue) {
            _phoneComponentsValues = newValue
            super.value = self.makeValues()
            if _cell != nil { updateCell() }
        }
        get {
            return _phoneComponentsValues
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
    
    internal var _phoneComponentsShown:PhoneComponentsShown = PhoneComponentsShown()
    internal var _phoneComponentsValues:PhoneComponentsValues = PhoneComponentsValues()
    
    required public init(tag: String?) {
        super.init(tag: tag)
        super.value = self.makeValues()
        
    }
    
    override open func beingRemovedFromForm() {
        cell.beingRemovedFromForm()
        super.beingRemovedFromForm()
    }
    
    // make the "value" [String:String?] pairs (or a single pair) for all the current values in the row
    internal func makeValues() -> [String:String?]  {
        var result:[String:String?] = [String:String?]()
        if self._phoneComponentsShown.multiValued {
            if self._phoneComponentsShown.phoneInternationalPrefix.shown {
                result[self._phoneComponentsShown.phoneInternationalPrefix.tag ?? "phoneIntl"] = _phoneComponentsValues.phoneInternationalPrefix
            }
            if self._phoneComponentsShown.phoneNumber.shown {
                result[self._phoneComponentsShown.phoneNumber.tag ?? "phoneNumber"] = _phoneComponentsValues.phoneNumber
            }
            if self._phoneComponentsShown.phoneExtension.shown {
                result[self._phoneComponentsShown.phoneExtension.tag ?? "phoneExt"] = _phoneComponentsValues.phoneExtension
            }
        } else {
            var valueString:String = ""
            if self._phoneComponentsShown.phoneInternationalPrefix.shown {
                if !(_phoneComponentsValues.phoneInternationalPrefix ?? "").isEmpty {
                    valueString = valueString + _phoneComponentsValues.phoneInternationalPrefix! + " "
                }
            }
            if self._phoneComponentsShown.phoneNumber.shown {
                if !(_phoneComponentsValues.phoneNumber ?? "").isEmpty {
                    if !valueString.isEmpty { valueString = valueString + " " }
                    valueString = valueString + _phoneComponentsValues.phoneNumber!
                }
            }
            if self._phoneComponentsShown.phoneExtension.shown {
                if !(_phoneComponentsValues.phoneExtension ?? "").isEmpty {
                    valueString = valueString + "x" + _phoneComponentsValues.phoneExtension!
                }
            }
            result[self.tag ?? "phone"] = valueString
        }
        return result
    }
    
    // extract the current values from pairs or a single pair
    private func extractFromValues(values:[String:String?]?) {
        if self._phoneComponentsShown.multiValued {
            if values == nil {
                _phoneComponentsValues.phoneInternationalPrefix = nil
                _phoneComponentsValues.phoneNumber = nil
                _phoneComponentsValues.phoneExtension = nil
            } else {
                _phoneComponentsValues.phoneInternationalPrefix = values![self._phoneComponentsShown.phoneInternationalPrefix.tag ?? "phoneIntl"] as? String
                _phoneComponentsValues.phoneNumber = values![self._phoneComponentsShown.phoneNumber.tag ?? "phoneNumber"] as? String
                _phoneComponentsValues.phoneExtension = values![self._phoneComponentsShown.phoneExtension.tag ?? "phoneExt"] as? String
            }
        } else {
            let phoneString:String? = values![self.tag ?? "phone"] as? String
            if (phoneString ?? "").isEmpty {
                _phoneComponentsValues.phoneInternationalPrefix = nil
                _phoneComponentsValues.phoneNumber = nil
                _phoneComponentsValues.phoneExtension = nil
            } else {
                var intlComponents = phoneString!.components(separatedBy: " ")
                if intlComponents.count > 1 {
                    _phoneComponentsValues.phoneInternationalPrefix = intlComponents[0]
                    intlComponents[0] = intlComponents[1]
                }
                var phoneComponents = intlComponents[0].components(separatedBy: "x")
                if phoneComponents.count > 1 {
                    _phoneComponentsValues.phoneExtension = phoneComponents[1]
                }
                _phoneComponentsValues.phoneNumber = phoneComponents[0]
            }
        }
    }
}

// Base class cell for Eureka
public class PhoneComponentsCell: Cell<[String:String?]>, CellType, UITextFieldDelegate {
    private var cTag:String = "EuCPC"
    
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var intlTextField: UITextField?
    @IBOutlet public weak var phoneTextField: UITextField?
    @IBOutlet public weak var extTextField: UITextField?

    internal var setupCompleted:Bool = false
    private var awakeFromNibInvoked:Bool = false
    private var _height:CGFloat = 46.0
    private var verticalPad:Int = 10
    open var textFieldTabOrder:[UITextField] = []
    private var composedLayout:ComposedLayout = ComposedLayout(contentView: nil, row: nil, cellHasManualHeight: true)
    private var dynamicConstraints = [NSLayoutConstraint]()
    
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
        self.intlTextField = tf1
        
        let tf2 = UITextField()
        self.phoneTextField = tf2
        
        let tf3 = UITextField()
        self.extTextField = tf3
        
        // for convenience place all the fields for now in the tab order
        // pre-setup all the text field's; they can be overriden later by user of in-Form overrides
        self.contentView.addSubview(titleLabel!)
        self.textFieldTabOrder = [self.intlTextField!, self.phoneTextField!, self.extTextField!]
        for textField in self.textFieldTabOrder {
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.borderStyle = UITextField.BorderStyle.bezel
            textField.textAlignment = .left
            textField.clearButtonMode = .whileEditing
            textField.keyboardType = .phonePad
            if #available(iOS 10,*) {
                textField.textContentType = .telephoneNumber
            }
            textField.isHidden = true
            textField.isEnabled = false
            textField.delegate = self
            textField.font = .preferredFont(forTextStyle: UIFont.TextStyle.body)
            textField.addTarget(self, action: #selector(PhoneComponentsCell.textFieldDidChange(_:)), for: .editingChanged)
            self.contentView.addSubview(textField)
        }
        self.intlTextField?.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
        self.intlTextField?.setContentHuggingPriority(UILayoutPriority.hugPriStandardField, for: .horizontal)
        self.intlTextField?.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
        
        self.intlTextField?.clearButtonMode = .never
        
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
    //the cell's row property has been set; so row-property dependent init's need be done here;
    // (but only inits that cannot be changed by the Form mainline)
    public override func setup() {
        super.setup()
        
        accessoryView = nil
        height = {
//debugPrint("\(self.cTag).height GET \(self._height)")
            return self._height
        }
        
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
        let phoneRow = self.row as! _PhoneComponentsRow
        var potentialLayoutChanges:Bool = false
        
        detailTextLabel?.text = nil
        textLabel?.text = nil
        
        if (row.title ?? "").isEmpty {
            if self.titleLabel!.text != nil { potentialLayoutChanges = true }
            self.titleLabel!.text = nil
        } else {
            if (phoneRow.title2 ?? "").isEmpty {
                if self.titleLabel!.text != row.title! || self.titleLabel!.numberOfLines != 1 { potentialLayoutChanges = true }
                self.titleLabel!.numberOfLines = 1
                self.titleLabel!.text = row.title!
            } else {
                if self.titleLabel!.text != row.title! + "\n" + phoneRow.title2! || self.titleLabel!.numberOfLines != 2 { potentialLayoutChanges = true }
                self.titleLabel!.numberOfLines = 2
                self.titleLabel!.text = row.title! + "\n" + phoneRow.title2!
            }
            if !row.isValid { self.titleLabel!.textColor = UIColor.red }
            else if row.isHighlighted { self.titleLabel!.textColor = tintColor }
        }
        
        if phoneRow._phoneComponentsShown.phoneInternationalPrefix.shown {
            self.intlTextField?.text = phoneRow._phoneComponentsValues.phoneInternationalPrefix
            if !(phoneRow._phoneComponentsShown.phoneInternationalPrefix.placeholder ?? "").isEmpty {
                self.intlTextField?.placeholder = phoneRow._phoneComponentsShown.phoneInternationalPrefix.placeholder!
            }
        }
        if phoneRow._phoneComponentsShown.phoneNumber.shown {
            self.phoneTextField?.text = phoneRow._phoneComponentsValues.phoneNumber
            if !(phoneRow._phoneComponentsShown.phoneNumber.placeholder ?? "").isEmpty {
                self.phoneTextField?.placeholder = phoneRow._phoneComponentsShown.phoneNumber.placeholder!
            }
        }
        if phoneRow._phoneComponentsShown.phoneExtension.shown {
            self.extTextField?.text = phoneRow._phoneComponentsValues.phoneExtension
            if !(phoneRow._phoneComponentsShown.phoneExtension.placeholder ?? "").isEmpty {
                self.extTextField?.placeholder = phoneRow._phoneComponentsShown.phoneExtension.placeholder!
            }
        }
        
        if potentialLayoutChanges { self.relayout() }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Layout the Cell's textFields and controls, and update constraints
    /////////////////////////////////////////////////////////////////////////
    
    // called whenever all the fields should be positioned (either first time or because phoneComponentsShown was changed or because of rotation);
    // this is called BEFORE update() above; constraint updating after this relayout will occur during layoutSubviews() which is iOS invoked
    internal func relayout() {
//debugPrint("\(self.cTag).relayout STARTED contentView.frame.size=\(contentView.frame.size)")
        let phoneRow = self.row as! _PhoneComponentsRow
        
//debugPrint("\(self.cTag).relayout titleLabel.size=\(self.titleLabel!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout intlTextField.size=\(self.intlTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout phoneTextField.size=\(self.phoneTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout extTextField.size=\(self.extTextField!.layer.frame.size)")
        
        // prepare to compose the relatively simple dynamic layout
        let newComposedLayout = ComposedLayout(contentView: self.contentView, row: row, cellHasManualHeight: true, titleAreaRatioWidthToMove: 0.2)
        
        var newHeight:CGFloat = 0.0
        if !(phoneRow.title ?? "").isEmpty {
            newComposedLayout.addTextTitleFirstControl(forControl: ComposedLayoutControl(controlName: "titleLabel", control: self.titleLabel!))
            newHeight = self.composedLayout.getTitlesBoundsSize().height
        } else { self.textLabel!.text = nil }
        
        var fieldsHeight:CGFloat = 0.0
        self.textFieldTabOrder = []
        if phoneRow._phoneComponentsShown.phoneInternationalPrefix.shown {
            var intlTextFieldCLC = ComposedLayoutControl(controlName: "intlTextField", control: self.intlTextField!, isFixedWidthOrLess: true)
            intlTextFieldCLC.isFixedWidthOrLess = true
            newComposedLayout.addControlToCurrentLine(forControl: intlTextFieldCLC)
            
            if self.intlTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.intlTextField!.layer.frame.size.height }
            self.intlTextField?.isHidden = false
            self.intlTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.intlTextField!)
        } else { self.intlTextField?.isHidden = true; self.intlTextField?.isEnabled = false }
        
        if phoneRow._phoneComponentsShown.phoneNumber.shown {
            let phoneTextFieldCLC = ComposedLayoutControl(controlName: "phoneTextField", control: self.phoneTextField!)
            newComposedLayout.addControlToCurrentLine(forControl: phoneTextFieldCLC)
            
            if self.phoneTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.phoneTextField!.layer.frame.size.height }
            self.phoneTextField?.isHidden = false
            self.phoneTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.phoneTextField!)
        } else { self.phoneTextField?.isHidden = true; self.phoneTextField?.isEnabled = false }
        
        if phoneRow._phoneComponentsShown.phoneExtension.shown {
            var extTextFieldCLC = ComposedLayoutControl(controlName: "extTextField", control: self.extTextField!)
            extTextFieldCLC.isFixedWidthOrLess = true
            newComposedLayout.addControlToCurrentLine(forControl: extTextFieldCLC)
            
            if self.extTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.extTextField!.layer.frame.size.height }
            self.extTextField?.isHidden = false
            self.extTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.extTextField!)
        } else { self.extTextField?.isHidden = true; self.extTextField?.isEnabled = false }
        newComposedLayout.done()
        let _ = newComposedLayout.assessTitleMove(contentView: contentView, noBottomsOrEnds: (fieldsHeight == 0.0))
        
        // only replace the composedLayout if it has changed; this is necessary to prevent infinite loops with doing auto-title moving;
        // if layout did change, just set that constraints need updating, but do not trigger that yet
        if self.composedLayout.isEmpty() {
            self.composedLayout = newComposedLayout
            setNeedsUpdateConstraints()
        } else if self.composedLayout != newComposedLayout {
            self.composedLayout = newComposedLayout
            setNeedsUpdateConstraints()
        }
        
        // get the height from the fields area of the composed layout
        if self.composedLayout.linesCount() > 0 &&  fieldsHeight > 0.0 {
            let workHeight:CGFloat = self.composedLayout.getFieldsBoundsSize().height
            if workHeight > newHeight { newHeight = workHeight }
        }

        // set the final height estimate
        if self._height != newHeight { setNeedsLayout() }   // force the tableview to know this cell's height needs changing
        self._height = newHeight
        contentView.frame.size.height = self._height
//debugPrint("\(self.cTag).relayout New Height contentView.frame.size=\(contentView.frame.size)")
    }
    
    // iOS Auto-Layout system FIRST calls updateConstraints() so that proper contraints can be put into place before doing actual layout
    open override func updateConstraints() {
//debugPrint("\(self.cTag).updateConstraints STARTED TableViewCell.frame.size=\(self.frame.size) bounds.size=\(self.bounds.size)")
//debugPrint("\(self.cTag).updateConstraints STARTED   contentView.frame.size=\(contentView.frame.size) bounds.size=\(contentView.bounds.size)")
        if self.awakeFromNibInvoked {
            // since the NIB did the layout and the contraints, we do nothing dynamically
            super.updateConstraints()
            return
        }
        
        // remove all existing dynamic contraints and prepare
        contentView.removeConstraints(self.dynamicConstraints)
        self.dynamicConstraints = []
        let phoneRow = self.row as! _PhoneComponentsRow
        var views: [String: AnyObject] = [:]
        
        // build up the necessary pre-information depending on what is supposed to be shown
        var fieldsWidth:CGFloat = contentView.frame.size.width - 40.0
        var titleHeight:CGFloat = 0.0
        var hasTitleLines = 0
        if !(phoneRow.title ?? "").isEmpty {
            if titleLabel!.layer.frame.size.height > titleHeight { titleHeight = titleLabel!.layer.frame.size.height }
//debugPrint("\(self.cTag).updateConstraints titleLabel.frame.size=\(titleLabel!.layer.frame.size)")
            fieldsWidth = fieldsWidth - titleLabel!.layer.frame.size.width - 5.0
            if (phoneRow.title2 ?? "").isEmpty { hasTitleLines = 1 }
            else { hasTitleLines = 2 }
        }
        
        var fieldsHeight:CGFloat = 0.0
        if self.intlTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.intlTextField!.layer.frame.size.height }
        if self.phoneTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.phoneTextField!.layer.frame.size.height }
        if self.extTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.extTextField!.layer.frame.size.height }
        
        // got anything to create?
        if hasTitleLines == 0 && (self.composedLayout.linesCount() == 0 || self.composedLayout.controlsCount(inLine: 0) <= 0)  { return }
        
        // yes, generate the bulk of the constraints
        (views, self.dynamicConstraints) = self.composedLayout.generateDynamicConstraints(contentView: contentView, noBottomsOrEnds: (fieldsHeight == 0.0))
        
        // additional specific constraints
        if phoneRow._phoneComponentsShown.phoneInternationalPrefix.shown {
            self.dynamicConstraints += [NSLayoutConstraint(item: self.extTextField!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: contentView, attribute: .width, multiplier: 0.2, constant: 0)]
        }
        if phoneRow._phoneComponentsShown.phoneExtension.shown {
            self.dynamicConstraints += [NSLayoutConstraint(item: self.extTextField!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: contentView, attribute: .width, multiplier: 0.3, constant: 0)]
        }

        contentView.addConstraints(self.dynamicConstraints)
        super.updateConstraints()
    }
    
    // iOS Auto-Layout system SECOND calls layoutSubviews() after constraints are in-place and relative positions and sizes of all elements
    // have been decided by auto-layout
    open override func layoutSubviews() {
        super.layoutSubviews()
//debugPrint("\(self.cTag).layoutSubviews STARTED TableViewCell.frame.size=\(self.frame.size) bounds.size=\(self.bounds.size)")
//debugPrint("\(self.cTag).layoutSubviews STARTED   contentView.frame.size=\(contentView.frame.size) bounds.size=\(bounds.size)")

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
                intlTextField?.canBecomeFirstResponder == true ||
                phoneTextField?.canBecomeFirstResponder == true ||
                extTextField?.canBecomeFirstResponder == true
        )
    }
    
    open override func cellBecomeFirstResponder(withDirection direction: Direction) -> Bool {
        return direction == .down ? self.textFieldTabOrder.first?.becomeFirstResponder() ?? false : self.textFieldTabOrder.last?.becomeFirstResponder() ?? false
    }
    
    open override func cellResignFirstResponder() -> Bool {
        return intlTextField?.resignFirstResponder() ?? true
            && phoneTextField?.resignFirstResponder() ?? true
            && extTextField?.resignFirstResponder() ?? true
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
    
    // called for every single character add, change, delete
    @objc open func textFieldDidChange(_ textField: UITextField) {
        // the text field's contents are NOT yet formatted
        let phoneRow = self.row as! _PhoneComponentsRow
        switch textField {
        case let field1 where field1 == self.intlTextField:
            if (field1.text ?? "").isEmpty {
                phoneRow._phoneComponentsValues.phoneInternationalPrefix = nil
            } else {
                phoneRow._phoneComponentsValues.phoneInternationalPrefix = field1.text
            }
            break
            
        case let field2 where field2 == self.phoneTextField:
            if (field2.text ?? "").isEmpty {
                phoneRow._phoneComponentsValues.phoneNumber = nil
            } else {
                phoneRow._phoneComponentsValues.phoneNumber = field2.text
            }
            break
            
        case let field3 where field3 == self.extTextField:
            if (field3.text ?? "").isEmpty {
                phoneRow._phoneComponentsValues.phoneExtension = nil
            } else {
                phoneRow._phoneComponentsValues.phoneExtension = field3.text
            }
            break
            
        default:
            break
        }
        phoneRow.value = phoneRow.makeValues()
    }
    
    // our custom handler for textField changes when the textField loses FirstResponder
    @objc open func textFieldDidEndEditing_handler(_ textField : UITextField) {
        let phoneRow = self.row as! _PhoneComponentsRow
        var formatter:Formatter? = nil
        var formatter_field:UITextField? = nil
        
        // record a final change (not yet formatted)
        self.textFieldDidChange(textField)
        
        // determine which formatter to use
        switch textField {
        case let field1 where field1 == self.intlTextField:
            if !(field1.text ?? "").isEmpty && phoneRow._phoneComponentsShown.phoneInternationalPrefix.formatter != nil {
                formatter = phoneRow._phoneComponentsShown.phoneInternationalPrefix.formatter!
                formatter_field = field1
            }
            break
            
        case let field2 where field2 == self.phoneTextField:
            if !(field2.text ?? "").isEmpty && phoneRow._phoneComponentsShown.phoneNumber.formatter != nil {
                formatter = phoneRow._phoneComponentsShown.phoneNumber.formatter!
                formatter_field = field2
                if phoneRow._phoneComponentsShown.phoneInternationalPrefix.shown &&
                   !(phoneRow._phoneComponentsValues.phoneInternationalPrefix ?? "").isEmpty {
                    
                    if PhoneFormatter_ECC.isSupported(intlCode: phoneRow._phoneComponentsValues.phoneInternationalPrefix) {
                        formatter = PhoneFormatter_ECC(forIntlCode: phoneRow._phoneComponentsValues.phoneInternationalPrefix!)
debugPrint("\(self.cTag).textFieldDidEndEditing_handler Override Phone# formatter:  \((formatter as! PhoneFormatter_ECC).forRegion)")
                    }
                }
            }
            break   
            
        case let field3 where field3 == self.extTextField:
            if !(field3.text ?? "").isEmpty && phoneRow._phoneComponentsShown.phoneExtension.formatter != nil {
                formatter = phoneRow._phoneComponentsShown.phoneExtension.formatter!
                formatter_field = field3
            }
            break
            
        default:
            break
        }
        
        // perform the formatting if supposed to; re-store the results
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
            case let field where field == self.intlTextField:
                if didFormat {
                    phoneRow._phoneComponentsValues.phoneInternationalPrefix = formattedText.pointee as? String
                    self.intlTextField!.text = phoneRow._phoneComponentsValues.phoneInternationalPrefix
                } else { phoneRow._phoneComponentsValues.phoneInternationalPrefix = sourceText }
                break
            case let field where field == self.phoneTextField:
                if didFormat {
                    phoneRow._phoneComponentsValues.phoneNumber = formattedText.pointee as? String
                    self.phoneTextField!.text = phoneRow._phoneComponentsValues.phoneNumber
                } else { phoneRow._phoneComponentsValues.phoneNumber = sourceText }
                break
            case let field where field == self.extTextField:
                if didFormat {
                    phoneRow._phoneComponentsValues.phoneExtension = formattedText.pointee as? String
                    self.extTextField!.text = phoneRow._phoneComponentsValues.phoneExtension
                } else { phoneRow._phoneComponentsValues.phoneExtension = sourceText }
                break
            default:
                break
            }
            phoneRow.value = phoneRow.makeValues()
        }
    }
}

// custom international phone formatter
public class PhoneInternationalPrefixFormatter_ECC: Formatter {
    
    /// Returns a InputString:String from the given FormattedString:String
    /// - Parameter obj: Pointer to FormattedString object
    /// - Return: A String object that textually represents object for display; return nil if object is not of the correct class
    override open func string(for obj: Any?) -> String? {
        if obj == nil { return nil }
        let str:String? = obj! as? String
        return str
    }
    
    /// Creates a FormattedString:String from the given InputString:String
    /// - Parameter obj: Pointer to FormattedString object to assign
    /// - Parameter for: InputString with raw phone# input
    /// - Parameter errorDescription: Pointer to place to store an error message string
    /// - Return:  true if the conversion from string to cell content object was successful, otherwise false
    override open func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        if obj == nil { return false }
        if string.isEmpty { return true }
        
        var result:String = ""
        if string.first != "+" { result = result + "+" }
        result = result + string
        
        obj!.pointee = result as AnyObject
        return true
    }
}

// custom phone formatter for US phones and others in the N. America Numbering Plan (including Canada; U.S. Protectorates; various Caribbean nations, states, territories)
public class PhoneFormatter_ECC: Formatter {
    public var forRegion:String = "NANP"
    public static var acceptableRegions:[String] = ["NANP","US","CA","MX","UK"]
    public static var acceptablePhoneIntlCodes:[String] = ["+1","+1","+1","+52","+44"]
    
    // initializer
    init(forRegion:String) {
        super.init()
        self.forRegion = forRegion
    }
    init(forIntlCode:String) {
        super.init()
        var working:String = forIntlCode
        if working.first != "+" { working = "+" + working }
        for i in 0...PhoneFormatter_ECC.acceptablePhoneIntlCodes.count - 1 {
            if PhoneFormatter_ECC.acceptablePhoneIntlCodes[i] == working {
                self.forRegion = PhoneFormatter_ECC.acceptableRegions[i]
                return
            }
        }
        self.forRegion = "NANP"
    }
    
    // required initializer
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // does the formatter support the indicated region or international code?
    public static func isSupported(region:String?) -> Bool {
        if (region ?? "").isEmpty { return false }
        if region! == "-" { return false }
        if self.acceptableRegions.contains(region!) { return true }
        return false
    }
    public static func isSupported(intlCode:String?) -> Bool {
        if (intlCode ?? "").isEmpty { return false }
        if intlCode! == "-" { return false }
        var working:String = intlCode!
        if working.first != "+" { working = "+" + working }
        if self.acceptablePhoneIntlCodes.contains(working) { return true }
        return false
    }
    
    /// Returns a InputString:String from the given FormattedString:String
    /// - Parameter obj: Pointer to FormattedString object
    /// - Return: A String object that textually represents object for display; return nil if object is not of the correct class
    override open func string(for obj: Any?) -> String? {
        if obj == nil { return nil }
        let str:String? = obj! as? String
        return str
    }
    
    /// Creates a FormattedString:String from the given InputString:String
    /// - Parameter obj: Pointer to FormattedString object to assign
    /// - Parameter for: InputString with raw phone# input
    /// - Parameter errorDescription: Pointer to place to store an error message string
    /// - Return:  true if the conversion from string to cell content object was successful, otherwise false
    override open func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        if obj == nil { return false }
        if string.isEmpty { return true }
        if self.forRegion.isEmpty { return false }
        
debugPrint("EUREKA.PhoneComponentsRow.PhoneFormatter_ECC.getObjectValue formatRegion: \(self.forRegion)")
        switch self.forRegion {
        case "-":
            return false
            
        case "NANP":
            return formatAs_NANP(obj, for:string, errorDescription: error)
            
        case "US":
            return formatAs_NANP(obj, for:string, errorDescription: error)
            
        case "CA":
            return formatAs_NANP(obj, for:string, errorDescription: error)
            
        case "MX":
            return formatAs_MX(obj, for:string, errorDescription: error)
            
        case "UK":
            return formatAs_UK(obj, for:string, errorDescription: error)
            
        default:
            return false
        }
    }
    
    // custom phone formatter for US phones and others in the N. America Numbering Plan (including Canada; U.S. Protectorates; various Caribbean nations, states, territories)
    private func formatAs_NANP(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
    
        if obj == nil { return false }
        if string.isEmpty { return true }
        
        // first remove all unacceptable characters and place each character into a string array
        var hasFormatting:Bool = false
        var workStringComps:[Character] = []
        for char in string {
            if char >= "0" && char <= "9" {
                workStringComps.append(char)
            } else if char == " " {
                workStringComps.append("-")
                hasFormatting = true
            } else if char == "(" || char == ")" || char == "-" {
                workStringComps.append(char)
                hasFormatting = true
            }
        }
        
        // now look at formatting
        if !hasFormatting {
            // has only digits
            if workStringComps.count == 7 {
                // no area code; should be 7 digits when fully entered
                workStringComps.insert("-", at: 3)
            } else if workStringComps.count == 10 {
                // includes area code; should be 10 digits when fully entered
                workStringComps.insert("-", at: 6)
                workStringComps.insert(")", at: 3)
                workStringComps.insert("(", at: 0)
            }
        } else {
            // has formatting present
            if workStringComps.count >= 9 {
                if workStringComps[3] == "-"  {
                    // if a dash is used to separate the area code, put the area code in parentheses
                    workStringComps.remove(at: 3)
                    workStringComps.insert("-", at: 6)
                    workStringComps.insert(")", at: 3)
                    workStringComps.insert("(", at: 0)
                }
            }
        }
        
        // convert back into a string
        var result:String = ""
        for char in workStringComps {
            result.append(char)
        }
        
        if !result.isEmpty {
            obj!.pointee = result as AnyObject
            return true
        }
        return false
    }
    
    // custom phone formatter for UK phones
    private func formatAs_UK(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        if obj == nil { return false }
        if string.isEmpty { return true }
        
        // first remove all unacceptable characters and place each character into a string array
        var hasFormatting:Bool = false
        var workStringComps:[Character] = []
        for char in string {
            if char >= "0" && char <= "9" {
                workStringComps.append(char)
            } else if char == "(" || char == ")" || char == " " {
                workStringComps.append(char)
                hasFormatting = true
            }
        }
        
        // now look at formatting
        if !hasFormatting {
            // has only digits
            if workStringComps[0] == "0"  {
                // it is a NSN; should be 11 digits when fully entered, though occasionally 10
                let _ = formatAs_UK_NSN(string: string, workStringComps: &workStringComps)
            } else {
                // local numbers (non-NSN)
                if workStringComps.count == 7 {
                    // format:  ### ####
                    workStringComps.insert(" ", at: 3)
                } else if workStringComps.count == 8 {
                    // format:  #### ####
                    workStringComps.insert(" ", at: 4)
                } else if workStringComps.count == 9 || workStringComps.count == 10 {
                    // has the leading '0' been omitted?
                    var nsnWorkStringComps:[Character] = workStringComps
                    nsnWorkStringComps.insert("0", at: 0)
                    let nsnString:String = "0" + string
                    if formatAs_UK_NSN(string: nsnString, workStringComps: &nsnWorkStringComps) {
                        workStringComps = nsnWorkStringComps
                    }
                }
            }
        } else {
            // has formatting present
            // not going to change nor correct
        }
        
        // convert back into a string
        var result:String = ""
        for char in workStringComps {
            result.append(char)
        }
        
        if !result.isEmpty {
            obj!.pointee = result as AnyObject
            return true
        }
        return false
    }
    private func formatAs_UK_NSN(string:String, workStringComps:inout [Character]) -> Bool {
        if workStringComps.count >= 10 {
            if workStringComps[1] == "2" {
                // London, format is: (02#)#### ####
                workStringComps.insert(" ", at: 7)
                workStringComps.insert(")", at: 3)
                workStringComps.insert("(", at: 0)
                return true
            } else if workStringComps[1] == "7" {
                if workStringComps[2] == "0" || workStringComps[2] == "6" {
                    // pagers; format is:  070 #### ####, or 076 #### ####
                    workStringComps.insert(" ", at: 7)
                    workStringComps.insert(" ", at: 3)
                    return true
                } else {
                    // mobile phones; format is:  07### ######
                    workStringComps.insert(" ", at: 5)
                    return true
                }
            } else if workStringComps[1] == "1" {
                let sixCode = string.prefix(6)
                if workStringComps[2] == "1" {
                    // format is: (011#)### ####
                    workStringComps.insert(" ", at: 7)
                    workStringComps.insert(")", at: 4)
                    workStringComps.insert("(", at: 0)
                    return true
                } else if workStringComps[3] == "1" {
                    // format is: (01#1)### ####
                    workStringComps.insert(" ", at: 7)
                    workStringComps.insert(")", at: 4)
                    workStringComps.insert("(", at: 0)
                    return true
                } else if sixCode == "013873" || sixCode == "015242" || sixCode == "015394" || sixCode == "015395" || sixCode == "015396" ||
                    sixCode == "016973" || sixCode == "016974" || sixCode == "016977" || sixCode == "017683" || sixCode == "017684" ||
                    sixCode == "017687" || sixCode == "019467" {
                    // format is: (01## ##)#####, though also (01## ##)####
                    workStringComps.insert(")", at: 6)
                    workStringComps.insert(" ", at: 4)
                    workStringComps.insert("(", at: 0)
                    return true
                } else {
                    // format is: (01###)######, though also (01###)#####
                    workStringComps.insert(")", at: 5)
                    workStringComps.insert("(", at: 0)
                    return true
                }
            } else if workStringComps[1] == "3" || workStringComps[1] == "8" || workStringComps[1] == "9" {
                // non-geographic:  format is: 03## ### ####
                // toll free; format is:  08## ### ####, though also 0800 1111, 0845 ####,  0800 ######
                // premium rate content; format is: 09## ### ####
                if workStringComps.count >= 8 &&  workStringComps.count <= 10 {
                    workStringComps.insert(" ", at: 4)
                    return true
                } else if workStringComps.count == 11 {
                    workStringComps.insert(" ", at: 7)
                    workStringComps.insert(" ", at: 4)
                    return true
                }
            } else if workStringComps[1] == "5" {
                // corporate/VoIP: format is: 05# #### ####, though also 0500 ######,
                if workStringComps.count >= 8 &&  workStringComps.count <= 10 {
                    workStringComps.insert(" ", at: 4)
                    return true
                } else if workStringComps.count == 11 {
                    workStringComps.insert(" ", at: 7)
                    workStringComps.insert(" ", at: 3)
                    return true
                }
            } else if workStringComps[1] == "0" || workStringComps[1] == "4" || workStringComps[1] == "6" {
                // codes 4 and 6 are not presently in-use, code 0 indicates an international prefix
            }
        }
        return false
    }
    
    // custom phone formatter for MX phones
    private func formatAs_MX(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        if obj == nil { return false }
        if string.isEmpty { return true }
        
        // first remove all unacceptable characters and place each character into a string array
        var hasFormatting:Bool = false
        var workStringComps:[Character] = []
        for char in string {
            if char >= "0" && char <= "9" {
                workStringComps.append(char)
            } else if char == " " {
                workStringComps.append("-")
                hasFormatting = true
            } else if char == "(" || char == ")" || char == "-" {
                workStringComps.append(char)
                hasFormatting = true
            }
        }
        
        let twoCode = string.prefix(2)
        let threeCode = string.prefix(3)
        if !hasFormatting {
            // has only digits
            if twoCode == "01" || twoCode == "02" {
                // has landline prefix; must include area code
                if workStringComps.count == 12 {
                    let twoCode2 = string[string.index(string.startIndex, offsetBy: 2) ..< string.index(string.startIndex, offsetBy: 4)]
                    if twoCode2 == "33" || twoCode2 == "55" || twoCode2 == "56" || twoCode2 == "81" {
                        // 01(##)####-####; includes area code; should be 12 digits when fully entered; two digit area code
                        workStringComps.insert("-", at: 8)
                        workStringComps.insert(")", at: 4)
                        workStringComps.insert("(", at: 2)
                    } else {
                        // 01(###)###-####; includes area code; should be 10 digits when fully entered; three digit area code
                        workStringComps.insert("-", at: 8)
                        workStringComps.insert(")", at: 5)
                        workStringComps.insert("(", at: 2)
                    }
                }
            } else if threeCode == "044" || threeCode == "045" {
                // has mobile prefix
                if workStringComps.count == 13 {
                    let twoCode2 = string[string.index(string.startIndex, offsetBy: 3) ..< string.index(string.startIndex, offsetBy: 5)]
                    if twoCode2 == "33" || twoCode2 == "55" || twoCode2 == "56" || twoCode2 == "81" {
                        // 044(##)####-####; includes area code; should be 13 digits when fully entered; two digit area code
                        workStringComps.insert("-", at: 9)
                        workStringComps.insert(")", at: 5)
                        workStringComps.insert("(", at: 3)
                    } else {
                        // 044(###)###-####; includes area code; should be 13 digits when fully entered; three digit area code
                        workStringComps.insert("-", at: 9)
                        workStringComps.insert(")", at: 6)
                        workStringComps.insert("(", at: 3)
                    }
                }
            } else {
                // not prefixed
                if workStringComps.count == 7 {
                    // ###-####; no area code; 7 digit local#
                    workStringComps.insert("-", at: 3)
                } else if workStringComps.count == 8 {
                    // ####-####; no area code; 8 digit local#
                    workStringComps.insert("-", at: 4)
                } else if workStringComps.count == 10 {
                    if twoCode == "33" || twoCode == "55" || twoCode == "56" || twoCode == "81" {
                        // (##)####-####; includes area code; should be 10 digits when fully entered; two digit area code
                        workStringComps.insert("-", at: 6)
                        workStringComps.insert(")", at: 2)
                        workStringComps.insert("(", at: 0)
                    } else {
                        // (###)###-####; includes area code; should be 10 digits when fully entered; three digit area code
                        workStringComps.insert("-", at: 6)
                        workStringComps.insert(")", at: 3)
                        workStringComps.insert("(", at: 0)
                    }
                }
            }
        } else {
            // has formatting present
            // not going to change nor correct
        }
        
        // convert back into a string
        var result:String = ""
        for char in workStringComps {
            result.append(char)
        }
        
        if !result.isEmpty {
            obj!.pointee = result as AnyObject
            return true
        }
        return false
    }
}

// example Eureka Rule struct for validating a set of [key:value] pairs using information from within the Row
// validates the PhoneComponentsRow
public struct RulePhoneComponents_ECC<T: Equatable>: RuleTypeExt {
    
    public init(id: String? = nil) {
        self.id = id
    }
    
    public var id: String?
    public var validationError:ValidationError = ValidationError(msg: NSLocalizedString("Phone number is invalid", comment:"") + " (NANP)")
    
    public func isValid(value: T?) -> ValidationError? {
        return ValidationError(msg: "$$$APP INTERNAL ERROR!!")
    }
    
    public func isValidExt(row:BaseRow, value: T?) -> ValidationError? {
        let phoneRow = row as! _PhoneComponentsRow
        var errors:String = ""
        var comma:String = ""
        if let objectDict:[String:Any?] = value as? [String:Any?] {
            for pair in objectDict {
                let valueString:String? = pair.value as? String
                if !(valueString ?? "").isEmpty {
                    if pair.key == phoneRow._phoneComponentsShown.phoneNumber.tag {
                        let valid = RulePhone_ECC<String>.testIsValid(formatRegion: phoneRow._phoneComponentsShown.withFormattingRegion, phoneString: valueString!)
                        if !valid {
                            errors = errors + comma + NSLocalizedString("Phone number is invalid", comment:"") +
                            " (\(phoneRow._phoneComponentsShown.withFormattingRegion ?? "-"))"
                            comma = ", "
                        }
                    } else if pair.key == phoneRow._phoneComponentsShown.phoneExtension.tag {
                        let phoneChars:CharacterSet = CharacterSet(charactersIn:"1234567890#*")
                        if valueString!.rangeOfCharacter(from: phoneChars.inverted) != nil {
                            errors = errors + comma + NSLocalizedString("Phone extension is invalid", comment:"")
                            comma = ", "
                        }
                    } else if pair.key == phoneRow._phoneComponentsShown.phoneInternationalPrefix.tag {
                        let phoneChars:CharacterSet = CharacterSet(charactersIn:"1234567890+")
                        if valueString!.rangeOfCharacter(from: phoneChars.inverted) != nil {
                            errors = errors + comma + NSLocalizedString("International phone prefix is invalid", comment:"")
                            comma = ", "
                        }
                    }
                }
            }
        }
        if errors.isEmpty { return nil }
        return ValidationError(msg: errors)
    }
}
