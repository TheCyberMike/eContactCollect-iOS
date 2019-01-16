//
//  WizFormDefine11ViewController.swift
//  eContact Collect
//
//  Created by Yo on 11/23/18.
//

import UIKit
import Eureka

class WizFormDefine11ViewController: UIViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW3-11"
    internal weak var mRootVC:WizMenuViewController? = nil
    private weak var mFormVC:WizFormDefine11FormViewController? = nil
    
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Form_Rec = nil
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
        assert(self.mRootVC!.mWorking_Form_Rec != nil, "\(self.mCTAG).viewDidLoad self.mRootVC!.mWorking_Form_Rec == nil")
        assert(self.mRootVC!.mEFP != nil, "\(self.mCTAG).viewDidLoad self.mEFP == nil")
        
        // locate the child view controllers
        var orgTitleVC:OrgTitleViewController? = nil
        self.mFormVC = nil
        for childVC in children {
            let vc1:OrgTitleViewController? = childVC as? OrgTitleViewController
            let vc2:WizFormDefine11FormViewController? = childVC as? WizFormDefine11FormViewController
            if vc1 != nil { orgTitleVC = vc1 }
            if vc2 != nil { self.mFormVC = vc2 }
        }
        assert(self.mFormVC != nil, "\(self.mCTAG).viewDidLoad self.mFormVC == nil")
        assert(orgTitleVC != nil, "\(self.mCTAG).viewDidLoad orgTitleVC == nil")        
        orgTitleVC!.mEFP = self.mRootVC!.mEFP!
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when the view has fully appeared
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)
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
    
    // clear out the Form so this VC will deinit
    private func clearVC() {
        self.mFormVC?.clearVC()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // intercept the Next segue
    override open func shouldPerformSegue(withIdentifier identifier:String, sender:Any?) -> Bool {
        if identifier != "Segue Next_W_FORM_3_4" { return true }
        // finalize the LangRegion settings to what is shown on the Form
        if !self.mFormVC!.finalizeLangs() { return false }
        self.clearVC()
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Form child ViewController
/////////////////////////////////////////////////////////////////////////

class WizFormDefine11FormViewController: FormViewController {
    // member variables
    private var mFormIsBuilt:Bool = false
    
    // member constants and other static content
    private let mCTAG:String = "VCW3-11F"
    private weak var mWiz11VC:WizFormDefine11ViewController? = nil
    private var mLangsMode:String = ""
    private var mLang1:String? = nil
    private var mLang2:String? = nil
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        // self.parent is not set until viewWillAppear()
    }
    
    // called by the framework when the view will re-appear;
    // remember this will be called upon return from the image chooser dialog
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // locate our parent then build the form; initializing values as we go
        self.mWiz11VC = (self.parent as! WizFormDefine11ViewController)
        self.buildForm()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // clear out the Form (caused by segue or cancel)
    public func clearVC() {
        form.removeAll()
        tableView.reloadData()
        self.mFormIsBuilt = false
    }
    
    // finalize the Form's settings into the Form record
    public func finalizeLangs() -> Bool {
        if self.mLangsMode == "All Languages" {
            self.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions = nil
        } else if self.mLangsMode == "One Language" {
            if self.mLang1 == nil {
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Must choose one language", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                return false
            }
            self.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions = [mLang1!]
        } else {
            if self.mLang1 == nil || self.mLang2 == nil {
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Must choose two languages", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                return false
            }
            self.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions = [mLang1!, mLang2!]
        }
        return true
    }
    
    // build the form
    private func buildForm() {
        if self.mFormIsBuilt { return }
        form.removeAll()
        tableView.reloadData()
        
        let section1 = Section()
        form +++ section1
        section1 <<< TextAreaRow() {
            $0.tag = "info"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 100.0)
            $0.title = NSLocalizedString("Info", comment:"")
            $0.value = NSLocalizedString("%info%_WizFormDefine11", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }
        
        let section2 = Section(NSLocalizedString("Form Languages Mode", comment:""))
        form +++ section2
        section2 <<< SegmentedRowExt<String>("form_langs_mode") { [weak self] row in
                row.title = "Languages Mode"
                row.options = ["One Language","Bilingual","All Languages"]
                let cnt:Int = (self!.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions?.count ?? 0)
                if cnt >= 2 { row.value = Set(["Bilingual"]); self!.mLangsMode = "Bilingual" }
                else if cnt == 1 { row.value = Set(["One Language"]); self!.mLangsMode = "One Language" }
                else { row.value = Set(["All Languages"]); self!.mLangsMode = "All Languages" }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mLangsMode = chgRow.value!.first!
                }
        }
        section2 <<< SegmentedRowExt<String>() { [weak self] row in
            row.tag = "form_langs_only_1"
            row.title = "Shown Language"
            row.hidden = Condition.function(["form_langs_mode"], { form in
                    if let val:Set<String> = (form.rowBy(tag: "form_langs_mode") as! SegmentedRowExt<String>).value {
                        if val.first != "One Language" { return true }
                    }
                    return false
                })
            row.options = self!.mWiz11VC!.mRootVC!.mWorking_Org_Rec!.rOrg_LangRegionCodes_Supported
            if (self!.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions?.count ?? 0) >= 1 {
                row.value = Set<String>([self!.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions![0]])
            }
            row.displayValueFor = { set in
                    if set == nil { return nil }
                    return set!.map { (Locale.current.localizedString(forLanguageCode: $0) ?? "") + " (\($0))" }.joined(separator: ", ")
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mLang1 = chgRow.value!.first!
                }
        }
        section2 <<< SegmentedRowExt<String>() { [weak self] row in
            row.tag = "form_langs_bi_first"
            row.title = "Upper Shown Language"
            row.hidden = Condition.function(["form_langs_mode"], { form in
                if let val:Set<String> = (form.rowBy(tag: "form_langs_mode") as! SegmentedRowExt<String>).value {
                    if val.first != "Bilingual" { return true }
                }
                return false
            })
            row.options = self!.mWiz11VC!.mRootVC!.mWorking_Org_Rec!.rOrg_LangRegionCodes_Supported
            if (self!.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions?.count ?? 0) >= 1 {
                row.value = Set<String>([self!.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions![0]])
            }
            row.displayValueFor = { set in
                    if set == nil { return nil }
                    return set!.map { (Locale.current.localizedString(forLanguageCode: $0) ?? "") + " (\($0))" }.joined(separator: ", ")
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mLang1 = chgRow.value!.first!
                }
        }
        section2 <<< SegmentedRowExt<String>() { [weak self] row in
            row.tag = "form_langs_bi_second"
            row.title = "Lower Shown Language"
            row.hidden = Condition.function(["form_langs_mode"], { form in
                if let val:Set<String> = (form.rowBy(tag: "form_langs_mode") as! SegmentedRowExt<String>).value {
                    if val.first != "Bilingual" { return true }
                }
                return false
            })
            row.options = self!.mWiz11VC!.mRootVC!.mWorking_Org_Rec!.rOrg_LangRegionCodes_Supported
            if (self!.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions?.count ?? 0) >= 2 {
                row.value = Set<String>([self!.mWiz11VC!.mRootVC!.mWorking_Form_Rec!.rForm_Lingual_LangRegions![1]])
            }
            row.displayValueFor = { set in
                    if set == nil { return nil }
                    return set!.map { (Locale.current.localizedString(forLanguageCode: $0) ?? "") + " (\($0))" }.joined(separator: ", ")
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil, chgRow.value!.first != nil {
                    self!.mLang2 = chgRow.value!.first!
                }
        }
        self.mFormIsBuilt = true
    }
}

