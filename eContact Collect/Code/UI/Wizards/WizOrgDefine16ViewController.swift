//
//  WizOrgDefine16ViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/4/18.
//

import UIKit
import Eureka

class WizOrgDefine16ViewController: FormViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW2-16"
    private weak var mRootVC:WizMenuViewController? = nil

    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC?.mWorking_Org_Rec = nil
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
        assert(self.mRootVC!.mWorking_Org_Rec != nil, "\(self.mCTAG).viewDidLoad self.mRootVC!.mWorking_Org_Rec == nil")
        
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
        if identifier != "Segue Next_W_ORG_16_21" { return true }
        // at this stage set for title-only mode
        self.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode = RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE
        return true
    }
    
    // clear out the Form so this VC will deinit
    private func clearVC() {
        form.removeAll()
        tableView.reloadData()
        self.mRootVC = nil
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
            $0.value = NSLocalizedString("%info%_WizOrgDefine16", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }

        let section2 = Section(NSLocalizedString("Organization Title(s)", comment:""))
        form +++ section2
        
        for langRegionCode in self.mRootVC!.mWorking_Org_Rec!.rOrg_LangRegionCodes_Supported {
            section2 <<< TextAreaRowExt() {
                $0.tag = "org_shown_title_\(langRegionCode)"
                $0.title = NSLocalizedString("Org Title for ", comment:"") + AppDelegate.makeFullDescription(forLangRegion: langRegionCode)
                do {
                    $0.value = try self.mRootVC!.mWorking_Org_Rec!.getOrgTitleShown(langRegion: langRegionCode)
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).buildForm", errorStruct: error, extra: nil)
                    // do not show error to end-user
                }
                $0.textAreaHeight = .fixed(cellHeight: 50)
                $0.textAreaWidth = .fixed(cellWidth: 300)
                }.cellUpdate { cell, row in
                    cell.textView.autocapitalizationType = .words
                    cell.textView.font = .boldSystemFont(ofSize: 17.0)
                    cell.textView.layer.cornerRadius = 0
                    cell.textView.layer.borderColor = UIColor.gray.cgColor
                    cell.textView.layer.borderWidth = 1
                }.onChange { [weak self] chgRow in
                    do {
                        try self!.mRootVC!.mWorking_Org_Rec!.setOrgTitleShown_Editing(langRegion: langRegionCode, title: chgRow.value)
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).buildForm", errorStruct: error, extra: nil)
                        AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Filesystem Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                    }
            }
        }
    }
}

