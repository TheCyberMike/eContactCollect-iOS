//
//  SupportAboutViewController.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import Eureka
import MessageUI
import MobileCoreServices

class SupportAboutViewController: FormViewController {
    // member variables
    
    // member constants and other static content
    private let mCTAG:String = "VCSSA"
    
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
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
            form.removeAll()
            tableView.reloadData()
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
    
    // build the form
    private func buildForm() {
        let appVer:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let appBuild:Int64 = Int64(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)!
        let appName:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        var versionString = "\(NSLocalizedString("Version", comment:"")) \(appVer), \(NSLocalizedString("Build", comment:"")) \(appBuild)"
        if let infoPath = Bundle.main.path(forResource: appName, ofType: nil),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date {
            let mydateFormatter = DateFormatter()
            mydateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let buildDate = mydateFormatter.string(from: infoDate)
            versionString = versionString + " [\(buildDate)]"
        }
        versionString = versionString + "\n\(NSLocalizedString("DB Version", comment:"")) \(DatabaseHandler.shared.getVersioning()), \(NSLocalizedString("DB State is", comment:"")) \(DatabaseHandler.shared.mDBstatus_state)"

        let section1 = Section()
        form +++ section1
        section1 <<< TextAreaRow() {
            $0.tag = "versionInfo"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 20.0)
            $0.value = versionString
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 15.0)
                cell.textView.textColor = UIColor.black
        }
        section1 <<< ButtonRow() {
            $0.tag = "shareApp"
            $0.title = NSLocalizedString("Share this App", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                let msg:String = NSLocalizedString("I recommend this free Contact Info Collection iOS App.", comment:"") + " https://sites.google.com/view/econtactcollect"
                let activityVC = UIActivityViewController(activityItems:[msg], applicationActivities:nil)
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad) {
                    activityVC.modalPresentationStyle = UIModalPresentationStyle.popover
                    activityVC.preferredContentSize = CGSize(width: 0, height: 0)
                    activityVC.popoverPresentationController?.sourceView = self!.view
                    activityVC.popoverPresentationController?.sourceRect = cell.frame
                }
                self!.present(activityVC, animated:true, completion:nil)
        }
        section1 <<< ButtonRow() {
            $0.tag = "rateApp"
            $0.title = NSLocalizedString("Rate this App", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"itms-apps://itunes.apple.com/app/id1447133009?action=write-review")! as URL)
        }
        section1 <<< ButtonRow() {
            $0.tag = "sampleForms"
            $0.title = NSLocalizedString("Sample Forms", comment:"")
            $0.presentationMode = .show(
                controllerProvider: .callback(builder: { return SampleFormsViewController() } ),
                onDismiss: nil)
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        }
        section1 <<< ButtonRow() {
            $0.tag = "onlineSupport"
            $0.title = NSLocalizedString("Online Support Options", comment:"")
            $0.presentationMode = .show(
                controllerProvider: .callback(builder: { return OnlineSupportViewController() } ),
                onDismiss: nil)
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        }
        section1 <<< ButtonRow() {
            $0.tag = "contactOptions"
            $0.title = NSLocalizedString("Contact Options", comment:"")
            $0.presentationMode = .show(
                    controllerProvider: .callback(builder: { return ContactOptionsViewController() } ),
                    onDismiss: nil)
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        }
        section1 <<< ButtonRow() {
            $0.tag = "onlinePrivacyPolicy"
            $0.title = NSLocalizedString("Privacy Policy", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://sites.google.com/view/econtactcollect/home/notices")! as URL)
        }
        
        var nameString:String = NSLocalizedString("Originally coded by", comment:"") + " Mike Maschino.\n"
        nameString = nameString + NSLocalizedString("Design advice provided by", comment:"") + " Rick-Arlo Yah Lira.\n"
        nameString = nameString + NSLocalizedString("Dedicated to the Public Domain.", comment:"")
        section1 <<< TextAreaRow() {
            $0.tag = "developerInfo"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 50.0)
            $0.value = nameString
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 15.0)
                cell.textView.textColor = UIColor.black
        }
#if DEBUG
        section1 <<< TextAreaRow() {
            $0.tag = "debugInfo"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 90.0)
            $0.value = AppDelegate.getErrorLogFullPath()
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 15.0)
                cell.textView.textColor = UIColor.black
        }
#endif
    }
}

///////////////////////////////////////////////////
// class definition for OnlineSupportViewController
///////////////////////////////////////////////////

class OnlineSupportViewController: FormViewController {
    // member variables
    
    // member constants and other static content
    private let mCTAG:String = "VCSSAS"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
        //debugPrint("\(mCTAG).deinit STARTED")
        NotificationCenter.default.removeObserver(self, name: .APP_EmailCompleted, object: nil)
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
        //debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationItem.title = NSLocalizedString("Online Support", comment:"")
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
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            //debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
            form.removeAll()
            tableView.reloadData()
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
    
    // build the form
    private func buildForm() {
        let section1 = Section()
        form +++ section1
        
        section1 <<< ButtonRow() {
            $0.tag = "onlineFAQ"
            $0.title = NSLocalizedString("Online FAQ", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://sites.google.com/view/econtactcollect/home/faq")! as URL)
        }
        section1 <<< ButtonRow() {
            $0.tag = "onlineUserGuide"
            $0.title = NSLocalizedString("Online User Guide", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://drive.google.com/file/d/1t8nJ_BGpoH2C5BKA3BtXuJ7tSEjMmQy8/view")! as URL)
        }
        section1 <<< ButtonRow() {
            $0.tag = "onlineTutorialVideos"
            $0.title = NSLocalizedString("Online Tutorial Videos", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://www.youtube.com/playlist?list=PL0jtp2DkiUc5dbXPTFD5C3Gq5BzBMS9WF")! as URL)
        }
        section1 <<< ButtonRow() {
            $0.tag = "websiteLink"
            $0.title = NSLocalizedString("Support Website", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://sites.google.com/view/econtactcollect")! as URL)
        }
    }
}

///////////////////////////////////////////////////
// class definition for ContactOptionsViewController
///////////////////////////////////////////////////

class ContactOptionsViewController: FormViewController, UIActivityItemSource {
    // member variables
    private var mSharedFileURL:URL? = nil
    private var mSharedFileUTI:String? = nil
    private var mSharedFileName:String? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCSSAC"
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
        NotificationCenter.default.removeObserver(self, name: .APP_EmailCompleted, object: nil)
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // add an observer for Notifications about complete SMTP tests
        NotificationCenter.default.addObserver(self, selector: #selector(noticeEmailCompleted(_:)), name: .APP_EmailCompleted, object: nil)
        
        // build the form entirely
        self.buildForm()
        
        // set overall form options
        navigationItem.title = NSLocalizedString("Contact Options", comment:"")
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
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need to forceably clear the form else this VC will not deinit()
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED")
            form.removeAll()
            tableView.reloadData()
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
    
    // build the form
    private func buildForm() {
        let section1 = Section()
        form +++ section1
        
        section1 <<< ButtonRow() {
            $0.tag = "submitIssues"
            $0.title = NSLocalizedString("Submit Issues/Bugs/Requests at", comment:"") + " GitHub"
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://github.com/TheCyberMike/eContactCollect-iOS/issues")! as URL)
        }
        section1 <<< ButtonRow() {
            $0.tag = "submitQuestions"
            $0.title = NSLocalizedString("Submit Questions at Google Groups", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.textLabel?.numberOfLines = 2
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://groups.google.com/forum/?nomobile=true#!forum/econtact-collect")! as URL)
        }
        section1 <<< ButtonRow() {
            $0.tag = "shareLog"
            $0.title = NSLocalizedString("Share error.log to Developer", comment:"") + ":\n \(AppDelegate.mDeveloperEmailAddress)"
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.textLabel?.numberOfLines = 2
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                self!.shareDeveloper(selfViewAnchorRect: cell.frame)
        }
        let section2 = Section(NSLocalizedString("Email the Developer", comment:""))
        form +++ section2
        let bodyRow = TextAreaRowExt() {
            $0.tag = "emailDeveloperBody"
            $0.title = NSLocalizedString("Message in English", comment:"")
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
            }.cellUpdate { cell, row in
                cell.textView.autocapitalizationType = .sentences
                cell.textView.font = .systemFont(ofSize: 15.0)
                cell.textView.layer.cornerRadius = 0
                cell.textView.layer.borderColor = UIColor.gray.cgColor
                cell.textView.layer.borderWidth = 1
        }
        section2 <<< bodyRow
        let attachRow = SwitchRow() {
            $0.tag = "emailDeveloperErrorLog"
            $0.title = NSLocalizedString("Include error.log?", comment:"")
            $0.value = true
        }
        section2 <<< attachRow
        section2 <<< ButtonRow() {
            $0.tag = "sendEmailLog"
            $0.title = NSLocalizedString("Send email to Developer", comment:"") + ":\n \(AppDelegate.mDeveloperEmailAddress)"
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.textLabel?.numberOfLines = 2
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                if !(bodyRow.value ?? "").isEmpty {
                    self!.emailDeveloper(body: bodyRow.value!, includeErrorLog: (attachRow.value ?? false))
                } else {
                    AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Entry Error", comment:""), message: NSLocalizedString("Message must contain some text", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                }
        }
    }

    // email the developer
    private func emailDeveloper(body:String, includeErrorLog:Bool) {
        // preparations
        var subject:String = "eContactCollect Support Email"
        var attachmentURL:URL? = nil
        if includeErrorLog {
            attachmentURL = URL(fileURLWithPath: AppDelegate.getErrorLogFullPath())
            subject = subject + " with error.log"
        }
        
        // send the email; this may or may not invoke an email compose view controller;
        // in this case, do not need the delegate callback (the EmailHandler will post any error to error.log in this situation)
        do {
            try EmailHandler.shared.sendEmailToDeveloper(vc: self, invoker: "SupportOptionsViewController", tagI: 1, tagS: nil, localizedTitle: NSLocalizedString("Email the Developer", comment:""), subject: subject, body: body, includingAttachment: attachmentURL)
        } catch let userError as USER_ERROR {
            // user errors are never posted to the error.log
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Email Error", comment:""), errorStruct: userError, buttonText: NSLocalizedString("Okay", comment:""))
        } catch let appError as APP_ERROR {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).emailDeveloper", during:"sendEmailToDeveloper", errorStruct: appError, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Email Error", comment:""), errorStruct: appError, buttonText: NSLocalizedString("Okay", comment:""))
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).emailDeveloper", during:"sendEmailToDeveloper", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Email Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
    
    // notification of the EMailHandler that a pending email or test was completed
    @objc func noticeEmailCompleted(_ notification:Notification) {
        if let emailResult:EmailResult = notification.object as? EmailResult {
            if emailResult.invoker == "SupportOptionsViewController" {
debugPrint("\(self.mCTAG).noticeEmailCompleted STARTED")
                if emailResult.error != nil {
                    // returned errors will properly have the 'noPost' setting for those email or oauth errors that should not get posted to error.log
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).noticeEmailCompleted", errorStruct: emailResult.error!, extra: nil)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Email Error", comment:""), errorStruct: emailResult.error!, buttonText: NSLocalizedString("Okay", comment:""))
                } else {
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Email Result", comment:""), message: NSLocalizedString("Email successfully sent", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
        }
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related UIActivityViewController and UIActivityItemSource
    ///////////////////////////////////////////////////////////////////
    
    // share the SV-File
    private func shareDeveloper(selfViewAnchorRect:CGRect) {
        // determine the mime type
        self.mSharedFileUTI = String(kUTTypePlainText)         // text/plain
        self.mSharedFileURL = URL(fileURLWithPath: AppDelegate.getErrorLogFullPath())
        self.mSharedFileName = "error.log"
        let avc = UIActivityViewController(activityItems: [self], applicationActivities: [])
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad) {
            avc.modalPresentationStyle = UIModalPresentationStyle.popover
            avc.preferredContentSize = CGSize(width: 0, height: 0)
            avc.popoverPresentationController?.sourceView = self.view
            avc.popoverPresentationController?.sourceRect = selfViewAnchorRect
        }
        self.present(avc, animated: true, completion: nil)
    }
    
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
            return "eContactCollect error.log"
        }
        return "eContactCollect error.log"
    }
}
