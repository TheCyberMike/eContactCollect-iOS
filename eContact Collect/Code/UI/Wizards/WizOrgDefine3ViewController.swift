//
//  WizOrgDefine3ViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/4/18.
//

import Eureka

class WizOrgDefine3ViewController: FormViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW2-3"
    private weak var mRootVC:WizMenuViewController? = nil
    
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Org_Rec = nil
        self.clearVC()
        if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
            self.navigationController!.popToRootViewController(animated: true)
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
        self.mRootVC = self.navigationController!.findViewController(ofKind: WizMenuViewController.self) as? WizMenuViewController
        assert(self.mRootVC != nil, "\(self.mCTAG).viewDidLoad self.mRootVC == nil")
        
        // create an empty Org record if it does not already exist
        if self.mRootVC!.mWorking_Org_Rec == nil {
            self.mRootVC!.mWorking_Org_Rec = RecOrganizationDefs(org_code_sv_file: "")
        }
        
        // build the form
        self.buildForm()
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
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
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // intercept the Next segue
    override open func shouldPerformSegue(withIdentifier identifier:String, sender:Any?) -> Bool {
        if identifier != "Segue Next_W_ORG_3_6" { return true }
        let validationError = form.validate()
        if validationError.count > 0 {
            var message:String = NSLocalizedString("There are errors in certain fields of the form; they are shown with red text. \n\nErrors:\n", comment:"")
            for errorStr in validationError {
                message = message + errorStr.msg + "\n"
            }
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: message, buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        
        // safety double-checks
        if self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File.isEmpty {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Organization short code cannot be empty", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        if self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File.rangeOfCharacter(from: AppDelegate.mAcceptableNameChars.inverted) != nil {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Organization short code can only contain letters, digits, space, or _ . + -", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        
        // the short name cannot already exist in the database
        var orgRec:RecOrganizationDefs?
        do {
            orgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).shouldPerformSegue", errorStruct: error, extra: self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        if orgRec != nil {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Organization short code already exists in the database", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }

        return true
    }
    
    // clear out the Form so this VC will deinit
    private func clearVC() {
        form.removeAll()
        tableView.reloadData()
        self.mRootVC = nil
    }
    
    // build the form
    private func buildForm() {
        form.removeAll()
        tableView.reloadData()
        
        let section1 = Section()
        form +++ section1
        section1 <<< TextAreaRow() {
            $0.tag = "info"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 100.0)
            $0.title = NSLocalizedString("Info", comment:"")
            $0.value = NSLocalizedString("%info%_WizOrgDefine3", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }
        
        let section2 = Section(NSLocalizedString("Organization Identity", comment:""))
        form +++ section2
        
        let orgShortNameRow = TextRow() {
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
                        self!.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File = chgRow.value!
                    }
                }
        }
        section2 <<< orgShortNameRow
        orgShortNameRow.value = self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File
    }
}
