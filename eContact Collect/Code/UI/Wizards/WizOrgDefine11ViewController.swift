//
//  WizOrgDefine11ViewController.swift
//  eContact Collect
//
//  Created by Yo on 11/20/18.
//  Copyright © 2018 Open Source. All rights reserved.
//

import UIKit
import Eureka

class WizOrgDefine11ViewController: FormViewController {
    // member variables
    private var mFirstTime:Bool = true
    private var mLangRows:OrgEditFormLangFields? = nil

    // member constants and other static content
    private let mCTAG:String = "VCW2-11"
    internal weak var mRootVC:WizMenuViewController? = nil
    
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Org_Rec = nil
        self.clearVC()
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
        
        // build the form but without content values to support PushRow MultiValuedSections
        self.buildForm()
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    // remember this will be called upon return from the language picker PushRow
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // set the form's values
        tableView.setEditing(true, animated: false) // this must be done in viewWillAppear() is within a ContainerView and using .Reorder MultivaluedSections
        self.revalueForm()
        self.mFirstTime = false
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
        if identifier != "Segue Next_W_ORG_11_16" { return true }
//debugPrint("\(self.mCTAG).shouldPerformSegue STARTED")
        
        // although the internal RecOrganizationLangs and the rOrg_LangRegionCodes_Supported SHOULD be already correct,
        // we will re-evaluate and reset all of them according to the final state of the form's fields
        do {
            try self.mLangRows!.finalizeLangRegions()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).shouldPerformSegue", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Filesystem Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            // allow the segue to occur even though we get errors
        }
        return true
    }
    
    // clear out the Form so this VC will deinit
    private func clearVC() {
        form.removeAll()
        tableView.reloadData()
        self.mRootVC = nil
    }
    
    // build the form
    // WARNING: must not rebuild the form as this breaks the MultivaluedSection PushRow return:
    //          self.viewWillAppear() and self.viewDidAppear() WILL be invoked upon return from the PushRow's view controller
    private func buildForm() {
        form.removeAll()
        tableView.reloadData()
        
        let section1 = Section()
        form +++ section1
        section1 <<< TextAreaRow() {
            $0.tag = "info"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 180.0)
            $0.title = NSLocalizedString("Info", comment:"")
            $0.value = NSLocalizedString("%info%_WizOrgDefine11", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }
        
        // add in the standard language Eureka Rows that this class and WizOrgDefine11ViewController can use
        self.mLangRows = OrgEditFormLangFields(form: form, orgRec: self.mRootVC!.mWorking_Org_Rec!, efp: nil, changeCallback: nil)
        self.mLangRows!.addFormLangRows()
        self.revalueForm()
    }
    
    // insert current working values into all the form's fields
    // this is done both after initial form creation and any re-display of the form;
    // WARNING: must not rebuild the form as this breaks the MultivaluedSection PushRow return:
    //          self.viewWillAppear() and self.viewDidAppear() WILL be invoked upon return from the PushRow's view controller
    private func revalueForm() {
        self.mLangRows!.revalueForm(firstTime: self.mFirstTime)
    }
    
    // make the LabelRow associated with the LangRegion of the SV-File not deletable
    override open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let superStyle = super.tableView(tableView, editingStyleForRowAt: indexPath)
        if self.mLangRows == nil { return superStyle }
        return self.mLangRows!.editingStyleForRowAt(indexPath: indexPath, superStyle: superStyle)
    }
    
    // this function will get invoked just before the move process
    // after this callback will be an immediate delete "rowsHaveBeenRemoved()" then insert "rowsHaveBeenAdded()"
    override func rowsWillBeMoved(movedRows:[BaseRow], sourceIndexes:[IndexPath], destinationIndexes:[IndexPath]) {
        super.rowsWillBeMoved(movedRows:movedRows, sourceIndexes:sourceIndexes, destinationIndexes:destinationIndexes)
        self.mLangRows?.rowsWillBeMoved(movedRows:movedRows, sourceIndexes:sourceIndexes, destinationIndexes:destinationIndexes)
    }
    
    // this function will get invoked when any rows are deleted or hidden anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        self.mLangRows?.rowsHaveBeenRemoved(rows, at: indexes)
    }
    
    // this function will get invoked when any rows are added or unhidden anywhere in the Form, include the MultivaluedSections
    // WARNING: this function also gets called when MOVING a row since effectively its a delete then add
    override func rowsHaveBeenAdded(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenAdded(rows, at: indexes)
        self.mLangRows?.rowsHaveBeenAdded(rows, at: indexes)
    }
}
