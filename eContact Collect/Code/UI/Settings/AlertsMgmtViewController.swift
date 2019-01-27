//
//  AlertsMgmtViewController.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import UIKit

class AlertsMgmtViewController: UITableViewController {
    // member variables
    private var mTableView_Array:NSMutableArray = NSMutableArray()
    
    // member constants and other static content
    private let mCTAG:String = "VCSAM"
    private let mAlertDateFormatter = DateFormatter()
    
    // outlets to screen controls
    @IBOutlet var tableview_alerts: UITableView!
    @IBAction func button_delete_all(_ sender: UIBarButtonItem) {
        AppDelegate.showYesNoDialog(vc:self, title:NSLocalizedString("Delete Confirmation", comment:""), message:NSLocalizedString("Delete all alerts?", comment:""), buttonYesText:NSLocalizedString("Yes", comment:""), buttonNoText:NSLocalizedString("No", comment:""), callbackAction:1, callbackString1:nil, callbackString2:nil, completion: {(vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
            // callback from the yes/no dialog upon one of the buttons being pressed
            if theResult {
                // answer was Yes; delete all stored alert records
                do {
                    _ = try RecAlert.alertDeleteAll()
                    self.refreshList()
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).button_delete_all", errorStruct: error, extra: nil)
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
            return  // from callback
        })        
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
        self.mAlertDateFormatter.dateFormat = "dd MMM yyyy HH:mm:ss"
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        self.refreshList()
    }
    
    // called by the framework when the view will disappear from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    override func viewWillDisappear(_ animated:Bool) {
        self.mTableView_Array.removeAllObjects()  // save some memory since this table gets rebuilt and reloaded at viewWillAppear()
        self.tableview_alerts.reloadData()
    }
    
    // called by the framework when the view has disappeared from the UI framework;
    // remember this does NOT necessarily mean the view is being dismissed since viewDidDisappear() will be called if this VC opens another VC;
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
            self.mTableView_Array.removeAllObjects()
            self.tableview_alerts!.reloadData()
            //self.tableview_alerts.delegate = nil
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
    
    // refresh the list of available alerts
    private func refreshList() {
        do {
            let records = try RecAlert.alertGetAllRecs()
            self.mTableView_Array.removeAllObjects()
            for rowObj in records {
                let alertRec = try RecAlert(row:rowObj)
                self.mTableView_Array.add(alertRec)
            }
            self.tableview_alerts!.reloadData()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).refreshList", errorStruct: error, extra: nil)
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
    
    // delete an alert of the indicated table view cell;
    // called by AlertsMgmtTableViewCell
    func doDelete(cell:AlertsMgmtTableViewCell) {
        do {
            _ = try RecAlert.alertDeleteRec(id:Int64(cell.tag))
            self.refreshList()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).doDelete", errorStruct: error, extra: String(cell.tag))
            AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
        }
    }
    
    ///////////////////////////////////////////////////
    // tableView handlers for UITableViewDataSource and UITableViewDelegate
    ///////////////////////////////////////////////////
    
    // return the number of rows to display
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mTableView_Array.count
    }
    
    // compose each cell's controls
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:AlertsMgmtTableViewCell = tableView.dequeueReusableCell(withIdentifier:"TblViewCell Alerts Mgmt", for:indexPath) as! AlertsMgmtTableViewCell
        cell.mTableViewDelegate = self
        let alertRec:RecAlert = self.mTableView_Array[indexPath.row] as! RecAlert
        cell.tag = Int(alertRec.rAlert_DBID)
        let thenLocal:Date = AppDelegate.convertUTCtoThenLocal(timestampUTC:alertRec.rAlert_Timestamp_MS_UTC)
        var text = "#\(alertRec.rAlert_DBID) \(self.mAlertDateFormatter.string(from: thenLocal))"
        text = "\(text) \(NSLocalizedString("TZO", comment:"TZO is an abbreviation for TimeZone Offset"))=\(alertRec.rAlert_Timezone_MS_UTC_Offset/3600000)"
        text = "\(text): \(alertRec.rAlert_Message)"
        cell.label_message?.text =  text
        return cell
    }

    // when using auto-layout and sizing-classes for a custom UITableViewCell that needs to auto-resize, both the following are needed
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//debugPrint("\(self.mCTAG).tableView.estimatedHeightForRowAtIndexPath STARTED")
        return 45
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//debugPrint("\(self.mCTAG).tableView.heightForRowAtIndexPath STARTED")
        return UITableView.automaticDimension
    }
}

///////////////////////////////////////////////////
// class definition for AlertsMgmtTableViewCell
///////////////////////////////////////////////////

class AlertsMgmtTableViewCell: UITableViewCell {
    // member variables
    public weak var mTableViewDelegate:AlertsMgmtViewController? = nil
    
    // outlets to screen controls
    @IBOutlet weak var label_message: UILabel!
    @IBAction func button_delete(_ sender: UIButton) {
        self.mTableViewDelegate?.doDelete(cell: self)
    }
    
    // TableViewCell has been prepared and ready to be shown
    override func awakeFromNib() {
        super.awakeFromNib()
        // do any custom changes to the cell's view
    }
}
