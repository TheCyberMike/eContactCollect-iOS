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
    
    // member constants and other static content
    private let mCTAG:String = "VCSP"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear()
    // will be called if this VC opens another VC;  need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
            form.removeAll()
            tableView.reloadData()
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed")
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
        } catch {}          // do not bother to report errors at the menu
        if orgQty == 1 {
            do {
                let records:AnySequence<SQLite.Row> = try RecOrganizationDefs.orgGetAllRecs()
                for rowObj in records {
                    let lastOrgRec:RecOrganizationDefs? = try RecOrganizationDefs(row:rowObj)
                    orgShortName = lastOrgRec?.rOrg_Code_For_SV_File
                    break
                }
                
            } catch {}  // do not bother to report errors at the menu
        }
        
        let section2 = Section(NSLocalizedString("Actions", comment:""))
        form +++ section2
        section2 <<< ButtonRow() {
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
        section2 <<< ButtonRow() {
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
        section2 <<< ButtonRow() {
            $0.tag = "import_settings"
            $0.title = NSLocalizedString("Import all Settings for an Org or Form", comment:"")
            }.onCellSelection { [weak self] cell, row in
                let documentPicker:UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["opensource.theCyberMike.eContactCollect.eContactCollectConfig"], in: UIDocumentPickerMode.import)
                documentPicker.delegate = self
                documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                self!.present(documentPicker, animated: true, completion: nil)
                
        }
        section2 <<< ButtonRow() {
            $0.tag = "factory_reset"
            $0.title = NSLocalizedString("Factory Reset [everything is wiped]", comment:"")
            }.onCellSelection { [weak self] cell, row in
                AppDelegate.showYesNoDialog(vc: self!, title: NSLocalizedString("Action Confirmation", comment:""), message: NSLocalizedString("This reset cannot be undone; all your settings, stored contacts, and stored SV files will be lost!", comment:""), buttonYesText: NSLocalizedString("Yes", comment:""), buttonNoText: NSLocalizedString("No", comment:""), callbackAction: 1, callbackString1: row.value, callbackString2: nil, completion: {[weak self] (vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                    // callback from the yes/no dialog upon one of the buttons being pressed
                    if theResult && callbackAction == 1  {
                        // answer was Yes; reset everything
                        AppDelegate.mSVFilesHandler!.deleteAll()
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
        } catch {}          // do not bother to report errors at the menu
        if formQty == 1 {
            do {
                let records:AnySequence<SQLite.Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: forOrgShortName)
                for rowObj in records {
                    let lastFormRec:RecOrgFormDefs? = try RecOrgFormDefs(row:rowObj)
                    formShortName = lastFormRec?.rForm_Code_For_SV_File
                    break
                }
                
            } catch {}  // do not bother to report errors at the menu
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
                // show the error back in the main UI thread; error.log and alert already done
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
