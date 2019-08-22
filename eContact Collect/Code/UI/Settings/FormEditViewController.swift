//
//  FormEditViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/10/18.
//

import UIKit 
import Eureka

// define the delegate protocol that other portions of the App must use to know when the FEVC saves or cancels
protocol FEVC_Delegate {
    // return wasSaved=true if saved successfully; wasSaved=false if cancelled
    func completed_FEVC(wasSaved:Bool)
}

class FormEditViewController: UIViewController {
    // caller pre-set member variables
    internal var mFEVCdelegate:FEVC_Delegate?                  // delegate callback if saved or cancelled
    public var mAction:FEVC_Actions = .Add                     // .Add or .Change
    public var mReference_orgRec:RecOrganizationDefs? = nil    // the reference OrgRec for the to-be-edited Form rec during .Change; COPY not a ref
    public var mEdit_orgFormRec:RecOrgFormDefs? = nil          // the Form record to-be-edited during .Change; will NOT be changed; COPY not a ref

    // member variables
    internal var mLocalEFP:EntryFormProvisioner? = nil                  // local EFP to drive the local OrgTitle View
    internal var mWorking_orgFormRec:RecOrgFormDefs? = nil              // edited FormRecord
    internal var mWorking_formFieldEntries:OrgFormFields? = nil         // edited FormField Records
    
    // member constants and other static content
    private let mCTAG:String = "VCSFE"
    private weak var mFormEditFormVC:FormEditFormViewController? = nil  // pointer to the containerViewController of the Form
    internal enum FEVC_Actions {
        case Add, Change
    }

    // outlets to screen controls
    @IBOutlet weak var navbar_item: UINavigationItem!
    @IBAction func button_preview_pressed(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let nextViewController:EntryViewController = storyboard.instantiateViewController(withIdentifier:"VC Entry") as! EntryViewController
        self.mLocalEFP?.mDismissing = false
        nextViewController.mEFP = self.mLocalEFP
        nextViewController.title = NSLocalizedString("PREVIEW MODE", comment:"")
        self.navigationController?.pushViewController(nextViewController, animated:true)
    }
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        // cancel button pressed; dismiss and return to the parent view controller
        if mFEVCdelegate != nil { mFEVCdelegate!.completed_FEVC(wasSaved:false) }
        self.navigationController?.popViewController(animated:true)
    }
    @IBAction func button_save_pressed(_ sender: UIBarButtonItem) {
        let msg:String = self.validateEntries()
        if (msg != "") {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: msg, buttonText: NSLocalizedString("Okay", comment:""))
        } else {
            let success:Bool = self.updateFormInDatabase()
            if success {
                if self.mFEVCdelegate != nil { self.mFEVCdelegate!.completed_FEVC(wasSaved:true) }
                self.navigationController?.popViewController(animated:true)
            }
        }
    }

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
        var orgTitleViewController:OrgTitleViewController? = nil
        self.mFormEditFormVC = nil
        for childVC in children {
            let vc1:OrgTitleViewController? = childVC as? OrgTitleViewController
            let vc2:FormEditFormViewController? = childVC as? FormEditFormViewController
            if vc1 != nil { orgTitleViewController = vc1 }
            if vc2 != nil { self.mFormEditFormVC = vc2 }
        }
        
        assert(self.mReference_orgRec != nil, "\(self.mCTAG).viewDidLoad self.mReference_orgRec == nil")    // this is a programming error
        if self.mAction == .Change {
            // its a change, so need to prepare to pre-load all the fields with the Org's existing definitions
            assert(self.mEdit_orgFormRec != nil, "\(self.mCTAG).viewDidLoad self.mEdit_orgFormRec == nil")    // this is a programming error
            if self.mWorking_orgFormRec != nil { self.mWorking_orgFormRec = nil }
            self.mWorking_orgFormRec = RecOrgFormDefs(existingRec:mEdit_orgFormRec!)   // make a copy of the existing Form rec
            self.navbar_item.title = NSLocalizedString("Edit Form", comment:"")
            self.mLocalEFP = EntryFormProvisioner(forOrgRec: self.mReference_orgRec!, forFormRec: self.mWorking_orgFormRec!)
            self.mLocalEFP!.mPreviewMode = true

            // gather the combined field information for this form in Shown order
            do {
                self.mWorking_formFieldEntries = try FieldHandler.shared.getOrgFormFields(forEFP: self.mLocalEFP!, forceLangRegion: nil, includeOptionSets: true, metaDataOnly: false, sortedBySVFileOrder: false, forEditing:true)
                self.mLocalEFP!.mFormFieldEntries = self.mWorking_formFieldEntries
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewDidLoad", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                self.mAction = .Add // auto-force to an Add
            }
        }
        if self.mAction == .Add {
            // its an add
            if self.mEdit_orgFormRec != nil { self.mEdit_orgFormRec = nil }
            if self.mWorking_orgFormRec != nil { self.mWorking_orgFormRec = nil }
            self.mWorking_orgFormRec = RecOrgFormDefs(org_code_sv_file: self.mReference_orgRec!.rOrg_Code_For_SV_File, form_code_sv_file: "")  // make am empty Form rec
            self.navbar_item.title = NSLocalizedString("Add Form", comment:"")
            self.mWorking_orgFormRec!.rForm_Override_Email_Subject = NSLocalizedString("Contacts collected from eContact Collect", comment:"do not translate the portion: eContact Collect")
            self.mLocalEFP = EntryFormProvisioner(forOrgRec: self.mReference_orgRec!, forFormRec: self.mWorking_orgFormRec!)
            self.mLocalEFP!.mPreviewMode = true

            // create a dummy Submit button meta-data entry; it will get updated into the pre-loaded ones when the Form record is created
            self.mWorking_formFieldEntries = OrgFormFields()
            do {
                let submitButtonEntries:OrgFormFields? = try FieldHandler.shared.getFieldDefsAsMatchForEditing(forFieldIDCode: FIELD_IDCODE_METADATA.SUBMIT_BUTTON.rawValue, forFormRec: self.mWorking_orgFormRec!, withOrgRec: self.mReference_orgRec!)
                if (submitButtonEntries?.count() ?? 0) > 0 {
                    self.mWorking_formFieldEntries!.appendNewDuringEditing(submitButtonEntries![0])
                    self.mLocalEFP!.mFormFieldEntries = self.mWorking_formFieldEntries!
                } else {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewDidLoad", during: "getFieldDefsAsMatchForEditing", errorMessage: "(submitButtonEntries?.count() ?? 0) == 0", extra: FIELD_IDCODE_METADATA.SUBMIT_BUTTON.rawValue)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).viewDidLoad", domain: FieldHandler.shared.mThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
                }
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewDidLoad", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
        }
        assert(self.mWorking_orgFormRec != nil, "\(self.mCTAG).viewDidLoad self.mWorking_orgFormRec == nil")    // this is a programming error
        assert(self.mWorking_formFieldEntries != nil, "\(self.mCTAG).viewDidLoad self.mWorking_formFieldEntries == nil")    // this is a programming error
        
        // setup a local EFP for the OrgTitle VC and for Preview Mode
        assert(orgTitleViewController != nil, "\(self.mCTAG).viewDidLoad orgTitleViewController == nil")    // this is a programming error
        orgTitleViewController!.mEFP = self.mLocalEFP!
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // reset the NavBar's color scheme as it may have been changed by the Preview Mode Entry View Controller
        self.navigationController!.navigationBar.barTintColor = nil
        self.navigationController!.navigationBar.tintColor = nil
    }
    
    // called by the framework when the view has fully appeared
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)
        
        // reset the dismissing flag in the EFP as a Preview Mode may have used it during its dismissal process
        self.mLocalEFP?.mDismissing = false
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            self.mLocalEFP?.mDismissing = true
        }
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
            self.mLocalEFP?.mDismissing = true
            self.mWorking_orgFormRec = nil
            self.mWorking_formFieldEntries?.removeAll()
            self.mWorking_formFieldEntries = nil
            self.mLocalEFP?.clear()
            self.mFormEditFormVC?.clearVC()
            self.mLocalEFP = nil
            self.mReference_orgRec = nil
            self.mEdit_orgFormRec = nil
            self.mFormEditFormVC = nil
            self.mFEVCdelegate = nil
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
    
    ///////////////////////////////////////////////////////////////////
    // Data entry validation and saves to database
    ///////////////////////////////////////////////////////////////////
    
    // validate entries
    // return "" if all validations passed, else an error message about what validation failed
    private func validateEntries() -> String {
        let result:String = self.mFormEditFormVC!.finalizeEverything()
        if !result.isEmpty { return result }
        
        // need to ensure this Form name does not already exist in the database
        if self.mAction == .Add {
            var orgFormRec:RecOrgFormDefs?
            do {
                orgFormRec = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName: self.mWorking_orgFormRec!.rForm_Code_For_SV_File, forOrgShortName: self.mReference_orgRec!.rOrg_Code_For_SV_File)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).validateEntries", errorStruct: error, extra: nil)
                return NSLocalizedString("Database error occurred while verifying inputs", comment:"")
            }
            if orgFormRec != nil {
                return NSLocalizedString("Form short name already exists in the database", comment:"") }
        }
        return ""
    }
    
    // update or add the entire form definition (including a FormFields et al) into the database;
    // return true if successful or false if failed
    private func updateFormInDatabase() -> Bool {
        // Stage 1: save or update the RecOrgFormDefs first
        switch self.mAction {
        case .Change:
            // update an existing RecOrgFormDefs
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.Form STARTED")
            if self.mWorking_orgFormRec!.rForm_Code_For_SV_File == self.mWorking_orgFormRec!.rForm_Code_For_SV_File {
                // the key has not been changed
                do {
                    _ = try self.mWorking_orgFormRec!.saveChangesToDB(originalFormRec: self.mWorking_orgFormRec!)
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).updateFormInDatabase", errorStruct: error, extra: nil)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    return false
                }
            } else {
                // ?? the key has been changed; presently not supported
                return false
            }
            break
            
        case .Add:
            // add an new RecOrgFormDefs; note this also auto-adds all the default metadata FormField records to the database
//debugPrint("\(self.mCTAG).updateFormInDatabase.Add.Form STARTED")
            self.mWorking_orgFormRec!.rOrg_Code_For_SV_File = self.mReference_orgRec!.rOrg_Code_For_SV_File
            do {
                _ = try self.mWorking_orgFormRec!.saveNewToDB(withOrgRec: self.mReference_orgRec!)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).updateFormInDatabase", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                return false
            }
            break
        }
        
        // Stage 2: update the meta-data RecOrgFormFieldDefs and RecOrgFormFieldLocales;
        // note: for a new form, the meta-data fields in mvs_fields are not yet connected to those pre-added into the database
        // for most meta-data records, there is only one RecOrgFormFieldLocales;
        // however the SUbmit button meta-data could include several RecOrgFormFieldLocales;
        // meta-data fields do have a sort-order that is important, but assigned sort#s has been pre-handled by the meta-data editor form
        switch self.mAction {
        case .Change:
            // update all the pre-loaded and potentiall revised meta-data RecOrgFormFieldDefs and RecOrgFormFieldLocales;
            // the RecOrgFormFieldLocales are most likely in Composited state
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.Metadata STARTED")
            for formFieldEntry in self.mWorking_formFieldEntries! {
                if formFieldEntry.mFormFieldRec.isMetaData()  {
                    do {
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.Metadata Changing \(formFieldEntry.mFormFieldRec.rFieldProp_IDCode)")
                        formFieldEntry.mFormFieldRec.rForm_Code_For_SV_File = self.mWorking_orgFormRec!.rForm_Code_For_SV_File
                        let _ = try formFieldEntry.mFormFieldRec.saveChangesToDB(originalRec: formFieldEntry.mFormFieldRec)     // this will auto-save any retained and modified RecOrgFormFieldLocales
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).updateFormInDatabase", errorStruct: error, extra: nil)
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                        return false
                    }
                }
            }
            break
        
        case .Add:
            // there should be only a few RecOrgFormFieldDefs and RecOrgFormFieldLocales in mWorking_formFieldRecMatches during an add;
            // usually just the Submit button meta-data entry; however a complete set of default meta-data records are now in the database
            // and are not sync-ed to these placeholder records in mWorking_formFieldRecMatches; there are no duplicate field IDCodes in the meta-data
//debugPrint("\(self.mCTAG).updateFormInDatabase.Add.ReviseMetadata STARTED")
            // first get a new set of matches from the database for only the metadata
            do {
                let metadataFormFieldEntries:OrgFormFields = try FieldHandler.shared.getOrgFormFields(forEFP: self.mLocalEFP!, forceLangRegion: nil, includeOptionSets: false, metaDataOnly: true, sortedBySVFileOrder: true, forEditing:true)
                for metadataFormFieldEntry in metadataFormFieldEntries {
                    let updaterIndex = self.mWorking_formFieldEntries!.findIndex(ofFieldIDCode: metadataFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)
                    if updaterIndex >= 0 {
                        // found an updater for this meta-data entry;
                        // there may be one or more new or edited RecOrgFormFieldLocales for this meta-data entry
                        let updateFormFieldEntry = self.mWorking_formFieldEntries![updaterIndex]
//debugPrint("\(self.mCTAG).updateFormInDatabase.Add.ReviseMetadata Revising locale recs for \(metadataFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)")
                        metadataFormFieldEntry.mFormFieldRec.rFieldProp_Col_Name_For_SV_File = updateFormFieldEntry.mFormFieldRec.rFieldProp_Col_Name_For_SV_File
                        metadataFormFieldEntry.mFormFieldRec.rFieldProp_Options_Code_For_SV_File = updateFormFieldEntry.mFormFieldRec.rFieldProp_Options_Code_For_SV_File
                        if (updateFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs?.count ?? 0) > 0 {
                            if metadataFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs == nil { metadataFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs = [] }
                            for updaterFormFieldLocRec in updateFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs! {
                                var found:Bool = false
                                for metadataFormFieldLocRec in metadataFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs! {
                                    if updaterFormFieldLocRec.rFormFieldLoc_LangRegionCode == metadataFormFieldLocRec.rFormFieldLoc_LangRegionCode {
                                        
                                        metadataFormFieldLocRec.rFieldLocProp_Name_Shown = updaterFormFieldLocRec.rFieldLocProp_Name_Shown
                                        metadataFormFieldLocRec.rFieldLocProp_Options_Name_Shown = updaterFormFieldLocRec.rFieldLocProp_Options_Name_Shown
                                        metadataFormFieldLocRec.rFieldLocProp_Metadatas_Name_Shown = updaterFormFieldLocRec.rFieldLocProp_Metadatas_Name_Shown
                                        metadataFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
                                        found = true
                                        break
                                    }
                                }
                                if !found {
                                    // these might not have been pre-set during Editing
                                    updaterFormFieldLocRec.rFormField_Index = metadataFormFieldEntry.mFormFieldRec.rFormField_Index
                                    updaterFormFieldLocRec.rForm_Code_For_SV_File = metadataFormFieldEntry.mFormFieldRec.rForm_Code_For_SV_File
                                    updaterFormFieldLocRec.rOrg_Code_For_SV_File = metadataFormFieldEntry.mFormFieldRec.rOrg_Code_For_SV_File
                                    metadataFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs!.append(updaterFormFieldLocRec)
                                    metadataFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
                                }
                            }
                        }
                        let _ = try metadataFormFieldEntry.mFormFieldRec.saveChangesToDB(originalRec: metadataFormFieldEntry.mFormFieldRec) // will also update all stored RecOrgFormFieldLocales
                    }
                }
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).updateFormInDatabase", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                return false
            }
            break
        }
        
        // Stage 3: now finally adjust all the form's data-entry RecOrgFormFieldDefs and RecOrgFormFieldLocales;
        let mvs_fields = self.mFormEditFormVC!.form.sectionBy(tag: "mvs_fields")
        switch self.mAction {
        case .Add:
            // just adding new records; database does not have existing of these records;
            // go though the on-screen fields, adding only those shown (any temporary deleted records in self.mWorking_formFieldRecMatches
            // will be automatically ignored
//debugPrint("\(self.mCTAG).updateFormInDatabase.Add.DataEntryFields STARTED")
            for inx in 0...mvs_fields!.endIndex - 1 {
                let row = mvs_fields![inx]
                if row.tag!.starts(with: "FF,") {
                    let ff_index = Int64(row.tag!.components(separatedBy: ",")[1])
                    let adderIndex = self.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: ff_index!)
                    if adderIndex >= 0 {
                        let adderFormFieldEntry:OrgFormFieldsEntry = self.mWorking_formFieldEntries![adderIndex]
                        if !adderFormFieldEntry.mDuringEditing_isDeleted {
                            do {
//debugPrint("\(self.mCTAG).updateFormInDatabase.Add.DataEntryFields Adding \(adderFormFieldEntry.mFormFieldRec.rFormField_Index) as \(adderFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)")
                                let temporaryFFIndex = adderFormFieldEntry.mFormFieldRec.rFormField_Index
                                adderFormFieldEntry.mFormFieldRec.rFormField_Index = -1
                                adderFormFieldEntry.mFormFieldRec.rForm_Code_For_SV_File = self.mWorking_orgFormRec!.rForm_Code_For_SV_File
                                adderFormFieldEntry.mFormFieldRec.rFormField_Order_Shown = (inx + 1) * 10
                                let _ = try adderFormFieldEntry.mFormFieldRec.saveNewToDB()    // this will auto-save any retained and modified RecOrgFormFieldLocales
                                                                
                                // also load new field definitions for any subfields; the end-user may have added or deleted subfields
                                if adderFormFieldEntry.mFormFieldRec.hasSubFormFields() {
                                    var subcount = adderFormFieldEntry.mFormFieldRec.rFormField_Order_Shown + 1
                                    for subFormFieldEntry in self.mWorking_formFieldEntries! {
                                        if !subFormFieldEntry.mDuringEditing_isDeleted && !subFormFieldEntry.mFormFieldRec.isMetaData() {
                                            if subFormFieldEntry.mFormFieldRec.rFormField_SubField_Within_FormField_Index == temporaryFFIndex {
                                                // found a sub-field to add
//debugPrint("\(self.mCTAG).updateFormInDatabase.Add.DataEntryFields Adding Subfield \(subFormFieldEntry.mFormFieldRec.rFormField_Index) as \(subFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)")
                                                subFormFieldEntry.mFormFieldRec.rFormField_Index = -1
                                                subFormFieldEntry.mFormFieldRec.rForm_Code_For_SV_File = self.mWorking_orgFormRec!.rForm_Code_For_SV_File
                                                subFormFieldEntry.mFormFieldRec.rFormField_SubField_Within_FormField_Index = adderFormFieldEntry.mFormFieldRec.rFormField_Index
                                                subFormFieldEntry.mFormFieldRec.rFormField_Order_Shown = subcount
                                                let _ = try subFormFieldEntry.mFormFieldRec.saveNewToDB()   // this will auto-save any retained and modified RecOrgFormFieldLocales
                                                subcount = subcount + 1
                                            }
                                        }
                                    }
                                }
                            } catch {
                                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).updateFormInDatabase", errorStruct: error, extra: nil)
                                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                                return false
                            }
                        }
                    }
                }
            }
            break
        
        case .Change:
            // most complex stage as not only are we changing existing records, we may also be deleting records, and adding new records;
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields STARTED")
            for formFieldEntry:OrgFormFieldsEntry in self.mWorking_formFieldEntries! {
                do {
                    if formFieldEntry.mDuringEditing_isDeleted {
                        // this entry is marked as deleted
                        if formFieldEntry.mFormFieldRec.rFormField_Index >= 0 {
                            // and it exists in the database
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields.Delete.A \(formFieldEntry.mFormFieldRec.rFormField_Index)")
                            let _ = try formFieldEntry.mFormFieldRec.deleteFromDB() // any associated RecOrgFormFieldLocales and sub RecOrgFormFieldDefs are also deleted
                        }
                    } else if formFieldEntry.mFormFieldRec.isMetaData()  {
                        // meta-data entry; ignored since already handled in stage 2
                    } else if formFieldEntry.mFormFieldRec.isSubFormField() {
                        // its a subfield of some container field; it will not be listed-on screen; ignore it for the moment
                    } else if mvs_fields == nil || mvs_fields?.count == 0 {
                        // all entry fields were deleted by the end-user, so delete this one
                        if formFieldEntry.mFormFieldRec.rFormField_Index >= 0 {
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields.Delete.B \(formFieldEntry.mFormFieldRec.rFormField_Index)")
                            let _ = try formFieldEntry.mFormFieldRec.deleteFromDB() // any associated RecOrgFormFieldLocales and sub RecOrgFormFieldDefs are also deleted
                        }
                    } else {
                        // locate this form field in the working set on-screen
                        var found:Bool = false
                        for inx in 0...mvs_fields!.endIndex - 1 {
                            let row = mvs_fields![inx]
                            if row.tag!.starts(with: "FF,") {
                                let ff_index = Int64(row.tag!.components(separatedBy: ",")[1])
                                if formFieldEntry.mFormFieldRec.rFormField_Index == ff_index {
                                    // found it; revise to the new sequential order shown; primary fields are incremented in decades to all
                                    // for "insertion" of their subfields into proper ordering "inside" their decade
                                    formFieldEntry.mFormFieldRec.rFormField_Order_Shown = (inx + 1) * 10
                                    found = true
                                    break
                                }
                            }
                        }
                        if !found {
                            // the entry field was removed on-screen, so delete it
                            if formFieldEntry.mFormFieldRec.rFormField_Index >= 0 {
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields.Delete.C \(formFieldEntry.mFormFieldRec.rFormField_Index)")
                                let _ = try formFieldEntry.mFormFieldRec.deleteFromDB() // any associated RecOrgFormFieldLocales and sub RecOrgFormFieldDefs are also deleted
                            }
                        } else if formFieldEntry.mFormFieldRec.rFormField_Index < 0 {
                            // the entry field is new and remains on-screen, so add it plus its subfields if any
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields.Add \(formFieldEntry.mFormFieldRec.rFormField_Index) as \(formFieldEntry.mFormFieldRec.rFieldProp_IDCode)")
                            let temporaryFFIndex = formFieldEntry.mFormFieldRec.rFormField_Index
                            formFieldEntry.mFormFieldRec.rFormField_Index = -1
                            formFieldEntry.mFormFieldRec.rForm_Code_For_SV_File = self.mWorking_orgFormRec!.rForm_Code_For_SV_File
                            let _ = try formFieldEntry.mFormFieldRec.saveNewToDB()  // this will auto-save any retained and modified RecOrgFormFieldLocales
                            
                            // also load then new field definitions for any subfields; the end-user may have added or deleted subfields
                            if formFieldEntry.mFormFieldRec.hasSubFormFields() {
                                var subcount = formFieldEntry.mFormFieldRec.rFormField_Order_Shown + 1
                                for subFormFieldEntry in self.mWorking_formFieldEntries! {
                                    if !subFormFieldEntry.mDuringEditing_isDeleted && !subFormFieldEntry.mFormFieldRec.isMetaData() {
                                        if subFormFieldEntry.mFormFieldRec.rFormField_SubField_Within_FormField_Index == temporaryFFIndex {
                                            // found a sub-field to add
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields.Add Adding Subfield \(subFormFieldEntry.mFormFieldRec.rFormField_Index) as \(subFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)")
                                            subFormFieldEntry.mFormFieldRec.rFormField_Index = -1
                                            subFormFieldEntry.mFormFieldRec.rForm_Code_For_SV_File = self.mWorking_orgFormRec!.rForm_Code_For_SV_File
                                            subFormFieldEntry.mFormFieldRec.rFormField_SubField_Within_FormField_Index = formFieldEntry.mFormFieldRec.rFormField_Index
                                            subFormFieldEntry.mFormFieldRec.rFormField_Order_Shown = subcount
                                            let _ = try subFormFieldEntry.mFormFieldRec.saveNewToDB()    // this will auto-save any retained and modified RecOrgFormFieldLocales
                                            subcount = subcount + 1
                                        }
                                    }
                                }
                            }
                        } else {
                            // the entry field pre-exists in the database and remains on-screen; update it
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryField Changing \(formFieldEntry.mFormFieldRec.rFormField_Index) as \(formFieldEntry.mFormFieldRec.rFormField_Order_Shown)")
                            _ = try formFieldEntry.mFormFieldRec.saveChangesToDB(originalRec: formFieldEntry.mFormFieldRec)     // this will auto-save any retained and modified RecOrgFormFieldLocales
                            
                            // now deal with its subfield's if-any; the end-user may have added, deleted, or changed any of them
                            if formFieldEntry.mFormFieldRec.hasSubFormFields() {
                                var subcount = formFieldEntry.mFormFieldRec.rFormField_Order_Shown + 1
                                for subFormFieldEntry in self.mWorking_formFieldEntries! {
                                    if subFormFieldEntry.mFormFieldRec.rFormField_SubField_Within_FormField_Index == formFieldEntry.mFormFieldRec.rFormField_Index {
                                        // found a sub-field to add or change or delete
                                        if subFormFieldEntry.mDuringEditing_isDeleted {
                                            // this subfield is marked as needing deletion
                                            if subFormFieldEntry.mFormFieldRec.rFormField_Index >= 0 {
                                                // and it exists in the database
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields.Change Deleting Subfield \(subFormFieldEntry.mFormFieldRec.rFormField_Index)")
                                                let _ = try subFormFieldEntry.mFormFieldRec.deleteFromDB() // any associated RecOrgFormFieldLocales are also deleted
                                            }
                                        } else if subFormFieldEntry.mFormFieldRec.rFormField_Index < 0 {
                                            // this subfield is an add
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields.Change Adding Subfield \(subFormFieldEntry.mFormFieldRec.rFormField_Index) as \(subFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)")
                                            subFormFieldEntry.mFormFieldRec.rFormField_Index = -1
                                            subFormFieldEntry.mFormFieldRec.rForm_Code_For_SV_File = self.mWorking_orgFormRec!.rForm_Code_For_SV_File
                                            subFormFieldEntry.mFormFieldRec.rFormField_SubField_Within_FormField_Index = formFieldEntry.mFormFieldRec.rFormField_Index
                                            subFormFieldEntry.mFormFieldRec.rFormField_Order_Shown = subcount
                                            let _ = try subFormFieldEntry.mFormFieldRec.saveNewToDB()    // this will auto-save any retained and modified RecOrgFormFieldLocales
                                            subcount = subcount + 1
                                        } else {
                                            // the subfield is a change
//debugPrint("\(self.mCTAG).updateFormInDatabase.Change.DataEntryFields.Change Changing Subfield \(subFormFieldEntry.mFormFieldRec.rFormField_Index) as \(subFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)")
                                            subFormFieldEntry.mFormFieldRec.rFormField_Order_Shown = subcount
                                            subcount = subcount + 1
                                            _ = try subFormFieldEntry.mFormFieldRec.saveChangesToDB(originalRec: subFormFieldEntry.mFormFieldRec)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).updateFormInDatabase", errorStruct: error, extra: nil)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    return false
                }
            }
            break
        }

        
        // check the App's currents
        (UIApplication.shared.delegate as! AppDelegate).checkCurrentForm(withFormRec: self.mWorking_orgFormRec!)
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Child FormViewController
/////////////////////////////////////////////////////////////////////////

class FormEditFormViewController: FormViewController {
    // member variables
    private var mFirstTime:Bool = true
    private var mMovesInProcess:Int = 0
    private var mLangsMode:String = "All Languages"
    private var mLang1:String = ""
    private var mLang2:String = ""
    private weak var mMVS_fields:MultivaluedSection? = nil
    private var mMVS_fields_splitRow:SplitRow<PushRow<String>, ButtonRow>? = nil
    private weak var mSubmitButtonSection:Section? = nil

    // member constants and other static content
    private let mCTAG:String = "VCSFEF"
    private weak var mFormEditVC:FormEditViewController? = nil

    private let SVFileModeStrings:[String] = [NSLocalizedString("Text file, rows Tab separated", comment:""),
                                             NSLocalizedString("Text file, rows Comma separated", comment:""),
                                             NSLocalizedString("Text file, rows Semicolon separated", comment:""),
                                             NSLocalizedString("XML file, rows Attrib/Value Pairs", comment:"")]
    private func svFileModeInt(fromString:String) -> Int {
        switch fromString {
        case SVFileModeStrings[0]: return 0
        case SVFileModeStrings[1]: return 1
        case SVFileModeStrings[2]: return 2
        case SVFileModeStrings[3]: return 3
        default: return 0
        }
    }
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // build the form but without content values;
        // self.parent is not set until viewWillAppear()
        self.buildForm()
        
        // set overall form options
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will re-appear
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)

        // locate our parent view controller; must be done in viewWillAppear() rather than viewDidLoad()
        self.mFormEditVC = (self.parent as! FormEditViewController)
        
        // extract the languages
        if self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions != nil {
            if self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions!.count >= 1 {
                self.mLang1 = self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![0]
            }
            if self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions!.count >= 2 {
                self.mLang2 = self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![1]
            }
        }

        // set the form's values
        tableView.setEditing(true, animated: false) // this must be done in viewWillAppear() is within a ContainerView and using .Reorder MultivaluedSections
        self.revalueForm()
        self.mFirstTime = false
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // do any finalizations drawing from what is shown on the Form before save into the database
    public func finalizeEverything() -> String {
        let validationError = form.validate()
        if validationError.count > 0 {
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            return message
        }
        
        // safety double-checks
        if self.mFormEditVC!.mWorking_orgFormRec!.rForm_Code_For_SV_File.isEmpty {
            return NSLocalizedString("Form short name cannot be blank", comment:"")
        }
        if self.mFormEditVC!.mWorking_orgFormRec!.rForm_Code_For_SV_File.rangeOfCharacter(from: AppDelegate.mAcceptableNameChars.inverted) != nil {
            return NSLocalizedString("Form short name can only contain letters, digits, space, or _ . + -", comment:"")
        }

        let cnt:Int = (self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions?.count ?? 0)
        if self.mLangsMode == "All Languages" {
            self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions = nil
        } else if self.mLangsMode == "One Language" {
            if cnt < 1 { return NSLocalizedString("Must choose one language", comment:"") }
            if self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![0].isEmpty { return NSLocalizedString("Must choose one language", comment:"") }
            self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions = [self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![0]]
        } else {
            if cnt < 2 { return NSLocalizedString("Must choose two languages", comment:"") }
            if self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![0].isEmpty { return NSLocalizedString("Must choose two languages", comment:"") }
            if self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![1].isEmpty { return NSLocalizedString("Must choose two languages", comment:"") }
        }
        self.mFormEditVC!.mLocalEFP!.reassess()
        return ""
    }
    
    // clear out the Form so it will be deinit
    public func clearVC() {
        form.removeAll()
        tableView.reloadData()
        self.mMVS_fields_splitRow = nil
        self.mMVS_fields = nil
        self.mSubmitButtonSection = nil
        self.mFormEditVC = nil
    }

    // build the form
    // CANNOT utilize self.mFormEditVC at this stage
    // WARNING: must not rebuild the form as this breaks the MultivaluedSection PushRow return:
    //          self.viewWillAppear() and self.viewDidAppear() WILL be invoked upon return from the PushRow's view controller
    private func buildForm() {
        let section1 = Section(NSLocalizedString("Form's Settings", comment:""))
        form +++ section1
        section1 <<< TextRow() {
            $0.tag = "form_short_name"
            $0.title = NSLocalizedString("Short Form Code", comment:"")
            $0.add(rule: RuleRequired(msg: NSLocalizedString("Form short name cannot be blank", comment:"")))
            $0.add(rule: RuleValidChars(acceptableChars: AppDelegate.mAcceptableNameChars, msg: NSLocalizedString("Form short name can only contain letters, digits, space, or _ . + -", comment:"")))
            $0.validationOptions = .validatesAlways
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { [weak self] chgRow in
                let _ = chgRow.validate()
                if chgRow.isValid {
                    if chgRow.value != nil {
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Code_For_SV_File = chgRow.value!
                    }
                }
        }
        section1 <<< SwitchRow("emailSwitchRowTag") {
            $0.title = NSLocalizedString("Override Org's email settings?", comment:"")
        }
        section1 <<< TextAreaRow() {
            $0.tag = "override_email_info"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 70.0)
            $0.disabled = true
            $0.hidden = Condition.function(["emailSwitchRowTag"], { form in
                return !((form.rowBy(tag: "emailSwitchRowTag") as? SwitchRow)?.value ?? false)
            })
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 14.0)
                cell.textView.textColor = UIColor.black
        }
        section1 <<< EmailRow() {
            $0.tag = "override_email_to"
            $0.title = NSLocalizedString("Email TO", comment:"")
            $0.hidden = Condition.function(["emailSwitchRowTag"], { form in
                return !((form.rowBy(tag: "emailSwitchRowTag") as? SwitchRow)?.value ?? false)
            })
            }.cellUpdate { cell, row in
                cell.textField.font = .systemFont(ofSize: 14.0)
            }.onChange { [weak self] chgRow in
                self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Override_Email_To = chgRow.value
        }
        section1 <<< EmailRow() {
            $0.tag = "override_email_cc"
            $0.title = NSLocalizedString("Email CC", comment:"")
            $0.hidden = Condition.function(["emailSwitchRowTag"], { form in
                return !((form.rowBy(tag: "emailSwitchRowTag") as? SwitchRow)?.value ?? false)
            })
            }.cellUpdate { cell, row in
                cell.textField.font = .systemFont(ofSize: 14.0)
            }.onChange { [weak self] chgRow in
                self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Override_Email_CC = chgRow.value
        }
        section1 <<< TextRow() {
            $0.tag = "override_email_subject"
            $0.title = NSLocalizedString("Subject", comment:"")
            $0.hidden = Condition.function(["emailSwitchRowTag"], { form in
                return !((form.rowBy(tag: "emailSwitchRowTag") as? SwitchRow)?.value ?? false)
            })
            }.cellUpdate { cell, row in
                cell.textField.font = .systemFont(ofSize: 14.0)
            }.onChange { [weak self] chgRow in
                self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Override_Email_Subject = chgRow.value
        }
        
        section1 <<< SegmentedRowExt<String>("form_langs_mode"){
            $0.title = "Languages Mode"
            $0.options = ["One Language","Bilingual","All Languages"]
            $0.value = Set([self.mLangsMode])
            $0.hidden = true
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mLangsMode = chgRow.value!.first!
                    switch self!.mLangsMode {
                    case "Bilingual":
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions = [self!.mLang1,self!.mLang2]
                        self!.mFormEditVC!.mLocalEFP!.reassess()
                        break
                    case "One Language":
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions = [self!.mLang1]
                        self!.mFormEditVC!.mLocalEFP!.reassess()
                        break
                    default:
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions = nil
                        self!.mFormEditVC!.mLocalEFP!.reassess()
                        break
                    }
                }
        }
        section1 <<< SegmentedRowExt<String>(){
            $0.tag = "form_langs_only_1"
            $0.title = "Shown Language"
            $0.hidden = Condition.function(["form_langs_mode"], { form in
                if let val:Set<String> = (form.rowBy(tag: "form_langs_mode") as! SegmentedRowExt<String>).value {
                    if val.first != "One Language" { return true }
                }
                return false
            })
            $0.displayValueFor = { set in
                    if set == nil { return nil }
                    return set!.map { (Locale.current.localizedString(forLanguageCode: $0) ?? "") + " (\($0))" }.joined(separator: ", ")
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mLang1 = chgRow.value!.first!
                    if (self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions?.count ?? 0) == 0 {
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions = [self!.mLang1]
                    } else {
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![0] = self!.mLang1
                    }
                    self!.mFormEditVC!.mLocalEFP!.reassess()
                }
        }
        section1 <<< SegmentedRowExt<String>(){
            $0.tag = "form_langs_bi_first"
            $0.title = "Upper Shown Language"
            $0.hidden = Condition.function(["form_langs_mode"], { form in
                if let val:Set<String> = (form.rowBy(tag: "form_langs_mode") as! SegmentedRowExt<String>).value {
                    if val.first != "Bilingual" { return true }
                }
                return false
            })
            $0.displayValueFor = { set in
                    if set == nil { return nil }
                    return set!.map { (Locale.current.localizedString(forLanguageCode: $0) ?? "") + " (\($0))" }.joined(separator: ", ")
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mLang1 = chgRow.value!.first!
                    if (self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions?.count ?? 0) == 0 {
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions = [self!.mLang1]
                    } else {
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![0] = self!.mLang1
                    }
                    self!.mFormEditVC!.mLocalEFP!.reassess()
                }
        }
        section1 <<< SegmentedRowExt<String>(){
            $0.tag = "form_langs_bi_second"
            $0.title = "Lower Shown Language"
            $0.hidden = Condition.function(["form_langs_mode"], { form in
                if let val:Set<String> = (form.rowBy(tag: "form_langs_mode") as! SegmentedRowExt<String>).value {
                    if val.first != "Bilingual" { return true }
                }
                return false
            })
            $0.displayValueFor = { set in
                    if set == nil { return nil }
                    return set!.map { (Locale.current.localizedString(forLanguageCode: $0) ?? "") + " (\($0))" }.joined(separator: ", ")
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mLang2 = chgRow.value!.first!
                    let cnt:Int = (self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions?.count ?? 0)
                    if cnt == 0 {
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions = [self!.mLang1,self!.mLang2]
                    } else if cnt == 1 {
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions!.append(self!.mLang2)
                    } else {
                        self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![1] = self!.mLang2
                    }
                    self!.mFormEditVC!.mLocalEFP!.reassess()
                }
        }
        
        // create a SplitRow to be used add the AddButtonProvider
        self.mMVS_fields_splitRow = SplitRow<PushRow<String>, ButtonRow>() {
            $0.tag = "split_add_button"
            $0.subscribeOnChangeLeft = false
            $0.subscribeOnChangeRight = false
            $0.rowLeft = PushRow<String>() { subRow in
                // !!! MMM use of PushRow is an extension to the Eureka code
                // REMEMBER: CANNOT do a buildForm() from viewWillAppear() ... the form must remain intact for this to work
                // must buildForm() from viewDidLoad() then populate field values separately
                subRow.title = NSLocalizedString("Select new field to add", comment:"")
                subRow.tag = "add_new_field"
                subRow.selectorTitle = NSLocalizedString("Choose one", comment:"")
                subRow.options = ["Field-1"]   // temporary placeholder; will be populated in .onPresent()
                }.cellUpdate { updCell, updRow in
                    updCell.textLabel?.textColor = UIColor(hex6: 0x007AFF)
                    updCell.imageView?.image = #imageLiteral(resourceName: "Add")
                }.onPresent { [weak self] sourceFVC, presentVC in
                    // callback to tap into PushRow's _SelectorViewController such that the ListCheckRows can be configured
                    let pRow:PushRow<String> = self!.mMVS_fields_splitRow!.rowLeft!
                    do {
                        let (controlPairs, sectionMap, sectionTitles) = try FieldHandler.shared.getAllAvailFieldIDCodes(withOrgRec: self!.mFormEditVC!.mReference_orgRec!)
                        pRow.options = controlPairs.map { $0.valueString }
                        pRow.retainedObject = (controlPairs, sectionMap, sectionTitles)
                        presentVC.selectableRowSetup = { listRow in
                            listRow.cellStyle = UITableViewCell.CellStyle.subtitle
                        }
                        presentVC.sectionKeyForValue = { oTitleShown in
                            return sectionMap[oTitleShown] ?? ""
                        }
                        presentVC.sectionHeaderTitleForKey = { sKey in
                            return sectionTitles[sKey]
                        }
                        //presentVC.selectableRowCellUpdate = { cell, row in
                        //    cell.detailTextLabel?.text = ??
                        //}
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).buildForm.MultivaluedSection.FormFields.SplitRow.PushRow.onPresent", errorStruct: error, extra: nil)
                        AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    }
                }.onChange { [weak self] chgRow in
                    // PushRow has returned a value selected from the PushRow's view controller;
                    // note our context is still within the PushRow's view controller, not the original FormViewController
                    if chgRow.value != nil {   // this must be present to prevent an infinite loop
                        guard let tableView = chgRow.cell.formViewController()?.tableView else { return }
                        guard let indexPath = self!.mMVS_fields_splitRow!.indexPath else { return }
                        self!.mMVS_fields_splitRow!.whichSelected = .leftSelected
                        DispatchQueue.main.async {
                            // must dispatch this so the PushRow's SelectorViewController is dismissed first and the UI is back at the main FormViewController
                            // this triggers multivaluedRowToInsertAt() below
                            chgRow.cell.formViewController()?.tableView(tableView, commit: .insert, forRowAt: indexPath)
                        }
                    }
            }
            $0.rowRight = ButtonRow() { subRow in
                subRow.tag = "insert_new_field"
                subRow.title = NSLocalizedString("or Add & Paste", comment:"")
                }.cellUpdate { updCell, updRrow in
                    updCell.backgroundColor = UIColor.lightGray
                    updCell.textLabel?.textColor = UIColor(hex6: 0x007AFF)
                }.onCellSelection { [weak self] selCell, selRow in
                    if FieldHandler.shared.mFormFieldClipboard == nil { return }
                    if FieldHandler.shared.mFormFieldClipboard!.mFrom_FormFields.countPrimary() == 1 {
                        // just one primary formfield was copied, so do a normal MVS insert
                        guard let tableView = selCell.formViewController()?.tableView else { return }
                        guard let indexPath = self!.mMVS_fields_splitRow!.indexPath else { return }
                        self!.mMVS_fields_splitRow!.whichSelected = .rightSelected
                        selCell.formViewController()?.tableView(tableView, commit: .insert, forRowAt: indexPath)
                    } else {
                        // multiple primary formfields are present, so must insert in-bulk and reload the Fields MVS
                        // ?? !! FUTURE feature
                    }
            }
            if FieldHandler.shared.mFormFieldClipboard != nil {
                $0.rowLeftPercentage = 0.6
                $0.rowLeft!.title = NSLocalizedString("Select new", comment:"")
            } else {
                $0.rowLeftPercentage = 0.99
                $0.rowLeft!.title = NSLocalizedString("Select new field to add", comment:"")
            }
        }
        
        /*  NOTE: in order to utilize the SplitRow instead of the ButtonRow, three lines in the Eureka Core's Section.swift file had to be changed;
                  the existing functionality using the ButtonRow remains intact
            in Section.swift in class MultivaluedSection:
                change: public var addButtonProvider: ((MultivaluedSection) -> ButtonRow) = { _ in
                to:     public var addButtonProvider: ((MultivaluedSection) -> BaseRow) = { _ in
            in Section.swift in class MultivaluedSection in function initialize()
                change the code block as shown by adding the if statement and changing the function source class:
                    if let buttonRowAdd = addRow as? ButtonRow {
                        buttonRowAdd.onCellSelection { cell, row in
                            guard let tableView = cell.formViewController()?.tableView, let indexPath = row.indexPath else { return }
                            cell.formViewController()?.tableView(tableView, commit: .insert, forRowAt: indexPath)
                        }
                    }
         */
        let mvs_fields = MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder],
            header: NSLocalizedString("Form's Fields and Sections in order to-be-shown", comment:"")) { mvSection in
            mvSection.tag = "mvs_fields"
            mvSection.showInsertIconInAddButton = false
            mvSection.addButtonProvider = { section in
                return self.mMVS_fields_splitRow! }
            mvSection.multivaluedRowToInsertAt = { [weak self] index in
                // an add or and add+paste was selected; must return a row
                switch self!.mMVS_fields_splitRow!.whichSelected {
                case .leftSelected:
                    // a new Field_IDCode was chosen by the end-user;
                    // get the collector-name of the field from the popup then translate it back to a proper FieldIDCode
                    let fromPushRow = self!.mMVS_fields_splitRow!.rowLeft!
                    let fieldNameForCollector:String? = fromPushRow.value!
                    var fieldIDCode:String? = nil
                    do {
                        let (controlPairs, _, _) = try FieldHandler.shared.getAllAvailFieldIDCodes(withOrgRec: self!.mFormEditVC!.mReference_orgRec!)
                        fieldIDCode = CodePair.findCode(pairs: controlPairs, givenValue: fieldNameForCollector!)
                    } catch {
                        // some type of filesystem error occurred; should not happen
                        AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).buildForm.MultivaluedSection.FormFields.multivaluedRowToInsertAt.left", errorStruct: error, extra: fieldNameForCollector)
                        AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                        // cannot throw or return from here
                    }
                    
                    // load the default configuration of the selected formFields and its subfields (if any)
                    var newFormFieldEntries:OrgFormFields? = nil
                    if !(fieldIDCode ?? "").isEmpty {
                        do {
                            newFormFieldEntries = try FieldHandler.shared.getFieldDefsAsMatchForEditing(forFieldIDCode: fieldIDCode!, forFormRec: self!.mFormEditVC!.mWorking_orgFormRec!, withOrgRec: self!.mFormEditVC!.mReference_orgRec!)
                        } catch {
                            // add new field; getFieldDefsAsMatchForEditing failed and threw; should not occur
                            AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).buildForm.MultivaluedSection.FormFields.multivaluedRowToInsertAt.left", errorStruct: error, extra: fieldIDCode)
                            AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                            // cannot throw or return from here
                        }
                    }
                    
                    // save the new OrgFormFieldsEntry and its subfields (if any);
                    // sequential negative formField_index will be used as temporary placeholder's until they are saved to the database
                    if (newFormFieldEntries?.count() ?? 0) == 0 {
                        // getFieldDefsAsMatchForEditing failed to find anything but didnt throw; should not occur
                        AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).buildForm.MultivaluedSection.FormFields.multivaluedRowToInsertAt.left", during: "getFieldDefsAsMatchForEditing", errorMessage: "(newFormFieldEntries?.count() ?? 0) == 0", extra: fieldIDCode)
                        AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("App Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self!.mCTAG).buildForm", domain: FieldHandler.shared.mThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
                        // cannot throw or return from here
                    } else {
                        // add the primary field and its subfield's (if any); orderShown is fully re-synced and compacted when the changes are saved
                        self!.mFormEditVC!.mWorking_formFieldEntries!.appendNewDuringEditing(fromFormFields: newFormFieldEntries!,
                                forOrgCode: self!.mFormEditVC!.mWorking_orgFormRec!.rOrg_Code_For_SV_File,
                                forFormCode: self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Code_For_SV_File)
                    }
                    
                    // create a new ButtonRow based upon the new entry
                    var newRow:ButtonRow
                    if (newFormFieldEntries?.count() ?? 0) == 0 {
                        newRow = self!.makeFieldsButtonRow(forFormFieldEntry: nil)  // this means some type of error occurred earlier
                    } else {
                        newRow = self!.makeFieldsButtonRow(forFormFieldEntry: newFormFieldEntries![0])
                    }
                    
                    fromPushRow.value = nil     // clear out the PushRow's value so this newly chosen item does not remain "selected"
                    fromPushRow.reload()        // note this will re-trigger .onChange in the PushRow so must ignore that re-trigger else infinite loop
                    return newRow               // self.rowsHaveBeenAdded() will get invoked after this point
                    
                case .rightSelected:
                    // add and paste was chosen; by definition the clipboard has 1 and only 1 primary formfield
                    assert(FieldHandler.shared.mFormFieldClipboard != nil, "\(self!.mCTAG).buildForm.MultivaluedSection.FormFields.multivaluedRowToInsertAt.right FieldHandler.shared.mFormFieldClipboard == nil")
                    
                    // add the primary field and its subfield's (if any); orderShown is fully re-synced and compacted when the changes are saved
                    self!.mFormEditVC!.mWorking_formFieldEntries!.appendNewDuringEditing(
                        fromFormFields: FieldHandler.shared.mFormFieldClipboard!.mFrom_FormFields,
                        forOrgCode: self!.mFormEditVC!.mWorking_orgFormRec!.rOrg_Code_For_SV_File,
                        forFormCode: self!.mFormEditVC!.mWorking_orgFormRec!.rForm_Code_For_SV_File)
                    
                    // create a new ButtonRow based upon the new entry
                    let newRow:ButtonRow = self!.makeFieldsButtonRow(forFormFieldEntry: FieldHandler.shared.mFormFieldClipboard!.mFrom_FormFields[0])
                    return newRow               // self.rowsHaveBeenAdded() will get invoked after this point
                }
            }
        }
        form +++ mvs_fields
        self.mMVS_fields = mvs_fields
        
        let submitButtonSection = Section(NSLocalizedString("Submit Button", comment:""))
        form +++ submitButtonSection
        self.mSubmitButtonSection = submitButtonSection
        
        let section4 = Section(NSLocalizedString("Advanced Settings", comment:""))
        form +++ section4
        
        section4 <<< ActionSheetRow<String>() {
            $0.tag = "SV_file_type"
            $0.title = "Generate File Type"
            $0.selectorTitle = NSLocalizedString("Pick an option", comment:"")
            $0.options = SVFileModeStrings
            $0.value = SVFileModeStrings[0]     // initial value to ensure conditionals below do not fail with a nil
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    switch self!.svFileModeInt(fromString: chgRow.value!)
                    {
                    case 0: self!.mFormEditVC!.mWorking_orgFormRec!.rForm_SV_File_Type = .TEXT_TAB_DELIMITED_WITH_HEADERS
                    case 1: self!.mFormEditVC!.mWorking_orgFormRec!.rForm_SV_File_Type = .TEXT_COMMA_DELIMITED_WITH_HEADERS
                    case 2: self!.mFormEditVC!.mWorking_orgFormRec!.rForm_SV_File_Type = .TEXT_SEMICOLON_DELIMITED_WITH_HEADERS
                    case 3: self!.mFormEditVC!.mWorking_orgFormRec!.rForm_SV_File_Type = .XML_ATTTRIB_VALUE_PAIRS
                    default: self!.mFormEditVC!.mWorking_orgFormRec!.rForm_SV_File_Type = .TEXT_TAB_DELIMITED_WITH_HEADERS
                    }
                }
        }
        section4 <<< TextRow() {
            $0.tag = "xml_collection_tag"
            $0.title = NSLocalizedString("Collection of records Tag", comment:"")
            $0.hidden = Condition.function(["SV_file_type"], { [weak self] form in
                return !((form.rowBy(tag: "SV_file_type") as! ActionSheetRow<String>).value! == self!.SVFileModeStrings[3])
            })
            $0.add(rule: RuleRequired())
            $0.validationOptions = .validatesOnChange
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mFormEditVC!.mWorking_orgFormRec!.rForm_XML_Collection_Tag = chgRow.value!
                }
        }
        section4 <<< TextRow() {
            $0.tag = "xml_record_tag"
            $0.title = NSLocalizedString("Per-record Tag", comment:"")
            $0.hidden = Condition.function(["SV_file_type"], { [weak self] form in
                return !((form.rowBy(tag: "SV_file_type") as! ActionSheetRow<String>).value! == self!.SVFileModeStrings[3])
            })
            $0.add(rule: RuleRequired())
            $0.validationOptions = .validatesOnChange
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mFormEditVC!.mWorking_orgFormRec!.rForm_XML_Record_Tag = chgRow.value!
                }
        }
        
        section4 <<< ButtonRow(){
            $0.title = NSLocalizedString("Order of Fields and Metadata in SV-File ", comment:"")
            $0.presentationMode = .show(controllerProvider: .callback(builder: { [weak self] in
                let vc = FormEditFormSVFileOrderViewController()
                vc.mFormEditVC = self!.mFormEditVC
                return vc
            }), onDismiss: nil)
        }
        
        /*section4 <<< ButtonRow(){
         $0.title = NSLocalizedString("Form's Coloration (FUTURE)", comment:"")
         $0.presentationMode = .show(controllerProvider: .callback(builder: {
         let yourViewController = FormEditFormMetadataViewController()
         return yourViewController
         }), onDismiss: nil)
         }*/
    }
    
    // insert current working values into all the form's fields
    // this is done both after initial form creation and any re-display of the form;
    // WARNING: must not rebuild the form as this breaks the MultivaluedSection PushRow return:
    //          self.viewWillAppear() and self.viewDidAppear() WILL be invoked upon return from the PushRow's view controller
    private func revalueForm() {
        // step through all the rows (except the MultivaluedSection
        for hasRow in form.allRows {    // need to include hidden rows
            switch hasRow.tag {
            case "form_short_name":
                let fsn_row = hasRow as! TextRow
                if self.mFormEditVC!.mAction == .Change { fsn_row.disabled = true; fsn_row.evaluateDisabled() }
                fsn_row.value = self.mFormEditVC!.mWorking_orgFormRec!.rForm_Code_For_SV_File
                break
            case "override_email_info":
                var str:String = NSLocalizedString("Org Email Settings:\n  To: ", comment:"")
                if self.mFormEditVC!.mReference_orgRec!.rOrg_Email_To != nil {
                    str = str + self.mFormEditVC!.mReference_orgRec!.rOrg_Email_To!
                }
                str = str + NSLocalizedString("\n  CC: ", comment:"")
                if self.mFormEditVC!.mReference_orgRec!.rOrg_Email_CC != nil {
                    str = str + self.mFormEditVC!.mReference_orgRec!.rOrg_Email_CC!
                }
                str = str + NSLocalizedString("\n  Subject: ", comment:"")
                if self.mFormEditVC!.mReference_orgRec!.rOrg_Email_Subject != nil {
                    str = str + self.mFormEditVC!.mReference_orgRec!.rOrg_Email_Subject!
                }
                (hasRow as! TextAreaRow).value = str
                break
            case "override_email_to":
                (hasRow as! EmailRow).value = self.mFormEditVC!.mWorking_orgFormRec!.rForm_Override_Email_To
                break
            case "override_email_cc":
                (hasRow as! EmailRow).value = self.mFormEditVC!.mWorking_orgFormRec!.rForm_Override_Email_CC
                break
            case "override_email_subject":
                (hasRow as! TextRow).value = self.mFormEditVC!.mWorking_orgFormRec!.rForm_Override_Email_Subject
                break
            case "form_langs_mode":
                if self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported.count <= 1 {
                    (hasRow as! SegmentedRowExt<String>).hidden = true
                } else {
                    (hasRow as! SegmentedRowExt<String>).hidden = false
                    let cnt:Int = (self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions?.count ?? 0)
                    if cnt >= 2 { (hasRow as! SegmentedRowExt<String>).value = Set(["Bilingual"]); self.mLangsMode = "Bilingual" }
                    else if cnt == 1 { (hasRow as! SegmentedRowExt<String>).value = Set(["One Language"]); self.mLangsMode = "One Language" }
                    else { (hasRow as! SegmentedRowExt<String>).value = Set(["All Languages"]); self.mLangsMode = "All Languages" }
                }
                (hasRow as! SegmentedRowExt<String>).evaluateHidden()
                break
            case "form_langs_only_1":
                (hasRow as! SegmentedRowExt<String>).options = self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported
                if (self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions?.count ?? 0) >= 1 {
                    (hasRow as! SegmentedRowExt<String>).value = Set<String>([self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![0]])
                }
                (hasRow as! SegmentedRowExt<String>).updateCell()
                break
            case "form_langs_bi_first":
                (hasRow as! SegmentedRowExt<String>).options = self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported
                if (self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions?.count ?? 0) >= 1 {
                    (hasRow as! SegmentedRowExt<String>).value = Set<String>([self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![0]])
                }
                (hasRow as! SegmentedRowExt<String>).updateCell()
                break
            case "form_langs_bi_second":
                (hasRow as! SegmentedRowExt<String>).options = self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported
                if (self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions?.count ?? 0) >= 2 {
                    (hasRow as! SegmentedRowExt<String>).value = Set<String>([self.mFormEditVC!.mWorking_orgFormRec!.rForm_Lingual_LangRegions![1]])
                }
                (hasRow as! SegmentedRowExt<String>).updateCell()
                break
            case "SV_file_type":
                (hasRow as! ActionSheetRow<String>).value = SVFileModeStrings[self.mFormEditVC!.mWorking_orgFormRec!.rForm_SV_File_Type.rawValue]
                break
            case "xml_collection_tag":
                (hasRow as! TextRow).value = self.mFormEditVC!.mWorking_orgFormRec!.rForm_XML_Collection_Tag
                break
            case "xml_record_tag":
                (hasRow as! TextRow).value = self.mFormEditVC!.mWorking_orgFormRec!.rForm_XML_Record_Tag
                break
            default:
                break
            }
        }
        
        // create the Submit Button Text field(s)
        self.mSubmitButtonSection!.removeAll()
        var formFieldEntry:OrgFormFieldsEntry? = nil
        let inx:Int = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFieldIDCode: FIELD_IDCODE_METADATA.SUBMIT_BUTTON.rawValue)
        if inx >= 0 { formFieldEntry = self.mFormEditVC!.mWorking_formFieldEntries![inx] }
        if self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported.count > 1 {
            for langRegion in self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported {
                var textString:String = NSLocalizedString("Submit", comment:"")
                if formFieldEntry != nil {
                    let tempStr:String? = formFieldEntry!.getShown(forLangRegion: langRegion)
                    if tempStr != nil { textString = tempStr! }
                }
                self.mSubmitButtonSection! <<< TextRow() {
                    $0.tag = "submit_button_text_\(langRegion)"
                    $0.title = NSLocalizedString("Submit Button Text for ", comment:"") + AppDelegate.makeFullDescription(forLangRegion: langRegion)
                    $0.value = textString
                    }.onChange { chgRow in
                        if formFieldEntry != nil {
                            formFieldEntry!.setShown(value: chgRow.value, forLangRegion: langRegion)
                        }
                }
            }
        } else {
            var textString:String = NSLocalizedString("Submit", comment:"")
            if formFieldEntry != nil { textString = formFieldEntry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown! }
            self.mSubmitButtonSection! <<< TextRow() {
                $0.tag = "submit_button_text"
                $0.title = NSLocalizedString("Submit Button Text", comment:"")
                $0.value = textString
                }.onChange { chgRow in
                    if formFieldEntry != nil {
                        formFieldEntry!.setShown(value: chgRow.value, forLangRegion: formFieldEntry!.mComposedFormFieldLocalesRec.mLocale2LangRegion!)
                    }
            }
        }
        
        // adjust the add button in the formFields MVS
        if FieldHandler.shared.mFormFieldClipboard != nil {
            if self.mMVS_fields_splitRow!.rowLeftPercentage != 0.6 {
                self.mMVS_fields_splitRow!.rowLeft!.title = NSLocalizedString("Select new", comment:"")
                self.mMVS_fields_splitRow!.rowLeftPercentage = 0.6
                self.mMVS_fields_splitRow!.changedSplitPercentage()
                self.mMVS_fields_splitRow!.updateCell()
            }
        } else {
            if self.mMVS_fields_splitRow!.rowLeftPercentage != 0.99 {
                self.mMVS_fields_splitRow!.rowLeft!.title = NSLocalizedString("Select new field to add", comment:"")
                self.mMVS_fields_splitRow!.rowLeftPercentage = 0.99
                self.mMVS_fields_splitRow!.changedSplitPercentage()
                self.mMVS_fields_splitRow!.updateCell()
            }
        }
        
        // now fill in the MultivaluedSections with any pre-existing fields and therefore matching rows
        for hasSection in form.allSections {
            switch hasSection.tag {
            case "mvs_fields":
                if self.mFirstTime {
                    let mvsSection = hasSection as! MultivaluedSection
                    if self.mFormEditVC!.mWorking_formFieldEntries != nil {
                        for formFieldEntry:OrgFormFieldsEntry in self.mFormEditVC!.mWorking_formFieldEntries! {
                            if !formFieldEntry.mDuringEditing_isDeleted && !formFieldEntry.mFormFieldRec.isMetaData() &&  !formFieldEntry.mFormFieldRec.isSubFormField() {

                                let br = self.makeFieldsButtonRow(forFormFieldEntry: formFieldEntry)
                                let ar = form.rowBy(tag: "split_add_button")
                                do {
                                    try mvsSection.insert(row: br, before: ar!)
                                } catch {
                                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).revalueForm", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                                    // do not show an error to the end-user
                                }
                            }
                        }
                    }
                }
                break
            default:
                break
            }
        }
    }
    
    // create the pretty button row needed for existing and new FormField records
    private func makeFieldsButtonRow(forFormFieldEntry:OrgFormFieldsEntry?) -> ButtonRow {
        if forFormFieldEntry != nil {
            return ButtonRow() { row in
                row.tag = "FF,\(forFormFieldEntry!.mFormFieldRec.rFormField_Index)"
                row.cellStyle = UITableViewCell.CellStyle.subtitle
                row.title = "#\(forFormFieldEntry!.mFormFieldRec.rFormField_Index) \(forFormFieldEntry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_For_Collector!)"
                row.retainedObject = forFormFieldEntry!
                row.presentationMode = .show(
                    // selecting the ButtonRow invokes FormEditFieldFormViewController with callback so the row's content can be refreshed
                    controllerProvider: .callback(builder: { [weak self, weak row] in
                        let vc = FormEditFieldFormViewController()
                        vc.mFormEditVC = self!.mFormEditVC
                        vc.mEdit_FormFieldEntry = (row!.retainedObject as! OrgFormFieldsEntry)
                        return vc
                    }),
                    onDismiss: { [weak row] vc in
                        row!.updateCell()
                    })
                }.cellUpdate { cell, row in
                    // create and show the second line of text in the row
                    if row.retainedObject != nil {
                        let formFieldEntry:OrgFormFieldsEntry = (row.retainedObject as! OrgFormFieldsEntry)
                        if formFieldEntry.mFormFieldRec.rFieldProp_Row_Type != .SECTION && formFieldEntry.mFormFieldRec.rFieldProp_Row_Type != .LABEL {
                            cell.detailTextLabel?.text = "\"\(formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!)\", col=\(formFieldEntry.mFormFieldRec.rFieldProp_Col_Name_For_SV_File)"
                        } else {
                            cell.detailTextLabel?.text = "\"\(formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!)\""
                        }
                    }
            }
        } else {
            return ButtonRow() { row in
                row.tag = nil
                row.title = "!!!ERRROR!!!"
            }
        }
    }
    
    // this function will get invoked just before the move process
    // after this callback will be an immediate delete "rowsHaveBeenRemoved()" then insert "rowsHaveBeenAdded()"
    override func rowsWillBeMoved(movedRows:[BaseRow], sourceIndexes:[IndexPath], destinationIndexes:[IndexPath]) {
        super.rowsWillBeMoved(movedRows:movedRows, sourceIndexes:sourceIndexes, destinationIndexes:destinationIndexes)
        
        var inx:Int = 0
        for sourceIndexPath in sourceIndexes {
            if sourceIndexPath.section == 1 {
                // this move will occur in the mvs_fields MultivaluedSection
                self.mMovesInProcess = mMovesInProcess + 1
                let sourceBR:ButtonRow = self.mMVS_fields![sourceIndexes[inx].row] as! ButtonRow
                let sourceFFindex:Int64 = Int64(sourceBR.tag!.components(separatedBy: ",")[1])!
                let sourceFFEindex:Int = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: sourceFFindex)
                if sourceFFEindex >= 0 {
                    if sourceIndexes[inx].row < destinationIndexes[inx].row {
                        let newDestRow = destinationIndexes[inx].row + 1
                        if newDestRow >= self.mMVS_fields!.count - 1  {
//debugPrint("\(self.mCTAG).rowsWillBeMoved.mvs_fields Move \(self.mMovesInProcess) from \(sourceIndexPath.row) is \(sourceBR.title!) @ \(sourceFFindex) to primary end")
                            self.mFormEditVC!.mWorking_formFieldEntries!.moveToPrimaryEnd(sourceFFEindex: sourceFFEindex)
                        } else {
                            let destBR:ButtonRow = self.mMVS_fields![newDestRow] as! ButtonRow
                            let destFFindex:Int64 = Int64(destBR.tag!.components(separatedBy: ",")[1])!
                            let destFFEindex:Int = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: destFFindex)
                            if destFFEindex >= 0 {
//debugPrint("\(self.mCTAG).rowsWillBeMoved.mvs_fields Move \(self.mMovesInProcess) from \(sourceIndexPath.row) is \(sourceBR.title!) @ \(sourceFFindex) to before adjusted \(destinationIndexes[inx].row) is \(destBR.title!) @ \(destFFindex)")
                                self.mFormEditVC!.mWorking_formFieldEntries!.moveBefore(sourceFFEindex: sourceFFEindex, destFFEindex: destFFEindex)
                            }
                        }
                    } else {
                        let destBR:ButtonRow = self.mMVS_fields![destinationIndexes[inx].row] as! ButtonRow
                        let destFFindex:Int64 = Int64(destBR.tag!.components(separatedBy: ",")[1])!
                        let destFFEindex:Int = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: destFFindex)
                        if destFFEindex >= 0 {
//debugPrint("\(self.mCTAG).rowsWillBeMoved.mvs_fields Move \(self.mMovesInProcess) from \(sourceIndexPath.row) is \(sourceBR.title!) @ \(sourceFFindex) to before \(destinationIndexes[inx].row) is \(destBR.title!) @ \(destFFindex)")
                            self.mFormEditVC!.mWorking_formFieldEntries!.moveBefore(sourceFFEindex: sourceFFEindex, destFFEindex: destFFEindex)
                        }
                    }
                }
            }
            inx = inx + 1
        }
    }
    
    // this function will get invoked when any rows are deleted or hidden anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)

        var inx:Int = 0
        for indexPath in indexes {
            if indexPath.section == 1 {
                // this removal or move or hide occured in the mvs_fields MultivaluedSection
                if self.mMovesInProcess > 0 {
//let br:ButtonRow = rows[inx] as! ButtonRow
//debugPrint("\(self.mCTAG).rowsHaveBeenRemoved.mvs_fields Move \(self.mMovesInProcess) in-process \(indexPath.item) is \(br.title!)")
                } else {
                    let br:ButtonRow = rows[inx] as! ButtonRow
                    let ffIndex:Int64 = Int64(br.tag!.components(separatedBy: ",")[1])!
                    let ffeIndex:Int = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: ffIndex)
                    if ffeIndex >= 0 {
//debugPrint("\(self.mCTAG).rowsHaveBeenRemoved.mvs_fields Delete \(indexPath.item) is \(br.title!) @ \(ffIndex)")
                        self.mFormEditVC!.mWorking_formFieldEntries!.delete(forFFEindex: ffeIndex)
                    }
                }
            }
            inx = inx + 1
        }
    }
    
    // this function will get invoked when any rows are added or unhidden anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenAdded(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenAdded(rows, at: indexes)
        
        var inx:Int = 0
        for indexPath in indexes {
            if indexPath.section == 1 {
                // this add or move or unhide occured in the mvs_fields MultivaluedSection
                if self.mMovesInProcess > 0 {
//let br:ButtonRow = rows[inx] as! ButtonRow
//debugPrint("\(self.mCTAG).rowsHaveBeenAdded.mvs_fields Move \(self.mMovesInProcess) completed \(indexPath.item) is \(br.title!)")
                    self.mMovesInProcess = self.mMovesInProcess - 1
                }
            }
            inx = inx + 1
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// Child FormViewController - Edit FormField
/////////////////////////////////////////////////////////////////////////

// note: RowControllerType is required for callback to reach ButtonRow's onDismiss
class FormEditFieldFormViewController: FormViewController, RowControllerType {
    // caller pre-set member variables
    public weak var mFormEditVC:FormEditViewController? = nil
    public weak var mEdit_FormFieldEntry:OrgFormFieldsEntry? = nil

    /// A closure to be called when the controller disappears.
    public var onDismissCallback: ((UIViewController) -> ())?
    
    // member variables
    private var mMovesInProcess:Int = 0
    private weak var mMVS_field_options:MultivaluedSection? = nil
    private weak var mMVS_field_metas:MultivaluedSection? = nil
    private weak var mMVS_field_subfields:MultivaluedSection? = nil
    private var mWorking_FormFieldEntry:OrgFormFieldsEntry? = nil
    private var mWorking_SubfieldEntries:OrgFormFields? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCSFEFF"

    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        assert(self.mFormEditVC != nil, "\(self.mCTAG).viewDidLoad self.mFormEditVC == nil")    // this is a programming error
        assert(self.mEdit_FormFieldEntry != nil, "\(self.mCTAG).viewDidLoad self.mEdit_FormFieldEntry == nil")    // this is a programming error
        
        // define navigations buttons and capture their press
        navigationItem.title = NSLocalizedString("Edit Field", comment:"")
        let button1 = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(FormEditFieldFormViewController.tappedCancel(_:)))
        button1.title = NSLocalizedString("Cancel", comment:"")
        navigationItem.leftBarButtonItem = button1
        let button2 = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(FormEditFieldFormViewController.tappedDone(_:)))
        button2.possibleTitles = Set(arrayLiteral: NSLocalizedString("Done", comment:""))
        let button3 = UIBarButtonItem(title: NSLocalizedString("Copy", comment:""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(FormEditFieldFormViewController.tappedCopy(_:)))
        button3.possibleTitles = Set(arrayLiteral: NSLocalizedString("Copy", comment:""))
        navigationItem.setRightBarButtonItems([button2, button3], animated: false)
        
        // make a copy of the RecOrgFormFieldDefs and its internally stored RecOrgFormFieldLocales
        self.mWorking_FormFieldEntry = OrgFormFieldsEntry(existingEntry: self.mEdit_FormFieldEntry!)
        
        // now build and blend subfield entries only if the primary field supports them;
        // all the auto-indexing in the default fields is only local to this working array, not the master working set of fields;
        // however they will be pre-autolinked to the index# of the editing form field (regardless of whether it has a database or temporary index#)
        do {
            self.mWorking_SubfieldEntries = try FieldHandler.shared.getAllowedSubfieldEntriesForEditing(forPrimaryFormFieldRec: self.mEdit_FormFieldEntry!.mFormFieldRec, forFormRec: self.mFormEditVC!.mWorking_orgFormRec!, withOrgRec: self.mFormEditVC!.mReference_orgRec!)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewDidLoad", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Filesystem Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            // allow to continue processing
        }
        if (self.mWorking_SubfieldEntries?.count() ?? 0) > 0 {
            if self.mEdit_FormFieldEntry!.mFormFieldRec.hasSubFormFields() {
                for subFieldIDCode in self.mEdit_FormFieldEntry!.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! {
                    let subEntry:OrgFormFieldsEntry? = self.mFormEditVC!.mWorking_formFieldEntries!.findSubfield(forPrimaryIndex: self.mEdit_FormFieldEntry!.mFormFieldRec.rFormField_Index, forSubFieldIDCode: subFieldIDCode)
                    if subEntry != nil {
                        let wInx:Int = self.mWorking_SubfieldEntries!.findIndex(ofFieldIDCode: subEntry!.mFormFieldRec.rFieldProp_IDCode)
                        if wInx >= 0 {
                            let workEntry:OrgFormFieldsEntry = self.mWorking_SubfieldEntries![wInx]
                            workEntry.mFormFieldRec = subEntry!.mFormFieldRec
                            workEntry.mComposedFormFieldLocalesRec =  subEntry!.mComposedFormFieldLocalesRec
                            workEntry.mDuringEditing_isChosen = true
                            workEntry.mDuringEditing_isDefault = false
                        }
                    }
                }
            }
        }
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will re-appear
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView and need .Reorder MultivaluedSections
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Cancel button was tapped
    @objc func tappedCancel(_ barButtonItem: UIBarButtonItem) {
        self.closeVC()
        self.navigationController?.popViewController(animated:true)
    }
    
    // Copy button was tapped
    @objc func tappedCopy(_ barButtonItem: UIBarButtonItem) {
        FieldHandler.shared.copyToClipboardOneEdited(editedFF: self.mWorking_FormFieldEntry, editedSubFields: self.mWorking_SubfieldEntries)
    }
    
    // Done button was tapped
    @objc func tappedDone(_ barButtonItem: UIBarButtonItem) {
        // validate the entries
        let validationError = self.form.validate()
        if validationError.count > 0 {
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: message, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        
        // if there are option attributes, they may need re-ordering to the order shown;
        // warning some options may be insert meta-data
        if self.mMVS_field_options != nil,
           self.mEdit_FormFieldEntry!.mFormFieldRec.rFieldProp_Flags != nil,
           self.mEdit_FormFieldEntry!.mFormFieldRec.rFieldProp_Flags!.contains("V") {
            
            // there are options and they are order-able and deletable;
            // change the mWorking_FormFieldEntry!.mFormFieldRec since it gets copied later as a whole back to the editing copy
            // remember the "add_option" button counts as an entry in self.mMVS_field_options
            if self.mMVS_field_options!.count > 1 {
                // first re-order the option SV-File names
                var newOptionsSVFile:FieldAttributes = FieldAttributes()
                for inx in 0...self.mMVS_field_options!.endIndex - 1 {
                    let row = self.mMVS_field_options![inx]
                    if row.tag!.starts(with: "OP\t") {
                        let optionTag = row.tag!.components(separatedBy: "\t")[1]
                        let optionSVFileString = self.mWorking_FormFieldEntry!.getOptionSVFile(forTag: optionTag)
                        assert(optionSVFileString != nil, "optionSVFileString == nil")
                        newOptionsSVFile.append(codeString: optionTag, valueString: optionSVFileString!)
                    }
                }
                self.mWorking_FormFieldEntry!.mFormFieldRec.rFieldProp_Options_Code_For_SV_File = newOptionsSVFile
                
                // now reorder the option shown names per their language
                for workingFormFieldLocaleRec in self.mWorking_FormFieldEntry!.mFormFieldRec.mFormFieldLocalesRecs! {
                    var newOptionsShownPerLang:FieldAttributes = FieldAttributes()
                    for inx in 0...self.mMVS_field_options!.endIndex - 1 {
                        let row = self.mMVS_field_options![inx]
                        if row.tag!.starts(with: "OP\t") {
                            let optionTag = row.tag!.components(separatedBy: "\t")[1]
                            var optionShownString = self.mWorking_FormFieldEntry!.getOptionShown(forTag: optionTag, forLangRegion: workingFormFieldLocaleRec.rFormFieldLoc_LangRegionCode)
                            if optionShownString == nil {
                                optionShownString = self.mWorking_FormFieldEntry!.getOptionSVFile(forTag: optionTag)
                            }
                            assert(optionShownString != nil, "optionShownString == nil")
                            newOptionsShownPerLang.append(codeString: optionTag, valueString: optionShownString!)
                        }
                    }
                    workingFormFieldLocaleRec.rFieldLocProp_Options_Name_Shown = newOptionsShownPerLang
                }
            }
        }

        // copy all the changes back into the "Being Edited" FormFieldEntry
        self.mEdit_FormFieldEntry!.mFormFieldRec = self.mWorking_FormFieldEntry!.mFormFieldRec  // this copies all the internal RecOrgFormFieldLocales
        self.mEdit_FormFieldEntry!.mComposedFormFieldLocalesRec = self.mWorking_FormFieldEntry!.mComposedFormFieldLocalesRec
        if (self.mWorking_SubfieldEntries?.count() ?? 0) > 0 {
            var newIDcodes:[String] = []
            for workEntry:OrgFormFieldsEntry in self.mWorking_SubfieldEntries! {
                if workEntry.mDuringEditing_isChosen {
                    // entry is desired, and should be undeleted or added if not present
                    newIDcodes.append(workEntry.mFormFieldRec.rFieldProp_IDCode)
                    if !workEntry.mDuringEditing_isDefault {
                        // existing; ensure is undeleted
                        let sInx:Int = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: workEntry.mFormFieldRec.rFormField_Index)
                        if sInx >= 0 {
                            let subEntry:OrgFormFieldsEntry = self.mFormEditVC!.mWorking_formFieldEntries![sInx]
                            subEntry.mDuringEditing_isDeleted = false
                        }
                    } else {
                        // default; add it to the master working list; the various sort orders have already been set properly against the primary field's
                        workEntry.mDuringEditing_isDefault = false
                        workEntry.mDuringEditing_isDeleted = false
                        workEntry.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
                        workEntry.mFormFieldRec.rFormField_SubField_Within_FormField_Index = self.mEdit_FormFieldEntry!.mFormFieldRec.rFormField_Index
                        self.mFormEditVC!.mWorking_formFieldEntries!.appendNewDuringEditing(workEntry)  // temporary indexing will be auto-assigned
                    }
                } else {
                    // entry is not needed and should be removed or marked for deletion if present
                    if !workEntry.mDuringEditing_isDefault {
                        let sInx:Int = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: workEntry.mFormFieldRec.rFormField_Index)
                        if sInx >= 0 {
                            let subEntry:OrgFormFieldsEntry = self.mFormEditVC!.mWorking_formFieldEntries![sInx]
                            subEntry.mDuringEditing_isDeleted = true
                        }
                    }
                }
            }
            self.mEdit_FormFieldEntry!.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! = newIDcodes
        }
        
        self.onDismissCallback?(self)
        self.closeVC()
        self.navigationController?.popViewController(animated:true)
    }

    // close out the form and any stored arrays that are not needed but should not hog memory if the NavController keeps this VC in-memory
    private func closeVC() {
        self.mWorking_FormFieldEntry = nil
        self.mWorking_SubfieldEntries = nil
        self.mMVS_field_options = nil
        self.mMVS_field_metas = nil
        self.mMVS_field_subfields = nil
        form.removeAll()
        tableView.reloadData()
        self.mFormEditVC = nil
        self.mEdit_FormFieldEntry = nil
        self.onDismissCallback = nil
    }
    
    // build the form
    private func buildForm() {
        let section1 = Section("Field's Identity")
        form +++ section1
        
        section1 <<< LabelRow() {
            $0.tag = "formfield_index"
            $0.title = NSLocalizedString("Index#", comment:"")
            $0.value = String(self.mEdit_FormFieldEntry!.mFormFieldRec.rFormField_Index)
        }
        section1 <<< LabelRow() {
            $0.tag = "formfield_idcode_name"
            $0.title = NSLocalizedString("Field IDCode Name", comment:"")
            $0.value = self.mEdit_FormFieldEntry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_For_Collector!
        }
        section1 <<< LabelRow() {
            $0.tag = "formfield_frt"
            $0.title = NSLocalizedString("Field Row-Type", comment:"")
            $0.value = FIELD_ROW_TYPE.getFieldRowTypeString(fromType: self.mEdit_FormFieldEntry!.mFormFieldRec.rFieldProp_Row_Type)
        }
        let section2 = Section("Field's Names")
        form +++ section2
        if self.mEdit_FormFieldEntry!.mFormFieldRec.rFieldProp_Row_Type != .SECTION && self.mEdit_FormFieldEntry!.mFormFieldRec.rFieldProp_Row_Type != .LABEL && !self.mEdit_FormFieldEntry!.mFormFieldRec.hasSubFormFields() {
            section2 <<< TextRow() {
                $0.tag = "formfield_col_name"
                $0.title = NSLocalizedString("SV-File Col Name", comment:"")
                $0.value = self.mWorking_FormFieldEntry!.mFormFieldRec.rFieldProp_Col_Name_For_SV_File
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate {cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }.onChange { [weak self] chgRow in
                    if !(chgRow.value ?? "").isEmpty {
                        self!.mWorking_FormFieldEntry!.mFormFieldRec.rFieldProp_Col_Name_For_SV_File = chgRow.value!
                    }
            }
        }
        
        // shown and placeholder text in the various languages
        if !self.mEdit_FormFieldEntry!.mFormFieldRec.isMetaData() {
            if self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported.count > 1 {
                for langRegionCode in self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported {
                    let currSection = Section("Shown for " + AppDelegate.makeFullDescription(forLangRegion: langRegionCode))
                    form +++ currSection
                    currSection <<< TextRow() {
                        $0.tag = "formfield_name_shown_\(langRegionCode)"
                        $0.title = NSLocalizedString("Title", comment:"")
                        $0.value = self.mWorking_FormFieldEntry!.getShown(forLangRegion: langRegionCode)
                        }.onChange { [weak self] chgRow in
                            self!.mWorking_FormFieldEntry!.setShown(value: chgRow.value, forLangRegion: langRegionCode)
                    }
                    currSection <<< TextRow() {
                        $0.tag = "formfield_placeholder_shown_\(langRegionCode)"
                        $0.title = NSLocalizedString("Placeholder", comment:"")
                        $0.value = self.mWorking_FormFieldEntry!.getPlaceholder(forLangRegion: langRegionCode)
                        }.onChange { [weak self] chgRow in
                            self!.mWorking_FormFieldEntry!.setPlaceholder(value: chgRow.value, forLangRegion: langRegionCode)
                    }
                }
            } else {
                let langRegionCode = self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0]
                section2 <<< TextRow() {
                    $0.tag = "formfield_name_shown_\(langRegionCode)"
                    $0.title = NSLocalizedString("Shown Title", comment:"")
                    $0.value = self.mWorking_FormFieldEntry!.getShown(forLangRegion: self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0])
                    }.onChange { [weak self] chgRow in
                        self!.mWorking_FormFieldEntry!.setShown(value: chgRow.value, forLangRegion: self!.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0])
                }
                section2 <<< TextRow() {
                    $0.tag = "formfield_placeholder_shown_\(langRegionCode)"
                    $0.title = NSLocalizedString("Shown Placeholder", comment:"")
                    $0.value = self.mWorking_FormFieldEntry!.getPlaceholder(forLangRegion: self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0])
                    }.onChange { [weak self] chgRow in
                        self!.mWorking_FormFieldEntry!.setPlaceholder(value: chgRow.value, forLangRegion: self!.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0])
                }
            }
        }

        // option attributes for those fields that have them
        if (self.mWorking_FormFieldEntry!.mFormFieldRec.rFieldProp_Options_Code_For_SV_File?.count() ?? 0) > 0 {
            var isFixed:Bool = true
            var options:MultivaluedOptions = .None
            if self.mWorking_FormFieldEntry!.mFormFieldRec.rFieldProp_Flags!.contains("V") {
                isFixed = false
                options = [.Insert, .Delete, .Reorder]
            }
            let mvs_field_options = MultivaluedSection(multivaluedOptions: options,
                 header: NSLocalizedString("Field's Options in order to-be-shown", comment:"")) { mvSection in
                    mvSection.tag = "mvs_field_options"
                    mvSection.showInsertIconInAddButton = false
                    if !isFixed {
                        mvSection.addButtonProvider = { section in
                            return ButtonRow(){
                                $0.tag = "add_new_option"
                                $0.title = NSLocalizedString("Add New Option", comment:"")
                                }.cellUpdate { updCell, updRow in
                                    updCell.textLabel?.textColor = UIColor(hex6: 0x007AFF)
                                    updCell.imageView?.image = #imageLiteral(resourceName: "Add")
                            }
                        }  // end of addButtonProvider
                        mvSection.multivaluedRowToInsertAt = { [weak self] index in
                            var counter:Int = 1
                            var newTag:String = ""
                            var newTagTest:String = ""
                            repeat {
                                newTag = "$" + NSLocalizedString("new", comment:"") + String(counter)
                                newTagTest = "OP\t\(newTag)\t"
                                counter = counter + 1
                            } while self!.form.rowBy(tagLeading: newTagTest) != nil
                            var langShownPairs:[CodePair] = []
                            for langRegionCode in self!.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported {
                                langShownPairs.append(CodePair(langRegionCode, NSLocalizedString("New", comment:"")))
                            }
                            self!.mWorking_FormFieldEntry!.addOption(tagValue: newTag, SVfileValue: NSLocalizedString("New", comment:""), langShownPairs: langShownPairs)
                            let br = self!.makeOptionsButtonRow(forTag: newTag)
                            return br
                        }
                    }
                }
            form +++ mvs_field_options
            self.mMVS_field_options = mvs_field_options
            for svCP in self.mWorking_FormFieldEntry!.mFormFieldRec.rFieldProp_Options_Code_For_SV_File!.mAttributes {
                let br = self.makeOptionsButtonRow(forTag: svCP.codeString)
                if isFixed {
                    self.mMVS_field_options!.append(br)
                } else {
                    let ar = form.rowBy(tag: "add_new_option")
                    do {
                        try self.mMVS_field_options!.insert(row: br, before: ar!)
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).buildForm", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                        // do not show an error to the end-user
                    }
                }
            }
        }
        
        // meta-data attributes for those fields that have them
        if (self.mWorking_FormFieldEntry!.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File?.count() ?? 0) > 0 {
            let mvs_field_metas = MultivaluedSection(multivaluedOptions: .None,
                header: NSLocalizedString("Field's Inline Metadata", comment:"")) { mvSection in
                    mvSection.tag = "mvs_field_metas"
                    mvSection.showInsertIconInAddButton = false
                }
            form +++ mvs_field_metas
            self.mMVS_field_metas = mvs_field_metas
            for svCP in self.mWorking_FormFieldEntry!.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File!.mAttributes {
                let br = self.makeMetadatasButtonRow(forTag: svCP.codeString)
                self.mMVS_field_metas!.append(br)
            }
        }
        
        // subfields for those fields that have them
        if (self.mWorking_SubfieldEntries?.count() ?? 0) > 0 {
            let mvs_field_subfields = MultivaluedSection(multivaluedOptions: .None,
                header: NSLocalizedString("Field's Subfields", comment:"")) { mvSection in
                    mvSection.tag = "mvs_field_subfields"
                    mvSection.showInsertIconInAddButton = false
            }
            form +++ mvs_field_subfields
            self.mMVS_field_subfields = mvs_field_subfields
            for entry:OrgFormFieldsEntry in self.mWorking_SubfieldEntries! {
                let br = self.makeSubfieldButtonRow(forFormFieldEntry: entry)
                self.mMVS_field_subfields!.append(br)
            }
        }
    }
    
    // create the pretty complex button row needed for existing and new Attribute entries
    private func makeOptionsButtonRow(forTag:String) -> ButtonRow {
        var svCode:String? = self.mWorking_FormFieldEntry!.getOptionSVFile(forTag: forTag)
        var shownName:String? = self.mWorking_FormFieldEntry!.getOptionShown(forTag: forTag, forLangRegion: self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0])
        if forTag.starts(with: "***") {
            if svCode == forTag { svCode = nil }
            if shownName == forTag { shownName = nil }
        }
        return ButtonRow() { row in
            row.tag = "OP\t\(forTag)\t\((svCode ?? ""))\t\((shownName ?? ""))"
            row.cellStyle = UITableViewCell.CellStyle.subtitle
            row.title = "(\(forTag)) " + (svCode ?? "")
            row.presentationMode = .show(
                // selecting the ButtonRow invokes FormEditAttributeFormViewController with callback so the row's content can be refreshed
                controllerProvider: .callback(builder: { [weak self, weak row] in
                    let tagComponents = row!.tag!.components(separatedBy: "\t")
                    let vc = FormEditAttributeFormViewController()
                    vc.mFormEditVC = self!.mFormEditVC
                    vc.mEdit_FormFieldEntry = self!.mWorking_FormFieldEntry
                    vc.mEdit_isMetadata = false
                    if tagComponents.count == 4 { vc.mEdit_Tag = tagComponents[1] }
                    else { vc.mEdit_Tag = forTag }
                    return vc
                }),
                onDismiss: { [weak self, weak row] vc in
                    let feafVC:FormEditAttributeFormViewController = vc as! FormEditAttributeFormViewController
                    let newTag = feafVC.mEdit_Tag!
                    var newSVcode = self!.mWorking_FormFieldEntry!.getOptionSVFile(forTag: newTag)
                    var newShownName = self!.mWorking_FormFieldEntry!.getOptionShown(forTag: newTag, forLangRegion: self!.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0])
                    if newTag.starts(with: "***") {
                        if newSVcode == newTag { newSVcode = nil }
                        if newShownName == newTag { newShownName = nil }
                    }
                    row!.tag = "OP\t\(newTag)\t\((newSVcode ?? ""))\t\((newShownName ?? ""))"
                    row!.title = "(\(newTag)) " + (newSVcode ?? "")
                    row!.updateCell()
            })
            }.cellUpdate { cell, row in
                let tagComponents = row.tag!.components(separatedBy: "\t")
                if tagComponents.count == 4 {
                    cell.detailTextLabel?.text = tagComponents[3]
                }
        }
    }
    
    // create the pretty complex button row needed for existing and new Metadata entries
    private func makeMetadatasButtonRow(forTag:String) -> ButtonRow {
        var svCode:String? = self.mWorking_FormFieldEntry!.getMetadataSVFile(forTag: forTag)
        var shownName:String? = self.mWorking_FormFieldEntry!.getMetadataShown(forTag: forTag, forLangRegion: self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0])
        if svCode == forTag { svCode = nil }
        if shownName == forTag { shownName = nil }
        return ButtonRow() { row in
            row.tag = "MT\t\(forTag)\t\((svCode ?? ""))\t\((shownName ?? ""))"
            row.cellStyle = UITableViewCell.CellStyle.subtitle
            row.title = "(\(forTag)) " + (svCode ?? "")
            row.presentationMode = .show(
                // selecting the ButtonRow invokes FormEditAttributeFormViewController with callback so the row's content can be refreshed
                controllerProvider: .callback(builder: { [weak self, weak row] in
                    let tagComponents = row!.tag!.components(separatedBy: "\t")
                    let vc = FormEditAttributeFormViewController()
                    vc.mFormEditVC = self!.mFormEditVC
                    vc.mEdit_FormFieldEntry = self!.mWorking_FormFieldEntry
                    vc.mEdit_isMetadata = true
                    if tagComponents.count == 4 { vc.mEdit_Tag = tagComponents[1] }
                    else { vc.mEdit_Tag = forTag }
                    return vc
                }),
                onDismiss: { [weak self, weak row] vc in
                    let feafVC:FormEditAttributeFormViewController = vc as! FormEditAttributeFormViewController
                    let newTag = feafVC.mEdit_Tag!
                    var newSVcode = self!.mWorking_FormFieldEntry!.getMetadataSVFile(forTag: newTag)
                    var newShownName = self!.mWorking_FormFieldEntry!.getMetadataShown(forTag: newTag, forLangRegion: self!.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0])
                    if newSVcode == newTag { newSVcode = nil }
                    if newShownName == newTag { newShownName = nil }
                    row!.tag = "MT\t\(newTag)\t\((newSVcode ?? ""))\t\((newShownName ?? ""))"
                    row!.title = "(\(newTag)) " + (newSVcode ?? "")
                    row!.updateCell()
            })
            }.cellUpdate { cell, row in
                let tagComponents = row.tag!.components(separatedBy: "\t")
                if tagComponents.count == 4 {
                    cell.detailTextLabel?.text = tagComponents[3]
                }
        }
    }
        
    // create the pretty complex button row needed for existing and new FormField records
    private func makeSubfieldButtonRow(forFormFieldEntry:OrgFormFieldsEntry) -> CheckButtonRow {
        return CheckButtonRow() { row in
            row.tag = "SF,\(forFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)"
            row.cellStyle = UITableViewCell.CellStyle.subtitle
            row.title = "#\(forFormFieldEntry.mFormFieldRec.rFormField_Index) \(forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_For_Collector!)"
            row.retainedObject = forFormFieldEntry
            row.checkBoxChanged = { cell, row in
                forFormFieldEntry.mDuringEditing_isChosen = cell.checkBox!.isSelected
            }
            row.presentationMode = .show(
                // selecting the ButtonRow invokes FormEditFieldFormViewController with callback so the row's content can be refreshed
                controllerProvider: .callback(builder: { [weak self, weak row] in
                    let vc = FormEditFieldFormViewController()
                    vc.mFormEditVC = self!.mFormEditVC
                    vc.mEdit_FormFieldEntry = (row!.retainedObject as! OrgFormFieldsEntry)
                    return vc
                }),
                onDismiss: { [weak row] vc in
                    row!.updateCell()
            })
            }.cellUpdate { cell, row in
                if row.retainedObject != nil {
                    let formFieldEntry = (row.retainedObject as! OrgFormFieldsEntry)
                    if formFieldEntry.mDuringEditing_isChosen { cell.checkBox?.isSelected = true }
                    else { cell.checkBox?.isSelected = false }
                    // create and show the second line of text in the row
                    cell.detailTextLabel?.text = "\"\(formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!)\", col=\(formFieldEntry.mFormFieldRec.rFieldProp_Col_Name_For_SV_File)"
                }
        }
    }
    
    // make the LabelRow associated with the $$$,***,### attributes not deletable
    override open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let superStyle = super.tableView(tableView, editingStyleForRowAt: indexPath)
        
        guard let section = form[indexPath.section] as? MultivaluedSection else {
            return superStyle
        }
        if section.tag != "mvs_field_options" { return superStyle }
        if indexPath.row == section.count - 1 { return superStyle }
        let hasTag:String? = form[indexPath.section][indexPath.row].tag
        if hasTag == nil { return superStyle }
        if !hasTag!.starts(with: "OP\t") { return superStyle }
        let tagComponents = hasTag!.components(separatedBy: "\t")
        if !tagComponents[1].starts(with:"$$$") && !tagComponents[1].starts(with:"***") && !tagComponents[1].starts(with:"###") { return superStyle }
        return .none
    }
    
    // this function will get invoked just before the move process
    // after this callback will be an immediate delete "rowsHaveBeenRemoved()" then insert "rowsHaveBeenAdded()"
    override func rowsWillBeMoved(movedRows:[BaseRow], sourceIndexes: [IndexPath], destinationIndexes: [IndexPath]) {
        super.rowsWillBeMoved(movedRows:movedRows, sourceIndexes:sourceIndexes, destinationIndexes:destinationIndexes)
        
        var inx:Int = 0
        for sourceIndexPath in sourceIndexes {
            if form[sourceIndexPath.section].tag == "mvs_field_options" {
                // this move will occur in the mvs_field_options MultivaluedSection
                self.mMovesInProcess = mMovesInProcess + 1
            }
            inx = inx + 1
        }
    }
    
    // this function will get invoked when any rows are deleted or hidden anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        
        var inx:Int = 0
        for indexPath in indexes {
            if form[indexPath.section].tag == "mvs_field_options" {
                // this removal or move or hide occured in the mvs_field_options MultivaluedSection
                if self.mMovesInProcess > 0 {
//let br:ButtonRow = rows[inx] as! ButtonRow
//debugPrint("\(self.mCTAG).rowsHaveBeenRemoved.mvs_field_options Move \(self.mMovesInProcess) in-process \(indexPath.item) is \(br.title!)")
                } else {
                    let br:ButtonRow = rows[inx] as! ButtonRow
                    let deleteTag:String = br.tag!.components(separatedBy: "\t")[1]
                    let _ = self.mWorking_FormFieldEntry!.removeOption(tagValue: deleteTag)
//debugPrint("\(self.mCTAG).rowsHaveBeenRemoved.mvs_field_options Delete \(indexPath.item) is \(br.title!)")
                }
            }
            inx = inx + 1
        }
    }
    
    // this function will get invoked when any rows are added or unhidden anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenAdded(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenAdded(rows, at: indexes)
        
        var inx:Int = 0
        for indexPath in indexes {
            if form[indexPath.section].tag == "mvs_field_options" {
                // this add or move or unhide occured in the mvs_field_options MultivaluedSection
                if self.mMovesInProcess > 0 {
//let br:ButtonRow = rows[inx] as! ButtonRow
//debugPrint("\(self.mCTAG).rowsHaveBeenAdded.mvs_field_options Move \(self.mMovesInProcess) completed \(indexPath.item) is \(br.title!)")
                    self.mMovesInProcess = self.mMovesInProcess - 1
                }
            }
            inx = inx + 1
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// Child FormViewController - Edit Attribute (either an Option or Metadata)
/////////////////////////////////////////////////////////////////////////

// note: RowControllerType is required for callback to reach ButtonRow's onDismiss
class FormEditAttributeFormViewController: FormViewController, RowControllerType {
    // caller pre-set member variables
    public weak var mFormEditVC:FormEditViewController? = nil
    public weak var mEdit_FormFieldEntry:OrgFormFieldsEntry? = nil
    public var mEdit_Tag:String? = nil
    public var mEdit_isMetadata:Bool = false

    /// A closure to be called when the controller disappears.
    public var onDismissCallback: ((UIViewController) -> ())?
    
    // member variables

    // member constants and other static content
    private let mCTAG:String = "VCSFEAF"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // define navigations buttons and capture their press
        navigationItem.title = NSLocalizedString("Edit Attribute", comment:"")
        let button1 = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(FormEditAttributeFormViewController.tappedDone(_:)))
        button1.title = NSLocalizedString("Done", comment:"")
        navigationItem.rightBarButtonItem = button1
        let button2 = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(FormEditAttributeFormViewController.tappedCancel(_:)))
        button2.title = NSLocalizedString("Cancel", comment:"")
        navigationItem.leftBarButtonItem = button2
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will re-appear
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView and need .Reorder MultivaluedSections
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Cancel button was tapped
    @objc func tappedCancel(_ barButtonItem: UIBarButtonItem) {
        self.closeVC()
        self.navigationController?.popViewController(animated:true)
    }
    
    // Done button was tapped
    @objc func tappedDone(_ barButtonItem: UIBarButtonItem) {
        // various validations
        let validationError = self.form.validate()
        if validationError.count > 0 {
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: message, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        let rowTag = form.rowBy(tag: "attribute_code") as? TextRow
        if rowTag != nil {
            if (rowTag!.value ?? "").isEmpty {
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Short Sync Tag must not be blank", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                return
            } else if rowTag!.value! != self.mEdit_Tag {
                if self.mEdit_isMetadata {
                    if self.mEdit_FormFieldEntry!.existsMetadataTag(tagValue: rowTag!.value!) {
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("The changed Short Sync Tag duplicates an existing one", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                        return
                    }
                } else {
                    if self.mEdit_FormFieldEntry!.existsOptionTag(tagValue: rowTag!.value!) {
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("The changed Short Sync Tag duplicates an existing one", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                        return
                    }
                }
            }
        }
        let rowColumn = form.rowBy(tag: "attribute_column") as? TextRow
        if rowColumn != nil {
            if (rowColumn!.value ?? "").isEmpty {
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Code for SV_File must not be blank", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                return
            }
        }
        for langRegionCode in self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported {
            let rowShown = form.rowBy(tag: "attribute_shown_\(langRegionCode)") as? TextRow
            if rowShown != nil {
                if (rowShown!.value ?? "").isEmpty {
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Phrases Shown must not be blank", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                    return
                }
            }
        }
        
        // all validation were passed
        if rowTag != nil, rowTag!.value! != self.mEdit_Tag, !self.mEdit_isMetadata {
            // the tag is not metadata, allowed to be changed, and indeed its value was changed; could be an add, change, or delete
            // first delete the original attribute by its tag; this will remove it from all languages too
            var useSVFileName:String? = self.mEdit_FormFieldEntry!.getOptionSVFile(forTag: self.mEdit_Tag!)
            self.mEdit_FormFieldEntry!.removeOption(tagValue: self.mEdit_Tag!)
            
            // now add the new attribute with its new tag and names in its various languages
            if rowColumn != nil { useSVFileName = rowColumn!.value! }
            var langShownPairs:[CodePair] = []
            for langRegionCode in self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported {
                let rowShown = form.rowBy(tag: "attribute_shown_\(langRegionCode)") as? TextRow
                if rowShown != nil, rowShown!.value != nil {
                    langShownPairs.append(CodePair(langRegionCode, rowShown!.value!))
                }
            }
            self.mEdit_FormFieldEntry!.addOption(tagValue: rowTag!.value!, SVfileValue: useSVFileName ?? "?", langShownPairs: langShownPairs)
            self.mEdit_Tag = rowTag!.value!
        } else {
            // the tag cannot be changed; only the column name and the shown names can be changed
            if rowColumn != nil {
                // column name is changable and is guarenteed to have a non-empty value
                if self.mEdit_isMetadata { self.mEdit_FormFieldEntry!.setMetadataSVFile(value: rowColumn!.value!, forTag: self.mEdit_Tag!) }
                else { self.mEdit_FormFieldEntry!.setOptionSVFile(value: rowColumn!.value!, forTag: self.mEdit_Tag!) }
            }
            // pull in all the possible shown names
            for langRegionCode in self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported {
                let rowShown = form.rowBy(tag: "attribute_shown_\(langRegionCode)") as? TextRow
                if rowShown != nil, rowShown!.value != nil {
                    if self.mEdit_isMetadata { self.mEdit_FormFieldEntry!.setMetadataShown(value: rowShown!.value!, forTag: self.mEdit_Tag!, forLangRegion: langRegionCode) }
                    else { self.mEdit_FormFieldEntry!.setOptionShown(value: rowShown!.value!, forTag: self.mEdit_Tag!, forLangRegion: langRegionCode) }
                }
            }
        }
        
        self.onDismissCallback?(self)
        self.closeVC()
        self.navigationController?.popViewController(animated:true)
    }
    
    // close out the form and any stored arrays that are not needed but should not hog memory if the NavController keeps this VC in-memory
    private func closeVC() {
        self.mEdit_FormFieldEntry = nil
        self.mEdit_Tag = nil
        form.removeAll()
        tableView.reloadData()
        self.mFormEditVC = nil
        self.onDismissCallback = nil
    }

    // build the form
    private func buildForm() {
        let section1 = Section(NSLocalizedString("Field's Identity", comment:""))
        form +++ section1
        
        section1 <<< LabelRow() {
            $0.tag = "formfield_index"
            $0.title = NSLocalizedString("Index#", comment:"")
            $0.value = String(self.mEdit_FormFieldEntry!.mFormFieldRec.rFormField_Index)
        }
        
        section1 <<< LabelRow() {
            $0.tag = "formfield_idcode_name"
            $0.title = NSLocalizedString("Field IDCode Name", comment:"")
            $0.value = self.mEdit_FormFieldEntry!.mComposedFormFieldLocalesRec.rFieldLocProp_Name_For_Collector!
        }
        
        section1 <<< LabelRow() {
            $0.tag = "formfield_frt"
            $0.title = NSLocalizedString("Field Row-Type", comment:"")
            $0.value = FIELD_ROW_TYPE.getFieldRowTypeString(fromType:self.mEdit_FormFieldEntry!.mFormFieldRec.rFieldProp_Row_Type)
        }
        
        var section2:Section
        if self.mEdit_isMetadata { section2 = Section(NSLocalizedString("MetaData's Identity and Names", comment:"")) }
        else { section2 = Section(NSLocalizedString("Option's Identity and Names", comment:"")) }
        form +++ section2
        if (self.mEdit_Tag?.starts(with: "$$$") ?? false) == true || (self.mEdit_Tag?.starts(with: "***") ?? false) == true ||
           (self.mEdit_Tag?.starts(with: "###") ?? false) == true || self.mEdit_isMetadata {
            section2 <<< LabelRow() {
                $0.tag = "attribute_code"
                $0.title = NSLocalizedString("Short Sync Tag", comment:"")
                $0.value = self.mEdit_Tag
            }
        } else {
            section2 <<< TextRow() {
                $0.tag = "attribute_code"
                $0.title = NSLocalizedString("Short Sync Tag", comment:"")
                $0.value = self.mEdit_Tag
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate {cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
        }
        
        var columnName:String?
        if self.mEdit_isMetadata { columnName = self.mEdit_FormFieldEntry!.getMetadataSVFile(forTag: self.mEdit_Tag!) }
        else { columnName = self.mEdit_FormFieldEntry!.getOptionSVFile(forTag: self.mEdit_Tag!) }
        if (self.mEdit_Tag?.starts(with: "***") ?? false) == true {
            // *** metadata or *** option-insert has no changable SV-File content
        } else if (self.mEdit_Tag?.starts(with: "$$$") ?? false) == true && self.mEdit_Tag == columnName {
            // $$$ options with duplicated SV-File name also has no changable SV-File content
        } else {
            section2 <<< TextRow() {
                $0.tag = "attribute_column"
                if (self.mEdit_Tag?.starts(with: "###") ?? false) == true { $0.title = NSLocalizedString("Code", comment:"") }
                else { $0.title = NSLocalizedString("Code for the SV-File", comment:"") }
                $0.value = columnName
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate {cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
        }
        
        if (self.mEdit_Tag?.starts(with: "###") ?? false) == true {
            // ### meta-data has no changable shown content
        } else if !self.mEdit_isMetadata && (self.mEdit_Tag?.starts(with: "***") ?? false) == true {
            // *** option-insert has no changable shown content
        } else if self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported.count > 1 {
            for langRegionCode in self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported {
                section2 <<< TextRow() {
                    $0.tag = "attribute_shown_\(langRegionCode)"
                    $0.title = NSLocalizedString("Phrase Shown for ", comment:"") + AppDelegate.makeFullDescription(forLangRegion: langRegionCode)
                    if self.mEdit_isMetadata { $0.value = self.mEdit_FormFieldEntry!.getMetadataShown(forTag: self.mEdit_Tag!, forLangRegion: langRegionCode) }
                    else { $0.value = self.mEdit_FormFieldEntry!.getOptionShown(forTag: self.mEdit_Tag!, forLangRegion: langRegionCode) }
                    $0.add(rule: RuleRequired())
                    $0.validationOptions = .validatesOnChange
                    }.cellUpdate {cell, row in
                        if !row.isValid {
                            cell.titleLabel?.textColor = .red
                        }
                }
            }
        } else {
            let langRegionCode = self.mFormEditVC!.mReference_orgRec!.rOrg_LangRegionCodes_Supported[0]
            section2 <<< TextRow() {
                $0.tag = "attribute_shown_\(langRegionCode)"
                $0.title = NSLocalizedString("Phrase Shown", comment:"")
                if self.mEdit_isMetadata { $0.value = self.mEdit_FormFieldEntry!.getMetadataShown(forTag: self.mEdit_Tag!, forLangRegion: langRegionCode) }
                else { $0.value = self.mEdit_FormFieldEntry!.getOptionShown(forTag: self.mEdit_Tag!, forLangRegion: langRegionCode) }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate {cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// Child FormViewController - Change SVFile order and edit Metadata
/////////////////////////////////////////////////////////////////////////

class FormEditFormSVFileOrderViewController: FormViewController {
    // caller pre-set member variables
    public weak var mFormEditVC:FormEditViewController? = nil

    // member variables
    private weak var mMVS_entryFields:MultivaluedSection? = nil
    private weak var mMVS_metaFields:MultivaluedSection? = nil
    
    // member constants and other static content
    private let mCTAG:String = "FEFOVC"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // define navigations buttons and capture their press
        let button1 = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(FormEditAttributeFormViewController.tappedDone(_:)))
        button1.title = NSLocalizedString("Done", comment:"")
        navigationItem.rightBarButtonItem = button1
        let button2 = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(FormEditAttributeFormViewController.tappedCancel(_:)))
        button2.title = NSLocalizedString("Cancel", comment:"")
        navigationItem.leftBarButtonItem = button2
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationItem.title = NSLocalizedString("Order of Fields", comment:"")
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will re-appear
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView and need .Reorder MultivaluedSections
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func tappedDone(_ barButtonItem: UIBarButtonItem) {
        // set all the rFormField_Order_SV_File in the order shown on-screen
        var orderSVfile:Int = 10
        for rInx in 0...self.mMVS_entryFields!.endIndex - 1 {
            let row = self.mMVS_entryFields![rInx]
            if row.tag!.starts(with: "EF,") {
                let ff_index = Int64(row.tag!.components(separatedBy: ",")[1])!
                let inx = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: ff_index)
                if inx >= 0 {
                    self.mFormEditVC!.mWorking_formFieldEntries![inx].mFormFieldRec.rFormField_Order_SV_File = orderSVfile
                }
            }
            orderSVfile = orderSVfile + 10
        }
        
        orderSVfile = RecOrgFormFieldDefs.FORMFIELD_ORDER_UPPERSTART
        for rInx in 0...self.mMVS_metaFields!.endIndex - 1 {
            let row = self.mMVS_metaFields![rInx]
            if row.tag!.starts(with: "MF,") {
                let ff_index = Int64(row.tag!.components(separatedBy: ",")[1])!
                let inx = self.mFormEditVC!.mWorking_formFieldEntries!.findIndex(ofFormFieldIndex: ff_index)
                if inx >= 0 {
                    self.mFormEditVC!.mWorking_formFieldEntries![inx].mFormFieldRec.rFormField_Order_SV_File = orderSVfile
                }
            }
            orderSVfile = orderSVfile + 1
        }
        
        self.closeVC()
        self.navigationController?.popViewController(animated:true)

    }
    @objc func tappedCancel(_ barButtonItem: UIBarButtonItem) {
        self.closeVC()
        self.navigationController?.popViewController(animated:true)
    }
    
    // close out the form and any stored arrays that are not needed but should not hog memory if the NavController keeps this VC in-memory
    private func closeVC() {
        self.mMVS_entryFields = nil
        self.mMVS_metaFields = nil
        form.removeAll()
        tableView.reloadData()
        self.mFormEditVC = nil
    }
    
    // build the form
    private func buildForm() {
        
        let mvs_entryFields = MultivaluedSection(multivaluedOptions: [.Reorder],
            header: NSLocalizedString("First Form's Fields in SV-File order", comment:"")) { mvSection in
                mvSection.tag = "mvs_entryfields"
                mvSection.showInsertIconInAddButton = false
        }
        form +++ mvs_entryFields
        self.mMVS_entryFields = mvs_entryFields
        
        let mvs_metaFields = MultivaluedSection(multivaluedOptions: [.Reorder],
            header: NSLocalizedString("Then Form's Metadata in SV-File order", comment:"")) { mvSection in
                mvSection.tag = "mvs_metafields"
                mvSection.showInsertIconInAddButton = false
        }
        form +++ mvs_metaFields
        self.mMVS_metaFields = mvs_metaFields
        
        // fill in both the section's contents
        if (self.mFormEditVC!.mWorking_formFieldEntries?.count() ?? 0) > 0 {
            // get an array of sorted index#s into mWorking_formFieldEntries in rFormField_Order_SV_File order
            let svFileOrder:[Int] = self.mFormEditVC!.mWorking_formFieldEntries!.enumerated().sorted { $0.element.mFormFieldRec.rFormField_Order_SV_File < $1.element.mFormFieldRec.rFormField_Order_SV_File }.map { $0.offset }
            
            for inx in 0...svFileOrder.count - 1 {
                let entry:OrgFormFieldsEntry = self.mFormEditVC!.mWorking_formFieldEntries![svFileOrder[inx]]
                // all fields; except for section, label, and container fields; except for non-SV-File metadata
                if !entry.mFormFieldRec.hasSubFormFields() && entry.mFormFieldRec.rFormField_Order_SV_File >= 0 &&
                   entry.mFormFieldRec.rFieldProp_Row_Type != .SECTION && entry.mFormFieldRec.rFieldProp_Row_Type != .LABEL {
                    let br = self.makeAllFieldButtonRow(forFormFieldEntry: entry)
                    if entry.mFormFieldRec.isMetaData() { self.mMVS_metaFields!.append(br) }
                    else { self.mMVS_entryFields!.append(br) }
                }
            }
        }
    }
    
    // create the pretty complex button row needed for existing and new FormField records
    private func makeAllFieldButtonRow(forFormFieldEntry:OrgFormFieldsEntry) -> ButtonRow {
        return ButtonRow() { row in
            if forFormFieldEntry.mFormFieldRec.isMetaData() { row.tag = "MF,\(forFormFieldEntry.mFormFieldRec.rFormField_Index)" }
            else { row.tag = "EF,\(forFormFieldEntry.mFormFieldRec.rFormField_Index)" }
            row.cellStyle = UITableViewCell.CellStyle.subtitle
            row.title = "#\(forFormFieldEntry.mFormFieldRec.rFormField_Index) \(forFormFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_For_Collector!)"
            row.retainedObject = forFormFieldEntry
            row.presentationMode = .show(
                // selecting the ButtonRow invokes FormEditFieldFormViewController with callback so the row's content can be refreshed
                controllerProvider: .callback(builder: { [weak self, weak row] in
                    let vc = FormEditFieldFormViewController()
                    vc.mFormEditVC = self!.mFormEditVC
                    vc.mEdit_FormFieldEntry = (row!.retainedObject as! OrgFormFieldsEntry)
                    return vc
                }),
                onDismiss: { [weak row] vc in
                    row!.updateCell()
            })
            }.cellUpdate { cell, row in
                if row.retainedObject != nil {
                    let formFieldEntry = (row.retainedObject as! OrgFormFieldsEntry)
                    // create and show the second line of text in the row
                    cell.detailTextLabel?.text = "\"\(formFieldEntry.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown!)\", col=\(formFieldEntry.mFormFieldRec.rFieldProp_Col_Name_For_SV_File)"
                }
        }
    }
}

