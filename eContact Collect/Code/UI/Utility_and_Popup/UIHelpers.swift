//
//  UIHelpers.swift
//  eContact Collect
//
//  Created by Dev on 12/26/18.
//

import UIKit

public class UIHelpers {
    // perform a standard import query and post results of the import;
    // is invoked by various ViewControllers either via a menu item or via an iOS Notification
    public static func importConfigFile(fromURL:URL, usingVC:UIViewController, fromExternal:Bool=false, finalDialogCompletion:((_ vc:UIViewController, _ url:URL, _ theChoice:Bool, _ theResult:Bool) -> Void)?=nil) {
    
        var messageStr:String = NSLocalizedString("Import Configuration from file:\n", comment:"") + "\(fromURL.path)?" +
            NSLocalizedString("\n\nWARNING: if you have this Organization or Form already in your database, it will be replaced with the new configuration in this file; any customization you may have done will be lost and need to be re-entered.", comment:"")
        if fromExternal { messageStr = messageStr + NSLocalizedString(" You can press No then invoke the import later in the Settings-> Preferences menu.", comment:"")}
        
        AppDelegate.showYesNoDialog(vc: usingVC, title: NSLocalizedString("Import Confirmation", comment:""), message: messageStr, buttonYesText: NSLocalizedString("Yes", comment:""), buttonNoText: NSLocalizedString("No", comment:""), callbackAction: 1, callbackString1: fromURL.path, callbackString2: nil, completion: {(vc:UIViewController, theChoice:Bool, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                // callback from the yes/no dialog upon one of the buttons being pressed
                assert(!(callbackString1 ?? "").isEmpty, "callbackString1 == nul or isEmpty")
                if theChoice {
                    // answer was Yes; import the indicated file
                    do {
                        let result:DatabaseHandler.ImportOrgOrForm_Result = try DatabaseHandler.importOrgOrForm(fromFileAtPath: callbackString1!)
                        if result.wasForm {
                            // Form-only import was performed
                            AppDelegate.showAlertDialog(vc: usingVC, title: NSLocalizedString("Success", comment:""), message: NSLocalizedString("The Form configuration file was successfully imported.", comment:""), buttonText: NSLocalizedString("Okay", comment:""), completion: { ()-> Void in
                                    if finalDialogCompletion != nil { finalDialogCompletion!(usingVC, fromURL, true, true )
                                    //return // from the showAlertDialog callback
                                }
                            })
                            if AppDelegate.mEntryFormProvisioner == nil {
                                // do nothing if the mainline EFP has not been established yet
                            } else if AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File == result.wasOrgShortName &&
                                AppDelegate.mEntryFormProvisioner!.mFormRec!.rForm_Code_For_SV_File == result.wasFormShortName {
                                // the shown Org's Form is the same as the imported Org's Form; need to inform of the shown Form's changes throughout the App
                                (UIApplication.shared.delegate as! AppDelegate).setCurrentForm(toFormShortName: result.wasFormShortName, withOrgShortName: result.wasOrgShortName)
                            }
                        } else {
                            // entire Org and all its Forms inport was performed
                            AppDelegate.showAlertDialog(vc: usingVC, title: NSLocalizedString("Success", comment:""), message: NSLocalizedString("The Organization configuration file was successfully imported.", comment:""), buttonText: NSLocalizedString("Okay", comment:""), completion: { ()-> Void in
                                    if finalDialogCompletion != nil { finalDialogCompletion!(usingVC, fromURL, true, true )
                                    //return // from the showAlertDialog callback
                                }
                            })
                            if AppDelegate.mEntryFormProvisioner == nil {
                                // this will trigger an auto-create of the mainline EFP and an auto-load of the first Org in the DB
                                (UIApplication.shared.delegate as! AppDelegate).setCurrentOrg(toOrgRec: nil)
                            } else if AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File == result.wasOrgShortName {
                                // the shown Org is the one just imported; need to inform of the changed shown Org and Forms throughout the App;
                                // if the currently showing Form is no longer present, the first or only Form of the Org will auto-show
                                (UIApplication.shared.delegate as! AppDelegate).setCurrentOrg(toOrgShortName: result.wasOrgShortName)
                            }
                        }
                    } catch let userError as USER_ERROR {
                        // user errors are never posted to the error.log
                        AppDelegate.showAlertDialog(vc: usingVC, title: NSLocalizedString("Import Error", comment:""), errorStruct: userError, buttonText: NSLocalizedString("Okay", comment:""), completion: { ()-> Void in
                            if finalDialogCompletion != nil { finalDialogCompletion!(usingVC, fromURL, true, false ) }
                        })
                    } catch {
                        AppDelegate.postToErrorLogAndAlert(method: "UIHelpers.importConfigFile", errorStruct: error, extra: callbackString1!)
                        AppDelegate.showAlertDialog(vc: usingVC, title: NSLocalizedString("Import Error", comment:""), errorStruct: error, buttonText: NSLocalizedString("Okay", comment:""), completion: { ()-> Void in
                                if finalDialogCompletion != nil { finalDialogCompletion!(usingVC, fromURL, true, false ) }
                        })
                    }
                } else {
                    // end-user chose NOT to import
                    if finalDialogCompletion != nil { finalDialogCompletion!(usingVC, fromURL, false, false ) }
                }
                //return  // from the showYesNoDialog callback
        })
    }
}
