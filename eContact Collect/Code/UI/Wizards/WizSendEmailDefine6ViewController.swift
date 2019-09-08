//
//  WizSendEmailDefine6ViewController.swift
//  eContact Collect
//
//  Created by Dev on 6/4/19.
//

import UIKit
import Eureka

class WizSendEmailDefine6ViewController: FormViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW4-6"
    private weak var mRootVC:WizMenuViewController? = nil
     
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_EmailVia = nil
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
        
        // create an empty Email Via record the first time the screen is created
        self.mRootVC!.mWorking_EmailVia = EmailVia()
     
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
        if identifier != "Segue Next_W_EMAIL_6_11" { return true }
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
        if self.mRootVC!.mWorking_EmailVia!.sendingEmailAddress.isEmpty {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Email Address cannot be empty", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        return true
    }
     
    // clear out the Form so this VC will deinit
    private func clearVC() {
        form.removeAll()
        tableView.reloadData()
    }
     
    // build the form
    private func buildForm() {
        form.removeAll()
        tableView.reloadData()
     
        let section1 = Section()
        form +++ section1
        section1 <<< TextAreaRow() {
                 $0.tag = "info"
                 $0.textAreaHeight = .dynamic(initialTextViewHeight: 60.0)
                 $0.title = NSLocalizedString("Info", comment:"")
                 $0.value = NSLocalizedString("%info%_WizSendEmailDefine6", comment:"")
                 $0.disabled = true
             }.cellUpdate { cell, row in
                 cell.textView.font = .systemFont(ofSize: 17.0)
                 cell.textView.textColor = UIColor.black
        }
     
        let section2 = Section(NSLocalizedString("Sending Email", comment:""))
        form +++ section2
     
        section2 <<< TextRow() {
            $0.title = NSLocalizedString("Email Name", comment:"")
            $0.tag = "sendingEmailName"
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mRootVC!.mWorking_EmailVia!.userDisplayName = chgRow.value!
                } else {
                    self!.mRootVC!.mWorking_EmailVia!.userDisplayName = ""
                }
        }
        
        section2 <<< EmailRow() {
                 $0.tag = "sendingEmail"
                 $0.title = NSLocalizedString("Email Addr", comment:"")
                 $0.add(rule: RuleRequired())
                 $0.add(rule: RuleEmail(msg: NSLocalizedString("Email Address is invalid", comment:"")) )
                 $0.validationOptions = .validatesAlways
            }.cellUpdate { cell, row in
                cell.textField.font = .systemFont(ofSize: 14.0)
                 if !row.isValid {
                     cell.titleLabel?.textColor = .red
                 }
            }.onChange { [weak self] chgRow in
                 if !(chgRow.value ?? "").isEmpty {
                    self!.mRootVC!.mWorking_EmailVia!.sendingEmailAddress = chgRow.value!
                 }
         }
    }
}
