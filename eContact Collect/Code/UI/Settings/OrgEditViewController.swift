//
//  EditOrgViewController.swift
//  eContact Collect
//
//  Created by Yo on 9/28/18.
//

import UIKit
import Eureka

// define the delegate protocol that other portions of the App must use to know when the OEVC saves or cancels
protocol OEVC_Delegate {
    // return wasSaved=true if saved successfully; wasSaved=false if cancelled
    func completed_OEVC(wasSaved:Bool)
}

class OrgEditViewController: UIViewController {
    // caller pre-set member variables
    internal var mOEVCdelegate:OEVC_Delegate?               // delegate callback if saved or cancelled
    public var mAction:OEVC_Actions = .Add                  // .Add or .Change
    public var mEdit_orgRec:RecOrganizationDefs? = nil      // the source OrgRecord when doing a .Change; will NOT be changed; is a COPY not a reference

    // member variables
    internal var mLocalEFP:EntryFormProvisioner? = nil                      // local EFP to drive the local OrgTitle View
    internal var mWorking_orgRec:RecOrganizationDefs? = nil                 // edited OrgRecord
    
    // member constants and other static content
    private let mCTAG:String = "VCSOE"
    internal weak var mOrgTitleViewController:OrgTitleViewController? = nil // pointer to the local OrgTitle View; needed to trigger refreshes of it
    private weak var mOrgEditFormVC:OrgEditFormViewController? = nil        // pointer to the containerViewController of the Form
    internal enum OEVC_Actions {
        case Add, Change
    }
    
    // outlets to screen controls
    @IBOutlet weak var navbar_item: UINavigationItem!
    @IBOutlet weak var button_forms: UIBarButtonItem!
    
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        // cancel button pressed;
        // first finalize the LangRegion settings to what is shown on the Form so as to detect changes
        do {
            try self.mOrgEditFormVC!.finalizeLangRegions()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).saveRecordToDB", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Filesystem Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
        
        // has anything changed?
        if self.mWorking_orgRec!.hasChanged(existingEntry: self.mEdit_orgRec!) {
            // yes, warn the end-user
            AppDelegate.showYesNoDialog(vc:self, title:NSLocalizedString("Cancel Confirmation", comment:""), message:NSLocalizedString("If you Cancel you will lose your changes; are you sure?", comment:""), buttonYesText:NSLocalizedString("Yes, Cancel", comment:""), buttonNoText:NSLocalizedString("No", comment:""), callbackAction:1, callbackString1:nil, callbackString2:nil, completion: {(vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                // callback from the yes/no dialog upon one of the buttons being pressed
                if theResult {
                    // answer was Yes, Cancel
                    if self.mOEVCdelegate != nil { self.mOEVCdelegate!.completed_OEVC(wasSaved:false) }
                    self.navigationController?.popViewController(animated:true)
                }
                return  // from callback
            })
        } else {
            // nothing has changed; just do an immediate cancel
            if self.mOEVCdelegate != nil { self.mOEVCdelegate!.completed_OEVC(wasSaved:false) }
            self.navigationController?.popViewController(animated:true)
        }
    }
    
    @IBAction func button_forms_pressed(_ sender: UIBarButtonItem) {
        // open the Forms Mgmt view
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let nextViewController:FormsMgmtViewController = storyboard.instantiateViewController(withIdentifier:"VC FormsMgmt") as! FormsMgmtViewController
        nextViewController.mFor_orgRec = RecOrganizationDefs(existingRec: self.mEdit_orgRec!)
        self.navigationController?.pushViewController(nextViewController, animated:true)
    }
    
    @IBAction func button_save_pressed(_ sender: UIBarButtonItem) {
        // save button pressed
        let msg:String = self.validateEntries()
        if (msg != "") {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message:msg, buttonText: NSLocalizedString("Okay", comment:""))
        } else {
            let success:Bool = self.saveRecordToDB()
            if success {
                if self.mOEVCdelegate != nil { self.mOEVCdelegate!.completed_OEVC(wasSaved:true) }
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
        self.mOrgTitleViewController = nil
        self.mOrgEditFormVC = nil
        for childVC in children {
            let vc1:OrgTitleViewController? = childVC as? OrgTitleViewController
            let vc2:OrgEditFormViewController? = childVC as? OrgEditFormViewController
            if vc1 != nil { self.mOrgTitleViewController = vc1 }
            if vc2 != nil { self.mOrgEditFormVC = vc2 }
        }
        
        // preparations if an add or a change
        if self.mAction == .Change {
            // its a change, so need to prepare to pre-load all the fields with the Org's existing definitions
            button_forms?.isEnabled = true
            button_forms?.title = NSLocalizedString("Forms", comment:"")
            assert(self.mEdit_orgRec != nil, "\(self.mCTAG).viewDidLoad self.mEdit_orgRec == nil")    // this is a programming error
            if self.mWorking_orgRec != nil { self.mWorking_orgRec = nil }
            self.mWorking_orgRec = RecOrganizationDefs(existingRec:mEdit_orgRec!)   // make a copy of the existing Org rec
            do {
                try self.mEdit_orgRec!.loadLangRecs(method: "\(self.mCTAG).viewDidLoad.change.1")
                try self.mWorking_orgRec!.loadLangRecs(method: "\(self.mCTAG).viewDidLoad.change.2")
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewDidLoad.change", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                self.mAction = .Add // auto-force to an Add
            }
            self.navbar_item.title = NSLocalizedString("Edit Org", comment:"")
        }
        if self.mAction == .Add {
            // its an add
            button_forms?.isEnabled = false
            button_forms?.title = ""
            if self.mEdit_orgRec != nil { self.mEdit_orgRec = nil }
            if self.mWorking_orgRec == nil {
                self.mWorking_orgRec = RecOrganizationDefs(org_code_sv_file: "")    // make am empty Org rec
                do {
                    try self.mWorking_orgRec!.loadLangRecs(method: "\(self.mCTAG).viewDidLoad.add")
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewDidLoad.add", errorStruct: error, extra: nil)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
            self.mEdit_orgRec = RecOrganizationDefs(existingRec: self.mWorking_orgRec!)     // make a deep copy
            self.navbar_item.title = NSLocalizedString("Add Org", comment:"")
            self.mWorking_orgRec!.rOrg_Email_Subject = NSLocalizedString("Contacts collected from eContact Collect", comment:"do not translate the portion: eContact Collect")
        }
        
        // setup a local EFP for the OrgTitle VC; it will mimic all changes to the mWorking_orgRec when its refresh() is called
        assert(self.mWorking_orgRec != nil, "\(self.mCTAG).viewDidLoad self.mWorking_orgRec == nil")    // this is a programming error
        assert(self.mOrgTitleViewController != nil, "\(self.mCTAG).viewDidLoad self.mOrgTitleViewController == nil")    // this is a programming error
        self.mLocalEFP = EntryFormProvisioner(forOrgRecOnly: self.mWorking_orgRec!)
        self.mOrgTitleViewController!.mEFP = self.mLocalEFP
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    // remember this will be called upon return from the image chooser dialog
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when the view has fully appeared
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)
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
            self.mEdit_orgRec = nil
            self.mWorking_orgRec = nil
            self.mLocalEFP?.clear()
            self.mOrgEditFormVC?.clearVC()
            self.mLocalEFP = nil
            self.mOrgTitleViewController = nil
            self.mOrgEditFormVC = nil
            self.mOEVCdelegate = nil
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed \(self)")
        }
        super.viewDidDisappear(animated)
    }
    
    ///////////////////////////////////////////////////////////////////
    // Data entry validation and saves to database
    ///////////////////////////////////////////////////////////////////
    
    // validate entries
    // return "" if all validations passed, else an error message about what validation failed
    private func validateEntries() -> String {
        let validationError = self.mOrgEditFormVC!.form.validate()
        if validationError.count > 0 {
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            return message
        }
        
        // safety double-checks
        if self.mWorking_orgRec!.rOrg_Code_For_SV_File.isEmpty {
            return NSLocalizedString("Organization short code cannot be blank", comment:"")
        }
        if self.mWorking_orgRec!.rOrg_Code_For_SV_File.rangeOfCharacter(from: AppDelegate.mAcceptableNameChars.inverted) != nil {
            return NSLocalizedString("Organization short code can only contain letters, digits, space, or _ . + -", comment:"")
        }
        
        // need to ensure this Org name does not already exist in the database
        if self.mAction == .Add {
            var orgRec:RecOrganizationDefs?
            do {
                orgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: self.mWorking_orgRec!.rOrg_Code_For_SV_File)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).validateEntries", errorStruct: error, extra: nil)
                return NSLocalizedString("Database error occurred while verifying inputs", comment:"")
        }
        if orgRec != nil {
            return NSLocalizedString("Organization short code already exists in the database", comment:"") }
        }
        return ""
    }
    
    // save the entered or updated profile information to the database;
    // return true if successful or false if failed
    private func saveRecordToDB() -> Bool {
        // finalize the LangRegion settings to what is shown on the Form
        do {
            try self.mOrgEditFormVC!.finalizeLangRegions()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).saveRecordToDB", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Filesystem Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        
        switch self.mAction {
        case .Add:
//debugPrint("\(self.mCTAG).saveRecordToDB.Add STARTED")
             do {
                let _ = try self.mWorking_orgRec!.saveNewToDB()     // this will auto-add all non-deleted internal RecOrganizationLangs
             } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).saveRecordToDB.Add", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                return false
             }

            (UIApplication.shared.delegate as! AppDelegate).checkCurrentOrg(withOrgRec: self.mWorking_orgRec!)
            return true
         
        case .Change:
//debugPrint("\(self.mCTAG).saveRecordToDB.Change STARTED")
            if self.mWorking_orgRec!.rOrg_Code_For_SV_File == self.mEdit_orgRec!.rOrg_Code_For_SV_File {
                // the key has not been changed
                do {
                    let _ = try self.mWorking_orgRec!.saveChangesToDB(originalOrgRec:self.mEdit_orgRec!)  // this will auto-add/update/delete internal RecOrganizationLangs
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).saveRecordToDB.Change", errorStruct: error, extra: nil)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    return false
                }
         
                // check the App's current Org record
                (UIApplication.shared.delegate as! AppDelegate).checkCurrentOrg(withOrgRec: self.mWorking_orgRec!)
                return true
            } else {
                // ?? the key has been changed; presently not supported
            }
            return false
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// Child FormViewController
/////////////////////////////////////////////////////////////////////////

class OrgEditFormViewController: FormViewController {
    // member variables
    private var mFirstTime:Bool = true
    private var mFormIsBuilt:Bool = false
    private weak var mSection4:Section? = nil
    private var mLangRows:OrgEditFormLangFields? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCSOEF"
    private weak var mOrgEditVC:OrgEditViewController? = nil
    
    private let TitleModeStrings:[String] = [NSLocalizedString("Title Only", comment:""),
                                            NSLocalizedString("Logo Only", comment:""),
                                            NSLocalizedString("50/50 Title and Logo", comment:""),
                                            NSLocalizedString("Full Logo, Title remains", comment:""),
                                            NSLocalizedString("Full Title, Logo remains", comment:"")]
    private func titleModeInt(fromString:String) -> Int {
        switch fromString {
        case TitleModeStrings[0]: return 0
        case TitleModeStrings[1]: return 1
        case TitleModeStrings[2]: return 2
        case TitleModeStrings[3]: return 3
        case TitleModeStrings[4]: return 4
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
    }
    
    // called by the framework when the view will re-appear;
    // remember this will be called upon return from the image chooser dialog
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)

        // locate our parent
        self.mOrgEditVC = (self.parent as! OrgEditViewController)

        // build the form but without content values to support various PushRows
        self.buildForm()
        
        // set the form's values
        tableView.setEditing(true, animated: false) // this must be done in viewWillAppear() is within a ContainerView and using .Reorder MultivaluedSections
        self.adjustForm()
        self.revalueForm()
        self.mFirstTime = false
    }
        
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // clear out the Form so it will be deinit
    public func clearVC() {
        self.mLangRows?.clear()
        form.removeAll()
        tableView.reloadData()
        self.mFormIsBuilt = false
        self.mLangRows = nil
        self.mOrgEditVC = nil
    }
    
    // although the internal RecOrganizationLangs and the rOrg_LangRegionCodes_Supported SHOULD be already correct,
    // we will re-evaluate and reset all of them according to the final state of the form's fields
    public func finalizeLangRegions() throws {
        do {
            try self.mLangRows!.finalizeLangRegions()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).finalizeLangRegions")
            throw appError
        } catch { throw error }
    }

    // build the form
    private func buildForm() {
        if self.mFormIsBuilt { return }
        form.removeAll()
        tableView.reloadData()
        
        let section1 = Section(NSLocalizedString("Organization's Overall Settings", comment:""))
        form +++ section1
        section1 <<< TextRow() {
            $0.tag = "org_short_name"
            $0.title = NSLocalizedString("Short Org code", comment:"")
            $0.add(rule: RuleRequired(msg: NSLocalizedString("Organization short code cannot be blank", comment:"")))
            $0.add(rule: RuleValidChars(acceptableChars: AppDelegate.mAcceptableNameChars, msg: NSLocalizedString("Organization short code can only contain letters, digits, space, or _ . + -", comment:"")))
            $0.validationOptions = .validatesAlways
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { [weak self] chgRow in
                let _ = chgRow.validate()
                if chgRow.isValid {
                    if chgRow.value != nil {
                        self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Code_For_SV_File = chgRow.value!
                    }
                }
        }
        section1 <<< EmailRow() {
            $0.tag = "email_to"
            $0.title = NSLocalizedString("Email TO", comment:"")
            }.cellUpdate { cell, row in
                cell.textField.font = .systemFont(ofSize: 14.0)
            }.onChange { [weak self] chgRow in
                self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Email_To = chgRow.value
        }
        section1 <<< EmailRow() {
            $0.tag = "email_cc"
            $0.title = NSLocalizedString("Email CC", comment:"")
            }.cellUpdate { cell, row in
                cell.textField.font = .systemFont(ofSize: 14.0)
            }.onChange { [weak self] chgRow in
                self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Email_CC = chgRow.value
        }
        section1 <<< TextRow() {
            $0.tag = "email_subject"
            $0.title = NSLocalizedString("Subject", comment:"")
            }.cellUpdate { cell, row in
                cell.textField.font = .systemFont(ofSize: 14.0)
            }.onChange { [weak self] chgRow in
                self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Email_Subject = chgRow.value
        }
        
        // add in the standard language Eureka Rows that this class and WizOrgDefine11ViewController can use
        self.mLangRows = OrgEditFormLangFields(form: form, orgRec: self.mOrgEditVC!.mWorking_orgRec!, efp: self.mOrgEditVC!.mLocalEFP!, changeCallback: { self.adjustForm() } )
        self.mLangRows!.addFormLangRows()
        
        let section3 = Section(NSLocalizedString("Organization Identity", comment:""))
        form +++ section3
        section3 <<< SegmentedRowExt<String>() {
            $0.tag = "show_lang"
            $0.title = NSLocalizedString("Show:", comment:"")
            $0.hidden = "$button_enable_multiLang == false"
            $0.displayValueFor = { set in
                    if set == nil { return nil }
                    return set!.map { AppDelegate.makeFullDescription(forLangRegion: $0, noCode: true) }.joined(separator: ", ")
                }
            }.cellUpdate { cell, row in
                cell.segmentedControl?.tintColor = UIColor.blue
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mOrgEditVC!.mLocalEFP!.forceChange(toLangRegion: chgRow.value!.first!)
                    self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                }
        }
        section3 <<< InlineColorPickerRow() {
            $0.tag = "org_shown_title_text_color"
            $0.title = "Text color"
            $0.isCircular = false
            //$0.showsCurrentSwatch = true
            $0.showsPaletteNames = true
            } .onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Visuals.rOrgTitle_TitleText_Color = chgRow.value!
                    self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                }
        }
        section3 <<< FontPickerInlineRow() {
            $0.tag = "org_shown_title_text_font"
            $0.title = "Text font"
            } .onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Visuals.rOrgTitle_TitleText_Font = chgRow.value!
                    self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                }
        }
        section3 <<< ImageRow() {
            $0.tag = "org_shown_logo"
            $0.title = NSLocalizedString("Logo (optional)", comment:"")
            $0.clearAction = ImageClearAction.yes(style: .destructive)
            }.onChange { [weak self] chgRow in
                if chgRow.value == nil {
                    // end-user has removed the image
                    self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Logo_Image_PNG_Blob = nil
                    self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                } else {
                    // end-user has chosen an image
                    if chgRow.userPickerInfo != nil {
                        if var pickedImage = chgRow.userPickerInfo![UIImagePickerController.InfoKey.originalImage] as? UIImage {
                            // an image was indeed returned;
                            // the view height for logos and titles is 50 ... for 3x imagery thus we need 150 height
                            let newHeight:CGFloat = 150.0
                            if pickedImage.size.height != newHeight {
                                let newWidth:CGFloat = pickedImage.size.width * (newHeight / pickedImage.size.height)
                                UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
                                pickedImage.draw(in:CGRect(x:0.0, y:0.0, width:newWidth, height:newHeight))
                                if let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
                                    pickedImage = newImage
                                }
                                UIGraphicsEndImageContext()
                            }
                            self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Logo_Image_PNG_Blob = pickedImage.pngData()
                            self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                        }
                    }
                }
        }
        section3 <<< InlineColorPickerRow() {
            $0.tag = "org_shown_back_color"
            $0.title = "Background color"
            $0.isCircular = false
            //$0.showsCurrentSwatch = true
            $0.showsPaletteNames = true
            } .onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Visuals.rOrgTitle_Background_Color = chgRow.value!
                    self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                }
        }
        section3 <<< PickerInlineRow<String>() {
            $0.tag = "org_shown_mode"
            $0.title = NSLocalizedString("Show as:", comment:"")
            $0.options = TitleModeStrings
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    switch self!.titleModeInt(fromString:chgRow.value!)
                    {
                    case 0: self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Title_Mode = .ONLY_TITLE
                    case 1: self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Title_Mode = .ONLY_LOGO
                    case 2: self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Title_Mode = .BOTH_50_50
                    case 3: self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Title_Mode = .BOTH_LOGO_DOMINATES
                    case 4: self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Title_Mode = .BOTH_TITLE_DOMINATES
                    default: self!.mOrgEditVC!.mWorking_orgRec!.rOrg_Title_Mode = .ONLY_TITLE
                    }
                    self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                }
        }
        
        let section4 = Section(NSLocalizedString("Organization Title(s)", comment:""))
        form +++ section4
        self.mSection4 = section4
        
        self.mFormIsBuilt = true
    }

    // adjust the form based upon changes in supported languages; will also be called the first time the Form is built
    private func adjustForm() {
        self.mSection4!.removeAll()  // remove all the Org Title Rows in the 4th section
        var langOptions:[String] = []
        
        // add the SV-File language to the SegmentedRow and an Org Title
        let langRegionCode:String = self.mOrgEditVC!.mWorking_orgRec!.rOrg_LangRegionCode_SV_File
        langOptions.append(self.mOrgEditVC!.mWorking_orgRec!.rOrg_LangRegionCode_SV_File)
        self.mSection4! <<< TextAreaRowExt() {
            $0.tag = "org_shown_titles_\(langRegionCode)"
            $0.title = NSLocalizedString("Org Title for ", comment:"") + AppDelegate.makeFullDescription(forLangRegion: langRegionCode)
            do {
                $0.value = try self.mOrgEditVC!.mWorking_orgRec!.getOrgTitleShown(langRegion: langRegionCode)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).adjustForm", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
            $0.textAreaHeight = .fixed(cellHeight: 50)
            $0.textAreaWidth = .fixed(cellWidth: 300)
            }.cellUpdate { cell, row in
                cell.textView.autocapitalizationType = .words
                cell.textView.font = .boldSystemFont(ofSize: 17.0)
                cell.textView.layer.cornerRadius = 0
                cell.textView.layer.borderColor = UIColor.gray.cgColor
                cell.textView.layer.borderWidth = 1
            }.onChange { [weak self] chgRow in
                do {
                    try self!.mOrgEditVC!.mWorking_orgRec!.setOrgTitleShown_Editing(langRegion: langRegionCode, title: chgRow.value)
                    self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).adjustForm", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                    AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
        }

        if self.mLangRows!.mSupportingMultLangs {
            // multi-language support has been turned on; the SegmentedRow will automatically be un-hidden
            for langRegionCode in self.mOrgEditVC!.mWorking_orgRec!.rOrg_LangRegionCodes_Supported {
                // has this langRegion code already been found?
                if !langOptions.contains(langRegionCode) {
                    // no, add the langRegion to the SegmentedRow's list
                    langOptions.append(langRegionCode)
                    
                    // emplace an Org Title Row for the language
                    self.mSection4! <<< TextAreaRowExt() {
                        $0.tag = "org_shown_titles_\(langRegionCode)"
                        $0.title = NSLocalizedString("Org Title for ", comment:"") + AppDelegate.makeFullDescription(forLangRegion: langRegionCode)
                        do {
                            $0.value = try self.mOrgEditVC!.mWorking_orgRec!.getOrgTitleShown(langRegion: langRegionCode)
                        } catch {
                            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).adjustForm", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                        }
                        $0.textAreaHeight = .fixed(cellHeight: 50)
                        $0.textAreaWidth = .fixed(cellWidth: 300)
                        }.cellUpdate { cell, row in
                            cell.textView.autocapitalizationType = .words
                            cell.textView.font = .boldSystemFont(ofSize: 17.0)
                            cell.textView.layer.cornerRadius = 0
                            cell.textView.layer.borderColor = UIColor.gray.cgColor
                            cell.textView.layer.borderWidth = 1
                        }.onChange { [weak self] chgRow in
                            do {
                                try self!.mOrgEditVC!.mWorking_orgRec!.setOrgTitleShown_Editing(langRegion: langRegionCode, title: chgRow.value)
                                self!.mOrgEditVC!.mOrgTitleViewController!.refresh()
                            } catch {
                                AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).adjustForm", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                                AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                            }
                    }
                }
            }
            
            // set the SegmentedRow's options
            let segRow:SegmentedRowExt<String> = form.rowBy(tag: "show_lang") as! SegmentedRowExt<String>
            segRow.options = langOptions
            segRow.updateCell()
        }
    }
    
    // insert current working values into all the form's fields
    // this is done both after initial form creation and any re-display of the form;
    // WARNING: must not rebuild the form as this breaks the MultivaluedSection PushRow return:
    //          self.viewWillAppear() and self.viewDidAppear() WILL be invoked upon return from the PushRow's view controller
    private func revalueForm() {
        // step through all the rows (except the MultivaluedSection
        for hasRow in form.allRows {    // need to include hidden rows
            switch hasRow.tag {
            case "org_short_name":
                if self.mOrgEditVC!.mAction == .Change { (hasRow as! TextRow).disabled = true;  (hasRow as! TextRow).evaluateDisabled() }
                (hasRow as! TextRow).value = self.mOrgEditVC!.mWorking_orgRec!.rOrg_Code_For_SV_File
                break
            case "email_to":
                (hasRow as! EmailRow).value = self.mOrgEditVC!.mWorking_orgRec!.rOrg_Email_To
                break
            case "email_cc":
                (hasRow as! EmailRow).value = self.mOrgEditVC!.mWorking_orgRec!.rOrg_Email_CC
                break
            case "email_subject":
                (hasRow as! TextRow).value = self.mOrgEditVC!.mWorking_orgRec!.rOrg_Email_Subject
                break
            case "show_lang":
                (hasRow as! SegmentedRowExt<String>).options = self.mOrgEditVC!.mWorking_orgRec!.rOrg_LangRegionCodes_Supported
                (hasRow as! SegmentedRowExt<String>).value = Set<String>([self.mOrgEditVC!.mWorking_orgRec!.rOrg_LangRegionCodes_Supported[0]])
                break
            case "org_shown_title_text_color":
                (hasRow as! InlineColorPickerRow).value = self.mOrgEditVC!.mWorking_orgRec!.rOrg_Visuals.rOrgTitle_TitleText_Color
                break
            case "org_shown_title_text_font":
                (hasRow as! FontPickerInlineRow).value = self.mOrgEditVC!.mWorking_orgRec!.rOrg_Visuals.rOrgTitle_TitleText_Font
                break
            case "org_shown_logo":
                if self.mOrgEditVC!.mWorking_orgRec!.rOrg_Logo_Image_PNG_Blob == nil {
                    (hasRow as! ImageRow).value = nil
                } else {
                    (hasRow as! ImageRow).value = UIImage(data:self.mOrgEditVC!.mWorking_orgRec!.rOrg_Logo_Image_PNG_Blob!)!
                }
                break
            case "org_shown_back_color":
                (hasRow as! InlineColorPickerRow).value = self.mOrgEditVC!.mWorking_orgRec!.rOrg_Visuals.rOrgTitle_Background_Color
                break
            case "org_shown_mode":
                (hasRow as! PickerInlineRow<String>).value = TitleModeStrings[self.mOrgEditVC!.mWorking_orgRec!.rOrg_Title_Mode.rawValue]
                break
            default:
                if hasRow.tag != nil {
                    if hasRow.tag!.starts(with: "org_shown_titles_") {
                        let pastIndex = hasRow.tag!.index(hasRow.tag!.startIndex, offsetBy: 17)
                        let langRegionCode = String(hasRow.tag![pastIndex...])
                        do {
                            (hasRow as! TextAreaRowExt).value = try self.mOrgEditVC!.mWorking_orgRec!.getOrgTitleShown(langRegion: langRegionCode)
                        } catch {
                            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).revalueForm", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                        }
                    }
                }
                break
            }
            hasRow.updateCell()
        }
        
        // do a revalue of the Language Rows
        self.mLangRows!.revalueForm(firstTime: self.mFirstTime)
    }
    
    // make the LabelRow associated with the LangRegion of the SV-File not deletable
    override open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let superStyle = super.tableView(tableView, editingStyleForRowAt: indexPath)
        if self.mLangRows == nil { return superStyle }
        return self.mLangRows!.editingStyleForRowAt(indexPath: indexPath, superStyle: superStyle)
    }
    
    // this function will get invoked just before the move process
    // after this callback will be an immediate delete "rowsHaveBeenRemoved()" then insert "rowsHaveBeenAdded()"
    override func rowsWillBeMoved(movedRows:[BaseRow], sourceIndexes:[IndexPath], destinationIndexes:[IndexPath]) {
        super.rowsWillBeMoved(movedRows:movedRows, sourceIndexes:sourceIndexes, destinationIndexes:destinationIndexes)
        self.mLangRows?.rowsWillBeMoved(movedRows:movedRows, sourceIndexes:sourceIndexes, destinationIndexes:destinationIndexes)
    }
    
    // this function will get invoked when any rows are deleted or HIDDEN anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        self.mLangRows?.rowsHaveBeenRemoved(rows, at: indexes)
    }
    
    // this function will get invoked when any rows are added or UNHIDDEN anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenAdded(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenAdded(rows, at: indexes)
        self.mLangRows?.rowsHaveBeenAdded(rows, at: indexes)
    }
}

// class to create and manage the Org Language Fields;
// separate class is necessary because identical logic is used in WizOrgDefine11ViewController
public class OrgEditFormLangFields {
    // class members
    public var mSupportingMultLangs:Bool = false
    public weak var mMVS_langs:MultivaluedSection? = nil
    private var mMovesInProcess:Int = 0
    
    // member constants and other static content
    private let mCTAG:String = "VCSOEFLF"
    private weak var mForm:Form?
    private weak var mOrgRec:RecOrganizationDefs?
    private weak var mEFP:EntryFormProvisioner?
    private var mChangesCallback:(()->Void)?

    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // constructor
    public init(form:Form, orgRec:RecOrganizationDefs, efp:EntryFormProvisioner?, changeCallback:(()->Void)?) {
        self.mForm = form
        self.mOrgRec = orgRec
        self.mEFP = efp
        self.mChangesCallback = changeCallback
    }
    
    // clear out the class so it will deinit
    public func clear() {
        self.mMVS_langs = nil
    }
    
    // add the proper Rows to the Eureka Form
    public func addFormLangRows() {
        let (controlPairs, sectionMap, sectionTitles) = AppDelegate.getAvailableLangs()

        let nextSection = Section(NSLocalizedString("Multi-Language Options", comment:""))
        self.mForm! +++ nextSection

        nextSection <<< SwitchRow("button_enable_multiLang") {
            $0.title = NSLocalizedString("Support multiple languages?", comment:"")
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    if chgRow.value! != self!.mSupportingMultLangs {
                        self!.mSupportingMultLangs = chgRow.value!
                        self!.mChangesCallback?()   // not used on WizOrgDefine11ViewController
                        self!.mEFP?.reassess()      // not used on WizOrgDefine11ViewController
                    }
                }
        }
        
        nextSection <<< PushRow<String>() {
            $0.tag = "lang_sv_file"
            $0.title = NSLocalizedString("SV-File Language", comment:"")
            $0.selectorTitle = NSLocalizedString("Choose one", comment:"")
            $0.options = controlPairs.map { $0.codeString }
            $0.hidden = "$button_enable_multiLang == false"
            $0.displayValueFor = { valueString in
                if valueString == nil { return nil }
                return CodePair.findValue(pairs: controlPairs, givenCode: valueString!)
            }
            }.onPresent { _, presentVC in
                presentVC.sectionKeyForValue = { oTitleShown in
                    return sectionMap[oTitleShown] ?? ""
                }
                presentVC.sectionHeaderTitleForKey = { sKey in
                    return sectionTitles[sKey]
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    // new SV-File language has been chosen
                    self!.mOrgRec!.rOrg_LangRegionCode_SV_File = chgRow.value!
                    var orgLangRec = self!.mOrgRec!.getLangRec(forLangRegion: self!.mOrgRec!.rOrg_LangRegionCode_SV_File, includingDeleted: true)
                    if orgLangRec != nil {
                        if orgLangRec!.mDuringEditing_isDeleted {
                            // its record is present but deleted so undelete it and get it shown in the MVS
                            self!.mOrgRec!.markUndeletedLangRec(forLangRegion: self!.mOrgRec!.rOrg_LangRegionCode_SV_File)
                            // create a MVS row for this shown language
                            let br = self!.makeLangButtonRow(forLangRec: orgLangRec!)
                            if self!.mForm!.rowBy(tag: br.tag!) == nil {
                                let ar = self!.mForm!.rowBy(tag: "add_new_lang")
                                do {
                                    try self!.mMVS_langs!.insert(row: br, before: ar!)
                                } catch {
                                    AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).addFormLangRows", errorStruct: error, extra: nil)
                                    // do not show an error to the end-user
                                }
                            }
                        }
                    } else {
                        // a langRegion record does not yet exist for this new SV-File langRegion; create it and get it shown in the MVS
                        let inx = self!.mOrgRec!.addNewPlaceholderLangRec(forLangRegion: self!.mOrgRec!.rOrg_LangRegionCode_SV_File)
                        orgLangRec = self!.mOrgRec!.mOrg_Lang_Recs![inx]
                        // create a MVS row for this shown language
                        let br = self!.makeLangButtonRow(forLangRec: orgLangRec!)
                        if self!.mForm!.rowBy(tag: br.tag!) == nil {
                            let ar = self!.mForm!.rowBy(tag: "add_new_lang")
                            do {
                                try self!.mMVS_langs!.insert(row: br, before: ar!)
                            } catch {
                                AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).addFormLangRows", errorStruct: error, extra: nil)
                                // do not show an error to the end-user
                            }
                        }
                    }
                    self!.mChangesCallback?()   // not used on WizOrgDefine11ViewController
                    self!.mEFP?.reassess()      // not used on WizOrgDefine11ViewController
                }
        }
        
        let mvs_langs = MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder],
             header: NSLocalizedString("Shown languages in order to-be-shown", comment:"")) { mvSection in
                mvSection.tag = "mvs_langs"
                mvSection.showInsertIconInAddButton = false
                mvSection.addButtonProvider = { [weak self] section in
                    return PushRow<String>(){ row in
                        // !!! MMM use of PushRow is an extension to the Eureka code
                        // REMEMBER: CANNOT do a buildForm() from viewWillAppear() ... the form must remain intact for this to work
                        // must buildForm() from viewDidLoad() then populate field values separately
                        row.title = NSLocalizedString("Select new language to add", comment:"")
                        row.tag = "add_new_lang"
                        row.selectorTitle = NSLocalizedString("Choose one", comment:"")
                        row.options = controlPairs.map { $0.codeString }
                        row.displayValueFor = { valueString in
                            if valueString == nil { return nil }
                            return CodePair.findValue(pairs: controlPairs, givenCode: valueString!)
                        }
                        }.cellUpdate { updCell, updRow in
                            updCell.textLabel?.textColor = UIColor(hex6: 0x007AFF)
                            updCell.imageView?.image = #imageLiteral(resourceName: "Add")
                        }.onPresent { _, presentVC in
                            presentVC.sectionKeyForValue = { oTitleShown in
                                return sectionMap[oTitleShown] ?? ""
                            }
                            presentVC.sectionHeaderTitleForKey = { sKey in
                                return sectionTitles[sKey]
                            }
                        }.onChange { [weak self] chgRow in
                            // PushRow has returned a value selected from the PushRow's view controller;
                            // note our context is still within the PushRow's view controller, not the original FormViewController
                            if chgRow.value != nil {   // this must be present to prevent an infinite loop
                                guard let tableView = chgRow.cell.formViewController()?.tableView, let indexPath = chgRow.indexPath else { return }
                                if self!.mOrgRec!.existsLangRec(forLangRegion: chgRow.value!) { return }
                                DispatchQueue.main.async {
                                    // must dispatch this so the PushRow's SelectorViewController is dismissed first and the UI is back at the main FormViewController
                                    // this triggers multivaluedRowToInsertAt() below
                                    chgRow.cell.formViewController()?.tableView(tableView, commit: .insert, forRowAt: indexPath)
                                }
                            }
                    }
                }  // end of addButtonProvider
                mvSection.multivaluedRowToInsertAt = { [weak self] index in
                    // a verified-new langRegion code was chosen by the end-user; get it from the PushRoc
                    let fromPushRow = self!.mForm!.rowBy(tag: "add_new_lang") as! PushRow<String>
                    let langRegionCode:String = fromPushRow.value!
                    
                    // add the new langugage record
                    let inx:Int = self!.mOrgRec!.addNewPlaceholderLangRec(forLangRegion: langRegionCode)
                    self!.mChangesCallback?()
                    self!.mEFP?.reassess()   // not used on WizOrgDefine11ViewController
                    
                    // create a new ButtonRow based upon the new entry
                    let newRow = self!.makeLangButtonRow(forLangRec: self!.mOrgRec!.mOrg_Lang_Recs![inx])
                    fromPushRow.value = nil     // clear out the PushRow's value so this newly chosen item does not remain "selected"
                    fromPushRow.reload()        // note this will re-trigger .onChange in the PushRow so must ignore that re-trigger else infinite loop
                    return newRow               // self.rowsHaveBeenAdded() will get invoked after this point
                }
        }
        mvs_langs.hidden = "$button_enable_multiLang == false"
        self.mForm! +++ mvs_langs
        self.mMVS_langs = mvs_langs
    }
    
    // create the pretty button row needed for existing and new FormField records
    private func makeLangButtonRow(forLangRec:RecOrganizationLangs) -> LabelRow {
        return LabelRow() { row in
            row.tag = "LC,\(forLangRec.rOrgLang_LangRegionCode)"
            row.cellStyle = UITableViewCell.CellStyle.subtitle
            row.title = AppDelegate.makeFullDescription(forLangRegion: forLangRec.rOrgLang_LangRegionCode)
            row.retainedObject = forLangRec
            }.cellUpdate { cell, row in
                // create and show the second line of text in the row
                if row.retainedObject != nil {
                    let langRec:RecOrganizationLangs = (row.retainedObject as! RecOrganizationLangs)
                    cell.detailTextLabel?.text = "\(langRec.rOrgLang_Lang_Title_Shown), en=\(langRec.rOrgLang_Lang_Title_EN)"
                }
        }
    }
    
    // set all the values for the Language rows
    // this is done both after initial form creation and any re-display of the form;
    // WARNING: must not rebuild the form as this breaks the MultivaluedSection PushRow return:
    //          self.viewWillAppear() and self.viewDidAppear() WILL be invoked upon return from the PushRow's view controller
    public func revalueForm(firstTime: Bool) {
        // step through all the rows (except the MultivaluedSection
        for hasRow in self.mForm!.allRows {    // need to include hidden rows
            switch hasRow.tag {
            case "button_enable_multiLang":
                if firstTime {
                    if self.mOrgRec!.rOrg_LangRegionCodes_Supported.count > 1 { self.mSupportingMultLangs = true }
                    else { self.mSupportingMultLangs = false }
                }
                (hasRow as! SwitchRow).value = self.mSupportingMultLangs
                hasRow.updateCell()
                break
                
            case "lang_sv_file":
                (hasRow as! PushRow<String>).value = self.mOrgRec!.rOrg_LangRegionCode_SV_File
                hasRow.updateCell()
                break
                
            default:
                break
            }
        }
        
        // now fill in the MultivaluedSections with any pre-existing fields and therefore matching rows; fix any dis-syncs
        for hasSection in self.mForm!.allSections {
            switch hasSection.tag {
            case "mvs_langs":
                if firstTime {
                    // first put in all the records listed in order in rOrg_LangRegionCodes_Supported;
                    // since the SV-File langRegion row is filled in first, it likely auto-created a row for its langRegion already
                    if self.mOrgRec!.mOrg_Lang_Recs == nil { self.mOrgRec!.mOrg_Lang_Recs = [] }
                    for langRegionCode:String in self.mOrgRec!.rOrg_LangRegionCodes_Supported {
                        let foundRow:LabelRow? = self.mMVS_langs!.rowBy(tag: "LC,\(langRegionCode)")
                        if foundRow == nil {
                            var langRec:RecOrganizationLangs? = self.mOrgRec!.getLangRec(forLangRegion: langRegionCode, includingDeleted: true)
                            if langRec == nil {
                                // its a shown langRegion but its LangRegion record is truely missing; manually add the missing record
                                langRec = RecOrganizationLangs(langRegion_code: langRegionCode, withOrgRec: self.mOrgRec!)
                                self.mOrgRec!.mOrg_Lang_Recs!.append(langRec!)
                            } else if langRec!.mDuringEditing_isDeleted {
                                // it exists but is marked as deleted but is still in rOrg_LangRegionCodes_Supported
                                langRec!.mDuringEditing_isDeleted = false
                            }
                            // create a MVS row for this shown language
                            let br = self.makeLangButtonRow(forLangRec: langRec!)
                            let ar = self.mForm!.rowBy(tag: "add_new_lang")
                            do {
                                try self.mMVS_langs!.insert(row: br, before: ar!)
                            } catch {
                                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).revalueForm", errorStruct: error, extra: nil)
                                // do not show an error to the end-user
                            }
                        }
                    }
                    // now look if there are any straggler LangRegion records that are NOT in rOrg_LangRegionCodes_Supported;
                    // this indicates database mis-sync and we will bring them back into place
                    if self.mOrgRec!.mOrg_Lang_Recs != nil {
                        for langRec:RecOrganizationLangs in self.mOrgRec!.mOrg_Lang_Recs! {
                            if !langRec.mDuringEditing_isDeleted {
                                let foundRow:LabelRow? = self.mMVS_langs!.rowBy(tag: "LC,\(langRec.rOrgLang_LangRegionCode)")
                                if foundRow == nil {
                                    self.mOrgRec!.rOrg_LangRegionCodes_Supported.append(langRec.rOrgLang_LangRegionCode)
                                    let br = self.makeLangButtonRow(forLangRec: langRec)
                                    let ar = self.mForm!.rowBy(tag: "add_new_lang")
                                    do {
                                        try self.mMVS_langs!.insert(row: br, before: ar!)
                                    } catch {
                                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).revalueForm", errorStruct: error, extra: nil)
                                        // do not show an error to the end-user
                                    }
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
    
    // although the internal RecOrganizationLangs and the rOrg_LangRegionCodes_Supported SHOULD be already correct,
    // we will re-evaluate and reset all of them according to the final state of the form's fields and
    // ensure all placeholder language records are finalized
    public func finalizeLangRegions() throws {
        do {
            var foundSVFileRec:Bool = false
            if !self.mSupportingMultLangs {
                // only the SV-File language is desired
                if self.mOrgRec!.mOrg_Lang_Recs != nil {
                    var inx:Int = 0
                    for langRec in self.mOrgRec!.mOrg_Lang_Recs! {
                        if langRec.rOrgLang_LangRegionCode == self.mOrgRec!.rOrg_LangRegionCode_SV_File {
                            foundSVFileRec = true
                            if langRec.mDuringEditing_isDeleted {
                                langRec.mDuringEditing_isDeleted = false
                                self.mOrgRec!.mOrg_Lang_Recs_are_changed = true
                            }
                        } else {
                            if !langRec.mDuringEditing_isDeleted {
                                langRec.mDuringEditing_isDeleted = true
                                self.mOrgRec!.mOrg_Lang_Recs_are_changed = true
                            }
                        }
                        inx = inx + 1
                    }
                }
                
                if !foundSVFileRec {
                    _ = try self.mOrgRec!.addNewFinalLangRec(forLangRegion: self.mOrgRec!.rOrg_LangRegionCode_SV_File)
                }
                self.mOrgRec!.rOrg_LangRegionCodes_Supported = [self.mOrgRec!.rOrg_LangRegionCode_SV_File]
            } else {
                // multiple shown languages are desired; do a safety finalization of those records;
                // first pre-mark ALL the records temporarily as deleted
                for orgLangRec in self.mOrgRec!.mOrg_Lang_Recs! {
                    orgLangRec.mDuringEditing_isMarked = true
                }
                
                // now unmark as deleted all those that ARE showing as rows in the multi-valued section; rebuild rOrg_LangRegionCodes_Supported in order shown
                var lrCodes_Supported:[String] = []
                if self.mMVS_langs!.count > 0 {
                    for inx in 0...self.mMVS_langs!.count - 1 {
                        let rowTag = self.mMVS_langs![inx].tag!
                        if rowTag.starts(with: "LC,") {
                            let components = rowTag.components(separatedBy: ",")
                            if components[1] == self.mOrgRec!.rOrg_LangRegionCode_SV_File { foundSVFileRec = true }
                            let orgLangRec:RecOrganizationLangs? = self.mOrgRec!.getLangRec(forLangRegion: components[1], includingDeleted: true)
                            if orgLangRec != nil {
                                orgLangRec!.mDuringEditing_isMarked = false
                                self.mOrgRec!.markUndeletedLangRec(forLangRegion: components[1])
                            } else {
                                _ = try self.mOrgRec!.addNewFinalLangRec(forLangRegion: components[1])
                            }
                            lrCodes_Supported.append(components[1])
                        }
                    }
                }
                
                // the SV-File's language record must exist; ensure it is undeleted or create it if missing
                if !foundSVFileRec {
                    let orgLangRec = self.mOrgRec!.getLangRec(forLangRegion: self.mOrgRec!.rOrg_LangRegionCode_SV_File, includingDeleted: true)
                    if orgLangRec != nil {
                        orgLangRec!.mDuringEditing_isMarked = false
                        self.mOrgRec!.markUndeletedLangRec(forLangRegion: self.mOrgRec!.rOrg_LangRegionCode_SV_File)
                    } else {
                        _ = try self.mOrgRec!.addNewFinalLangRec(forLangRegion: self.mOrgRec!.rOrg_LangRegionCode_SV_File)
                    }
                    lrCodes_Supported.append(self.mOrgRec!.rOrg_LangRegionCode_SV_File)
                }
                self.mOrgRec!.rOrg_LangRegionCodes_Supported = lrCodes_Supported
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).finalizeLangRegions")
            throw appError
        } catch { throw error }
        
        // now finalize any partial language records or remaining marked records;
        // going to ignore these throws as the partials can be used as-is
        for orgLangRec in self.mOrgRec!.mOrg_Lang_Recs! {
            if orgLangRec.mDuringEditing_isMarked {
                // the record has a remaining mark; so it must be deleted
                if !orgLangRec.mDuringEditing_isDeleted {
                    orgLangRec.mDuringEditing_isDeleted = true
                    self.mOrgRec!.mOrg_Lang_Recs_are_changed = true
                }
                
            } else if !orgLangRec.mDuringEditing_isDeleted && orgLangRec.mDuringEditing_isPartial {
                // it is a non-deleted partial record
                do {
                    try orgLangRec.finalizePartial(svFileLangRegion: self.mOrgRec!.rOrg_LangRegionCode_SV_File)
                    self.mOrgRec!.mOrg_Lang_Recs_are_changed = true
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).finalizeLangRegions", errorStruct: error, extra: nil)
                    // only post the error; do not show to end-user nor throw
                }
            }
        }
    }
    
    // make the LabelRow associated with the LangRegion of the SV-File not deletable
    public func editingStyleForRowAt(indexPath:IndexPath, superStyle:UITableViewCell.EditingStyle) -> UITableViewCell.EditingStyle {
        guard let section = self.mForm![indexPath.section] as? MultivaluedSection else {
            return superStyle
        }

        if section.tag != "mvs_langs" { return superStyle }
        if indexPath.row == section.count - 1 { return superStyle }
        let hasTag:String? = self.mForm![indexPath.section][indexPath.row].tag
        if hasTag == nil { return superStyle }
        if !hasTag!.starts(with: "LC,") { return superStyle }
        let comps = hasTag!.components(separatedBy: ",")
        if comps[1] != self.mOrgRec!.rOrg_LangRegionCode_SV_File { return superStyle }
        return .none
    }
    
    // this function will get invoked just before the move process
    // after this callback will be an immediate delete "rowsHaveBeenRemoved()" then insert "rowsHaveBeenAdded()"
    public func rowsWillBeMoved(movedRows:[BaseRow], sourceIndexes:[IndexPath], destinationIndexes:[IndexPath]) {
        for sourceIndexPath in sourceIndexes {
            if self.mForm![sourceIndexPath.section].tag == "mvs_langs" {
                // this move will occur in the mvs_fields MultivaluedSection;
                // will do the re-ordering in the rowsHaveBeenAdded()
                self.mMovesInProcess = self.mMovesInProcess + 1
            }
        }
    }
    
    // this function will get invoked when any rows are deleted or HIDDEN anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    public func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        var deletesDone:Bool = false
        var inx:Int = 0
        for indexPath in indexes {
            if self.mForm![indexPath.section].tag == "mvs_langs" {
                // this removal or move or hide occured in the mvs_langs MultivaluedSection
                if self.mMovesInProcess > 0 {
                    // it is an in-process move
//let br:LabelRow = rows[inx] as! LabelRow
//debugPrint("\(self.mCTAG).rowsHaveBeenRemoved.mvs_langs Move \(self.mMovesInProcess) in-process \(indexPath.item) is \(br.title!)")
                } else {
                    // it is a delete or hide; mark the applicable OrgLangRec as deleted but keep it for now in the array
                    let br:LabelRow = rows[inx] as! LabelRow
                    let removeLangRegion:String = br.tag!.components(separatedBy: ",")[1]
                    self.mOrgRec!.markDeletedLangRec(forLangRegion: removeLangRegion)
                    
                    // remove the applicable language from the rOrg_LangRegionCodes_Supported
                    var inx = 0
                    for isLangRegion in self.mOrgRec!.rOrg_LangRegionCodes_Supported {
                        if isLangRegion == removeLangRegion {
                            self.mOrgRec!.rOrg_LangRegionCodes_Supported.remove(at: inx)
                            break
                        }
                        inx = inx + 1
                    }
                    deletesDone = true
//debugPrint("\(self.mCTAG).rowsHaveBeenRemoved.mvs_langs Delete \(indexPath.item) is \(br.title!) @ \(removeLangRegion)")
                }
            }
            inx = inx + 1
        }
        
        // if any deletes were done, inform the mains
        if deletesDone {
            self.mChangesCallback?()    // not used on WizOrgDefine11ViewController
            self.mEFP?.reassess()       // not used on WizOrgDefine11ViewController
        }
    }
    
    // this function will get invoked when any rows are added or UNHIDDEN anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    public func rowsHaveBeenAdded(_ rows: [BaseRow], at indexes: [IndexPath]) {
        var inx:Int = 0
        for indexPath in indexes {
            if self.mForm![indexPath.section].tag == "mvs_langs" {
                // this add or move or unhide occured in the mvs_langs MultivaluedSection
                if self.mMovesInProcess > 0 {
                    // it is a move; not an add or unhide
//let br:LabelRow = rows[inx] as! LabelRow
//debugPrint("\(self.mCTAG).rowsHaveBeenAdded.mvs_langs Move \(self.mMovesInProcess) completed \(indexPath.item) is \(br.title!)")
                    self.mMovesInProcess = self.mMovesInProcess - 1
                    
                    // rebuild the rOrg_LangRegionCodes_Supported with the new order of the languages
                    self.mOrgRec!.rOrg_LangRegionCodes_Supported = []
                    for inx1 in 0...self.mMVS_langs!.endIndex - 1 {
                        let br1:LabelRow? = self.mMVS_langs![inx1] as? LabelRow
                        if br1 != nil {
                            let langRegion:String = br1!.tag!.components(separatedBy: ",")[1]
                            self.mOrgRec!.rOrg_LangRegionCodes_Supported.append(langRegion)
                        }
                    }
                    
                    // inform the mains
                    self.mChangesCallback?()    // not used on WizOrgDefine11ViewController
                    self.mEFP?.reassess()       // not used on WizOrgDefine11ViewController
                }
            }
            inx = inx + 1
        }
    }
}
