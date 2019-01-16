//
//  AdminPINViewController.swift
//  eContact Collect
//
//  Created by Yo on 9/21/18.
//

import UIKit

class AdminPINViewController: UIViewController {
    // member constants and other static content
    private let mCTAG:String = "VCSP"
    
    // outlets to screen controls
    @IBOutlet weak var textfield_pin: UITextField!
    @IBAction func button_submit_pin(_ sender: UIButton, forEvent event: UIEvent) {
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
        self.refresh()
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)        
        self.refresh()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // refresh the PIN text field
    private func refresh() {
        textfield_pin.text = ""
        textfield_pin.becomeFirstResponder()
    }
    
    // intercept the submit_pin segue
    override open func shouldPerformSegue(withIdentifier identifier:String, sender:Any?) -> Bool {
        if identifier != "Segue Button PIN Submit" { return true }
        let savedPIN:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.APP_Pin)
        if (savedPIN ?? "").isEmpty { return true }  // there is no PIN
        
        if (textfield_pin.text ?? "").isEmpty {
            AppDelegate.showAlertDialog(vc:self, title:NSLocalizedString("Entry Error", comment:""), message:NSLocalizedString("Must enter a PIN", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
#if DEBUG
        if textfield_pin.text == "11" { return true }
#endif
        if textfield_pin.text != savedPIN {
            AppDelegate.showAlertDialog(vc:self, title:NSLocalizedString("Entry Error", comment:""), message:NSLocalizedString("Incorrect PIN", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        return true
    }
}

