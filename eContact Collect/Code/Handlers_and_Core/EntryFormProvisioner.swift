//
//  EntryFormProvisioner.swift
//  eContact Collect
//
//  Created by Yo on 11/25/18.
//

import Foundation

// this class provisions the EntryViewController, either the main one or one operating in Preview Mode;
// various ViewControllers (Entry, EntryForm, OrgTitle) all reference one common object instanciation of this class
public class EntryFormProvisioner {
    public enum EFP_SHOW_MODE:Int {
        case SINGLE_LANG = 0, BILINGUAL = 1, MULTI_LINGUAL = 2
    }
    
    // member variables
    private var _mOrgRec:RecOrganizationDefs
    public var mOrgRec:RecOrganizationDefs {                        // sets the current Organization
        get { return self._mOrgRec }
        set {
              self._mOrgRec = newValue
              self.reassess()
        }
    }
    private var _mFormRec:RecOrgFormDefs?
    public var mFormRec:RecOrgFormDefs? {                           // sets the current Form
        get { return self._mFormRec }
        set {
            self._mFormRec = newValue
            self.reassess()
        }
    }
    public var mFormFieldEntries:OrgFormFields? = nil               // storage area for the Form's FormFields
    public var mIsMainlineEFP:Bool = false                          // indicates that this EFP is the mainline global EFP
    public var mPreviewMode:Bool = false                            // indicates that this EFP is for a Preview Mode of the EntryViewController
    public var mDismissing:Bool = false                             // indicates that this EFP will soon be deleted so stop referring to it
    public private(set) var mShowMode:EFP_SHOW_MODE = .SINGLE_LANG  // indicates the current shown mode: single, bilingual, all
    public private(set) var mShownLanguage:String = "en"            // indicates the current shown language
    public private(set) var mShownBilingualLanguage:String = ""     // indicates the current bilingual language
    
    // member constants and other static content
    internal var mCTAG:String = "HEFP"
    
    deinit {
//debugPrint("\(self.mCTAG).deinit STARTED")
    }
    
    // class object initializer
    init(forOrgRecOnly:RecOrganizationDefs) {
        self._mOrgRec = forOrgRecOnly
        self._mFormRec = nil
        self.mFormFieldEntries = nil
        self.mPreviewMode = false
        self.reassess()
    }


    // class object initializer
    init(forOrgRec:RecOrganizationDefs, forFormRec:RecOrgFormDefs) {
        self._mOrgRec = forOrgRec
        self._mFormRec = forFormRec
        self.mFormFieldEntries = nil
        self.mPreviewMode = false
        self.reassess()
    }
    
    // clear out the EFP so non-global versions of it can get deeply dealloc
    public func clear() {
        self.mDismissing = true
        if self.mFormFieldEntries != nil { self.mFormFieldEntries?.removeAll(); self.mFormFieldEntries = nil }
        self._mFormRec = nil
    }
    
    // set both at the same time so only one Notification gets sent out
    public func setBoth(orgRec:RecOrganizationDefs, formRec:RecOrgFormDefs) {
        self._mOrgRec = orgRec
        self._mFormRec = formRec
        self.reassess()
    }
    
    // reassess the provided OrgRec and FormRec (since they were changed)
    public func reassess() {
debugPrint("\(self.mCTAG).reassess STARTED")
        self.mShownBilingualLanguage = ""
        self.mShowMode = .SINGLE_LANG
        
        let oCnt:Int = self._mOrgRec.rOrg_LangRegionCodes_Supported.count
        if oCnt == 0 {
            self.mShownLanguage = self._mOrgRec.rOrg_LangRegionCode_SV_File
        } else if oCnt == 1 {
            self.mShownLanguage = self._mOrgRec.rOrg_LangRegionCodes_Supported[0]
        } else if oCnt >= 2 {
            if self._mFormRec != nil {
                let fCnt:Int = (self._mFormRec!.rForm_Lingual_LangRegions?.count ?? 0)
                if fCnt == 2 {
                    self.mShowMode = .BILINGUAL
                    self.mShownLanguage = self._mFormRec!.rForm_Lingual_LangRegions![0]
                    self.mShownBilingualLanguage = self._mFormRec!.rForm_Lingual_LangRegions![1]
                } else if fCnt == 1 {
                    self.mShownLanguage = self._mFormRec!.rForm_Lingual_LangRegions![0]
                } else {
                    self.mShowMode = .MULTI_LINGUAL
                    self.mShownLanguage = self._mOrgRec.rOrg_LangRegionCodes_Supported[0]
                }
            } else {
                self.mShowMode = .MULTI_LINGUAL
                self.mShownLanguage = self._mOrgRec.rOrg_LangRegionCodes_Supported[0]
            }
        }
        if !self.mDismissing { NotificationCenter.default.post(name: .APP_EFP_OrgFormChange, object: self) }
    }
    
    // change to a new primary language only when in multi-lingual mode
    public func changeNewMultiLingual(toLangRegion:String) {
        if self.mShowMode == .MULTI_LINGUAL {
            self.mShownLanguage = toLangRegion
            if !self.mDismissing { NotificationCenter.default.post(name: .APP_EFP_LangRegionChanged, object: self) }
        }
    }
    
    // force change the shown language ... this is used only by the Org Editor and Wizard
    public func forceChange(toLangRegion:String) {
        self.mShownLanguage = toLangRegion
        if !self.mDismissing { NotificationCenter.default.post(name: .APP_EFP_LangRegionChanged, object: self) }
    }
}
