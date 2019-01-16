//
//  WizUsageNotesViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/6/18.
//

import UIKit

class WizUsageNotesViewController: UIViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW1-5"

    // outlets to screen controls
    @IBAction func button_done_pressed(_ sender: UIBarButtonItem) {
        let savedNickame:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.Collector_Nickname)
        if savedNickame != nil {
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value: 3)
            AppDelegate.mFirstTImeStages = 3
        }
        self.navigationController?.popToRootViewController(animated: true)
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
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
