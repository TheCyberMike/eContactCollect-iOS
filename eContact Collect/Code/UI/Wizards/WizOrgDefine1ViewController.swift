//
//  WizOrgDefine1ViewController.swift
//  eContact Collect
//
//  Created by Yo on 11/30/18.
//

import UIKit
import Eureka

class WizOrgDefine1ViewController: FormViewController, UIDocumentPickerDelegate, CIVC_Delegate {
    // member variables
    private var mSelections:SelectableSection<ListCheckRow<String>>? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCW2-1"
    private weak var mRootVC:WizMenuViewController? = nil
    
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
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
        if identifier != "Segue Next_W_ORG_1_3" { return true }
        let selected:String = self.mSelections!.selectedRow()!.selectableValue!
        switch selected {
        case "Create":
            // create a default Org
            do {
                let orgRec:RecOrganizationDefs = try DatabaseHandler.shared.createDefaultOrg()
                self.mRootVC!.mWorking_Org_Rec = orgRec
                (UIApplication.shared.delegate as! AppDelegate).checkCurrentOrg(withOrgRec: orgRec)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).shouldPerformSegue", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
            self.clearVC()
            if !self.navigationController!.popToViewController(ofKind: WizMenuViewController.self) {
                self.navigationController!.popToRootViewController(animated: true)
            }
            return false
            
        case "Import":
            let documentPicker:UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["opensource.theCyberMike.eContactCollect.eContactCollectConfig"], in: UIDocumentPickerMode.import)
            documentPicker.delegate = self
            documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            self.present(documentPicker, animated: true, completion: nil)
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
        self.mRootVC!.mWorking_Org_Rec = nil
        form.removeAll()
        tableView.reloadData()
        self.mSelections = nil
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
            $0.value = NSLocalizedString("%info%_WizOrgDefine1", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }
        
        // show the allowed selections
        self.mSelections = SelectableSection<ListCheckRow<String>>(NSLocalizedString("Please Choose Below then Press Next", comment:""), selectionType: .singleSelection(enableDeselection: false))
        form +++ self.mSelections!
        form.last! <<< ListCheckRow<String>("option_Create"){ listRow in
                listRow.title = NSLocalizedString("Create a simple default Organization you can edit later", comment:"")
                listRow.selectableValue = "Create"
                listRow.value = "Create"
            }.cellUpdate { cell, row in
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.numberOfLines = 0
        }
        form.last! <<< ListCheckRow<String>("option_import"){ listRow in
                listRow.title = NSLocalizedString("Import an Organization Definitions file you have already been given", comment:"")
                listRow.selectableValue = "Import"
                listRow.value = nil
            }.cellUpdate { cell, row in
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.numberOfLines = 0
        }
        form.last! <<< ListCheckRow<String>("option_wizard"){ listRow in
                listRow.title = NSLocalizedString("Use a Wizard to create and customize an Organization in detail", comment:"")
                listRow.selectableValue = "Wizard"
                listRow.value = nil
            }.cellUpdate { cell, row in
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.numberOfLines = 0
        }
    }
    
    // return from the document picker
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//debugPrint("\(self.mCTAG).documentPicker.didPickDocumentsAt STARTED URL=\(urls[0].path)")
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC PopupImport") as! PopupImportViewController
        newViewController.mCIVCdelegate = self
        newViewController.mFromExternal = false
        newViewController.mFileURL = urls[0]
        newViewController.modalPresentationStyle = .custom
        self.present(newViewController, animated: true, completion: nil)
    }
    
    // return from a successful import
    func completed_CIVC_ImportSuccess(fromVC:PopupImportViewController, orgWasImported:String, formWasImported:String?) {
//debugPrint("\(self.mCTAG).completed_CIVC_ImportSuccess STARTED")
        (UIApplication.shared.delegate as! AppDelegate).setCurrentOrg(toOrgShortName: orgWasImported)
        self.mRootVC!.mWorking_Org_Rec = nil
        self.navigationController?.popToRootViewController(animated: true)
    }
}
