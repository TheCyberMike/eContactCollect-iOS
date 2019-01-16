//
//  WizFirstTimeViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/29/18.
//

import UIKit

class WizFirstTimeViewController: UIViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW1-1"
    
    // outlets to screen controls
    @IBAction func button_next_pressed(_ sender: UIBarButtonItem) {
        if AppDelegate.mDeviceLangRegion != AppDelegate.mAppLangRegion {
            let storyboard = UIStoryboard(name:"Main", bundle:nil)
            let nextVC = storyboard.instantiateViewController(withIdentifier:"VC WizLangNote")
            self.navigationController?.pushViewController(nextVC, animated:true)
        } else {
            let storyboard = UIStoryboard(name:"Main", bundle:nil)
            let nextVC = storyboard.instantiateViewController(withIdentifier:"VC WizDefinePIN")
            self.navigationController?.pushViewController(nextVC, animated:true)
        }
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
        self.refresh()
    }
    
    // called by the framework when the view will *re-appear* (first time, from popovers, etc)
    // parent and all children are now available
    override func viewWillAppear(_ animated:Bool) {
//debugPrint("\(self.mCTAG).viewWillAppear STARTED")
        super.viewWillAppear(animated)
        self.refresh()
    }
    
    // called by the framework when memory needs to be freed
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // insert any existing PIN
    private func refresh() {
    }
}
