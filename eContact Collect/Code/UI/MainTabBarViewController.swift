//
//  MainTabBarViewController.swift
//  eContact Collect
//
//  Created by Yo on 10/11/18.
//

import UIKit

class MainTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    // member constants and other static content
    private let mCTAG:String = "TBCM"
    
    // called by the framework after the view has been setup from Storyboard or NIB, but NOT called during a fully programmatic startup;
    // only children (no parents) will be available but not yet initialized (not yet viewDidLoad)
    override func viewDidLoad() {
//debugPrint("\(self.mCTAG).viewDidLoad STARTED")
        super.viewDidLoad()
        self.delegate = self
        
        if AppDelegate.mFirstTImeStages >= 0 {
            // first time the App has ever been run; force the entire wizard sequence to be utilized
            tabBar.items![0].isEnabled = false
            tabBar.items![1].isEnabled = false
            tabBar.items![2].isEnabled = true
            selectedIndex = 2
        } else {
            // standard startup - wizards are blocked from direct entry
            tabBar.items![0].isEnabled = true
            tabBar.items![1].isEnabled = true
            tabBar.items![2].isEnabled = false
            selectedIndex = 0
        }
    }
    
    // a new tab was selected
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        switch tabBarIndex {
        case 0:
            // Entry tab was chosen, pop to root for the Settings and Wizard navigation controllers
            if self.viewControllers != nil {
                if self.viewControllers!.count >= 2 {
                    let nc2:UINavigationController = self.viewControllers![1] as! UINavigationController
                    nc2.popToRootViewController(animated: false)
                }
                if self.viewControllers!.count >= 3 {
                    let nc3:UINavigationController = self.viewControllers![2] as! UINavigationController
                    nc3.popToRootViewController(animated: false)
                }
            }
            break
        case 1:
            // Settings tab was chosen; determine whether to bypass the PIN root
            let savedPIN:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.APP_Pin)
            if (savedPIN ?? "").isEmpty {
                // there is no PIN
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "VC AdminMenu")
                let nc2:UINavigationController = viewController as! UINavigationController
                nc2.setViewControllers([vc], animated: false)
            } else {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "VC AdminPINEntry")
                let nc2:UINavigationController = viewController as! UINavigationController
                nc2.setViewControllers([vc], animated: false)
            }
            break
        case 2:
            // do nothing for now
            break
        default:
            break
        }
        if AppDelegate.mFirstTImeStages >= 0 {
            // first time the App has ever been run; likely caused by a Factory Reset if discovered here; force the entire wizard sequence to be utilized
            tabBar.items![0].isEnabled = false
            tabBar.items![1].isEnabled = false
            tabBar.items![2].isEnabled = true
            selectedIndex = 2
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // wizard tab is indicating its done with first time setup and AppDelegate.mFirstTIme is now false
    public func exitWizardFirstTime() {
        tabBar.items![0].isEnabled = true
        tabBar.items![1].isEnabled = true
        tabBar.items![2].isEnabled = false
        selectedIndex = 0
    }
}
