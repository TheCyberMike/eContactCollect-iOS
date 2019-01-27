//
//  ChooserOrgViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/5/18.
//

import UIKit
import SQLite

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol COVC_Delegate {
    // return wasChosen=nil if cancelled; wasChosen=Org_short_name if chosen
    // delegate MUST perform: dismiss(animated: true, completion: nil) or dismiss(animated: true, completion: {...})
    func completed_COVC(fromVC:ChooserOrgViewController, wasChosen:String?)
}

class ChooserOrgViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    // caller pre-set member variables
    public var mCOVCdelegate:COVC_Delegate? = nil   // optional callback
    public var mFor:Int = 0                         // optional integer available to the invoker

    // member variables
    private var mOrgRecs:NSMutableArray = NSMutableArray()
    
    // member constants and other static content
    private let mCTAG:String = "VCUCO"

    // outlets to screen controls
    @IBOutlet weak var view_dialog: UIView!
    @IBOutlet weak var pickerview_orgs: UIPickerView!
    @IBAction func button_choose(_ sender: UIButton) {
        // choose button pressed; tell delegate as such; delegate MUST DISMISS!!
        if mCOVCdelegate == nil {
            dismiss(animated: true, completion: nil)
        } else {
            let row:Int = self.pickerview_orgs.selectedRow(inComponent:0)
            let orgRec:RecOrganizationDefs = self.mOrgRecs[row] as! RecOrganizationDefs
            mCOVCdelegate!.completed_COVC(fromVC: self, wasChosen: orgRec.rOrg_Code_For_SV_File)
        }
    }
    @IBAction func button_cancel(_ sender: UIButton) {
        // cancel button pressed; tell delegate as such, then delegate MUST DISMISS!!
        if mCOVCdelegate == nil {
            dismiss(animated: true, completion: nil)
        } else {
            mCOVCdelegate!.completed_COVC(fromVC: self, wasChosen: nil)
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
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // obtain a list of all Org records
        self.mOrgRecs.removeAllObjects()
        do {
            let records:AnySequence<Row> = try RecOrganizationDefs.orgGetAllRecs()
            for rowObj in records {
                let orgRec:RecOrganizationDefs = try RecOrganizationDefs(row:rowObj)
                self.mOrgRecs.add(orgRec)
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).viewWillAppear", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""), completion: { () in
                if self.mCOVCdelegate == nil { self.dismiss(animated: true, completion: nil) }
                else { self.mCOVCdelegate!.completed_COVC(fromVC: self, wasChosen: nil) }
            })
        }

        // if there are no choices, then just return that and quit;
        // if there is only one choice, then just return that and quit
        if self.mOrgRecs.count == 0 {
            if self.mCOVCdelegate == nil { self.dismiss(animated: true, completion: nil) }
            else { self.mCOVCdelegate!.completed_COVC(fromVC: self, wasChosen: nil) }
        } else if self.mOrgRecs.count == 1 {
            if self.mCOVCdelegate == nil { self.dismiss(animated: true, completion: nil) }
            else {
                let orgRec:RecOrganizationDefs = self.mOrgRecs[0] as! RecOrganizationDefs
                self.mCOVCdelegate!.completed_COVC(fromVC: self, wasChosen: orgRec.rOrg_Code_For_SV_File)
            }
        }
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related to the PickerView
    ///////////////////////////////////////////////////////////////////
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView:UIPickerView) -> Int { return 1 }
    
    // returns the # of rows in each component
    func pickerView(_ pickerView:UIPickerView, numberOfRowsInComponent component:Int) -> Int{ return self.mOrgRecs.count }
    
    // returns the item in each row in each component
    func pickerView(_ pickerView:UIPickerView, titleForRow row:Int, forComponent component:Int) -> String? {
        let orgRec:RecOrganizationDefs = self.mOrgRecs[row] as! RecOrganizationDefs
        return orgRec.rOrg_Code_For_SV_File
    }
}
