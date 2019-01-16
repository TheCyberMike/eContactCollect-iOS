//
//  WizFormDefine1ViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/5/18.
//

import UIKit
import SQLite
import Eureka

class WizFormDefine1ViewController: UIViewController, COVC_Delegate {
    // member constants and other static content
    private let mCTAG:String = "VCW3-1"
    internal weak var mRootVC:WizMenuViewController? = nil
    private weak var mFormVC:WizFormDefine1FormViewController? = nil
    private weak var mOrgTitleViewController:OrgTitleViewController? = nil
    
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Form_Rec = nil
        self.clearVC()
        self.navigationController?.popToRootViewController(animated: true)
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
        self.mRootVC = self.navigationController!.viewControllers.first as? WizMenuViewController
        assert(self.mRootVC != nil, "\(self.mCTAG).viewDidLoad self.mRootVC == nil")
        
        // locate the child view controllers
        self.mOrgTitleViewController = nil
        self.mFormVC = nil
        for childVC in children {
            let vc1:OrgTitleViewController? = childVC as? OrgTitleViewController
            let vc2:WizFormDefine1FormViewController? = childVC as? WizFormDefine1FormViewController
            if vc1 != nil { self.mOrgTitleViewController = vc1 }
            if vc2 != nil { self.mFormVC = vc2 }
        }
        assert(self.mFormVC != nil, "\(self.mCTAG).viewDidLoad self.mFormVC == nil")
        assert(self.mOrgTitleViewController != nil, "\(self.mCTAG).viewDidLoad mOrgTitleViewController == nil")
        
        if self.mRootVC!.mWorking_Org_Rec != nil && self.mRootVC!.mEFP != nil {
            self.mOrgTitleViewController!.mEFP = self.mRootVC!.mEFP!
            self.mOrgTitleViewController!.mWait = false
        } else {
            self.mOrgTitleViewController!.mWait = true
        }
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        if self.mRootVC!.mWorking_Org_Rec == nil {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED self.mRootVC!.mWorking_Org_Rec == nil")
            // obtain a list of all Org records
            do {
                let records:AnySequence<SQLite.Row> = try RecOrganizationDefs.orgGetAllRecs()
                var count:Int = 0
                for rowObj in records {
                    count = count + 1
                    if count == 1 {
                        self.mRootVC!.mWorking_Org_Rec = try RecOrganizationDefs(row:rowObj)
                    }
                }
                if count == 0 {
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("There are no Organizations yet defined to make a Form for", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                } else if count > 1 {
                    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC ChooseOrg") as! ChooserOrgViewController
                    newViewController.mCOVCdelegate = self
                    newViewController.modalPresentationStyle = .custom
                    self.present(newViewController, animated: true, completion: nil)
                }
            } catch {
                // error.log and alert already posted
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
//debugPrint("\(self.mCTAG).viewWillAppear ENDED self.mRootVC!.mWorking_Org_Rec == nil")
        }
        
        // create an empty Form record if it does not already exist and setup the Org Title
        if self.mRootVC!.mWorking_Org_Rec != nil {
            if self.mRootVC!.mWorking_Form_Rec == nil {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED self.mRootVC!.mWorking_Form_Rec == nil")
                self.mRootVC!.mWorking_Form_Rec = RecOrgFormDefs(org_code_sv_file: self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File, form_code_sv_file: "")
            }
//debugPrint("\(self.mCTAG).viewWillAppear STARTED self.mOrgTitleViewController!.mEFP = self.mRootVC!.mEFP!")
            self.mOrgTitleViewController!.mEFP = self.mRootVC!.mEFP!
            self.mOrgTitleViewController!.mWait = false
            self.mOrgTitleViewController!.refresh()
        }
//debugPrint("\(self.mCTAG).viewWillAppear ENDED")
    }
    
    // called by the framework when the view has fully appeared
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
            self.clearVC()
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed")
        }
        super.viewDidDisappear(animated)
    }
    
    // clear out the Form so this VC will deinit
    private func clearVC() {
        self.mFormVC?.clearVC()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // return from the Org Chooser view;
    // note: the chooser view is still showing and the chooser view controller is still the mainline;
    // this callback MUST perform dismiss of the chooser view controller
    func completed_COVC(fromVC:ChooserOrgViewController, wasChosen:String?) {
        if wasChosen == nil {
            if self.mRootVC != nil { self.mRootVC!.mWorking_Form_Rec = nil }
            self.navigationController?.popToRootViewController(animated: true)
            dismiss(animated: true, completion: nil)
            return
        }
        
        dismiss(animated: true, completion: {
            // perform the following after the dismiss is completed so if there is an error, the showAlertDialog will work
            // load the chosen Org record
            do {
                self.mRootVC!.mWorking_Org_Rec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName:wasChosen!)
            } catch {
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                return  // from the completion handler
            }
            if self.mRootVC!.mWorking_Org_Rec == nil {
                AppDelegate.showAlertDialog(vc:self, title:NSLocalizedString("Database Error", comment:""), errorStruct: APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText:NSLocalizedString("Okay", comment:""))
                return  // from the completion handler
            }
            
            // create an empty Form record if it does not already exist and setup the Org Title
            if self.mRootVC!.mWorking_Org_Rec != nil {
                if self.mRootVC!.mWorking_Form_Rec == nil {
                    self.mRootVC!.mWorking_Form_Rec = RecOrgFormDefs(org_code_sv_file: self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File, form_code_sv_file: "")
                }
                self.mOrgTitleViewController!.mEFP = self.mRootVC!.mEFP!
                self.mOrgTitleViewController!.mWait = false
                self.mOrgTitleViewController!.refresh()
            }
            return  // from the completion handler
        })
    }
    
    // intercept the Next segue
    override open func shouldPerformSegue(withIdentifier identifier:String, sender:Any?) -> Bool {
        if identifier != "Segue Next_W_FORM_1_2" { return true }
        let validationError = self.mFormVC!.form.validate()
        if validationError.count > 0 {
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: message, buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        
        // safety double-checks
        if self.mRootVC!.mWorking_Form_Rec!.rForm_Code_For_SV_File.isEmpty {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Form short name cannot be empty", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        if self.mRootVC!.mWorking_Form_Rec!.rForm_Code_For_SV_File.rangeOfCharacter(from: AppDelegate.mAcceptableNameChars.inverted) != nil {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Form short name can only contain letters, digits, space, or _ . + -", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        
        // the short name cannot already exist in the database
        var formRec:RecOrgFormDefs?
        do {
            formRec = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName: self.mRootVC!.mWorking_Form_Rec!.rForm_Code_For_SV_File, forOrgShortName:self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File)
        } catch {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        if formRec != nil {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Form short name already exists in the database", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }

        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Form child ViewController
/////////////////////////////////////////////////////////////////////////

class WizFormDefine1FormViewController: FormViewController {
    // member variables
    private var mFormIsBuilt:Bool = false
    
    // member constants and other static content
    private let mCTAG:String = "VCW3-1F"
    private weak var mWiz1VC:WizFormDefine1ViewController? = nil
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB
    override func viewDidLoad() {
debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        // self.parent is not set until viewWillAppear()
    }
    
    // called by the framework when the view will re-appear;
    // remember this will be called upon return from the image chooser dialog
    override func viewWillAppear(_ animated:Bool) {
debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // locate our parent then build the form; initializing values as we go
        self.mWiz1VC = (self.parent as! WizFormDefine1ViewController)
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
debugPrint("\(self.mCTAG).rebuildForm STARTED")
        if self.mFormIsBuilt { return }
        form.removeAll()
        tableView.reloadData()
        
        let section1 = Section()
        form +++ section1
        section1 <<< TextAreaRow() {
            $0.tag = "info"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 100.0)
            $0.title = NSLocalizedString("Info", comment:"")
            $0.value = NSLocalizedString("%info%_WizFormDefine1", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }

        let section2 = Section(NSLocalizedString("Form Identity", comment:""))
        form +++ section2
        
        let formShortNameRow = TextRow() {
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
                        self!.mWiz1VC!.mRootVC!.mWorking_Form_Rec!.rForm_Code_For_SV_File = chgRow.value!
                    }
                }
        }
        section2 <<< formShortNameRow
        formShortNameRow.value = self.mWiz1VC!.mRootVC!.mWorking_Form_Rec!.rForm_Code_For_SV_File
        self.mFormIsBuilt = true
debugPrint("\(self.mCTAG).rebuildForm ENDED")
    }
}
