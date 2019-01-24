//
//  ContactsReviewViewController.swift
//  eContact Collect
//
//  Created by Dev on 1/22/19.
//

import UIKit
import Eureka

// define the delegate protocol that other portions of the App must use to know when the OEVC saves or cancels
protocol CCRVC_Delegate {
    // return wasSaved=true if saved successfully; wasSaved=false if cancelled
    func completed_CCRVC(wasChanged:Bool)
}

class ContactsReviewViewController: UIViewController {
    // caller pre-set member variables
    internal var mCCRVCdelegate:CCRVC_Delegate?             // delegate callback if saved or cancelled
    public var mReview_CCrec:RecContactsCollected? = nil    // the source Contacts record; is a COPY not a reference
    
    // member variables
    
    // member constants and other static content
    private let mCTAG:String = "VCSCR"
    private weak var mContactsReviewFormVC:ContactsReviewFormViewController? = nil        // pointer to the containerViewController of the Form
    
    // outlets to screen controls
    @IBAction func button_delete_pressed(_ sender: UIBarButtonItem) {
        // query if the end-user is really sure about the delete
        AppDelegate.showYesNoDialog(vc:self, title:NSLocalizedString("Delete Confirmation", comment:""), message:NSLocalizedString("Delete Contact?", comment:""), buttonYesText:NSLocalizedString("Yes", comment:""), buttonNoText:NSLocalizedString("No", comment:""), callbackAction:1, callbackString1:nil, callbackString2:nil, completion: {(vc:UIViewController, theResult:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
            // callback from the yes/no dialog upon one of the buttons being pressed
            if theResult {
                // answer was Yes; delete the collected contact
                do {
                    let _ = try RecContactsCollected.ccDeleteRec(index: self.mReview_CCrec!.rCC_index)
                    if self.mCCRVCdelegate != nil { self.mCCRVCdelegate!.completed_CCRVC(wasChanged: true) }
                    self.navigationController?.popViewController(animated:true)
                } catch {
                    // already error.log and alert
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
            return  // from callback
        })
    }
    @IBAction func button_back_pressed(_ sender: UIBarButtonItem) {
        self.mContactsReviewFormVC!.finalizeChanges()
        if self.mCCRVCdelegate != nil { self.mCCRVCdelegate!.completed_CCRVC(wasChanged: self.mContactsReviewFormVC!.mChangesMade) }
        self.navigationController?.popViewController(animated:true)
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
        
        // locate our children view controllers
        //var orgTitleViewController:OrgTitleViewController? = nil
        self.mContactsReviewFormVC = nil
        for childVC in children {
            //let vc1:OrgTitleViewController? = childVC as? OrgTitleViewController
            let vc2:ContactsReviewFormViewController? = childVC as? ContactsReviewFormViewController
            //if vc1 != nil { orgTitleViewController = vc1 }
            if vc2 != nil { self.mContactsReviewFormVC = vc2 }
        }
        
        // verifications
        assert(self.mContactsReviewFormVC != nil, "\(self.mCTAG).viewDidLoad mContactsReviewFormVC == nil")    // this is a programming error
        assert(self.mReview_CCrec != nil, "\(self.mCTAG).viewDidLoad mReview_CCrec == nil")    // this is a programming error
        //assert(orgTitleViewController != nil, "\(self.mCTAG).viewDidLoad self.orgTitleViewController == nil")    // this is a programming error
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    // remember this will be called upon return from the image chooser dialog
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
    // need this for SendContactsFormViewController() contained view controller
    override func viewDidDisappear(_ animated:Bool) {
        if self.isBeingDismissed || self.isMovingFromParent ||
            (self.navigationController?.isBeingDismissed ?? false) || (self.navigationController?.isMovingFromParent ?? false) {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED AND VC IS DISMISSED \(self)")
            self.mReview_CCrec = nil
            self.mContactsReviewFormVC?.clearVC()
            self.mContactsReviewFormVC = nil
            self.mCCRVCdelegate = nil
        } else {
//debugPrint("\(self.mCTAG).viewDidDisappear STARTED BUT VC is not being dismissed \(self)")
        }
        super.viewDidDisappear(animated)
    }
}

/////////////////////////////////////////////////////////////////////////
// Child FormViewController
/////////////////////////////////////////////////////////////////////////

class ContactsReviewFormViewController: FormViewController {
    // member variables
    private var mFormIsBuilt:Bool = false
    public var mChangesMade:Bool = false
    
    // member constants and other static content
    private let mCTAG:String = "VCSCRF"
    private weak var mContactsReviewVC:ContactsReviewViewController? = nil
    
    // outlets to screen controls
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
    }
    
    // called by the framework after the view has been setup from Storyboard or NIB
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
    }
    
    // called by the framework when the view will re-appear;
    // remember this will be called upon return from the image chooser dialog
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        
        // locate our parent
        self.mContactsReviewVC = (self.parent as! ContactsReviewViewController)
        
        // build the form but without content values to support various PushRows
        self.buildForm()
        
        // set the form's values
        tableView.setEditing(true, animated: false) // this must be done in viewWillAppear() is within a ContainerView and using .Reorder MultivaluedSections
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // finalize any changes made on the form for the collected contact
    public func finalizeChanges() {
        if let notesRow:TextAreaRowExt = form.rowBy(tag: "cc_notes") as? TextAreaRowExt {
            if notesRow.value != self.mContactsReviewVC!.mReview_CCrec!.rCC_Collector_Notes {
                self.mContactsReviewVC!.mReview_CCrec!.rCC_Collector_Notes = notesRow.value
                do {
                    let _ = try self.mContactsReviewVC!.mReview_CCrec!.saveChangesToDB(originalCCRec: self.mContactsReviewVC!.mReview_CCrec!)
                } catch {
                    AppDelegate.showAlertDialog(vc: self, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
            }
        }
    }
    
    // clear out the Form so it will be deinit
    public func clearVC() {
        form.removeAll()
        tableView.reloadData()
        self.mFormIsBuilt = false
        self.mContactsReviewVC = nil
    }
    
    // build the form
    private func buildForm() {
        if self.mFormIsBuilt { return }
        form.removeAll()
        tableView.reloadData()
        
        let section1 = Section()
        form +++ section1
        section1 <<< TextAreaRowExt() {
            $0.tag = "cc_info"
            $0.title = NSLocalizedString("Contact's Information", comment:"")
            $0.value = composeEnteredPairs()
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 20)
            $0.textAreaWidth = .fixed(cellWidth: 300)
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.autocapitalizationType = .words
                cell.textView.font = .systemFont(ofSize: 14.0)
                cell.textView.layer.cornerRadius = 0
                cell.textView.layer.borderColor = UIColor.gray.cgColor
                cell.textView.layer.borderWidth = 1
        }
        
        let optionImgs:[UIImage] = [#imageLiteral(resourceName: "Exclaim"),#imageLiteral(resourceName: "Star Five"),#imageLiteral(resourceName: "Star Three"),#imageLiteral(resourceName: "Star One"),#imageLiteral(resourceName: "Question"),#imageLiteral(resourceName: "Not")]
        var selectedImgs:[UIImage] = []
        if self.mContactsReviewVC!.mReview_CCrec!.rCC_Importance != nil {
            for hasChar in self.mContactsReviewVC!.mReview_CCrec!.rCC_Importance! {
                switch (hasChar) {
                case "!":
                    selectedImgs.append(optionImgs[0])
                    break
                case "5":
                    selectedImgs.append(optionImgs[1])
                    break
                case "3":
                    selectedImgs.append(optionImgs[2])
                    break
                case "1":
                    selectedImgs.append(optionImgs[3])
                    break
                case "?":
                    selectedImgs.append(optionImgs[4])
                    break
                case "X":
                    selectedImgs.append(optionImgs[5])
                    break
                default:
                    break
                }
            }
        }
        let selectedImgsSet = Set(selectedImgs)
        section1 <<< SegmentedRowExt<UIImage>() {
            $0.tag = "cc_importance"
            $0.title = NSLocalizedString("Importance", comment:"")
            $0.allowMultiSelect = true
            $0.options = optionImgs
            $0.value = selectedImgsSet
            }.cellSetup { cell, row in
                cell.segmentedControl!.tintColor = UIColor(hex6: 0x007AFF)
            }.onChange { [weak self] chgRow in
                if chgRow.value != nil {
                    self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance = ""
                    for img in chgRow.value! {
                        switch img {
                        case optionImgs[0]:
                            self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance = self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance! + "!"
                            break
                        case optionImgs[1]:
                            self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance = self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance! + "5"
                            break
                        case optionImgs[2]:
                            self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance = self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance! + "3"
                            break
                        case optionImgs[3]:
                            self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance = self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance! + "1"
                            break
                        case optionImgs[4]:
                            self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance = self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance! + "?"
                            break
                        case optionImgs[5]:
                            self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance = self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance! + "X"
                            break
                        default:
                            break
                        }
                    }
                } else {
                    self!.mContactsReviewVC!.mReview_CCrec!.rCC_Importance = nil
                }
                self!.mChangesMade = true
                do {
                    let _ = try self!.mContactsReviewVC!.mReview_CCrec!.saveChangesToDB(originalCCRec: self!.mContactsReviewVC!.mReview_CCrec!)
                } catch {
                    AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
        }
        
        section1 <<< TextAreaRowExt() {
            $0.tag = "cc_notes"
            $0.title = NSLocalizedString("Notes", comment:"")
            $0.value = self.mContactsReviewVC!.mReview_CCrec!.rCC_Collector_Notes
            $0.textAreaHeight = .fixed(cellHeight: 100)
            $0.textAreaWidth = .fixed(cellWidth: 300)
            }.cellUpdate { cell, row in
                cell.textView.autocapitalizationType = .words
                cell.textView.font = .systemFont(ofSize: 14.0)
                cell.textView.layer.cornerRadius = 0
                cell.textView.layer.borderColor = UIColor.gray.cgColor
                cell.textView.layer.borderWidth = 1
            }.onChange { [weak self] chgRow in
                self!.mChangesMade = true
            }.onCellHighlightChanged { [weak self] cell, row in
                self!.mContactsReviewVC!.mReview_CCrec!.rCC_Collector_Notes = row.value
                do {
                    let _ = try self!.mContactsReviewVC!.mReview_CCrec!.saveChangesToDB(originalCCRec: self!.mContactsReviewVC!.mReview_CCrec!)
                } catch {
                    AppDelegate.showAlertDialog(vc: self!, title: NSLocalizedString("Database Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""))
                }
        }
        
        section1 <<< TextAreaRowExt() {
            $0.tag = "cc_metadata"
            $0.title = NSLocalizedString("Contact's Metadata", comment:"")
            $0.value = composeMetaPairs()
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 20)
            $0.textAreaWidth = .fixed(cellWidth: 300)
            $0.disabled = true
            }.cellUpdate { cell, row in
                cell.textView.autocapitalizationType = .words
                cell.textView.font = .systemFont(ofSize: 14.0)
                cell.textView.layer.cornerRadius = 0
                cell.textView.layer.borderColor = UIColor.gray.cgColor
                cell.textView.layer.borderWidth = 1
        }
        
        self.mFormIsBuilt = true
    }
    
    // parse and show a set of pairs
    private func composeEnteredPairs() -> String {
        let attribComps:[String] = self.mContactsReviewVC!.mReview_CCrec!.rCC_EnteredAttribs.components(separatedBy: "\t")
        let valueComps:[String] = self.mContactsReviewVC!.mReview_CCrec!.rCC_EnteredValues.components(separatedBy: "\t")
        
        var result:String = ""
        var inx:Int = 0
        for attrib:String in attribComps {
            if !attrib.isEmpty {
                if inx > 0 { result = result + "\n" }
                result = result + attrib
                if inx < valueComps.count { result = result + ": " + valueComps[inx] }
                inx = inx + 1
            }
        }

        return result
    }
    
    // parse and show a set of pairs
    private func composeMetaPairs() -> String {
        let attribComps:[String] = self.mContactsReviewVC!.mReview_CCrec!.rCC_MetadataAttribs.components(separatedBy: "\t")
        let valueComps:[String] = self.mContactsReviewVC!.mReview_CCrec!.rCC_MetadataValues.components(separatedBy: "\t")
        
        var result:String = ""
        var inx:Int = 0
        var inx2:Int = 0
        for attrib:String in attribComps {
            if !attrib.isEmpty && inx != self.mContactsReviewVC!.mReview_CCrec!.rCC_Importance_Position && inx != self.mContactsReviewVC!.mReview_CCrec!.rCC_Collector_Notes_Position {
                if inx2 > 0 { result = result + "\n" }
                result = result + attrib
                if inx < valueComps.count { result = result + ": " + valueComps[inx] }
                inx2 = inx2 + 1
            }
            inx = inx + 1
        }
        
        return result
    }
}
