//
//  AddressComponentsRow.swift
//  Eureka
//
//  Created by Yo on 11/4/18.
//

// struct holding the return values for a AddressComponentsRow
public struct AddressComponentsValues {
    public var addrCountryCode: String?
    public var addrAptSuite: String?
    public var addrStreet1: String?
    public var addrStreet2: String?
    public var addrLocality: String?
    public var addrCity: String?
    public var addrStateProvFull: String?
    public var addrStateProvCode: String?
    public var addrPostalCode: String?
}

/*public func == (lhs: AddressComponentsValues, rhs: AddressComponentsValues) -> Bool {
    return lhs.addrCountryCode == rhs.addrCountryCode && lhs.addrAptSuite == rhs.addrAptSuite && lhs.addrStreet1 == rhs.addrStreet1 && lhs.addrStreet2 == rhs.addrStreet2 && lhs.addrCity == rhs.addrCity && lhs.addrStateProvFull == rhs.addrStateProvFull && lhs.addrStateProvCode == rhs.addrStateProvCode && lhs.addrPostalCode == rhs.addrPostalCode
}*/

// the following fields can selectively be shown by this Row;
// their tags, formatters, and placeholders can optionally be set or overriden
// fields are composed and shown in the order presented below (shown ordering cannot be changed)
public struct AddressComponentsShown {
    public var addrCountryCode = AddrCountryCode()
    public var addrAptSuite = AddrAptSuite()
    public var addrStreet1 = AddrStreet1()
    public var addrStreet2 = AddrStreet2()
    public var addrLocality = AddrLocality()
    public var addrCity = AddrCity()
    public var addrStateProv = AddrStateProv()
    public var addrPostalCode = AddrPostalCode()
    
    public struct AddrCountryCode {
        public var shown:Bool = true
        public var tag:String? = "Country"
        public var initialCountryCode:String = "US"
        public var placeholder:String? = "US"
        public var countryCodes:[CodePair]? = nil
        public var retainObject:Any? = nil
    }
    public struct AddrAptSuite {
        public var shown:Bool = true
        public var tag:String? = "Apt/Suite"
        public var placeholder:String? = "Suite#"
        public var formatter:Formatter? = nil
    }
    public struct AddrStreet1 {
        public var shown:Bool = true
        public var tag:String? = "Street1"
        public var placeholder:String? = "Street"
        public var formatter:Formatter? = nil
    }
    public struct AddrStreet2 {
        public var shown:Bool = false
        public var tag:String? = "Street2"
        public var placeholder:String? = "Street addtl"
        public var formatter:Formatter? = nil
    }
    public struct AddrLocality {
        public var shown:Bool = false
        public var tag:String? = "Locality"
        public var placeholder:String? = "Locality"
        public var formatter:Formatter? = nil
    }
    public struct AddrCity {
        public var shown:Bool = true
        public var tag:String? = "City"
        public var placeholder:String? = "City"
        public var formatter:Formatter? = nil
    }
    public struct AddrStateProv {
        public var shown:Bool = true
        public var asStateCodeChooser:Bool = true
        public var defaultCountryCode:String = "US"
        public var tag:String? = "State"
        public var placeholder:String? = "State/Province"
        public var formatter:Formatter? = nil
        public var stateProvCodes:[CodePair]? = nil
        public var retainObject:Any? = nil
    }
    public struct AddrPostalCode {
        public var shown:Bool = true
        public var onlyNumeric:Bool = false
        public var tag:String? = "PostalCode"
        public var placeholder:String? = "Postal#"
        public var formatter:Formatter? = nil
    }
    
    public init() {}
    
    public func requiresRelayout(comparedTo:AddressComponentsShown) -> Bool {
        if  self.addrCountryCode.shown != comparedTo.addrCountryCode.shown ||
            self.addrAptSuite.shown != comparedTo.addrAptSuite.shown ||
            self.addrStreet1.shown != comparedTo.addrStreet1.shown ||
            self.addrStreet2.shown != comparedTo.addrStreet2.shown ||
            self.addrLocality.shown != comparedTo.addrLocality.shown ||
            self.addrCity.shown != comparedTo.addrCity.shown ||
            self.addrStateProv.shown != comparedTo.addrStateProv.shown ||
            self.addrPostalCode.shown != comparedTo.addrPostalCode.shown ||
            self.addrStateProv.asStateCodeChooser != comparedTo.addrStateProv.asStateCodeChooser { return true }
        return false
    }
}

// Base class row for Eureka
public final class AddressComponentsRow: _AddressComponentsRow, RowType {
    private var cTag:String = "EuRAC"
    
    required public init(tag: String?) {
        super.init(tag: tag)
        // set the cellProvider to default (which means the fields are constructed by the Cell
        //cellProvider = CellProvider<AddrComponentsCell>()
    }
}

// Subclass row for Eureka
open class _AddressComponentsRow : Row<AddressComponentsCell> {
    private var cTag:String = "EuR_AC"
    public var title2:String? = nil
    
    open var addrComponentsShown:AddressComponentsShown {
        set (newValue) {
            let needsRelayout:Bool = _addrComponentsShown.requiresRelayout(comparedTo: newValue)
            _addrComponentsShown = newValue
            if _cell != nil && needsRelayout {
                cell.relayout()
                updateCell()
            }
        }
        get {
            return _addrComponentsShown
        }
    }
    open var addrComponentsValues:AddressComponentsValues {
        set (newValue) {
            _addrComponentsValues = newValue
            super.value = self.makeValues()
            if _cell != nil { updateCell() }
        }
        get {
            return _addrComponentsValues
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
    
    open var countryCodeFinishedEditing:((AddressComponentsCell, _AddressComponentsRow) -> Void) = { _,_ in }
    
    internal var _addrComponentsShown:AddressComponentsShown = AddressComponentsShown()
    internal var _addrComponentsValues:AddressComponentsValues = AddressComponentsValues()
    
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
        if self._addrComponentsShown.addrCountryCode.shown {
            result[self._addrComponentsShown.addrCountryCode.tag ?? "Country"] = _addrComponentsValues.addrCountryCode
        }
        if self._addrComponentsShown.addrAptSuite.shown {
            result[self._addrComponentsShown.addrAptSuite.tag ?? "Apt/Suite"] = _addrComponentsValues.addrAptSuite
        }
        if self._addrComponentsShown.addrStreet1.shown {
            result[self._addrComponentsShown.addrStreet1.tag ?? "Street1"] = _addrComponentsValues.addrStreet1
        }
        if self._addrComponentsShown.addrStreet2.shown {
            result[self._addrComponentsShown.addrStreet2.tag ?? "Street2"] = _addrComponentsValues.addrStreet2
        }
        if self._addrComponentsShown.addrLocality.shown {
            result[self._addrComponentsShown.addrLocality.tag ?? "Locality"] = _addrComponentsValues.addrLocality
        }
        if self._addrComponentsShown.addrCity.shown {
            result[self._addrComponentsShown.addrCity.tag ?? "City"] = _addrComponentsValues.addrCity
        }
        if self._addrComponentsShown.addrStateProv.shown {
            if self._addrComponentsShown.addrStateProv.asStateCodeChooser {
                result[self._addrComponentsShown.addrStateProv.tag ?? "State"] = _addrComponentsValues.addrStateProvCode
            } else {
                result[self._addrComponentsShown.addrStateProv.tag ?? "State"] = _addrComponentsValues.addrStateProvFull
            }
        }
        if self._addrComponentsShown.addrPostalCode.shown {
            result[self._addrComponentsShown.addrPostalCode.tag ?? "PostalCode"] = _addrComponentsValues.addrPostalCode
        }
        return result
    }

    // extract the current values from pairs or a single pair
    private func extractFromValues(values:[String:String?]?) {
        if values == nil {
            _addrComponentsValues.addrCountryCode = nil
            _addrComponentsValues.addrAptSuite = nil
            _addrComponentsValues.addrStreet1 = nil
            _addrComponentsValues.addrStreet2 = nil
            _addrComponentsValues.addrLocality = nil
            _addrComponentsValues.addrCity = nil
            _addrComponentsValues.addrStateProvFull = nil
            _addrComponentsValues.addrStateProvCode = nil
            _addrComponentsValues.addrPostalCode = nil
        } else {
            _addrComponentsValues.addrCountryCode = values![self._addrComponentsShown.addrCountryCode.tag ?? "Country"] as? String
            _addrComponentsValues.addrAptSuite = values![self._addrComponentsShown.addrAptSuite.tag ?? "Apt/Suite"] as? String
            _addrComponentsValues.addrStreet1 = values![self._addrComponentsShown.addrStreet1.tag ?? "Street1"] as? String
            _addrComponentsValues.addrStreet2 = values![self._addrComponentsShown.addrStreet2.tag ?? "Street2"] as? String
            _addrComponentsValues.addrLocality = values![self._addrComponentsShown.addrLocality.tag ?? "Locality"] as? String
            _addrComponentsValues.addrCity = values![self._addrComponentsShown.addrCity.tag ?? "City"] as? String
            if self._addrComponentsShown.addrStateProv.asStateCodeChooser {
                _addrComponentsValues.addrStateProvCode = values![self._addrComponentsShown.addrStateProv.tag ?? "State"] as? String
            } else {
                _addrComponentsValues.addrStateProvFull = values![self._addrComponentsShown.addrStateProv.tag ?? "State"] as? String
            }
            _addrComponentsValues.addrPostalCode = values![self._addrComponentsShown.addrPostalCode.tag ?? "PostalCode"] as? String
        }
    }
}

// Base class cell for Eureka
public class AddressComponentsCell: Cell<[String:String?]>, CellType, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    private var cTag:String = "EuCAC"
    
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var countryTextField: UITextField?
    @IBOutlet public weak var aptSuiteTextField: UITextField?
    @IBOutlet public weak var street1TextField: UITextField?
    @IBOutlet public weak var street2TextField: UITextField?
    @IBOutlet public weak var localityTextField: UITextField?
    @IBOutlet public weak var cityTextField: UITextField?
    @IBOutlet public weak var stateProvTextField: UITextField?
    @IBOutlet public weak var postalCodeTextField: UITextField?
    
    internal var setupCompleted:Bool = false
    private var awakeFromNibInvoked:Bool = false
    private var _height:CGFloat = 46.0
    private var verticalPad:Int = 10
    open var textFieldTabOrder:[UITextField] = []
    private var composedLayout:ComposedLayout = ComposedLayout(contentView: nil, row: nil, cellHasManualHeight: true)
    private var dynamicConstraints:[NSLayoutConstraint] = []
    private let alphaInvalidChars:CharacterSet = CharacterSet(charactersIn:"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 ").inverted
    private let numericInvalidChars:CharacterSet = CharacterSet(charactersIn:"1234567890 ").inverted
    
    lazy public var countryPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.tag = 4004
        picker.delegate = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    lazy public var statePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.tag = 4005
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
        self.titleLabel?.setContentCompressionResistancePriority(UILayoutPriority.compressPriLessLikely, for: .horizontal)
        
        let tf1 = UITextField()
        self.countryTextField = tf1
        
        let tf2 = UITextField()
        self.aptSuiteTextField = tf2
        
        let tf3 = UITextField()
        self.street1TextField = tf3
        
        let tf4 = UITextField()
        self.street2TextField = tf4
        
        let tf5 = UITextField()
        self.localityTextField = tf5
        
        let tf6 = UITextField()
        self.cityTextField = tf6
        
        let tf7 = UITextField()
        self.stateProvTextField = tf7
        
        let tf8 = UITextField()
        self.postalCodeTextField = tf8
        
        // for convenience place all the fields for now in the tab order
        // pre-setup all the text field's; they can be overriden later by user of in-Form overrides
        self.contentView.addSubview(titleLabel!)
        self.textFieldTabOrder = [self.countryTextField!, self.aptSuiteTextField!, self.street1TextField!, self.street2TextField!, self.localityTextField!, self.cityTextField!, self.stateProvTextField!, self.postalCodeTextField!]
        for textField in self.textFieldTabOrder {
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.setContentHuggingPriority(UILayoutPriority.hugPriStandardField, for: .horizontal)
            textField.borderStyle = UITextField.BorderStyle.bezel
            textField.autocapitalizationType = .words
            textField.textAlignment = .left
            textField.clearButtonMode = .whileEditing
            textField.isHidden = true
            textField.isEnabled = false
            textField.delegate = self
            textField.font = .preferredFont(forTextStyle: UIFont.TextStyle.body)
            textField.addTarget(self, action: #selector(AddressComponentsCell.textFieldDidChange(_:)), for: .editingChanged)
            self.contentView.addSubview(textField)
        }
        self.countryTextField!.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
        self.aptSuiteTextField!.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
        self.postalCodeTextField!.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
        
        self.countryTextField!.clearButtonMode = .never
        
        if #available(iOSApplicationExtension 10.0, *) {
            self.street1TextField?.textContentType = .streetAddressLine1
            self.street2TextField?.textContentType = .streetAddressLine2
            self.localityTextField?.textContentType = .addressCity
            self.cityTextField?.textContentType = .addressCity
            self.stateProvTextField?.textContentType = .sublocality
            self.postalCodeTextField?.textContentType = .postalCode
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
        let addrRow = self.row as! _AddressComponentsRow
        var potentialLayoutChanges:Bool = false
        
        detailTextLabel?.text = nil
        textLabel?.text = nil
        
        if (row.title ?? "").isEmpty {
            if self.titleLabel!.text != nil { potentialLayoutChanges = true }
            self.titleLabel!.text = nil
        } else {
            if (addrRow.title2 ?? "").isEmpty {
                if self.titleLabel!.text != row.title! || self.titleLabel!.numberOfLines != 1 { potentialLayoutChanges = true }
                self.titleLabel!.numberOfLines = 1
                self.titleLabel!.text = row.title!
            } else {
                if self.titleLabel!.text != row.title! + "\n" + addrRow.title2! || self.titleLabel!.numberOfLines != 2 { potentialLayoutChanges = true }
                self.titleLabel!.numberOfLines = 2
                self.titleLabel!.text = row.title! + "\n" + addrRow.title2!
            }
            if !row.isValid { self.titleLabel!.textColor = UIColor.red }
            else if row.isHighlighted { self.titleLabel!.textColor = tintColor }
        }

        if addrRow._addrComponentsShown.addrCountryCode.shown {
            self.countryTextField?.text = addrRow._addrComponentsValues.addrCountryCode
            if !(addrRow._addrComponentsShown.addrCountryCode.placeholder ?? "").isEmpty {
                self.countryTextField?.placeholder = addrRow._addrComponentsShown.addrCountryCode.placeholder!
            }
        }
        if addrRow._addrComponentsShown.addrAptSuite.shown {
            self.aptSuiteTextField?.text = addrRow._addrComponentsValues.addrAptSuite
            if !(addrRow._addrComponentsShown.addrAptSuite.placeholder ?? "").isEmpty {
                self.aptSuiteTextField?.placeholder = addrRow._addrComponentsShown.addrAptSuite.placeholder!
            }
        }
        if addrRow._addrComponentsShown.addrStreet1.shown {
            self.street1TextField?.text = addrRow._addrComponentsValues.addrStreet1
            if !(addrRow._addrComponentsShown.addrStreet1.placeholder ?? "").isEmpty {
                self.street1TextField?.placeholder = addrRow._addrComponentsShown.addrStreet1.placeholder!
            }
        }
        if addrRow._addrComponentsShown.addrStreet2.shown {
            self.street2TextField?.text = addrRow._addrComponentsValues.addrStreet2
            if !(addrRow._addrComponentsShown.addrStreet2.placeholder ?? "").isEmpty {
                self.street2TextField?.placeholder = addrRow._addrComponentsShown.addrStreet2.placeholder!
            }
        }
        if addrRow._addrComponentsShown.addrLocality.shown {
            self.localityTextField?.text = addrRow._addrComponentsValues.addrLocality
            if !(addrRow._addrComponentsShown.addrLocality.placeholder ?? "").isEmpty {
                self.localityTextField?.placeholder = addrRow._addrComponentsShown.addrLocality.placeholder!
            }
        }
        if addrRow._addrComponentsShown.addrCity.shown {
            self.cityTextField?.text = addrRow._addrComponentsValues.addrCity
            if !(addrRow._addrComponentsShown.addrCity.placeholder ?? "").isEmpty {
                self.cityTextField?.placeholder = addrRow._addrComponentsShown.addrCity.placeholder!
            }
        }
        if addrRow._addrComponentsShown.addrStateProv.shown {
            if addrRow._addrComponentsShown.addrStateProv.asStateCodeChooser { self.stateProvTextField?.text = addrRow._addrComponentsValues.addrStateProvCode }
            else { self.stateProvTextField?.text = addrRow._addrComponentsValues.addrStateProvFull }
            if !(addrRow._addrComponentsShown.addrStateProv.placeholder ?? "").isEmpty {
                self.stateProvTextField?.placeholder = addrRow._addrComponentsShown.addrStateProv.placeholder!
            }
        }
        if addrRow._addrComponentsShown.addrPostalCode.shown {
            if addrRow._addrComponentsShown.addrPostalCode.onlyNumeric {
                self.postalCodeTextField?.keyboardType = .numberPad
                self.postalCodeTextField?.autocapitalizationType = .none
            }
            else {
                self.postalCodeTextField?.keyboardType = .namePhonePad
                self.postalCodeTextField?.autocapitalizationType = .allCharacters
            }
            self.postalCodeTextField?.delegate = self
            self.postalCodeTextField?.text = addrRow._addrComponentsValues.addrPostalCode
            if !(addrRow._addrComponentsShown.addrPostalCode.placeholder ?? "").isEmpty {
                self.postalCodeTextField?.placeholder = addrRow._addrComponentsShown.addrPostalCode.placeholder!
            }
        }
        
        if addrRow._addrComponentsShown.addrCountryCode.shown && (addrRow._addrComponentsShown.addrCountryCode.countryCodes?.count ?? 0) > 0 {
            self.countryTextField?.inputView = self.countryPicker
        } else {
            self.countryTextField?.inputView = nil
        }
        
        if addrRow._addrComponentsShown.addrStateProv.shown && addrRow._addrComponentsShown.addrStateProv.asStateCodeChooser && (addrRow._addrComponentsShown.addrStateProv.stateProvCodes?.count ?? 0) > 0 {
            self.stateProvTextField?.inputView = self.statePicker
            self.stateProvTextField?.clearButtonMode = .never
        } else {
            self.stateProvTextField?.inputView = nil
            self.stateProvTextField?.clearButtonMode = .whileEditing
        }
        
        if potentialLayoutChanges { self.relayout() }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Country and State code picker handlers
    /////////////////////////////////////////////////////////////////////////

    open func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let addrRow = self.row as! _AddressComponentsRow
        if pickerView.tag == 4004 {
            return addrRow.addrComponentsShown.addrCountryCode.countryCodes?.count ?? 0
        } else if pickerView.tag == 4005 {
            return addrRow.addrComponentsShown.addrStateProv.stateProvCodes?.count ?? 0
        }
        return 0
        
    }
    
    open func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let addrRow = self.row as! _AddressComponentsRow
        if pickerView.tag == 4004 {
            guard (addrRow.addrComponentsShown.addrCountryCode.countryCodes?.count ?? 0) > 0 else {
                return nil
            }
            return addrRow.addrComponentsShown.addrCountryCode.countryCodes![row].valueString + " (" + addrRow.addrComponentsShown.addrCountryCode.countryCodes![row].codeString + ")"
        } else if pickerView.tag == 4005 {
            guard (addrRow.addrComponentsShown.addrStateProv.stateProvCodes?.count ?? 0) > 0 else {
                return nil
            }
            return addrRow.addrComponentsShown.addrStateProv.stateProvCodes![row].valueString + " (" + addrRow.addrComponentsShown.addrStateProv.stateProvCodes![row].codeString + ")"
        }
        return nil
    }
    
    open func pickerView(_ pickerView: UIPickerView, didSelectRow rowNumber: Int, inComponent component: Int) {
        let addrRow = self.row as! _AddressComponentsRow
        if pickerView.tag == 4004 {
            guard (addrRow.addrComponentsShown.addrCountryCode.countryCodes?.count ?? 0) > 0 else {
                return
            }
            addrRow._addrComponentsValues.addrCountryCode = addrRow.addrComponentsShown.addrCountryCode.countryCodes![rowNumber].codeString
            update()
        } else if pickerView.tag == 4005 {
            guard (addrRow.addrComponentsShown.addrStateProv.stateProvCodes?.count ?? 0) > 0 else {
                return
            }
            addrRow._addrComponentsValues.addrStateProvCode = addrRow.addrComponentsShown.addrStateProv.stateProvCodes![rowNumber].codeString
            update()
        }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Layout the Cell's textFields and controls, and update constraints
    /////////////////////////////////////////////////////////////////////////
    
    // called whenever all the fields should be positioned (either first time or because addrComponentsShown was changed or because of rotation);
    // this is called BEFORE update() above;  constraint updating after this relayout will occur during layoutSubviews() which is iOS invoked
    internal func relayout() {
//debugPrint("\(self.cTag).relayout STARTED contentView.frame.size=\(contentView.frame.size)")
        let addrRow = self.row as! _AddressComponentsRow
        
//debugPrint("\(self.cTag).relayout titleLabel.size=\(self.titleLabel!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout countryTextField.size=\(self.countryTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout aptSuiteTextField.size=\(self.aptSuiteTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout street1TextField.size=\(self.street1TextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout street2TextField.size=\(self.street2TextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout localityTextField.size=\(self.localityTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout cityTextField.size=\(self.cityTextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout stateProvTextField.size=\(self.street2TextField!.layer.frame.size)")
//debugPrint("\(self.cTag).relayout postalTextField.size=\(self.street2TextField!.layer.frame.size)")
        
        var fieldsHeight:CGFloat = 0.0
        self.textFieldTabOrder = []
        if addrRow._addrComponentsShown.addrCountryCode.shown {
            if self.countryTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.countryTextField!.layer.frame.size.height }
            self.countryTextField?.isHidden = false
            self.countryTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.countryTextField!)
        } else { self.countryTextField?.isHidden = true; self.countryTextField?.isEnabled = false }
        if addrRow._addrComponentsShown.addrAptSuite.shown {
            if self.aptSuiteTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.aptSuiteTextField!.layer.frame.size.height }
            self.aptSuiteTextField?.isHidden = false
            self.aptSuiteTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.aptSuiteTextField!)
        } else { self.aptSuiteTextField?.isHidden = true; self.aptSuiteTextField?.isEnabled = false }
        if addrRow._addrComponentsShown.addrStreet1.shown {
            if self.street1TextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.street1TextField!.layer.frame.size.height }
            self.street1TextField?.isHidden = false
            self.street1TextField?.isEnabled = true
            self.textFieldTabOrder.append(self.street1TextField!)
        } else { self.street1TextField?.isHidden = true; self.street1TextField?.isEnabled = false }
        if addrRow._addrComponentsShown.addrStreet2.shown {
            if self.street2TextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.street2TextField!.layer.frame.size.height }
            self.street2TextField?.isHidden = false
            self.street2TextField?.isEnabled = true
            self.textFieldTabOrder.append(self.street2TextField!)
        } else { self.street2TextField?.isHidden = true; self.street2TextField?.isEnabled = false }
        if addrRow._addrComponentsShown.addrLocality.shown {
            if self.localityTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.localityTextField!.layer.frame.size.height }
            self.localityTextField?.isHidden = false
            self.localityTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.localityTextField!)
        } else { self.localityTextField?.isHidden = true; self.localityTextField?.isEnabled = false }
        if addrRow._addrComponentsShown.addrCity.shown {
            if self.cityTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.cityTextField!.layer.frame.size.height }
            self.cityTextField?.isHidden = false
            self.cityTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.cityTextField!)
        } else { self.cityTextField?.isHidden = true; self.cityTextField?.isEnabled = false }
        if addrRow._addrComponentsShown.addrStateProv.shown {
            if self.stateProvTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.stateProvTextField!.layer.frame.size.height }
            self.stateProvTextField?.isHidden = false
            self.stateProvTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.stateProvTextField!)
        } else { self.stateProvTextField?.isHidden = true; self.stateProvTextField?.isEnabled = false }
        if addrRow._addrComponentsShown.addrPostalCode.shown {
            if self.postalCodeTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.postalCodeTextField!.layer.frame.size.height }
            self.postalCodeTextField?.isHidden = false
            self.postalCodeTextField?.isEnabled = true
            self.textFieldTabOrder.append(self.postalCodeTextField!)
        } else { self.postalCodeTextField?.isHidden = true; self.postalCodeTextField?.isEnabled = false }
        
        self.composeLayout(fieldsHeight: fieldsHeight)
        
        var newHeight:CGFloat = 0.0
        if !(addrRow.title ?? "").isEmpty {
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
        let addrRow = self.row as! _AddressComponentsRow
        let newComposedLayout = ComposedLayout(contentView: self.contentView, row: row, cellHasManualHeight: true, titleAreaRatioWidthToMove: 0.2)
        
        if !(addrRow.title ?? "").isEmpty {
            newComposedLayout.addTextTitleFirstControl(forControl: ComposedLayoutControl(controlName: "titleLabel", control: self.titleLabel!))
        }
        
        var countryNeeded:Bool = addrRow._addrComponentsShown.addrCountryCode.shown
        var aptSuiteNeeded:Bool = addrRow._addrComponentsShown.addrAptSuite.shown
        
        // possible first line
        if countryNeeded && aptSuiteNeeded {
            let countryCLC = ComposedLayoutControl(controlName: "countryTextField", control: self.countryTextField!, isFixedWidthOrLess: true)
            newComposedLayout.addControlToCurrentLine(forControl: countryCLC)
            newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "aptSuiteTextField", control: self.aptSuiteTextField!))
            newComposedLayout.moveToNextLine()
            countryNeeded = false
            aptSuiteNeeded = false
        }
        
        // always its own line
        if addrRow._addrComponentsShown.addrStreet1.shown {
            newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "street1TextField", control: self.street1TextField!))
            newComposedLayout.moveToNextLine()
        }
        
        // possible third line
        if addrRow._addrComponentsShown.addrStreet2.shown {
            if aptSuiteNeeded {
                newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "street2TextField", control: self.street2TextField!))
                newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "aptSuiteTextField", control: self.aptSuiteTextField!))
                newComposedLayout.moveToNextLine()
                aptSuiteNeeded = false
            } else {
                newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "street2TextField", control: self.street2TextField!))
                newComposedLayout.moveToNextLine()
            }
        }
        
        // possible 4th line
        if addrRow._addrComponentsShown.addrLocality.shown {
            if aptSuiteNeeded {
                newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "localityTextField", control: self.localityTextField!))
                newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "aptSuiteTextField", control: self.aptSuiteTextField!))
                newComposedLayout.moveToNextLine()
                aptSuiteNeeded = false
            } else {
                newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "localityTextField", control: self.localityTextField!))
                newComposedLayout.moveToNextLine()
            }
        }
        
        // possible 5th line
        if aptSuiteNeeded {
            newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "aptSuiteTextField", control: self.aptSuiteTextField!))
            aptSuiteNeeded = false
        } else if countryNeeded {
            let countryCLC = ComposedLayoutControl(controlName: "countryTextField", control: self.countryTextField!, isFixedWidthOrLess: true)
            newComposedLayout.addControlToCurrentLine(forControl: countryCLC)
            countryNeeded = false
        }
        if addrRow._addrComponentsShown.addrCity.shown {
            newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "cityTextField", control: self.cityTextField!))
        }
        if newComposedLayout.controlsCountCurrentLine() > 1 { newComposedLayout.moveToNextLine() }
        
        // possible 6th line
        if !addrRow._addrComponentsShown.addrStateProv.shown {
            if addrRow._addrComponentsShown.addrPostalCode.shown {
                newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "postalCodeTextField", control: self.postalCodeTextField!))
            }
        } else {
            if !addrRow._addrComponentsShown.addrStateProv.asStateCodeChooser {
                // full state wanted; place it and any remaining on another line
                newComposedLayout.moveToNextLine()
                newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "stateProvTextField", control: self.stateProvTextField!))
                if addrRow._addrComponentsShown.addrPostalCode.shown {
                    newComposedLayout.addControlToCurrentLine(forControl: ComposedLayoutControl(controlName: "postalCodeTextField", control: self.postalCodeTextField!))
                }
            } else {
                // state code wanted; this is a <= width field and needs .noTrail if it is the only thing on the Line
                if newComposedLayout.controlsCountCurrentLine() >= 2 {
                    // current line already has two items on it; need to place any remaining on another line
                    newComposedLayout.moveToNextLine()
                }
                let stateCodeCLC = ComposedLayoutControl(controlName: "stateProvTextField", control: self.stateProvTextField!, isFixedWidthOrLess: true)
                newComposedLayout.addControlToCurrentLine(forControl: stateCodeCLC)
                if addrRow._addrComponentsShown.addrPostalCode.shown {
                    let postalCLC = ComposedLayoutControl(controlName: "postalCodeTextField", control: self.postalCodeTextField!)
                    newComposedLayout.addControlToCurrentLine(forControl: postalCLC)
                }
            }
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
        let addrRow = self.row as! _AddressComponentsRow
        var views: [String: AnyObject] = [:]
        
        // build up the necessary pre-information depending on what is supposed to be shown
        var fieldsWidth:CGFloat = contentView.frame.size.width - 40.0
        var titleHeight:CGFloat = 0.0
        var hasTitleLines = 0
        if !(addrRow.title ?? "").isEmpty {
            if titleLabel!.layer.frame.size.height > titleHeight { titleHeight = titleLabel!.layer.frame.size.height }
//debugPrint("\(self.cTag).updateConstraints titleLabel.frame.size=\(titleLabel!.layer.frame.size)")
            fieldsWidth = fieldsWidth - titleLabel!.layer.frame.size.width - 5.0
            if (addrRow.title2 ?? "").isEmpty { hasTitleLines = 1 }
            else { hasTitleLines = 2 }
        }
        
        var fieldsHeight:CGFloat = 0.0
        if self.countryTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.countryTextField!.layer.frame.size.height }
        if self.aptSuiteTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.aptSuiteTextField!.layer.frame.size.height }
        if self.street1TextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.street1TextField!.layer.frame.size.height }
        if self.street2TextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.street2TextField!.layer.frame.size.height }
        if self.localityTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.localityTextField!.layer.frame.size.height }
        if self.cityTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.cityTextField!.layer.frame.size.height }
        if self.stateProvTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.stateProvTextField!.layer.frame.size.height }
        if self.postalCodeTextField!.layer.frame.size.height > fieldsHeight { fieldsHeight = self.postalCodeTextField!.layer.frame.size.height }
        
        // got anything to create?
        if hasTitleLines == 0 && (self.composedLayout.linesCount() == 0 || self.composedLayout.controlsCount(inLine: 0) <= 0)  { return }
        
        // yes, generate the bulk of the constraints
        (views, self.dynamicConstraints) = self.composedLayout.generateDynamicConstraints(contentView: contentView, noBottomsOrEnds: (fieldsHeight == 0.0))
        
        // additional specific constraints
        if addrRow._addrComponentsShown.addrCountryCode.shown {
//debugPrint("\(self.cTag).updateConstraints Width: countryTextField<=50")
            self.dynamicConstraints += [NSLayoutConstraint(item: self.countryTextField!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 75)]
        }
        if addrRow._addrComponentsShown.addrCity.shown {
//debugPrint("\(self.cTag).updateConstraints Width: cityTextField>=0.3")
            self.dynamicConstraints += [NSLayoutConstraint(item: self.cityTextField!, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: contentView, attribute: .width, multiplier: 0.3, constant: 0)]
        }
        if addrRow._addrComponentsShown.addrStateProv.shown {
            if addrRow._addrComponentsShown.addrStateProv.asStateCodeChooser {
                if self.composedLayout.nonMovedLinesCount() == 1 && !addrRow._addrComponentsShown.addrPostalCode.shown && addrRow._addrComponentsShown.addrCountryCode.shown {
                    // special case for FC_AddrCntryStCodes
//debugPrint("\(self.cTag).updateConstraints Width: stateProvTextField<=200")
                    self.dynamicConstraints += [NSLayoutConstraint(item: self.stateProvTextField!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)]
                    self.stateProvTextField!.setContentHuggingPriority(UILayoutPriority.hugPriStandardField, for: .horizontal)
                } else {
//debugPrint("\(self.cTag).updateConstraints Width: stateProvTextField<=50")
                    self.dynamicConstraints += [NSLayoutConstraint(item: self.stateProvTextField!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)]
                    self.stateProvTextField!.setContentHuggingPriority(UILayoutPriority.hugPriSmallField, for: .horizontal)
                }
            } else {
//debugPrint("\(self.cTag).updateConstraints Width: stateProvTextField>=0.3")
                self.dynamicConstraints += [NSLayoutConstraint(item: self.stateProvTextField!, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: contentView, attribute: .width, multiplier: 0.3, constant: 0)]
                self.stateProvTextField!.setContentHuggingPriority(UILayoutPriority.hugPriStandardField, for: .horizontal)
            }
        }
        if addrRow._addrComponentsShown.addrPostalCode.shown {
//debugPrint("\(self.cTag).updateConstraints Width: postalCodeTextField>=0.2")
            self.dynamicConstraints += [NSLayoutConstraint(item: self.postalCodeTextField!, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: contentView, attribute: .width, multiplier: 0.2, constant: 0)]
        }
        if addrRow._addrComponentsShown.addrAptSuite.shown {
//debugPrint("\(self.cTag).updateConstraints Width: aptSuiteTextField>=0.2")
            let aptSuiteConstraint:NSLayoutConstraint = NSLayoutConstraint(item: self.aptSuiteTextField!, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: contentView, attribute: .width, multiplier: 0.2, constant: 0)
            aptSuiteConstraint.priority = UILayoutPriority(rawValue: 990.0)
            self.dynamicConstraints += [aptSuiteConstraint]
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
                countryTextField?.canBecomeFirstResponder == true ||
                aptSuiteTextField?.canBecomeFirstResponder == true ||
                street1TextField?.canBecomeFirstResponder == true ||
                street2TextField?.canBecomeFirstResponder == true ||
                localityTextField?.canBecomeFirstResponder == true ||
                cityTextField?.canBecomeFirstResponder == true ||
                stateProvTextField?.canBecomeFirstResponder == true ||
                postalCodeTextField?.canBecomeFirstResponder == true
        )
    }
    
    open override func cellBecomeFirstResponder(withDirection direction: Direction) -> Bool {
        return direction == .down ? self.textFieldTabOrder.first?.becomeFirstResponder() ?? false : self.textFieldTabOrder.last?.becomeFirstResponder() ?? false
    }
    
    open override func cellResignFirstResponder() -> Bool {
        return countryTextField?.resignFirstResponder() ?? true
            && aptSuiteTextField?.resignFirstResponder() ?? true
            && street1TextField?.resignFirstResponder() ?? true
            && street2TextField?.resignFirstResponder() ?? true
            && localityTextField?.resignFirstResponder() ?? true
            && cityTextField?.resignFirstResponder() ?? true
            && stateProvTextField?.resignFirstResponder() ?? true
            && postalCodeTextField?.resignFirstResponder() ?? true
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
        let addrRow = self.row as! _AddressComponentsRow
        // Attempt to find the range of invalid characters in the input string. This returns an optional if not nil then invalid char is present.
        if textField == self.postalCodeTextField {
            if addrRow._addrComponentsShown.addrPostalCode.onlyNumeric {
                let testRange = string.rangeOfCharacter(from: numericInvalidChars)
                if testRange != nil { return false }
            } else {
                let testRange = string.rangeOfCharacter(from: alphaInvalidChars)
                if testRange != nil { return false }
            }
        }
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
        let addrRow = self.row as! _AddressComponentsRow
        switch textField {
        case let field1 where field1 == self.countryTextField:
            if (field1.text ?? "").isEmpty {
                addrRow._addrComponentsValues.addrCountryCode = nil
            } else {
                addrRow._addrComponentsValues.addrCountryCode = field1.text
            }
            break
            
        case let field2 where field2 == self.aptSuiteTextField:
            if (field2.text ?? "").isEmpty {
                addrRow._addrComponentsValues.addrAptSuite = nil
            } else {
                addrRow._addrComponentsValues.addrAptSuite = field2.text
            }
            break
            
        case let field3 where field3 == self.street1TextField:
            if (field3.text ?? "").isEmpty {
                addrRow._addrComponentsValues.addrStreet1 = nil
            } else {
                addrRow._addrComponentsValues.addrStreet1 = field3.text
            }
            break
            
        case let field4 where field4 == self.street2TextField:
            if (field4.text ?? "").isEmpty {
                addrRow._addrComponentsValues.addrStreet2 = nil
            } else {
                addrRow._addrComponentsValues.addrStreet2 = field4.text
            }
            break
            
        case let field5 where field5 == self.localityTextField:
            if (field5.text ?? "").isEmpty {
                addrRow._addrComponentsValues.addrLocality = nil
            } else {
                addrRow._addrComponentsValues.addrLocality = field5.text
            }
            break
            
        case let field6 where field6 == self.cityTextField:
            if (field6.text ?? "").isEmpty {
                addrRow._addrComponentsValues.addrCity = nil
            } else {
                addrRow._addrComponentsValues.addrCity = field6.text
            }
            break
        
        case let field7 where field7 == self.stateProvTextField:
            if (field7.text ?? "").isEmpty {
                addrRow._addrComponentsValues.addrStateProvFull = nil
                addrRow._addrComponentsValues.addrStateProvCode = nil
            } else {
                if addrRow._addrComponentsShown.addrStateProv.asStateCodeChooser { addrRow._addrComponentsValues.addrStateProvCode = field7.text }
                else { addrRow._addrComponentsValues.addrStateProvFull = field7.text }
            }
            break
            
        case let field8 where field8 == self.postalCodeTextField:
            if (field8.text ?? "").isEmpty {
                addrRow._addrComponentsValues.addrPostalCode = nil
            } else {
                field8.text = field8.text!.uppercased()
                addrRow._addrComponentsValues.addrPostalCode = field8.text!.uppercased()
            }
            break
            
        default:
            break
        }
        addrRow.value = addrRow.makeValues()
    }
    
    // our custom handler for textField changes when the textField loses FirstResponder
    @objc open func textFieldDidEndEditing_handler(_ textField : UITextField) {
        let addrRow = self.row as! _AddressComponentsRow
        var formatter:Formatter? = nil
        var formatter_field:UITextField? = nil

        self.textFieldDidChange(textField)
        
        switch textField {
        case let field1 where field1 == self.countryTextField:
            addrRow.countryCodeFinishedEditing(self, addrRow)
            break
            
        case let field2 where field2 == self.aptSuiteTextField:
            if !(field2.text ?? "").isEmpty && addrRow._addrComponentsShown.addrAptSuite.formatter != nil {
                formatter = addrRow._addrComponentsShown.addrAptSuite.formatter!
                formatter_field = field2
            }
            break
            
        case let field3 where field3 == self.street1TextField:
            if !(field3.text ?? "").isEmpty && addrRow._addrComponentsShown.addrStreet1.formatter != nil {
                formatter = addrRow._addrComponentsShown.addrStreet1.formatter!
                formatter_field = field3
            }
            break
            
        case let field4 where field4 == self.street2TextField:
            if !(field4.text ?? "").isEmpty && addrRow._addrComponentsShown.addrStreet2.formatter != nil {
                formatter = addrRow._addrComponentsShown.addrStreet2.formatter!
                formatter_field = field4
            }
            break
            
        case let field5 where field5 == self.localityTextField:
            if !(field5.text ?? "").isEmpty && addrRow._addrComponentsShown.addrLocality.formatter != nil {
                formatter = addrRow._addrComponentsShown.addrLocality.formatter!
                formatter_field = field5
            }
            break
            
        case let field6 where field6 == self.cityTextField:
            if !(field6.text ?? "").isEmpty && addrRow._addrComponentsShown.addrCity.formatter != nil  {
                formatter = addrRow._addrComponentsShown.addrCity.formatter!
                formatter_field = field6
            }
            break
            
        case let field7 where field7 == self.stateProvTextField:
            if !(field7.text ?? "").isEmpty && addrRow._addrComponentsShown.addrStateProv.formatter != nil {
                formatter = addrRow._addrComponentsShown.addrStateProv.formatter!
                formatter_field = field7
            }
            break
            
        case let field8 where field8 == self.postalCodeTextField:
            if !(field8.text ?? "").isEmpty && addrRow._addrComponentsShown.addrPostalCode.formatter != nil  {
                formatter = addrRow._addrComponentsShown.addrPostalCode.formatter!
                formatter_field = field8
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
            case let field2 where field2 == self.aptSuiteTextField:
                if didFormat {
                    addrRow._addrComponentsValues.addrAptSuite = formattedText.pointee as? String
                    self.aptSuiteTextField!.text = addrRow._addrComponentsValues.addrAptSuite
                } else { addrRow._addrComponentsValues.addrAptSuite = sourceText }
                break
            case let field3 where field3 == self.street1TextField:
                if didFormat {
                    addrRow._addrComponentsValues.addrStreet1 = formattedText.pointee as? String
                    self.street1TextField!.text = addrRow._addrComponentsValues.addrStreet1
                } else { addrRow._addrComponentsValues.addrStreet1 = sourceText }
                break
            case let field4 where field4 == self.street2TextField:
                if didFormat {
                    addrRow._addrComponentsValues.addrStreet2 = formattedText.pointee as? String
                    self.street2TextField!.text = addrRow._addrComponentsValues.addrStreet2
                } else { addrRow._addrComponentsValues.addrStreet2 = sourceText }
                break
            case let field5 where field5 == self.localityTextField:
                if didFormat {
                    addrRow._addrComponentsValues.addrLocality = formattedText.pointee as? String
                    self.localityTextField!.text = addrRow._addrComponentsValues.addrLocality
                } else { addrRow._addrComponentsValues.addrLocality = sourceText }
                break
            case let field6 where field6 == self.cityTextField:
                if didFormat {
                    addrRow._addrComponentsValues.addrCity = formattedText.pointee as? String
                    self.cityTextField!.text = addrRow._addrComponentsValues.addrCity
                } else { addrRow._addrComponentsValues.addrCity = sourceText }
                break
            case let field7 where field7 == self.stateProvTextField:
                if didFormat {
                    addrRow._addrComponentsValues.addrStateProvFull = formattedText.pointee as? String
                    self.stateProvTextField!.text = addrRow._addrComponentsValues.addrStateProvFull
                } else { addrRow._addrComponentsValues.addrStateProvFull = sourceText }
                break
            case let field8 where field8 == self.postalCodeTextField:
                if didFormat {
                    addrRow._addrComponentsValues.addrPostalCode = formattedText.pointee as? String
                    self.postalCodeTextField!.text = addrRow._addrComponentsValues.addrPostalCode
                } else { addrRow._addrComponentsValues.addrPostalCode = sourceText }
                break
            default:
                break
            }
            addrRow.value = addrRow.makeValues()
        }
    }
}
