//
//  ChooserLangRegionViewController.swift
//  eContact Collect
//
//  Created by Dev on 1/9/19.
//

import UIKit
import SQLite

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol CLRVC_Delegate {
    // return wasChosen=nil if cancelled; wasChosen=LangRegion if chosen
    func completed_CLRVC(fromVC:ChooserLangRegionViewController, wasChosen:String?)
}

class ChooserLangRegionViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    // caller pre-set member variables
    public var mCLRVCdelegate:CLRVC_Delegate? = nil         // optional callback
    public weak var mEFP:EntryFormProvisioner? = nil        // caller must set the active EFP
    
    // member variables
    private var mLangRegions:[String] = []
    
    // member constants and other static content
    private let mCTAG:String = "VCUCLR"
    
    // outlets to screen controls
    @IBOutlet weak var pickerview_langRegions: UIPickerView!
    @IBAction func button_cancel_pressed(_ sender: UIButton) {
        // cancel button pressed; tell delegate as such
        if mCLRVCdelegate != nil {
            mCLRVCdelegate!.completed_CLRVC(fromVC: self, wasChosen: nil)
        }
        dismiss(animated: true, completion: nil)
    }
    @IBAction func button_choose_pressed(_ sender: UIButton) {
        // choose button pressed; tell delegate as such
        let maxRow:Int = self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported.count - 1
        let row:Int = self.pickerview_langRegions.selectedRow(inComponent:0)
        var langRegion:String
        if maxRow == 0 {
            langRegion = self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[0]
        } else if row == maxRow {
            langRegion = self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[1]
        } else if row == maxRow - 1 {
            langRegion = self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[0]
        } else {
            langRegion = self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[row + 2]
        }
        
        if mCLRVCdelegate != nil {
            mCLRVCdelegate!.completed_CLRVC(fromVC: self, wasChosen: langRegion)
        }
        dismiss(animated: true, completion: nil)
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
        assert(self.mEFP != nil, "\(self.mCTAG).viewDidLoad mEFP == nil")    // this is a programming error
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // create the list of all shown languages; the first two shown languages are placed at the end
        self.mLangRegions = []
        if self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported.count > 0 {
            for i:Int in 0...self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported.count - 1 {
                if i > 1 {
                    let title:String = self.mEFP!.mOrgRec.getLangNameInLang(langRegion: self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[i])
                    self.mLangRegions.append(title)
                }
            }
            for i:Int in 0...self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported.count - 1 {
                if i == 0 {
                    let title:String = self.mEFP!.mOrgRec.getLangNameInLang(langRegion: self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[i])
                    self.mLangRegions.append(title)
                } else if i == 1 {
                    let title:String = self.mEFP!.mOrgRec.getLangNameInLang(langRegion: self.mEFP!.mOrgRec.rOrg_LangRegionCodes_Supported[i])
                    self.mLangRegions.append(title)
                    break
                }
            }
        }
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related to the PickerView
    ///////////////////////////////////////////////////////////////////
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView:UIPickerView) -> Int { return 1 }
    
    // returns the # of rows in each component
    func pickerView(_ pickerView:UIPickerView, numberOfRowsInComponent component:Int) -> Int{ return self.mLangRegions.count }
    
    // returns the item in each row in each component
    func pickerView(_ pickerView:UIPickerView, titleForRow row:Int, forComponent component:Int) -> String? {
        return self.mLangRegions[row]
    }
}

