//
//  AdminPrefsViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/23/18.
//

import Eureka
import SQLite

class AdminPrefsViewController: FormViewController, COVC_Delegate, CFVC_Delegate, UIDocumentPickerDelegate {
    // member variables
    private var mEmailDefault:String? = nil
    private var mEmailViaOptions:[EmailVia]? = nil
    private weak var mMVSaccts:MultivaluedSection? = nil
    private weak var mDefaultAcct:PushRow<String>? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCSP"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        self.mEmailDefault = EmailHandler.shared.getLocalizedDefaultEmail()
        self.mEmailViaOptions = EmailHandler.shared.getListEmailOptions()
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView
        self.refreshEmailAccts()
        self.refreshDefaultEmailAcct()
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear()
    // will be called if this VC opens another VC;  need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
            form.removeAll()
            tableView.reloadData()
            self.mEmailViaOptions = nil
            self.mMVSaccts = nil
            self.mDefaultAcct = nil
        } else {
debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed")
        }
        super.viewDidDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // validate the Form's entries; return true is all okay; return false if any errors
    private func validateAll() -> Bool {
        let validationError = form.validate()
        if validationError.count == 0 { return true }
        
        var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
        for errorStr in validationError {
            message = message + errorStr.msg + "\n"
        }
        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message:message, buttonText: NSLocalizedString("Okay", comment:""))
        return false
    }
    
    // refresh the Email Accts MVS
    private func refreshEmailAccts() {
        self.mEmailViaOptions = EmailHandler.shared.getListEmailOptions()
        self.mDefaultAcct!.options = self.mEmailViaOptions!.map { $0.viaNameLocalized }
        
        // check the recorded EmailVias against what is in the MVS
        for emailVia in self.mEmailViaOptions! {
            if let br = form.rowBy(tag: "AC," + emailVia.viaNameLocalized) {
                // EmailVia already exists as a buttonRow; change it
                br.title = emailVia.viaNameLocalized
                br.retainedObject = emailVia
                br.updateCell()
            } else {
                // EmailVia is not in the MVS; add it
                let br1 = self.makeAccountsButtonRow(forVia: emailVia)
                let ar = form.rowBy(tag: "add_new_account")
                do {
                    try self.mMVSaccts!.insert(row: br1, before: ar!)
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).refreshEmailAccts", errorStruct: error, extra: nil)
                    // do not show an error to the end-user
                }
            }
        }
        // not going to check for deletions
    }
    private func refreshDefaultEmailAcct() {
        self.mEmailDefault = EmailHandler.shared.getLocalizedDefaultEmail()
        self.mDefaultAcct!.value = self.mEmailDefault
    }
    
    // build the form
    private func buildForm() {
        let section1 = Section(NSLocalizedString("Personal Settings", comment:""))
        form +++ section1
        var savedPIN:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.APP_Pin)
        section1 <<< PasswordRow() {
            $0.tag = "personal_pin"
            $0.title = NSLocalizedString("Your PIN", comment:"")
            $0.value = savedPIN
            }.cellUpdate() { cell, row in
                cell.textField.keyboardType = .numberPad
            }.onCellHighlightChanged { [weak self] cell, row in
                if !row.isHighlighted {
                    if row.value != savedPIN {
                        var msg:String = ""
                        if (row.value ?? "").isEmpty {
                            msg = NSLocalizedString("Are you sure you want to remove your PIN?", comment:"")
                        } else {
                            msg = NSLocalizedString("Are you sure you want to change your PIN to", comment:"") + " \(row.value!)?"
                        }
                        AppDelegate.showYesNoDialog(vc: self!, title: NSLocalizedString("Change Confirmation", comment:""), message: msg, buttonYesText: NSLocalizedString("Yes", comment:""), buttonNoText: NSLocalizedString("No", comment:""), callbackAction: 1, callbackString1: row.value, callbackString2: nil, completion: {(vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                            // callback from the yes/no dialog upon one of the buttons being pressed
                            if theResult && callbackAction == 1  {
                                // answer was Yes; change the PIN
                                savedPIN = callbackString1
                                if (callbackString1 ?? "").isEmpty {
                                    AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_Pin, value: nil)
                                } else {
                                    AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_Pin, value: callbackString1!)
                                }
                            } else {
                                // restore the prior PIN into the field
                                row.value = savedPIN
                                row.updateCell()
                            }
                            return  // from callback
                        })
                    }
                }
        }
        let savedNickame:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.Collector_Nickname)
        section1 <<< TextRow() {
            $0.tag = "personal_nickname"
            $0.title = NSLocalizedString("Your Short Nickname", comment:"")
            $0.value = savedNickame
            $0.add(rule: RuleRequired(msg: NSLocalizedString("Nickname cannot be blank", comment:"")))
            $0.add(rule: RuleValidChars(acceptableChars: AppDelegate.mAcceptableNameChars, msg: NSLocalizedString("Nickname can only contain letters, digits, space, or _ . + -", comment:"")))
            $0.validationOptions = .validatesAlways
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { chgRow in
                let _ = chgRow.validate()
                if chgRow.isValid {
                    if !(chgRow.value ?? "").isEmpty {
                        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.Collector_Nickname, value: chgRow.value!)
                    }
                }
            }.onCellHighlightChanged { [weak self] cell, row in
                if !row.isHighlighted {
                    let _ = self!.validateAll()
                }
        }
        
        // determine quantity of Org records and the name of the only Org record
        var orgQty:Int64 = 0
        var orgShortName:String? = nil
        do {
            orgQty = try RecOrganizationDefs.orgGetQtyRecs()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).buildForm", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
        if orgQty == 1 {
            do {
                let records:AnySequence<SQLite.Row> = try RecOrganizationDefs.orgGetAllRecs()
                for rowObj in records {
                    let lastOrgRec:RecOrganizationDefs? = try RecOrganizationDefs(row:rowObj)
                    orgShortName = lastOrgRec?.rOrg_Code_For_SV_File
                    break
                }
                
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).buildForm", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
        }

        let defaultAcctRow = PushRow<String>(){ row in
            row.title = NSLocalizedString("Default Sending Email Acct", comment:"")
            row.tag = "email_default"
            row.selectorTitle = NSLocalizedString("Choose one", comment:"")
            row.options = self.mEmailViaOptions!.map { $0.viaNameLocalized }
            row.value = self.mEmailDefault
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mEmailDefault =  chgRow.value!
                    EmailHandler.shared.setLocalizedDefaultEmail(localizedName: chgRow.value!)
                    self!.refreshEmailAccts()
                }
        }
        section1 <<< defaultAcctRow
        self.mDefaultAcct = defaultAcctRow
        
        let mvs_accounts = MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
            header: NSLocalizedString("Sending Email Accounts", comment:"")) { mvSection in
                mvSection.tag = "email_mvs_accounts"
                mvSection.showInsertIconInAddButton = false
                mvSection.addButtonProvider = { section in
                    return ButtonRow(){ row in
                        row.title = NSLocalizedString("Select new provider to add", comment:"")
                        row.tag = "add_new_account"
                        row.presentationMode = .show(
                            controllerProvider: .callback(builder: { return AdminPrefsEmailProvidersViewController() } ),
                            onDismiss: nil)
                        }.cellUpdate { cell, row in
                            cell.textLabel?.textAlignment = .left
                            //cell.textLabel?.font = .systemFont(ofSize: 15.0)
                            cell.textLabel?.textColor = UIColor.black
                            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
                            row.onCellSelection { cell, row in }    // override the default behavior of the MVS ButtonRow
                    }
                }  // end of addButtonProvider
                /*mvSection.multivaluedRowToInsertAt = { [weak self] index in
                    // not necessary for this particular MVS
                }*/
        }
        form +++ mvs_accounts
        self.mMVSaccts = mvs_accounts
        
        let section3 = Section(NSLocalizedString("Actions", comment:""))
        form +++ section3
        section3 <<< ButtonRow() {
            $0.tag = "export_settings_org"
            $0.title = NSLocalizedString("Export/Backup all Settings for an Organization", comment:"")
            if orgQty <= 0 { $0.disabled = true }
            }.onCellSelection { [weak self] cell, row in
                if orgQty == 1 || orgShortName != nil {
                    self!.generateOrgOrFormConfigFile(forOrgShortName: orgShortName!)
                } else {
                    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC ChooseOrg") as! ChooserOrgViewController
                    newViewController.mCOVCdelegate = self
                    newViewController.mFor = 0
                    newViewController.modalPresentationStyle = .custom
                    self!.present(newViewController, animated: true, completion: nil)
                }
        }
        section3 <<< ButtonRow() {
            $0.tag = "export_settings_form"
            $0.title = NSLocalizedString("Export/Backup all Settings for one Form", comment:"")
            if orgQty <= 0 { $0.disabled = true }
            }.onCellSelection { [weak self] cell, row in
                if orgQty == 1 || orgShortName != nil {
                    self!.chooseForm(forOrgShortName: orgShortName!)
                } else {
                    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC ChooseOrg") as! ChooserOrgViewController
                    newViewController.mCOVCdelegate = self
                    newViewController.mFor = 1
                    newViewController.modalPresentationStyle = .custom
                    self!.present(newViewController, animated: true, completion: nil)
                }
        }
        section3 <<< ButtonRow() {
            $0.tag = "import_settings"
            $0.title = NSLocalizedString("Import all Settings for an Org or Form", comment:"")
            }.onCellSelection { [weak self] cell, row in
                let documentPicker:UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["opensource.theCyberMike.eContactCollect.eContactCollectConfig"], in: UIDocumentPickerMode.import)
                documentPicker.delegate = self
                documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                self!.present(documentPicker, animated: true, completion: nil)
                
        }
        section3 <<< ButtonRow() {
            $0.tag = "factory_reset"
            $0.title = NSLocalizedString("Factory Reset [everything is wiped]", comment:"")
            }.onCellSelection { [weak self] cell, row in
                AppDelegate.showYesNoDialog(vc: self!, title: NSLocalizedString("Action Confirmation", comment:""), message: NSLocalizedString("This reset cannot be undone; all your settings, stored contacts, and stored SV files will be lost!", comment:""), buttonYesText: NSLocalizedString("Yes", comment:""), buttonNoText: NSLocalizedString("No", comment:""), callbackAction: 1, callbackString1: row.value, callbackString2: nil, completion: {[weak self] (vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                    // callback from the yes/no dialog upon one of the buttons being pressed
                    if theResult && callbackAction == 1  {
                        // answer was Yes; reset everything
                        do {
                            try AppDelegate.mSVFilesHandler!.deleteAll()
                        } catch {
                            AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).buildForm.ButtonRow.factory_reset", errorStruct: error, extra: nil)
                            // do not show this error to the end-user
                        }
                        (UIApplication.shared.delegate as! AppDelegate).resetCurrents()
                        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.Collector_Nickname, value: nil)
                        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_Pin, value: nil)
                        AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 0)
                        AppDelegate.mFirstTImeStages = 0
                        let row1 = self!.form.rowBy(tag: "personal_pin")
                        if row1 != nil { (row1! as! PasswordRow).value = nil; row1!.updateCell() }
                        let row2 = self!.form.rowBy(tag: "personal_nickname")
                        if row2 != nil { (row2! as! TextRow).value = nil; row2!.updateCell()  }
                        let succeeded = AppDelegate.mDatabaseHandler!.factoryResetEntireDB()
                        if !succeeded {
                            AppDelegate.postAlert(message: NSLocalizedString("Factory reset of the database failed", comment:""))
                            AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Database Error", comment:""), message: NSLocalizedString("Database failed to Factory Reset", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                        } else {
                            AppDelegate.postAlert(message: NSLocalizedString("Factory reset was successful", comment:""))
                        }
                    }
                    return  // from callback
                })
        }
    }
    
    // create the pretty complex button row needed for existing and new FormField records
    private func makeAccountsButtonRow(forVia:EmailVia) -> ButtonRow {
        return ButtonRow() { row in
            row.tag = "AC,\(forVia.viaNameLocalized)"
            row.cellStyle = UITableViewCell.CellStyle.subtitle
            row.title = forVia.viaNameLocalized
            row.retainedObject = forVia
            row.presentationMode = .show(
                // selecting the ButtonRow invokes FormEditFieldFormViewController with callback so the row's content can be refreshed
                controllerProvider: .callback(builder: { [weak row] in
                    let vc = AdminPrefsEditEmailAccountViewController()
                    vc.mEditVia = (row!.retainedObject as! EmailVia)
                    vc.mAction = .Change
                    return vc
                }),
                onDismiss: { [weak row] vc in
                    row!.updateCell()
            })
            }.cellUpdate { cell, row in
                if row.retainedObject != nil {
                    let via = (row.retainedObject as! EmailVia)
                    // create and show the second line of text in the row
                    cell.detailTextLabel?.text = via.userDisplayName
                }
        }
    }
    
    // dynamically make the ButtonRows associated with the EmailAccounts deletable or not depending on conditions
    override open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let superStyle = super.tableView(tableView, editingStyleForRowAt: indexPath)
        guard let section = form[indexPath.section] as? MultivaluedSection else {
            return superStyle
        }
        
        if section.tag != "email_mvs_accounts" { return superStyle }
        if indexPath.row == section.count - 1 { return superStyle }
        let hasTag:String? = form[indexPath.section][indexPath.row].tag
        if hasTag == nil { return superStyle }
        if !hasTag!.starts(with: "AC,") { return superStyle }
        if (self.mEmailViaOptions?.count ?? 0) <= 1 { return .none }    // only one or no Email providers then cannot delete
        let comps = hasTag!.components(separatedBy: ",")
        if comps[1] == self.mEmailDefault { return .none }              // cannot delete the default email provider
        return superStyle
    }
    
    // this function will get invoked when any rows are deleted or hidden anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        
        var inx:Int = 0
        for indexPath in indexes {
            if indexPath.section == 1 {
                // this removal or move or hide occured in the email_mvs_accounts MultivaluedSection
                let br:ButtonRow = rows[inx] as! ButtonRow
                if br.tag != nil, br.tag!.starts(with: "AC,") {
debugPrint("\(self.mCTAG).rowsHaveBeenRemoved.email_mvs_accounts Delete #\(inx): \(indexPath.item) is \(br.title!)")
                    do {
                        try EmailHandler.shared.deleteEmailVia(localizedName: br.title!)
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).rowsHaveBeenRemoved", errorStruct: error, extra: br.title!)
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                        return
                    }
                }
            }
            inx = inx + 1
        }
        self.refreshEmailAccts()
    }
    
    // return from the Org Chooser view;
    // note: the chooser view is still showing and the chooser view controller is still the mainline;
    // this callback MUST perform dismiss of the chooser view controller
    func completed_COVC(fromVC:ChooserOrgViewController, wasChosen:String?) {
//debugPrint("\(self.mCTAG).completed_COVC STARTED")
        dismiss(animated: true, completion: {
            // perform the following after the dismiss is completed so the showAlertDialog will work
            if wasChosen != nil {
                // generate the file in a background thread
                if fromVC.mFor == 1 {
                    self.chooseForm(forOrgShortName: wasChosen!)
                } else {
                    self.generateOrgOrFormConfigFile(forOrgShortName: wasChosen!)
                }
            }
            return // from the completion handler
        })
    }
    
    // choose the Form to export
    private func chooseForm(forOrgShortName:String) {
        // determine quantity of Form records and the name of the only Form record
        var formQty:Int64 = 0
        var formShortName:String? = nil
        do {
            formQty = try RecOrgFormDefs.orgFormGetQtyRecs(forOrgShortName: forOrgShortName)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).chooseForm", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
        if formQty == 1 {
            do {
                let records:AnySequence<SQLite.Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: forOrgShortName)
                for rowObj in records {
                    let lastFormRec:RecOrgFormDefs? = try RecOrgFormDefs(row:rowObj)
                    formShortName = lastFormRec?.rForm_Code_For_SV_File
                    break
                }
                
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).chooseForm", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
        }
        
        if formQty == 1 && formShortName != nil {
            self.generateOrgOrFormConfigFile(forOrgShortName: forOrgShortName, forFormShortName: formShortName)
        } else {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC ChooseForm") as! ChooserFormViewController
            newViewController.mCFVCdelegate = self
            newViewController.mForOrgShortName = forOrgShortName
            newViewController.modalPresentationStyle = .custom
            self.present(newViewController, animated: true, completion: nil)
        }
    }
    
    // return from the Form Chooser view;
    // note: the chooser view is still showing and the chooser view controller is still the mainline;
    // this callback MUST perform dismiss of the chooser view controller
    func completed_CFVC(fromVC:ChooserFormViewController, wasChosen:String?) {
//debugPrint("\(self.mCTAG).completed_CFVC STARTED")
        dismiss(animated: true, completion: {
            // perform the following after the dismiss is completed so the showAlertDialog will work
            if wasChosen != nil {
                // generate the file in a background thread
                self.generateOrgOrFormConfigFile(forOrgShortName: fromVC.mForOrgShortName!, forFormShortName: wasChosen!)
            }
            return // from the completion handler
        })
    }
    
    // generate the chosen Org or Form config file
    private func generateOrgOrFormConfigFile(forOrgShortName:String, forFormShortName:String?=nil) {
//debugPrint("\(self.mCTAG).generateOrgOrFormConfigFile STARTED")
        DispatchQueue.global(qos:.utility).async {
            do {
                let filename = try DatabaseHandler.exportOrgOrForm(forOrgShortName: forOrgShortName, forFormShortName: forFormShortName)
                // show the result back in the main UI thread
                DispatchQueue.main.async {
                    let msg:String = NSLocalizedString("The Exported configuration file named", comment:"") + "\"\(filename)\"" + NSLocalizedString("is now available in the iOS Files app for sharing", comment:"")
                    AppDelegate.postAlert(message: msg)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Success", comment:""), message: msg, buttonText: NSLocalizedString("Okay", comment:""))
                }
            } catch {
                // post the error then show the error back in the main UI thread
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).generateOrgOrFormConfigFile", errorStruct: error, extra: nil)
                DispatchQueue.main.async {
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Export Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
        }
    }
    
    // return from the document picker
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        UIHelpers.importConfigFile(fromURL: urls[0], usingVC: self)
    }
}

///////////////////////////////////////////////////
// class definition for AdminPrefsEmailProvidersViewController
///////////////////////////////////////////////////

class AdminPrefsEmailProvidersViewController: FormViewController {
    // member variables
    
    // member constants and other static content
    private let mCTAG:String = "VCSPPL"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationItem.title = NSLocalizedString("Choose one", comment:"")
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear()
    // will be called if this VC opens another VC;  need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
            form.removeAll()
            tableView.reloadData()
        } else {
debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed")
        }
        super.viewDidDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // build the form
    private func buildForm() {
        let section1 = Section(NSLocalizedString("Select new provider to add", comment:""))
        form +++ section1
        
        let emailViaPotentials:[EmailVia] = EmailHandler.shared.getListPotentialEmailProviders()
        for via in emailViaPotentials {
            section1 <<< ButtonRow(){ row in
                row.tag = "PV,\(via.emailProvider_InternalName)"
                row.title = via.viaNameLocalized
                row.retainedObject = via
                row.presentationMode = .show(
                    // selecting the ButtonRow invokes FormEditFieldFormViewController with callback so the row's content can be refreshed
                    controllerProvider: .callback(builder: { [weak row] in
                        let vc = AdminPrefsEditEmailAccountViewController()
                        vc.mEditVia = (row!.retainedObject as! EmailVia)
                        vc.mAction = .Add
                        return vc
                    }),
                    onDismiss: { [weak row] vc in
                        row!.updateCell()
                })
                }.cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .left
                    //cell.textLabel?.font = .systemFont(ofSize: 15.0)
                    cell.textLabel?.textColor = UIColor.black
                    cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }
        }
    }
}

///////////////////////////////////////////////////
// class definition for AdminPrefsEditEmailAccountViewController
///////////////////////////////////////////////////

class AdminPrefsEditEmailAccountViewController: FormViewController {
    // caller pre-set member variables
    public weak var mEditVia:EmailVia? = nil        // EmailVia to add or change
    public var mAction:APEEAVC_Actions = .Add       // .Add or .Change
    
    // member variables
    public var mWorkingVia:EmailVia? = nil
    private var mTestResultsRow:TextAreaRowExt? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCSPEA"
    internal enum APEEAVC_Actions {
        case Add, Change
    }
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
debugPrint("\(mCTAG).deinit STARTED")
        NotificationCenter.default.removeObserver(self, name: .APP_EmailCompleted, object: nil)
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        assert(self.mEditVia != nil, "\(self.mCTAG).viewDidLoad mEditVia == nil")    // this is a programming error
        self.mWorkingVia = EmailVia(fromExisting: self.mEditVia!)    // make a deep-copy duplicate
        
        if self.mAction == .Change {
            if self.mWorkingVia!.viaType == .SMTPknown {
                if self.mWorkingVia!.emailProvider_SMTP == nil {
                    self.mWorkingVia!.emailProvider_SMTP = EmailProviderSMTP(localizedName: self.mWorkingVia!.viaNameLocalized, knownProviderInternalName: self.mWorkingVia!.emailProvider_InternalName)
                }
            }
            if self.mWorkingVia!.viaType == .SMTPknown || self.mWorkingVia!.viaType == .SMTPsettings {
                if self.mWorkingVia!.emailProvider_Credentials == nil {
                    // get the userid and password from the secure store
                    var encodedCred:Data? = nil
                    do {
                        encodedCred = try AppDelegate.retrieveSecureItem(key: self.mWorkingVia!.viaNameLocalized, label: "Email")
                        if encodedCred != nil {
                            self.mWorkingVia!.emailProvider_Credentials = EmailAccountCredentials(localizedName: self.mWorkingVia!.viaNameLocalized, data: encodedCred!)
                        }
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewDidLoad", errorStruct: error, extra: self.mWorkingVia!.viaNameLocalized)
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    }
                }
            }
        }
        
        let button1 = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(AdminPrefsEditEmailAccountViewController.tappedDone(_:)))
        button1.title = NSLocalizedString("Save", comment:"")
        navigationItem.rightBarButtonItem = button1
        let button2 = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(AdminPrefsEditEmailAccountViewController.tappedCancel(_:)))
        button2.title = NSLocalizedString("Cancel", comment:"")
        navigationItem.leftBarButtonItem = button2
        
        // add an observer for Notifications about complete SMTP tests
        NotificationCenter.default.addObserver(self, selector: #selector(noticeEmailCompleted(_:)), name: .APP_EmailCompleted, object: nil)
    
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        if self.mAction == .Change { navigationItem.title = NSLocalizedString("Change Account", comment:"") }
        else { navigationItem.title = NSLocalizedString("Add Account", comment:"") }
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear()
    // will be called if this VC opens another VC;  need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
            form.removeAll()
            tableView.reloadData()
            self.mEditVia = nil
            self.mWorkingVia = nil
        } else {
debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed")
        }
        super.viewDidDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Cancel button was tapped
    @objc func tappedCancel(_ barButtonItem: UIBarButtonItem) {
        self.mEditVia = self.mWorkingVia        // return all unsaved changes so they can re-appear if the end-user returns to re-try the add/change
        self.navigationController?.popViewController(animated:true)
    }
    
    // Done button was tapped
    @objc func tappedDone(_ barButtonItem: UIBarButtonItem) {
        // validate the entries
        if !self.validateForm() { return }
        
        // ensure the localizedName is unique upon an add
        if self.mAction == .Add {
            if EmailHandler.shared.storedEmailViaExists(localizedName: self.mWorkingVia!.viaNameLocalized) {
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Account Nickname already exists", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                return
            }
        }
        
        // finalize the EmailVia type and other settings
        if self.mWorkingVia!.viaType == .SMTPknown {
            let override:Bool = ((form.rowBy(tag: "override_settings") as? SwitchRow)?.value ?? false)
            if !override {
                self.mWorkingVia!.emailProvider_SMTP = nil
            } else if self.mWorkingVia!.emailProvider_SMTP == self.mEditVia!.emailProvider_SMTP {
                self.mWorkingVia!.emailProvider_SMTP = nil
            } else {
                self.mWorkingVia!.viaType = .SMTPsettings
            }
        }
        self.mWorkingVia!.emailProvider_SMTP?.viaNameLocalized = self.mWorkingVia!.viaNameLocalized
        self.mWorkingVia!.emailProvider_Credentials?.viaNameLocalized = self.mWorkingVia!.viaNameLocalized
        
        // save or update the EmailVia into the proper storage areas
        self.mEditVia = self.mWorkingVia        // return all saved changes so they can re-appear if the end-user tries again
        do {
            try EmailHandler.shared.storeEmailVia(via: self.mEditVia!)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).tappedDone", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        self.navigationController?.popViewController(animated:true)
    }
    
    // validate the form and show error
    public func validateForm() -> Bool {
        let validationError = self.form.validate()
        if validationError.count > 0 {
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: message, buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        return true
    }
    
    // build the form
    private func buildForm() {
        let section1 = Section()
        form +++ section1
        
        if !(self.mWorkingVia!.emailProvider_SMTP?.localizedNotes ?? "").isEmpty {
            section1 <<< TextAreaRowExt() {
                //$0.title = ""
                $0.tag = "acct_notes"
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 60)
                $0.value = self.mWorkingVia!.emailProvider_SMTP!.localizedNotes!
                }.cellUpdate { cell, row in
                    cell.textView.font = .systemFont(ofSize: 14.0)
                    cell.textView.layer.cornerRadius = 0
                    cell.textView.layer.borderColor = UIColor.gray.cgColor
                    cell.textView.layer.borderWidth = 1
            }
        }
        
        section1 <<< TextRow() {
            $0.title = NSLocalizedString("Account Nickname", comment:"")
            $0.tag = "acct_nickname"
            $0.value = self.mWorkingVia!.viaNameLocalized
            $0.add(rule: RuleRequired() )
            $0.add(rule: RuleValidChars(acceptableChars: AppDelegate.mAcceptableNameChars, msg: NSLocalizedString("Account Nickname can only contain letters, digits, space, or _ . + -", comment:"")))
            $0.validationOptions = .validatesAlways
            if self.mAction == .Change { $0.disabled = true }
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { chgRow in
                if chgRow.value != nil {
                    self.mWorkingVia!.viaNameLocalized = chgRow.value!
                }
        }
        
        if self.mWorkingVia!.viaType == .API || self.mWorkingVia!.viaType == .None { return }
        
        section1 <<< TextRow() {
            $0.title = NSLocalizedString("From: Email Name", comment:"")
            $0.tag = "sending_email_name"
            $0.value = self.mWorkingVia!.userDisplayName
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { chgRow in
                if chgRow.value != nil {
                    self.mWorkingVia!.userDisplayName = chgRow.value!
                }
        }
        section1 <<< EmailRow() {
            $0.title = NSLocalizedString("From: Email Address", comment:"")
            $0.tag = "sending_email_addr"
            $0.value = self.mWorkingVia!.sendingEmailAddress
            $0.add(rule: RuleRequired() )
            $0.validationOptions = .validatesAlways
            }.cellUpdate { cell, row in
                cell.textField?.autocapitalizationType = .none
                cell.textField?.autocorrectionType = .no
                cell.textField?.spellCheckingType = .no
                if #available(iOS 11.0, *) {
                    cell.textField?.smartQuotesType = .no
                    cell.textField?.smartDashesType = .no
                }
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { chgRow in
                if chgRow.value != nil {
                    self.mWorkingVia!.sendingEmailAddress = chgRow.value!
                }
        }
        section1 <<< TextRow() {
            $0.title = NSLocalizedString("Email Acct: UserID", comment:"")
            $0.tag = "acct_userid"
            $0.value = self.mWorkingVia!.emailProvider_Credentials?.username
            $0.add(rule: RuleRequired() )
            $0.validationOptions = .validatesAlways
            }.cellUpdate { cell, row in
                cell.textField?.autocapitalizationType = .none
                cell.textField?.autocorrectionType = .no
                cell.textField?.spellCheckingType = .no
                if #available(iOS 11.0, *) {
                    cell.textField?.smartQuotesType = .no
                    cell.textField?.smartDashesType = .no
                }
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { chgRow in
                if chgRow.value != nil {
                    if self.mWorkingVia!.emailProvider_Credentials == nil { self.mWorkingVia!.emailProvider_Credentials = EmailAccountCredentials() }
                    self.mWorkingVia!.emailProvider_Credentials!.username = chgRow.value!
                }
        }
        if self.mAction == .Add {
            section1 <<< TextRow() {
                $0.title = NSLocalizedString("Email Acct: Password", comment:"")
                $0.tag = "acct_password"
                $0.value = self.mWorkingVia!.emailProvider_Credentials?.password
                }.cellUpdate { cell, row in
                    cell.textField?.autocapitalizationType = .none
                    cell.textField?.autocorrectionType = .no
                    cell.textField?.spellCheckingType = .no
                    if #available(iOS 11.0, *) {
                        cell.textField?.smartQuotesType = .no
                        cell.textField?.smartDashesType = .no
                    }
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { chgRow in
                    if chgRow.value != nil {
                        if self.mWorkingVia!.emailProvider_Credentials == nil { self.mWorkingVia!.emailProvider_Credentials = EmailAccountCredentials() }
                        self.mWorkingVia!.emailProvider_Credentials!.password = chgRow.value!
                    }
            }
        } else {
            section1 <<< PasswordRow() {
                $0.title = NSLocalizedString("Email Acct: Password", comment:"")
                $0.tag = "acct_password"
                $0.value = self.mWorkingVia!.emailProvider_Credentials?.password
                }.cellUpdate { cell, row in
                    cell.textField?.autocapitalizationType = .none
                    cell.textField?.autocorrectionType = .no
                    cell.textField?.spellCheckingType = .no
                    if #available(iOS 11.0, *) {
                        cell.textField?.smartQuotesType = .no
                        cell.textField?.smartDashesType = .no
                    }
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { chgRow in
                    if chgRow.value != nil {
                        if self.mWorkingVia!.emailProvider_Credentials == nil { self.mWorkingVia!.emailProvider_Credentials = EmailAccountCredentials() }
                        self.mWorkingVia!.emailProvider_Credentials!.password = chgRow.value!
                    }
            }
        }
        
        if self.mWorkingVia!.viaType == .SMTPknown || self.mWorkingVia!.viaType == .SMTPsettings {
            let section2 = Section(NSLocalizedString("SMTP Email Provider Settings", comment:""))
            form +++ section2
            
            section2 <<< SwitchRow() {
                $0.title = NSLocalizedString("Override standard settings?", comment:"")
                $0.tag = "override_settings"
                if self.mWorkingVia!.viaType == .SMTPknown { $0.value = false }
                else { $0.value = true  }
                $0.hidden = self.mWorkingVia!.viaType == .SMTPknown ? false : true
            }
            
            section2 <<< TextRow() {
                $0.title = NSLocalizedString("HostName", comment:"")
                $0.tag = "smtp_hostname"
                $0.value = self.mWorkingVia!.emailProvider_SMTP?.hostname
                $0.disabled = Condition.function(["override_settings"], { form in
                    return !((form.rowBy(tag: "override_settings") as? SwitchRow)?.value ?? false)
                })
                $0.add(rule: RuleRequired() )
                $0.validationOptions = .validatesAlways
                }.cellUpdate { cell, row in
                    cell.textField?.autocapitalizationType = .none
                    cell.textField?.autocorrectionType = .no
                    cell.textField?.spellCheckingType = .no
                    if #available(iOS 11.0, *) {
                        cell.textField?.smartQuotesType = .no
                        cell.textField?.smartDashesType = .no
                    }
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { chgRow in
                    if chgRow.value != nil {
                        if self.mWorkingVia!.emailProvider_SMTP == nil { self.mWorkingVia!.emailProvider_SMTP = EmailProviderSMTP() }
                        self.mWorkingVia!.emailProvider_SMTP!.hostname = chgRow.value!
                    }
            }
            section2 <<< IntRow() {
                $0.title = NSLocalizedString("Port", comment:"")
                $0.tag = "smtp_port"
                $0.value = self.mWorkingVia!.emailProvider_SMTP?.port
                $0.disabled = Condition.function(["override_settings"], { form in
                    return !((form.rowBy(tag: "override_settings") as? SwitchRow)?.value ?? false)
                })
                $0.add(rule: RuleRequired() )
                $0.add(rule: RuleGreaterThan(min: 1))
                $0.add(rule: RuleSmallerThan(max: 65535))
                $0.validationOptions = .validatesAlways
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { chgRow in
                    if chgRow.value != nil {
                        if self.mWorkingVia!.emailProvider_SMTP == nil { self.mWorkingVia!.emailProvider_SMTP = EmailProviderSMTP() }
                        self.mWorkingVia!.emailProvider_SMTP!.port = chgRow.value!
                    }
            }
            
            section2 <<< SegmentedRowExt<String>() {
                $0.title = NSLocalizedString("Connection Type", comment:"")
                $0.tag = "smtp_connection"
                $0.allowMultiSelect = false
                $0.options = EmailHandler.connectionTypeDefs.map { $0.typeStrLocalized }
                if self.mWorkingVia!.emailProvider_SMTP != nil {
                    for aConnTypeDef in EmailHandler.connectionTypeDefs {
                        if self.mWorkingVia!.emailProvider_SMTP!.connectionType == aConnTypeDef.type {
                            $0.value = Set([aConnTypeDef.typeStrLocalized])
                            break
                        }
                    }
                } else {
                    $0.value = Set([EmailHandler.connectionTypeDefs[2].typeStrLocalized])
                }
                $0.disabled = Condition.function(["override_settings"], { form in
                    return !((form.rowBy(tag: "override_settings") as? SwitchRow)?.value ?? false)
                })
                $0.add(rule: RuleRequired() )
                $0.validationOptions = .validatesAlways
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { chgRow in
                    if chgRow.value != nil {
                        if self.mWorkingVia!.emailProvider_SMTP == nil { self.mWorkingVia!.emailProvider_SMTP = EmailProviderSMTP() }
                        for item in chgRow.value! {
                            for aConnTypeDef in EmailHandler.connectionTypeDefs {
                                if item == aConnTypeDef.typeStrLocalized {
                                    self.mWorkingVia!.emailProvider_SMTP!.connectionType = aConnTypeDef.type
                                    break
                                }
                            }
                        }
                    }
            }
            section2 <<< PushRow<String>() {
                $0.title = NSLocalizedString("Authentication Type", comment:"")
                $0.tag = "smtp_authentication"
                $0.options = EmailHandler.authTypeDefs.map { $0.typeStrLocalized }
                if self.mWorkingVia!.emailProvider_SMTP != nil {
                    for anAuthTypeDef in EmailHandler.authTypeDefs {
                        if self.mWorkingVia!.emailProvider_SMTP!.authType == anAuthTypeDef.type {
                            $0.value = anAuthTypeDef.typeStrLocalized
                            break
                        }
                    }
                } else {
                    $0.value = EmailHandler.authTypeDefs[1].typeStrLocalized
                }
                $0.disabled = Condition.function(["override_settings"], { form in
                    return !((form.rowBy(tag: "override_settings") as? SwitchRow)?.value ?? false)
                })
                $0.add(rule: RuleRequired() )
                $0.validationOptions = .validatesAlways
                }.cellUpdate { cell, row in
                    //if !row.isValid {
                        //cell.titleLabel?.textColor = .red
                    //}
                }.onChange { chgRow in
                    if chgRow.value != nil {
                        if self.mWorkingVia!.emailProvider_SMTP == nil { self.mWorkingVia!.emailProvider_SMTP = EmailProviderSMTP() }
                        for anAuthTypeDef in EmailHandler.authTypeDefs {
                            if chgRow.value! == anAuthTypeDef.typeStrLocalized {
                                self.mWorkingVia!.emailProvider_SMTP!.authType = anAuthTypeDef.type
                                break
                            }
                        }
                    }
            }
            
            let section3 = Section(NSLocalizedString("Test the Settings", comment:""))
            form +++ section3
            
            section3 <<< ButtonRow() {
                $0.tag = "test_smtp_connection"
                $0.title = NSLocalizedString("Press HERE to test access to Email Provider", comment:"")
                }.cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .left
                    //cell.textLabel?.font = .systemFont(ofSize: 15.0)
                    cell.textLabel?.textColor = UIColor.black
                    //cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
                }.onCellSelection { [weak self] cell, row in
                    if self!.validateForm() {
                        do {
                            try EmailHandler.shared.testEmailViaMailCore(vc: self!, invoker: "AdminPrefsEditEmailAccountViewController", tagI: 1, tagS: "$test", via: self!.mWorkingVia!)
                        } catch {
                            // do not post these test errors to error.log
                            AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Email Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                        }
                    }
            }
            
            let testResultsRow = TextAreaRowExt() {
                $0.tag = "test_smtp_connection_results"
                $0.title = NSLocalizedString("Test Results", comment:"")
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 120)
                }.cellUpdate { cell, row in
                    cell.textView.font = .systemFont(ofSize: 12.0)
                    cell.textView.layer.cornerRadius = 0
                    cell.textView.layer.borderColor = UIColor.gray.cgColor
                    cell.textView.layer.borderWidth = 1
            }
            section3 <<< testResultsRow
            self.mTestResultsRow = testResultsRow
        }
    }
    
    // notification of the EMailHandler that a pending email or test was completed
    @objc func noticeEmailCompleted(_ notification:Notification) {
        if let emailResult:EmailResult = notification.object as? EmailResult {
            if emailResult.invoker == "AdminPrefsEditEmailAccountViewController" {
debugPrint("\(self.mCTAG).noticeEmailCompleted STARTED")
                self.mTestResultsRow!.value = emailResult.extendedDetails
                self.mTestResultsRow!.updateCell()
                tableView.reloadData()  // allow the TextAreaRowExt to re-size its height
                
                if emailResult.error != nil {
                    // returned errors will properly have the 'noPost' setting for those email or oauth errors that should not get posted to error.log
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).noticeEmailCompleted", errorStruct: emailResult.error!, extra: nil)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Email Error", comment:""), errorStruct: emailResult.error!, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
        }
    }
}
