//
//  WizFormDefine16ViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/6/18.
//

import UIKit

class WizFormDefine16ViewController: UIViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW3-16"
    private weak var mRootVC:WizMenuViewController? = nil

    // outlets to screen controls
    @IBOutlet weak var switch_interested_in: UISwitch!
    @IBOutlet weak var switch_name: UISegmentedControl!
    @IBOutlet weak var switch_email_address: UISwitch!
    @IBOutlet weak var switch_phone_number: UISwitch!
    @IBOutlet weak var switch_address: UISwitch!
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Form_Rec = nil
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func button_done_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Form_Rec!.rOrg_Code_For_SV_File = self.mRootVC!.mWorking_Org_Rec!.rOrg_Code_For_SV_File
        
        var fieldsToAdd:[String] = []
        if self.switch_name.selectedSegmentIndex == 0 {
            fieldsToAdd.append("FC_Name1st")
            fieldsToAdd.append("FC_NameLast")
        } else {
            fieldsToAdd.append("FC_NameFull")
        }
        if self.switch_email_address.isOn { fieldsToAdd.append("FC_Email") }
        if self.switch_phone_number.isOn { fieldsToAdd.append("FC_PhFull") }
        if self.switch_address.isOn { fieldsToAdd.append("FC_AddrAll") }
        if self.switch_interested_in.isOn { fieldsToAdd.append("FC_InterCharity") }
        
        // first add the new form record
        do {
            _ = try self.mRootVC!.mWorking_Form_Rec!.saveNewToDB(withOrgRec: self.mRootVC!.mWorking_Org_Rec!)
        } catch {
            // error.log and alert already posted
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        
        // now add all the selected form fields
        do {
            var orderSVfile:Int = 10
            var orderShown:Int = 10
            try AppDelegate.mFieldHandler!.addFieldstoForm(field_IDCodes: fieldsToAdd, forFormRec: self.mRootVC!.mWorking_Form_Rec!, withOrgRec: self.mRootVC!.mWorking_Org_Rec!, orderSVfile: &orderSVfile, orderShown: &orderShown)
        } catch {
            // error.log and alert already posted
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        
        (UIApplication.shared.delegate as! AppDelegate).checkCurrentForm(withFormRec: self.mRootVC!.mWorking_Form_Rec!)
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
        assert(self.mRootVC!.mWorking_Org_Rec != nil, "\(self.mCTAG).viewDidLoad self.mRootVC!.mWorking_Org_Rec == nil")
        assert(self.mRootVC!.mWorking_Form_Rec != nil, "\(self.mCTAG).viewDidLoad self.mRootVC!.mWorking_Form_Rec == nil")
        assert(self.mRootVC!.mEFP != nil, "\(self.mCTAG).viewDidLoad self.mEFP == nil")
        
        // locate the child OrgTitleViewController
        let orgTitleVC:OrgTitleViewController? = children.first as? OrgTitleViewController
        assert(orgTitleVC != nil, "\(self.mCTAG).viewDidLoad orgTitleVC == nil")
        orgTitleVC!.mEFP = self.mRootVC!.mEFP!
    }
    
    // called by the framework when the view will re-appear
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        self.reload()
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // do any preparations
    private func reload() {
    }
}
