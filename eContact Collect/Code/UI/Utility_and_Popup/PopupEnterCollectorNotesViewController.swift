//
//  PopupEnterCollectorNotesViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/17/18.
//

import UIKit

// define the delegate protocol that other portions of the App must use to know when the choice is made or cancelled
protocol CNVC_Delegate {
    func completed_CNVC(fromVC:PopupEnterCollectorNotesViewController, wasCancelled:Bool, collectorsNotes:String?)
}

class PopupEnterCollectorNotesViewController: UIViewController {
    // caller pre-set member variables
    public var mCNVCdelegate:CNVC_Delegate? = nil   // optional callback

    // member variables
    internal var mForCCindex:Int64 = 0
    internal var mInitialValue:String? = nil
    
    // member constants and other static content
    private let mCTAG:String = "VCUCN"

    // outlets to screen controls
    @IBOutlet weak var textview_notes: UITextView!
    @IBAction func button_done_pressed(_ sender: UIButton) {
        if self.mCNVCdelegate != nil { self.mCNVCdelegate!.completed_CNVC(fromVC:self, wasCancelled:false, collectorsNotes:self.textview_notes.text) }
        dismiss(animated: true, completion: nil)
    }
    @IBAction func button_cancel_pressed(_ sender: UIButton) {
        // cancel button pressed; tell delegate as such, then dismiss and return to the parent view controller
        if self.mCNVCdelegate != nil { self.mCNVCdelegate!.completed_CNVC(fromVC:self, wasCancelled:true, collectorsNotes:nil) }
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
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        if self.mInitialValue != nil {
            textview_notes.text = self.mInitialValue!
        }
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
