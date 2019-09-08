//
//  EntryFormViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/9/18.
//

import Eureka

class EntryFormViewController: FormViewController {
    // member variables
    private var isVisible:Bool = false
    private var mFormIsBuilt:Bool = false
    private var mListenersEstablished:Bool = false
    private weak var mActiveTextField:UITextField? = nil
    private weak var mCurrentSection:Section? = nil
    private weak var mFullNameHiddenInserted:ECC_HiddenFullNameRow? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCEF"
    private let mThrownDomain:String = NSLocalizedString("EntryForm-ViewController", comment: "")
    private weak var mEntryVC:EntryViewController? = nil

    // outlets to screen controls

    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED \(self)")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED \(self)")
        super.viewDidLoad()
        
        // set overall form options
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED \(self)")
        super.viewWillAppear(animated)
        self.isVisible = true

        // locate our parent view controller; must be done in viewWillAppear() rather than viewDidLoad()
        self.mEntryVC = (self.parent as! EntryViewController)

        // setup a notification listener if the current Org or Form or Language has changed
        if self.mEntryVC!.mEFP != nil && !self.mListenersEstablished {
            NotificationCenter.default.addObserver(self, selector: #selector(noticeNewOrgForm(_:)), name: .APP_EFP_OrgFormChange, object: self.mEntryVC!.mEFP!)
            NotificationCenter.default.addObserver(self, selector: #selector(noticeNewLang(_:)), name: .APP_EFP_LangRegionChanged, object: self.mEntryVC!.mEFP!)
            self.mListenersEstablished = true
        }
        
        // build the form entirely; must be done in viewWillAppear since the code depends on having access to self.mEntryVC
        // note: viewWillAppear() will get invoked upon return from PushRows, so the form must not be rebuilt ad-hoc
        self.buildForm()        // buildForm() will decide whether to rebuild or not
    }
    
    // called by the framework when the view has fully *re-appeared*
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED \(self)")
        super.viewDidAppear(animated)
        
        // upon some returns there may be rows that are now tagged to become hidden or unhidden
        for row:BaseRow in form.allRows {
            row.evaluateHidden()
        }
//debugPrint("\(self.mCTAG).viewDidAppear tableView.reloadData()")
        tableView.reloadData()  // solves a problem when returned from a PushRow
    }
    
    // called by the framework when the view will soon disappear from the UI framework; needs to be done before viewDidDisappear() so self.parent is valid;
    // remember this does NOT necessarily mean the view is being dismissed since viewWillDisappear() will be called if this VC opens another VC;
    // need to forceably clear out the form so this VC will deinit()
    override func viewWillDisappear(_ animated:Bool) {
        if self.parent != nil {
            let myParent:EntryViewController = self.parent as! EntryViewController
            if myParent.mDismissing {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED AND PARENT VC IS DISMISSING parent=\(self.parent!)")
                form.removeAll()
                self.mFormIsBuilt = false
                tableView.reloadData()
                self.mFullNameHiddenInserted = nil
                self.mCurrentSection = nil
                self.mActiveTextField = nil
                if self.mEntryVC!.mEFP != nil && self.mListenersEstablished {
                    NotificationCenter.default.removeObserver(self, name: .APP_EFP_OrgFormChange, object: self.mEntryVC!.mEFP!)
                    NotificationCenter.default.removeObserver(self, name: .APP_EFP_LangRegionChanged, object: self.mEntryVC!.mEFP!)
                    self.mListenersEstablished = false
                }
                self.mEntryVC = nil
            } else {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED BUT PARENT VC is not being dismissed parent=\(self.parent!)")
            }
        } else {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED NO PARENT VC")
        }
        super.viewWillDisappear(animated)
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC
    override func viewDidDisappear(_ animated:Bool) {
        self.isVisible = false
        super.viewDidDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // iOS will call this upon rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
//debugPrint("\(self.mCTAG).viewWillTransition STARTED \(self)")
        
        // solves a problem when a variable TableViewCell height is changed during rotation
        tableView.reloadData()
    }
    
    // received a notification from our parent that the mainline EFP was just created and made ready; note it could indicate a nil during a factory reset
    public func noticeCreatedMainEFPPassThru() {
//debugPrint("\(self.mCTAG).noticeCreatedMainEFPPassThru STARTED \(self)")
        if self.mEntryVC!.mEFP != nil && !self.mListenersEstablished {
            NotificationCenter.default.addObserver(self, selector: #selector(noticeNewOrgForm(_:)), name: .APP_EFP_OrgFormChange, object: self.mEntryVC!.mEFP!)
            NotificationCenter.default.addObserver(self, selector: #selector(noticeNewLang(_:)), name: .APP_EFP_LangRegionChanged, object: self.mEntryVC!.mEFP!)
            self.mListenersEstablished = true
        }
        self.mFormIsBuilt = false       // allow a rebuild to take place
        self.buildForm()
    }
    
    // a factory reset is removing the mainline EFP; a noticeCreatedMainEFP() will get called shortly as well
    public func noticeRemovingMainEFPPassThru() {
//debugPrint("\(self.mCTAG).noticeRemovingMainEFPPassThru STARTED \(self)")
        if self.mEntryVC!.mEFP != nil && self.mListenersEstablished {
            NotificationCenter.default.removeObserver(self, name: .APP_EFP_OrgFormChange, object: self.mEntryVC!.mEFP!)
            NotificationCenter.default.removeObserver(self, name: .APP_EFP_LangRegionChanged, object: self.mEntryVC!.mEFP!)
            self.mListenersEstablished = false
        }
    }
    
    // received a notification that the current Org or Form for our EFP has changed; this change will always occur while we are not visible
    @objc func noticeNewOrgForm(_ notification:Notification) {
debugPrint("\(self.mCTAG).noticeNewOrgForm STARTED \(self)")
        self.mFormIsBuilt = false       // allow a rebuild to take place when viewWillAppear occurs
    }
    
    // received a notification that the lanugage for our EFP has changed; this will occur while we are visible
    @objc func noticeNewLang(_ notification:Notification) {
//debugPrint("\(self.mCTAG).noticeNewLang STARTED \(self)")
        self.retitleForm()
    }
    
    // reset all the form's fields to their default value
    public func clearAll() {
        for row in form.allRows {
            row.baseValue = nil
            row.updateCell()
        }
        self.tableView!.endEditing(true)
    }
    
    // rebuild the form even upon re-display of the screen
    private func buildForm() {
        if self.mFormIsBuilt { return }
        if !self.isVisible { return }
//debugPrint("\(self.mCTAG).buildForm STARTED")
        
        // remove all prior rows and sections
        form.removeAll()
        tableView.reloadData()
        if self.mEntryVC!.mEFP == nil { return }
        if self.mEntryVC!.mEFP!.mFormRec == nil { return }
        let funcName:String = "buildForm" + (self.mEntryVC!.mEFP!.mPreviewMode ? ".previewMode":"")

        // setups
        self.mFullNameHiddenInserted = nil
        if !self.mEntryVC!.mEFP!.mPreviewMode {
            do {
                self.mEntryVC!.mEFP!.mFormFieldEntries = try FieldHandler.shared.getOrgFormFields(forEFP: self.mEntryVC!.mEFP!, forceLangRegion: nil, includeOptionSets: true, metaDataOnly: false, sortedBySVFileOrder: false)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                return
            }
        } else {
            do {
                try FieldHandler.shared.changeOrgFormFieldsLanguageShown(forEFP: self.mEntryVC!.mEFP!, forceLangRegion: nil)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
        }
        if self.mEntryVC!.mEFP!.mFormFieldEntries!.count() == 0 { return }
        
        // step through all the form's fields
        var counter:Int = 0
        for formFieldEntry in self.mEntryVC!.mEFP!.mFormFieldEntries! {
            if !formFieldEntry.mDuringEditing_isDeleted {
                // what kind of field was found?
                if !formFieldEntry.mFormFieldRec.isMetaData() {
                    // entry field; prepare to emplace the row
                    if !formFieldEntry.mFormFieldRec.isSubFormField() {
                        // its not a subfield either
                        counter = counter + 1
                        if counter == 1 && formFieldEntry.mFormFieldRec.rFieldProp_Row_Type != FIELD_ROW_TYPE.SECTION {
                            // create the default Section if the first emplaced field is not a Section
                            let newSection = Section() {
                                $0.tag = "Main"
                            }
                            form +++ newSection
                            self.mCurrentSection = newSection
                        }
                        // emplace the field on the form
                        emplaceField(forFormRec:self.mEntryVC!.mEFP!.mFormRec!, forFormFieldEntry: formFieldEntry)
                    }
                    
                } else if formFieldEntry.mFormFieldRec.rFieldProp_IDCode == FIELD_IDCODE_METADATA.SUBMIT_BUTTON.rawValue {
                    // found the Submit button metadata
                    var textString = NSLocalizedString("Submit", comment:"")
                    if !(formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown ?? "").isEmpty {
                        if !(formFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Name_Shown_Bilingual_2nd ?? "").isEmpty {
                            textString = formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown! + "\n" + (formFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Name_Shown_Bilingual_2nd!)
                        } else {
                            textString = formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!
                        }
                    }
                    self.mEntryVC!.button_submit.setTitle(textString, for: UIControl.State.normal)
                }
            }
        }
        
        // flag the form as built so that viewWillAppear() does not normally rebuild the form
        if !self.mEntryVC!.mEFP!.mPreviewMode { self.mEntryVC!.mEFP!.mFormFieldEntries = nil }    // free up some memory
        self.mFormIsBuilt = true
    }
    
    // emplace the specific field
    private func emplaceField(forFormRec:RecOrgFormDefs, forFormFieldEntry:OrgFormFieldsEntry) {
        
        // determine the row's title (shown text) and tag (column name)
        let rowTag = String(forFormFieldEntry.mFormFieldRec.rFormField_Index)
        var rowTitle:String = ""
        var rowTitle2:String = ""
        var rowPlaceholder:String? = nil
        if !(forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown ?? "").isEmpty {
            if !(forFormFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Name_Shown_Bilingual_2nd ?? "").isEmpty {
                rowTitle = forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!
                rowTitle2 = forFormFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Name_Shown_Bilingual_2nd!
            } else {
                rowTitle = forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!
            }
        }
        if !(forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
            rowPlaceholder = forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
        }
        
        // setup the field within the Eureka Form framework
        switch forFormFieldEntry.mFormFieldRec.rFieldProp_Row_Type {
        case FIELD_ROW_TYPE.SECTION:
            // Section header
            var newSection:Section
            if rowTitle.isEmpty {
                newSection = Section() {
                    $0.tag = rowTag
                }
            } else {
                var workTitle:String = rowTitle
                if !rowTitle2.isEmpty { workTitle = rowTitle + "\n" + rowTitle2 }
                newSection = Section(workTitle) {
                    $0.tag = rowTag
                }
            }
            self.mCurrentSection = newSection
            form +++ newSection
            break
            
        case FIELD_ROW_TYPE.LABEL:
            // informational text (no data entry)
            self.mCurrentSection! <<< TextAreaRow() {
                $0.tag = rowTag
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 20.0)
                if rowTitle2.isEmpty { $0.value = rowTitle }
                else { $0.value = rowTitle + "\n" + rowTitle2 }
                $0.disabled = true
            }
            break
            
        case FIELD_ROW_TYPE.TEXT:
            // general purpose text row; all text is accepted; just one line of text
            self.mCurrentSection! <<< TextRow() {
                $0.tag = rowTag
                $0.title = rowTitle
                $0.placeholder = rowPlaceholder
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.TEXT_MULTILINE:
            // general purpose text row; all text is accepted; multiple lines of text
            self.mCurrentSection! <<< TextAreaRowExt() {
                $0.tag = rowTag
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 100.0)
                $0.title = rowTitle
                $0.title2 = rowTitle2
                $0.placeholder = rowPlaceholder
                }.cellUpdate { cell, row in
                    cell.textView.layer.cornerRadius = 0
                    cell.textView.layer.borderColor = UIColor.gray.cgColor
                    cell.textView.layer.borderWidth = 1
            }
            break
            
        case FIELD_ROW_TYPE.ALPHANUMERIC:
            // alphanumeric row, a-z, A-Z, 0-9, including space
            self.mCurrentSection! <<< AlphanumericRow() {
                $0.tag = rowTag
                $0.title = rowTitle
                $0.placeholder = rowPlaceholder
                }.cellUpdate { cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.NUMBER:
            // number row, including + - . ,
            self.mCurrentSection! <<< DecimalRow() {
                $0.tag = rowTag
                $0.title = rowTitle
                $0.placeholder = rowPlaceholder
                }.cellUpdate { cell, row in
                    cell.textField.keyboardType = .decimalPad
                    cell.textField.inputViewController = NumberKeyboardViewController(allows: "+-.")
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.DIGITS:
            // digits only row
            self.mCurrentSection! <<< DigitsRow() {
                $0.tag = rowTag
                $0.title = rowTitle
                $0.placeholder = rowPlaceholder
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.HEXADECIMAL:
            // hexadecimal row, including :
            self.mCurrentSection! <<< TextRow() {
                $0.tag = rowTag
                $0.title = rowTitle
                $0.placeholder = rowPlaceholder
                }.cellUpdate { cell, row in
                    cell.textField.keyboardType = .decimalPad
                    cell.textField.inputViewController = HexKeyboardViewController()
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.NAME_PERSON:
            // name row; all words are capitalized by default; just one line of text
            // will contribute to the hidden FullName row
            if self.mFullNameHiddenInserted == nil {
                let fullNameHiddenInserted = ECC_HiddenFullNameRow(){
                    $0.title = "$Name-Full"
                    $0.tag = "$Name-Full"
                    $0.hidden = true
                }
                self.mCurrentSection! <<< fullNameHiddenInserted
                self.mFullNameHiddenInserted = fullNameHiddenInserted
            }
            self.mCurrentSection! <<< ECC_NameRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                $0.placeholder = rowPlaceholder
                $0.vCard_Subproperty_No = forFormFieldEntry.mFormFieldRec.rFieldProp_vCard_Subproperty_No!
                $0.eccHiddenFullNameRow = self.mFullNameHiddenInserted
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.NAME_PERSON_CONTAINER:
            // full name components (prefix, first, middle, last, suffix)
            var workNameComponentsShown = NameComponentsShown()
            workNameComponentsShown.nameHonorPrefix.shown = false
            workNameComponentsShown.nameFirst.shown = false
            workNameComponentsShown.nameMiddle.shown = false
            workNameComponentsShown.nameLast.shown = false
            workNameComponentsShown.nameHonorSuffix.shown = false
            for subFormFieldIDCode in forFormFieldEntry.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! {
                let subFFentry:OrgFormFieldsEntry? = self.mEntryVC!.mEFP!.mFormFieldEntries!.findSubfield(forPrimaryIndex: forFormFieldEntry.mFormFieldRec.rFormField_Index, forSubFieldIDCode: subFormFieldIDCode)
                if subFFentry != nil {
                    switch subFFentry!.mFormFieldRec.rFieldProp_IDCode {
                    case "FC_NameHonPre":
                        workNameComponentsShown.nameHonorPrefix.shown = true
                        workNameComponentsShown.nameHonorPrefix.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workNameComponentsShown.nameHonorPrefix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workNameComponentsShown.nameHonorPrefix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_Name1st":
                        workNameComponentsShown.nameFirst.shown = true
                        workNameComponentsShown.nameFirst.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workNameComponentsShown.nameFirst.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workNameComponentsShown.nameFirst.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_NameMid":
                        workNameComponentsShown.nameMiddle.shown = true
                        workNameComponentsShown.nameMiddle.onlyMiddleInitial = false
                        workNameComponentsShown.nameMiddle.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workNameComponentsShown.nameMiddle.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workNameComponentsShown.nameMiddle.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_NameMidI":
                        workNameComponentsShown.nameMiddle.shown = true
                        workNameComponentsShown.nameMiddle.onlyMiddleInitial = true
                        workNameComponentsShown.nameMiddle.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workNameComponentsShown.nameMiddle.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workNameComponentsShown.nameMiddle.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_NameLast":
                        workNameComponentsShown.nameLast.shown = true
                        workNameComponentsShown.nameLast.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workNameComponentsShown.nameLast.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workNameComponentsShown.nameLast.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_NameHonSuf":
                        workNameComponentsShown.nameHonorSuffix.shown = true
                        workNameComponentsShown.nameHonorSuffix.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workNameComponentsShown.nameHonorSuffix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workNameComponentsShown.nameHonorSuffix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    default:
                        break
                    }
                }
            }
            self.mCurrentSection! <<< NameComponentsRow(){
                $0.title = rowTitle
                if !rowTitle2.isEmpty { $0.title2 = rowTitle2 }
                $0.tag = rowTag
                $0.nameComponentsShown = workNameComponentsShown
            }
            break
            
        case FIELD_ROW_TYPE.NAME_PERSON_HONOR:
            // name honorifics ... pre or post ... which one in particular comes from the rField_vCard_Subproperty_No
            // will contribute to the hidden FullName row
            self.mCurrentSection! <<< ECC_NameRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                $0.placeholder = rowPlaceholder
                $0.vCard_Subproperty_No = forFormFieldEntry.mFormFieldRec.rFieldProp_vCard_Subproperty_No!
                $0.eccHiddenFullNameRow = self.mFullNameHiddenInserted
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.NAME_ORGANIZATION:
            // organization name ... this could have been a Text row but this allows for future special handling
            self.mCurrentSection! <<< NameRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                $0.placeholder = rowPlaceholder
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.DATE:
            // choose a date
            self.mCurrentSection! <<< DateRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                }.cellUpdate {cell, row in
                    row.dateFormatter?.dateFormat = "yyyy/MM/dd"
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.DATE_BEFORE_TODAY:
            // choose a date before or including today
            self.mCurrentSection! <<< DateRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                $0.maximumDate = Date()
                }.cellUpdate {cell, row in
                    row.dateFormatter?.dateFormat = "yyyy/MM/dd"
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.TIME_12:
            // choose a time in 12 hour clock
            self.mCurrentSection! <<< TimeRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                }.cellUpdate {cell, row in
                    row.dateFormatter?.dateFormat = "hh:mm: a"
                    cell.datePicker.locale = Locale.init(identifier: AppDelegate.forceRegion(region: "US", intoLangRegion: self.mEntryVC!.mEFP!.mShownLanguage))
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.TIME_24:
            // choose a time in 24 hour clock
            self.mCurrentSection! <<< TimeRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                }.cellUpdate {cell, row in
                    row.dateFormatter?.dateFormat = "HH:mm"
                    cell.datePicker.locale = Locale.init(identifier: "en_GB")
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break

        case FIELD_ROW_TYPE.PHONE_CONTAINER:
            // full phone components (+intl code, phone#, extension)
            var workPhoneComponentsShown = PhoneComponentsShown()
            workPhoneComponentsShown.phoneInternationalPrefix.shown = false
            workPhoneComponentsShown.phoneNumber.shown = false
            workPhoneComponentsShown.phoneExtension.shown = false
            var formatCode:String? = nil
            if let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                formatCode = CodePair.findValue(pairs: metaPairs, givenCode: "###Region")
                workPhoneComponentsShown.withFormattingRegion = formatCode
            }
            if forFormFieldEntry.mFormFieldRec.hasSubFormFields() {
                for subFormFieldIDCode in forFormFieldEntry.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! {
                    let subFFentry:OrgFormFieldsEntry? = self.mEntryVC!.mEFP!.mFormFieldEntries!.findSubfield(forPrimaryIndex: forFormFieldEntry.mFormFieldRec.rFormField_Index, forSubFieldIDCode: subFormFieldIDCode)
                    if subFFentry != nil {
                        switch subFFentry!.mFormFieldRec.rFieldProp_IDCode {
                        case "FC_PhIntl":
                            workPhoneComponentsShown.phoneInternationalPrefix.shown = true
                            workPhoneComponentsShown.phoneInternationalPrefix.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                            if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                workPhoneComponentsShown.phoneInternationalPrefix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                            } else {
                                workPhoneComponentsShown.phoneInternationalPrefix.placeholder = "+"
                            }
                            break
                        case "FC_Ph":
                            workPhoneComponentsShown.phoneNumber.shown = true
                            workPhoneComponentsShown.phoneNumber.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                            if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                workPhoneComponentsShown.phoneNumber.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                            } else {
                                workPhoneComponentsShown.phoneNumber.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                            }
                            break
                        case "FC_PhExt":
                            workPhoneComponentsShown.phoneExtension.shown = true
                            workPhoneComponentsShown.phoneExtension.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                            if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                workPhoneComponentsShown.phoneExtension.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                            } else {
                                workPhoneComponentsShown.phoneExtension.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                            }
                            break
                        default:
                            break
                        }
                    }
                }
            }
            self.mCurrentSection! <<< PhoneComponentsRow(){
                $0.title = rowTitle
                if !rowTitle2.isEmpty { $0.title2 = rowTitle2 }
                $0.tag = rowTag
                $0.phoneComponentsShown = workPhoneComponentsShown
                if !(formatCode ?? "").isEmpty, formatCode! != "-" {
                    $0.add(rule: RulePhoneComponents_ECC())
                }
                $0.validationOptions = .validatesOnChangeAfterBlurred
            }
            break
            
        case FIELD_ROW_TYPE.PHONE_WORK:
            // work phone (phone and extension fields)
            var workPhoneComponentsShown = PhoneComponentsShown()
            workPhoneComponentsShown.phoneInternationalPrefix.shown = false
            workPhoneComponentsShown.phoneNumber.shown = true
            workPhoneComponentsShown.phoneExtension.shown = true
            workPhoneComponentsShown.multiValued = false
            var formatCode:String? = nil
            if let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                formatCode = CodePair.findValue(pairs: metaPairs, givenCode: "###Region")
                workPhoneComponentsShown.withFormattingRegion = formatCode
            }
            if !(rowPlaceholder ?? "").isEmpty {
                let placeholderComponents = rowPlaceholder!.components(separatedBy: ";")
                workPhoneComponentsShown.phoneNumber.placeholder = placeholderComponents[0]
                if placeholderComponents.count > 1 { workPhoneComponentsShown.phoneExtension.placeholder = placeholderComponents[1] }
            }
            self.mCurrentSection! <<< PhoneComponentsRow(){
                $0.title = rowTitle
                if !rowTitle2.isEmpty { $0.title2 = rowTitle2 }
                $0.tag = rowTag
                $0.phoneComponentsShown = workPhoneComponentsShown
                if !(formatCode ?? "").isEmpty, formatCode! != "-" {
                    $0.add(rule: RulePhoneComponents_ECC())
                }
                $0.validationOptions = .validatesOnChangeAfterBlurred
            }
            break
            
        case FIELD_ROW_TYPE.PHONE_3:
            // formattable phone#; defaults to standard US phone number
            self.mCurrentSection! <<< PhoneRowExt(){
                $0.title = rowTitle
                $0.tag = rowTag
                if let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry),
                   let formatCode:String = CodePair.findValue(pairs: metaPairs, givenCode: "###Region") {
                    $0.withFormatRegion = formatCode
                    if !formatCode.isEmpty, formatCode != "-" {
                        $0.add(rule: RulePhone_ECC())
                    }
                }
                if !(rowPlaceholder ?? "").isEmpty { $0.placeholder = rowPlaceholder }
                $0.validationOptions = .validatesOnChangeAfterBlurred
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.PHONE_EXT:
            // phone extension
            self.mCurrentSection! <<< PhoneRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                $0.placeholder = rowPlaceholder
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.PHONE_INTL_CODE:
            // international phone code
            self.mCurrentSection! <<< PhoneRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                if !(rowPlaceholder ?? "").isEmpty { $0.placeholder = "+" }
                else { $0.placeholder = rowPlaceholder }
                }.cellUpdate {cell, row in
                    cell.textField.frame.size.width = 50
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.PRONOUNS:
            if let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry) {
                if controlPairs.count > 0 {
                    let (set1pairs, set2pairs, set3pairs) = self.preparePronouns(forFormFieldEntry: forFormFieldEntry, sourcePairs: controlPairs)
                    self.mCurrentSection! <<< TriplePickerInlineRow<String, String, String>() { mainRow in
                        mainRow.tag = rowTag
                        mainRow.title = rowTitle
                        mainRow.firstOptions = { return set1pairs.map { $0.codeString } }
                        mainRow.secondOptions = { opt1 in return set2pairs.map { $0.codeString } }
                        mainRow.thirdOptions = { opt1, opt2 in return set3pairs.map { $0.codeString } }
                        mainRow.retainedObject = (set1pairs, set2pairs, set3pairs)
                        mainRow.displayValueForFirstRow = { valueString in
                            let (set1pairs, _, _) = mainRow.retainedObject as! ([CodePair], [CodePair], [CodePair])
                            return CodePair.findValue(pairs: set1pairs, givenCode: valueString) ?? valueString
                        }
                        mainRow.displayValueForSecondRow = { valueString in
                            let (_, set2pairs, _) = mainRow.retainedObject as! ([CodePair], [CodePair], [CodePair])
                            return CodePair.findValue(pairs: set2pairs, givenCode: valueString) ?? valueString
                        }
                        mainRow.displayValueForThirdRow = { valueString in
                            let (_, _, set3pairs) = mainRow.retainedObject as! ([CodePair], [CodePair], [CodePair])
                            return CodePair.findValue(pairs: set3pairs, givenCode: valueString) ?? valueString
                        }
                        mainRow.displayValueFor = { tuple in
                            guard let tuple = tuple else { return "" }
                            let (set1pairs, set2pairs, set3pairs) = mainRow.retainedObject as! ([CodePair], [CodePair], [CodePair])
                            let str1:String = tuple.a == "-" ? "" : CodePair.findValue(pairs: set1pairs, givenCode: tuple.a) ?? tuple.a
                            let str2:String = tuple.b == "-" ? "" : CodePair.findValue(pairs: set2pairs, givenCode: tuple.b) ?? tuple.b
                            let str3:String = tuple.c == "-" ? "" : CodePair.findValue(pairs: set3pairs, givenCode: tuple.c) ?? tuple.c
                            var retStr = ""
                            if !str1.isEmpty { retStr = retStr + str1 }
                            if !str2.isEmpty {
                                retStr = retStr + "," + str2
                            }
                            if !str3.isEmpty {
                                if str2.isEmpty { retStr = retStr + "," }
                                retStr = retStr + "," + str3
                            }
                            return retStr
                        }
                        }.cellUpdate { cell, row in
                            if !rowTitle2.isEmpty {
                                cell.textLabel?.numberOfLines = 2
                                cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                            }
                            if !row.isValid {
                                cell.textLabel?.textColor = .red
                            }
                    }
                }
            }
            break
            
        case FIELD_ROW_TYPE.LANGUAGE_ISO_CODE:
            var (controlPairs, sectionMap, sectionTitles) = AppDelegate.getAvailableLangs(inLangRegion: self.mEntryVC!.mEFP!.mShownLanguage)
            if let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                if metaPairs.count > 0 {
                    var secTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***01")
                    if !(secTitle ?? "").isEmpty { sectionTitles["01"] = secTitle }
                    secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***02")
                    if !(secTitle ?? "").isEmpty { sectionTitles["02"] = secTitle }
                    secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***03")
                    if !(secTitle ?? "").isEmpty { sectionTitles["03"] = secTitle }
                    secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***04")
                    if !(secTitle ?? "").isEmpty { sectionTitles["04"] = secTitle }
                    secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***05")
                    if !(secTitle ?? "").isEmpty { sectionTitles["05"] = secTitle }
                    secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***06")
                    if !(secTitle ?? "").isEmpty { sectionTitles["06"] = secTitle }
                }
            }

            self.mCurrentSection! <<< PushRow<String>() { mainrow in
                    mainrow.tag = rowTag
                    mainrow.title = rowTitle
                    mainrow.options = controlPairs.map { $0.codeString }
                    mainrow.retainedObject = (controlPairs, sectionMap, sectionTitles)
                    mainrow.displayValueFor = { valueString in
                        if valueString == nil { return nil }
                        let (controlPairs, _, _) = mainrow.retainedObject as! ([CodePair], [String:String], [String:String])
                        return CodePair.findValue(pairs: controlPairs, givenCode: valueString!)
                    }
                    mainrow.onPresent { _, presentVC in
                        presentVC.sectionKeyForValue = { oTitleShown in
                            let (_, sectionMap, _) = mainrow.retainedObject as! ([CodePair], [String:String], [String:String])
                            return sectionMap[oTitleShown] ?? ""
                        }
                        presentVC.sectionHeaderTitleForKey = { sKey in
                            let (_, _, sectionTitles) = mainrow.retainedObject as! ([CodePair], [String:String], [String:String])
                            return sectionTitles[sKey]
                        }
                    }
                }.cellUpdate { cell, row in
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
                    if !row.isValid {
                        cell.textLabel?.textColor = .red
                    }
            }
            break
            
        case FIELD_ROW_TYPE.EMAIL:
            // text row with keyboard optimized for email addresses
            self.mCurrentSection! <<< EmailRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                $0.placeholder = rowPlaceholder
                $0.add(rule: RuleEmail())
                $0.validationOptions = .validatesOnBlur
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
            break
            
        case FIELD_ROW_TYPE.URL:
            // text row with keyboard optimized for URLs
            self.mCurrentSection! <<< URLRow(){
                $0.title = rowTitle
                $0.tag = rowTag
                $0.placeholder = rowPlaceholder
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.ADDRESS_CONTAINER:
            // full address components [country, apt/suite, street1, street2, city, state, postal]
            var workAddressComponentsShown = AddressComponentsShown()
            workAddressComponentsShown.addrCountryCode.shown = false
            workAddressComponentsShown.addrAptSuite.shown = false
            workAddressComponentsShown.addrStreet1.shown = false
            workAddressComponentsShown.addrStreet2.shown = false
            workAddressComponentsShown.addrCity.shown = false
            workAddressComponentsShown.addrStateProv.shown = false
            workAddressComponentsShown.addrPostalCode.shown = false
            for subFormFieldIDCode in forFormFieldEntry.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! {
                let subFFentry:OrgFormFieldsEntry? = self.mEntryVC!.mEFP!.mFormFieldEntries!.findSubfield(forPrimaryIndex: forFormFieldEntry.mFormFieldRec.rFormField_Index, forSubFieldIDCode: subFormFieldIDCode)
                if subFFentry != nil {
                    switch subFFentry!.mFormFieldRec.rFieldProp_IDCode {
                    case "FC_AddrCntry":
                        workAddressComponentsShown.addrCountryCode.shown = true
                        workAddressComponentsShown.addrCountryCode.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        workAddressComponentsShown.addrCountryCode.placeholder = AppDelegate.mDeviceRegion
                        if subFFentry!.mComposedOptionSetLocalesRecs != nil {
                             if let subControlCodes = self.prepareOptions(forFormFieldEntry: subFFentry!) {
                                workAddressComponentsShown.addrCountryCode.countryCodes = subControlCodes
                                if workAddressComponentsShown.addrCountryCode.countryCodes != nil {
                                    for codeEntry in workAddressComponentsShown.addrCountryCode.countryCodes! {
                                        if codeEntry.codeString == AppDelegate.mDeviceRegion {
                                            workAddressComponentsShown.addrCountryCode.countryCodes!.insert(codeEntry, at: 0)
                                            break
                                        }
                                    }
                                }
                            }
                        }
                        break
                    case "FC_AddrEx":
                        workAddressComponentsShown.addrAptSuite.shown = true
                        workAddressComponentsShown.addrAptSuite.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workAddressComponentsShown.addrAptSuite.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workAddressComponentsShown.addrAptSuite.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_AddrStr":
                        workAddressComponentsShown.addrStreet1.shown = true
                        workAddressComponentsShown.addrStreet1.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workAddressComponentsShown.addrStreet1.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workAddressComponentsShown.addrStreet1.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_AddrStr2":
                        workAddressComponentsShown.addrStreet2.shown = true
                        workAddressComponentsShown.addrStreet2.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workAddressComponentsShown.addrStreet2.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workAddressComponentsShown.addrStreet2.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_AddrCity":
                        workAddressComponentsShown.addrCity.shown = true
                        workAddressComponentsShown.addrCity.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workAddressComponentsShown.addrCity.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workAddressComponentsShown.addrCity.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_AddrSTcode":
                        workAddressComponentsShown.addrStateProv.shown = true
                        workAddressComponentsShown.addrStateProv.asStateCodeChooser = true
                        workAddressComponentsShown.addrStateProv.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workAddressComponentsShown.addrStateProv.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workAddressComponentsShown.addrStateProv.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        if let subControlCodes = self.prepareOptions(forFormFieldEntry: subFFentry!, forExtension: AppDelegate.mDeviceRegion) {
                            workAddressComponentsShown.addrStateProv.stateProvCodes = subControlCodes
                            workAddressComponentsShown.addrStateProv.retainObject = subFFentry!
                        }
                        break
                    case "FC_AddrSTfull":
                        workAddressComponentsShown.addrStateProv.shown = true
                        workAddressComponentsShown.addrStateProv.asStateCodeChooser = false
                        workAddressComponentsShown.addrStateProv.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workAddressComponentsShown.addrStateProv.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workAddressComponentsShown.addrStateProv.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        
                        break
                    case "FC_AddrPostalAlp":
                        workAddressComponentsShown.addrPostalCode.shown = true
                        workAddressComponentsShown.addrPostalCode.onlyNumeric = false
                        workAddressComponentsShown.addrPostalCode.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workAddressComponentsShown.addrPostalCode.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workAddressComponentsShown.addrPostalCode.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    case "FC_AddrPostalNum":
                        workAddressComponentsShown.addrPostalCode.shown = true
                        workAddressComponentsShown.addrPostalCode.onlyNumeric = true
                        workAddressComponentsShown.addrPostalCode.tag = String(subFFentry!.mFormFieldRec.rFormField_Index)
                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                            workAddressComponentsShown.addrPostalCode.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        } else {
                            workAddressComponentsShown.addrPostalCode.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                        }
                        break
                    default:
                        break
                    }
                }
            }
            self.mCurrentSection! <<< AddressComponentsRow(){
                $0.title = rowTitle
                if !rowTitle2.isEmpty { $0.title2 = rowTitle2 }
                $0.tag = rowTag
                $0.addrComponentsShown = workAddressComponentsShown
                $0.countryCodeFinishedEditing = { cell, row in
                    // country code was changed; should a state code field also be changedf
                    if row.addrComponentsShown.addrStateProv.shown && row.addrComponentsShown.addrStateProv.asStateCodeChooser {
                        if row.addrComponentsShown.addrStateProv.retainObject != nil {
                            let subFFentry:OrgFormFieldsEntry = row.addrComponentsShown.addrStateProv.retainObject as! OrgFormFieldsEntry
                            if row.addrComponentsValues.addrCountryCode != nil {
                                if let subControlCodes = self.prepareOptions(forFormFieldEntry: subFFentry, forExtension: row.addrComponentsValues.addrCountryCode!) {
                                    row.addrComponentsShown.addrStateProv.stateProvCodes = subControlCodes
                                }
                            } else {
                                if let subControlCodes = self.prepareOptions(forFormFieldEntry: subFFentry, forExtension: AppDelegate.mDeviceRegion) {
                                    row.addrComponentsShown.addrStateProv.stateProvCodes = subControlCodes
                                }
                            }
                        }
                    }
                }
            }
            break
            
        case FIELD_ROW_TYPE.ADDRESS_COUNTRY_ISO_CODE:
            if let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry),
               let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry),
               controlPairs.count > 0 {
                
                let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                self.mCurrentSection! <<< PushRow<String>(){ row in
                    row.title = rowTitle
                    row.tag = rowTag
                    if !(topTitle ?? "").isEmpty { row.selectorTitle  = topTitle }
                    else { row.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                    row.options = controlPairs.map { $0.codeString }
                    row.retainedObject = controlPairs
                    row.displayValueFor = { set in
                        if set == nil { return nil }
                        return CodePair.findValue(pairs: (row.retainedObject as! [CodePair]), givenCode: set!)
                    }
                    }.cellUpdate {cell, row in
                        cell.detailTextLabel?.numberOfLines = 0
                        cell.detailTextLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
                        if !rowTitle2.isEmpty {
                            cell.textLabel?.numberOfLines = 2
                            cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                        }
                }
            } else {
                self.mCurrentSection! <<< TextRow() {
                    $0.tag = rowTag
                    $0.title = rowTitle
                    }.cellUpdate { cell, row in
                        cell.textField.borderStyle = UITextField.BorderStyle.bezel
                        cell.textField.textAlignment = .left
                        cell.textField.clearButtonMode = .whileEditing
                        cell.textField.autocapitalizationType = .allCharacters
                        if !rowTitle2.isEmpty {
                            cell.textLabel?.numberOfLines = 2
                            cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                        }
                }
            }
            break
            
        case FIELD_ROW_TYPE.STATE_PROVINCE_CODE_BY_COUNTRY_ISO_CODE:
            if let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry),
               let countryCode:String = CodePair.findValue(pairs: metaPairs, givenCode: "###Country"),
               let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry, forExtension: countryCode),
               controlPairs.count > 0 {
                
                let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                self.mCurrentSection! <<< PushRow<String>(){ row in
                    row.title = rowTitle
                    row.tag = rowTag
                    if !(topTitle ?? "").isEmpty { row.selectorTitle  = topTitle }
                    else { row.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                    row.options = controlPairs.map { $0.codeString }
                    row.retainedObject = controlPairs
                    row.displayValueFor = { set in
                        if set == nil { return nil }
                        return CodePair.findValue(pairs: (row.retainedObject as! [CodePair]), givenCode: set!)
                    }
                    }.cellUpdate {cell, row in
                        cell.detailTextLabel?.numberOfLines = 0
                        cell.detailTextLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
                        if !rowTitle2.isEmpty {
                            cell.textLabel?.numberOfLines = 2
                            cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                        }
                }
            } else {
                self.mCurrentSection! <<< TextRow() {
                    $0.tag = rowTag
                    $0.title = rowTitle
                    }.cellUpdate { cell, row in
                        cell.textField.borderStyle = UITextField.BorderStyle.bezel
                        cell.textField.textAlignment = .left
                        cell.textField.clearButtonMode = .whileEditing
                        cell.textField.autocapitalizationType = .allCharacters
                        if !rowTitle2.isEmpty {
                            cell.textLabel?.numberOfLines = 2
                            cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                        }
                }
            }
            break
            
        case FIELD_ROW_TYPE.POSTAL_CODE_NUMERIC:
            // postal code row, allows 0-9, including space
            self.mCurrentSection! <<< DigitsRow() {
                $0.tag = rowTag
                $0.title = rowTitle
                $0.placeholder = rowPlaceholder
                }.cellUpdate {cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
        
        case FIELD_ROW_TYPE.POSTAL_CODE_ALPHANUMERIC:
            // postal code row, allows A-Z, 0-9, including space
            self.mCurrentSection! <<< PostalCodeAlphaRow() {
                $0.tag = rowTag
                $0.title = rowTitle
                $0.placeholder = rowPlaceholder
                }.cellUpdate { cell, row in
                    cell.textField.borderStyle = UITextField.BorderStyle.bezel
                    cell.textField.textAlignment = .left
                    cell.textField.clearButtonMode = .whileEditing
                    if !rowTitle2.isEmpty {
                        cell.textLabel?.numberOfLines = 2
                        cell.textLabel?.text = rowTitle + "\n" + rowTitle2
                    }
            }
            break
            
        case FIELD_ROW_TYPE.CHOOSE_1:
            // chose one from a sequence of options; will attempt to show the options inline if there are few enough
            if let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry),
               let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                if controlPairs.count > 0 {
                    let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                    self.mCurrentSection! <<< SegmentedRowExt<String>(){ mainRow in
                        mainRow.title = rowTitle
                        mainRow.title2 = rowTitle2
                        mainRow.tag = rowTag
                        if !(topTitle ?? "").isEmpty { mainRow.selectorTitle = topTitle }
                        else { mainRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                        mainRow.options = controlPairs.map { $0.codeString }
                        mainRow.retainedObject = controlPairs
                        mainRow.displayValueFor = { set in
                            if set == nil { return nil }
                            return set!.map { CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: $0)! }.joined(separator: ", ")
                        }
                        mainRow.onPresent({ _, presentVC in
                            presentVC.selectableRowSetup = { vcRow in
                                vcRow.title = CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: vcRow.title!)
                            }
                        })
                    }
                }
            }
            break
            
        case FIELD_ROW_TYPE.CHOOSE_1_OTHER:
            // chose one from a sequence of options; will attempt to show the options inline if there are few enough; if "other" is pressed a textrow appears
            if let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry),
               let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                if controlPairs.count > 0 {
                    let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                    let otherCode:String? = forFormFieldEntry.getOptionSVFile(forTag: "$$$other$")
                    var otherRow:TextRow? = nil
                    if !(otherCode ?? "").isEmpty {
                        otherRow = TextRow(){ row in
                            row.title = CodePair.findValue(pairs: controlPairs, givenCode: otherCode!)
                            row.tag = nil
                            row.hidden = Condition.function([rowTag], { form in
                                return (form.rowBy(tag: rowTag) as? SegmentedRowExt<String>)?.otherRowShouldHide ?? true
                            })
                            }.cellUpdate {cell, row in
                                cell.textField.borderStyle = UITextField.BorderStyle.bezel
                                cell.textField.textAlignment = .left
                                cell.textField.clearButtonMode = .whileEditing
                        }
                    }
                    self.mCurrentSection! <<< SegmentedRowExt<String>(){ mainRow in
                        mainRow.title = rowTitle
                        mainRow.title2 = rowTitle2
                        mainRow.tag = rowTag
                        if !(topTitle ?? "").isEmpty { mainRow.selectorTitle  = topTitle }
                        else { mainRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                        mainRow.options = controlPairs.map { $0.codeString }
                        mainRow.retainedObject = controlPairs
                        mainRow.displayValueFor = { set in
                            if set == nil { return nil }
                            return set!.map { CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: $0) ?? $0 }.joined(separator: ", ")
                        }
                        mainRow.onPresent({ _, presentVC in
                            presentVC.selectableRowSetup = { vcRow in
                                vcRow.title = CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: vcRow.title!)
                            }
                        })
                        if otherRow != nil {
                            mainRow.otherRow = otherRow
                            mainRow.otherRowUponChoosingOptionCode = otherCode
                        }
                    }
                    if otherRow != nil { self.mCurrentSection! <<< otherRow! }
                }
            }
            break
            
        case FIELD_ROW_TYPE.CHOOSE_ANY:
            // chose one or more from a sequence of options; will attempt to show the options inline if there are few enough
            if let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry),
               let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                if controlPairs.count > 0 {
                    let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                    self.mCurrentSection! <<< SegmentedRowExt<String>(){ mainRow in
                        mainRow.title = rowTitle
                        mainRow.title2 = rowTitle2
                        mainRow.tag = rowTag
                        mainRow.allowMultiSelect = true
                        if !(topTitle ?? "").isEmpty { mainRow.selectorTitle  = topTitle }
                        else { mainRow.selectorTitle = NSLocalizedString("Choose one or more", comment:"") }
                        mainRow.options = controlPairs.map { $0.codeString }
                        mainRow.retainedObject = controlPairs
                        mainRow.displayValueFor = { set in
                            if set == nil { return nil }
                            return set!.map { CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: $0)! }.joined(separator: ", ")
                        }
                        mainRow.onPresent({ _, presentVC in
                            presentVC.selectableRowSetup = { vcRow in
                                vcRow.title = CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: vcRow.title!)
                            }
                        })
                    }
                }
            }
            break
            
        case FIELD_ROW_TYPE.CHOOSE_ANY_OTHER:
            // chose one or more from a sequence of options; will attempt to show the options inline if there are few enough; if "other" is pressed a textrow appears
            if let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry),
               let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                if controlPairs.count > 0 {
                    let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                    let otherCode:String! = forFormFieldEntry.getOptionSVFile(forTag: "$$$other$")
                    var otherRow:TextRow? = nil
                    if !(otherCode ?? "").isEmpty {
                        otherRow = TextRow(){ row in
                            row.title = CodePair.findValue(pairs: controlPairs, givenCode: otherCode!)
                            row.tag = nil
                            row.hidden = Condition.function([rowTag], { form in
                                return (form.rowBy(tag: rowTag) as? SegmentedRowExt<String>)?.otherRowShouldHide ?? true
                            })
                            }.cellUpdate {cell, row in
                                cell.textField.borderStyle = UITextField.BorderStyle.bezel
                                cell.textField.textAlignment = .left
                                cell.textField.clearButtonMode = .whileEditing
                        }
                    }
                    self.mCurrentSection! <<< SegmentedRowExt<String>(){ mainRow in
                        mainRow.title = rowTitle
                        mainRow.title2 = rowTitle2
                        mainRow.tag = rowTag
                        mainRow.allowMultiSelect = true
                        if !(topTitle ?? "").isEmpty { mainRow.selectorTitle  = topTitle }
                        else { mainRow.selectorTitle = NSLocalizedString("Choose one or more", comment:"") }
                        mainRow.options = controlPairs.map { $0.codeString }
                        mainRow.retainedObject = controlPairs
                        mainRow.displayValueFor = { set in
                            if set == nil { return nil }
                            return set!.map { CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: $0) ?? $0 }.joined(separator: ", ")
                        }
                        mainRow.onPresent({ _, presentVC in
                            presentVC.selectableRowSetup = { vcRow in
                                vcRow.title = CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: vcRow.title!)
                            }
                        })
                        if otherRow != nil {
                            mainRow.otherRow = otherRow!
                            mainRow.otherRowUponChoosingOptionCode = otherCode
                        }
                    }
                    if otherRow != nil { self.mCurrentSection! <<< otherRow! }
                }
            }
            break

        case FIELD_ROW_TYPE.YESNO:
            // Yes or No choice of one
            if let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry),
               let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                if controlPairs.count > 0 {
                    let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                    self.mCurrentSection! <<< SegmentedRowExt<String>(){ mainRow in
                        mainRow.title = rowTitle
                        mainRow.title2 = rowTitle2
                        mainRow.tag = rowTag
                        if !(topTitle ?? "").isEmpty { mainRow.selectorTitle  = topTitle }
                        else { mainRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                        mainRow.options = controlPairs.map { $0.codeString }
                        mainRow.retainedObject = controlPairs
                        mainRow.displayValueFor = { set in
                            if set == nil { return nil }
                            return set!.map { CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: $0) ?? $0 }.joined(separator: ", ")
                            }
                        mainRow.onPresent({ _, presentVC in
                            presentVC.selectableRowSetup = { vcRow in
                                vcRow.title = CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: vcRow.title!)
                            }
                        })
                    }
                }
            }
            break
            
        case FIELD_ROW_TYPE.YESNOMAYBE:
            // Yes or No choice of one
            if let controlPairs = self.prepareOptions(forFormFieldEntry: forFormFieldEntry),
               let metaPairs = self.prepareMetadata(forFormFieldEntry: forFormFieldEntry) {
                if controlPairs.count > 0 {
                    let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                    self.mCurrentSection! <<< SegmentedRowExt<String>(){ mainRow in
                        mainRow.title = rowTitle
                        mainRow.title2 = rowTitle2
                        mainRow.tag = rowTag
                        if !(topTitle ?? "").isEmpty { mainRow.selectorTitle  = topTitle }
                        else { mainRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                        mainRow.options = controlPairs.map { $0.valueString }
                        mainRow.retainedObject = controlPairs
                        mainRow.displayValueFor = { set in
                            if set == nil { return nil }
                            return set!.map { CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: $0) ?? $0 }.joined(separator: ", ")
                        }
                        mainRow.onPresent({ _, presentVC in
                            presentVC.selectableRowSetup = { vcRow in
                                vcRow.title = CodePair.findValue(pairs: (mainRow.retainedObject as! [CodePair]), givenCode: vcRow.title!)
                            }
                        })
                    }
                }
            }
            break
        }
    }
    
    // retitle the built form's fields to the new AppDelegate current language
    private func retitleForm() {
        if !self.mFormIsBuilt {
            // if the form has been tagged for rebuilding, then just rebuild it instead of retitling it
            self.buildForm()
            return
        }
        
        if self.mEntryVC!.mEFP == nil { return }
        if self.mEntryVC!.mEFP!.mFormRec == nil { return }
        let funcName:String = "retitleForm" + (self.mEntryVC!.mEFP!.mPreviewMode ? ".previewMode":"")
        if !self.mEntryVC!.mEFP!.mPreviewMode {
            do {
                self.mEntryVC!.mEFP!.mFormFieldEntries = try FieldHandler.shared.getOrgFormFields(forEFP: self.mEntryVC!.mEFP!, forceLangRegion: nil, includeOptionSets: true, metaDataOnly: false, sortedBySVFileOrder: false)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                return
            }
        } else {
            do {
                try FieldHandler.shared.changeOrgFormFieldsLanguageShown(forEFP: self.mEntryVC!.mEFP!, forceLangRegion: nil)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
        }
        for formFieldEntry in self.mEntryVC!.mEFP!.mFormFieldEntries! {
            if !formFieldEntry.mDuringEditing_isDeleted {
                // what kind of field was found?
                if !formFieldEntry.mFormFieldRec.isMetaData() {
                    // entry field; prepare to retitle the row and its attributes too
                    let rowTag = String(formFieldEntry.mFormFieldRec.rFormField_Index)
                    var rowTitle:String = ""
                    var rowTitle2:String = ""
                    var rowPlaceholder:String? = nil
                    if !(formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown ?? "").isEmpty {
                        if !(formFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Name_Shown_Bilingual_2nd ?? "").isEmpty {
                            rowTitle = formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!
                            rowTitle2 = formFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Name_Shown_Bilingual_2nd!
                        } else {
                            rowTitle = formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!
                        }
                    }
                    if !(formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                        rowPlaceholder = formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                    }
                    
                    // specifically handle an inserted section
                    if formFieldEntry.mFormFieldRec.rFieldProp_Row_Type == FIELD_ROW_TYPE.SECTION {
                        if !rowTitle.isEmpty {
                            var workTitle:String = rowTitle
                            if !rowTitle2.isEmpty { workTitle = rowTitle + "\n" + rowTitle2 }
                            let section:Section? = form.sectionBy(tag: rowTag)
                            if section != nil {
                                section!.header?.title = workTitle
                                section!.reload()
                            }
                        }
                    }
                    
                    let row = form.rowBy(tag: rowTag)
                    if row != nil {
                        switch formFieldEntry.mFormFieldRec.rFieldProp_Row_Type {
                        case FIELD_ROW_TYPE.SECTION:
                            // do nothing
                            break
                        case FIELD_ROW_TYPE.LABEL:
                            let textAreaRow = row as! TextAreaRow
                            if rowTitle2.isEmpty { textAreaRow.value = rowTitle }
                            else { textAreaRow.value = rowTitle + "\n" + rowTitle2 }
                            break
                        case FIELD_ROW_TYPE.TEXT:
                            let textRow = row as! TextRow
                            if rowTitle2.isEmpty { textRow.title = rowTitle }
                            else { textRow.title = rowTitle + "\n" + rowTitle2 }
                            textRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.TEXT_MULTILINE:
                            let textAreaRow = row as! TextAreaRowExt
                            textAreaRow.title = rowTitle
                            textAreaRow.title2 = rowTitle2
                            textAreaRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.ALPHANUMERIC:
                            let textRow = row as! AlphanumericRow
                            if rowTitle2.isEmpty { textRow.title = rowTitle }
                            else { textRow.title = rowTitle + "\n" + rowTitle2 }
                            textRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.NUMBER:
                            let decimalRow = row as! DecimalRow
                            if rowTitle2.isEmpty { decimalRow.title = rowTitle }
                            else { decimalRow.title = rowTitle + "\n" + rowTitle2 }
                            decimalRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.DIGITS:
                            let decimalRow = row as! DigitsRow
                            if rowTitle2.isEmpty { decimalRow.title = rowTitle }
                            else { decimalRow.title = rowTitle + "\n" + rowTitle2 }
                            decimalRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.HEXADECIMAL:
                            let textRow = row as! TextRow
                            if rowTitle2.isEmpty { textRow.title = rowTitle }
                            else { textRow.title = rowTitle + "\n" + rowTitle2 }
                            textRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.DATE:
                            let dateRow = row as! DateRow
                            if rowTitle2.isEmpty { dateRow.title = rowTitle }
                            else { dateRow.title = rowTitle + "\n" + rowTitle2 }
                            break
                        case FIELD_ROW_TYPE.DATE_BEFORE_TODAY:
                            let dateRow = row as! DateRow
                            if rowTitle2.isEmpty { dateRow.title = rowTitle }
                            else { dateRow.title = rowTitle + "\n" + rowTitle2 }
                            break
                        case FIELD_ROW_TYPE.TIME_12:
                            let timeRow = row as! TimeRow
                            if rowTitle2.isEmpty { timeRow.title = rowTitle }
                            else { timeRow.title = rowTitle + "\n" + rowTitle2 }
                            break
                        case FIELD_ROW_TYPE.TIME_24:
                            let timeRow = row as! TimeRow
                            if rowTitle2.isEmpty { timeRow.title = rowTitle }
                            else { timeRow.title = rowTitle + "\n" + rowTitle2 }
                            break
                        case FIELD_ROW_TYPE.NAME_PERSON:
                            let nameRow = row as! ECC_NameRow
                            if rowTitle2.isEmpty { nameRow.title = rowTitle }
                            else { nameRow.title = rowTitle + "\n" + rowTitle2 }
                            nameRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.NAME_PERSON_HONOR:
                            let nameRow = row as! ECC_NameRow
                            if rowTitle2.isEmpty { nameRow.title = rowTitle }
                            else { nameRow.title = rowTitle + "\n" + rowTitle2 }
                            nameRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.NAME_PERSON_CONTAINER:
                            let nameCompRow = row as! NameComponentsRow
                            for subFormFieldIDCode in formFieldEntry.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! {
                                let subFFentry:OrgFormFieldsEntry? = self.mEntryVC!.mEFP!.mFormFieldEntries!.findSubfield(forPrimaryIndex: formFieldEntry.mFormFieldRec.rFormField_Index, forSubFieldIDCode: subFormFieldIDCode)
                                if subFFentry != nil {
                                    switch subFFentry!.mFormFieldRec.rFieldProp_IDCode {
                                    case "FC_NameHonPre":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            nameCompRow.nameComponentsShown.nameHonorPrefix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            nameCompRow.nameComponentsShown.nameHonorPrefix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_Name1st":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            nameCompRow.nameComponentsShown.nameFirst.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            nameCompRow.nameComponentsShown.nameFirst.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_NameMid":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            nameCompRow.nameComponentsShown.nameMiddle.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            nameCompRow.nameComponentsShown.nameMiddle.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_NameMidI":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            nameCompRow.nameComponentsShown.nameMiddle.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            nameCompRow.nameComponentsShown.nameMiddle.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_NameLast":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            nameCompRow.nameComponentsShown.nameLast.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            nameCompRow.nameComponentsShown.nameLast.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_NameHonSuf":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            nameCompRow.nameComponentsShown.nameHonorSuffix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            nameCompRow.nameComponentsShown.nameHonorSuffix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    default:
                                        break
                                    }
                                }
                            }
                            break
                        case FIELD_ROW_TYPE.NAME_ORGANIZATION:
                            let nameRow = row as! NameRow
                            if rowTitle2.isEmpty { nameRow.title = rowTitle }
                            else { nameRow.title = rowTitle + "\n" + rowTitle2 }
                            nameRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.PHONE_CONTAINER:
                            let phoneCompRow = row as! PhoneComponentsRow
                            phoneCompRow.title = rowTitle
                            phoneCompRow.title2 = rowTitle2
                            if formFieldEntry.mFormFieldRec.hasSubFormFields() {
                                for subFormFieldIDCode in formFieldEntry.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! {
                                    let subFFentry:OrgFormFieldsEntry? = self.mEntryVC!.mEFP!.mFormFieldEntries!.findSubfield(forPrimaryIndex: formFieldEntry.mFormFieldRec.rFormField_Index, forSubFieldIDCode: subFormFieldIDCode)
                                    if subFFentry != nil {
                                        switch subFFentry!.mFormFieldRec.rFieldProp_IDCode {
                                        case "FC_PhIntl":
                                            if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                                phoneCompRow.phoneComponentsShown.phoneInternationalPrefix.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                            } else {
                                                phoneCompRow.phoneComponentsShown.phoneInternationalPrefix.placeholder = "+"
                                            }
                                            break
                                        case "FC_Ph":
                                            if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                                phoneCompRow.phoneComponentsShown.phoneNumber.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                            } else {
                                                phoneCompRow.phoneComponentsShown.phoneNumber.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                            }
                                            break
                                        case "FC_PhExt":
                                            if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                                phoneCompRow.phoneComponentsShown.phoneExtension.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                            } else {
                                                phoneCompRow.phoneComponentsShown.phoneExtension.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                            }
                                            break
                                        default:
                                            break
                                        }
                                    }
                                }
                            }
                            break
                        case FIELD_ROW_TYPE.PHONE_WORK:
                            let phoneCompRow = row as! PhoneComponentsRow
                            phoneCompRow.title = rowTitle
                            phoneCompRow.title2 = rowTitle2
                            if !(rowPlaceholder ?? "").isEmpty {
                                let placeholderComponents = rowPlaceholder!.components(separatedBy: ";")
                                phoneCompRow.phoneComponentsShown.phoneNumber.placeholder = placeholderComponents[0]
                                if placeholderComponents.count > 1 { phoneCompRow.phoneComponentsShown.phoneExtension.placeholder = placeholderComponents[1] }
                            }
                            break
                        case FIELD_ROW_TYPE.PHONE_3:
                            let phoneRow = row as! PhoneRow
                            if rowTitle2.isEmpty { phoneRow.title = rowTitle }
                            else { phoneRow.title = rowTitle + "\n" + rowTitle2 }
                            phoneRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.PHONE_EXT:
                            let phoneRow = row as! PhoneRow
                            if rowTitle2.isEmpty { phoneRow.title = rowTitle }
                            else { phoneRow.title = rowTitle + "\n" + rowTitle2 }
                            phoneRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.PHONE_INTL_CODE:
                            let phoneRow = row as! PhoneRow
                            if rowTitle2.isEmpty { phoneRow.title = rowTitle }
                            else { phoneRow.title = rowTitle + "\n" + rowTitle2 }
                            phoneRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.PRONOUNS:
                            let pick3Row = row as! TriplePickerInlineRow<String, String, String>
                            if rowTitle2.isEmpty { pick3Row.title = rowTitle }
                            else { pick3Row.title = rowTitle + "\n" + rowTitle2 }
                            if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                               controlPairs.count > 0 {
                                
                                let (set1pairs, set2pairs, set3pairs) = self.preparePronouns(forFormFieldEntry: formFieldEntry, sourcePairs: controlPairs)
                                pick3Row.retainedObject = (set1pairs, set2pairs, set3pairs)
                            }
                            break
                        case FIELD_ROW_TYPE.LANGUAGE_ISO_CODE:
                            let pushRow = row as! PushRow<String>
                            if rowTitle2.isEmpty { pushRow.title = rowTitle }
                            else { pushRow.title = rowTitle + "\n" + rowTitle2 }
                            var (controlPairs, sectionMap, sectionTitles) = AppDelegate.getAvailableLangs(inLangRegion: self.mEntryVC!.mEFP!.mShownLanguage)
                            if let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                               metaPairs.count > 0 {
                                
                                var secTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***01")
                                if !(secTitle ?? "").isEmpty { sectionTitles["01"] = secTitle }
                                secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***02")
                                if !(secTitle ?? "").isEmpty { sectionTitles["02"] = secTitle }
                                secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***03")
                                if !(secTitle ?? "").isEmpty { sectionTitles["03"] = secTitle }
                                secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***04")
                                if !(secTitle ?? "").isEmpty { sectionTitles["04"] = secTitle }
                                secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***05")
                                if !(secTitle ?? "").isEmpty { sectionTitles["05"] = secTitle }
                                secTitle = CodePair.findValue(pairs: metaPairs, givenCode: "***06")
                                if !(secTitle ?? "").isEmpty { sectionTitles["06"] = secTitle }
                            }
                            pushRow.retainedObject = (controlPairs, sectionMap, sectionTitles)
                            break
                        case FIELD_ROW_TYPE.EMAIL:
                            let emailRow = row as! EmailRow
                            if rowTitle2.isEmpty { emailRow.title = rowTitle }
                            else { emailRow.title = rowTitle + "\n" + rowTitle2 }
                            emailRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.URL:
                            let urlRow = row as! URLRow
                            if rowTitle2.isEmpty { urlRow.title = rowTitle }
                            else { urlRow.title = rowTitle + "\n" + rowTitle2 }
                            urlRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.ADDRESS_CONTAINER:
                            let addrCompRow = row as! AddressComponentsRow
                            addrCompRow.title = rowTitle
                            addrCompRow.title2 = rowTitle2
                            for subFormFieldIDCode in formFieldEntry.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! {
                                let subFFentry:OrgFormFieldsEntry? = self.mEntryVC!.mEFP!.mFormFieldEntries!.findSubfield(forPrimaryIndex: formFieldEntry.mFormFieldRec.rFormField_Index, forSubFieldIDCode: subFormFieldIDCode)
                                if subFFentry != nil {
                                    switch subFFentry!.mFormFieldRec.rFieldProp_IDCode {
                                    case "FC_AddrCntry":
                                        if subFFentry!.mComposedOptionSetLocalesRecs != nil {
                                            if let subControlCodes = self.prepareOptions(forFormFieldEntry: subFFentry!) {
                                                addrCompRow.addrComponentsShown.addrCountryCode.countryCodes = subControlCodes
                                                if addrCompRow.addrComponentsShown.addrCountryCode.countryCodes != nil {
                                                    for codeEntry in addrCompRow.addrComponentsShown.addrCountryCode.countryCodes! {
                                                        if codeEntry.codeString == AppDelegate.mDeviceRegion {
                                                            addrCompRow.addrComponentsShown.addrCountryCode.countryCodes!.insert(codeEntry, at: 0)
                                                            break
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        break
                                    case "FC_AddrEx":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            addrCompRow.addrComponentsShown.addrAptSuite.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            addrCompRow.addrComponentsShown.addrAptSuite.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_AddrStr":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            addrCompRow.addrComponentsShown.addrStreet1.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            addrCompRow.addrComponentsShown.addrStreet1.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_AddrStr2":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            addrCompRow.addrComponentsShown.addrStreet2.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            addrCompRow.addrComponentsShown.addrStreet2.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_AddrCity":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            addrCompRow.addrComponentsShown.addrCity.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            addrCompRow.addrComponentsShown.addrCity.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_AddrSTcode":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            addrCompRow.addrComponentsShown.addrStateProv.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            addrCompRow.addrComponentsShown.addrStateProv.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        if addrCompRow.addrComponentsShown.addrStateProv.asStateCodeChooser {
                                            addrCompRow.addrComponentsShown.addrStateProv.retainObject = subFFentry!
                                            if addrCompRow.addrComponentsValues.addrCountryCode != nil {
                                                if let subControlCodes = self.prepareOptions(forFormFieldEntry: subFFentry!, forExtension: addrCompRow.addrComponentsValues.addrCountryCode!) {
                                                    addrCompRow.addrComponentsShown.addrStateProv.stateProvCodes = subControlCodes
                                                }
                                            } else {
                                                if let subControlCodes = self.prepareOptions(forFormFieldEntry: subFFentry!, forExtension: AppDelegate.mDeviceRegion) {
                                                    addrCompRow.addrComponentsShown.addrStateProv.stateProvCodes = subControlCodes
                                                }
                                            }
                                        }
                                        break
                                    case "FC_AddrSTfull":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            addrCompRow.addrComponentsShown.addrStateProv.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            addrCompRow.addrComponentsShown.addrStateProv.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        
                                        break
                                    case "FC_AddrPostalAlp":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            addrCompRow.addrComponentsShown.addrPostalCode.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            addrCompRow.addrComponentsShown.addrPostalCode.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    case "FC_AddrPostalNum":
                                        if !(subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown ?? "").isEmpty {
                                            addrCompRow.addrComponentsShown.addrPostalCode.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                                        } else {
                                            addrCompRow.addrComponentsShown.addrPostalCode.placeholder = subFFentry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown
                                        }
                                        break
                                    default:
                                        break
                                    }
                                }
                            }
                            break
                        case FIELD_ROW_TYPE.ADDRESS_COUNTRY_ISO_CODE:
                            if let textRow = row as? TextRow {
                                if rowTitle2.isEmpty { textRow.title = rowTitle }
                                else { textRow.title = rowTitle + "\n" + rowTitle2 }
                                textRow.placeholder = rowPlaceholder
                            } else if let pushRow = row as? PushRow<String> {
                                if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                                   let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                                   controlPairs.count > 0 {
                                    
                                    pushRow.retainedObject = controlPairs
                                    let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                                    if !(topTitle ?? "").isEmpty { pushRow.selectorTitle  = topTitle }
                                    else { pushRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                                }
                                if rowTitle2.isEmpty { pushRow.title = rowTitle }
                                else { pushRow.title = rowTitle + "\n" + rowTitle2 }
                            }
                            break
                        case FIELD_ROW_TYPE.STATE_PROVINCE_CODE_BY_COUNTRY_ISO_CODE:
                            if let textRow = row as? TextRow {
                                if rowTitle2.isEmpty { textRow.title = rowTitle }
                                else { textRow.title = rowTitle + "\n" + rowTitle2 }
                                textRow.placeholder = rowPlaceholder
                            } else if let pushRow = row as? PushRow<String> {
                                if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                                   let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                                   controlPairs.count > 0 {
                                    
                                    pushRow.retainedObject = controlPairs
                                    let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                                    if !(topTitle ?? "").isEmpty { pushRow.selectorTitle  = topTitle }
                                    else { pushRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                                }
                                if rowTitle2.isEmpty { pushRow.title = rowTitle }
                                else { pushRow.title = rowTitle + "\n" + rowTitle2 }
                            }
                            break
                        case FIELD_ROW_TYPE.POSTAL_CODE_NUMERIC:
                            let textRow = row as! DigitsRow
                            if rowTitle2.isEmpty { textRow.title = rowTitle }
                            else { textRow.title = rowTitle + "\n" + rowTitle2 }
                            textRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.POSTAL_CODE_ALPHANUMERIC:
                            let textRow = row as! PostalCodeAlphaRow
                            if rowTitle2.isEmpty { textRow.title = rowTitle }
                            else { textRow.title = rowTitle + "\n" + rowTitle2 }
                            textRow.placeholder = rowPlaceholder
                            break
                        case FIELD_ROW_TYPE.CHOOSE_1:
                            let segExtRow = row as! SegmentedRowExt<String>
                            segExtRow.title = rowTitle
                            segExtRow.title2 = rowTitle2
                            if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                               let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                               controlPairs.count > 0 {
                                
                                segExtRow.retainedObject = controlPairs
                                let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                                if !(topTitle ?? "").isEmpty { segExtRow.selectorTitle  = topTitle }
                                else { segExtRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                            }
                            break
                        case FIELD_ROW_TYPE.CHOOSE_ANY:
                            let segExtRow = row as! SegmentedRowExt<String>
                            segExtRow.title = rowTitle
                            segExtRow.title2 = rowTitle2
                            if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                               let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                               controlPairs.count > 0 {
                                
                                segExtRow.retainedObject = controlPairs
                                let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                                if !(topTitle ?? "").isEmpty { segExtRow.selectorTitle  = topTitle }
                                else { segExtRow.selectorTitle = NSLocalizedString("Choose one or more", comment:"") }
                            }
                            break
                        case FIELD_ROW_TYPE.CHOOSE_1_OTHER:
                            let segExtRow = row as! SegmentedRowExt<String>
                            segExtRow.title = rowTitle
                            segExtRow.title2 = rowTitle2
                            if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                               let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                               controlPairs.count > 0 {
                                
                                segExtRow.retainedObject = controlPairs
                                let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                                if !(topTitle ?? "").isEmpty { segExtRow.selectorTitle  = topTitle }
                                else { segExtRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                                if segExtRow.otherRow != nil {
                                    let otherCode:String? = formFieldEntry.getOptionSVFile(forTag: "$$$other$")
                                    if !(otherCode ?? "").isEmpty {
                                        segExtRow.otherRow!.title = CodePair.findValue(pairs: controlPairs, givenCode: otherCode!)
                                    }
                                }
                            }
                            break
                        case FIELD_ROW_TYPE.CHOOSE_ANY_OTHER:
                            let segExtRow = row as! SegmentedRowExt<String>
                            segExtRow.title = rowTitle
                            segExtRow.title2 = rowTitle2
                            if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                               let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                               controlPairs.count > 0 {
                                
                                segExtRow.retainedObject = controlPairs
                                let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                                if !(topTitle ?? "").isEmpty { segExtRow.selectorTitle  = topTitle }
                                else { segExtRow.selectorTitle = NSLocalizedString("Choose one or more", comment:"") }
                                if segExtRow.otherRow != nil {
                                    let otherCode:String? = formFieldEntry.getOptionSVFile(forTag: "$$$other$")
                                    if !(otherCode ?? "").isEmpty {
                                        segExtRow.otherRow!.title = CodePair.findValue(pairs: controlPairs, givenCode: otherCode!)
                                    }
                                }
                            }
                            break
                        case FIELD_ROW_TYPE.YESNO:
                            let segExtRow = row as! SegmentedRowExt<String>
                            segExtRow.title = rowTitle
                            segExtRow.title2 = rowTitle2
                            if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                               let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                               controlPairs.count > 0 {
                                
                                segExtRow.retainedObject = controlPairs
                                let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                                if !(topTitle ?? "").isEmpty { segExtRow.selectorTitle  = topTitle }
                                else { segExtRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                            }
                            break
                        case FIELD_ROW_TYPE.YESNOMAYBE:
                            let segExtRow = row as! SegmentedRowExt<String>
                            segExtRow.title = rowTitle
                            segExtRow.title2 = rowTitle2
                            if let controlPairs = self.prepareOptions(forFormFieldEntry: formFieldEntry),
                               let metaPairs = self.prepareMetadata(forFormFieldEntry: formFieldEntry),
                               controlPairs.count > 0 {
                                
                                segExtRow.retainedObject = controlPairs
                                let topTitle:String? = CodePair.findValue(pairs: metaPairs, givenCode: "***TopTitle")
                                if !(topTitle ?? "").isEmpty { segExtRow.selectorTitle  = topTitle }
                                else { segExtRow.selectorTitle = NSLocalizedString("Choose one", comment:"") }
                            }
                            break
                        }
                        row!.updateCell()
                    }
                } else if formFieldEntry.mFormFieldRec.rFieldProp_IDCode == FIELD_IDCODE_METADATA.SUBMIT_BUTTON.rawValue {
                    // found the Submit button metadata
                    var textString = NSLocalizedString("Submit", comment:"")
                    if !(formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown ?? "").isEmpty {
                        if !(formFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Name_Shown_Bilingual_2nd ?? "").isEmpty {
                            textString = formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown! + "\n" + (formFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Name_Shown_Bilingual_2nd!)
                        } else {
                            textString = formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!
                        }
                    }
                    self.mEntryVC!.button_submit.setTitle(textString, for: UIControl.State.normal)
                }
            }
        }
        self.tableView.reloadData()
        if !self.mEntryVC!.mEFP!.mPreviewMode { self.mEntryVC!.mEFP!.mFormFieldEntries = nil }    // free up some memory
    }
    
    // find a specific attribute by its tag
    private func findAttribute(byTag:String, inSet:[String]) -> [String] {
        let useKey = byTag + ":"
        for setString in inSet {
            if setString.starts(with: useKey) { return setString.components(separatedBy: ":") }
        }
        return []
    }
    
    // find a specific attribute by its tag
    private func findMetadata(byTag:String, inSet:[String]) -> [String] {
        let useKey = byTag + ":"
        for setString in inSet {
            if setString.starts(with: useKey) { return setString.components(separatedBy: ":") }
        }
        return []
    }
    
    // build up the metadata attribute controlPairs that might be needed;
    // the CodePair is the TagCode:Shown-Value else TagCode:SV-File-Value
    private func prepareMetadata(forFormFieldEntry:OrgFormFieldsEntry) -> [CodePair]? {
        if (forFormFieldEntry.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File?.count() ?? 0) == 0 &&
           (forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Metadatas_Name_Shown?.count() ?? 0) == 0 {
            // the entry has no metadata available; this is not an error since older created fields may not have newer metadata but should work in their default manner
            return nil
        }
        
        // first build-up all the Shown entries; do not bother to do match verification with the SV-File entries
        var metaPairs:[CodePair] = []
        let includeBilingual:Bool = ((forFormFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd?.count() ?? 0) > 0)
        if (forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Metadatas_Name_Shown?.count() ?? 0) > 0 {
            for cp in forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Metadatas_Name_Shown!.mAttributes {
                if cp.codeString.prefix(3) != "###" {
                    if !includeBilingual { metaPairs.append(cp) }
                    else {
                        let biValue:String? = forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Metadatas_Name_Shown!.findValue(givenCode: cp.codeString)
                        if (biValue ?? "").isEmpty { metaPairs.append(cp) }
                        else {
                            metaPairs.append(CodePair(cp.codeString, cp.valueString + "\n" + biValue!))
                        }
                    }
                }
            }
        }
        
        // now include any SV-File only entries that are not in the Shown set; these are non-localized metadata entries
        if (forFormFieldEntry.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File?.count() ?? 0) > 0 {
            for cp in forFormFieldEntry.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File!.mAttributes {
                if !CodePair.codeExists(pairs: metaPairs, givenCode: cp.codeString) {
                    metaPairs.append(cp)
                }
            }
        }
        return metaPairs
    }
        
    // build up the option attribute controlPairs needed for the various pickers in the Form;
    // the CodePair is the SV_File-Value:Shown-Value
    private func prepareOptions(forFormFieldEntry:OrgFormFieldsEntry, forExtension:String?=nil) -> [CodePair]? {
        let endUserDuring:String = NSLocalizedString("Form-Field#", comment:"") + " \(forFormFieldEntry.mFormFieldRec.rFormField_Index)"
        let extra:String = "\(forFormFieldEntry.mFormFieldRec.rFormField_Index): \(forFormFieldEntry.mFormFieldRec.rFieldProp_IDCode) is \(forFormFieldEntry.mFormFieldRec.rFieldProp_Row_Type.rawValue)"
        let funcName:String = "prepareOptions" + (self.mEntryVC!.mEFP!.mPreviewMode ? ".previewMode":"")
        
        // does the FormFieldEntry have any attributes?
        if (forFormFieldEntry.mFormFieldRec.rFieldProp_Options_Code_For_SV_File?.count() ?? 0) == 0 {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", during: "precheck1", errorMessage: "Missing all entries", extra: extra)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Form Field Error", comment:""), endUserDuring: endUserDuring, errorStruct: APP_ERROR(funcName: "\(self.mCTAG).\(funcName)", domain: self.mThrownDomain, errorCode: .MISSING_OR_MISMATCHED_FIELD_OPTIONS, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
            return nil
        }
        var optionSetLocaleComposedRec:RecOptionSetLocales_Composed? = nil
        
        // first check if this particular FormFieldEntry needs to pull in an external list of options from RecOptionSetLocales;
        // there may be additional ones present to prepend or postpend to the main list; these are only checks not the actual composition
        for svCP in forFormFieldEntry.mFormFieldRec.rFieldProp_Options_Code_For_SV_File!.mAttributes {
            if svCP.codeString.starts(with: "***OSLC_") {
                // yes, need to pull in a complete set from RecFieldAttribLocales; pre-checks; these are never shown bi-lingual
                if (forFormFieldEntry.mComposedOptionSetLocalesRecs?.count ?? 0) == 0 {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", during: "precheck2", errorMessage: "Missing records", extra: extra + "; for " + svCP.codeString)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Form Field Error", comment:""), endUserDuring: endUserDuring, errorStruct: APP_ERROR(funcName: "\(self.mCTAG).\(funcName)", domain: self.mThrownDomain, errorCode: .MISSING_OR_MISMATCHED_FIELD_OPTIONSET, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
                } else {
                    // is an extension needed to choose the partcular set?  This is used for State codes;
                    // if missing it is not reported as an error since state codes for most countries have not been encoded in the App's datafiles
                    let oslc:String = String(svCP.codeString.suffix(from: svCP.codeString.index(svCP.codeString.startIndex, offsetBy: 3)))
                    if !(forExtension ?? "").isEmpty {
                        for nextOSLrec:RecOptionSetLocales_Composed in forFormFieldEntry.mComposedOptionSetLocalesRecs! {
                            if nextOSLrec.rOptionSetLoc_Code == oslc &&
                               nextOSLrec.rOptionSetLoc_Code_Extension == forExtension {
                                optionSetLocaleComposedRec = nextOSLrec
                                break
                            }
                        }
                    } else {
                        optionSetLocaleComposedRec = forFormFieldEntry.mComposedOptionSetLocalesRecs![0]
                    }
                    
                    // check the chosen RecOptionSetLocales_Composed
                    if optionSetLocaleComposedRec != nil {
                        do {
                            try FieldAttributes.compareSync(domain: self.mThrownDomain,
                                                            sv: optionSetLocaleComposedRec!.rFieldLocProp_Options_Code_For_SV_File,
                                                            shown: optionSetLocaleComposedRec!.rFieldLocProp_Options_Name_Shown)
                        } catch {
                            var changedError:APP_ERROR = error as! APP_ERROR
                            changedError.errorCode = .MISSING_OR_MISMATCHED_FIELD_OPTIONSET
                            changedError.prependCallStack(funcName: "\(self.mCTAG).\(funcName)")
                            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", during: "precheck3", errorStruct: changedError, extra: extra + "; for " + svCP.codeString)
                            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Form Field Error", comment:""), endUserDuring: endUserDuring, errorStruct: changedError, buttonText: NSLocalizedString("Okay", comment:""))
                        }
                    }
                }
                break
            }
        }
        
        // now do the checks on the rest of the option attributes
        do {
            try FieldAttributes.compareSync(domain: self.mThrownDomain,
                                            sv: forFormFieldEntry.mFormFieldRec.rFieldProp_Options_Code_For_SV_File,
                                            shown: forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Options_Name_Shown,
                                            deepSync: true)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", during: "precheck4", errorStruct: error, extra: extra)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Form Field Error", comment:""), endUserDuring: endUserDuring, errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return nil
        }
        
        // all the checks are done and were satisfactory, now compose the pairs
        var controlPairs:[CodePair] = []
        let includeBilingual:Bool = ((forFormFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Options_Name_Shown_Bilingual_2nd?.count() ?? 0) > 0)
        for svCP in forFormFieldEntry.mFormFieldRec.rFieldProp_Options_Code_For_SV_File!.mAttributes {
            if !svCP.codeString.starts(with: "***OSLC_") {
                // pull in locally defined options
                let shownString:String = forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Options_Name_Shown!.findValue(givenCode: svCP.codeString)!
                if !includeBilingual {
                    controlPairs.append(CodePair(svCP.valueString, shownString))
                } else {
                    let shownBiString:String? = forFormFieldEntry.mComposedFormFieldLocalesRec.mFieldLocProp_Options_Name_Shown_Bilingual_2nd!.findValue(givenCode: svCP.codeString)
                    if (shownBiString ?? "").isEmpty {
                        controlPairs.append(CodePair(svCP.valueString, shownString))
                    } else {
                        controlPairs.append(CodePair(svCP.valueString, shownString + "\n" + shownBiString!))
                    }
                }
            } else {
                if optionSetLocaleComposedRec != nil {
                    // pull in any found external options
                    for oslSVcp in optionSetLocaleComposedRec!.rFieldLocProp_Options_Code_For_SV_File!.mAttributes {
                        let shownString:String = optionSetLocaleComposedRec!.rFieldLocProp_Options_Name_Shown!.findValue(givenCode: oslSVcp.codeString)!
                        controlPairs.append(CodePair(oslSVcp.valueString, shownString))
                    }
                }
            }
        }
        
        return controlPairs
    }
    
    // control pairs structure:  ["[-;he;she;they;ze]", "[n/d;he;she;they;ze]"], ["[...]", "[...]", ["[...]", "[...]"
    private func preparePronouns(forFormFieldEntry:OrgFormFieldsEntry, sourcePairs:[CodePair]) -> ([CodePair],[CodePair],[CodePair]) {
        var set1Pairs:[CodePair] = []
        var set2Pairs:[CodePair] = []
        var set3Pairs:[CodePair] = []

        var sInx:Int = 0
        for sourcePair in sourcePairs {
            let codeComponents = sourcePair.codeString.components(separatedBy: ";")
            let shownComponents = sourcePair.valueString.components(separatedBy: ";")
            if codeComponents.count == shownComponents.count {
                for cInx:Int in 0...codeComponents.count - 1 {
                    switch sInx {
                    case 0:
                        set1Pairs.append(CodePair(codeComponents[cInx], shownComponents[cInx]))
                        break
                    case 1:
                        set2Pairs.append(CodePair(codeComponents[cInx], shownComponents[cInx]))
                        break
                    case 2:
                        set3Pairs.append(CodePair(codeComponents[cInx], shownComponents[cInx]))
                        break
                    default:
                        break
                    }
                }
            }
            sInx = sInx + 1
        }
        return (set1Pairs, set2Pairs, set3Pairs)
    }
}
