//
//  WizFormDefine6ViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/6/18.
//

import UIKit
import Eureka

class WizFormDefine6ViewController: UIViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW3-6"
    internal weak var mRootVC:WizMenuViewController? = nil
    private weak var mFormVC:WizFormDefine6FormViewController? = nil

    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Form_Rec = nil
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
        assert(self.mRootVC!.mWorking_Form_Rec != nil, "\(self.mCTAG).viewDidLoad self.mRootVC!.mWorking_Form_Rec == nil")
        assert(self.mRootVC!.mEFP != nil, "\(self.mCTAG).viewDidLoad self.mEFP == nil")
        
        // locate the child view controllers
        var orgTitleVC:OrgTitleViewController? = nil
        self.mFormVC = nil
        for childVC in children {
            let vc1:OrgTitleViewController? = childVC as? OrgTitleViewController
            let vc2:WizFormDefine6FormViewController? = childVC as? WizFormDefine6FormViewController
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
        if identifier != "Segue Next_W_FORM_2_3" { return true }
        self.clearVC()
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Form child ViewController
/////////////////////////////////////////////////////////////////////////

class WizFormDefine6FormViewController: FormViewController {
    // member variables
    private var mFormIsBuilt:Bool = false
    
    // member constants and other static content
    private let mCTAG:String = "VCW3-6F"
    private weak var mWiz6VC:WizFormDefine6ViewController? = nil
    
    private let SVFileModeStrings:[String] = [NSLocalizedString("Text file, rows Tab separated", comment:""),
                                              NSLocalizedString("Text file, rows Comma separated", comment:""),
                                              NSLocalizedString("Text file, rows Semicolon separated", comment:""),
                                              NSLocalizedString("XML file, rows Attrib/Value Pairs", comment:"")]
    private func svFileModeInt(fromString:String) -> Int {
        switch fromString {
        case SVFileModeStrings[0]: return 0
        case SVFileModeStrings[1]: return 1
        case SVFileModeStrings[2]: return 2
        case SVFileModeStrings[3]: return 3
        default: return 0
        }
    }
    
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
        self.mWiz6VC = (self.parent as! WizFormDefine6ViewController)
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
            $0.value = NSLocalizedString("%info%_WizFormDefine6", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }
        
        let section2 = Section(NSLocalizedString("Form SV-File Mode", comment:""))
        form +++ section2
        section2 <<< ActionSheetRow<String>() {
            $0.tag = "SV_file_type"
            $0.title = "Generate File Type"
            $0.selectorTitle = NSLocalizedString("Pick an option", comment:"")
            $0.options = SVFileModeStrings
            $0.value = SVFileModeStrings[self.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_SV_File_Type.rawValue]
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    switch self!.svFileModeInt(fromString: chgRow.value!)
                    {
                    case 0: self!.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_SV_File_Type = .TEXT_TAB_DELIMITED_WITH_HEADERS
                    case 1: self!.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_SV_File_Type = .TEXT_COMMA_DELIMITED_WITH_HEADERS
                    case 2: self!.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_SV_File_Type = .TEXT_SEMICOLON_DELIMITED_WITH_HEADERS
                    case 3: self!.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_SV_File_Type = .XML_ATTTRIB_VALUE_PAIRS
                    default: self!.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_SV_File_Type = .TEXT_TAB_DELIMITED_WITH_HEADERS
                    }
                }
        }
        section2 <<< TextRow() {
            $0.tag = "xml_collection_tag"
            $0.title = NSLocalizedString("Collection of records Tag", comment:"")
            $0.value = self.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_XML_Collection_Tag
            $0.hidden = Condition.function(["SV_file_type"], { [weak self] form in
                return !((form.rowBy(tag: "SV_file_type") as! ActionSheetRow<String>).value! == self!.SVFileModeStrings[3])
            })
            $0.add(rule: RuleRequired())
            $0.validationOptions = .validatesOnChange
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_XML_Collection_Tag = chgRow.value!
                }
        }
        section2 <<< TextRow() {
            $0.tag = "xml_record_tag"
            $0.title = NSLocalizedString("Per-record Tag", comment:"")
            $0.value = self.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_XML_Record_Tag
            $0.hidden = Condition.function(["SV_file_type"], { [weak self] form in
                return !((form.rowBy(tag: "SV_file_type") as! ActionSheetRow<String>).value! == self!.SVFileModeStrings[3])
            })
            $0.add(rule: RuleRequired())
            $0.validationOptions = .validatesOnChange
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mWiz6VC!.mRootVC!.mWorking_Form_Rec!.rForm_XML_Record_Tag = chgRow.value!
                }
        }
        self.mFormIsBuilt = true
    }
}
