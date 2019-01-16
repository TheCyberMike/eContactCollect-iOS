//
//  PopupFirstTimeViewController.swift
//  eContact Collect
//
//  Created by Dev on 12/18/18.
//

import UIKit

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol C1stVC_Delegate {
    // delegate MUST perform: dismiss(animated: true, completion: nil) or dismiss(animated: true, completion: {...})
    func completed_C1stVC(fromVC:PopupFirstTimeViewController, choice:Int)
}

class PopupFirstTimeViewController: UIViewController {
    // caller pre-set member variables
    public var mC1stVCdelegate:C1stVC_Delegate? = nil   // optional callback
    
    // member variables
    
    // member constants and other static content
    private let mCTAG:String = "VCUC1st"
    
    // outlets to screen controls
    @IBOutlet weak var textfield_nickname: UITextField!
    @IBAction func textfield_nickname_done(_ sender: UITextField) {
        textfield_nickname.resignFirstResponder()
    }
    @IBAction func button_1_pressed(_ sender: ResizableButton) {
        self.validateChoice(choice: 1)
    }
    @IBAction func button_2_pressed(_ sender: ResizableButton) {
        self.validateChoice(choice: 2)
    }
    @IBAction func button_3_pressed(_ sender: ResizableButton) {
        self.validateChoice(choice: 3)
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
        self.textfield_nickname.text = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.Collector_Nickname)
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func validateChoice(choice:Int) {
        if (textfield_nickname?.text ?? "").isEmpty {
            AppDelegate.showAlertDialog(vc:self, title:NSLocalizedString("Entry Error", comment:""), message:NSLocalizedString("Please fill in your nickname", comment:""), buttonText:NSLocalizedString("Okay", comment:""))
            return
        }
        if textfield_nickname?.text!.rangeOfCharacter(from: AppDelegate.mAcceptableNameChars.inverted) != nil {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Nickname can only contain letters, digits, space, or _ . + -", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return
        }

        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.Collector_Nickname, value: self.textfield_nickname.text!)
        if self.mC1stVCdelegate != nil { self.mC1stVCdelegate!.completed_C1stVC(fromVC:self, choice: choice) }
        self.mC1stVCdelegate = nil
    }
}
