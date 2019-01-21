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
        case APP_Rating_Needed = "TESTapp_PIN"
        case APP_Rating_Done = "TESTapp_PIN"
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
#else
        case APP_Pin = "app_PIN"                                // PIN needed to get into the Settings; may be nil or empty
        case Collector_Nickname = "collector_Nickname"          // Nickname of the app's end-user; will be inserted into all collected records
        case APP_LastOrganization = "app_LastOrganization"      // Org short name that was last currently active
        case APP_LastForm = "app_LastForm"                      // Form short name that was last currently active
        case APP_Rating_LastDate = "app_rating_lastDate"        // last date-of-use (part of ask-for-a-rating); YYYYMMDD
#endif
    }
    enum Ints: String {
#if TESTING
        case APP_FirstTime = "TESTapp_firstTimeStages"
        case APP_Rating_DaysCountdown = "TESTapp_rating_daysCountdown"
#else
        case APP_FirstTime = "app_firstTimeStages"              // nil=first time stage 1 needed; -1=first time fully completed; 1,2... currently in the indicated first time stage
        case APP_Rating_DaysCountdown = "app_rating_daysCountdown"  // countdown of unique days of use (part of ask-for-a-rating)
#endif
    }
}

// App internal Notification definitions
extension Notification.Name {
    static let APP_CreatedMainEFP = Notification.Name("APP_CreatedMainEFP")
    static let APP_EFP_OrgFormChange = Notification.Name("APP_EFP_OrgFormChange")
    static let APP_EFP_LangRegionChanged = Notification.Name("APP_EFP_LangRegionChanged")
    static let APP_FileRequestedToOpen = Notification.Name("APP_FileRequestedToOpen")
}

// Handler status enumerator
public func <<T: RawRepresentable>(a: T, b: T) -> Bool where T.RawValue: Comparable {
    return a.rawValue < b.rawValue
}
public enum HandlerStatusStates: Int, Comparable {
    case Unknown = 0, Missing = 1, Errors = 2, Invalid = 3, Obsolete = 4, Valid = 5
}

public struct APP_ERROR:Error, CustomStringConvertible {
    var during:String? = nil
    var domain:String
    var errorCode:APP_ERROR_CODE
    var userErrorDetails:String? = nil
    var developerInfo:String? = nil
    
    public init(during:String?=nil, domain:String, errorCode:APP_ERROR_CODE, userErrorDetails:String?, developerInfo:String?=nil) {
        self.during = during
        self.domain = domain
        self.errorCode = errorCode
        self.userErrorDetails = userErrorDetails
        self.developerInfo = developerInfo
    }

    public var description:String {
        var messageStr:String = ""
        if self.during != nil { messageStr = messageStr + "\(self.during!) @ " }
        messageStr = messageStr + "\(self.domain): (\(self.errorCode.rawValue)) \"\(self.errorCode.description)\""
        if !(self.userErrorDetails ?? "").isEmpty { messageStr = messageStr + "; " + self.userErrorDetails! }
        return messageStr
    }
}

public enum APP_ERROR_CODE:Int, CustomStringConvertible {
    case NO_ERROR  = 0
    case UNKNOWN_ERROR  = -1
    case HANDLER_IS_NOT_ENABLED  = -40
    case FILESYSTEM_ERROR  = -41
    case DATABASE_ERROR  = -42
    case INTERNAL_ERROR  = -43
    case MISSING_REQUIRED_CONTENT  = -44
    case RECORD_NOT_FOUND = -45
    case RECORD_IS_COMPOSED  = -46
    case COULD_NOT_CREATE = -47
    case COULD_NOT_ACCESS = -48
    case DID_NOT_VALIDATE = -49
    case DID_NOT_OPEN = -50
    case ORG_DOES_NOT_EXIST = -51
    case RECORD_MARKED_DELETED = -52
    case MISSING_OR_MISMATCHED_FIELD_METADATA = -53
    case MISSING_OR_MISMATCHED_FIELD_OPTIONS = -54
    case MISSING_OR_MISMATCHED_FIELD_OPTIONSET = -55
    
    public var description:String {
        switch self {
        case .NO_ERROR:
            return NSLocalizedString("No error", comment:"")
        case .UNKNOWN_ERROR:
            return NSLocalizedString("Unknown error", comment:"")
        case .HANDLER_IS_NOT_ENABLED:
            return NSLocalizedString("Handler is not enabled", comment:"")
        case .FILESYSTEM_ERROR:
            return NSLocalizedString("Filesystem Error", comment:"")
        case .DATABASE_ERROR:
            return NSLocalizedString("Database Error", comment:"")
        case .INTERNAL_ERROR:
            return NSLocalizedString("Internal Error", comment:"")
        case .MISSING_REQUIRED_CONTENT:
            return NSLocalizedString("Missing required content", comment:"")
        case .RECORD_IS_COMPOSED:
            return NSLocalizedString("Record is composed", comment:"")
        case .RECORD_NOT_FOUND:
            return NSLocalizedString("Record not found", comment:"")
        case .COULD_NOT_CREATE:
            return NSLocalizedString("Could not create", comment:"")
        case .COULD_NOT_ACCESS:
            return NSLocalizedString("Could not access", comment:"")
        case .DID_NOT_VALIDATE:
            return NSLocalizedString("Did not validate", comment:"")
        case .DID_NOT_OPEN:
            return NSLocalizedString("Did not open", comment:"")
        case .ORG_DOES_NOT_EXIST:
            return NSLocalizedString("Oganization does not exist", comment:"")
        case .RECORD_MARKED_DELETED:
            return NSLocalizedString("Record is marked deleted and cannot be saved", comment:"")
        case .MISSING_OR_MISMATCHED_FIELD_METADATA:
            return NSLocalizedString("Field's metadata is missing or mismatched", comment:"")
        case .MISSING_OR_MISMATCHED_FIELD_OPTIONS:
            return NSLocalizedString("Field's options are missing or mismatched", comment:"")
        case .MISSING_OR_MISMATCHED_FIELD_OPTIONSET:
            return NSLocalizedString("Field's optionSet is missing or mismatched", comment:"")
        }
    }
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
    public static var mFirstTImeStages:Int = 0                          // -1=first time fully done; 1,2,... is the first time stage presently in; 0=stage 1 is needed
    public static var mDatabaseHandler:DatabaseHandler? = nil           // common pointer to the DatabaseHandler Object
    public static var mFieldHandler:FieldHandler? = nil                 // common pointer to the FieldHandler Object
    public static var mSVFilesHandler:SVFilesHandler? = nil             // common pointer to the SVFilesHandler Object
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
        
        // startup any App's Handlers and Coordinators, and perform first time setups if warranted;
        // errors are logged to error.log, and a user message stored within; errors will be reported to the end-user when the UI launches
        AppDelegate.mDatabaseHandler = DatabaseHandler()        // must create and initialize the database handler first
        let _ = AppDelegate.mDatabaseHandler!.initialize()
        AppDelegate.mFieldHandler = FieldHandler()
        let _ = AppDelegate.mFieldHandler!.initialize()
        AppDelegate.mSVFilesHandler = SVFilesHandler()
        let _ = AppDelegate.mSVFilesHandler!.initialize()
        if AppDelegate.mFirstTImeStages == 0 {
            do {
                try AppDelegate.mDatabaseHandler!.firstTimeSetup()
                try AppDelegate.mFieldHandler!.firstTimeSetup()
                try AppDelegate.mSVFilesHandler!.firstTimeSetup()
            } catch {}      // not reporting any errors to the end-user at this stage
        }
        
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
        AppDelegate.mSVFilesHandler!.shutdown()
        AppDelegate.mSVFilesHandler = nil
        AppDelegate.mFieldHandler!.shutdown()
        AppDelegate.mFieldHandler = nil
        AppDelegate.mDatabaseHandler!.shutdown()
        AppDelegate.mDatabaseHandler = nil
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
//debugPrint("\(AppDelegate.mCTAG).openURL STARTED PATH=\(url.path)")
        // is it the correct extension?
        if url.scheme != "file" { return false }
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
            } catch { return false }
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
        } catch {}  // not reporting any errors to the end-user at this stage
        
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
            } catch {}  // not reporting any errors to the end-user at this stage
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
        } catch {}
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
        } catch {}
        
        // were both found and consistent with each other?
        if lastOrgRec != nil && (lastFormRec?.isPartOfOrg(orgRec: lastOrgRec!) ?? false) == true {
            // yes, create or alter the mainline EntryFormProvisioner
            if AppDelegate.mEntryFormProvisioner == nil {
                // create the new mainline EntryFormProvisioner; must also send out a global notification this its been late-created
                AppDelegate.mEntryFormProvisioner = EntryFormProvisioner(forOrgRec: lastOrgRec!, forFormRec: lastFormRec!)
                NotificationCenter.default.post(name: .APP_CreatedMainEFP, object: nil)
            } else {
                // change the existing mainline EntryFormProvisioner; it will auto-notify those listening to it
                AppDelegate.mEntryFormProvisioner!.setBoth(orgRec: lastOrgRec!, formRec: lastFormRec!)
            }
            // remember the OrgRec and FormRec
            AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: lastOrgRec!.rOrg_Code_For_SV_File)
            AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm, value: lastFormRec!.rForm_Code_For_SV_File)
        } else if lastOrgRec != nil {
            // no, at least remember the OrgRec
            AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: lastOrgRec!.rOrg_Code_For_SV_File)
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
        } catch {}
    }
    
    // set and remember the specified Form or one that is found in the database
    public func setCurrentForm(toFormRec:RecOrgFormDefs?) {
//debugPrint("\(AppDelegate.mCTAG).setCurrentForm STARTED")
        var lastOrgRec:RecOrganizationDefs? = nil
        var lastFormRec:RecOrgFormDefs? = nil
        do {
            if toFormRec == nil {
                // being told to load the first or only Form that the remembered Org has
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
            } else {
                // being told to change to a specified Form
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
            
            // were both found and consistent with each other?
            if lastOrgRec != nil && (lastFormRec?.isPartOfOrg(orgRec: lastOrgRec!) ?? false) == true {
                // yes, create or alter the mainline EntryFormProvisioner
                if AppDelegate.mEntryFormProvisioner == nil {
                    // create the new mainline EntryFormProvisioner; must also send out a global notification this its been late-created
                    AppDelegate.mEntryFormProvisioner = EntryFormProvisioner(forOrgRec: lastOrgRec!, forFormRec: lastFormRec!)
                    NotificationCenter.default.post(name: .APP_CreatedMainEFP, object: nil)
                } else {
                    // change the existing mainline EntryFormProvisioner; it will auto-notify those listening to it
                    AppDelegate.mEntryFormProvisioner!.setBoth(orgRec: lastOrgRec!, formRec: lastFormRec!)
                }
                // remember the OrgRec and FormRec
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: lastOrgRec!.rOrg_Code_For_SV_File)
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm, value: lastFormRec!.rForm_Code_For_SV_File)
            } else if lastFormRec != nil {
                // no, at least remember the FormRec
                AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm, value: lastFormRec!.rForm_Code_For_SV_File)
            }
        } catch {}
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
    
    // reset everything during a factory reset
    public func resetCurrents() {
        AppDelegate.mEntryFormProvisioner = nil
        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastOrganization, value: nil)
        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.APP_LastForm, value: nil)
        NotificationCenter.default.post(name: .APP_CreatedMainEFP, object: nil)    // let all OrgTitle VCs and any other VCs know
    }
    
    ///////////////////////////////////////////////////////////////////
    // Methods related to preferences
    ///////////////////////////////////////////////////////////////////
    
    public static func doesPreferenceStringExist(prefKey:PreferencesKeys.Strings) -> Bool {
        if AppDelegate.mPrefsApp.object(forKey: prefKey.rawValue) != nil { return true }
        return false
    }
    public static func getPreferenceString(prefKey: PreferencesKeys.Strings) -> String? {
        return AppDelegate.mPrefsApp.string(forKey: prefKey.rawValue)
    }
    public static func setPreferenceString(prefKey: PreferencesKeys.Strings, value: String?) {
        AppDelegate.mPrefsApp.set(value, forKey: prefKey.rawValue)
    }
    public static func doesPreferenceIntExist(prefKey:PreferencesKeys.Ints) -> Bool {
        if AppDelegate.mPrefsApp.object(forKey: prefKey.rawValue) != nil { return true }
        return false
    }
    public static func getPreferenceInt(prefKey: PreferencesKeys.Ints) -> Int {
        return AppDelegate.mPrefsApp.integer(forKey: prefKey.rawValue)
    }
    public static func setPreferenceInt(prefKey: PreferencesKeys.Ints, value: Int?) {
        if value == nil { AppDelegate.mPrefsApp.set(nil, forKey: prefKey.rawValue) }
        else { AppDelegate.mPrefsApp.set(value, forKey: prefKey.rawValue) }
    }
    public static func doesPreferenceBoolExist(prefKey:PreferencesKeys.Bools) -> Bool {
        if AppDelegate.mPrefsApp.object(forKey: prefKey.rawValue) != nil { return true }
        return false
    }
    public static func getPreferenceBool(prefKey: PreferencesKeys.Bools) -> Bool {
        return AppDelegate.mPrefsApp.bool(forKey: prefKey.rawValue)
    }
    public static func setPreferenceBool(prefKey: PreferencesKeys.Bools, value: Bool?) {
        if value == nil { AppDelegate.mPrefsApp.set(nil, forKey: prefKey.rawValue) }
        else { AppDelegate.mPrefsApp.set(value, forKey: prefKey.rawValue) }
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
    public static func showAlertDialog(vc:UIViewController, title:String, during:String?=nil, errorStruct:Error, buttonText:String, completion:(() -> Void)?=nil) {
        var msg:String
        if !(during ?? "").isEmpty { msg = "\(during!): " + AppDelegate.endUserErrorMessage(errorStruct: errorStruct) }
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
            return "\(NSLocalizedString("Database found ErrCode", comment:""))=\(errorResult._code) \"\(errorResult.description)\""
        } else if type(of:errorStruct) == QueryError.self {
            // SQLite.swift query error
            let errorResult:QueryError = errorStruct as! QueryError
            return "\(NSLocalizedString("Database found ErrCode", comment:""))=\(errorResult._code) \"\(errorResult.description)\""
        } else if type(of:errorStruct) == APP_ERROR.self {
            // our App's errors
            let errorResult:APP_ERROR = errorStruct as! APP_ERROR
            var errorMessage:String = ""
            if errorResult.during != nil { errorMessage = errorMessage + "\(NSLocalizedString("During ", comment:"")) \(errorResult.during!) " }
            errorMessage = errorMessage + "\(errorResult.domain) \(NSLocalizedString("found ErrCode", comment:""))=\(errorResult.errorCode.rawValue) \"\(errorResult.errorCode.description)\""
            if !(errorResult.userErrorDetails ?? "").isEmpty { errorMessage = errorMessage + "; " + errorResult.userErrorDetails! }
            return errorMessage
        } else {
            // standard error
            return "\(errorStruct._domain) \(NSLocalizedString("found ErrCode", comment:""))=\(errorStruct._code) \"\(errorStruct.localizedDescription)\""
        }
    }
    
    // Thread Context: may be called from utility threads, so cannot perform UI actions
    // create an appropriate developer error string based upon the type of the ErrorType
    public static func developerErrorMessage(errorStruct:Error) -> String {
        if type(of:errorStruct) == Result.self {
            // SQLite.swift error
            let errorResult:Result = errorStruct as! Result
            return "SQLite Error: ErrCode=\(errorResult._code) \(errorResult.description)"
        } else if type(of:errorStruct) == QueryError.self {
            // SQLite.swift query error
            let errorResult:QueryError = errorStruct as! QueryError
            return "SQLite Query Error: ErrCode=\(errorResult._code) \(errorResult.description)"
        } else if type(of:errorStruct) == APP_ERROR.self {
            // our App's errors
            let errorResult:APP_ERROR = errorStruct as! APP_ERROR
            var errorMessage:String = "App Error: "
            if errorResult.during != nil { errorMessage = errorMessage + "During \(errorResult.during!) " }
            errorMessage = errorMessage + "\(errorResult.domain) ErrCode=\(errorResult.errorCode.rawValue) \"\(errorResult.errorCode.description)\""
            if !(errorResult.userErrorDetails ?? "").isEmpty { errorMessage = errorMessage + "; " + errorResult.userErrorDetails! }
            if !(errorResult.developerInfo ?? "").isEmpty { errorMessage = errorMessage + "; " + errorResult.developerInfo! }
            return errorMessage
        } else {
            // standard error
            var errorMessage = "Error: \(errorStruct._domain) ErrCode=\(errorStruct._code) \"\(errorStruct.localizedDescription)\""
            if errorStruct._userInfo != nil {
                errorMessage = errorMessage + " UserInfo:"
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
        self.postToErrorLogAndAlert_internal(method: method, during:nil, prefix:"EXCEPTION!", exception:exception, message:nil ,extra:extra, noAlert:false)
    }
    public static func postToErrorLogAndAlert(method:String?, during:String, errorStruct:Error, extra:String?, noAlert:Bool=false) {
        self.postToErrorLogAndAlert_internal(method:method, during:during, prefix:"ERROR!", exception:nil, message:AppDelegate.developerErrorMessage(errorStruct: errorStruct), extra:extra, noAlert:noAlert)
    }
    public static func postToErrorLogAndAlert(method:String?, during:String, errorMessage:String, extra:String? = nil, noAlert:Bool=false) {
        self.postToErrorLogAndAlert_internal(method: method, during:during, prefix:"ERROR!", exception:nil, message:errorMessage, extra:extra, noAlert:noAlert)
    }
    public static func noticeToErrorLogAndAlert(method:String?, during:String?, notice:String, extra:String? = nil, noAlert:Bool=false) {
        self.postToErrorLogAndAlert_internal(method: method, during:during, prefix:"NOTICE!", exception:nil, message:notice, extra:extra, noAlert:noAlert)
    }
    private static func postToErrorLogAndAlert_internal(method:String?, during:String?, prefix:String, exception:NSException?, message:String?, extra:String?, noAlert:Bool) {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        // show the error on the console
        var eMsg:String = prefix
        if !(method ?? "").isEmpty { eMsg = eMsg + " in \(method!)" }
        if !(during ?? "").isEmpty { eMsg = eMsg + " during \(during!)" }
        if !(extra ?? "").isEmpty { eMsg = eMsg + " [\(extra!)]" }
        if !(message ?? "").isEmpty { eMsg = eMsg + ": \(message!)" }

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
            if AppDelegate.mDatabaseHandler != nil {
                str = "DBHandler State \(AppDelegate.mDatabaseHandler!.mDBstatus_state), DBver \(AppDelegate.mDatabaseHandler!.getVersioning())\n"
            } else {
                str = "DBHandler = nil\n"
            }
            outputStream.write(str, maxLength:str.count)
            if AppDelegate.mFieldHandler != nil {
                str = "FieldHandler State \(AppDelegate.mFieldHandler!.mFHstatus_state)\n"
            } else {
                str = "FieldHandler = nil\n"
            }
            outputStream.write(str, maxLength:str.count)
            if AppDelegate.mSVFilesHandler != nil {
                str = "SVFileHandler State \(AppDelegate.mSVFilesHandler!.mSVHstatus_state)\n"
            } else {
                str = "SVFileHandler = nil\n"
            }
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
            outputStream.write("-----Thread-----\n", maxLength:17)
            
            // record the call stack into the error.log
            let stack:[String] = Thread.callStackSymbols
            for entry in stack {
                str = "\(entry)\n"
                outputStream.write(str, maxLength:str.count)
            }
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
    public static func postAlert(message:String) {
        if AppDelegate.mDatabaseHandler == nil || !(AppDelegate.mDatabaseHandler?.isReady() ?? false) {
            print("\(AppDelegate.mCTAG).postAlert Attempt to post an alert before the DatabaseHandler has been instantiated");
            return
        }
        
        let aRec = RecAlert(timestamp_ms_utc: AppDelegate.utcCurrentTimeMillis(), timezone_ms_utc_offset: AppDelegate.mDeviceTimezoneOffsetMS, message: message)
        do {
            let _ = try aRec.saveNewToDB()
        } catch {
            // errors will have already been logged; nothing else we can do about it
            return
        }
    }
}

