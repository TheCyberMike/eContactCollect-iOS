//
//  ContactsMgmtViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/16/18.
//

import UIKit
import SQLite

class ContactsMgmtViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CNVC_Delegate, CRVC_Delegate, CCRVC_Delegate {
    // member variables
    private var mContacts_database_List:NSMutableArray = NSMutableArray()
    
    // member constants and other static content
    private let mCTAG:String = "VCSCM"

    // outlets to screen controls
    @IBOutlet weak var tableview_contacts_list: UITableView!
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        
        // setups
        self.tableview_contacts_list.delegate = self
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // setups
        self.build_database_list()
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        self.mContacts_database_List.removeAllObjects()  // save some memory since this table gets rebuilt and reloaded at viewWillAppear()
        self.tableview_contacts_list.reloadData()
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
            self.mContacts_database_List.removeAllObjects()
            self.tableview_contacts_list.reloadData()
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
    
    // build the list of Form records from our database
    private func build_database_list() {
        self.mContacts_database_List.removeAllObjects()
        if AppDelegate.mEntryFormProvisioner != nil {
            var records:AnySequence<Row>
            do {
                records = try RecContactsCollected.ccGetAllRecs(forOrgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                for rowRec in records {
                    let ccRec = try RecContactsCollected(row:rowRec)
                    self.mContacts_database_List.add(ccRec)
                }
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).build_database_list", errorStruct: error, extra: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                return
            }
        }
        self.tableview_contacts_list.reloadData()
    }
    
    // review a contacts record of the indicated table view cell;
    // called by ContactsMgmtTableViewCell
    internal func doEdit(cell:ContactsMgmtTableViewCell) {
        // set the proposed row as selected
        for cell in tableview_contacts_list.visibleCells {
            cell.setSelected(false, animated: false)
        }
        cell.setSelected(true, animated: true)
        
        // get the needed information from the cell
        let indexPath:IndexPath? = tableview_contacts_list.indexPath(for:cell)
        if indexPath == nil { return }
        self.doEdit(indexPath: indexPath!)
    }
    internal func doEdit(indexPath:IndexPath) {
        let ccRec:RecContactsCollected = self.mContacts_database_List[indexPath.row] as! RecContactsCollected
        
        // open the ContactsReview view for changing
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let nextViewController:ContactsReviewViewController = storyboard.instantiateViewController(withIdentifier:"VC ContactsReview") as! ContactsReviewViewController
        nextViewController.mCCRVCdelegate = self
        nextViewController.mReview_CCrec = RecContactsCollected(existingRec: ccRec)
        self.navigationController?.pushViewController(nextViewController, animated:true)
    }
    
    // delete a form of the indicated table view cell;
    // called by FormsMgmtTableViewCell
    internal func doDelete(cell:ContactsMgmtTableViewCell) {
        // set the proposed row as selected
        for cell in self.tableview_contacts_list.visibleCells {
            cell.setSelected(false, animated: false)
        }
        cell.setSelected(true, animated: true)
        
        // get the needed information from the cell
        let indexPath:IndexPath? = self.tableview_contacts_list.indexPath(for:cell)
        if indexPath == nil { return }
        let ccRec:RecContactsCollected = self.mContacts_database_List[indexPath!.row] as! RecContactsCollected
        
        // query if the end-user is really sure about the delete
        AppDelegate.showYesNoDialog(vc:self, title:NSLocalizedString("Delete Confirmation", comment:""), message:NSLocalizedString("Delete Contact?", comment:"")+" [\(ccRec.rCC_Composed_Name)]", buttonYesText:NSLocalizedString("Yes", comment:""), buttonNoText:NSLocalizedString("No", comment:""), callbackAction:1, callbackString1:nil, callbackString2:nil, completion: {(vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
            // callback from the yes/no dialog upon one of the buttons being pressed
            if theResult {
                // answer was Yes; delete the indicated Form
                do {
                    _ = try RecContactsCollected.ccDeleteRec(index:ccRec.rCC_index)
                    self.build_database_list()
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).doDelete", errorStruct: error, extra: String(ccRec.rCC_index))
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
            return  // from callback
        })
    }
    
    // edit a form of the indicated table view cell;
    // called by FormsMgmtTableViewCell
    internal func doNotes(cell:ContactsMgmtTableViewCell) {
        // get the needed information from the cell
        let indexPath:IndexPath? = self.tableview_contacts_list.indexPath(for:cell)
        if indexPath == nil { return }
        let ccRec:RecContactsCollected = self.mContacts_database_List[indexPath!.row] as! RecContactsCollected
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC CollectorNotes") as! PopupEnterCollectorNotesViewController
        newViewController.mCNVCdelegate = self
        newViewController.modalPresentationStyle = .custom
        newViewController.mForCCindex = ccRec.rCC_index
        newViewController.mInitialValue = ccRec.rCC_Collector_Notes
        self.present(newViewController, animated: true, completion: nil)
    }
    
    // edit a form of the indicated table view cell;
    // called by FormsMgmtTableViewCell
    internal func doRating(cell:ContactsMgmtTableViewCell) {
        // get the needed information from the cell
        let indexPath:IndexPath? = self.tableview_contacts_list.indexPath(for:cell)
        if indexPath == nil { return }
        let ccRec:RecContactsCollected = self.mContacts_database_List[indexPath!.row] as! RecContactsCollected
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "VC ChooseRating") as! ChooserRatingViewController
        newViewController.mCRVCdelegate = self
        newViewController.modalPresentationStyle = .custom
        newViewController.mForCCindex = ccRec.rCC_index
        newViewController.mInitialValue = ccRec.rCC_Importance
        self.present(newViewController, animated: true, completion: nil)
    }
    
    // return from the Collector's Notes view
    func completed_CNVC(fromVC:PopupEnterCollectorNotesViewController, wasCancelled:Bool, collectorsNotes:String?) {
        if wasCancelled { return }
        self.changeCCrecord(index:fromVC.mForCCindex, changeNotes:true, theNotes:collectorsNotes, changeRating:false, theRating:nil)
        self.build_database_list()
    }
    
    // return from the Collector's Rating view
    func completed_CRVC(fromVC:ChooserRatingViewController, wasCancelled:Bool, collectorsRatings:String?) {
        if wasCancelled { return }
        self.changeCCrecord(index:fromVC.mForCCindex, changeNotes:false, theNotes:nil, changeRating:true, theRating:collectorsRatings)
        self.build_database_list()
    }
    
    // return from the ContactsReview View Controller
    func completed_CCRVC(wasChanged:Bool) {
        if !wasChanged { return }
        self.build_database_list()
    }
    
    private func changeCCrecord(index:Int64, changeNotes:Bool, theNotes:String?, changeRating:Bool, theRating:String?) {
        // load and change the in-process CC record
        do {
            let ccRec:RecContactsCollected? = try RecContactsCollected.ccGetSpecifiedRecOfIndex(index:index)
            if ccRec == nil {
                AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: APP_ERROR(funcName: "\(self.mCTAG).changeCCrecord", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: nil), buttonText: NSLocalizedString("Okay", comment:""))
                return
            }
            if changeNotes {
                ccRec!.rCC_Collector_Notes = theNotes
            }
            if changeRating {
                ccRec!.rCC_Importance = theRating
            }

            _ = try ccRec!.saveChangesToDB(originalCCRec: ccRec!)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).changeCCrecord", errorStruct: error, extra: String(index))
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
            return
        }
    }
    
    ///////////////////////////////////////////////////
    // tableView handlers for UITableViewDataSource and UITableViewDelegate
    ///////////////////////////////////////////////////
    
    // return the number of rows to display
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.mContacts_database_List.count
    }
    
    // compose each cell's controls
    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell:ContactsMgmtTableViewCell = tableView.dequeueReusableCell(withIdentifier:"TblViewCell Contacts Mgmt", for:indexPath) as! ContactsMgmtTableViewCell
        cell.mTableViewDelegate = self
        let ccRec:RecContactsCollected = self.mContacts_database_List[indexPath.row] as! RecContactsCollected
        if !ccRec.rCC_Composed_Name.isEmpty {
            cell.label_name?.text = ccRec.rCC_Composed_Name
        } else {
            cell.label_name?.text = ccRec.rCC_EnteredValues.replacingOccurrences(of: "\t", with: ",")
        }
        cell.button_rate.backgroundColor = nil
        if ccRec.rCC_Importance != nil {
            if !(ccRec.rCC_Importance!.isEmpty) {
                cell.button_rate.backgroundColor = UIColor.yellow
            }
        }
        cell.button_notes.backgroundColor = nil
        if ccRec.rCC_Collector_Notes != nil {
            if !(ccRec.rCC_Collector_Notes!.isEmpty) {
                cell.button_notes.backgroundColor = UIColor.yellow
            }
        }
        return cell
    }
    
    // when using auto-layout and sizing-classes for a custom UITableViewCell that needs to auto-resize, both the following are needed
    func tableView(_ tableView:UITableView, estimatedHeightForRowAt indexPath:IndexPath) -> CGFloat {
        return 45
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

///////////////////////////////////////////////////
// class definition for ContactsMgmtTableViewCell
///////////////////////////////////////////////////

class ContactsMgmtTableViewCell: UITableViewCell {
    // member variables
    public weak var mTableViewDelegate:ContactsMgmtViewController?
    
    // outlets to screen controls
    @IBOutlet weak var button_notes: UIButton!
    @IBOutlet weak var button_rate: UIButton!
    @IBOutlet weak var label_name: UILabel!
    @IBAction func button_delete_pressed(_ sender: UIButton) {
        if self.mTableViewDelegate != nil {
            self.mTableViewDelegate!.doDelete(cell:self)
        }
    }
    @IBAction func button_notes_pressed(_ sender: UIButton) {
        if self.mTableViewDelegate != nil {
            self.mTableViewDelegate!.doNotes(cell:self)
        }
    }
    @IBAction func button_rate_pressed(_ sender: UIButton) {
        if self.mTableViewDelegate != nil {
            self.mTableViewDelegate!.doRating(cell:self)
        }
    }
    
    // TableViewCell has been prepared and ready to be shown
    override func awakeFromNib() {
        super.awakeFromNib()
        // do any custom changes to the cell's view
    }
}
