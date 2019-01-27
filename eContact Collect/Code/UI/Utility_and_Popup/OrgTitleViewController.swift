//
//  OrgTitleViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/1/18.
//

import UIKit

class OrgTitleViewController: UIViewController {
    // caller pre-set member variables
    public var mWait:Bool = false                       // optional delay in viewController lifecycle before OrgTitle is shown
    public weak var mEFP:EntryFormProvisioner? = nil    // optional EFP to be used; if nil then the mainline's EFP will be used

    // member variables
    private var mListenersEstablished:Bool = false

    // member constants and other static content
    private let mCTAG:String = "VCUOT"

    // outlets to screen controls

    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED \(self)")
        NotificationCenter.default.removeObserver(self, name: .APP_CreatedMainEFP, object: nil)
        if self.mListenersEstablished && self.mEFP != nil {
            NotificationCenter.default.removeObserver(self, name: .APP_EFP_OrgFormChange, object: self.mEFP!)
            NotificationCenter.default.removeObserver(self, name: .APP_EFP_LangRegionChanged, object: self.mEFP!)
        }
    }

    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED \(self)")
        super.viewDidLoad()
        // note: do not do any subview setup here for this particular View Controller
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED \(self)")
        super.viewWillAppear(animated)
        // note: do not do any subview setup here for this particular View Controller
    }
    
    // called by the framework when the view has fully *re-appeared*
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED \(self)")
        super.viewDidAppear(animated)
        
        // if we were not given a provisioner by this point, then use the mainline one (if there is indeed one available);
        // given the need to do this at viewDidAppear() since various parents have different timing issues with the VC lifecycle
        if self.mEFP == nil {
            self.mEFP = AppDelegate.mEntryFormProvisioner
            self.mEFP?.mIsMainlineEFP = true
        }
        NotificationCenter.default.addObserver(self, selector: #selector(noticeCreatedMainEFP(_:)), name: .APP_CreatedMainEFP, object: nil)

        if self.mEFP != nil && !self.mListenersEstablished {
            NotificationCenter.default.addObserver(self, selector: #selector(noticeNewOrgForm(_:)), name: .APP_EFP_OrgFormChange, object: self.mEFP!)
            NotificationCenter.default.addObserver(self, selector: #selector(noticeNewLang(_:)), name: .APP_EFP_LangRegionChanged, object: self.mEFP!)
            self.mListenersEstablished = true
        }
        self.recompose()
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        // use our parent view controller to determine if a dismissal is happening
        if self.parent == nil {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED NO PARENT VC")
        } else if (self.parent?.isBeingDismissed ?? false) || (self.parent?.isMovingFromParent ?? false) ||
                  (self.parent?.navigationController?.isBeingDismissed ?? false) || (self.parent?.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED AND PARENT VC IS DISMISSED parent=\(self.parent!)")
        } else {
//debugPrint("\(self.mCTAG).viewWillDisappear STARTED BUT PARENT VC is not being dismissed parent=\(self.parent!)")
        }
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC
    override func viewDidDisappear(_ animated:Bool) {
        // use our parent view controller to determine if a dismissal is happening
        if self.parent == nil {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED NO PARENT VC")
        } else if (self.parent?.isBeingDismissed ?? false) || (self.parent?.isMovingFromParent ?? false) ||
                  (self.parent?.navigationController?.isBeingDismissed ?? false) || (self.parent?.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND PARENT VC IS DISMISSED parent=\(self.parent!)")
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT PARENT VC is not being dismissed parent=\(self.parent!)")
        }
        super.viewDidDisappear(animated)
    }
    
    // called by the framework prior to rotation
    override func viewWillTransition(to size:CGSize, with coordinator:UIViewControllerTransitionCoordinator ) {
        // now schedule a dispatch to get the *after* rotation state
        DispatchQueue.main.async() {
//debugPrint("\(self.mCTAG).viewWillTransition.async STARTED  \(self)")
            self.recompose()
        }
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // received a notification that the mainline EFP was just created and made ready; note it could indicate a nil during a factory reset
    @objc func noticeCreatedMainEFP(_ notification:Notification) {
        if AppDelegate.mEntryFormProvisioner != nil {
            // is being changed
            if self.mEFP == nil {
//debugPrint("\(self.mCTAG).noticeCreatedMainEFP TAKING UP NEW MAINLINE EFP \(self)")
                // and we do not have a EFP
                self.mEFP = AppDelegate.mEntryFormProvisioner
                self.recompose()
                if self.mEFP != nil && !self.mListenersEstablished {
                    NotificationCenter.default.addObserver(self, selector: #selector(noticeNewOrgForm(_:)), name: .APP_EFP_OrgFormChange, object: self.mEFP!)
                    NotificationCenter.default.addObserver(self, selector: #selector(noticeNewLang(_:)), name: .APP_EFP_LangRegionChanged, object: self.mEFP!)
                    self.mListenersEstablished = true
                }
            }
        } else {
            // is a factory reset
            if self.mEFP != nil {
                if self.mEFP!.mIsMainlineEFP {
//debugPrint("\(self.mCTAG).noticeCreatedMainEFP IS AFFECTED BY FACTORY RESET \(self)")
                    // and we are using the mainline EFP
                    NotificationCenter.default.removeObserver(self, name: .APP_EFP_OrgFormChange, object: self.mEFP!)
                    NotificationCenter.default.removeObserver(self, name: .APP_EFP_LangRegionChanged, object: self.mEFP!)
                    self.mListenersEstablished = false
                    self.mEFP = nil
                    self.recompose()
                }
            }
        }
    }
    
    // received a notification that the AppDelegate current Org or Form has changed
    @objc func noticeNewOrgForm(_ notification:Notification) {
//debugPrint("\(self.mCTAG).noticeNewOrgForm STARTED \(self)")
        self.recompose()
    }
    
    // received a notification that the AppDelegate current Language has changed
    @objc func noticeNewLang(_ notification:Notification) {
//debugPrint("\(self.mCTAG).noticeNewLang STARTED \(self)")
        self.recompose()
    }

    // external callers indicate that a refresh is needed
    public func refresh() {
        self.recompose()
    }
    
    // refresh the Organization title view area
    private func recompose() {
//debugPrint("\(self.mCTAG).recompose STARTED \(self)")
        // remove all existing subviews
        for subview in self.view.subviews {
            subview.removeFromSuperview()
        }

        // if not enabled or not provisioned then show nothing
        if self.mWait || self.mEFP == nil { return }
        if self.mEFP!.mDismissing { return }
        
        // locate an organization title that can be used; since the App could be in its initial very undefined state be careful to check for nils
        // also determine whether being directed from an Editor or using the AppDelegate current's
        var shownTitle:String? = nil
        var shown2ndTitle:String? = nil
        do {
            shownTitle = try self.mEFP!.mOrgRec.getOrgTitleShown(langRegion: self.mEFP!.mShownLanguage)
            if (shownTitle ?? "").isEmpty {
                for langRegionCode in self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported {
                    shownTitle = try self.mEFP!.mOrgRec.getOrgTitleShown(langRegion: langRegionCode)
                    if !(shownTitle ?? "").isEmpty { break }
                }
            }
            if (shownTitle ?? "").isEmpty {
                shownTitle = try self.mEFP!.mOrgRec.getOrgTitleShown(langRegion: self.mEFP!.mOrgRec.rOrg_LangRegionCode_SV_File)
            }
            if (shownTitle ?? "").isEmpty {
                shownTitle = try self.mEFP!.mOrgRec.getOrgTitleShown(langRegion: AppDelegate.mDeviceLangRegion)
            }
            if self.mEFP!.mShowMode == .BILINGUAL && !self.mEFP!.mShownBilingualLanguage.isEmpty {
                shown2ndTitle = try self.mEFP!.mOrgRec.getOrgTitleShown(langRegion: self.mEFP!.mShownBilingualLanguage)
            }
            
        } catch {
            // these are database errors when loading all the Org's language records
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).recompose", errorStruct: error, extra: nil)
            // do not show error to end-user
        }
        
        // choose the default Title Mode
        var showMode:RecOrganizationDefs.ORG_TITLE_MODE = RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE     // show textual title is the default
        showMode = self.mEFP!.mOrgRec.rOrg_Title_Mode
        
        // adjust the Title Mode depending on what we actually have
        if !(shownTitle ?? "").isEmpty && self.mEFP!.mOrgRec.rOrg_Logo_Image_PNG_Blob != nil {
            // both are available
            if !(shown2ndTitle ?? "").isEmpty && (showMode == RecOrganizationDefs.ORG_TITLE_MODE.BOTH_50_50 ||
                                                  showMode == RecOrganizationDefs.ORG_TITLE_MODE.BOTH_LOGO_DOMINATES ) {
                showMode = RecOrganizationDefs.ORG_TITLE_MODE.BOTH_TITLE_DOMINATES
            }
        } else if !(shownTitle ?? "").isEmpty {
            // only a textual title is available
            showMode = RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE
        } else if self.mEFP!.mOrgRec.rOrg_Logo_Image_PNG_Blob != nil {
            // only a logo is available
            showMode = RecOrganizationDefs.ORG_TITLE_MODE.ONLY_LOGO
        } else {
            // neither are available; show nothing
            return
        }
        
        // note about rotation; since the ContainerView may be outside the current viewing area of the ScrollView;
        // it may not have been yet auto-layed out, so its view.frame may not yet be correct;
        // we are not using Constraint-based Auto-layout
        var width:CGFloat = self.view.frame.size.width
        
        // set the overall background color and get the text color
        self.view.backgroundColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_Background_Color
        
        // prepare for title alternatives
        var titleWidth:CGFloat = 0.0
        var biTitleMaxWidth:CGFloat = 0.0
        var idealTitle:String = ""
        if shownTitle != nil {
            idealTitle = shownTitle!
            let fontAttributes = [NSAttributedString.Key.font: self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Font]
            titleWidth = shownTitle!.size(withAttributes: fontAttributes).width
            biTitleMaxWidth = titleWidth
            if !(shown2ndTitle ?? "").isEmpty {
                let width = shown2ndTitle!.size(withAttributes: fontAttributes).width
                if width > titleWidth { biTitleMaxWidth = width }
                else { biTitleMaxWidth = titleWidth }
                idealTitle = shownTitle! + "\n" + shown2ndTitle!
            }
        }

        // show the new subviews
        switch showMode {
        case RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE:
            // show just the title
            if shownTitle != nil {
                let label:UILabel = UILabel(frame:CGRect(x:0.0, y:0.0, width:width, height:50.0))
                label.font = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Font
                label.numberOfLines = 2
                label.textAlignment = NSTextAlignment.center
                label.backgroundColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_Background_Color
                label.textColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Color
                if biTitleMaxWidth <= width { label.text = idealTitle }
                else { label.text = shownTitle! }
                self.view.addSubview(label)
            }
            break
            
        case RecOrganizationDefs.ORG_TITLE_MODE.ONLY_LOGO:
            // show just the logo
            let imageView:UIImageView = UIImageView(frame:CGRect(x:0.0, y:0.0, width:width, height:50.0))
            imageView.contentMode = UIView.ContentMode.scaleAspectFit
            imageView.image = UIImage(data:self.mEFP!.mOrgRec.rOrg_Logo_Image_PNG_Blob!)!
            self.view.addSubview(imageView)
            break
            
        case RecOrganizationDefs.ORG_TITLE_MODE.BOTH_50_50:
            // show title then logo 50/50 split the width of the screen
            width = width / 2.0
            width.round(.up)
            
            if shownTitle != nil {
                let label:UILabel = UILabel(frame:CGRect(x:0.0, y:0.0, width:width, height:50.0))
                label.font = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Font
                label.numberOfLines = 2
                label.textAlignment = NSTextAlignment.center
                label.backgroundColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_Background_Color
                label.textColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Color
                if biTitleMaxWidth <= width { label.text = idealTitle }
                else { label.text = shownTitle! }
                self.view.addSubview(label)
            }
            
            let imageView:UIImageView = UIImageView(frame:CGRect(x:width, y:0.0, width:width, height:50.0))
            imageView.contentMode = UIView.ContentMode.scaleAspectFit
            imageView.image = UIImage(data:self.mEFP!.mOrgRec.rOrg_Logo_Image_PNG_Blob!)!
            self.view.addSubview(imageView)
            break
            
        case RecOrganizationDefs.ORG_TITLE_MODE.BOTH_LOGO_DOMINATES:
            // show the logo first at its fullest fit size within the height constraint
            let tempImageView = UIImage(data:self.mEFP!.mOrgRec.rOrg_Logo_Image_PNG_Blob!)!
            var logoWidth:CGFloat = tempImageView.size.width * (50.0 / tempImageView.size.height)
            logoWidth.round(.up)
            if logoWidth > width { logoWidth = width }
            
            let imageView:UIImageView = UIImageView(frame:CGRect(x:0.0, y:0.0, width:logoWidth, height:50.0))
            imageView.contentMode = UIView.ContentMode.scaleAspectFit
            imageView.image = UIImage(data:self.mEFP!.mOrgRec.rOrg_Logo_Image_PNG_Blob!)!
            self.view.addSubview(imageView)
            
            // now if there is space remaining, show the title
            if logoWidth < width {
                if shownTitle != nil {
                    width = width - logoWidth
                    let label:UILabel = UILabel(frame:CGRect(x:logoWidth, y:0.0, width:width, height:50.0))
                    label.font = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Font
                    label.numberOfLines = 2
                    label.textAlignment = NSTextAlignment.center
                    label.backgroundColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_Background_Color
                    label.textColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Color
                    if biTitleMaxWidth <= width { label.text = idealTitle }
                    else { label.text = shownTitle! }
                    self.view.addSubview(label)
                }
            }
            break
            
        case RecOrganizationDefs.ORG_TITLE_MODE.BOTH_TITLE_DOMINATES:
            // show the title first; care has to be taken to force the UILabel to wrap lines BEFORE shrinking the logo
            // first do various size calcuations; it gets more complicated with a second bilingual title
            let tempImageView:UIImage = UIImage(data:self.mEFP!.mOrgRec.rOrg_Logo_Image_PNG_Blob!)!
            var logoWidth:CGFloat = tempImageView.size.width * (50.0 / tempImageView.size.height)
            logoWidth.round(.up)
            
            if biTitleMaxWidth <= width - logoWidth {
                titleWidth = biTitleMaxWidth
                let label:UILabel = UILabel(frame:CGRect(x:0.0, y:0.0, width:titleWidth, height:50.0))
                label.font = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Font
                label.numberOfLines = 2
                label.textAlignment = NSTextAlignment.center
                label.backgroundColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_Background_Color
                label.textColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Color
                label.text = idealTitle
                self.view.addSubview(label)
            } else {
                //titleWidth = titleWidth + 10.0
                if titleWidth > width { titleWidth = width }

                // is the title going to force the logo to shrink?
                if titleWidth + logoWidth > width {
                    // potentially yes; is the second line showing yet, and is truncation occuring of the title?
                    titleWidth = width - logoWidth - 1.0
                    var titleSizeEstRect:CGSize = CGSize.zero
                    repeat {
                        titleWidth = titleWidth + 1.0
                        titleSizeEstRect = shownTitle!.boundingRect(
                            with: CGSize(width: titleWidth , height: .greatestFiniteMagnitude),
                            options: .usesLineFragmentOrigin,
                            attributes: [.font: self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Font],
                            context: nil).size
                    } while titleSizeEstRect.height > 50.0 && titleWidth < width
                }
                
                let label:UILabel = UILabel(frame:CGRect(x:0.0, y:0.0, width:titleWidth, height:50.0))
                label.font = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Font
                label.numberOfLines = 2
                label.textAlignment = NSTextAlignment.center
                label.backgroundColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_Background_Color
                label.textColor = self.mEFP!.mOrgRec.rOrg_Visuals.rOrgTitle_TitleText_Color
                label.text = shownTitle!
                self.view.addSubview(label)
            }
            
            // now if there is space remaining, show the logo
            if titleWidth < width {
                width = width - titleWidth
                let imageView:UIImageView = UIImageView(frame:CGRect(x:titleWidth, y:0.0, width:width, height:50.0))
                imageView.contentMode = UIView.ContentMode.scaleAspectFit
                imageView.image = UIImage(data:self.mEFP!.mOrgRec.rOrg_Logo_Image_PNG_Blob!)!
                self.view.addSubview(imageView)
            }
            break
        }
    }
}
