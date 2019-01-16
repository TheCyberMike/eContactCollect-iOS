//
//  WizLangNoteViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/29/18.
//

import UIKit

class WizLangNoteViewController: UIViewController {
    // member constants and other static content
    private let mCTAG:String = "VCW1-2"
    
    // outlets to screen controls
    @IBOutlet weak var label_intro: UILabel!
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        self.refresh()
    }
    
    // called when the object instance is being destroyed
    deinit {
//debugPrint("\(mCTAG).deinit STARTED")
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
        var devLang = AppDelegate.mDeviceLangRegion
        if devLang.contains("-") { devLang = devLang.components(separatedBy: "-").first! }
        var appLang = AppDelegate.mAppLangRegion
        if appLang.contains("-") { appLang = appLang.components(separatedBy: "-").first! }
        var string1:String = "translated"
        if devLang == appLang { string1 = "regionalized" }
        let locale = NSLocale(localeIdentifier: AppDelegate.mDeviceLangRegion)
        let langName:String = locale.localizedString(forLanguageCode: AppDelegate.mDeviceLangRegion)!
        let countryName:String = locale.localizedString(forCountryCode: AppDelegate.mDeviceRegion)!
            
        label_intro.text = NSLocalizedString("Unfortunately, eContact Collect has not yet been \(string1) into your preferred language of \(langName) in \(countryName).\n", comment:"")
    }
}
