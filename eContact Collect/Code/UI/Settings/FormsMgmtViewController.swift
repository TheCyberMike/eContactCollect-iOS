//
//  FormsMgmtViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/10/18.
//

import UIKit
import SQLite

class FormsMgmtViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FEVC_Delegate, CECVC_Delegate {
    // caller pre-set member variables
    public var mFor_orgRec:RecOrganizationDefs? = nil   // show only Forms for the supplied Org record; will never be changed; is a COPY not a reference

    // member variables
    private var mLocalEFP:EntryFormProvisioner? = nil
    private var mOrgForm_database_List:NSMutableArray = NSMutableArray()
    
    // member constants and other static content
    private let mCTAG:String = "VCSFM"

    // outlets to screen controls
    @IBOutlet weak var tableview_form_list: UITableView!
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // locate the child OrgTitleViewController
        let orgTitleViewController:OrgTitleViewController? = children.first as? OrgTitleViewController

        // setup a local EFP for the OrgTitle VC
        assert(self.mFor_orgRec != nil, "\(self.mCTAG).viewDidLoad self.mFor_orgRec == nil")    // this is a programming error
        assert(orgTitleViewController != nil, "\(self.mCTAG).viewDidLoad orgTitleViewController == nil")    // this is a programming error
        self.mLocalEFP = EntryFormProvisioner(forOrgRecOnly: self.mFor_orgRec!)
        orgTitleViewController!.mEFP = self.mLocalEFP

        // setup everything
        self.tableview_form_list.delegate = self
        self.tableview_form_list.estimatedRowHeight = 44.0
        self.tableview_form_list.rowHeight = UITableView.automaticDimension
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        self.build_database_list()
    }
    
    // called by the framework when the view has fully appeared
    override func viewDidAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewDidAppear STARTED")
        super.viewDidAppear(animated)
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        self.mOrgForm_database_List.removeAllObjects()  // save some memory since this table gets rebuilt and reloaded at viewWillAppear()
        self.tableview_form_list.reloadData()
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
            self.mLocalEFP?.mDismissing = true
        }
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
           (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
            self.mLocalEFP?.mDismissing = true
            self.mOrgForm_database_List.removeAllObjects()
            self.tableview_form_list.reloadData()
            self.tableview_form_list.delegate = nil
            self.mFor_orgRec = nil
            self.mLocalEFP?.clear()
            self.mLocalEFP = nil
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
    
    // called when the Add button is pressed before the segue is handed off to the new view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is FormEditViewController
        {
            let vc = segue.destination as! FormEditViewController
            vc.mFEVCdelegate = self
            vc.mReference_orgRec = RecOrganizationDefs(existingRec: self.mFor_orgRec!)
        }
    }
    
    // the add/edit Form view controller has finished;
    // the TableView will be auto-refreshed upon re-entry
    func completed_FEVC(wasSaved:Bool) {
        if wasSaved {
            self.build_database_list()
        }
    }
    
    // the clone is desired and a new name provided
    func completed_CECVC(wasCancelled:Bool, newFormName:String, hadIndex:Int) {
        // all seems okay; perform the clone after dismissing the popup
        dismiss(animated: true, completion: {
            // perform the following after the dismiss is completed so if there is an error, the showAlertDialog will work
            if !wasCancelled {
                let orgFormRec:RecOrgFormDefs = self.mOrgForm_database_List[hadIndex] as! RecOrgFormDefs
                do {
                    try orgFormRec.clone(newFormName: newFormName, withOrgRec: self.mFor_orgRec!)
                } catch {
                    // error.log and alert already posted
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
                self.build_database_list()
            }
            return // from the callback
        })
    }
    
    // build the list of Form records from our database
    private func build_database_list() {
        self.mOrgForm_database_List.removeAllObjects()
        var records:AnySequence<Row>
        do {
            records = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: self.mFor_orgRec!.rOrg_Code_For_SV_File)
            for rowRec in records {
                let orgFormRec = try RecOrgFormDefs(row: rowRec)
                self.mOrgForm_database_List.add(orgFormRec)
            }
            self.tableview_form_list.reloadData()
        } catch {
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
    }
    
    // delete a form of the indicated table view cell;
    // called by FormsMgmtTableViewCell
    internal func doDelete(cell:FormsMgmtTableViewCell) {
        // set the proposed row as selected
        for cell in self.tableview_form_list.visibleCells {
            cell.setSelected(false, animated: false)
        }
        cell.setSelected(true, animated: true)
        
        // get the needed information from the cell
        let indexPath:IndexPath? = self.tableview_form_list.indexPath(for:cell)
        if indexPath == nil { return }
        let orgFormRec:RecOrgFormDefs = self.mOrgForm_database_List[indexPath!.row] as! RecOrgFormDefs
        
        // query if the end-user is really sure about the delete
        AppDelegate.showYesNoDialog(vc:self, title:NSLocalizedString("Delete Confirmation", comment:""), message:NSLocalizedString("Delete Form?", comment:"")+" [\(orgFormRec.rForm_Code_For_SV_File)]", buttonYesText:NSLocalizedString("Yes", comment:""), buttonNoText:NSLocalizedString("No", comment:""), callbackAction:1, callbackString1:orgFormRec.rForm_Code_For_SV_File, callbackString2:orgFormRec.rOrg_Code_For_SV_File, completion: {(vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
            // callback from the yes/no dialog upon one of the buttons being pressed
            if theResult && callbackString1 != nil && callbackString2 != nil  {
                // answer was Yes; delete the indicated Form
                do {
                    // will also auto-delete all related RecOrgFormFieldDefs and RecOrgFormFieldLocales
                    _ = try RecOrgFormDefs.orgFormDeleteRec(formShortName: callbackString1!, forOrgShortName: callbackString2!)
                    (UIApplication.shared.delegate as! AppDelegate).checkDeletionCurrentForm(withFormRecShortName: callbackString1!, withOrgRecShortName: callbackString2!)
                    self.build_database_list()
                } catch {
                    // error.log and alert already posted
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
            return  // from callback
        })
    }
    
    // edit a form of the indicated table view cell;
    // called by FormsMgmtTableViewCell
    internal func doEdit(cell:FormsMgmtTableViewCell) {
        // set the proposed row as selected
        for cell in self.tableview_form_list.visibleCells {
            cell.setSelected(false, animated: false)
        }
        cell.setSelected(true, animated: true)
        
        // get the needed information from the cell
        let indexPath:IndexPath? = self.tableview_form_list.indexPath(for:cell)
        if indexPath == nil { return }
        self.doEdit(indexPath: indexPath!)
        
    }
    internal func doEdit(indexPath:IndexPath) {
        let orgFormRec:RecOrgFormDefs = self.mOrgForm_database_List[indexPath.row] as! RecOrgFormDefs
        
        // open the Edit Form view for changing
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let nextViewController:FormEditViewController = storyboard.instantiateViewController(withIdentifier:"VC FormEdit") as! FormEditViewController
        nextViewController.mFEVCdelegate = self
        nextViewController.mAction = .Change
        nextViewController.mReference_orgRec = RecOrganizationDefs(existingRec: self.mFor_orgRec!)
        nextViewController.mEdit_orgFormRec = RecOrgFormDefs(existingRec: orgFormRec)
        self.navigationController?.pushViewController(nextViewController, animated:true)
    }
    
    // clone a form of the indicated table view cell;
    // called by FormsMgmtTableViewCell
    internal func doClone(cell:FormsMgmtTableViewCell) {
        // set the proposed row as selected
        for cell in self.tableview_form_list.visibleCells {
            cell.setSelected(false, animated: false)
        }
        cell.setSelected(true, animated: true)
        
        // get the needed information from the cell
        let indexPath:IndexPath? = self.tableview_form_list.indexPath(for:cell)
        if indexPath == nil { return }
        
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let nextViewController:PopupEnterCloneViewController = storyboard.instantiateViewController(withIdentifier:"VC PopupEnterClone") as! PopupEnterCloneViewController
        nextViewController.mCECVCdelegate = self
        nextViewController.mFormInRowInx = indexPath!.row
        nextViewController.mOrgShortName = self.mFor_orgRec!.rOrg_Code_For_SV_File
        nextViewController.modalPresentationStyle = .custom
        self.present(nextViewController, animated: true, completion: nil)
    }
    
    ///////////////////////////////////////////////////
    // tableView handlers for UITableViewDataSource and UITableViewDelegate
    ///////////////////////////////////////////////////
    
    // return the number of rows to display
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.mOrgForm_database_List.count
    }
    
    // compose each cell's controls
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell:FormsMgmtTableViewCell = tableView.dequeueReusableCell(withIdentifier:"TblViewCell Forms Mgmt", for:indexPath) as! FormsMgmtTableViewCell
        cell.mTableViewDelegate = self
        let orgFormRec:RecOrgFormDefs = self.mOrgForm_database_List[indexPath.row] as! RecOrgFormDefs
        cell.button_form_short_name?.setTitle(orgFormRec.rForm_Code_For_SV_File, for:UIControl.State.normal)
        self.tableview_form_list.delegate = self
        return cell
    }
    
    // when using auto-layout and sizing-classes for a custom UITableViewCell that needs to auto-resize, both the following are needed
    func tableView(_ tableView:UITableView, estimatedHeightForRowAt indexPath:IndexPath) -> CGFloat {
        return 44
    }
    func tableView(_ tableView:UITableView, heightForRowAt indexPath:IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // a cell row was tapped; setup for editing it;
    // for some reason I cannot get this method to be invoked anymore despite alot of Googling and different texts;
    // so I implemented a text button instead of a label for each row
    func tableView(_ tableView:UITableView, didSelectRowAt indexPath:IndexPath) {
//debugPrint("\(self.mCTAG).didSelectRowAtIndexPath STARTED")
        self.doEdit(indexPath: indexPath)
    }
}

class FormsMgmtTableViewCell: UITableViewCell {
    // member variables
    public weak var mTableViewDelegate:FormsMgmtViewController? = nil
    
    // outlets to screen controls
    @IBOutlet weak var button_form_short_name: UIButton!
    @IBAction func button_form_short_name_pressed(_ sender: UIButton) {
        self.mTableViewDelegate?.doEdit(cell: self)
    }
    @IBAction func button_delete_form_pressed(_ sender: UIButton) {
        self.mTableViewDelegate?.doDelete(cell: self)
    }
    @IBAction func button_clone_form_pressed(_ sender: UIButton) {
        self.mTableViewDelegate?.doClone(cell: self)
    }
    
    // TableViewCell has been prepared and ready to be shown
    override func awakeFromNib() {
        super.awakeFromNib()
        // do any custom changes to the cell's view
    }
}
