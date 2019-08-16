//
//  PopupImportViewController.swift
//  eContact Collect
//
//  Created by Dev on 5/22/19.
//

import UIKit
import Eureka
import SQLite

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol CIVC_Delegate {
    // return wasChosen=nil if cancelled; wasChosen=Org_short_name if chosen
    func completed_CIVC_ImportSuccess()
}

class PopupImportViewController: UIViewController {
    // caller pre-set member variables
    public var mCIVCdelegate:CIVC_Delegate? = nil   // optional callback
    public var mFromExternal:Bool = false           // external file open?
    public var mFileURL:URL? = nil                  // file URL to be opened
    
    // member variables
    internal var mFormOnly:Bool = false
    internal var mFileOrgName:String? = nil
    internal var mFileFormNames:String? = nil
    internal var mFile1stFormName:String? = nil
    internal var mStoreAsOrgName:String? = nil
    internal var mStoreAsFormName:String? = nil
    internal var mOrgShortNames:[String] = []
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
            self.importConfigFile()
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
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 257)    // must be one higher than the read length
        buffer.initialize(to: 0)
        let qty = stream!.read(buffer, maxLength: 256)
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
        buffer.deallocate()
        
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
        } else {
            // Org and Forms file
            if (self.mFileOrgName ?? "").isEmpty {
                self.mPreImportErrors.append(NSLocalizedString("The Org configuration file is missing its stored Org name", comment: ""))
            }
        }
        
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
    
    // perform the actual import
    private func importConfigFile() {
        do {
            let result:DatabaseHandler.ImportOrgOrForm_Result = try DatabaseHandler.importOrgOrForm(fromFileAtPath: self.mFileURL!.path, intoOrgShortName: self.mStoreAsOrgName, asFormShortName: self.mStoreAsFormName)
            if self.mFormOnly {
                // Form-only import was performed
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Success", comment:""), message: NSLocalizedString("The Form configuration file was successfully imported.", comment:""), buttonText: NSLocalizedString("Okay", comment:""), completion: { self.dismiss(animated: true, completion: {
                        if self.mCIVCdelegate != nil { self.mCIVCdelegate!.completed_CIVC_ImportSuccess() }
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
                        if self.mCIVCdelegate != nil { self.mCIVCdelegate!.completed_CIVC_ImportSuccess() }
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
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Import Error", comment:""), errorStruct: userError, buttonText: NSLocalizedString("Okay", comment:""))
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
            if self.mParentVC!.mOrgShortNames.count == 1 {      // case of mOrgShortNames.count == 0 already covered in pre-import errors
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
