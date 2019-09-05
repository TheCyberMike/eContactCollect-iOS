//
//  WizSendEmailDefine1ViewController.swift
//  eContact Collect
//
//  Created by Dev on 6/4/19.
//

import UIKit
import Eureka

class WizSendEmailDefine1ViewController: FormViewController {
    // member variables
    private var mSelections:SelectableSection<ListCheckRow<String>>? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCW4-1"
    private weak var mRootVC:WizMenuViewController? = nil
    
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC?.mWorking_EmailVia = nil
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
        
        // create an empty Email Via record if it does not already exist
        if self.mRootVC!.mWorking_EmailVia == nil {
            self.mRootVC!.mWorking_EmailVia = EmailVia()
        }
        
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
        if identifier != "Segue Next_W_EMAIL_1_6" { return true }
        let selected:String = self.mSelections!.selectedRow()!.selectableValue!
        switch selected {
        case "Skip":
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 4)
            AppDelegate.mFirstTImeStages = 4
            self.mRootVC?.mWorking_EmailVia = nil
            self.clearVC()
            if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
                self.navigationController!.popToRootViewController(animated: true)
            }
            return false
            
        case "Wizard":
            break
        default:
            break
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
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 100.0)
            $0.title = NSLocalizedString("Info", comment:"")
            $0.value = NSLocalizedString("%info%_WizSendEmailDefine1", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }
        
        // show the allowed selections
        self.mSelections = SelectableSection<ListCheckRow<String>>(NSLocalizedString("Please Choose Below then Press Next", comment:""), selectionType: .singleSelection(enableDeselection: false))
        form +++ self.mSelections!
        form.last! <<< ListCheckRow<String>("option_Skip"){ listRow in
            listRow.title = NSLocalizedString("Skip this step for now; the Wizard can be used later when first emailing", comment:"")
            listRow.selectableValue = "Skip"
            listRow.value = "Skip"
            }.cellUpdate { cell, row in
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.numberOfLines = 0
        }
        form.last! <<< ListCheckRow<String>("option_Wizard"){ listRow in
            listRow.title = NSLocalizedString("Use a Wizard to setup your sending email", comment:"")
            listRow.selectableValue = "Wizard"
            listRow.value = nil
            }.cellUpdate { cell, row in
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.numberOfLines = 0
        }
    }
}
