//
//  PopupEnterCloneViewController.swift
//  eContact Collect
//
//  Created by Yo on 12/1/18.
//

import UIKit
import Eureka

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol CECVC_Delegate {
    // delegate MUST perform: dismiss(animated: true, completion: nil) or dismiss(animated: true, completion: {...})
    func completed_CECVC(wasCancelled:Bool, newFormName:String, hadIndex:Int)
}

class PopupEnterCloneViewController: UIViewController {
    // caller pre-set member variables
    public var mCECVCdelegate:CECVC_Delegate? = nil     // optional callback
    public var mOrgShortName:String? = nil              // invoker must set the Org short name
    public var mFormInRowInx:Int = -1                   // invoker specifies the source Form's index in its list of Forms; is returned in the callback

    // member variables
    
    // member constants and other static content
    private let mCTAG:String = "VCUCEC"

    // outlets to screen controls
    @IBOutlet weak var textfield_form_name: UITextField!
    @IBAction func button_choose_pressed(_ sender: UIButton) {
        // check the name itself
        if (self.textfield_form_name.text ?? "").isEmpty {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("New form short name cannot be blank", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        if self.textfield_form_name.text!.rangeOfCharacter(from: AppDelegate.mAcceptableNameChars.inverted) != nil {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("New form short name can only contain letters, digits, space, or _ . + -", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        
        // the short name cannot already exist in the database
        var formRec:RecOrgFormDefs?
        do {
            formRec = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName: textfield_form_name.text!, forOrgShortName:self.mOrgShortName!)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).button_choose_pressed", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        if formRec != nil {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Form short name already exists in the database", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        if self.mCECVCdelegate != nil { self.mCECVCdelegate!.completed_CECVC(wasCancelled: false, newFormName: self.textfield_form_name.text!, hadIndex: self.mFormInRowInx) }
        else { dismiss(animated: true, completion: nil) }
    }
    @IBAction func button_cancel_pressed(_ sender: UIButton) {
        // cancel button pressed; tell delegate as such, then dismiss and return to the parent view controller
        if self.mCECVCdelegate != nil { self.mCECVCdelegate!.completed_CECVC(wasCancelled: true, newFormName: "", hadIndex: self.mFormInRowInx) }
        dismiss(animated: true, completion: nil)
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
        textfield_form_name.becomeFirstResponder()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
