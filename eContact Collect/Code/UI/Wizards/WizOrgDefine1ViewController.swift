//
//  WizOrgDefine1ViewController.swift
//  eContact Collect
//
//  Created by Yo on 11/30/18.
//

import UIKit

class WizOrgDefine1ViewController: UIViewController, UIDocumentPickerDelegate {
    // member constants and other static content
    private let mCTAG:String = "VCW2-1"
    private weak var mRootVC:WizMenuViewController? = nil
    
    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Org_Rec = nil
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func button_import_pressed(_ sender: UIButton) {
        let documentPicker:UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["opensource.theCyberMike.eContactCollect.eContactCollectConfig"], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
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
    
    // return from the document picker
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//debugPrint("\(self.mCTAG).documentPicker.didPickDocumentsAt STARTED URL=\(urls[0].path)")
        UIHelpers.importConfigFile(fromURL: urls[0], usingVC: self, finalDialogCompletion: { vc, url, theChoice, theResult in
            if theResult {
                self.mRootVC!.mWorking_Org_Rec = nil
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
    }
    
    // intercept the Next segue
    override open func shouldPerformSegue(withIdentifier identifier:String, sender:Any?) -> Bool {
        if identifier != "Segue Next_W_ORG_1_3" { return true }
        // an import was not chosen or did not succeed
        return true
    }
}

