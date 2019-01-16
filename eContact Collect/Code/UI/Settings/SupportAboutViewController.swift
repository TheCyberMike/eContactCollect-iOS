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
        if AppDelegate.mDatabaseHandler != nil {
            versionString = versionString + "\n\(NSLocalizedString("DB Version", comment:"")) \(AppDelegate.mDatabaseHandler!.getVersioning()), \(NSLocalizedString("DB State is", comment:"")) \(AppDelegate.mDatabaseHandler!.mDBstatus_state)"
        }

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
            $0.title = NSLocalizedString("Website", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://sites.google.com/view/econtactcollect")! as URL)
        }
        section1 <<< ButtonRow() {
            $0.tag = "supportOptions"
            $0.title = NSLocalizedString("Support Options", comment:"")
            $0.presentationMode = .show(
                    controllerProvider: .callback(builder: { return SupportOptionsViewController() } ),
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

class SupportOptionsViewController: FormViewController, MFMailComposeViewControllerDelegate {
    // member variables
    
    // member constants and other static content
    private let mCTAG:String = "VCSSAO"
    
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
            $0.title = NSLocalizedString("Submit Questions at", comment:"") + " StackOverflow; " + NSLocalizedString("\nPlease include tag:", comment:"") + " eContactCollect"
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.textLabel?.numberOfLines = 2
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { cell, row in
                UIApplication.shared.open(NSURL(string:"https://stackoverflow.com/questions/tagged/econtactcollect")! as URL)
        }
        section1 <<< ButtonRow() {
            $0.tag = "sendEmail"
            $0.title = NSLocalizedString("Send to Developer: email", comment:"")
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                self!.emailDeveloper(includeErrorLog: false)
        }
        section1 <<< ButtonRow() {
            $0.tag = "sendErrorLog"
            $0.title = NSLocalizedString("Send to Developer:", comment:"") + " error.log"
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.font = .systemFont(ofSize: 15.0)
                cell.textLabel?.textColor = UIColor.black
                cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            }.onCellSelection { [weak self] cell, row in
                self!.emailDeveloper(includeErrorLog: true)
        }
    }

    // email the developer
    private func emailDeveloper(includeErrorLog:Bool) {
        // invoke the emailer
        if MFMailComposeViewController.canSendMail() {
            var subject:String = "eContactCollect Support Email"
            let mail = MFMailComposeViewController()
            mail.title = NSLocalizedString("Email the Developer", comment:"")
            mail.mailComposeDelegate = self
            mail.setToRecipients(["theCyberMike@yahoo.com"])
            mail.setMessageBody("?Your message here?", isHTML: false)
            if includeErrorLog {
                let fileData:Data? = FileManager.default.contents(atPath: AppDelegate.getErrorLogFullPath())
                if fileData != nil {
                    mail.addAttachmentData(fileData!, mimeType: "text/plain", fileName: "error.log")
                    subject = subject + " with error.log"
                }
            }
            mail.setSubject(subject)
            self.present(mail, animated: true, completion: nil)
        } else {
            // do not error log or alert
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("iOS eMail Error", comment:""), message: NSLocalizedString("iOS is not allowing App to send email", comment:""), buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
    
    // email the developer:  callback from iOS indicating rejection or initial success
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//debugPrint("\(self.mCTAG).mailComposeController.didFinishWith for \(controller.title!)")
        if error != nil {
            // do not error.log
            let msg:String = NSLocalizedString("Error was returned from the iOS eMail System", comment:"") + ": " + AppDelegate.endUserErrorMessage(errorStruct: error!)
            AppDelegate.postAlert(message: msg)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("iOS eMail Error", comment:""), message: msg, buttonText: NSLocalizedString("Okay", comment:""))
        }
        controller.dismiss(animated: true, completion: nil)
    }
}



