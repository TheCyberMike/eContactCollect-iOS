//
//  AppDelegate.swift
//  eContact Collect
//
//  Created by Yo on 9/21/18.
//

import UIKit
import SQLite
import Eureka
import StoreKit
import OAuthSwift

// global exception handler (cannot catch Swift runtime errors)
func globalExceptionHandler(exception:NSException) {
    print("globalExceptionHandler =====!!=====Unhandled Abort Captured=====!!=====")
    AppDelegate.postExceptionToErrorLogAndAlert(method:"globalExceptionHandler", exception:exception, extra:"*UNHANDLED*")
}

// used for auto-tabbing when not using Eureka Forms
extension UIView {
    // go thru this view's subviews and look for the current first responder
    func findFirstResponder() -> UIView? {
        // if self is the first responder, return it (needed for recursion below)
        if isFirstResponder { return self }
        // check all the immediate child views
        for v in subviews {
            if v.isFirstResponder == true { return v }
            // check the subview of this child view
            if v.subviews.count > 0 {
                if let fr = v.findFirstResponder() { return fr }
            }
        }
        // no first responder
        return nil
    }
}
extension UIApplication.OpenURLOptionsKey {
    public static let url:UIApplication.OpenURLOptionsKey = UIApplication.OpenURLOptionsKey(rawValue: "url")
}
extension UIFont {
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    public func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    public func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
    
    public func boldItalic() -> UIFont {
        return withTraits(traits: [.traitBold, .traitItalic])
    }
    
    private func withTraits(traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        if descriptor == nil { return self }
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }
}
class ResizableButton: UIButton {
    override var intrinsicContentSize: CGSize {
        let labelSize = titleLabel?.sizeThatFits(CGSize(width: frame.width, height: .greatestFiniteMagnitude)) ?? .zero
        let desiredButtonSize = CGSize(width: labelSize.width + titleEdgeInsets.left + titleEdgeInsets.right, height: labelSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
        
        return desiredButtonSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.titleLabel?.preferredMaxLayoutWidth = self.frame.width
    }
}

// keys for preferences accessed via AppDelegate's methods;
// NEVER change these keys in future releases unless willing to do an upgrade process for these keys

public struct PreferencesKeys {
    enum Bools: String {
#if TESTING
        case APP_Rating_Needed = "TESTapp_rating_needed"
        case APP_Rating_Done = "TESTapp_rating_done"
#else
        case APP_Rating_Needed = "app_rating_needed"            // perform the rating reminder (part of ask-for-a-rating)
        case APP_Rating_Done = "app_rating_done"                // rating was performed; do not ask again (part of ask-for-a-rating)
#endif
    }
    enum Strings: String {
#if TESTING
        case APP_Pin = "TESTapp_PIN"
        case Collector_Nickname = "TESTcollector_Nickname"
        case APP_LastOrganization = "TESTapp_LastOrganization"
        case APP_LastForm = "TESTapp_LastForm"
        case APP_Rating_LastDate = "TESTapp_rating_lastDate"
        case EmailVia_Stored_Named = "TESTemailVia_stored_named_"
        case EmailVia_Default_Name = "TESTemailVia_default_name"
#else
        case APP_Pin = "app_PIN"                                // PIN needed to get into the Settings; may be nil or empty
        case Collector_Nickname = "collector_Nickname"          // Nickname of the app's end-user; will be inserted into all collected records
        case APP_LastOrganization = "app_LastOrganization"      // Org short name that was last currently active
        case APP_LastForm = "app_LastForm"                      // Form short name that was last currently active
        case APP_Rating_LastDate = "app_rating_lastDate"        // last date-of-use (part of ask-for-a-rating); YYYYMMDD
        case EmailVia_Stored_Named = "emailVia_stored_named_"   // storage of one or more EmailVia as set by the Collector
        case EmailVia_Default_Name = "emailVia_default_name"    // the name of the default EmailVia as chosen by the Collector
#endif
    }
    enum Ints: String {
#if TESTING
        case APP_FirstTime = "TESTapp_firstTimeStages"
        case APP_Rating_DaysCountdown = "TESTapp_rating_daysCountdown"
        case APP_Handler_Database_FirstTime_Done = "TESTapp_handler_database_firsttime_done"
        case APP_Handler_Field_FirstTime_Done = "TESTapp_handler_field_firsttime_done"
        case APP_Handler_SVFiles_FirstTime_Done = "TESTapp_handler_svfiles_firsttime_done"
        case APP_Handler_Email_FirstTime_Done = "TESTapp_handler_email_firsttime_done"

#else
        case APP_FirstTime = "app_firstTimeStages"                  // nil=first time stage 1 needed; -1=first time fully completed; 1,2... currently in the indicated first time stage
        case APP_Rating_DaysCountdown = "app_rating_daysCountdown"  // countdown of unique days of use (part of ask-for-a-rating)
        case APP_Handler_Database_FirstTime_Done = "app_handler_database_firsttime_done"
        case APP_Handler_Field_FirstTime_Done = "app_handler_field_firsttime_done"
        case APP_Handler_SVFiles_FirstTime_Done = "app_handler_svfiles_firsttime_done"
        case APP_Handler_Email_FirstTime_Done = "app_handler_email_firsttime_done"

#endif
    }
}

// App internal Notification definitions
extension Notification.Name {
    // global notifications
    static let APP_MainEFPaddedRemoved = Notification.Name("APP_MainEFPaddedRemoved")
    static let APP_FileRequestedToOpen = Notification.Name("APP_FileRequestedToOpen")
    static let APP_EmailCompleted = Notification.Name("APP_EmailCompleted")
    // per-object notifications
    static let APP_EFP_OrgFormChange = Notification.Name("APP_EFP_OrgFormChange")
    static let APP_EFP_LangRegionChanged = Notification.Name("APP_EFP_LangRegionChanged")
}

// Handler status enumerator
public func <<T: RawRepresentable>(a: T, b: T) -> Bool where T.RawValue: Comparable {
    return a.rawValue < b.rawValue
}
public enum HandlerStatusStates: Int, Comparable {
    case Unknown = 0, Missing = 1, Errors = 2, Invalid = 3, Obsolete = 4, Valid = 5
}

// global pointer to the AppDelegate which is useful for debugging
internal var gAppDelegate:AppDelegate? = nil

// this is the non-GUI-based application mainline
@UIApplicationMain
internal class AppDelegate: UIResponder, UIApplicationDelegate {
    // member variables
    var window:UIWindow?
    
#if TESTING
    public static var mTestingMode:Bool = false                 // only available in testing builds of the product
#endif

    // member constants and other static content
    internal static let mCTAG:String = "AppD"
    public static let mDeveloperEmailAddress:String = "theCyberMike@yahoo.com"
    public static let mKeychainThrownDomain:String = NSLocalizedString("Secure Storage", comment:"")
    public static var mFirstTImeStages:Int = 0      // -1=first time fully done; 1,2,... is the first time stage presently in; 0=stage 1 is needed
    public static var mEntryFormProvisioner:EntryFormProvisioner? = nil // common pointer to the EFP for the mainline EntryViewController

    // basic states of the iOS Device and App regions
    @nonobjc private static var mPrefsApp:UserDefaults = UserDefaults.standard     // standard non-shared local defaults for the App
    @nonobjc public static var mDocsApp:String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    @nonobjc public static var mLibApp:String = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
    @nonobjc public static var mAppLangRegion:String = "en"         // language-Region that iOS is running the App in
    @nonobjc public static var mDeviceLangRegion:String = "en"      // language-Region that iOS is running the App in
    @nonobjc public static var mDeviceLanguage:String = "en"        // device's default language
    @nonobjc public static var mDeviceRegion:String = "US"          // device's default region
    @nonobjc public static var mDeviceTimezone:String = ""          // device's default timezome string
    @nonobjc public static var mDeviceTimezoneOffsetMS:Int64 = 0    // device's default timezone offset in milliseconds
    public static let mAcceptableNameChars:NSCharacterSet = NSCharacterSet(charactersIn:"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 _.+-")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // called with the App is launched (first-time or after a termination); it will only be called once even if the App is paused
//debugPrint("\(AppDelegate.mCTAG).didFinishLaunchingWithOptions STARTED")
        gAppDelegate = self
        
        // activate the global unhandled exception handler in this main thread
        //NSSetUncaughtExceptionHandler(globalExceptionHandler)
        
        // initialize everything that should be done even when doing Unit Testing
        self.initialize()
        
//debugPrint("\(AppDelegate.mCTAG).didFinishLaunchingWithOptions COMPLETED")
        return true
    }
    
    // to assist the Unit and UI Testing framework, place most initializations in here unless it should not be done for testing
    internal func initialize() {
#if TESTING
debugPrint("\(AppDelegate.mCTAG).initialize STARTED IN TESTING MODE!!")
        AppDelegate.mTestingMode = true                 // only available in testing builds of the product
        AppDelegate.mDocsApp = NSTemporaryDirectory()
        AppDelegate.mLibApp = NSTemporaryDirectory()
#else
debugPrint("\(AppDelegate.mCTAG).initialize STARTED")
#endif
        
        // this App supports multi-languages even aside from automatic Localization
        // get device locale information from iOS; iOS allows setting both preferred Languagess w/Region, and a separate Region
        AppDelegate.mDeviceLanguage = AppDelegate.getLangOnly(fromLangRegion: NSLocale.preferredLanguages[0])
        let value2:String? = (Locale.current as NSLocale).object(forKey: .countryCode) as? String
        if value2 != nil { AppDelegate.mDeviceRegion = value2! }
        AppDelegate.mDeviceLangRegion = NSLocale.preferredLanguages[0]
        if AppDelegate.mDeviceLangRegion == "en-US" { AppDelegate.mDeviceLangRegion = "en" }
        
        // get App's active locale from the Bundle; really want the localization directory in-use
        let filePath:String? = Bundle.main.path(forResource: "FieldLocales", ofType: "json")
        AppDelegate.mAppLangRegion = "en"
        if filePath != nil {
            let pathComponents = filePath!.components(separatedBy: "/")
            let langFolder = pathComponents[pathComponents.count - 2]
            AppDelegate.mAppLangRegion = langFolder.components(separatedBy: ".")[0]
        } else {
            AppDelegate.mAppLangRegion = Bundle.main.preferredLocalizations.first!
            if AppDelegate.mAppLangRegion.contains("_") {
                AppDelegate.mAppLangRegion = AppDelegate.mAppLangRegion.replacingOccurrences(of: "_", with: "-")
            }
            if AppDelegate.mAppLangRegion == "en-US" { AppDelegate.mAppLangRegion = "en" }
        }
        
        // get timezone information from iOS
        NSTimeZone.resetSystemTimeZone()
        let tz = NSTimeZone.system
        AppDelegate.mDeviceTimezoneOffsetMS = Int64(tz.secondsFromGMT(for: Date())) * 1000     // ?? if App is left running then need to refresh this every 24 hours to reflect DST
        AppDelegate.mDeviceTimezone = tz.identifier
        
debugPrint("\(AppDelegate.mCTAG).initialize Localization: iOS Language \(AppDelegate.mDeviceLanguage), iOS Region \(AppDelegate.mDeviceRegion), iOS LangRegion \(AppDelegate.mDeviceLangRegion), App Language-Region \(AppDelegate.mAppLangRegion), TimezoneOffset_min: \(AppDelegate.mDeviceTimezoneOffsetMS / 60000) (\(AppDelegate.mDeviceTimezone))")
        
        // detect first time the App has run
        if !AppDelegate.doesPreferenceIntExist(prefKey: PreferencesKeys.Ints.APP_FirstTime) { AppDelegate.mFirstTImeStages = 0 }
        else { AppDelegate.mFirstTImeStages = AppDelegate.getPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime) }
        if AppDelegate.mFirstTImeStages == 0 {
            // first time the App has been run; remember that first time setups are not yet completed
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime, value:0)
        }
        
        // startup any App's Handlers and Coordinators
        // errors are logged to error.log, and a user message stored within; errors will be reported to the end-user when the UI launches
        let _ = DatabaseHandler.shared.initialize(method: "\(AppDelegate.mCTAG).initialize")
        let _ = FieldHandler.shared.initialize(method: "\(AppDelegate.mCTAG).initialize")
        let _ = SVFilesHandler.shared.initialize(method: "\(AppDelegate.mCTAG).initialize")
        let _ = EmailHandler.shared.initialize(method: "\(AppDelegate.mCTAG).initialize")

        // allow handlers to perform any additional first-time-of-use initializations that a particular handler may require;
        // their interrnal logic prevents repeated first-time setups, but also allow later versions of the app to retro-perform missed first-time setups
        DatabaseHandler.shared.firstTimeSetup(method: "\(AppDelegate.mCTAG).initialize")
        FieldHandler.shared.firstTimeSetup(method: "\(AppDelegate.mCTAG).initialize")
        SVFilesHandler.shared.firstTimeSetup(method: "\(AppDelegate.mCTAG).initialize")
        EmailHandler.shared.firstTimeSetup(method: "\(AppDelegate.mCTAG).initialize")
        
        // prepare the mainline EFP if possible; for first time setup this will not be possible
        if AppDelegate.mFirstTImeStages < 0 { AppDelegate.setupMainlineEFP() }
        
        // check whether the rating reminder interval should be incremented
        if AppDelegate.mFirstTImeStages == 0 {
            AppDelegate.ratingReminderIncrement(reason: .FirstTime)
            AppDelegate.noticeToErrorLogAndAlert(method: "\(AppDelegate.mCTAG).initialize", during: nil, notice: "First-Time Log Entry", extra: nil, noAlert: true)

        } else { AppDelegate.ratingReminderIncrement(reason: .AppStart) }
//debugPrint("\(AppDelegate.mCTAG).initialize COMPLETED")
    }
    
    // shutdown prior to termination; also called in Unit and UI Testing
    internal func shutdown() {
        SVFilesHandler.shared.shutdown()
        FieldHandler.shared.shutdown()
        DatabaseHandler.shared.shutdown()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//debugPrint("\(AppDelegate.mCTAG).applicationWillResignActive STARTED")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//debugPrint("\(AppDelegate.mCTAG).applicationDidEnterBackground STARTED")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.  *NOT* called during Application launch.
//debugPrint("\(AppDelegate.mCTAG).applicationWillEnterForeground STARTED")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.  Also called upon Application launch.
//debugPrint("\(AppDelegate.mCTAG).applicationDidBecomeActive STARTED")
        
        // check whether the rating reminder interval should be incremented
        AppDelegate.ratingReminderIncrement(reason: .AppRestart)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground.
        // This may not get called during many App terminations
//debugPrint("\(AppDelegate.mCTAG).applicationWillTerminate STARTED")
        self.shutdown()
    }

    // provide a convenient means to access the AppDelegate instanciated object
    static func shared() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    ///////////////////////////////////////////////////////////////////
    // Application-specific
    ///////////////////////////////////////////////////////////////////

    // called when the end-user has requested that one of our files be opened; return true if the request was successfully handled
    // end-user has indicated that it wants one of our app's files opened;
    // presently, only the "eContactsCollectConfig" file extension of mimetype "application/json" is defined as openable
    // first three lines need to be:
    //      "$schema":"http://json-schema.org/draft-04/schema#"
    //      "apiVersion":"1.0"
    //      "method":"eContactCollect.db.org.export" or "method":"eContactCollect.db.form.export"
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//debugPrint("\(AppDelegate.mCTAG).openURL STARTED PATH=\(url.absoluteString)")
        if url.scheme == "file" {
            // handle a file open
//debugPrint("\(AppDelegate.mCTAG).openURL FILE STARTED")
            let filename = url.lastPathComponent
            let extensionStr = filename.components(separatedBy: ".").last
            if extensionStr != "eContactCollectConfig" { return false } // no

            // must we copy it to open it?
            let canOpenInPlace = options[UIApplication.OpenURLOptionsKey.openInPlace] as? Bool
            var workingURL = url
            if canOpenInPlace == nil || canOpenInPlace == false {
                // yes must copy it first
                workingURL = URL(fileURLWithPath: AppDelegate.mDocsApp, isDirectory: true).appendingPathComponent(url.lastPathComponent)
                do {
                    try FileManager.default.copyItem(at: url, to: workingURL)
                } catch {
                    AppDelegate.postToErrorLogAndAlert(method: "\(AppDelegate.mCTAG).application.open url", during:"FileManager.default.copyItem", errorStruct: error, extra: "\(url.path) to \(workingURL.path)")
                    // cannot show the error to the end-user at this time
                    return false
                }
            }
            
            // open it and make sure its our file
            var valid:Bool = false
            let stream = InputStream(fileAtPath: workingURL.path)
            if stream == nil { return false }
            stream!.open()
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 257)    // must be one higher than the read length
            buffer.initialize(to: 0)
            let qty = stream!.read(buffer, maxLength: 256)
            stream!.close()
            if qty > 0 {
                let bufferString = String(cString: buffer)
                if bufferString.contains("\"method\":\"eContactCollect.db.org.export\"") ||
                   bufferString.contains("\"method\":\"eContactCollect.db.form.export\"") {
                    valid = true
                }
            }
            buffer.deallocate()
            if !valid { return false }
            
            // all seems okay; push the file open request into the message queue so the mainline UI can handle it
//debugPrint("\(AppDelegate.mCTAG).openURL VALID SENDING NOTIFICATION")
            var requestInfo = options
            requestInfo[UIApplication.OpenURLOptionsKey.url] = workingURL
            NotificationCenter.default.post(name: .APP_FileRequestedToOpen, object: nil, userInfo: requestInfo)
            return true
            
        } else if url.path.starts(with: "/\(EmailHandler.mOAuthCallbackPath)") {
            // handle an OAuth response
            if (options[.sourceApplication] as? String == "com.apple.SafariViewService") {
//debugPrint("\(AppDelegate.mCTAG).openURL OAUTH2 STARTED")
                OAuthSwift.handle(url: url)
                return true
            }
        }
        return false
    }
    
    // setup the mainline's EFP
    public static func setupMainlineEFP() {
        var lastOrgRec:RecOrganizationDefs? = nil
        var lastFormRec:RecOrgFormDefs? = nil
        do {
            let lastOrg:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization)
            if lastOrg != nil {
                lastOrgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: lastOrg!)
                let lastForm:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm)
                if lastForm != nil {
                    lastFormRec = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName:lastForm!, forOrgShortName:lastOrg!)
                    if lastOrgRec != nil && lastFormRec != nil {
                        if AppDelegate.mEntryFormProvisioner != nil { AppDelegate.mEntryFormProvisioner!.clear() }
                        AppDelegate.mEntryFormProvisioner = EntryFormProvisioner(forOrgRec: lastOrgRec!, forFormRec: lastFormRec!)
                    }
                }
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).setupMainlineEFP", errorStruct: error, extra: nil)
            // do not show an error to the end-user
        }
        
        // successful in getting the last-used Org and Form?
        if AppDelegate.mEntryFormProvisioner == nil {
            // no; what was found?
            do {
                
                if lastOrgRec != nil {
                    // a last Org record was found, but not its last form; attempt to get any other of the Org's forms
                    let records:AnySequence<SQLite.Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: lastOrgRec!.rOrg_Code_For_SV_File)
                    for rowObj in records {
                        lastFormRec = try RecOrgFormDefs(row:rowObj)
                        break
                    }
                    if lastFormRec != nil {
                        if AppDelegate.mEntryFormProvisioner != nil { AppDelegate.mEntryFormProvisioner!.clear() }
                        AppDelegate.mEntryFormProvisioner = EntryFormProvisioner(forOrgRec: lastOrgRec!, forFormRec: lastFormRec!)
                    }
                }
                // found a pair yet?
                if AppDelegate.mEntryFormProvisioner == nil {
                    // no, last resort: get the first available Org record that has at least one Form record
                    lastOrgRec = nil
                    lastFormRec = nil
                    let records:AnySequence<SQLite.Row> = try RecOrganizationDefs.orgGetAllRecs()
                    for rowObj in records {
                        lastOrgRec = try RecOrganizationDefs(row:rowObj)
                        let records:AnySequence<SQLite.Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: lastOrgRec!.rOrg_Code_For_SV_File)
                        for rowObj in records {
                            lastFormRec = try RecOrgFormDefs(row:rowObj)
                            break
                        }
                        if lastFormRec != nil { break }
                    }
                    if lastOrgRec != nil && lastFormRec != nil {
                        if AppDelegate.mEntryFormProvisioner != nil { AppDelegate.mEntryFormProvisioner!.clear() }
                        AppDelegate.mEntryFormProvisioner = EntryFormProvisioner(forOrgRec: lastOrgRec!, forFormRec: lastFormRec!)
                    }
                }
            } catch {
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).setupMainlineEFP", errorStruct: error, extra: nil)
                // do not show an error to the end-user
            }
        }
    }
    
    // check if the Org record should be remembered
    public func checkCurrentOrg(withOrgRec:RecOrganizationDefs) {
        if AppDelegate.mEntryFormProvisioner == nil {
            self.setCurrentOrg(toOrgRec: withOrgRec)
        } else if AppDelegate.mEntryFormProvisioner!.mOrgRec.isSameNamed(otherRec: withOrgRec) {
            self.setCurrentOrg(toOrgRec: withOrgRec)
        }
    }
    
    // check if the current Org record needs be deleted and a new one found
    public func checkDeletionCurrentOrg(withOrgRecShortName:String) {
        if AppDelegate.mEntryFormProvisioner != nil {
            if AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File == withOrgRecShortName {
                self.setCurrentOrg(toOrgRec: nil)
            }
        }
    }
    
    // set and remember the named Organization
    public func setCurrentOrg(toOrgShortName:String) {
        do {
            let orgRec:RecOrganizationDefs? = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: toOrgShortName)
            if orgRec != nil {
                self.setCurrentOrg(toOrgRec: orgRec)
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(AppDelegate.mCTAG).setCurrentOrg(toOrgShortName", errorStruct: error, extra: nil)
            // do not show an error to the end-user
        }
    }
    
    // set and remember the specified Organization or one that is found in the database
    public func setCurrentOrg(toOrgRec:RecOrganizationDefs?) {
//debugPrint("\(AppDelegate.mCTAG).setCurrentOrg STARTED")
        var lastOrgRec:RecOrganizationDefs? = nil
        var lastFormRec:RecOrgFormDefs? = nil
        do {
            if toOrgRec == nil {
                // Load the first (or only) Org that has at least one Form
                let records:AnySequence<SQLite.Row> = try RecOrganizationDefs.orgGetAllRecs()
                for rowObj in records {
                    lastOrgRec = try RecOrganizationDefs(row:rowObj)
                    let records:AnySequence<SQLite.Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: lastOrgRec!.rOrg_Code_For_SV_File)
                    for rowObj in records {
                        lastFormRec = try RecOrgFormDefs(row:rowObj)
                        break
                    }
                    if lastFormRec != nil { break }
                }
            } else {
                lastOrgRec = toOrgRec
                if (AppDelegate.mEntryFormProvisioner?.mFormRec?.isPartOfOrg(orgRec: lastOrgRec!) ?? false) == true {
                    // have an Org and our current Form is part of that Org
                    lastFormRec = AppDelegate.mEntryFormProvisioner!.mFormRec!
                } else {
                    // have an Org but our current Form is incorrect or missing, so find its first or only Form
                    let records:AnySequence<SQLite.Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: lastOrgRec!.rOrg_Code_For_SV_File)
                    for rowObj in records {
                        lastFormRec = try RecOrgFormDefs(row:rowObj)
                        break
                    }
                }
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(AppDelegate.mCTAG).setCurrentOrg(toOrgRec", errorStruct: error, extra: nil)
            // do not show an error to the end-user
        }
        
        // examine what was found in the database
        if lastOrgRec == nil {
            // there are no Org records in the database; eliminate the Main EFP and let every VC know
            self.resetCurrents()
        } else {
            // an Org record was found
            if (lastFormRec?.isPartOfOrg(orgRec: lastOrgRec!) ?? false) == true {
                // yes both were found and are consistent with each other; create or alter the mainline EntryFormProvisioner
                if AppDelegate.mEntryFormProvisioner == nil {
                    // create the new mainline EntryFormProvisioner; must also send out a global notification this its been late-created
                    AppDelegate.mEntryFormProvisioner = EntryFormProvisioner(forOrgRec: lastOrgRec!, forFormRec: lastFormRec!)
                    NotificationCenter.default.post(name: .APP_MainEFPaddedRemoved, object: nil)
                } else {
                    // change the existing mainline EntryFormProvisioner; it will auto-notify those listening to it
                    AppDelegate.mEntryFormProvisioner!.setBoth(orgRec: lastOrgRec!, formRec: lastFormRec!)
                }
                // remember the OrgRec and FormRec
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: lastOrgRec!.rOrg_Code_For_SV_File)
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm, value: lastFormRec!.rForm_Code_For_SV_File)
            } else {
                // no, at least remember the OrgRec's short name
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: lastOrgRec!.rOrg_Code_For_SV_File)
            }
        }
    }
    
    // check if the Form record should be remembered
    public func checkCurrentForm(withFormRec:RecOrgFormDefs) {
        if AppDelegate.mEntryFormProvisioner == nil {
            self.setCurrentForm(toFormRec: withFormRec)
        } else if withFormRec.isPartOfOrg(orgRec: AppDelegate.mEntryFormProvisioner!.mOrgRec) {
            if AppDelegate.mEntryFormProvisioner!.mFormRec == nil {
                self.setCurrentForm(toFormRec: withFormRec)
            } else if withFormRec.isSameNamed(otherRec: AppDelegate.mEntryFormProvisioner!.mFormRec!) {
                self.setCurrentForm(toFormRec: withFormRec)
            }
        }
    }
    
    // check if the current Form record needs be deleted and a new one found
    public func checkDeletionCurrentForm(withFormRecShortName:String, withOrgRecShortName:String) {
        if AppDelegate.mEntryFormProvisioner != nil {
            if AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File == withOrgRecShortName &&
                AppDelegate.mEntryFormProvisioner!.mFormRec != nil {
                if AppDelegate.mEntryFormProvisioner!.mFormRec!.rForm_Code_For_SV_File == withFormRecShortName {
                    self.setCurrentForm(toFormRec: nil)
                }
            }
        }
    }
    
    // set and remember the named Form
    public func setCurrentForm(toFormShortName:String, withOrgShortName:String) {
        do {
            let formRec:RecOrgFormDefs? = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName: toFormShortName, forOrgShortName: withOrgShortName)
            if formRec != nil {
                self.setCurrentForm(toFormRec: formRec)
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(AppDelegate.mCTAG).setCurrentForm(toFormShortName", errorStruct: error, extra: nil)
            // do not show an error to the end-user
        }
    }
    
    // set and remember the specified Form or one that is found in the database
    public func setCurrentForm(toFormRec:RecOrgFormDefs?) {
//debugPrint("\(AppDelegate.mCTAG).setCurrentForm STARTED")
        var lastOrgRec:RecOrganizationDefs? = nil
        var lastFormRec:RecOrgFormDefs? = nil
        do {
            if toFormRec != nil {
                // being told to change to a specified Form; have to make sure the Org record is also present in the database
                lastFormRec = toFormRec!
                if AppDelegate.mEntryFormProvisioner != nil {
                    if toFormRec!.isPartOfOrg(orgRec: AppDelegate.mEntryFormProvisioner!.mOrgRec) {
                        // new Form is part of our existing EFP, so just do a change
                        lastOrgRec = AppDelegate.mEntryFormProvisioner!.mOrgRec
                    } else {
                        // new Form apparently is dictating a change in Org too, so do both
                        lastOrgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: toFormRec!.rOrg_Code_For_SV_File)
                    }
                } else {
                    // no mainline EFP exists, so create one for this Form and its implied Org
                    lastOrgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: toFormRec!.rOrg_Code_For_SV_File)
                }
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(AppDelegate.mCTAG).setCurrentForm(toFormRec.1", errorStruct: error, extra: nil)
            // do not show an error to the end-user
        }
        
        do {
            if toFormRec == nil || lastOrgRec == nil {
                // being told to load the first or only Form that the remembered Org has; or the Form's Org was not found
                if AppDelegate.mEntryFormProvisioner != nil {
                    lastOrgRec = AppDelegate.mEntryFormProvisioner?.mOrgRec
                } else {
                    let lastOrg:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization)
                    if !(lastOrg ?? "").isEmpty {
                        lastOrgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: lastOrg!)
                    }
                }
                if lastOrgRec != nil {
                    let records:AnySequence<SQLite.Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: lastOrgRec!.rOrg_Code_For_SV_File)
                    for rowObj in records {
                        lastFormRec = try RecOrgFormDefs(row:rowObj)
                        break
                    }
                }
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(AppDelegate.mCTAG).setCurrentForm(toFormRec.2", errorStruct: error, extra: nil)
            // do not show an error to the end-user
        }
        
        // examine what was found in the database
        if lastOrgRec == nil {
            // there are no Org records in the database; eliminate the Main EFP and let every VC know
            self.resetCurrents()
        } else if lastFormRec == nil {
            // there are no Form records for the current Org; eliminate the Main EFP and let every VC know
            self.resetCurrents()
            AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: lastOrgRec!.rOrg_Code_For_SV_File)
        } else {
            // an Org and Form were found
            if lastOrgRec != nil && (lastFormRec?.isPartOfOrg(orgRec: lastOrgRec!) ?? false) == true {
                // yes both are consistent with each other; create or alter the mainline EntryFormProvisioner
                if AppDelegate.mEntryFormProvisioner == nil {
                    // create the new mainline EntryFormProvisioner; must also send out a global notification this its been late-created
                    AppDelegate.mEntryFormProvisioner = EntryFormProvisioner(forOrgRec: lastOrgRec!, forFormRec: lastFormRec!)
                    NotificationCenter.default.post(name: .APP_MainEFPaddedRemoved, object: nil)
                } else {
                    // change the existing mainline EntryFormProvisioner; it will auto-notify those listening to it
                    AppDelegate.mEntryFormProvisioner!.setBoth(orgRec: lastOrgRec!, formRec: lastFormRec!)
                }
                // remember the OrgRec and FormRec
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: lastOrgRec!.rOrg_Code_For_SV_File)
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm, value: lastFormRec!.rForm_Code_For_SV_File)
            } else {
                // no, at least remember the FormRec's short name
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm, value: lastFormRec!.rForm_Code_For_SV_File)
            }
        }
    }
    
    // set the Event
    public func setCurrentEvent(toOrgRec:RecOrganizationDefs) {
//debugPrint("\(AppDelegate.mCTAG).setCurrentEvent STARTED")
        if AppDelegate.mEntryFormProvisioner != nil {
            if toOrgRec.isSameNamed(otherRec: AppDelegate.mEntryFormProvisioner!.mOrgRec) {
                AppDelegate.mEntryFormProvisioner!.mOrgRec = toOrgRec
                }
        }
    }
    
    // reset everything; usually during a factory reset or when all Orgs are deleted
    public func resetCurrents() {
        AppDelegate.mEntryFormProvisioner = nil
        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: nil)
        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm, value: nil)
        NotificationCenter.default.post(name: .APP_MainEFPaddedRemoved, object: nil)    // let all OrgTitle VCs and any other VCs know
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related to preferences
    ///////////////////////////////////////////////////////////////////
    
    public static func getAllPreferenceKeys(keyPrefix:String? = nil) -> [String] {
        var check:Bool = false
        if !(keyPrefix ?? "").isEmpty { check = true }
        var result:[String] = []
        for pair in AppDelegate.mPrefsApp.dictionaryRepresentation() {
            if !check {
                result.append(pair.key)
            } else if pair.key.starts(with: keyPrefix!) {
                result.append(pair.key)
            }
        }
        return result
    }
    public static func getAllPreferencePairs(keyPrefix:String? = nil) -> [String:Any] {
        if !(keyPrefix ?? "").isEmpty { return AppDelegate.mPrefsApp.dictionaryRepresentation() }
        
        var result:[String:Any] = [:]
        for pair in AppDelegate.mPrefsApp.dictionaryRepresentation() {
            if pair.key.starts(with: keyPrefix!) {
                result[pair.key] = pair.value
            }
        }
        return result
    }
    public static func removeAllPreferences() {
        for pair in AppDelegate.mPrefsApp.dictionaryRepresentation() {
            AppDelegate.mPrefsApp.removeObject(forKey: pair.key)
        }
    }
    public static func doesPreferenceStringExist(prefKey:PreferencesKeys.Strings) -> Bool {
        if AppDelegate.mPrefsApp.object(forKey: prefKey.rawValue) != nil { return true }
        return false
    }
    public static func getPreferenceString(prefKey:PreferencesKeys.Strings) -> String? {
        return AppDelegate.mPrefsApp.string(forKey: prefKey.rawValue)
    }
    public static func setPreferenceString(prefKey:PreferencesKeys.Strings, value:String?) {
        AppDelegate.mPrefsApp.set(value, forKey: prefKey.rawValue)
    }
    public static func getPreferenceString(prefKeyString:String) -> String? {
        return AppDelegate.mPrefsApp.string(forKey: prefKeyString)
    }
    public static func setPreferenceString(prefKeyString:String, value:String?) {
        AppDelegate.mPrefsApp.set(value, forKey: prefKeyString)
    }
    public static func deletePreferenceString(prefKeyString:String) {
        AppDelegate.mPrefsApp.removeObject(forKey: prefKeyString)
    }
    public static func doesPreferenceIntExist(prefKey:PreferencesKeys.Ints) -> Bool {
        if AppDelegate.mPrefsApp.object(forKey: prefKey.rawValue) != nil { return true }
        return false
    }
    public static func getPreferenceInt(prefKey:PreferencesKeys.Ints) -> Int {
        return AppDelegate.mPrefsApp.integer(forKey: prefKey.rawValue)
    }
    public static func setPreferenceInt(prefKey:PreferencesKeys.Ints, value:Int?) {
        if value == nil { AppDelegate.mPrefsApp.set(nil, forKey: prefKey.rawValue) }
        else { AppDelegate.mPrefsApp.set(value, forKey: prefKey.rawValue) }
    }
    public static func doesPreferenceBoolExist(prefKey:PreferencesKeys.Bools) -> Bool {
        if AppDelegate.mPrefsApp.object(forKey: prefKey.rawValue) != nil { return true }
        return false
    }
    public static func getPreferenceBool(prefKey:PreferencesKeys.Bools) -> Bool {
        return AppDelegate.mPrefsApp.bool(forKey: prefKey.rawValue)
    }
    public static func setPreferenceBool(prefKey:PreferencesKeys.Bools, value:Bool?) {
        if value == nil { AppDelegate.mPrefsApp.set(nil, forKey: prefKey.rawValue) }
        else { AppDelegate.mPrefsApp.set(value, forKey: prefKey.rawValue) }
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related to KeyChain secured storage
    ///////////////////////////////////////////////////////////////////
    
    /*
     For internet passwords, the primary keys include:  kSecAttrAccount, kSecAttrSecurityDomain, kSecAttrServer,
                                                        kSecAttrProtocol, kSecAttrAuthenticationType, kSecAttrPort, and kSecAttrPath.
    */

    // store a secured item; key is key or key+label
    public static func storeSecureItem(key:String, label:String, data:Data) throws {
        // build first the read query
        var query:[String:Any] = [kSecClass as String: kSecClassInternetPassword,
                                  kSecAttrAccount as String: key,
                                  kSecAttrSecurityDomain as String: label,
                                  kSecMatchLimit as String: kSecMatchLimitOne,
                                  kSecReturnAttributes as String: kCFBooleanTrue as Any,
                                  kSecReturnData as String: kCFBooleanFalse as Any]
        
        // perform the read query
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        if status == errSecItemNotFound {   // -25300
            // perform an add; build the add query
            query = [kSecClass as String: kSecClassInternetPassword,
                     kSecAttrAccount as String: key,
                     kSecAttrSecurityDomain as String: label,
                     kSecValueData as String: data as AnyObject]
            // perform the add query
            let status1 = SecItemAdd(query as CFDictionary, nil)
            if status1 != errSecSuccess {
                var devInfo:String
                if #available(iOS 11.3, *) {
                    devInfo = "(\(status1)) \(SecCopyErrorMessageString(status1, nil) as String? ?? "")"
                } else {
                    devInfo = "\(status1)"
                }
                throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).storeSecureItem", during: "SecItemAdd", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Store Credentials", comment:""), developerInfo: devInfo)
            }
            return
        }
        if status != errSecSuccess {
            var devInfo:String
            if #available(iOS 11.3, *) {
                devInfo = "(\(status)) \(SecCopyErrorMessageString(status, nil) as String? ?? "")"
            } else {
                devInfo = "\(status)"
            }
            throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).storeSecureItem", during: "SecItemCopyMatching", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Retrieve Credentials", comment:""), developerInfo: devInfo)
        }
        // perform an update; build the changes dictionary
        let updates:[String:Any] = [kSecValueData as String: data as AnyObject]
        // build the update query
        query = [kSecClass as String: kSecClassInternetPassword,
                 kSecAttrAccount as String: key,
                 kSecAttrSecurityDomain as String: label]
        // perform the update query
        let status2 = SecItemUpdate(query as CFDictionary, updates as CFDictionary)
        if status2 != errSecSuccess {
            var devInfo:String
            if #available(iOS 11.3, *) {
                devInfo = "(\(status2)) \(SecCopyErrorMessageString(status2, nil) as String? ?? "")"
            } else {
                devInfo = "\(status2)"
            }
            throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).storeSecureItem", during: "SecItemUpdate", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Store Credentials", comment:""), developerInfo: devInfo)
        }
    }
    
    // does a secured item exist?; key is key or key+label
    public static func secureItemExists(key:String, label:String) throws -> Bool {
        // build the read query
        let query:[String:Any] = [kSecClass as String: kSecClassInternetPassword,
                                  kSecAttrAccount as String: key,
                                  kSecAttrSecurityDomain as String: label,
                                  kSecMatchLimit as String: kSecMatchLimitOne,
                                  kSecReturnAttributes as String: kCFBooleanTrue as Any,
                                  kSecReturnData as String: kCFBooleanFalse as Any]
        
        // perform the read query
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        if status == errSecItemNotFound { return false }    // -25300
        if status != errSecSuccess {
            var devInfo:String
            if #available(iOS 11.3, *) {
                devInfo = "(\(status)) \(SecCopyErrorMessageString(status, nil) as String? ?? "")"
            } else {
                devInfo = "\(status)"
            }
            throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).secureItemExists", during: "SecItemCopyMatching", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Retrieve Credentials", comment:""), developerInfo: devInfo)
        }
        return true
    }

    // retrieve a secured item; key is key or key+label
    public static func retrieveSecureItem(key:String, label:String) throws -> Data? {
        // build the read query
        let query:[String:Any] = [kSecClass as String: kSecClassInternetPassword,
                                  kSecAttrAccount as String: key,
                                  kSecAttrSecurityDomain as String: label,
                                  kSecMatchLimit as String: kSecMatchLimitOne,
                                  kSecReturnAttributes as String: kCFBooleanTrue as Any,
                                  kSecReturnData as String: kCFBooleanTrue as Any]
        
        // perform the read query
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        if status == errSecItemNotFound { return nil }  // -25300
        if status != errSecSuccess {
            var devInfo:String
            if #available(iOS 11.3, *) {
                devInfo = "(\(status)) \(SecCopyErrorMessageString(status, nil) as String? ?? "")"
            } else {
                devInfo = "\(status)"
            }
            throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).retrieveSecureItem", during: "SecItemCopyMatching", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Retrieve Credentials", comment:""), developerInfo: devInfo)
        }
        
        // return the read query result
        if let existingItem = queryResult as? [String : AnyObject] {
            return existingItem[kSecValueData as String] as? Data
        } else {
            throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).retrieveSecureItem", during: "queryResult as? [String : AnyObject]", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Retrieve Credentials", comment:""))
        }
    }
    
    // retrieve just the keys for all secured items; if an item has a label the return element is key\tlabel
    public static func retrieveAllSecureItemKeys(key:String?) throws -> [String] {
        // build the read query
        var query:[String:Any] = [kSecClass as String: kSecClassInternetPassword,
                                  kSecMatchLimit as String: kSecMatchLimitAll,
                                  kSecReturnAttributes as String: kCFBooleanTrue as Any]
        if !(key ?? "").isEmpty { query[kSecAttrAccount as String] = key! }
        
        // perform the read query
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        if status == errSecItemNotFound { return [] }   // -25300
        if status != errSecSuccess {
            var devInfo:String
            if #available(iOS 11.3, *) {
                devInfo = "(\(status)) \(SecCopyErrorMessageString(status, nil) as String? ?? "")"
            } else {
                devInfo = "\(status)"
            }
            throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).retrieveAllSecureItemKeys", during: "SecItemCopyMatching", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Retrieve Credentials", comment:""), developerInfo: devInfo)
        }
        
        // step through the results
        if let existingItems = queryResult as? [[String : AnyObject]] {
            var results:[String] = []
            for existingItem in existingItems {
                var account:String = existingItem[kSecAttrAccount as String] as! String
                let label:String? = existingItem[kSecAttrSecurityDomain as String] as? String
                if !(label ?? "").isEmpty { account = account + "\t" + label! }
                results.append(account)
            }
            return results
        } else {
            throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).retrieveAllSecureItemKeys", during: "queryResult as? [[String : AnyObject]]", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Retrieve Credentials", comment:""))
        }
    }
    
    // delete a secured item; key is key or key+label
    public static func deleteSecureItem(key:String, label:String) throws -> Bool {
        // build the delete query
        let query:[String:Any] = [kSecClass as String: kSecClassInternetPassword,
                                  kSecAttrAccount as String: key,
                                  kSecAttrSecurityDomain as String: label]
        
        // perform the delete query
        let status = SecItemDelete(query as CFDictionary)

        if status == errSecItemNotFound { return false }    // -25300
        if status != errSecSuccess {
            var devInfo:String
            if #available(iOS 11.3, *) {
                devInfo = "(\(status)) \(SecCopyErrorMessageString(status, nil) as String? ?? "")"
            } else {
                devInfo = "\(status)"
            }
            throw APP_ERROR(funcName: "\(AppDelegate.mCTAG).deleteSecureItem", during: "SecItemDelete", domain: AppDelegate.mKeychainThrownDomain, errorCode: .SECURE_STORAGE_ERROR, userErrorDetails: NSLocalizedString("Delete Credentials", comment:""), developerInfo: devInfo)
        }
        return true
    }
    
    ///////////////////////////////////////////////////////////////////
    // localization
    ///////////////////////////////////////////////////////////////////
    
    // get just the language portion of a LangRegion
    public static func getLangOnly(fromLangRegion:String) -> String {
        if fromLangRegion.contains("-") {
            return fromLangRegion.components(separatedBy: "-").first!
        } else if fromLangRegion.contains("_") {
            return fromLangRegion.components(separatedBy: "_").first!
        }
        return fromLangRegion
    }
    
    // force add/change the region portion of a LangRegion
    public static func forceRegion(region:String, intoLangRegion:String) -> String {
        if intoLangRegion.contains("-") {
            return intoLangRegion.components(separatedBy: "-").first! + "_" + region
        } else if intoLangRegion.contains("_") {
            return intoLangRegion.components(separatedBy: "_").first! + "_" + region
        }
        return intoLangRegion + "_" + region
    }

    // returns a list of all the localizations (*.lproj folders) that it supports
    public static func getAppsLocalizations() -> [String] {
        return Bundle.main.localizations
    }

    // return a descriptor (in the App's language) for the specified lang-region code
    public static func makeFullDescription(forLangRegion:String, inLangRegion:String?=nil, noCode:Bool=false) -> String {
        let seperators:CharacterSet = CharacterSet(charactersIn: "_-")
        var workingLocale = Locale.current
        if !(inLangRegion ?? "").isEmpty {
            workingLocale = Locale(identifier: inLangRegion!)
        }
        var regionShownString:String = ""
        if forLangRegion.contains("-") || forLangRegion.contains("_") {
            let components = forLangRegion.components(separatedBy: seperators)
            regionShownString = workingLocale.localizedString(forRegionCode: components[1]) ?? ""
        }
        if noCode {
            let langShownString = workingLocale.localizedString(forLanguageCode: forLangRegion) ?? forLangRegion
            return "\(langShownString) \(regionShownString)"
        } else {
            let langShownString = workingLocale.localizedString(forLanguageCode: forLangRegion) ?? ""
            return "\(langShownString) \(regionShownString) (\(forLangRegion))"
        }
    }
    
    // generate a list of languages useful for Eurerka's PushRow
    public static func getAvailableLangs(inLangRegion:String?=nil) -> ([CodePair], [String:String], [String:String]) {
        let commonBaseLangs = ["en","en_GB","en_AU","en_CA","en_IN","fr","fr_CA","es","es_MX","pt","pt_BR","it","de","zh","zh_Hans","zh_Hant","zh_HK","nl","ja","ko","vi","ru","sv","da","fi","nb","tr","el","id","ms","th","hi","hu","pl","cs","uk","hr","ca","ro","he","ar"]
        var workingLocale = Locale.current
        if !(inLangRegion ?? "").isEmpty {
            workingLocale = Locale(identifier: inLangRegion!)
        }
        let localesAvail = Locale.availableIdentifiers.sorted()
        let seperators:CharacterSet = CharacterSet(charactersIn: "_-")
    
        var controlPairs:[CodePair] = []
        var sectionMap:[String:String] = [:]
        var sectionTitles:[String:String] = [:]
        
        var currentSectionCode:String = "01"
        sectionTitles[currentSectionCode] = NSLocalizedString("Common Languages", comment:"")
        for localeCodeString in commonBaseLangs {
            var regionShownString = ""
            if localeCodeString.contains("-") || localeCodeString.contains("_") {
                let components = localeCodeString.components(separatedBy: seperators)
                regionShownString = workingLocale.localizedString(forRegionCode: components[1]) ?? ""
            }
            let localeShownString = (workingLocale.localizedString(forLanguageCode: localeCodeString) ?? "") + " \(regionShownString) (\(localeCodeString)) "
            let pairing:CodePair = CodePair(localeCodeString, localeShownString)
            controlPairs.append(pairing)
            sectionMap[localeCodeString] = currentSectionCode
        }
        
        currentSectionCode = "02"
        sectionTitles[currentSectionCode] = NSLocalizedString("Base Languages", comment:"")
        for localeCodeString in localesAvail {
            if localeCodeString.count == 2 {
                if !commonBaseLangs.contains(localeCodeString) {
                    let localeShownString = (workingLocale.localizedString(forLanguageCode: localeCodeString) ?? "") + " (\(localeCodeString)) "
                    let pairing:CodePair = CodePair(localeCodeString, localeShownString)
                    controlPairs.append(pairing)
                    sectionMap[localeCodeString] = currentSectionCode
                }
            }
        }
        
        currentSectionCode = "03"
        sectionTitles[currentSectionCode] = NSLocalizedString("Extended Languages", comment:"")
        for localeCodeString in localesAvail {
            if !localeCodeString.contains("-") && !localeCodeString.contains("_") {
                if localeCodeString.count > 2 {
                    let localeShownString = (workingLocale.localizedString(forLanguageCode: localeCodeString) ?? "") + " (\(localeCodeString)) "
                    let pairing:CodePair = CodePair(localeCodeString, localeShownString)
                    controlPairs.append(pairing)
                    sectionMap[localeCodeString] = currentSectionCode
                }
            }
        }
        
        currentSectionCode = "04"
        sectionTitles[currentSectionCode] = NSLocalizedString("Regionalized Common Languages", comment:"")
        for localeCodeString in localesAvail {
            if localeCodeString.contains("-") || localeCodeString.contains("_") {
                if !commonBaseLangs.contains(localeCodeString) {
                    let components = localeCodeString.components(separatedBy: seperators)
                    if commonBaseLangs.contains(components[0]) {
                        let regionShownString = workingLocale.localizedString(forRegionCode: components[1]) ?? ""
                        let localeShownString = (workingLocale.localizedString(forLanguageCode: localeCodeString) ?? "") + " \(regionShownString) (\(localeCodeString)) "
                        let pairing:CodePair = CodePair(localeCodeString, localeShownString)
                        controlPairs.append(pairing)
                        sectionMap[localeCodeString] = currentSectionCode
                    }
                }
            }
        }
        
        currentSectionCode = "05"
        sectionTitles[currentSectionCode] = NSLocalizedString("Regionalized Base Languages", comment:"")
        for localeCodeString in localesAvail {
            if localeCodeString.contains("-") || localeCodeString.contains("_") {
                if !commonBaseLangs.contains(localeCodeString) {
                    let components = localeCodeString.components(separatedBy: seperators)
                    if components[0].count == 2 {
                        if !commonBaseLangs.contains(components[0]) {
                            let regionShownString = workingLocale.localizedString(forRegionCode: components[1]) ?? ""
                            let localeShownString = (workingLocale.localizedString(forLanguageCode: localeCodeString) ?? "") + "  \(regionShownString) (\(localeCodeString)) "
                            let pairing:CodePair = CodePair(localeCodeString, localeShownString)
                            controlPairs.append(pairing)
                            sectionMap[localeCodeString] = currentSectionCode
                        }
                    }
                }
            }
        }
        
        currentSectionCode = "06"
        sectionTitles[currentSectionCode] = NSLocalizedString("Regionalized Extended Languages", comment:"")
        for localeCodeString in localesAvail {
            if localeCodeString.contains("-") || localeCodeString.contains("_") {
                let components = localeCodeString.components(separatedBy: seperators)
                if components[0].count > 2 {
                    let regionShownString = workingLocale.localizedString(forRegionCode: components[1]) ?? ""
                    let localeShownString = (workingLocale.localizedString(forLanguageCode: localeCodeString) ?? "") + "  \(regionShownString) (\(localeCodeString)) "
                    let pairing:CodePair = CodePair(localeCodeString, localeShownString)
                    controlPairs.append(pairing)
                    sectionMap[localeCodeString] = currentSectionCode
                }
            }
        }

        return (controlPairs, sectionMap, sectionTitles)
    }

    ///////////////////////////////////////////////////////////////////
    // UTC date-time handling
    ///////////////////////////////////////////////////////////////////
    
    // get the current timestamp (in integer MS) for UTC
    public static func utcCurrentTimeMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000.0) - AppDelegate.mDeviceTimezoneOffsetMS
    }
    
    // convert a recorded UTC timestamp to this device's local timezone
    public static func convertUTCtoThenLocal(timestampUTC:Int64) -> Date {
        return Date(timeIntervalSince1970:(Double(timestampUTC + AppDelegate.mDeviceTimezoneOffsetMS) / 1000.0))
    }
    
    ///////////////////////////////////////////////////////////////////
    // App Rating Reminder
    ///////////////////////////////////////////////////////////////////

    public enum RatingReminderReason {
        case FirstTime, AppStart, AppRestart, ContactCollected
    }
    
    // increment the days of use counter for the rating reminder
    public static func ratingReminderIncrement(reason: RatingReminderReason) {
        let isDone:Bool = AppDelegate.getPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Done)
        if isDone { return }
        
        let mydateFormatter = DateFormatter()
        mydateFormatter.dateFormat = "yyyyMMdd"
        let todayStr:String = mydateFormatter.string(from: Date())

        switch reason {
        case .FirstTime:
            // application first-time ever startup; set a baseline initial date
            AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_Rating_LastDate, value: todayStr)
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Rating_DaysCountdown, value: 14)
            AppDelegate.setPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Needed, value: false)
            AppDelegate.setPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Done, value: false)
            break
        
        case .AppStart:
            // application startup; going to ignore this
            break
        
        case .AppRestart:
            // application being re-activated; going to ignore this
            break
            
        case .ContactCollected:
            // contact was collected
            let lastDate:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.APP_Rating_LastDate)
            if (lastDate ?? "").isEmpty {
                // last date is missing from the preferences; reset and re-start
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_Rating_LastDate, value: todayStr)
                AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Rating_DaysCountdown, value: 14)
            } else if lastDate! != todayStr {
                // today is different from the last known date; decrement the days counter
                var lastCnt:Int = AppDelegate.getPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Rating_DaysCountdown)
                lastCnt = lastCnt - 1
                if lastCnt > 0 {
                    // still not time to remind, so just save all in preferences
                    AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_Rating_LastDate, value: todayStr)
                    AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Rating_DaysCountdown, value: lastCnt)
                } else {
                    // it is now time to remind
                    AppDelegate.setPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Needed, value: true)
                    AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_Rating_LastDate, value: todayStr)
                    AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Rating_DaysCountdown, value: 30)
                }
            }
            break
        }
    }
    
    // perform the rating reminder if time to do so
    public static func ratingReminderPerform(vc: UIViewController) {
        let isDone:Bool = AppDelegate.getPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Done)
        if isDone { return }
        let needed:Bool = AppDelegate.getPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Needed)
        if !needed { return }
        
        // it is time to remind for a rating; reset the flag
        AppDelegate.setPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Needed, value: false)
        
        // perform the asking
        //if #available( iOS 10.3,*) {
            // use the new intra-APP rating iOS API ... it auto-includes the "done" mechanism so will not get re-asked if a rating was performed;
            // it also enforces not asking more than three times per year
            //SKStoreReviewController.requestReview()
        //} else {
            // since APP's minimum iOS is 10.0, then this applies only to 10.0, 10.1, and 10.2
            AppDelegate.show3ButtonDialog(vc:vc, title:NSLocalizedString("Rating Reminder", comment:""), message:NSLocalizedString("Are you willing to rate/review this App in the AppStore?", comment:""), button1Text:NSLocalizedString("Yes", comment:""), button2Text:NSLocalizedString("Later", comment:""), button3Text:NSLocalizedString("Never", comment:""), callbackAction:1, callbackString1:nil, callbackString2:nil, completion: {(vc:UIViewController, theResult:Int, callbackAction:Int, callbackString1:String?, callbackString2:String?) -> Void in
                // callback from the dialog upon one of the buttons being pressed
                switch theResult {
                case 1:
                    // button yes; send them to the AppStore
                    UIApplication.shared.open(NSURL(string:"itms-apps://itunes.apple.com/app/id1447133009?action=write-review")! as URL)
                    AppDelegate.setPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Done, value: true)
                    break
                case 2:
                    // button later; nothing need be done
                    break
                case 3:
                    // button never; set the done flag
                    AppDelegate.setPreferenceBool(prefKey: PreferencesKeys.Bools.APP_Rating_Done, value: true)
                    break
                default:
                    break
                }
                return  // from callback
            })
        //}
    }
    
    ///////////////////////////////////////////////////////////////////
    // Font and Color encoding and decoding for transport and storage
    ///////////////////////////////////////////////////////////////////

    // encode UIColor into "color-rgba;#;#;#;#"
    public static func encodeColor(fromColor:UIColor) -> String {
        let rgbaValues = fromColor.rgba()
        return "color-rgba;\(rgbaValues.r);\(rgbaValues.g);\(rgbaValues.b);\(rgbaValues.a)"
    }
    
    // decode "color-rgba;#;#;#;#" back into a UIColor
    public static func decodeColor(fromString:String) -> UIColor? {
        if !fromString.hasPrefix("color-rgba;") { return nil }
        let comps:[String] = fromString.components(separatedBy: ";")
        if comps.count < 4 { return nil }
        
        // initialize to black
        var r:CGFloat = 0.0
        var g:CGFloat = 0.0
        var b:CGFloat = 0.0
        var a:CGFloat = 1.0
        
        // extract component colors and alpha
        r = CGFloat((comps[1] as NSString).floatValue)
        g = CGFloat((comps[2] as NSString).floatValue)
        b = CGFloat((comps[3] as NSString).floatValue)
        if comps.count >= 5 {
            a = CGFloat((comps[4] as NSString).floatValue)
        }
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    // encode UIFont into "font-fssn;<FontFamily>;<styles>;#;<fontName>"
    public static func encodeFont(fromFont:UIFont) -> String {
        var fontFamily = fromFont.familyName
        if fontFamily.starts(with: ".SF") { fontFamily = "System" }
        
        var styles:String = ""
        if fromFont.isBold { styles = styles + "B" }
        if fromFont.isItalic { styles = styles + "I" }
        
        return "font-fssn;\(fontFamily);\(styles);\(fromFont.pointSize);\(fromFont.fontName)"
    }
    
    // decode "font-fssn;<FontFamily>;<styles>;#;<fontName>" back into a UIFont
    public static func decodeFont(fromString:String) -> UIFont? {
        if !fromString.hasPrefix("font-fssn;") { return nil }
        let comps:[String] = fromString.components(separatedBy: ";")
        if comps.count < 4 { return nil }
        let size = CGFloat((comps[3] as NSString).floatValue)
        
        var retFont:UIFont
        if comps[1] == "System" { retFont = UIFont.systemFont(ofSize: size) }
        else { retFont = UIFont(name: comps[1], size: size) ?? UIFont.systemFont(ofSize: size) }
        
        if comps[2].contains("I") && comps[2].contains("B") { retFont = retFont.boldItalic() }
        else if comps[2].contains("B") { retFont = retFont.bold() }
        else if comps[2].contains("I") { retFont = retFont.italic() }
        
        return retFont
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related to standard dialogs
    ///////////////////////////////////////////////////////////////////

    // show an alert dialog with only an Okay button (aka dismiss button)
    public static func showAlertDialog(vc:UIViewController, title:String, message:String, buttonText:String, completion: (() -> Void)? = nil) {
        let alertObj = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        if completion != nil {
            alertObj.addAction(UIAlertAction(title:buttonText, style:UIAlertAction.Style.default, handler: { action in
            completion!()
            }))
        } else {
            alertObj.addAction(UIAlertAction(title:buttonText, style:UIAlertAction.Style.default, handler:nil))
        }
        vc.present(alertObj, animated:true, completion:nil)
    }
    
    // show an alert dialog with only an Okay button (aka dismiss button)
    public static func showAlertDialog(vc:UIViewController, title:String, endUserDuring:String?=nil, errorStruct:Error, buttonText:String, completion:(() -> Void)?=nil) {
        var msg:String
        if !(endUserDuring ?? "").isEmpty { msg = "\(endUserDuring!): " + AppDelegate.endUserErrorMessage(errorStruct: errorStruct) }
        else { msg = AppDelegate.endUserErrorMessage(errorStruct: errorStruct) }
        
        let alertObj = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        if completion != nil {
            alertObj.addAction(UIAlertAction(title:buttonText, style:UIAlertAction.Style.default, handler: { action in
                completion!()
            }))
        } else {
            alertObj.addAction(UIAlertAction(title:buttonText, style:UIAlertAction.Style.default, handler:nil))
        }
        vc.present(alertObj, animated:true, completion:nil)
    }
    
    // show a Yes/No dialog, normally for Confirmation dialogs; theResult will be true for yes, and false for no
    // the callbackAction integer and the two callbackStrings are provided solely for use of the caller
    public static func showYesNoDialog(vc:UIViewController, title:String, message:String, buttonYesText:String?, buttonNoText:String?, callbackAction:Int, callbackString1:String?, callbackString2:String?, completion:@escaping(_ vc:UIViewController, _ theChoice:Bool, _ callbackAction:Int, _ callbackString1:String?, _ callbackString2:String?) -> Void) {
        
        let alertObj = UIAlertController(title:title, message:message, preferredStyle:UIAlertController.Style.alert)
        if !(buttonYesText ?? "").isEmpty {
            alertObj.addAction(UIAlertAction(title:buttonYesText!, style:UIAlertAction.Style.default, handler: { action in
                completion(vc, true, callbackAction, callbackString1, callbackString2)
            }))
        }
        if !(buttonNoText ?? "").isEmpty {
            alertObj.addAction(UIAlertAction(title:buttonNoText!, style:UIAlertAction.Style.default, handler:{ action in
                completion(vc, false, callbackAction, callbackString1, callbackString2)
            }))
        }
        vc.present(alertObj, animated:true, completion:nil)
    }
    
    // show a 3 button dialog; theResult will be 1, 2, or 3;
    // the callbackAction integer and the two callbackStrings are provided solely for use of the caller
    public static func show3ButtonDialog(vc:UIViewController, title:String, message:String, button1Text:String?, button2Text:String?, button3Text:String?, callbackAction:Int, callbackString1:String?, callbackString2:String?, completion:@escaping(_ vc:UIViewController, _ theChoice:Int, _ callbackAction:Int, _ callbackString1:String?, _ callbackString2:String?) -> Void) {
        
        let alertObj = UIAlertController(title:title, message:message, preferredStyle:UIAlertController.Style.alert)
        if !(button1Text ?? "").isEmpty {
            alertObj.addAction(UIAlertAction(title:button1Text!, style:UIAlertAction.Style.default, handler: { action in
                completion(vc, 1, callbackAction, callbackString1, callbackString2)
            }))
        }
        if !(button2Text ?? "").isEmpty {
            alertObj.addAction(UIAlertAction(title:button2Text!, style:UIAlertAction.Style.default, handler: { action in
                completion(vc, 2, callbackAction, callbackString1, callbackString2)
            }))
        }
        if !(button3Text ?? "").isEmpty {
            alertObj.addAction(UIAlertAction(title:button3Text!, style:UIAlertAction.Style.default, handler: { action in
                completion(vc, 3, callbackAction, callbackString1, callbackString2)
            }))
        }
        vc.present(alertObj, animated:true, completion:nil)
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related to the error.log and Alerts
    ///////////////////////////////////////////////////////////////////
    
    // return the full path to the error log
    public static func getErrorLogFullPath() -> String {
        return "\(AppDelegate.mDocsApp)/error.log"
    }
    
    // Thread Context: may be called from utility threads, so cannot perform UI actions
    // create an appropriate end-user error string based upon the type of the ErrorType
    public static func endUserErrorMessage(errorStruct:Error) -> String {
        if type(of:errorStruct) == Result.self {
            // SQLite.swift general error
            let errorResult:Result = errorStruct as! Result
            return "\(NSLocalizedString("Database-Handler:", comment:"")) \(errorResult._code) \"\(errorResult.localizedDescription)\""
        } else if type(of:errorStruct) == QueryError.self {
            // SQLite.swift query error
            let errorResult:QueryError = errorStruct as! QueryError
            return "\(NSLocalizedString("Database-Handler:", comment:"")) \(errorResult._code) \"\(errorResult.localizedDescription)\""
        } else if type(of:errorStruct) == USER_ERROR.self {
            // our App's user errors
            let errorResult:USER_ERROR = errorStruct as! USER_ERROR
            return errorResult.localizedDescription
        } else if type(of:errorStruct) == APP_ERROR.self {
            // our App's programming errors
            let errorResult:APP_ERROR = errorStruct as! APP_ERROR
            return errorResult.localizedDescription
        } else {
            // standard error
            return "\(errorStruct._domain): \(errorStruct._code) \"\(errorStruct.localizedDescription)\""
        }
    }
    
    // Thread Context: may be called from utility threads, so cannot perform UI actions;
    // create an appropriate developer error string based upon the type of the ErrorType;
    // if forErrorLog do NOT place a final '\n' into the return string
    public static func developerErrorMessage(errorStruct:Error, forErrorLog:Bool=false) -> String {
        if type(of:errorStruct) == Result.self {
            // SQLite.swift error
            let errorResult:Result = errorStruct as! Result
            return "SQLite Error: \(errorResult._code) \"\(errorResult.description)\""
        } else if type(of:errorStruct) == QueryError.self {
            // SQLite.swift query error
            let errorResult:QueryError = errorStruct as! QueryError
            return "SQLite Query Error: \(errorResult._code) \"\(errorResult.description)\""
        } else if type(of:errorStruct) == USER_ERROR.self {
            // our App's user errors
            let errorResult:USER_ERROR = errorStruct as! USER_ERROR
            var errorMessage:String = "User_Error: "
            if forErrorLog {
                errorMessage = "  " + errorMessage + errorResult.description
            } else {
                errorMessage = errorMessage + errorResult.description
            }
            return errorMessage
        } else if type(of:errorStruct) == APP_ERROR.self {
            // our App's errors
            let errorResult:APP_ERROR = errorStruct as! APP_ERROR
            var errorMessage:String = "App_Error: "
            if forErrorLog {
                errorMessage = "  " + errorMessage + errorResult.descriptionForErrorLog
            } else {
                errorMessage = errorMessage + errorResult.description
            }
            if errorResult.error != nil && !forErrorLog {
                if forErrorLog { errorMessage = errorMessage + "\n" }
                else { errorMessage = errorMessage + "; " }
                errorMessage = errorMessage + developerErrorMessage(errorStruct: errorResult.error!, forErrorLog: forErrorLog)
            }
            return errorMessage
        } else {
            // standard error
            var errorMessage:String = "Error: "
            if forErrorLog { errorMessage = "  " + errorMessage }
            errorMessage = errorMessage + "\(errorStruct._domain): \(errorStruct._code) \"\(errorStruct.localizedDescription)\""
            if errorStruct._userInfo != nil {
                if forErrorLog { errorMessage = errorMessage + "\n         UserInfo:" }
                else { errorMessage = errorMessage + "; UserInfo:" }
                for (key, value) in (errorStruct._userInfo! as! NSDictionary) {
                    let keyString = key as? String
                    let valueString = value as? String
                    if !(keyString ?? "").isEmpty && !(valueString ?? "").isEmpty {
                        errorMessage = errorMessage + " " + keyString! + "=" + valueString! + ","
                    } else if !(keyString ?? "").isEmpty {
                        errorMessage = errorMessage + " " + keyString! + ","
                    } else if !(valueString ?? "").isEmpty {
                        errorMessage = errorMessage + " " + valueString! + ","
                    }
                }
            }
            return errorMessage
        }
    }

    // Thread Context: may be called from utility threads, so cannot perform UI actions
    // write detailed exception and severe error information into an error log that the end-user can email to the developer
    public static func postExceptionToErrorLogAndAlert(method:String?, exception:NSException, extra:String?) {
        self.postToErrorLogAndAlert_internal(method: method, during:nil, prefix:"EXCEPTION!", exception:exception, errorStruct:nil, message:nil ,extra:extra, noAlert:false)
    }
    public static func postToErrorLogAndAlert(method:String?, during:String?=nil, errorStruct:Error, extra:String?, noAlert:Bool=false) {
        if method != nil, var appError = errorStruct as? APP_ERROR {
            if !appError.callStack.starts(with: method!) {
                appError.prependCallStack(funcName: method!)
                var doNoAlert:Bool = noAlert
                if appError.noAlert { doNoAlert = true }
                self.postToErrorLogAndAlert_internal(method:method!, during:during, prefix:"ERROR!", exception:nil, errorStruct:appError, message:nil, extra:extra, noAlert:doNoAlert)
                return
            }
        }
        self.postToErrorLogAndAlert_internal(method:method, during:during, prefix:"ERROR!", exception:nil, errorStruct:errorStruct, message:nil, extra:extra, noAlert:noAlert)
    }
    public static func postToErrorLogAndAlert(method:String?, during:String?=nil, errorMessage:String, extra:String? = nil, noAlert:Bool=false) {
        self.postToErrorLogAndAlert_internal(method: method, during:during, prefix:"ERROR!", exception:nil, errorStruct:nil, message:errorMessage, extra:extra, noAlert:noAlert)
    }
    public static func noticeToErrorLogAndAlert(method:String?, during:String?=nil, notice:String, extra:String? = nil, noAlert:Bool=false) {
        self.postToErrorLogAndAlert_internal(method: method, during:during, prefix:"NOTICE!", exception:nil, errorStruct:nil, message:notice, extra:extra, noAlert:noAlert)
    }
    private static func postToErrorLogAndAlert_internal(method:String?, during:String?, prefix:String, exception:NSException?, errorStruct:Error?, message:String?, extra:String?, noAlert:Bool) {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        // show the error on the console
        var eMsg:String = prefix
        if !(method ?? "").isEmpty { eMsg = eMsg + " in \(method!)" }
        if !(during ?? "").isEmpty { eMsg = eMsg + " during \(during!)" }
        if !(extra ?? "").isEmpty { eMsg = eMsg + " [\(extra!)]" }
        if !(message ?? "").isEmpty { eMsg = eMsg + ": \(message!)" }
        if errorStruct != nil { eMsg = eMsg + ": " + AppDelegate.developerErrorMessage(errorStruct: errorStruct!) }

        if exception != nil {
            eMsg = eMsg + ": \(exception!.name)"
            if exception!.reason != nil {
                eMsg = eMsg + " \(exception!.reason!)"
            }
        }
        print("\(AppDelegate.mCTAG).postToErrorLogAndAlert: \(eMsg)")
        if exception != nil {
            print(exception!.callStackSymbols)
        }
        if errorStruct != nil {
            if type(of:errorStruct) == USER_ERROR.self { return }   // do not post user errors into the error.log nor make an alert
            if let appError = errorStruct as? APP_ERROR {           // is APP_ERROR marked as "noPost"?
                if appError.noPost { return }                           // yes, do not post it
            }
        }
        
        // build the pre-information for the error.log
        let mydateFormatter = DateFormatter()
        mydateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let appCode:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
        let appName:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        let appVer:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let appBuild:Int64 = Int64(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)!
        var sysinfo = utsname()
        uname(&sysinfo)
        let model = NSString(bytes: &sysinfo.machine, length: Int(_SYS_NAMELEN), encoding: String.Encoding.ascii.rawValue)! as String
        let screenSize: CGRect = UIScreen.main.bounds
        var orient:String
        switch UIDevice.current.orientation {       // note: this may return unknown during App startup
        case .portrait:
            orient = "portrait"
            break
        case .portraitUpsideDown:
            orient = "portrait-upsidedown"
            break
        case .landscapeLeft:
            orient = "landscape-left"
            break
        case .landscapeRight:
            orient = "landscape-right"
            break
        case .faceUp:
            orient = "face-up"
            break
        case .faceDown:
            orient = "face-down"
            break
        default:
            orient = "unknown"
            break
        }
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        var orientApp:String
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            orientApp = "portrait"
            break
        case .portraitUpsideDown:
            orientApp = "portrait-upsidedown"
            break
        case .landscapeLeft:
            orientApp = "landscape-left"
            break
        case .landscapeRight:
            orientApp = "landscape-right"
            break
        default:
            orientApp = "unknown"
            break
        }
        
        var buildDate:String = ""
        if let infoPath = Bundle.main.path(forResource: appName, ofType: nil),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date {
            buildDate = mydateFormatter.string(from: infoDate)
        }

        // append a full set of information into error.log
        let fullPath = "\(AppDelegate.mDocsApp)/error.log"
        if let outputStream = OutputStream(toFileAtPath: fullPath, append: true) {
            outputStream.open()
            var str = "Local DateTime: \(mydateFormatter.string(from: Date())), TimezoneOffset_min: \(AppDelegate.mDeviceTimezoneOffsetMS / 60000) (\(AppDelegate.mDeviceTimezone))\n"
            outputStream.write(str, maxLength:str.count)
            str = "iOS App \(appName) [\(appCode)], AppVersionString \(appVer), AppBuildCode \(appBuild), BuildDateTime \(buildDate)\n"
            outputStream.write(str, maxLength:str.count)
            str = "DBHandler State \(DatabaseHandler.shared.mDBstatus_state), DBver \(DatabaseHandler.shared.getVersioning())\n"
            outputStream.write(str, maxLength:str.count)
            str = "FieldHandler State \(FieldHandler.shared.mFHstatus_state)\n"
            outputStream.write(str, maxLength:str.count)
            str = "SVFileHandler State \(SVFilesHandler.shared.mSVHstatus_state)\n"
            outputStream.write(str, maxLength:str.count)
            str = "iOS Version \(UIDevice.current.systemVersion)\n"
            outputStream.write(str, maxLength:str.count)
            str = "iOS Language \(AppDelegate.mDeviceLanguage), iOS Region \(AppDelegate.mDeviceRegion), iOS LangRegion \(AppDelegate.mDeviceLangRegion)\n"
            outputStream.write(str, maxLength:str.count)
            str = "App Language-Region \(AppDelegate.mAppLangRegion)\n"
            outputStream.write(str, maxLength:str.count)
            str = "Platform Manf Apple, Model \(model)\n"
            outputStream.write(str, maxLength:str.count)
            str = "Platform Screen Orientation X,Y \(screenSize.width),\(screenSize.height); Orient=\(orient); Density=\(UIScreen.main.scale)\n"
            outputStream.write(str, maxLength:str.count)
            str = "App Screen Orientation=\(orientApp)\n"
            outputStream.write(str, maxLength:str.count)
            if !(method ?? "").isEmpty { str = "Method: \(method!)\n"; outputStream.write(str, maxLength:str.count) }
            if !(during ?? "").isEmpty { str = "During: \(during!)\n"; outputStream.write(str, maxLength:str.count) }
            if !(extra ?? "").isEmpty { str = "Extra: \(extra!)\n"; outputStream.write(str, maxLength:str.count) }
            if !(message ?? "").isEmpty { str = "Message: \(prefix) \(message!)\n"; outputStream.write(str, maxLength:str.count) }
            if errorStruct != nil {
                str = "ErrorStruct: \(prefix)\n"
                outputStream.write(str, maxLength:str.count)
                if let appError = errorStruct as? APP_ERROR {
                    str = AppDelegate.developerErrorMessage(errorStruct: appError, forErrorLog: true) + "\n"
                    outputStream.write(str, maxLength:str.utf8.count)
                    if appError.error != nil {
                        str = AppDelegate.developerErrorMessage(errorStruct: appError.error!, forErrorLog: true) + "\n"
                        outputStream.write(str, maxLength:str.utf8.count)
                    }
                } else {
                    str = AppDelegate.developerErrorMessage(errorStruct: errorStruct!, forErrorLog: true) + "\n"
                    outputStream.write(str, maxLength:str.utf8.count)
                }
            }
            if exception != nil {
                str = "Exception: \(exception!.name)"
                if exception!.reason != nil { str = str + " \(exception!.reason!)" }
                str = str + "\n"
                outputStream.write(str, maxLength:str.count)
                if exception!.userInfo != nil {
                    str = "Exception UserInfo: "
                    for (key, value) in exception!.userInfo! {
                        let keyString = key as? String
                        let valueString = value as? String
                        if !(keyString ?? "").isEmpty && !(valueString ?? "").isEmpty {
                            str = str + " " + keyString! + "=" + valueString! + ","
                        } else if !(keyString ?? "").isEmpty {
                            str = str + " " + keyString! + ","
                        } else if !(valueString ?? "").isEmpty {
                            str = str + " " + valueString! + ","
                        }
                    }
                    str = str + "\n"
                    outputStream.write(str, maxLength:str.count)
                }
                str = str + "-----Exception-----\n"
                outputStream.write(str, maxLength:str.count)
                let array = exception!.callStackSymbols
                for line:String in array {
                    str = "\(line)\n"
                    outputStream.write(str, maxLength:str.count)
                }
            }
#if DEBUG
            // record the call stack into the error.log; since the downloaded App has no symbols this is not useful in the released version
            outputStream.write("-----Thread-----\n", maxLength:17)
            let stack:[String] = Thread.callStackSymbols
            for entry in stack {
                str = "\(entry)\n"
                outputStream.write(str, maxLength:str.count)
            }
#endif
            outputStream.write("==========\n", maxLength:11)
            outputStream.write("==========\n", maxLength:11)
            outputStream.write("==========\n", maxLength:11)
            outputStream.close()
        } else {
            print("\(AppDelegate.mCTAG).postToErrorLog: ERROR! failed to open error.log file")
        }
        
        // typically but optionally also post an alert into the DB
        if !noAlert {
            AppDelegate.postAlert(message: NSLocalizedString("Severe error has occured; see error.log for details", comment:""));
            
        }
    }
    
    // Thread Context: may be called from utility threads, so cannot perform UI actions
    // write an alert message into the database; do not throw any errors!
    public static func postAlert(message:String, extendedDetails:String?=nil) {
        if !DatabaseHandler.shared.isReady() {
            print("\(AppDelegate.mCTAG).postAlert Attempt to post an alert before the DatabaseHandler has been instantiated");
            return
        }
        
        let aRec = RecAlert(timestamp_ms_utc: AppDelegate.utcCurrentTimeMillis(), timezone_ms_utc_offset: AppDelegate.mDeviceTimezoneOffsetMS, message: message)
        aRec.rAlert_ExtendedDetails = extendedDetails
        do {
            let _ = try aRec.saveNewToDB()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).postAlert", errorStruct: error, extra: nil, noAlert: true)
            // do not show an error to the end-user
        }
    }
}

