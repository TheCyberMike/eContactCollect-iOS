//
//  WizMenuViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/4/18.
//

import UIKit
import SQLite

class WizMenuViewController: UIViewController, C1stVC_Delegate {
    // member variables
    public var mEFP:EntryFormProvisioner? = nil
    public var mWorking_Org_Rec:RecOrganizationDefs? = nil {
        didSet {
            if self.mWorking_Org_Rec != nil {
                if self.mWorking_Form_Rec == nil {
                    self.mEFP = EntryFormProvisioner(forOrgRecOnly: self.mWorking_Org_Rec!)
                } else {
                    self.mEFP = EntryFormProvisioner(forOrgRec: self.mWorking_Org_Rec!, forFormRec: self.mWorking_Form_Rec!)
                }
            } else {
                self.mEFP = nil
            }
        }
    }
    public var mWorking_Form_Rec:RecOrgFormDefs? = nil {
        didSet {
            if self.mWorking_Org_Rec != nil && self.mWorking_Form_Rec != nil {
                self.mEFP = EntryFormProvisioner(forOrgRec: self.mWorking_Org_Rec!, forFormRec: self.mWorking_Form_Rec!)
            }
        }
    }
    
    // member constants and other static content
    private let mCTAG:String = "VCW0"

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
        
        // listen for file-open notifications since the end-user may be attempting to load a config file at initial startup
        NotificationCenter.default.addObserver(self, selector: #selector(noticeOpenConfigFile(_:)), name: .APP_FileRequestedToOpen, object: nil)
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
    }
    
    // called by the framework when the view has re-appeared (first time, from popovers, etc)
    // parent and all children are now available
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)
        
        self.mWorking_Org_Rec = nil     // clear out any previously created Org definition
        self.mWorking_Form_Rec = nil     // clear out any previously created Form definition
        
        self.checkFirstTime()
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED \(self)")
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            
            NotificationCenter.default.removeObserver(self, name: .APP_FileRequestedToOpen, object: nil)
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
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
    
    // perform first time activities if supposed to
    private func checkFirstTime() {
        // first start with stage 1
        if AppDelegate.mFirstTImeStages == 0 {
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 1)
            AppDelegate.mFirstTImeStages = 1
        }
        
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        switch AppDelegate.mFirstTImeStages {
        case 1:
            // present the First Time popup
            let nextViewController = storyboard.instantiateViewController(withIdentifier:"VC PopupFirstTime") as! PopupFirstTimeViewController
            nextViewController.mC1stVCdelegate = self
            nextViewController.modalPresentationStyle = .custom
            self.present(nextViewController, animated: true, completion: nil)
            break
            
        case 2:
            // segue to the First Time Wizard sequence
            let nextViewController:UIViewController = storyboard.instantiateViewController(withIdentifier:"VC WizFirstTime")
            self.navigationController?.pushViewController(nextViewController, animated:true)
            break
            
        case 3:
            // step thru the Org and Form Wizard sequences
            var qtyOrgs:Int64 = 0
            do {
                qtyOrgs = try RecOrganizationDefs.orgGetQtyRecs()
            } catch {}
            if qtyOrgs <= 0 {
                // segue to the Org Definition Wizard sequence
                let nextViewController:UIViewController = storyboard.instantiateViewController(withIdentifier:"VC WizOrgDefine1")
                self.navigationController?.pushViewController(nextViewController, animated:true)
            } else {
                var qtyForms:Int64 = 0
                do {
                    var records:AnySequence<Row>
                    records = try RecOrganizationDefs.orgGetAllRecs()
                    for orgRec in records {
                        let orgRec = try RecOrganizationDefs(row:orgRec)
                        qtyForms += try RecOrgFormDefs.orgFormGetQtyRecs(forOrgShortName: orgRec.rOrg_Code_For_SV_File)
                    }
                } catch {}
                if qtyForms <= 0 {
                    // segue to the Form Definition Wizard sequence
                    let nextViewController:UIViewController = storyboard.instantiateViewController(withIdentifier:"VC WizFormDefine1")
                    self.navigationController?.pushViewController(nextViewController, animated:true)
                } else {
                    AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: -1)
                    AppDelegate.mFirstTImeStages = -1
                    AppDelegate.setupMainlineEFP()
                    let tbc:MainTabBarViewController = self.tabBarController as! MainTabBarViewController
                    tbc.exitWizardFirstTime()
                }
            }
            break
            
        default:
            if AppDelegate.mFirstTImeStages > 0 {
                // not a known First Time Stage; so end the First-Time mode
                AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: -1)
                AppDelegate.mFirstTImeStages = -1
                AppDelegate.setupMainlineEFP()
                let tbc:MainTabBarViewController = self.tabBarController as! MainTabBarViewController
                tbc.exitWizardFirstTime()
            }
            break
        }
    }
    
    // received a notification that the end-user opened an OrgConfigs file
    @objc func noticeOpenConfigFile(_ notification:Notification) {
//debugPrint("\(self.mCTAG).openConfigFileNotice STARTED")
        if notification.userInfo == nil { return }
        let url:URL = notification.userInfo![UIApplication.OpenURLOptionsKey.url] as! URL
        UIHelpers.importConfigFile(fromURL: url, usingVC: self, fromExternal: true)
    }
    
    // return from the Popup First Time view
    func completed_C1stVC(fromVC:PopupFirstTimeViewController, choice:Int) {
//debugPrint("\(self.mCTAG).completed_C1stVC STARTED choice=\(choice)")
        switch choice {
        
        case 1:
            // create a default Org and Form
            do {
                let (orgRec, formRec) = try AppDelegate.mDatabaseHandler!.createDefaultOrgAndForm()
                (UIApplication.shared.delegate as! AppDelegate).checkCurrentOrg(withOrgRec: orgRec)
                (UIApplication.shared.delegate as! AppDelegate).checkCurrentForm(withFormRec: formRec)
                AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: -1)
                AppDelegate.mFirstTImeStages = -1
                AppDelegate.setupMainlineEFP()
                let tbc:MainTabBarViewController = self.tabBarController as! MainTabBarViewController
                tbc.exitWizardFirstTime()
            } catch {
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            }
            break
            
        case 2:
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 2)
            AppDelegate.mFirstTImeStages = 2
            break
        
        case 3:
            // Helper to import an Org-config
            AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_Pin, value: "")
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 3)
            AppDelegate.mFirstTImeStages = 3
            break
            
        default:
            break
        }
        dismiss(animated: true, completion: {
            self.checkFirstTime()
            return // from callback
        })
    }
}