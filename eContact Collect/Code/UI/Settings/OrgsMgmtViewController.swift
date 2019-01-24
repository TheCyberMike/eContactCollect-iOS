//
//  ManageOrgsViewController.swift
//  eContact Collect
//
//  Created by Yo on 9/28/18.
//

import UIKit
import SQLite

class OrgsMgmtViewController: UITableViewController, OEVC_Delegate {
    // member variables
    private var mOrg_database_List:NSMutableArray = NSMutableArray()
    
    // member constants and other static content
    private let mCTAG:String = "VCSOM"
    
    // outlets to screen controls
    @IBOutlet weak var tableView_org_list: UITableView!
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED \(self)")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED \(self)")
        super.viewDidLoad()
        self.tableView_org_list.delegate = self
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED \(self)")
        super.viewWillAppear(animated)
        self.build_database_list()
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        self.mOrg_database_List.removeAllObjects()  // save some memory since this table gets rebuilt and reloaded at viewWillAppear()
        self.tableView_org_list.reloadData()
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
            self.mOrg_database_List.removeAllObjects()
            self.tableView_org_list.reloadData()
            //self.tableView_org_list.delegate = nil
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
        if segue.destination is OrgEditViewController
        {
            let vc = segue.destination as! OrgEditViewController
            vc.mOEVCdelegate = self
        }
    }
    
    // the add/edit Organization view controller has finished;
    // the TableView will be auto-refreshed upon re-entry
    func completed_OEVC(wasSaved:Bool) {
        if wasSaved {
            self.build_database_list()
        }
    }
    
    // build the list of Org records from our database
    private func build_database_list() {
        self.mOrg_database_List.removeAllObjects()
        do {
            let records:AnySequence<Row> = try RecOrganizationDefs.orgGetAllRecs()
            for rowRec in records {
                let orgRec = try RecOrganizationDefs(row:rowRec)
                self.mOrg_database_List.add(orgRec)
            }
        } catch {
            // error.log and alert already posted
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
        
        self.tableView_org_list.reloadData()
    }
    
    // delete an organization of the indicated table view cell;
    // called by OrgsMgmtTableViewCell
    internal func doDelete(cell:OrgsMgmtTableViewCell) {
        // set the proposed row as selected
        for cell in tableView.visibleCells {
            cell.setSelected(false, animated: false)
        }
        cell.setSelected(true, animated: true)
        
        // get the needed information from the cell
        let indexPath:IndexPath? = tableView.indexPath(for:cell)
        if indexPath == nil { return }
        let orgRec:RecOrganizationDefs = self.mOrg_database_List[indexPath!.row] as! RecOrganizationDefs

        // query if the end-user is really sure about the delete
        AppDelegate.showYesNoDialog(vc:self, title:NSLocalizedString("Delete Confirmation", comment:""), message:NSLocalizedString("Delete Organization?", comment:"")+" [\(orgRec.rOrg_Code_For_SV_File)]", buttonYesText:NSLocalizedString("Yes", comment:""), buttonNoText:NSLocalizedString("No", comment:""), callbackAction:1, callbackString1:orgRec.rOrg_Code_For_SV_File, callbackString2:nil, completion: {(vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
            // callback from the yes/no dialog upon one of the buttons being pressed
            if theResult && callbackString1 != nil {
                // answer was Yes; delete the indicated Organization
                do {
                    _ = try RecOrganizationDefs.orgDeleteRec(orgShortName: callbackString1!)  // will also delete all related Forms and FormFields
                    (UIApplication.shared.delegate as! AppDelegate).checkDeletionCurrentOrg(withOrgRecShortName: callbackString1!)
                    self.build_database_list()
                } catch {
                    // error.log and alert already posted
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
            return  // from callback
        })
    }
    
    // edit an organizations of the indicated table view cell;
    // called by OrgsMgmtTableViewCell
    internal func doEdit(cell:OrgsMgmtTableViewCell) {
        // set the proposed row as selected
        for cell in tableView.visibleCells {
            cell.setSelected(false, animated: false)
        }
        cell.setSelected(true, animated: true)
        
        // get the needed information from the cell
        let indexPath:IndexPath? = tableView.indexPath(for:cell)
        if indexPath == nil { return }
        self.doEdit(indexPath: indexPath!)
    }
    internal func doEdit(indexPath:IndexPath) {
        let orgRec:RecOrganizationDefs = self.mOrg_database_List[indexPath.row] as! RecOrganizationDefs
        
        // open the Edit Org view for changing
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let nextViewController:OrgEditViewController = storyboard.instantiateViewController(withIdentifier:"VC OrgEdit") as! OrgEditViewController
        nextViewController.mOEVCdelegate = self
        nextViewController.mAction = .Change
        nextViewController.mEdit_orgRec = RecOrganizationDefs(existingRec: orgRec)
        self.navigationController?.pushViewController(nextViewController, animated:true)
    }
    
    // edit an organization's forms of the indicated table view cell;
    // called by OrgsMgmtTableViewCell
    internal func doEditForms(cell:OrgsMgmtTableViewCell) {
        // set the proposed row as selected
        for cell in tableView.visibleCells {
            cell.setSelected(false, animated: false)
        }
        cell.setSelected(true, animated: true)
        
        // get the needed information from the cell
        let indexPath:IndexPath? = tableView.indexPath(for:cell)
        if indexPath == nil { return }
        let orgRec:RecOrganizationDefs = self.mOrg_database_List[indexPath!.row] as! RecOrganizationDefs
        
        // open the Forms Mgmt view
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let nextViewController:FormsMgmtViewController = storyboard.instantiateViewController(withIdentifier:"VC FormsMgmt") as! FormsMgmtViewController
        nextViewController.mFor_orgRec = RecOrganizationDefs(existingRec: orgRec) 
        self.navigationController?.pushViewController(nextViewController, animated:true)
    }
    
    ///////////////////////////////////////////////////
    // tableView handlers for UITableViewDataSource and UITableViewDelegate
    ///////////////////////////////////////////////////
    
    // return the number of rows to display
    override func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.mOrg_database_List.count
    }
    
    // compose each cell's controls
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell:OrgsMgmtTableViewCell = tableView.dequeueReusableCell(withIdentifier:"TblViewCell Orgs Mgmt", for:indexPath) as! OrgsMgmtTableViewCell
        cell.mTableViewDelegate = self
        let orgRec:RecOrganizationDefs = self.mOrg_database_List[indexPath.row] as! RecOrganizationDefs
        cell.button_org_short_name?.setTitle(orgRec.rOrg_Code_For_SV_File, for:UIControl.State.normal)
        return cell
    }
    
    // when using auto-layout and sizing-classes for a custom UITableViewCell that needs to auto-resize, both the following are needed
    func tableView(tableView:UITableView, estimatedHeightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat {
        return 44
    }
    func tableView(tableView:UITableView, heightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // a cell row was tapped; setup for editing it;
    // for some reason I cannot get this method to be invoked anymore despite alot of Googling and different texts;
    // so I implemented a text button instead of a label for each row
    override func tableView(_ tableView:UITableView, didSelectRowAt indexPath:IndexPath) {
//debugPrint("\(self.mCTAG).didSelectRowAtIndexPath STARTED")
        self.doEdit(indexPath: indexPath)
    }
}

///////////////////////////////////////////////////
// class definition for OrgsMgmtTableViewCell
///////////////////////////////////////////////////

class OrgsMgmtTableViewCell: UITableViewCell {
    // member variables
    public weak var mTableViewDelegate:OrgsMgmtViewController? = nil
    
    // outlets to screen controls
    @IBOutlet weak var button_org_short_name: UIButton!
    @IBAction func button_org_short_name_pressed(_ sender: UIButton) {
        self.mTableViewDelegate?.doEdit(cell: self)
    }
    @IBAction func button_delete_org(_ sender: UIButton) {
        self.mTableViewDelegate?.doDelete(cell: self)
    }
    @IBAction func button_edit_org_forms(_ sender: UIButton) {
        self.mTableViewDelegate?.doEditForms(cell: self)
    }
    
    // TableViewCell has been prepared and ready to be shown
    override func awakeFromNib() {
        super.awakeFromNib()
        // do any custom changes to the cell's view
    }
}
