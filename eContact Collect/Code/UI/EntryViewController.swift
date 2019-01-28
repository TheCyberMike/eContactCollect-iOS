//
//  EntryViewController.swift
//  eContact Collect
//
//  Created by Yo on 9/21/18.
//

import UIKit
import SQLite

class EntryViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, CLRVC_Delegate {
    // caller pre-set member variables
    public weak var mEFP:EntryFormProvisioner? = nil
    
    // member variables
    public var mDismissing:Bool = false
    private var isVisible:Bool = false
    private var mListenersEstablished:Bool = false
    private var mAppStartupsDone:Bool = false
    private var mButton_lang1_langRegion:String? = nil
    private var mButton_lang2_langRegion:String? = nil
    private var mEnteredDataDict:[String:Any?]? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCE"
    private weak var mEntryFormVC:EntryFormViewController? = nil

    // outlets to screen controls
    @IBOutlet weak var label_event: UILabel!
    @IBOutlet weak var button_submit: UIButton!
    @IBOutlet weak var button_lang1: UIButton!
    @IBOutlet weak var button_lang2: UIButton!
    @IBOutlet weak var button_lang_more: UIButton!
    @IBAction func button_submit_pressed(_ sender: UIButton) {
        let validationError = self.mEntryFormVC!.form.validate()
        if validationError.count == 0 {
            self.mEnteredDataDict = self.mEntryFormVC!.form.values(includeHidden:true)
//debugPrint("\(self.mCTAG).button_submit_pressed ENTERED_VALUEPAIRS=\(self.mEnteredDataDict!)")
            if !self.mEFP!.mPreviewMode {
                self.recordSubmission()
            }
            self.mEnteredDataDict = nil     // flush memory
            self.mEntryFormVC!.clearAll()
            
            // check whether the rating reminder interval should be incremented
            AppDelegate.ratingReminderIncrement(reason: .ContactCollected)
        } else {
//debugPrint("\(self.mCTAG).button_submit_pressed ERRORS=\(validationError)")
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message:message, buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
    @IBAction func button_lang1_pressed(_ sender: UIButton) {
        self.mEFP?.changeNewMultiLingual(toLangRegion: self.mButton_lang1_langRegion!)
        self.refresh()
    }
    @IBAction func button_lang2_pressed(_ sender: UIButton) {
        self.mEFP?.changeNewMultiLingual(toLangRegion: self.mButton_lang2_langRegion!)
        self.refresh()
    }
    @IBAction func button_lang_more_pressed(_ sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC ChooseLangRegion") as! ChooserLangRegionViewController
        newViewController.mCLRVCdelegate = self
        newViewController.mEFP = self.mEFP!
        newViewController.modalPresentationStyle = .custom
        self.present(newViewController, animated: true, completion: nil)
    }
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED \(self)")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED \(self)")
        
        // if we were not immediately given a provisioner, then use the mainline one (if there is indeed one available);
        // need to do this soonest possible
        if self.mEFP == nil {
            self.mEFP = AppDelegate.mEntryFormProvisioner
            self.mEFP?.mIsMainlineEFP = true
        }

        super.viewDidLoad()
        
        // listen for file-open notifications since this View Controller acts as the mainline
        NotificationCenter.default.addObserver(self, selector: #selector(noticeOpenConfigFile(_:)), name: .APP_FileRequestedToOpen, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(noticeCreatedMainEFP(_:)), name: .APP_CreatedMainEFP, object: nil)
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED \(self)")
        super.viewWillAppear(animated)
        self.isVisible = true

        
        // find the two Container View Controllers
        var orgTitleViewController:OrgTitleViewController? = nil
        for childVC in children {
            let vc1:OrgTitleViewController? = childVC as? OrgTitleViewController
            let vc2:EntryFormViewController? = childVC as? EntryFormViewController
            if vc1 != nil { orgTitleViewController = vc1 }
            if vc2 != nil { self.mEntryFormVC = vc2 }
        }
        
        // if Preview Mode, configure the OrgTitle to take up the Preview EFP
        if (self.mEFP?.mPreviewMode ?? false) && orgTitleViewController != nil {
            orgTitleViewController?.mEFP = self.mEFP
        }
        
        // initialize our access to the EFP
        self.initializeProvisionerAccess()
    }
    
    // called by the framework when the view has fully *re-appeared*
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)

        // non-automatic OrgTitle initialization must wait until viewDidAppear to ensure all UIView frame sizes have finalized
        // perform refresh of the components this view controller manages
        self.refresh()

        if !self.mAppStartupsDone {
            if (self.mEFP?.mPreviewMode ?? false) == false {
                // first time the App has re-started (not the first-time it has ever been run), and not in preview mode;
                // 1. check if any of the Handler's failed their initialization;
                // 2. check if there are any pending SV files not yet sent
                
                if AppDelegate.mDatabaseHandler == nil || !(AppDelegate.mDatabaseHandler!.isReady()) {
                    var msg:String = NSLocalizedString("The handler that manages the App's database ", comment:"") + NSLocalizedString("has experienced critical error(s) which should be in the error.log; the App may need to be shutdown and restarted; or possibly uninstalled and reinstalled.", comment:"")
                    if AppDelegate.mDatabaseHandler!.mAppError != nil { msg = msg + "\n\n" + AppDelegate.endUserErrorMessage(errorStruct: AppDelegate.mDatabaseHandler!.mAppError!)}
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Critical Error", comment:""), message: msg, buttonText: NSLocalizedString("Okay", comment:""))
                } else if AppDelegate.mFieldHandler == nil || !(AppDelegate.mFieldHandler!.isReady()) {
                    var msg:String = NSLocalizedString("The handler that manages basic definitions of form fields ", comment:"") + NSLocalizedString("has experienced critical error(s) which should be in the error.log; the App may need to be shutdown and restarted; or possibly uninstalled and reinstalled.", comment:"")
                    if AppDelegate.mFieldHandler!.mAppError != nil { msg = msg + "\n\n" + AppDelegate.endUserErrorMessage(errorStruct: AppDelegate.mFieldHandler!.mAppError!)}
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Severe Error", comment:""), message: msg, buttonText: NSLocalizedString("Okay", comment:""))
                } else if AppDelegate.mSVFilesHandler == nil || !(AppDelegate.mSVFilesHandler!.isReady()) {
                    var msg:String = NSLocalizedString("The handler that manages your SV files ", comment:"") + NSLocalizedString("has experienced critical error(s) which should be in the error.log; the App may need to be shutdown and restarted; or possibly uninstalled and reinstalled.", comment:"")
                            if AppDelegate.mSVFilesHandler!.mAppError != nil { msg = msg + "\n\n" + AppDelegate.endUserErrorMessage(errorStruct: AppDelegate.mSVFilesHandler!.mAppError!)}
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Severe Error", comment:""), message: msg, buttonText: NSLocalizedString("Okay", comment:""))
                } else {
                    do {
                        if try AppDelegate.mSVFilesHandler!.anyPendingFiles() {
                            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Notice", comment:""), message: NSLocalizedString("There are attachments waiting to be sent", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                        }
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mainline.viewDidAppear", during: "anyPendingFiles", errorStruct: error, extra: nil)
                        // do not show the end-user the error at this time
                    }
                }
                self.mAppStartupsDone = true
            }
        }
        
        // perform a rating reminder if it is time to do so
        AppDelegate.ratingReminderPerform(vc: self)
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            self.mDismissing = true
            self.mEFP?.mDismissing = true
        }
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        self.isVisible = false
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSING \(self)")
            NotificationCenter.default.removeObserver(self, name: .APP_FileRequestedToOpen, object: nil)
            NotificationCenter.default.removeObserver(self, name: .APP_CreatedMainEFP, object: nil)
            if self.mEFP != nil && self.mListenersEstablished {
                NotificationCenter.default.removeObserver(self, name: .APP_EFP_OrgFormChange, object: self.mEFP!)
                NotificationCenter.default.removeObserver(self, name: .APP_EFP_LangRegionChanged, object: self.mEFP!)
                self.mListenersEstablished = false
            }
            self.mEFP?.mDismissing = true
            self.mEFP = nil
            self.mEntryFormVC = nil
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed \(self)")
        }
        super.viewDidDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // initialize our access to the EFP
    private func initializeProvisionerAccess() {
        if self.mEFP == nil { return }
        
        if self.mEFP!.mPreviewMode {
            // preview mode: change the navigation bar color scheme to something bright and annoying
            self.navigationController!.navigationBar.barTintColor = UIColor.red
            self.navigationController!.navigationBar.tintColor = UIColor.black
        }
        if !self.mListenersEstablished {
            NotificationCenter.default.addObserver(self, selector: #selector(noticeNewOrgForm(_:)), name: .APP_EFP_OrgFormChange, object: self.mEFP!)
            NotificationCenter.default.addObserver(self, selector: #selector(noticeNewLang(_:)), name: .APP_EFP_LangRegionChanged, object: self.mEFP!)
            self.mListenersEstablished = true
        }
    }
    
    // received a notification that the mainline EFP was just created and made ready; note it could indicate a nil during a factory reset
    // usually this will be triggered when the VC is currently NOT showing
    @objc func noticeCreatedMainEFP(_ notification:Notification) {
        if AppDelegate.mEntryFormProvisioner != nil {
            // is being changed
            if self.mEFP == nil {
//debugPrint("\(self.mCTAG).noticeCreatedMainEFP TAKING UP NEW MAINLINE EFP \(self)")
                // and we do not have a EFP
                self.mEFP = AppDelegate.mEntryFormProvisioner
                self.initializeProvisionerAccess()
                self.refresh()
                self.mEntryFormVC!.noticeCreatedMainEFPPassThru()
            }
        } else {
            // is a factory reset
            if self.mEFP != nil {
                if self.mEFP!.mIsMainlineEFP {
//debugPrint("\(self.mCTAG).noticeCreatedMainEFP IS AFFECTED BY FACTORY RESET \(self)")
                    // and we are using the mainline EFP
                    self.mEntryFormVC!.noticeRemovingMainEFPPassThru()
                    if self.mListenersEstablished && self.mEFP != nil {
                        NotificationCenter.default.removeObserver(self, name: .APP_EFP_OrgFormChange, object: self.mEFP!)
                        NotificationCenter.default.removeObserver(self, name: .APP_EFP_LangRegionChanged, object: self.mEFP!)
                    }
                    self.mEFP = nil
                    self.refresh()
                    self.mEntryFormVC!.noticeCreatedMainEFPPassThru()
                }
            }
        }
    }
    
    // received a notification that the current Org or Form for our EFP has changed
    @objc func noticeNewOrgForm(_ notification:Notification) {
//debugPrint("\(self.mCTAG).noticeNewOrgForm STARTED \(self)")
        //self.refresh()  // ignore this for now ... a refresh gets done upon viewDidAppear() anyways and this ViewController triggers language changes
    }
    
    // received a notification that the lanugage for our EFP has changed
    @objc func noticeNewLang(_ notification:Notification) {
//debugPrint("\(self.mCTAG).noticeNewLang STARTED \(self)")
        //self.refresh()  // ignore this for now ... a refresh gets done upon viewDidAppear() anyways and this ViewController triggers language changes
    }
    
    // a language was selected from the chooser popup
    func completed_CLRVC(fromVC:ChooserLangRegionViewController, wasChosen:String?) {
        if wasChosen != nil {
//debugPrint("\(self.mCTAG).completed_CLRVC NEW LANG=\(wasChosen!)")
            self.mEFP?.changeNewMultiLingual(toLangRegion: wasChosen!)
            self.refresh()
        }
    }
    
    // received a notification that the end-user opened an OrgConfigs file
    @objc func noticeOpenConfigFile(_ notification:Notification) {
//debugPrint("\(self.mCTAG).openConfigFileNotice STARTED")
        if notification.userInfo == nil { return }
        let url:URL = notification.userInfo![UIApplication.OpenURLOptionsKey.url] as! URL
        UIHelpers.importConfigFile(fromURL: url, usingVC: self, fromExternal: true)
    }
    
    // refresh the limited content on the upper portion of the screen;
    // the OrgTitle, Event title, and Language buttons; the Submit button is handled by the EntryFormViewController
    // note that during a factory reset the self.mEFP will become nil and thus various previously shown values need to be cleared
    private func refresh() {
        if !self.isVisible { return }
        if self.mEFP == nil { return }
        let funcName:String = "refresh" + (self.mEFP!.mPreviewMode ? ".previewMode":"")
        
        // multi-lingual buttons
        if self.mEFP!.mShowMode == .MULTI_LINGUAL {
            let oCnt:Int = self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported.count
            
            do {
                let title1:String = try self.mEFP!.mOrgRec.getLangNameInLang(langRegion: self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[0])
                self.button_lang1.setTitle(title1, for: .normal)
                self.button_lang1.isHidden = false
                self.mButton_lang1_langRegion = self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[0]
                
                let title2:String = try self.mEFP!.mOrgRec.getLangNameInLang(langRegion: self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[1])
                self.button_lang2.setTitle(title2, for: .normal)
                self.button_lang2.isHidden = false
                self.mButton_lang2_langRegion = self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[1]
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", during:"Lang Button refresh", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
            
            if oCnt > 2 { self.button_lang_more.setTitle("...", for: .normal); self.button_lang_more.isHidden = false }
            else { self.button_lang_more.isHidden = true }
        } else {
            self.button_lang1.isHidden = true
            self.button_lang2.isHidden = true
            self.button_lang_more.isHidden = true
        }
        
        // refresh the Org's Event Shown text (if any)
        do {
            var shownEventTitle:String? = try self.mEFP!.mOrgRec.getEventTitleShown(langRegion: self.mEFP!.mShownLanguage)
            if (shownEventTitle ?? "").isEmpty { shownEventTitle = try self.mEFP!.mOrgRec.getEventTitleShown(langRegion: self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[0]) }
            if !(shownEventTitle ?? "").isEmpty { self.label_event.text = shownEventTitle! }
            else { self.label_event.text = "" }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", during:"Event refresh", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
    
    // record the submission into the database;
    // this will never get called in Preview mode
    private func recordSubmission() {
        if self.mEFP == nil { return }
        if self.mEFP!.mPreviewMode || self.mEFP!.mFormRec == nil { return } // will not be performed in preview mode
        if (self.mEnteredDataDict?.count ?? 0) == 0 { return }  // will not be performed if errors are pending
        let funcName:String = "recordSubmission" + (self.mEFP!.mPreviewMode ? ".previewMode":"")
        
        // capture the desired metadata for this submission
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd'T'HH:mm:ss"
        let dateTimeString:String = formatter.string(from: Date())
        let dateTimeStrings:[Substring] = dateTimeString.split(separator: "T")
        
        // gather the combined field information for this form in SV File order in prep to save to the file;
        // use the SV-File language
        do {
            self.mEFP!.mFormFieldEntries = try AppDelegate.mFieldHandler!.getOrgFormFields(forEFP: self.mEFP!, forceLangRegion: self.mEFP!.mOrgRec.rOrg_LangRegionCode_SV_File, includeOptionSets: false, metaDataOnly: false, sortedBySVFileOrder: true)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        
        // pre-process the set of fields and entered data to "decant" any container fields (name, address, phone)
        for formFieldEntry:OrgFormFieldsEntry in self.mEFP!.mFormFieldEntries! {
            // gather the field's various definitional records
            if !formFieldEntry.mDuringEditing_isDeleted &&  !formFieldEntry.mFormFieldRec.isMetaData() &&
                (formFieldEntry.mFormFieldRec.rFieldProp_Contains_Field_IDCodes?.count ?? 0) > 0 {
            
                // its a collection field
                let keyString:String = String(formFieldEntry.mFormFieldRec.rFormField_Index)
                let object = self.mEnteredDataDict![keyString]
                if object != nil {
                    if let objectDict:[String:Any?] = object as? [String:Any?] {
                        // row provided an Array of dictionary pairs [String:Any?] though usually its [String:String];
                        // unpack it; no need to delete the packed version of it
                        for pair in objectDict {
                            self.mEnteredDataDict![pair.key] = pair.value
                        }
                    }
                }
            }
        }
                    
        
        // process each field to compose the metadata, order the entered fields, and get everything tagged properly
        var metadataAttribs:String = ""
        var metadataValues:String = ""
        var enteredAttribs:String = ""
        var enteredValues:String = ""
        var composedName:String = ""
        var metaPosition:Int = 0
        var hasValueCount:Int = 0
        var importancePosition:Int = -1
        var collectorNotesPosition:Int = -1
        
        for formFieldEntry:OrgFormFieldsEntry in self.mEFP!.mFormFieldEntries! {
            if !formFieldEntry.mDuringEditing_isDeleted {
                // it is not a deleted FormField
                let rowTag:String = formFieldEntry.mFormFieldRec.rFieldProp_Col_Name_For_SV_File

                if formFieldEntry.mFormFieldRec.isMetaData()  {
                    // a metadata formfield
                    switch formFieldEntry.mFormFieldRec.rFieldProp_IDCode {
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_FORM.rawValue:
                        metadataAttribs = metadataAttribs + rowTag + "\t"
                        metadataValues = metadataValues + self.mEFP!.mFormRec!.rForm_Code_For_SV_File + "\t"
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_DATE.rawValue:
                        metadataAttribs = metadataAttribs + rowTag + "\t"
                        metadataValues = metadataValues + dateTimeStrings[0] + "\t"
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_TIME.rawValue:
                        metadataAttribs = metadataAttribs + rowTag + "\t"
                        metadataValues = metadataValues + dateTimeStrings[1] + "\t"
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_ORG.rawValue:
                        metadataAttribs = metadataAttribs + rowTag + "\t"
                        metadataValues = metadataValues + self.mEFP!.mOrgRec.rOrg_Code_For_SV_File + "\t"
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_EVENT.rawValue:
                        if (self.mEFP!.mOrgRec.rOrg_Event_Code_For_SV_File ?? "").isEmpty {
                            metadataAttribs = metadataAttribs + rowTag + "\t"
                            metadataValues = metadataValues + "\t"
                        } else {
                            metadataAttribs = metadataAttribs + rowTag + "\t"
                            metadataValues = metadataValues + self.mEFP!.mOrgRec.rOrg_Event_Code_For_SV_File! + "\t"
                        }
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_COLLECTED_BY.rawValue:
                        metadataAttribs = metadataAttribs + rowTag + "\t"
                        let nickname:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.Collector_Nickname)
                        metadataValues = metadataValues + (nickname ?? "")  + "\t"
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_LANG_USED.rawValue:
                        metadataAttribs = metadataAttribs + rowTag + "\t"
                        metadataValues = metadataValues + self.mEFP!.mShownLanguage + "\t"
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_COLLECTOR_IMPORTANCE.rawValue:
                        importancePosition = metaPosition
                        metadataAttribs = metadataAttribs + rowTag + "\t"
                        metadataValues = metadataValues + "\t"      // importance as not yet been entered
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_COLLECT_COLLECTOR_NOTES.rawValue:
                        collectorNotesPosition = metaPosition
                        metadataAttribs = metadataAttribs + rowTag + "\t"
                        metadataValues = metadataValues + "\t"      // notes have not yet been entered
                        metaPosition = metaPosition + 1
                        break
                    case FIELD_IDCODE_METADATA.NAME_FULL.rawValue:
                        let keyString:String = formFieldEntry.mFormFieldRec.rFieldProp_Col_Name_For_SV_File
                        let object = self.mEnteredDataDict![keyString]
                        if let objectString:String = object as? String {
                            composedName = objectString
                        }
                        break
                    default:
                        break
                    }
                } else {
                    // an entered formfield
                    if (formFieldEntry.mFormFieldRec.rFieldProp_Contains_Field_IDCodes?.count ?? 0) == 0 {
                        // its not a container field
                        let keyString:String = String(formFieldEntry.mFormFieldRec.rFormField_Index)
                        let object = self.mEnteredDataDict![keyString]
                        if object == nil {
                            // row was not provided any data by the end-user
                            enteredAttribs = enteredAttribs + rowTag + "\t"
                            enteredValues = enteredValues + "\t"
                        } else {
                            if let objectString:String = object as? String {
                                // row provided a value string
                                enteredAttribs = enteredAttribs + rowTag + "\t"
                                enteredValues = enteredValues + objectString + "\t"
                                if !objectString.isEmpty { hasValueCount = hasValueCount + 1 }
                            } else if let objectStringArray:Set<String> = object as? Set<String> {
                                // row provided a Set of strings
                                enteredAttribs = enteredAttribs + rowTag + "\t"
                                enteredValues = enteredValues + objectStringArray.joined(separator: ",") + "\t"
                                if objectStringArray.count > 0 { hasValueCount = hasValueCount + 1 }
                            } else if let objectStringArray:Array<String> = object as? Array<String> {
                                // row provided an Array of strings
                                enteredAttribs = enteredAttribs + rowTag + "\t"
                                enteredValues = enteredValues + objectStringArray.joined(separator: ",") + "\t"
                                if objectStringArray.count > 0 { hasValueCount = hasValueCount + 1 }
                            } else if let objectDict:[String:Any?] = object as? [String:Any?] {
                                // row provided an Array of dictionary pairs [String:Any?] though usually its [String:String]
                                for pair in objectDict {
                                    let valueString:String? = pair.value as? String
                                    if pair.key == keyString && objectDict.count == 1 {
                                        // the key is our formFieldRec index#, so assume its a container that is outputting a solo value
                                        if valueString != nil {
                                            enteredAttribs = enteredAttribs + rowTag + "\t"
                                            enteredValues = enteredValues + valueString! + "\t"
                                            if !valueString!.isEmpty { hasValueCount = hasValueCount + 1 }
                                        } else {
                                            enteredAttribs = enteredAttribs + rowTag + "\t"
                                            enteredValues = enteredValues + "\t"
                                        }
                                    } else {
                                        if valueString != nil {
                                            enteredAttribs = enteredAttribs + pair.key + "\t"
                                            enteredValues = enteredValues + valueString! + "\t"
                                            if !valueString!.isEmpty { hasValueCount = hasValueCount + 1 }
                                        } else {
                                            enteredAttribs = enteredAttribs + pair.key + "\t"
                                            enteredValues = enteredValues + "\t"
                                        }
                                    }
                                }
                            } else {
                                // row's data could not be interpreted
                                enteredAttribs = enteredAttribs + rowTag + "\t"
                                enteredValues = enteredValues + "\t"
                            }
                        }
                    }
                }
            }
        }
/*
debugPrint("\(self.mCTAG).recordSubmission METAATTRIBS   =\(metadataAttribs)")
debugPrint("\(self.mCTAG).recordSubmission METAVALUES    =\(metadataValues)")
debugPrint("\(self.mCTAG).recordSubmission ENTEREDATTRIBS=\(enteredAttribs)")
debugPrint("\(self.mCTAG).recordSubmission ENTEREDVALUES =\(enteredValues)")
debugPrint("\(self.mCTAG).recordSubmission NAME=\(composedName)")
*/

        if hasValueCount == 0 {
//debugPrint("\(self.mCTAG).recordSubmission NO DATA ENTERED - IGNORING THE SUBMISSION")
            return
        }
        
        // place the information into the database
        let ccRec:RecContactsCollected = RecContactsCollected(org_code_sv_file:self.mEFP!.mOrgRec.rOrg_Code_For_SV_File, form_code_sv_file:self.mEFP!.mFormRec!.rForm_Code_For_SV_File, dateTime:dateTimeString, status:.Stored, composed_name:composedName, meta_attribs:metadataAttribs, meta_values:metadataValues, entered_attribs:enteredAttribs, entered_values:enteredValues)
        ccRec.rCC_Importance_Position = importancePosition
        ccRec.rCC_Collector_Notes_Position = collectorNotesPosition
        do {
            _ = try ccRec.saveNewToDB()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).\(funcName)", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
}
