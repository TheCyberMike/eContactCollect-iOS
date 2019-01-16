//
//  ChooserFormViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/8/18.
//

import UIKit
import SQLite

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol CFVC_Delegate {
    // return wasChosen=nil if cancelled; wasChosen=Form_short_name if chosen
    // delegate MUST perform: dismiss(animated: true, completion: nil) or dismiss(animated: true, completion: {...})
    func completed_CFVC(fromVC:ChooserFormViewController, wasChosen:String?)
}

class ChooserFormViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    // caller pre-set member variables
    public var mCFVCdelegate:CFVC_Delegate? = nil   // optional callback
    public var mForOrgShortName:String? = nil       // invoker must set the Org Short Name that Forms will be chosen from

    // member variables
    private var mFormRecs:NSMutableArray = NSMutableArray()
    
    // member constants and other static content
    private let mCTAG:String = "VCUCF"

    // outlets to screen controls
    @IBOutlet weak var pickerview_forms: UIPickerView!
    @IBAction func button_choose_pressed(_ sender: UIButton) {
        // choose button pressed; tell delegate as such; delegate MUST DISMISS!!
        if mCFVCdelegate == nil {
            dismiss(animated: true, completion: nil)
        } else {
            let row:Int = self.pickerview_forms.selectedRow(inComponent:0)
            let orgFormRec:RecOrgFormDefs = self.mFormRecs[row] as! RecOrgFormDefs
            mCFVCdelegate!.completed_CFVC(fromVC: self, wasChosen: orgFormRec.rForm_Code_For_SV_File)
        }
    }
    @IBAction func button_cancel_pressed(_ sender: UIButton) {
        // cancel button pressed; tell delegate as such, then delegate MUST DISMISS!!
        if mCFVCdelegate == nil {
            dismiss(animated: true, completion: nil)
        } else {
            mCFVCdelegate!.completed_CFVC(fromVC: self, wasChosen: nil)
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
        
        // obtain a list of all Form records
        self.mFormRecs.removeAllObjects()
        do {
            if self.mForOrgShortName != nil {
                let records:AnySequence<Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: self.mForOrgShortName!)
                for rowObj in records {
                    let orgFormRec:RecOrgFormDefs = try RecOrgFormDefs(row:rowObj)
                    self.mFormRecs.add(orgFormRec)
                }
            } else if AppDelegate.mEntryFormProvisioner != nil {
                let records:AnySequence<Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                for rowObj in records {
                    let orgFormRec:RecOrgFormDefs = try RecOrgFormDefs(row:rowObj)
                    self.mFormRecs.add(orgFormRec)
                }
            }
        } catch {
            // error.log and alert already posted
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""), completion: { () in
                if self.mCFVCdelegate == nil { self.dismiss(animated: true, completion: nil) }
                else { self.mCFVCdelegate!.completed_CFVC(fromVC: self, wasChosen: nil) }
            })
        }
        
        // if there are no choices, then just return that and quit;
        // if there is only one choice, then just return that and quit
        if self.mFormRecs.count == 0 {
            if self.mCFVCdelegate == nil { self.dismiss(animated: true, completion: nil) }
            else { self.mCFVCdelegate!.completed_CFVC(fromVC: self, wasChosen: nil) }
        } else if self.mFormRecs.count == 1 {
            if self.mCFVCdelegate == nil { self.dismiss(animated: true, completion: nil) }
            else {
                let orgFormRec:RecOrgFormDefs = self.mFormRecs[0] as! RecOrgFormDefs
                self.mCFVCdelegate!.completed_CFVC(fromVC: self, wasChosen: orgFormRec.rForm_Code_For_SV_File)
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
    func pickerView(_ pickerView:UIPickerView, numberOfRowsInComponent component:Int) -> Int{ return self.mFormRecs.count }
    
    // returns the item in each row in each component
    func pickerView(_ pickerView:UIPickerView, titleForRow row:Int, forComponent component:Int) -> String? {
        let orgFormRec:RecOrgFormDefs = self.mFormRecs[row] as! RecOrgFormDefs
        return orgFormRec.rForm_Code_For_SV_File
    }
}
