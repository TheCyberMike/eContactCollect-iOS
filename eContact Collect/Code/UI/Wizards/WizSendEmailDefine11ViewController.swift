//
//  WizSendEmailDefine11ViewController.swift
//  eContact Collect
//
//  Created by Dev on 6/4/19.
//

import UIKit
import Eureka

class WizSendEmailDefine11ViewController: FormViewController {
    /*
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
    @IBAction func button_done_pressed(_ sender: UIBarButtonItem) {
        if EmailHandler.shared.getQtyEmailOptions() == 0 {
            AppDelegate.showYesNoDialog(vc:self, title:NSLocalizedString("Confirmation", comment:""), message:NSLocalizedString("There are no Sending Email Addresses defined; are you sure you are Done?", comment:""), buttonYesText:NSLocalizedString("Leave", comment:""), buttonNoText:NSLocalizedString("Stay", comment:""), callbackAction:1, callbackString1:nil, callbackString2:nil, completion: {(vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                // callback from the yes/no dialog upon one of the buttons being pressed
                if theResult {
                    // answer was Leave
                    if AppDelegate.mFirstTImeStages > 0 {
                        AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 4)
                        AppDelegate.mFirstTImeStages = 4
                    }
                    self.mRootVC!.mWorking_EmailVia = nil
                    self.clearVC()
                    self.navigationController?.popToRootViewController(animated: true)
                }
                return  // from callback
            })
        } else {
            if AppDelegate.mFirstTImeStages > 0 {
                AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 4)
                AppDelegate.mFirstTImeStages = 4
            }
            self.mRootVC!.mWorking_EmailVia = nil
            self.clearVC()
            if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
                self.navigationController!.popToRootViewController(animated: true)
            }
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
        assert(self.mRootVC!.mWorking_EmailVia != nil, "\(self.mCTAG).viewDidLoad self.mRootVC!.mWorking_EmailVia == nil")
        
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
    
    // clear out the Form so this VC will deinit
    private func clearVC() {
        form.removeAll()
        tableView.reloadData()
    }
    
    // build the form
    private func buildForm() {
        form.removeAll()
        tableView.reloadData()
        
        let section1 = Section(NSLocalizedString("Select new provider to add", comment:""))
        form +++ section1
        
        let emailViaPotentials:[EmailVia] = EmailHandler.shared.getListPotentialEmailProviders()
        for via in emailViaPotentials {
            section1 <<< ButtonRow(){ row in
                row.tag = "PV,\(via.emailProvider_InternalName)"
                row.title = via.viaNameLocalized
                row.retainedObject = via
                row.presentationMode = .show(
                    // selecting the ButtonRow invokes FormEditFieldFormViewController with callback so the row's content can be refreshed
                    controllerProvider: .callback(builder: { [weak row] in
                        let vc = AdminPrefsEditEmailAccountViewController()
                        vc.mEditVia = (row!.retainedObject as! EmailVia)
                        vc.mEditVia!.sendingEmailAddress = self.mRootVC!.mWorking_EmailVia!.sendingEmailAddress
                        vc.mAction = .Add
                        return vc
                    }),
                    onDismiss: { [weak row] vc in
                        row!.updateCell()
                })
                }.cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .left
                    //cell.textLabel?.font = .systemFont(ofSize: 15.0)
                    cell.textLabel?.textColor = UIColor.black
                    cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }
        }
    }
 */
}

