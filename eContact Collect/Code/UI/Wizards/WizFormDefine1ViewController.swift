//
//  WizFormDefine1ViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/5/18.
//

import UIKit
import SQLite
import Eureka

class WizFormDefine1ViewController: UIViewController, CSFVC_Delegate {
    // member variables
    private var mImportsSucceeded:Bool = false
    
    // member constants and other static content
    private let mCTAG:String = "VCW3-1"
    internal weak var mRootVC:WizMenuViewController? = nil
    private weak var mFormVC:WizFormDefine1FormViewController? = nil
    private weak var mOrgTitleViewController:OrgTitleViewController? = nil
    
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.clearVC()
        if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
            self.navigationController!.popToRootViewController(animated: true)
        }
    }
    @IBAction func button_next_pressed(_ sender: UIBarButtonItem) {
        let selected:String = self.mFormVC!.mSelections!.selectedRow()!.selectableValue!
        switch selected {
        case "Create":
            // create a default Form
            do {
                let formRec:RecOrgFormDefs = try DatabaseHandler.shared.createDefaultForm(forOrgRec: self.mRootVC!.mWorking_Org_Rec!)
                (UIApplication.shared.delegate as! AppDelegate).checkCurrentForm(withFormRec: formRec)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).button_next_pressed", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
            self.clearVC()
            if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
                self.navigationController!.popToRootViewController(animated: true)
            }
            return
            
        case "Sample":
            break
        default:
            break
        }
        
        // allow end-user to choose sample forms; they will return to this VC when done
        let nextVC:SampleFormsViewController = SampleFormsViewController()
        nextVC.mForOrgShortCode = self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File
        nextVC.mDelegate = self
        self.navigationController?.pushViewController(nextVC, animated:true)
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
    // parent and all children are now available; this will be invoked upon return from the sample forms screen
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // is the screen post-Sample Forms and some were imported?
        if self.mImportsSucceeded {
            // yes, terminate this screen
            self.clearVC()
            if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
                self.navigationController!.popToRootViewController(animated: true)
            }
            return
        }
        
        // re-ensure there is an Org record defined
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
                }
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewWillAppear", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
//debugPrint("\(self.mCTAG).viewWillAppear ENDED self.mRootVC!.mWorking_Org_Rec == nil")
        }
        
        // re-setup the Org Title
        if self.mRootVC!.mWorking_Org_Rec != nil {
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
        self.mFormVC = nil
        self.mRootVC = nil
        self.mOrgTitleViewController = nil
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // callback from the sample forms screen
    // note this could get called several times if the end-user imports more than one form
    func completed_CSFVC(fromVC:SampleFormsViewController, orgWasImported:String, formWasImported:String?) {
        if formWasImported != nil {
            (UIApplication.shared.delegate as! AppDelegate).setCurrentForm(toFormShortName: formWasImported!, withOrgShortName: orgWasImported)
        }
        self.mImportsSucceeded = true
    }
}

/////////////////////////////////////////////////////////////////////////
// Form child ViewController
/////////////////////////////////////////////////////////////////////////

class WizFormDefine1FormViewController: FormViewController {
    // member variables
    internal var mSelections:SelectableSection<ListCheckRow<String>>? = nil
    
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
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
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
        self.mSelections = nil
        self.mWiz1VC = nil
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
            $0.value = NSLocalizedString("%info%_WizFormDefine1", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }
        
        // show the allowed selections
        self.mSelections = SelectableSection<ListCheckRow<String>>(NSLocalizedString("Please Choose Below then Press Next", comment:""), selectionType: .singleSelection(enableDeselection: false))
        form +++ self.mSelections!
        form.last! <<< ListCheckRow<String>("option_Create"){ listRow in
            listRow.title = NSLocalizedString("Create a simple default Form you can edit later", comment:"")
            listRow.selectableValue = "Create"
            listRow.value = "Create"
            }.cellUpdate { cell, row in
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.numberOfLines = 0
        }
        form.last! <<< ListCheckRow<String>("option_import"){ listRow in
            listRow.title = NSLocalizedString("Choose a Form from the Form Sample Library; it can be edited afterwards", comment:"")
            listRow.selectableValue = "Sample"
            listRow.value = nil
            }.cellUpdate { cell, row in
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.numberOfLines = 0
        }
    }
}
