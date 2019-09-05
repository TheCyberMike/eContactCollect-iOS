//
//  WizSendEmailDefine11ViewController.swift
//  eContact Collect
//
//  Created by Dev on 6/4/19.
//

import UIKit
import Eureka

import UIKit
import Eureka

class WizSendEmailDefine11ViewController: FormViewController {
    // member variables
    private var mLocalEmailSetup:Bool = false
    
    // member constants and other static content
    private let mCTAG:String = "VCW4-11"
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
debugPrint("\(mCTAG).deinit STARTED")
    }
     
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        self.mRootVC = self.navigationController!.findViewController(ofKind: WizMenuViewController.self) as? WizMenuViewController
        assert(self.mRootVC != nil, "\(self.mCTAG).viewDidLoad self.mRootVC == nil")
        assert(self.mRootVC!.mWorking_EmailVia != nil, "\(self.mCTAG).viewDidLoad self.mRootVC!.mWorking_EmailVia == nil")
        
        // detect if local Mail App is even available
        self.mLocalEmailSetup = !EmailHandler.hasLocalMailApp()
        
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
        if identifier != "Segue Next_W_EMAIL_11_16" { return true }
        if !self.mLocalEmailSetup {
            // no Mail App was available
            let row1:SwitchRow = form.rowBy(tag: "useIOSemailSW2") as! SwitchRow
            if (row1.value ?? false) == true {
                if EmailHandler.hasLocalMailApp() {
                    // end-user does want to use the Mail App and has been given instructions on how to do so;
                    // they are supposed to press Next when it is all setup
                    do {
                        self.mRootVC!.mWorking_EmailVia = EmailVia(fromAPI: .iOSMail, displayName: self.mRootVC!.mWorking_EmailVia!.userDisplayName, sendingEmailAddr: self.mRootVC!.mWorking_EmailVia!.sendingEmailAddress)
                        try EmailHandler.shared.storeEmailVia(via: self.mRootVC!.mWorking_EmailVia!)
                        EmailHandler.shared.setLocalizedDefaultEmail(localizedName: self.mRootVC!.mWorking_EmailVia!.viaNameLocalized)
                        self.mRootVC?.mWorking_EmailVia = nil
                        self.clearVC()
                        if AppDelegate.mFirstTImeStages > 0 {
                            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 4)
                            AppDelegate.mFirstTImeStages = 4
                        }
                        if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
                            self.navigationController!.popToRootViewController(animated: true)
                        }
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).shouldPerformSegue.1", errorStruct: error, extra: nil)
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    }
                } else {
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Email Error", comment:""), message: "The native iOS Mail App appears to still be either uninstalled or not setup with accounts", buttonText: NSLocalizedString("Okay", comment:""))
                }
                return false
            }
        } else {
            // Mail App is available
            let row1:SwitchRow = form.rowBy(tag: "useIOSemailSW") as! SwitchRow
            let row2:SwitchRow = form.rowBy(tag: "useIOSemailHasSendEmailSW") as! SwitchRow
            let row3:SwitchRow = form.rowBy(tag: "useIOSemailAddSendEmailSW") as! SwitchRow
            
            if (row1.value ?? false) == true {
                // end-user does use the iOS Mail App
                if (row2.value ?? false) == true {
                    // email address is already configured into the iOS Mail App
                    do {
                        self.mRootVC!.mWorking_EmailVia = EmailVia(fromAPI: .iOSMail, displayName: self.mRootVC!.mWorking_EmailVia!.userDisplayName, sendingEmailAddr: self.mRootVC!.mWorking_EmailVia!.sendingEmailAddress)
                        try EmailHandler.shared.storeEmailVia(via: self.mRootVC!.mWorking_EmailVia!)
                        EmailHandler.shared.setLocalizedDefaultEmail(localizedName: self.mRootVC!.mWorking_EmailVia!.viaNameLocalized)
                        self.mRootVC?.mWorking_EmailVia = nil
                        self.clearVC()
                        if AppDelegate.mFirstTImeStages > 0 {
                            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 4)
                            AppDelegate.mFirstTImeStages = 4
                        }
                        if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
                            self.navigationController!.popToRootViewController(animated: true)
                        }
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).shouldPerformSegue.2", errorStruct: error, extra: nil)
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    }
                    return false
                    
                } else if (row3.value ?? false) == true {
                    // email address is wanted to be added into the iOS Mail App so invoke Settings for them
                    do {
                        self.mRootVC!.mWorking_EmailVia = EmailVia(fromAPI: .iOSMail, displayName: self.mRootVC!.mWorking_EmailVia!.userDisplayName, sendingEmailAddr: self.mRootVC!.mWorking_EmailVia!.sendingEmailAddress)
                        try EmailHandler.shared.storeEmailVia(via: self.mRootVC!.mWorking_EmailVia!)
                        EmailHandler.shared.setLocalizedDefaultEmail(localizedName: self.mRootVC!.mWorking_EmailVia!.viaNameLocalized)
                        self.mRootVC!.mWorking_EmailVia = nil
                        self.clearVC()
                        if AppDelegate.mFirstTImeStages > 0 {
                            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 4)
                            AppDelegate.mFirstTImeStages = 4
                        }
                        self.navigationController?.popToRootViewController(animated: true)
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).shouldPerformSegue.3", errorStruct: error, extra: nil)
                        AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    }
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    return false
                }
            }
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
                 $0.tag = "info1"
                 $0.textAreaHeight = .dynamic(initialTextViewHeight: 100.0)
                 $0.title = NSLocalizedString("Info", comment:"")
                 $0.value = NSLocalizedString("%info%_WizSendEmailDefine11", comment:"")
                 $0.disabled = true
             }.cellUpdate { cell, row in
                 cell.textView.font = .systemFont(ofSize: 17.0)
                 cell.textView.textColor = UIColor.black
        }
     
        let section2 = Section()
        form +++ section2
        section2 <<< TextRow() {
                 $0.tag = "sendEmailAddr"
                 $0.title = NSLocalizedString("Email Addr", comment:"")
                 $0.value = self.mRootVC!.mWorking_EmailVia!.sendingEmailAddress
                 $0.disabled = true
             }.cellUpdate { cell, row in
                cell.textField.font = .systemFont(ofSize: 14.0)
        }
        if self.mLocalEmailSetup {
            section2 <<< LabelRow() {
                $0.tag = "info2"
                $0.value = NSLocalizedString("Native iOS Mail App appears to be usable", comment:"")
                $0.disabled = true
                }.cellUpdate { cell, row in
                    cell.textLabel?.font = .systemFont(ofSize: 15.0)
                    cell.textLabel?.textColor = UIColor.black
            }
            
            let section3 = Section()
            form +++ section3
            
            section3 <<< LabelRow() {
                $0.tag = "useIOSemailLBL"
                $0.title = NSLocalizedString("Do you use the native iOS Mail App?", comment:"")
                }.cellUpdate { cell, row in
                    cell.textLabel?.numberOfLines = 0
            }
            section3 <<< SwitchRow() {
                $0.tag = "useIOSemailSW"
                $0.title = NSLocalizedString("Use?", comment:"")
                $0.value = false
                }.onChange { chgRow in
            }
            
            section3 <<< LabelRow() {
                $0.tag = "useIOSemailHasSendEmailLBL"
                $0.title = NSLocalizedString("Is the email address above configured to send email in the native iOS Mail App?", comment:"")
                $0.hidden = "$useIOSemailSW == false"
                }.cellUpdate { cell, row in
                    cell.textLabel?.numberOfLines = 0
            }
            section3 <<< SwitchRow() {
                $0.tag = "useIOSemailHasSendEmailSW"
                $0.title = NSLocalizedString("Configured?", comment:"")
                $0.value = true
                $0.hidden = "$useIOSemailSW == false"
                }.onChange { chgRow in
            }
            
            section3 <<< LabelRow() {
                $0.tag = "useIOSemailAddSendEmailLBL"
                $0.title = NSLocalizedString("Do you wish to add the email address above to the Accounts for the native iOS Mail App?", comment:"")
                $0.hidden = "$useIOSemailSW == false || $useIOSemailHasSendEmailSW == true"
                }.cellUpdate { cell, row in
                    cell.textLabel?.numberOfLines = 0
            }
            section3 <<< SwitchRow() {
                $0.tag = "useIOSemailAddSendEmailSW"
                $0.title = NSLocalizedString("Add?", comment:"")
                $0.value = false
                $0.hidden = "$useIOSemailSW == false || $useIOSemailHasSendEmailSW == true"
                }.onChange { chgRow in
            }
            
            section3 <<< LabelRow() {
                $0.tag = "pressNext"
                $0.title = NSLocalizedString("Press Next when all the questions are answered correctly.", comment:"")
                }.cellUpdate { cell, row in
                    cell.textLabel?.numberOfLines = 0
            }
        } else {
            section2 <<< LabelRow() {
                $0.tag = "info2"
                $0.value = NSLocalizedString("Native iOS Mail App is not setup", comment:"")
                $0.disabled = true
                }.cellUpdate { cell, row in
                    cell.textLabel?.font = .systemFont(ofSize: 15.0)
                    cell.textLabel?.textColor = UIColor.black
            }
            
            let section3 = Section()
            form +++ section3
            
            section3 <<< LabelRow() {
                $0.tag = "useIOSemailLBL2"
                $0.title = NSLocalizedString("Do you want to use the native iOS Mail App to send emails?", comment:"")
                }.cellUpdate { cell, row in
                    cell.textLabel?.numberOfLines = 0
            }
            section3 <<< SwitchRow() {
                $0.tag = "useIOSemailSW2"
                $0.title = NSLocalizedString("Use?", comment:"")
                $0.value = false
                }.onChange { chgRow in
            }
            section3 <<< TextAreaRow() {
                $0.tag = "info3"
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 100.0)
                $0.title = NSLocalizedString("Info", comment:"")
                $0.value = NSLocalizedString("%info%_WizSendEmailDefine11_Install", comment:"")
                $0.disabled = true
                $0.hidden = "$useIOSemailSW2 == false"
                }.cellUpdate { cell, row in
                    cell.textView.font = .systemFont(ofSize: 15.0)
                    cell.textView.textColor = UIColor.black
            }
            section3 <<< LabelRow() {
                $0.tag = "pressNext1"
                $0.title = NSLocalizedString("Press Next when the above has been completed.", comment:"")
                $0.hidden = "$useIOSemailSW2 == false"
                }.cellUpdate { cell, row in
                    cell.textLabel?.numberOfLines = 0
            }
            section3 <<< LabelRow() {
                $0.tag = "pressNext2"
                $0.title = NSLocalizedString("Press Next when all the questions are answered correctly.", comment:"")
                $0.hidden = "$useIOSemailSW2 == true"
                }.cellUpdate { cell, row in
                    cell.textLabel?.numberOfLines = 0
            }
        }
    }
}
