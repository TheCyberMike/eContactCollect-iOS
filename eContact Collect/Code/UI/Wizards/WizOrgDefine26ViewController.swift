//
//  WizOrgDefine26ViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/4/18.
//

import UIKit
import Eureka

class WizOrgDefine26ViewController: UIViewController {
    // member variables
    
    // member constants and other static content
    private let mCTAG:String = "VCW2-26"
    internal weak var mRootVC:WizMenuViewController? = nil
    internal weak var mOrgTitleViewController:OrgTitleViewController? = nil
    private weak var mFormVC:WizOrgDefine26FormViewController? = nil

    // outlets to screen controls
    @IBAction func button_cancel_pressed(_ sender: UIBarButtonItem) {
        self.mRootVC!.mWorking_Org_Rec = nil
        self.clearVC()
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func button_done_pressed(_ sender: UIBarButtonItem) {
        do {
            _ = try self.mRootVC!.mWorking_Org_Rec!.saveNewToDB()   // this will also save all internal RecOrganizationLangs
        } catch {
            // error.log and alert already posted
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        (UIApplication.shared.delegate as! AppDelegate).setCurrentOrg(toOrgRec:self.mRootVC!.mWorking_Org_Rec!)
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
        assert(self.mRootVC!.mEFP != nil, "\(self.mCTAG).viewDidLoad self.mEFP == nil")
        
        // locate the child view controllers
        self.mOrgTitleViewController = nil
        self.mFormVC = nil
        for childVC in children {
            let vc1:OrgTitleViewController? = childVC as? OrgTitleViewController
            let vc2:WizOrgDefine26FormViewController? = childVC as? WizOrgDefine26FormViewController
            if vc1 != nil { self.mOrgTitleViewController = vc1 }
            if vc2 != nil { self.mFormVC = vc2 }
        }
        assert(self.mOrgTitleViewController != nil, "\(self.mCTAG).viewDidLoad self.mOrgTitleViewController == nil")
        assert(self.mFormVC != nil, "\(self.mCTAG).viewDidLoad self.mFormVC == nil")
        
        self.mOrgTitleViewController!.mEFP = self.mRootVC!.mEFP!
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
        self.mOrgTitleViewController = nil
        self.mFormVC = nil
        self.mRootVC = nil
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

/////////////////////////////////////////////////////////////////////////
// Form child ViewController
/////////////////////////////////////////////////////////////////////////

class WizOrgDefine26FormViewController: FormViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW2-26F"
    private weak var mWiz26VC:WizOrgDefine26ViewController? = nil
    
    private let TitleModeStrings:[String] = [NSLocalizedString("Title Only", comment:""),
                                             NSLocalizedString("Logo Only", comment:""),
                                             NSLocalizedString("50/50 Title and Logo", comment:""),
                                             NSLocalizedString("Full Logo, Title remains", comment:""),
                                             NSLocalizedString("Full Title, Logo remains", comment:"")]
    private func titleModeInt(fromString:String) -> Int {
        switch fromString {
        case TitleModeStrings[0]: return 0
        case TitleModeStrings[1]: return 1
        case TitleModeStrings[2]: return 2
        case TitleModeStrings[3]: return 3
        case TitleModeStrings[4]: return 4
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
        self.mWiz26VC = (self.parent as! WizOrgDefine26ViewController)
        self.rebuildForm()
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
        self.mWiz26VC = nil
    }
    
    // build the form
    private func rebuildForm() {
        form.removeAll()
        tableView.reloadData()
        
        let section1 = Section()
        form +++ section1
        if self.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_LangRegionCodes_Supported.count > 1 {
            section1 <<< SegmentedRowExt<String>() { [weak self] row in
                row.tag = "show_lang"
                row.title = NSLocalizedString("Show:", comment:"")
                row.options = self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_LangRegionCodes_Supported
                row.value = Set<String>([self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_LangRegionCodes_Supported[0]])
                row.displayValueFor = { set in
                        if set == nil { return nil }
                        return set!.map { (Locale.current.localizedString(forLanguageCode: $0) ?? $0) }.joined(separator: ", ")
                    }
                }.cellUpdate { cell, row in
                    cell.segmentedControl?.tintColor = UIColor.blue
                }.onChange { [weak self] chgRow in
                    if chgRow.value != nil, chgRow.value!.first != nil {
                        self!.mWiz26VC!.mRootVC!.mEFP!.forceChange(toLangRegion: chgRow.value!.first!)
                        self!.mWiz26VC!.mOrgTitleViewController!.refresh()
                    }
            }
        }
        
        section1 <<< TextAreaRow() {
            $0.tag = "info"
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 180.0)
            $0.title = NSLocalizedString("Info", comment:"")
            $0.value = NSLocalizedString("%info%_WizOrgDefine26", comment:"")
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.font = .systemFont(ofSize: 17.0)
                cell.textView.textColor = UIColor.black
        }
        
        let section2 = Section(NSLocalizedString("Organization's Logo and Look", comment:""))
        form +++ section2
        
        section2 <<< InlineColorPickerRow() { [weak self] row in
            row.tag = "org_shown_title_text_color"
            row.title = "Text color"
            row.isCircular = false
            //row.showsCurrentSwatch = true
            row.showsPaletteNames = true
            row.value = self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Visuals.rOrgTitle_TitleText_Color
            } .onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Visuals.rOrgTitle_TitleText_Color = chgRow.value!
                    self!.mWiz26VC!.mOrgTitleViewController!.refresh()
                }
        }
        section2 <<< FontPickerInlineRow() { [weak self] row in
            row.tag = "org_shown_title_text_font"
            row.title = "Text font"
            row.value = self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Visuals.rOrgTitle_TitleText_Font
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Visuals.rOrgTitle_TitleText_Font = chgRow.value!
                    self!.mWiz26VC!.mOrgTitleViewController!.refresh()
                }
        }
        section2 <<< ImageRow() { [weak self] row in
            row.tag = "org_shown_logo"
            row.title = NSLocalizedString("Logo (optional)", comment:"")
            row.clearAction = ImageClearAction.yes(style: .destructive)
            if self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob == nil {
                row.value = nil
            } else {
                row.value = UIImage(data:self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob!)!
            }
            }.onChange { [weak self] chgRow in
                if chgRow.value == nil {
                    // end-user has removed the image
                    self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob = nil
                    self!.mWiz26VC!.mOrgTitleViewController!.refresh()
                } else {
                    // end-user has chosen an image
                    if chgRow.userPickerInfo != nil {
                        if var pickedImage = chgRow.userPickerInfo![UIImagePickerController.InfoKey.originalImage] as? UIImage {
                            // an image was indeed returned;
                            // the view height for logos and titles is 50 ... for 3x imagery thus we need 150 height
                            let newHeight:CGFloat = 150.0
                            if pickedImage.size.height != newHeight {
                                let newWidth:CGFloat = pickedImage.size.width * (newHeight / pickedImage.size.height)
                                UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
                                pickedImage.draw(in:CGRect(x:0.0, y:0.0, width:newWidth, height:newHeight))
                                if let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
                                    pickedImage = newImage
                                }
                                UIGraphicsEndImageContext()
                            }
                            self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Logo_Image_PNG_Blob = pickedImage.pngData()
                            self!.mWiz26VC!.mOrgTitleViewController!.refresh()
                        }
                    }
                }
        }
        section2 <<< InlineColorPickerRow() { [weak self] row in
            row.tag = "org_shown_back_color"
            row.title = "Background color"
            row.isCircular = false
            //row.showsCurrentSwatch = true
            row.showsPaletteNames = true
            row.value = self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Visuals.rOrgTitle_Background_Color
            } .onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Visuals.rOrgTitle_Background_Color = chgRow.value!
                    self!.mWiz26VC!.mOrgTitleViewController!.refresh()
                }
        }
        section2 <<< PickerInlineRow<String>() { [weak self] row in
            row.tag = "org_shown_mode"
            row.title = NSLocalizedString("Show as:", comment:"")
            row.options = TitleModeStrings
            row.value = TitleModeStrings[self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode.rawValue]
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    switch self!.titleModeInt(fromString:chgRow.value!)
                    {
                    case 0: self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode = .ONLY_TITLE
                    case 1: self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode = .ONLY_LOGO
                    case 2: self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode = .BOTH_50_50
                    case 3: self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode = .BOTH_LOGO_DOMINATES
                    case 4: self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode = .BOTH_TITLE_DOMINATES
                    default: self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_Title_Mode = .ONLY_TITLE
                    }
                    self!.mWiz26VC!.mOrgTitleViewController!.refresh()
                }
        }
        
        let section3 = Section(NSLocalizedString("Organization Title(s)", comment:""))
        form +++ section3
        
        for langRegionCode in self.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.rOrg_LangRegionCodes_Supported {
            section3 <<< TextAreaRowExt() { [weak self] row in
                row.tag = "org_shown_title_\(langRegionCode)"
                row.title = NSLocalizedString("Org Title for ", comment:"") + AppDelegate.makeFullDescription(forLangRegion: langRegionCode)
                do {
                    row.value = try self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.getOrgTitleShown(langRegion: langRegionCode)
                } catch {}  // report no error
                row.textAreaHeight = .fixed(cellHeight: 50)
                row.textAreaWidth = .fixed(cellWidth: 200)
                }.cellUpdate { cell, row in
                    cell.textView.font = .boldSystemFont(ofSize: 17.0)
                    cell.textView.layer.cornerRadius = 0
                    cell.textView.layer.borderColor = UIColor.gray.cgColor
                    cell.textView.layer.borderWidth = 1
                }.onChange { [weak self] chgRow in
                    do {
                        try self!.mWiz26VC!.mRootVC!.mWorking_Org_Rec!.setOrgTitleShown(langRegion: langRegionCode, title: chgRow.value)
                    } catch {}  // report no error
            }
        }
    }
}
