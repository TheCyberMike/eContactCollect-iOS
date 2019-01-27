//
//  AdminMenuViewController.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import UIKit
import Eureka

class AdminMenuViewController: UIViewController {
    // member constants and other static content
    private let mCTAG:String = "VCSM"
    public var mDismissing:Bool = false
    
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
    
    // called by the framework when the view will re-appear
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewWillDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            self.mDismissing = true
        }
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent {
            self.mDismissing = true
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
        } else if (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            self.mDismissing = true
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC's NC IS DISMISSED \(self)")
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
    
    // perform the segue from the parent VC to ensure navigation titles are correct
    internal func performSegue(toVCIdentifier:String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: toVCIdentifier )
        self.navigationController?.pushViewController(newViewController, animated:true)
    }
}

/////////////////////////////////////////////////////////////////////////
// Child FormViewController
/////////////////////////////////////////////////////////////////////////

class AdminMenuFormViewController: FormViewController, COVC_Delegate, CFVC_Delegate, CEVC_Delegate {
    // member variables
    private var mHasNotification:Bool = false
    private var mButtonRowEditContacts:ButtonRow? = nil
    private var mButtonRowSendContacts:ButtonRow? = nil
    private var mButtonRowSwitchEvent:ButtonRow? = nil
    private var mButtonRowSwitchForm:ButtonRow? = nil
    private var mButtonRowSwitchOrg:ButtonRow? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCSMF"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(self.mCTAG).deinit STARTED")
        if self.mHasNotification && AppDelegate.mEntryFormProvisioner != nil {
            NotificationCenter.default.removeObserver(self, name: .APP_EFP_OrgFormChange, object: AppDelegate.mEntryFormProvisioner!)
        }
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
        
        // setup a notification listener if the current Org or Form has changed
        if AppDelegate.mEntryFormProvisioner != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(newCurrentsNotice(_:)), name: .APP_EFP_OrgFormChange, object: AppDelegate.mEntryFormProvisioner!)
            self.mHasNotification = true
        }
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need to forceably clear out the form so this VC will deinit()
    override func viewDidDisappear(_ animated:Bool) {
        let myParent:AdminMenuViewController? = self.parent as? AdminMenuViewController
        if myParent != nil {
            if myParent!.mDismissing {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND PARENT VC IS DISMISSED parent=\(self.parent!)")
                if self.mHasNotification && AppDelegate.mEntryFormProvisioner != nil {
                    NotificationCenter.default.removeObserver(self, name: .APP_EFP_OrgFormChange, object: AppDelegate.mEntryFormProvisioner!)
                    self.mHasNotification = false
                }
                self.mButtonRowEditContacts = nil
                self.mButtonRowSendContacts = nil
                self.mButtonRowSwitchEvent = nil
                self.mButtonRowSwitchForm = nil
                self.mButtonRowSwitchOrg = nil
                form.removeAll()
                tableView.reloadData()
            } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT PARENT VC is not being dismissed parent=\(self.parent!)")
            }
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED NO PARENT VC")
        }
        super.viewDidDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // received a notification that the AppDelegate current Org or Form has changed
    @objc func newCurrentsNotice(_ notification:Notification) {
//debugPrint("\(self.mCTAG).newCurrentsNotice STARTED")
        self.refresh()
    }
    
    // build the menu form
    private func buildForm() {
        var hasCurrentOrg:Bool = false
        var hasCurrentForm:Bool = false
        if AppDelegate.mEntryFormProvisioner != nil {
            hasCurrentOrg = true
            if AppDelegate.mEntryFormProvisioner!.mFormRec != nil { hasCurrentForm = true }
        }

        var orgQty:Int64 = 0
        var formQty:Int64 = 0
        do {
            orgQty = try RecOrganizationDefs.orgGetQtyRecs()
            if hasCurrentOrg {
                formQty = try RecOrgFormDefs.orgFormGetQtyRecs(forOrgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).buildForm", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
        
        let section1 = Section(NSLocalizedString("Actions for the Current Organization", comment: ""))
        form +++ section1
        self.mButtonRowEditContacts = ButtonRow() {
            $0.tag = "edit_collected_contacts"
            $0.title = NSLocalizedString("Edit Collected Contacts >", comment: "")
            $0.disabled = (hasCurrentOrg) ? false : true
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                (self!.parent as! AdminMenuViewController).performSegue(toVCIdentifier: "VC ContactsMgmt")
        }
        section1 <<< self.mButtonRowEditContacts!
        self.mButtonRowSendContacts = ButtonRow() {
            $0.tag = "send_collected_contacts"
            $0.title = NSLocalizedString("Send Collected Contacts >", comment: "")
            $0.disabled = (hasCurrentOrg) ? false : true
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                (self!.parent as! AdminMenuViewController).performSegue(toVCIdentifier: "VC SendContacts")
        }
        section1 <<< self.mButtonRowSendContacts!
        self.mButtonRowSwitchEvent = ButtonRow() {
            $0.tag = "switch_event"
            $0.cellStyle = UITableViewCell.CellStyle.subtitle
            $0.title = NSLocalizedString("Switch Event >", comment: "")
            $0.disabled = (hasCurrentOrg) ? false : true
            }.cellUpdate { cell, row in
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
                if hasCurrentOrg {
                    cell.detailTextLabel?.text = AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Event_Code_For_SV_File
                }
            }.onCellSelection { [weak self] cell, row in
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC PopupEnterEvent") as! PopupEnterEventViewController
                newViewController.mCEVCdelegate = self
                newViewController.modalPresentationStyle = .custom
                self!.present(newViewController, animated: true, completion: nil)
        }
        section1 <<< self.mButtonRowSwitchEvent!
        self.mButtonRowSwitchForm = ButtonRow() {
            $0.tag = "switch_form"
            $0.cellStyle = UITableViewCell.CellStyle.subtitle
            $0.title = NSLocalizedString("Switch Form >", comment: "")
            $0.disabled = (!hasCurrentOrg || formQty < 2) ? true : false
            }.cellUpdate { cell, row in
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
                if hasCurrentOrg && hasCurrentForm {
                    cell.detailTextLabel?.text = AppDelegate.mEntryFormProvisioner!.mFormRec!.rForm_Code_For_SV_File
                }
            }.onCellSelection { [weak self] cell, row in
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC ChooseForm") as! ChooserFormViewController
                newViewController.mCFVCdelegate = self
                newViewController.modalPresentationStyle = .custom
                self!.present(newViewController, animated: true, completion: nil)
        }
        section1 <<< self.mButtonRowSwitchForm!
        self.mButtonRowSwitchOrg = ButtonRow() {
            $0.tag = "switch_org"
            $0.cellStyle = UITableViewCell.CellStyle.subtitle
            $0.title = NSLocalizedString("Switch Organization >", comment: "")
            $0.disabled = (orgQty < 2) ? true : false
            }.cellUpdate { cell, row in
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
                if hasCurrentOrg {
                    cell.detailTextLabel?.text = AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File
                }
            }.onCellSelection { [weak self] cell, row in
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC ChooseOrg") as! ChooserOrgViewController
                newViewController.mCOVCdelegate = self
                newViewController.modalPresentationStyle = .custom
                self!.present(newViewController, animated: true, completion: nil)
        }
        section1 <<< self.mButtonRowSwitchOrg!
        
        let section2 = Section(NSLocalizedString("Overall Settings", comment: ""))
        form +++ section2
        section2 <<< ButtonRow() {
            $0.tag = "manage_orgs_forms"
            $0.title = NSLocalizedString("Manage Orgs and Forms >", comment: "")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                (self!.parent as! AdminMenuViewController).performSegue(toVCIdentifier: "VC OrgsMgmt")
        }
        section2 <<< ButtonRow() {
            $0.tag = "manage_preferences"
            $0.title = NSLocalizedString("Manage Preferences >", comment: "")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                (self!.parent as! AdminMenuViewController).performSegue(toVCIdentifier: "VC PrefsMgmt")
        }
        section2 <<< ButtonRow() {
            $0.tag = "manage_alerts"
            $0.title = NSLocalizedString("Manage Alerts >", comment: "")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                (self!.parent as! AdminMenuViewController).performSegue(toVCIdentifier: "VC AlertsMgmt")
        }
        section2 <<< ButtonRow() {
            $0.tag = "about"
            $0.title = NSLocalizedString("Support and About >", comment: "")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                (self!.parent as! AdminMenuViewController).performSegue(toVCIdentifier: "VC AppSupportAbout")
        }
    }
    
    // refresh changes that may have occured by the popup callbacks
    private func refresh() {
//debugPrint("\(self.mCTAG).refresh STARTED")
        var hasCurrentOrg:Bool = false
        if AppDelegate.mEntryFormProvisioner != nil {
            hasCurrentOrg = true
        }
        var orgQty:Int64 = 0
        var formQty:Int64 = 0
        do {
            orgQty = try RecOrganizationDefs.orgGetQtyRecs()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).refresh", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }

        if !hasCurrentOrg {
            self.mButtonRowEditContacts!.disabled = true
            self.mButtonRowSendContacts!.disabled = true
            self.mButtonRowSwitchEvent!.disabled = true
            self.mButtonRowSwitchForm!.disabled = true
            self.mButtonRowSwitchOrg!.disabled = true
        } else {
            do {
                formQty = try RecOrgFormDefs.orgFormGetQtyRecs(forOrgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).refresh", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
            
            self.mButtonRowEditContacts!.disabled = false
            self.mButtonRowSendContacts!.disabled = false
            self.mButtonRowSwitchEvent!.disabled = false
            if formQty < 2 { self.mButtonRowSwitchForm!.disabled = true }
            else { self.mButtonRowSwitchForm!.disabled = false }
            if orgQty < 2 { self.mButtonRowSwitchOrg!.disabled = true }
            else { self.mButtonRowSwitchOrg!.disabled = false }
        }
        self.mButtonRowEditContacts!.evaluateDisabled()
        self.mButtonRowSendContacts!.evaluateDisabled()
        self.mButtonRowSwitchEvent!.evaluateDisabled()
        self.mButtonRowSwitchForm!.evaluateDisabled()
        self.mButtonRowSwitchOrg!.evaluateDisabled()
        
        self.mButtonRowSwitchEvent!.updateCell()
        self.mButtonRowSwitchOrg!.updateCell()
        self.mButtonRowSwitchForm!.updateCell()
    }
    
    // return from the Org Chooser view;
    // note: the chooser view is still showing and the chooser view controller is still the mainline;
    // this callback MUST perform dismiss of the chooser view controller
    func completed_COVC(fromVC:ChooserOrgViewController, wasChosen:String?) {
        dismiss(animated: true, completion: {
            // perform the following after the dismiss is completed so if there is an error, the showAlertDialog will work
            if wasChosen != nil {
                // load the chosen Org record
                do {
                    let orgRec:RecOrganizationDefs? = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName:wasChosen!)
                    if orgRec == nil {
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).completed_COVC", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
                        return  // from the completion handler
                    }
                    
                    (UIApplication.shared.delegate as! AppDelegate).setCurrentOrg(toOrgRec:orgRec!)
                    self.refresh()
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).completed_COVC", errorStruct: error, extra: wasChosen!)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
            return // from the completion handler
        })
    }
    
    // return from the Form Chooser view
    // note: the chooser view is still showing and the chooser view controller is still the mainline;
    // this callback MUST perform dismiss of the chooser view controller
    func completed_CFVC(fromVC:ChooserFormViewController, wasChosen:String?) {
        dismiss(animated: true, completion: {
            // perform the following after the dismiss is completed so if there is an error, the showAlertDialog will work
            if wasChosen != nil && AppDelegate.mEntryFormProvisioner != nil {
                // load the chosen Form record
                do {
                    let orgFormRec:RecOrgFormDefs? = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName: wasChosen!, forOrgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                    if orgFormRec == nil {
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).completed_CFVC", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
                        return
                    }
                    
                    (UIApplication.shared.delegate as! AppDelegate).setCurrentForm(toFormRec:orgFormRec!)
                    self.refresh()
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).completed_CFVC", errorStruct: error, extra: wasChosen!)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
            return // from the completion handler
        })
    }
    
    // return from the Event Chooser view
    func completed_CEVC(wasCancelled:Bool, eventShortName:String?, eventFullTitles:[CodePair]?) {
        if wasCancelled { return }
        
        // load and change the Org record's event information
        if AppDelegate.mEntryFormProvisioner != nil && eventFullTitles != nil {
            do {
                let orgRec:RecOrganizationDefs? = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                if orgRec == nil {
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).completed_CEVC", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
                    return
                }
                
                orgRec!.rOrg_Event_Code_For_SV_File = eventShortName
                for cp in eventFullTitles! {
                    try orgRec!.setEventTitleShown_Editing(langRegion: cp.codeString, title: cp.valueString)
                }
                _ = try orgRec!.saveChangesToDB(originalOrgRec: AppDelegate.mEntryFormProvisioner!.mOrgRec)
                
                (UIApplication.shared.delegate as! AppDelegate).setCurrentEvent(toOrgRec: orgRec!)
                self.refresh()
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).completed_CEVC", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                return
            }
        }
    }
}
