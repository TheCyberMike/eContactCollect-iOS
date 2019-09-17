//
//  PopupImportViewController.swift
//  eContact Collect
//
//  Created by Dev on 5/22/19.
//

import UIKit
import Eureka
import SQLite

// define the delegate protocol that other portions of the App must use to know when the import succeeded
protocol CIVC_Delegate {
    func completed_CIVC_ImportSuccess(fromVC:PopupImportViewController, orgWasImported:String, formWasImported:String?)
}

class PopupImportViewController: UIViewController {
    // caller pre-set member variables
    public var mCIVCdelegate:CIVC_Delegate? = nil   // optional callback
    public var mFromExternal:Bool = false           // external file open?
    public var mFileURL:URL? = nil                  // file URL to be opened
    public var mForOrgShortCode:String? = nil       // target Org Code (optional)
    
    // member variables
    internal var mFormOnly:Bool = false
    internal var mFileOrgName:String? = nil
    internal var mFileFormNames:String? = nil
    internal var mFile1stFormName:String? = nil
    internal var mStoreAsOrgName:String? = nil
    internal var mStoreAsFormName:String? = nil
    internal var mOrgShortNames:[String] = []
    internal var mFormLanguages:String? = nil
    internal var mPreImportErrors:[String] = []
    
    // member constants and other static content
    private let mCTAG:String = "VCUCI"
    private var mImportFormVC:PopupImportFormViewController? = nil

    // outlets to screen controls
    @IBAction func button_cancel_press(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func button_import_pressed(_ sender: UIButton) {
        if !self.mPreImportErrors.isEmpty { return }
        let validationError = self.mImportFormVC!.form.validate()
        if validationError.count > 0 {
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: message, buttonText: NSLocalizedString("Okay", comment:""))
        } else {
            let warningMsg:String? = self.precheckLanguages()
            if warningMsg == nil {
                self.importConfigFile(langMode:  .NO_CHANGES_NEEDED)
            } else {
                if warningMsg!.contains("!!") {
                    AppDelegate.showYesNoDialog(vc: self, title: NSLocalizedString("Action Confirmation", comment:""), message: NSLocalizedString("Import cannot proceed per the warning below unless you authorize that all the Form's missing languages be ADDED to the Organization's supported languages; this has implications for all the Organization's existing Forms.", comment:""), buttonYesText: NSLocalizedString("Add All to Org", comment:""), buttonNoText: NSLocalizedString("Cancel", comment:""), callbackAction: 1, callbackString1: nil, callbackString2: nil, completion: {[weak self] (vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                        // callback from the yes/no dialog upon one of the buttons being pressed
                        if theResult && callbackAction == 1  {
                            // answer was Yes; import by adding all missing languages to Org first
                            self!.importConfigFile(langMode: .APPEND_MISSING_LANGS_TO_ORG)
                        }
                        return  // from callback
                    })
                } else {
                    AppDelegate.show3ButtonDialog(vc: self, title: NSLocalizedString("Action Confirmation", comment:""), message: NSLocalizedString("Per the warning below, you can either BEST-FIT just those Form languages that match in some manner with the Organization's existing languages; or you can first ADD those of the Form's missing languages to the Organization's supported languages (which preserves the entire import) but has implications for all the Organization's existing Forms.", comment:""), button1Text: NSLocalizedString("Best-Fit Only", comment:""), button2Text: NSLocalizedString("Add Missing then Best-Fit", comment:""), button3Text: NSLocalizedString("Cancel", comment:""), callbackAction: 1, callbackString1: nil, callbackString2: nil, completion: {[weak self] (vc:UIViewController, theChoice:Int, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                        // callback from the yes/no/cancel dialog upon one of the buttons being pressed
                        if callbackAction == 1  {
                            if theChoice == 1 {
                                // answer was Yes; perform only a best-fit import
                                self!.importConfigFile(langMode: .BEST_FIT)
                            } else if theChoice == 2 {
                                // answer was Yes; import by adding first all missing languages to Org, then perform a best-fit
                                self!.importConfigFile(langMode: .APPEND_MISSING_LANGS_TO_ORG)
                            }
                        }
                        return  // from callback
                    })
                }
            }
        }
    }
    @IBOutlet weak var button_import: UIButton!
    @IBOutlet weak var label_title: UILabel!
    @IBOutlet weak var label_subtitle: UILabel!
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // locate our children view controllers
        self.mImportFormVC = nil
        for childVC in children {
            let vc1:PopupImportFormViewController? = childVC as? PopupImportFormViewController
            if vc1 != nil { self.mImportFormVC = vc1 }
        }
        assert(self.mImportFormVC != nil, "\(self.mCTAG).viewDidLoad self.mImportFormVC == nil")    // this is a programming error
        assert(self.mFileURL != nil, "\(self.mCTAG).viewDidLoad self.mFileURL == nil")    // this is a programming error

        // determine which Org records pre-exist
        do {
            let records:AnySequence<SQLite.Row> = try RecOrganizationDefs.orgGetAllRecs()
            for rowObj in records {
                let orgRec1:RecOrganizationDefs = try RecOrganizationDefs(row:rowObj)
                self.mOrgShortNames.append(orgRec1.rOrg_Code_For_SV_File)
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewDidLoad", errorStruct: error, extra: nil)
            self.mPreImportErrors.append(AppDelegate.endUserErrorMessage(errorStruct: error))
        }

        // open the proposed file and get its header information
        let stream = InputStream(fileAtPath: self.mFileURL!.path)
        if stream == nil {
            self.mPreImportErrors.append(NSLocalizedString("Could not open the file", comment: ""))
            return
        }
        stream!.open()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 513)    // must be one higher than the read length
        buffer.initialize(to: 0)
        let qty = stream!.read(buffer, maxLength: 512)
        stream!.close()
        if qty == 0 {
            self.mPreImportErrors.append(NSLocalizedString("The selected file was empty", comment: ""))
            return
        }
        
        // validate the retrieved content's method field
        var valid:Bool = false
        let bufferString = String(cString: buffer)
        if bufferString.contains("\"method\":\"eContactCollect.db.org.export\"") {
            valid = true
            self.mFormOnly = false
            self.label_subtitle.text = NSLocalizedString("Org & Forms", comment:"")
        } else if bufferString.contains("\"method\":\"eContactCollect.db.form.export\"") {
            valid = true
            self.mFormOnly = true
            self.label_subtitle.text = NSLocalizedString("Form", comment:"")
        }
        if !valid {
            buffer.deallocate()
            self.mPreImportErrors.append(NSLocalizedString("The selected file was not one of this App's configuration files", comment: ""))
            return
        }
        
        // validate the retrieved content's context field
        if let contextRange1:Range = bufferString.range(of: "\"context\":\"") {
            let contextPos1:String.Index = bufferString.index(contextRange1.upperBound, offsetBy: 0)
            if let contextRange2:Range = bufferString[contextPos1...].range(of: "\"") {
                let contextPos2:String.Index = bufferString.index(contextRange2.lowerBound, offsetBy: -1)
                let contextString = bufferString[contextPos1...contextPos2]
                let nameComponents1 = contextString.components(separatedBy: ";")
                if nameComponents1.count >= 2 {
                    // new format of 'context':  Org;Form,Form,...      Org;Form        ;Form
                    self.mFileOrgName = nameComponents1[0]
                    self.mFileFormNames = nameComponents1[1]
                    let nameComponents2 = nameComponents1[1].components(separatedBy: ",")
                    self.mFile1stFormName = nameComponents2[0]
                } else {
                    // old format of 'context':  Org                    Org,Form
                    let nameComponents2 = contextString.components(separatedBy: ",")
                    self.mFileOrgName = nameComponents2[0]
                    if nameComponents2.count > 1 { self.mFileFormNames = nameComponents2[1]; self.mFile1stFormName = nameComponents2[1] }
                    else { self.mFileFormNames = nil; self.mFile1stFormName = nil }
                }
            } else {
                buffer.deallocate()
                self.mPreImportErrors.append(NSLocalizedString("The selected file's 'context' is improperly formatted", comment: ""))
                return
            }
        } else {
            buffer.deallocate()
            self.mPreImportErrors.append(NSLocalizedString("The selected file was not one of this App's configuration files", comment: ""))
            return
        }

        self.mStoreAsOrgName = self.mFileOrgName
        self.mStoreAsFormName = self.mFile1stFormName
        
        // Additional checks
        if self.mFormOnly {
            // Form-only file
            if (self.mFile1stFormName ?? "").isEmpty {
                self.mPreImportErrors.append(NSLocalizedString("The Form configuration file is missing its stored Form name", comment: ""))
            } else if self.mOrgShortNames.count == 0 {
                // it is a Form-only import and there are no Org records available at all; cannot import
                self.mPreImportErrors.append(NSLocalizedString("A Form configuration file cannot be imported if you have no Organizations defined", comment: ""))
            } else if (self.mFileOrgName ?? "").isEmpty {
                // it is a sample from from the support website
                self.label_subtitle.text = NSLocalizedString("Sample Form", comment:"")
            } else {
                // not a sample form, but does the File's Org exist in this App's database?
                let inx:Int? = self.mOrgShortNames.firstIndex(of: self.mFileOrgName!)
                if inx == nil {
                    // File's Org name is not in this App's database, so force the end-user to choose an Org in the App's database
                    self.mFileOrgName = nil
                }
            }
            // get the form's languages
            if let langRange1 = bufferString.range(of: "\"languages\":\"") {
                let langPos1:String.Index = bufferString.index(langRange1.upperBound, offsetBy: 0)
                if let langRange2:Range = bufferString[langPos1...].range(of: "\"") {
                    let langPos2:String.Index = bufferString.index(langRange2.lowerBound, offsetBy: -1)
                    self.mFormLanguages = String(bufferString[langPos1...langPos2])
                }
            }
        } else {
            // Org and Forms file
            if (self.mFileOrgName ?? "").isEmpty {
                self.mPreImportErrors.append(NSLocalizedString("The Org configuration file is missing its stored Org name", comment: ""))
            }
        }
        buffer.deallocate()

        if !self.mPreImportErrors.isEmpty { self.button_import.isHidden = true }
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // precheck the import form's languages against the Org's languages; return warning string if there is a problem
    public func precheckLanguages() -> String? {
        if (self.mStoreAsOrgName ?? "").isEmpty { return nil }
        if (self.mFormLanguages ?? "").isEmpty { return nil }
        
        do {
            let orgRec:RecOrganizationDefs? = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: self.mStoreAsOrgName!)
            if orgRec == nil { return nil }
            let result:FieldHandler.AssessLangRegions_Results = FieldHandler.assessLangRegions(sourcelangRegions: self.mFormLanguages!.components(separatedBy: ","), targetOrgRec: orgRec!)
            switch result.mode {
            case .NO_CHANGES_NEEDED:
                break
            case .MISSINGS_ONLY:
                return NSLocalizedString("WARNING: The import Form's language/regions are not well aligned with the Into-Organization's language/regions", comment:"") + ": " + orgRec!.rOrg_LangRegionCodes_Supported.joined(separator: ",")
            case .BEST_FIT:
                return NSLocalizedString("WARNING: The import Form's language/regions are not well aligned with the Into-Organization's language/regions", comment:"") + ": " + orgRec!.rOrg_LangRegionCodes_Supported.joined(separator: ",")
            case .IMPOSSIBLE:
                return NSLocalizedString("WARNING!!: There are no matching langage/regions between the import Form and the Into-Organization", comment:"") + ": " + orgRec!.rOrg_LangRegionCodes_Supported.joined(separator: ",")
            }
        } catch {}
        return nil
    }
    
    // perform the actual import
    private func importConfigFile(langMode:DatabaseHandler.ImportOrgOrFormLangMode) {
        do {
            let result:DatabaseHandler.ImportOrgOrForm_Result = try DatabaseHandler.importOrgOrForm(fromFileAtPath: self.mFileURL!.path, intoOrgShortName: self.mStoreAsOrgName, asFormShortName: self.mStoreAsFormName, langMode: langMode)
            if self.mFormOnly {
                // Form-only import was performed
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Success", comment:""), message: NSLocalizedString("The Form configuration file was successfully imported.", comment:""), buttonText: NSLocalizedString("Okay", comment:""), completion: { self.dismiss(animated: true, completion: {
                        if self.mCIVCdelegate != nil { self.mCIVCdelegate!.completed_CIVC_ImportSuccess(fromVC: self, orgWasImported: result.wasOrgShortName, formWasImported: nil) }
                    })
                })
                if AppDelegate.mEntryFormProvisioner == nil {
                    // this will trigger an auto-create of the mainline EFP and an auto-load of the first Org and Form in the DB
                    (UIApplication.shared.delegate as! AppDelegate).setCurrentOrg(toOrgShortName: result.wasOrgShortName)
                } else if AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File == result.wasOrgShortName &&
                    AppDelegate.mEntryFormProvisioner!.mFormRec!.rForm_Code_For_SV_File == result.wasFormShortName {
                    // the shown Org's Form is the same as the imported Org's Form; need to inform of the shown Form's changes throughout the App
                    (UIApplication.shared.delegate as! AppDelegate).setCurrentForm(toFormShortName: result.wasFormShortName, withOrgShortName: result.wasOrgShortName)
                }
            } else {
                // entire Org and all its Forms inport was performed
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Success", comment:""), message: NSLocalizedString("The Organization configuration file was successfully imported.", comment:""), buttonText: NSLocalizedString("Okay", comment:""), completion: { self.dismiss(animated: true, completion: {
                        if self.mCIVCdelegate != nil { self.mCIVCdelegate!.completed_CIVC_ImportSuccess(fromVC: self, orgWasImported: result.wasOrgShortName, formWasImported: result.wasFormShortName) }
                    })
                })
                if AppDelegate.mEntryFormProvisioner == nil {
                    // this will trigger an auto-create of the mainline EFP and an auto-load of the first Org in the DB
                    (UIApplication.shared.delegate as! AppDelegate).setCurrentOrg(toOrgRec: nil)
                } else if AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File == result.wasOrgShortName {
                    // the shown Org is the one just imported; need to inform of the changed shown Org and Forms throughout the App;
                    // if the currently showing Form is no longer present, the first or only Form of the Org will auto-show
                    (UIApplication.shared.delegate as! AppDelegate).setCurrentOrg(toOrgShortName: result.wasOrgShortName)
                }
            }
        } catch let userError as USER_ERROR {
            // user errors are never posted to the error.log
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("User Error", comment:""), errorStruct: userError, buttonText: NSLocalizedString("Okay", comment:""))
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).importConfigFile", errorStruct: error, extra: self.mFileURL!.path)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Import Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// Form child ViewController
/////////////////////////////////////////////////////////////////////////

class PopupImportFormViewController: FormViewController {
    // member variables
    private var mFormIsBuilt:Bool = false
    
    // member constants and other static content
    private let mCTAG:String = "VCUCIF"
    private weak var mParentVC:PopupImportViewController? = nil
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        // self.parent is not set until viewWillAppear()
    }
    
    // called by the framework when the view will re-appear;
    // remember this will be called upon return from the image chooser dialog
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // locate our parent then build the form; initializing values as we go
        self.mParentVC = (self.parent as! PopupImportViewController)
        self.buildForm()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // clear out the Form (caused by segue or cancel)
    public func clearVC() {
        form.removeAll()
        tableView.reloadData()
        self.mFormIsBuilt = false
    }
    
    // build the form
    private func buildForm() {
        if self.mFormIsBuilt { return }
        form.removeAll()
        tableView.reloadData()
        
        // identify the file to-be-imported
        let section1 = Section()
        form +++ section1
        section1 <<< LabelRow() {
            $0.title = self.mParentVC!.mFileURL!.lastPathComponent
            }.cellUpdate { cell, row in
                cell.textLabel!.font = .systemFont(ofSize: 14.0)
        }
        
        // did any pre-import errros occur?
        if self.mParentVC!.mPreImportErrors.count > 0 {
            // yes; cannot continue with the import
            var msgString:String = ""
            for msg in self.self.mParentVC!.mPreImportErrors {
                msgString = msgString + msg + "\n\n"
            }

            let section2 = Section(NSLocalizedString("PRE-IMPORT ERRORS OCCURED", comment:""))
            form +++ section2
            section2 <<< TextAreaRow() {
                $0.value = msgString
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 120)
                }.cellUpdate { cell, row in
                    cell.textView.font = .systemFont(ofSize: 14.0)
            }
            self.mFormIsBuilt = true
            return
        }
        
        // build the import information form depending upon file contents and database contents
        if self.mParentVC!.mFormOnly {
            // Form-Only
            let section2 = Section(NSLocalizedString("Into Organization", comment:""))
            form +++ section2
            if !(self.mParentVC!.mForOrgShortCode ?? "").isEmpty {
                self.mParentVC!.mStoreAsOrgName = self.mParentVC!.mForOrgShortCode
                section2 <<< LabelRow() {
                    $0.tag = "orgName"
                    $0.title = self.mParentVC!.mForOrgShortCode
                }
            } else if self.mParentVC!.mOrgShortNames.count == 1 {      // case of mOrgShortNames.count == 0 already covered in pre-import errors
                self.mParentVC!.mStoreAsOrgName = self.mParentVC!.mOrgShortNames[0]
                section2 <<< LabelRow() {
                    $0.tag = "orgName"
                    $0.title = self.mParentVC!.mOrgShortNames[0]
                }
            } else {
                section2 <<< PushRow<String>() {
                    $0.tag = "orgName"
                    $0.title = NSLocalizedString("Org Code", comment:"")
                    $0.selectorTitle = NSLocalizedString("Choose one", comment:"")
                    $0.options = self.mParentVC!.mOrgShortNames
                    $0.value = self.mParentVC!.mFileOrgName     // can initially be null or blank in case of sample forms
                    $0.add(rule: RuleRequired(msg: NSLocalizedString("Org short name cannot be blank", comment:"")))
                    $0.validationOptions = .validatesAlways
                    }.onPresent { _, presentVC in
                        presentVC.onDismissCallback = { presentVC2 in
                            // since not using a NavController need to do a popup dismiss of the PopupRow's view controller
                            presentVC2.dismiss(animated: true, completion: nil)
                        }
                        
                    }.cellUpdate { cell, row in
                        if !row.isValid {
                            cell.textLabel?.textColor = .red
                        }
                    }.onChange { [weak self] chgRow in
                        let _ = chgRow.validate()
                        if chgRow.isValid && chgRow.value != nil {
                            self!.mParentVC!.mStoreAsOrgName = chgRow.value!
                            
                            // does the Form code already exist in the database for the newly selected Org?
                            let wr = self!.form.rowBy(tag: "formExistsWarning")
                            if wr != nil {
                                if self!.doesFormExist() { wr!.hidden = false }
                                else { wr!.hidden = true }
                                wr!.evaluateHidden()
                            }
                            
                            // are there language mis-match issues?
                            let wr1 = self!.form.rowBy(tag: "languageWarning")
                            if wr1 != nil {
                                if let hasWarning:String = self!.mParentVC!.precheckLanguages() {
                                    wr1!.title = hasWarning
                                    wr1!.hidden = false
                                } else { wr1!.hidden = true }
                                wr1!.evaluateHidden()
                                wr1!.updateCell()
                            }
                        }
                }
            }
            
            let section3 = Section(NSLocalizedString("As Form", comment:""))
            form +++ section3
            section3 <<< TextRow() {
                $0.tag = "formName"
                $0.title = NSLocalizedString("Form Code", comment:"")
                $0.value = self.mParentVC!.mFile1stFormName
                $0.add(rule: RuleRequired(msg: NSLocalizedString("Form short name cannot be blank", comment:"")))
                $0.add(rule: RuleValidChars(acceptableChars: AppDelegate.mAcceptableNameChars, msg: NSLocalizedString("Form short name can only contain letters, digits, space, or _ . + -", comment:"")))
                $0.validationOptions = .validatesAlways
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { [weak self] chgRow in
                    let _ = chgRow.validate()
                    if chgRow.isValid && chgRow.value != nil {
                        self!.mParentVC!.mStoreAsFormName = chgRow.value!
                        
                        // does the changed Form code already exist in the database for the selected Org?
                        let wr = self!.form.rowBy(tag: "formExistsWarning")
                        if wr != nil {
                            if self!.doesFormExist() { wr!.hidden = false }
                            else { wr!.hidden = true }
                            wr!.evaluateHidden()
                        }
                    }
            }
            section3 <<< LabelRow() {
                $0.tag = "formExistsWarning"
                $0.title = NSLocalizedString("WARNING: There is a Form already in the database for the chosen Org with the same name; if you import then the existing Form will be replaced with this file's form", comment:"")
                if self.doesFormExist() { $0.hidden = false }
                else { $0.hidden = true }
                }.cellUpdate { cell, row in
                    cell.textLabel!.numberOfLines = 0
                    cell.textLabel!.font = .systemFont(ofSize: 14.0)
            }
            if !(self.mParentVC!.mFormLanguages ?? "").isEmpty {
                let section4 = Section(NSLocalizedString("Language/Regions", comment:""))
                form +++ section4
                section4 <<< LabelRow() {
                    $0.tag = "formLanguages"
                    $0.title = NSLocalizedString("Source LangRegions: ", comment:"") + self.mParentVC!.mFormLanguages!
                    }.cellUpdate { cell, row in
                        cell.textLabel!.numberOfLines = 0
                        cell.textLabel!.font = .systemFont(ofSize: 14.0)
                }
                section4 <<< LabelRow() {
                    $0.tag = "languageWarning"
                    if let hasWarning:String = self.mParentVC!.precheckLanguages() {
                        $0.title = hasWarning
                        $0.hidden = false
                    } else { $0.hidden = true }
                    }.cellUpdate { cell, row in
                        cell.textLabel!.numberOfLines = 0
                        cell.textLabel!.font = .systemFont(ofSize: 14.0)
                }
            }
        } else {
            
            // Org and Forms
            let section2 = Section(NSLocalizedString("As Organization", comment:""))
            form +++ section2
            section2 <<< TextRow() {
                $0.tag = "orgName"
                $0.title = NSLocalizedString("Org Code", comment:"")
                $0.value = self.mParentVC!.mFileOrgName!
                $0.add(rule: RuleRequired(msg: NSLocalizedString("Organization short code cannot be blank", comment:"")))
                $0.add(rule: RuleValidChars(acceptableChars: AppDelegate.mAcceptableNameChars, msg: NSLocalizedString("Organization short code can only contain letters, digits, space, or _ . + -", comment:"")))
                $0.validationOptions = .validatesAlways
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { [weak self] chgRow in
                    let _ = chgRow.validate()
                    if chgRow.isValid && chgRow.value != nil {
                        self!.mParentVC!.mStoreAsOrgName = chgRow.value!
                        
                        // does the changed Org code already exist in the database?
                        let wr = self!.form.rowBy(tag: "orgExistsWarning")
                        if wr != nil {
                            let inx:Int? = self!.mParentVC!.mOrgShortNames.firstIndex(of: chgRow.value!)
                            if inx != nil { wr!.hidden = false }
                            else { wr!.hidden = true }
                            wr!.evaluateHidden()
                        }
                    }
            }
            section2 <<< LabelRow() {
                $0.tag = "orgExistsWarning"
                $0.title = NSLocalizedString("WARNING: There is an Org already in the database with the same name; if you import then all the existing Org's setting and forms will be replaced with this file's new configurations", comment:"")
                let inx:Int? = self.mParentVC!.mOrgShortNames.firstIndex(of: self.mParentVC!.mFileOrgName!)
                if inx == nil { $0.hidden = true }
                else { $0.hidden = false }
                }.cellUpdate { cell, row in
                    cell.textLabel!.numberOfLines = 0
                    cell.textLabel!.font = .systemFont(ofSize: 14.0)
            }
            
            let section3 = Section(NSLocalizedString("Contains Forms", comment:""))
            form +++ section3
            section3 <<< LabelRow() {
                $0.tag = "formNames"
                $0.title = self.mParentVC!.mFileFormNames
                }.cellUpdate { cell, row in
                    cell.textLabel!.font = .systemFont(ofSize: 14.0)
            }
        }
        self.mFormIsBuilt = true
    }
    
    // does the indicated Form already exist?
    private func doesFormExist() -> Bool {
        if (self.mParentVC!.mStoreAsOrgName ?? "").isEmpty { return false }
        if (self.mParentVC!.mStoreAsFormName ?? "").isEmpty { return false }
        
        do {
            let formRec:RecOrgFormDefs? = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName: self.mParentVC!.mStoreAsFormName!, forOrgShortName: self.mParentVC!.mStoreAsOrgName!)
            if formRec != nil { return true }
        } catch {}
        return false
    }
}
