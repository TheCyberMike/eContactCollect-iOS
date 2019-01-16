//
//  PopupEnterEventViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/9/18.
//

import UIKit
import Eureka

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol CEVC_Delegate {
    func completed_CEVC(wasCancelled:Bool, eventShortName:String?, eventFullTitles:[CodePair]?)
}

class PopupEnterEventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // caller pre-set member variables
    public var mCEVCdelegate:CEVC_Delegate? = nil   // optional callback

    // member variables
    private var mRows:Int = 1
    
    // member constants and other static content
    private let mCTAG:String = "VCUCEE"

    // outlets to screen controls
    @IBOutlet weak var tableview_shown_names: UITableView!
    @IBOutlet weak var textfield_event_short_name: UITextField!
    @IBAction func button_choose_pressed(_ sender: UIButton) {
        var hasShort:Bool = false
        var hasShowns:Bool = false
        if self.textfield_event_short_name.text != nil {
            if !(self.textfield_event_short_name.text!.isEmpty) { hasShort = true }
        }
        var fullTitles:[CodePair] = []
        var inxPath:IndexPath = IndexPath(item: 0, section: 0)
        for inx in 0...mRows - 1 {
            inxPath.item = inx
            let tvc:PopupEnterEventTableViewCell = tableview_shown_names.cellForRow(at: inxPath) as! PopupEnterEventTableViewCell
            if !(tvc.textfield_name_shown.text ?? "").isEmpty { hasShowns = true }
            fullTitles.append(CodePair(tvc.mLangRegion!, tvc.textfield_name_shown!.text ?? ""))
        }
        if hasShowns && !hasShort {
            AppDelegate.showAlertDialog(vc:self, title:NSLocalizedString("Entry Error", comment:""), message:NSLocalizedString("Must have an Event short code if any Names shown are filled in", comment:""), buttonText:NSLocalizedString("Okay", comment:""))
            return
        }
        if self.mCEVCdelegate != nil { self.mCEVCdelegate!.completed_CEVC(wasCancelled: false, eventShortName: self.textfield_event_short_name.text!, eventFullTitles: fullTitles) }
        dismiss(animated: true, completion: nil)
    }
    @IBAction func button_cancel_pressed(_ sender: UIButton) {
        // cancel button pressed; tell delegate as such, then dismiss and return to the parent view controller
        if self.mCEVCdelegate != nil { self.mCEVCdelegate!.completed_CEVC(wasCancelled: true, eventShortName: nil, eventFullTitles: nil) }
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
        if AppDelegate.mEntryFormProvisioner != nil {
            self.mRows = AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_LangRegionCodes_Supported.count
        }
        tableview_shown_names.delegate = self
        tableview_shown_names.dataSource = self
        tableview_shown_names.reloadData()
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        if AppDelegate.mEntryFormProvisioner != nil {
            if AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Event_Code_For_SV_File != nil {
                textfield_event_short_name.text = AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Event_Code_For_SV_File!
            } else {
                self.textfield_event_short_name.text = ""
            }
            var inxPath:IndexPath = IndexPath(item: 0, section: 0)
            for inx in 0...mRows - 1 {
                inxPath.item = inx
                let tvc:PopupEnterEventTableViewCell = tableview_shown_names.cellForRow(at: inxPath) as! PopupEnterEventTableViewCell
                do {
                    tvc.textfield_name_shown?.text = try AppDelegate.mEntryFormProvisioner!.mOrgRec.getEventTitleShown(langRegion: tvc.mLangRegion!)
                } catch {}  // report no error

            }
        } else {
            self.textfield_event_short_name.text = ""
        }
        textfield_event_short_name.becomeFirstResponder()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///////////////////////////////////////////////////
    // tableView handlers for UITableViewDataSource and UITableViewDelegate
    ///////////////////////////////////////////////////
    
    // return the number of rows to display
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.mRows
    }
    
    // compose each cell's controls
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell:PopupEnterEventTableViewCell = tableView.dequeueReusableCell(withIdentifier:"TblViewCell Events", for:indexPath) as! PopupEnterEventTableViewCell
        if AppDelegate.mEntryFormProvisioner != nil {
            cell.mLangRegion = AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_LangRegionCodes_Supported[indexPath.row]
            cell.label_title?.text = NSLocalizedString("Name shown in ", comment:"") + AppDelegate.makeFullDescription(forLangRegion: cell.mLangRegion!)
        }
        return cell
    }
    
    // when using auto-layout and sizing-classes for a custom UITableViewCell that needs to auto-resize, both the following are needed
    /*func tableView(tableView:UITableView, estimatedHeightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat {
        return 60
    }
    func tableView(tableView:UITableView, heightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat {
        return 60
    }*/
}

class PopupEnterEventTableViewCell: UITableViewCell {
    // member variables
    public var mLangRegion:String? = nil
    
    // outlets to screen controls
    @IBOutlet weak var label_title: UILabel!
    @IBOutlet weak var textfield_name_shown: UITextField!
    
    // TableViewCell has been prepared and ready to be shown
    override func awakeFromNib() {
        super.awakeFromNib()
        // do any custom changes to the cell's view
    }
}
