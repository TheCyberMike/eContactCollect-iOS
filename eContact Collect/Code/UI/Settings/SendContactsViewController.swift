//
//  SendContactsViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/13/18.
//

import UIKit
import MessageUI
import MobileCoreServices
import Eureka

class SendContactsViewController: UIViewController {
    // member variables
    public var mDismissing:Bool = false
    
    // member constants and other static content
    private let mCTAG:String = "VCSCS"

    // outlets to screen controls

    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewWillDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent ||
           (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            self.mDismissing = true
        }
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent {
            self.mDismissing = true
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
        } else if (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            self.mDismissing = true
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC's NC IS DISMISSED \(self)")
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed \(self)")
        }
        super.viewDidDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

/////////////////////////////////////////////////////////////////////////
// Child FormViewController
/////////////////////////////////////////////////////////////////////////

class SendContactsFormViewController: FormViewController, UIActivityItemSource, MFMailComposeViewControllerDelegate {
    // member variables
    private var mNoDelete:Bool = false
    private var mMVSfilesPending:MultivaluedSection? = nil
    private var mMVSfilesSent:MultivaluedSection? = nil
    private var mSharedFileURL:URL? = nil
    private var mSharedFileUTI:String? = nil
    private var mSharedFileName:String? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCSCSF"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
        rowKeyboardSpacing = 5
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        tableView.setEditing(true, animated: false) // this is necessary if in a ContainerView
    }
    
    // called by the framework when the view will soon disappear from the UI framework; needs to be done before viewDidDisappear() so self.parent is valid;
    // remember this does NOT necessarily mean the view is being dismissed since viewWillDisappear() will be called if this VC opens another VC;
    // need to forceably clear out the form so this VC will deinit()
    override func viewWillDisappear(_ animated:Bool) {
        if self.parent != nil {
            let myParent:SendContactsViewController = self.parent as! SendContactsViewController
            if myParent.mDismissing {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED AND PARENT VC IS DISMISSING parent=\(self.parent!)")
                self.mMVSfilesPending = nil
                self.mMVSfilesSent = nil
                form.removeAll()
                tableView.reloadData()
            } else {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED BUT PARENT VC is not being dismissed parent=\(self.parent!)")
            }
        } else {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED NO PARENT VC")
        }
        super.viewWillDisappear(animated)
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // build the form
    private func buildForm() {
        var qty:Int64 = 0
        if AppDelegate.mEntryFormProvisioner != nil {
            do {
                qty = try RecContactsCollected.ccGetQtyRecs(forOrgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).buildForm", during:"ccGetQtyRecs#1", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
        }

        let section1 = Section(NSLocalizedString("Generate Attachments", comment:""))
        form +++ section1
        section1 <<<  LabelRow() {
            $0.title = NSLocalizedString("Contacts not-yet-sent", comment:"") + ": \(qty)"
            $0.tag = "info_not_yet_sent"
        }
        
        section1 <<< ButtonRow() {
            $0.title = NSLocalizedString("Generate new attachments", comment:"")
            $0.tag = "button_generate"
            $0.disabled = (qty <= 0) ? true : false
            $0.evaluateDisabled()
            $0.onCellSelection { [weak self] cell, row in
//debugPrint("\(self.mCTAG).buildForm.ButtonRow<Generate>.onCellSelection STARTED")
                let success = self!.generateNewSVFiles()
                if success {
                    var qty1:Int64 = 0
                    if AppDelegate.mEntryFormProvisioner != nil {
                        do {
                            qty1 = try RecContactsCollected.ccGetQtyRecs(forOrgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                        } catch {
                            AppDelegate.postToErrorLogAndAlert(method: "\(self!.mCTAG).buildForm", during:"ccGetQtyRecs#2", errorStruct: error, extra: nil)
                            AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                        }
                    }
                    let labelRow:LabelRow = self!.form.rowBy(tag: "info_not_yet_sent") as! LabelRow
                    labelRow.title = NSLocalizedString("Contacts not-yet-sent", comment:"") + ": \(qty1)"
                    labelRow.updateCell()
                    let buttonRow:ButtonRow = self!.form.rowBy(tag: "button_generate") as! ButtonRow
                    buttonRow.disabled = true
                    buttonRow.evaluateDisabled()
                    buttonRow.updateCell()
                    self!.displayListOfFiles()
                }
            }
        }
        
        self.mMVSfilesPending = MultivaluedSection(multivaluedOptions: [.Delete],
            header: NSLocalizedString("Pending Attachments; press to email or share", comment:"")) {
                $0.showInsertIconInAddButton = false
                $0.tag = "$Pending"
        }
        form +++ self.mMVSfilesPending!
        
        self.mMVSfilesSent = MultivaluedSection(multivaluedOptions: [.Delete],
              header: NSLocalizedString("Retained Sent Attachments (held for 7 days); press to re-email or re-share", comment:"")) {
                $0.showInsertIconInAddButton = false
                $0.tag = "$Sent"
        }
        form +++ self.mMVSfilesSent!
        self.displayListOfFiles()
    }
    
    private func displayListOfFiles() {
        var fileURLs:[URL]? = nil
        do {
            fileURLs = try AppDelegate.mSVFilesHandler!.getPendingFiles()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).displayListOfFiles", during: "getPendingFiles", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
        self.mNoDelete = true
        self.mMVSfilesPending!.removeAll()
        self.mNoDelete = false
        for url in fileURLs! {
            let fileName:String = url.lastPathComponent
            self.mMVSfilesPending! <<< SegmentedRow<UIImage>() {
                $0.title = fileName
                $0.options = [#imageLiteral(resourceName: "Email"),#imageLiteral(resourceName: "Share")]
                $0.cellSetup { cell, row in
                    cell.textLabel?.font = .systemFont(ofSize: 12.0)
                }
                $0.onCellSelection { cell, row in
                    self.emailSVfile(filePath:AppDelegate.mSVFilesHandler!.makePendingFullPath(fileName:row.title!), fileName:row.title!)
                }
                $0.onChange { row in
                    switch row.cell.segmentedControl.selectedSegmentIndex {
                    case 0:
                        self.emailSVfile(filePath:AppDelegate.mSVFilesHandler!.makePendingFullPath(fileName:row.title!), fileName:row.title!)
                        break
                    case 1:
                        var anchorRect = row.cell.segmentedControl.subviews[0].frame    // segmentedRow adds buttons in backwards order
                        anchorRect = self.view.convert(anchorRect, from: row.cell.segmentedControl)
                        self.shareSVfile(filePath:AppDelegate.mSVFilesHandler!.makePendingFullPath(fileName:row.title!), fileName:row.title!, selfViewAnchorRect: anchorRect)
                        break
                    default:
                        break
                    }
                    row.value = nil
                    row.cell.segmentedControl.selectedSegmentIndex = -1
                    row.updateCell()
                }
            }
        }
        
        do {
            fileURLs = try AppDelegate.mSVFilesHandler!.getSentFiles()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).displayListOfFiles", during: "getSentFiles", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("File Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
        self.mNoDelete = true
        self.mMVSfilesSent!.removeAll()
        self.mNoDelete = false
        for url in fileURLs! {
            let fileName:String = url.lastPathComponent
            self.mMVSfilesSent! <<< SegmentedRow<UIImage>() {
                $0.title = fileName
                $0.options = [#imageLiteral(resourceName: "Email"),#imageLiteral(resourceName: "Share")]
                $0.cellSetup { cell, row in
                    cell.textLabel?.font = .systemFont(ofSize: 12.0)
                }
                $0.onCellSelection { cell, row in
                    self.emailSVfile(filePath:AppDelegate.mSVFilesHandler!.makeSentFullPath(fileName:row.title!), fileName:row.title!)
                }
                $0.onChange { row in
                    switch row.cell.segmentedControl.selectedSegmentIndex {
                    case 0:
                        self.emailSVfile(filePath:AppDelegate.mSVFilesHandler!.makeSentFullPath(fileName:row.title!), fileName:row.title!)
                        break
                    case 1:
                        var anchorRect = row.cell.segmentedControl.subviews[0].frame    // segmentedRow adds buttons in backwards order
                        anchorRect = self.view.convert(anchorRect, from: row.cell.segmentedControl)
                        self.shareSVfile(filePath:AppDelegate.mSVFilesHandler!.makeSentFullPath(fileName:row.title!), fileName:row.title!, selfViewAnchorRect: anchorRect)
                        break
                    default:
                        break
                    }
                    row.value = nil
                    row.cell.segmentedControl.selectedSegmentIndex = -1
                    row.updateCell()
                }
            }
        }
        tableView.reloadData()
    }
    
    // note: this function will also be called when removeAll() has been invoked on the MultiValuedSection
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        if self.mNoDelete { return }
        
//debugPrint("\(self.mCTAG).rowsHaveBeenRemoved STARTED")
        for row in rows {
            if row.title != nil {
                let index = indexes.first!.section
                let section = form.allSections[index] as! MultivaluedSection
                do {
                    if section.tag == "$Pending" {
                        try AppDelegate.mSVFilesHandler!.deletePendingFile(fileName:row.title!)
                    } else {
                        try AppDelegate.mSVFilesHandler!.deleteSentFile(fileName:row.title!)
                    }
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).rowsHaveBeenRemoved", errorStruct: error, extra: nil)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("File Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
        }
    }
    
    private func generateNewSVFiles() -> Bool {
        do {
            _ = try AppDelegate.mSVFilesHandler!.generateNewSVFiles()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).generateNewSVFiles", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("File Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return false
        }
        return true
    }
    
    // email the SV-File:  prep it and place it into an email
    private func emailSVfile(filePath:String, fileName:String) {
//debugPrint("\(self.mCTAG).emailSVfile STARTED")
        // obtain the Org and Form records; assumes the SVFile's name is composed in a certain order
        let splits:[String] = fileName.components(separatedBy: "_")
        if splits.count < 4 {
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).emailSVfile", during:"fileName.components(separatedBy:)", errorMessage:"Filename mis-composed", extra:fileName)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("App Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).emailSVfile", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .INTERNAL_ERROR, userErrorDetails: NSLocalizedString("Filename mis-composed", comment:"")), buttonText: NSLocalizedString("Okay", comment:""))
        }
        let formSplits:[String] = splits[3].components(separatedBy: ".")
        var orgRec:RecOrganizationDefs? = nil
        var formRec:RecOrgFormDefs? = nil
        do {
            orgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName:splits[2])
            formRec = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName:formSplits[0], forOrgShortName:splits[2])
            
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).emailSVfile", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).emailSVfile", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        if orgRec == nil {
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).emailSVfile", during:"orgGetSpecifiedRecOfShortName", errorMessage:"Could not get Org record", extra:splits[2])
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).emailSVfile", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        if formRec == nil {
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).emailSVfile", during:"orgFormGetSpecifiedRecOfShortName", errorMessage:"Could not get Form record", extra:formSplits[0])
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).emailSVfile", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        
        // determine the proper email parameters from the Form or Org records
        var email_to:String? = nil
        var email_cc:String? = nil
        var email_subject:String? = nil
        if !((formRec!.rForm_Override_Email_To ?? "").isEmpty) {
            email_to = formRec!.rForm_Override_Email_To!
        } else if !((orgRec!.rOrg_Email_To ?? "").isEmpty) {
            email_to = orgRec!.rOrg_Email_To!
        }
        if !((formRec!.rForm_Override_Email_CC ?? "").isEmpty) {
            email_cc = formRec!.rForm_Override_Email_CC!
        } else if !((orgRec!.rOrg_Email_CC ?? "").isEmpty) {
            email_cc = orgRec!.rOrg_Email_CC!
        }
        if !((formRec!.rForm_Override_Email_Subject ?? "").isEmpty) {
            email_subject = formRec!.rForm_Override_Email_Subject!
        } else if !((orgRec!.rOrg_Email_Subject ?? "").isEmpty) {
            email_subject = orgRec!.rOrg_Email_Subject!
        }
        
        var emailToArray:[String] = []
        var emailCCArray:[String] = []
        if !((email_to ?? "").isEmpty) {
            emailToArray = email_to!.components(separatedBy: ",")
        }
        if !((email_cc ?? "").isEmpty) {
            emailCCArray = email_cc!.components(separatedBy: ",")
        }
        
        // determine the mime type
        var mimeType = "text/plain"
        let extString = (fileName as NSString).pathExtension
        switch extString {
        case "txt":
            mimeType = "text/tab-separated-values"
            break
        case "csv":
            mimeType = "text/csv"
            break
        case "xml":
            mimeType = "text/xml"
            break
        default:
            break
        }

        // invoke the emailer
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.title = fileName
            mail.mailComposeDelegate = self
            mail.setToRecipients(emailToArray)
            mail.setCcRecipients(emailCCArray)
            mail.setSubject((email_subject != nil) ? email_subject! : "")
            //mail.setMessageBody("Message body", isHTML: false)
            let fileData:Data = FileManager.default.contents(atPath:filePath)!
            mail.addAttachmentData(fileData, mimeType: mimeType, fileName: fileName)
            self.present(mail, animated: true, completion: nil)
        } else {
            // do not error log or alert
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("iOS eMail Error", comment:""), message: NSLocalizedString("iOS is not allowing App to send email", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
    
    // email the SV-File:  callback from iOS indicating rejection or initial success
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//debugPrint("\(self.mCTAG).mailComposeController.didFinishWith for \(controller.title!)")
        if error != nil {
            // do not error.log
            let msg:String = NSLocalizedString("Error was returned from the iOS eMail System", comment:"") + ": " + AppDelegate.endUserErrorMessage(errorStruct: error!)
            AppDelegate.postAlert(message: msg)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("iOS eMail Error", comment:""), message: msg, buttonText: NSLocalizedString("Okay", comment:""))
        }
        if result == .sent || result == .saved {
            let fileName:String = controller.title!
            do {
                try AppDelegate.mSVFilesHandler!.movePendingToSent(fileName:fileName)
                self.displayListOfFiles()
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mailComposeController.didFinishWith", errorStruct: error, extra: nil)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("File Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    // share the SV-File
    private func shareSVfile(filePath:String, fileName:String, selfViewAnchorRect:CGRect) {
//debugPrint("\(self.mCTAG).shareSVfile STARTED PATH=\(filePath)")
        // determine the mime type
        self.mSharedFileUTI = String(kUTTypePlainText)         // text/plain
        let extString = (fileName as NSString).pathExtension
        switch extString {
        case "txt":
            self.mSharedFileUTI = String(kUTTypeText)              // text/
            break
        case "csv":
            self.mSharedFileUTI = String(kUTTypeText)              // text/
            break
        case "xml":
            self.mSharedFileUTI = String(kUTTypeXML)               // text/xml
            break
        default:
            break
        }
        
        self.mSharedFileURL = URL(fileURLWithPath: filePath)
        self.mSharedFileName = fileName
        let avc = UIActivityViewController(activityItems: [self], applicationActivities: [])
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad) {
            avc.modalPresentationStyle = UIModalPresentationStyle.popover
            avc.preferredContentSize = CGSize(width: 0, height: 0)
            avc.popoverPresentationController?.sourceView = self.view
            avc.popoverPresentationController?.sourceRect = selfViewAnchorRect
        }
        self.present(avc, animated: true, completion: nil)
    }
    
    // FUTURE: !! ?? vCard     String(kUTTypeVCard)  text/vcard
    // FUTURE: !! ?? Contact   String(kUTTypeContact)
    
    ///////////////////////////////////////////////////////////////////
    // Methods related UIActivityViewController and UIActivityItemSource
    ///////////////////////////////////////////////////////////////////
    
    // placeholder so UIActivityViewController knows in general what is going to be shared
    func activityViewControllerPlaceholderItem(_ activityViewController:UIActivityViewController) -> Any {
//debugPrint("\(self.mCTAG).activityViewControllerPlaceholderItem STARTED")
        return self.mSharedFileURL!
    }
    
    // return the actual content to be shared (e.g. the body of the email)
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
//debugPrint("\(self.mCTAG).activityViewController.itemForActivityType STARTED")
        return self.mSharedFileURL!
    }
    
    // return the UTI if asked for
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
//debugPrint("\(self.mCTAG).activityViewController.dataTypeIdentifierForActivityType STARTED")
        return self.mSharedFileUTI!
    }
    
    // return a Subject line for the likes of email
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
//debugPrint("\(self.mCTAG).activityViewController.subjectForActivityType STARTED")
        if activityType == .mail {
            return NSLocalizedString("Contacts collected from eContact Collect", comment:"do not translate the portion: eContact Collect")
        }
        return "eContactCollect \(self.mSharedFileName!)"
    }
}

