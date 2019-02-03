//
//  EmailHandler.swift
//  eContact Collect
//
//  Created by Dev on 1/29/19.
//

import Foundation
import MessageUI
import MobileCoreServices

/////////////////////////////////////////////////////////////////////////
// EmailVia class and its supporting structures
/////////////////////////////////////////////////////////////////////////

public struct AuthTypeDef {
    public var type:MCOAuthType
    public var typeStr:String
    public var typeStrLocalized:String
}
public struct ConnectionTypeDef {
    public var type:MCOConnectionType
    public var typeStr:String
    public var typeStrLocalized:String
}
public struct EmailAccountCredentials:Equatable {
    public var viaNameLocalized:String = ""
    public var username:String = ""
    public var password:String = ""

    init() {}
    
    init(localizedName:String, data:Data) {
        self.viaNameLocalized = localizedName
        if data.count > 0 {
            let str = String(data: data, encoding: String.Encoding.utf16)!
            let strComps = str.components(separatedBy: "\t")
            if strComps.count >= 2 { self.username = strComps[0]; self.password = strComps[1] }
            else { self.username = str }
        }
    }
    
    // encoded as <username> \t <password>
    public func data() -> Data? {
        if !self.valid() { return nil }
        return "\(self.username)\t\(self.password)".data(using: String.Encoding.utf16)
    }
    
    public func valid() -> Bool {
        if viaNameLocalized.isEmpty || username.isEmpty { return false }
        return true
    }
}
public struct EmailProviderSMTP:Equatable {
    public var viaNameLocalized:String = ""
    public var providerInternalName:String = ""
    public var hostname:String = ""
    public var port:Int = 0
    public var connectionType:MCOConnectionType = .clear
    public var authType:MCOAuthType = .saslPlain
    
    init() {}
    
    init(viaNameLocalized:String, providerInternalName:String, hostname:String, port:Int, connectionType:MCOConnectionType, authType:MCOAuthType) {
        self.viaNameLocalized = viaNameLocalized
        self.providerInternalName = providerInternalName
        self.hostname = hostname
        self.port = port
        self.connectionType = connectionType
        self.authType = authType
    }
    
    init?(localizedName:String, knownProviderInternalName:String) {
        for provider in EmailHandler.knownSMTPEmailProviders {
            if provider.providerInternalName == knownProviderInternalName {
                self.viaNameLocalized = localizedName
                self.providerInternalName = provider.providerInternalName
                self.hostname = provider.hostname
                self.port = provider.port
                self.connectionType = provider.connectionType
                self.authType = provider.authType
                return
            }
        }
        return nil
    }
}
public class EmailVia {
    public var viaNameLocalized:String = NSLocalizedString("iOS Mail App", comment:"")
    public var viaType:ViaType = .API
    public var unsecuredCredentials:Bool = false
    public var emailProvider_InternalName:String = "iOSMail"
    public var userDisplayName:String = ""
    public var sendingEmailAddress:String = ""
    public var emailProvider_SMTP:EmailProviderSMTP? = nil
    public var emailProvider_Credentials:EmailAccountCredentials? = nil
    
    // EmailVia types:  Stored can only be used when stored in OrgRec or FormRec
    public enum ViaType: Int {
        case None = 0, Stored = 1, API = 2, SMTPknown = 3, SMTPsettings = 4
    }
    
    // create a default instance which is the iOS Mail App API
    init() {}
    
    // create an empty instance
    init(viaLocalizedName:String) {
        self.viaNameLocalized = viaLocalizedName
        self.viaType = .None
    }
    
    // create an instance from an encoded string
    init(fromEncode:String?, fromCredentials: Data?) {
        self.decode(fromEncode: fromEncode, fromCredentials: fromCredentials)
    }
    
    // create an instance from a known SMTP Email Provider
    init(fromSMTPProvider:EmailProviderSMTP) {
        self.viaNameLocalized = fromSMTPProvider.viaNameLocalized
        self.viaType = .SMTPknown
        self.emailProvider_InternalName = fromSMTPProvider.providerInternalName
        self.emailProvider_SMTP = fromSMTPProvider
    }
    
    // duplicate an instance (deep copy)
    init(fromExisting:EmailVia) {
        self.viaNameLocalized = fromExisting.viaNameLocalized
        self.viaType = fromExisting.viaType
        self.unsecuredCredentials = fromExisting.unsecuredCredentials
        self.emailProvider_InternalName = fromExisting.emailProvider_InternalName
        self.userDisplayName = fromExisting.userDisplayName
        self.sendingEmailAddress = fromExisting.sendingEmailAddress
        self.emailProvider_SMTP = fromExisting.emailProvider_SMTP   // structure auto-deep copies
        self.emailProvider_Credentials = fromExisting.emailProvider_Credentials // structure auto-deep copies
    }
    
    // create an encoded string
    // encode formats:
    //   <localizedName> \t stored
    //   <localizedName> \t api \t api : <api>
    //   <localizedName> \t smtpKnown \t from : <displayName> : <email> \t knownProvider : <providerInternalName>
    //   <localizedName> \t smtpSet \t from : <displayName> : <email> \t settings : <hostName> : <port> : <connectType> : <authType>
    //   <localizedName> \t smtpSet \t from : <displayName> : <email> \t settings : <hostName> : <port> : <connectType> : <authType> \t credentials : <userID> : <password>
    //   <localizedName> \t appScheme \t ??FUTURE
    public func encode() -> String? {
        switch self.viaType {
        case .None:
            return nil
        case .Stored:
            return "\(self.viaNameLocalized)\tstored"
        case .API:
            return "\(self.viaNameLocalized)\tapi\tapi:\(self.emailProvider_InternalName)"
        case .SMTPknown:
            return "\(self.viaNameLocalized)\tsmtpKnown\tfrom:\(self.userDisplayName):\(self.sendingEmailAddress)\tknownProvider:\(self.emailProvider_InternalName)"
        case .SMTPsettings:
            var result = "\(self.viaNameLocalized)\tsmtpSet\tfrom:\(self.userDisplayName):\(self.sendingEmailAddress)"
            if self.emailProvider_SMTP != nil {
                result = result + "\tsettings:\(self.emailProvider_SMTP!.hostname):\(self.emailProvider_SMTP!.port)"
                for aConnTypeDef in EmailHandler.connectionTypeDefs {
                    if self.emailProvider_SMTP!.connectionType == aConnTypeDef.type {
                        result = result  + ":" + aConnTypeDef.typeStr
                        break
                    }
                }
                for anAuthType in EmailHandler.authTypeDefs {
                    if self.emailProvider_SMTP!.authType == anAuthType.type {
                        result = result  + ":" + anAuthType.typeStr
                        break
                    }
                }
            }
            if self.unsecuredCredentials && self.emailProvider_Credentials != nil {
                if self.emailProvider_Credentials!.valid() {
                    result = result + "\tcredentials:\(self.emailProvider_Credentials!.username):\(self.emailProvider_Credentials!.password)"
                }
            }
            return result
        }
    }
    
    // update this instance with the decoded information
    public func decode(fromEncode:String?, fromCredentials: Data?) {
        if fromEncode == nil { return }
        
        // decode the bulk of the via
        let encodeComps:[String] = fromEncode!.components(separatedBy: "\t")
        var inx:Int = 0
        for comp in encodeComps {
            if inx == 0 {
                self.viaNameLocalized = comp
            } else if inx == 1 {
                switch comp {
                case "stored":
                    self.viaType = .Stored
                    break
                case "api":
                    self.viaType = .API
                    break
                case "smtpKnown":
                    self.viaType = .SMTPknown
                    break
                case "smtpSet":
                    self.viaType = .SMTPsettings
                    break
                default:
                    // ???
                    break
                }
            } else {
                let elements:[String] = comp.components(separatedBy: ":")
                switch elements[0] {
                case "api":
                    if self.viaType != .API || elements.count < 2 { }
                    self.emailProvider_InternalName = elements[1]
                    break
                case "knownProvider":
                    if self.viaType != .SMTPknown || elements.count < 2 { }
                    self.emailProvider_InternalName = elements[1]
                    break
                case "from":
                    if (self.viaType != .SMTPknown && self.viaType != .SMTPsettings) || elements.count < 3 { }
                    self.userDisplayName = elements[1]
                    self.sendingEmailAddress = elements[2]
                    break
                case "settings":
                    if self.viaType != .SMTPsettings || elements.count < 5 { }
                    if self.emailProvider_SMTP == nil { self.emailProvider_SMTP = EmailProviderSMTP() }
                    self.emailProvider_SMTP!.viaNameLocalized = self.viaNameLocalized
                    self.emailProvider_SMTP!.providerInternalName = ""
                    self.emailProvider_SMTP!.hostname = elements[1]
                    self.emailProvider_SMTP!.port = Int(elements[2]) ?? 0
                    for aConnTypeDef in EmailHandler.connectionTypeDefs {
                        if elements[3] == aConnTypeDef.typeStr {
                            self.emailProvider_SMTP!.connectionType = aConnTypeDef.type
                            break
                        }
                    }
                    for anAuthType in EmailHandler.authTypeDefs {
                        if elements[4] == anAuthType.typeStr {
                            self.emailProvider_SMTP!.authType = anAuthType.type
                            break
                        }
                    }
                    break
                case "credentials":
                    if self.viaType != .SMTPsettings || elements.count < 3 { }
                    if self.emailProvider_Credentials == nil { self.emailProvider_Credentials = EmailAccountCredentials() }
                    self.emailProvider_Credentials!.viaNameLocalized = self.viaNameLocalized
                    self.emailProvider_Credentials!.username = elements[1]
                    self.emailProvider_Credentials!.password = elements[2]
                    break
                default:
                    // ???
                    break
                }
            }
            inx = inx + 1
        }
        
        // now decode the credentials if supplied
        if fromCredentials != nil {
            self.emailProvider_Credentials = EmailAccountCredentials(localizedName: self.viaNameLocalized, data: fromCredentials!)
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// Main class that handles sending Emails
/////////////////////////////////////////////////////////////////////////

// define the delegate protocol that other portions of the App must use to know the final result of a sent email
public protocol HEM_Delegate {
    func completed_HEM(tagI:Int, tagS:String?, result:EmailHandler.EmailHandlerResults, error:APP_ERROR?)
    func logger_HEM(tagI:Int, tagS:String?, result:EmailHandler.EmailHandlerResults, error:APP_ERROR?)
}

// base handler class for sending emails
public class EmailHandler:NSObject, MFMailComposeViewControllerDelegate {
    // member variables
    public var mEMHstatus_state:HandlerStatusStates = .Unknown
    public var mAppError:APP_ERROR? = nil
    
    // member constants and other static content
    internal var mCTAG:String = "HEM"
    internal var mThrowErrorDomain:String = NSLocalizedString("Email-Handler", comment:"")
    
    public enum EmailHandlerResults: Int {
        case Cancelled = 0, Error = 1, Saved = 2, Sent = 3
    }
    
    public static var knownSMTPEmailProviders:[EmailProviderSMTP] = [
        // Google GMail - "less secure" access; username is full gmail email address
        // https://support.google.com/mail/answer/7126229?hl=en
        // https://support.google.com/accounts/answer/6010255
        EmailProviderSMTP(viaNameLocalized: NSLocalizedString("Gmail legacy", comment:""), providerInternalName: "Gmail legacy", hostname: "smtp.gmail.com", port: 465, connectionType: MCOConnectionType.TLS, authType: MCOAuthType.saslPlain),
        
        // Yahoo Mail - "less secure" access; username is full yahoo email address
        // https://help.yahoo.com/kb/pop-settings-sln4724.html
        // https://help.yahoo.com/kb/SLN3792.html
        EmailProviderSMTP(viaNameLocalized: NSLocalizedString("Yahoo legacy", comment:""), providerInternalName: "Yahoo legacy", hostname: "smtp.mail.yahoo.com", port: 465, connectionType: MCOConnectionType.TLS, authType: MCOAuthType.saslPlain)
    ]
    
    public static var connectionTypeDefs:[ConnectionTypeDef] = [
        ConnectionTypeDef(type: .clear, typeStr: "clear", typeStrLocalized: NSLocalizedString("Clear", comment:"")),
        ConnectionTypeDef(type: .startTLS, typeStr: "startTLS", typeStrLocalized: NSLocalizedString("Start-TLS", comment:"")),
        ConnectionTypeDef(type: .TLS, typeStr: "TLS", typeStrLocalized: NSLocalizedString("TLS", comment:""))
    ]
    public static var authTypeDefs:[AuthTypeDef] = [
        AuthTypeDef(type: .SASLCRAMMD5, typeStr: "crammd5", typeStrLocalized: NSLocalizedString("SASL CRAM MD5", comment:"")),
        AuthTypeDef(type: .saslPlain, typeStr: "plain", typeStrLocalized: NSLocalizedString("SASL Plain", comment:"")),
        AuthTypeDef(type: .SASLGSSAPI, typeStr: "GSSAPI", typeStrLocalized: NSLocalizedString("SASL GSSAPI", comment:"")),
        AuthTypeDef(type: .SASLDIGESTMD5, typeStr: "DigestMD5", typeStrLocalized: NSLocalizedString("SASL Digest MD5", comment:"")),
        AuthTypeDef(type: .saslLogin, typeStr: "Login", typeStrLocalized: NSLocalizedString("SASL Login", comment:"")),
        AuthTypeDef(type: .SASLSRP, typeStr: "SRP", typeStrLocalized: NSLocalizedString("SASL SRP", comment:"")),
        AuthTypeDef(type: .SASLNTLM, typeStr: "NTLM", typeStrLocalized: NSLocalizedString("SASL NTLM", comment:"")),
        AuthTypeDef(type: .saslKerberosV4, typeStr: "KerberosV4", typeStrLocalized: NSLocalizedString("SASL Kerberos-V4", comment:"")),
        AuthTypeDef(type: .xoAuth2, typeStr: "OAuth2", typeStrLocalized: NSLocalizedString("OAuth2", comment:"")),
        AuthTypeDef(type: .xoAuth2Outlook, typeStr: "OAuth2Outlook", typeStrLocalized: NSLocalizedString("OAuth2 Outlook.com", comment:""))
    ]

    // initialization; returns true if initialize fully succeeded;
    // errors are stored via the class members and will already be posted to the error.log;
    // this handler must be mindful that the database initialization may have failed
    public func initialize(method:String) -> Bool {
//debugPrint("\(mCTAG).initialize STARTED")
        // ???
        self.mEMHstatus_state = .Valid
        return true
    }
    
    // perform any handler first time setups that have not already been performed; the sequence# allows later versions to retro-add a first-time setup;
    // this handler must be mindful that if it or the database handler may not have properly initialized that this should be bypassed;
    // errors are stored via the class members and will already be posted to the error.log
    public func firstTimeSetup(method:String) {
//debugPrint("\(mCTAG).firstTimeSetup STARTED")
        if AppDelegate.getPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Handler_Email_FirstTime_Done) != 1 {
            do {
                try self.storeEmailVia(via: EmailVia())     // store the iOS Mail App as a possible Email provider
                AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Handler_Email_FirstTime_Done, value: 1)
            } catch {
                self.mEMHstatus_state = .Errors
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).firstTimeSetup", domain: self.mThrowErrorDomain, error: error, errorCode: .INTERNAL_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""))
            }
        }
    }
    
    // return whether the handler is fully operational
    public func isReady() -> Bool {
        if self.mEMHstatus_state == .Valid { return true }
        return false
    }
    
    // this will not get called during normal App operation, but does get called during Unit and UI Testing
    // perform any shutdown that may be needed
    internal func shutdown() {
        self.mEMHstatus_state = .Unknown
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    // public methods
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // set the end-users preferred default EmailVia
    public func setLocalizedDefaultEmail(localizedName:String) {
        AppDelegate.setPreferenceString(prefKey: PreferencesKeys.Strings.EmailVia_Default_Name, value: localizedName)
    }
    
    // provide the current default email provider's localized name; no credentials are accessed
    public func getLocalizedDefaultEmail() -> String {
        let defaultViaLocalizedName:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.EmailVia_Default_Name)
        let viaEncodeKeys:[String] = AppDelegate.getAllPreferenceKeys(keyPrefix: PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue)
        if viaEncodeKeys.isEmpty {
            // no stored EmailVia's
            return EmailVia().viaNameLocalized   // default to the iOS Mail App
        } else if viaEncodeKeys.count == 1 || (defaultViaLocalizedName ?? "").isEmpty {
            // use the first/only stored EmailVia
            let size:Int = viaEncodeKeys[0].count - PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue.count
            return String(viaEncodeKeys[0].suffix(size))
        }
        
        // get the specified default EmailVia
        let workingKey = PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue + defaultViaLocalizedName!
        for viaLocalizedName in viaEncodeKeys {
            if viaLocalizedName == workingKey { return defaultViaLocalizedName! }
        }
        
        // default could not be found; use the first stored
        let size:Int = viaEncodeKeys[0].count - PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue.count
        return String(viaEncodeKeys[0].suffix(size))
    }
    
    // provide a list of all stored email provider's localized names
    public func getListEmailOptions() -> [EmailVia] {
        let viaEncodeKeys:[String] = AppDelegate.getAllPreferenceKeys(keyPrefix: PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue)
        if viaEncodeKeys.isEmpty {
            // no stored EmailVia
            return [EmailVia()]   // default to the iOS Mail App
        }
        
        var result:[EmailVia] = []
        for viaKey in viaEncodeKeys {
            let len:Int = viaKey.count - PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue.count
            let via:EmailVia? = self.getStoredEmailViaNoCredentials(localizedName: String(viaKey.suffix(len)))
            if via != nil { result.append(via!) }
        }
        return result
    }
    
    // provide a list of all stored email provider's localized names
    public func getListPotentialEmailProviders() -> [EmailVia] {
        var result:[EmailVia] = [EmailVia()]    // always include the iOS Mail App
        
        for providerSMTP in EmailHandler.knownSMTPEmailProviders {
            result.append(EmailVia(fromSMTPProvider: providerSMTP))
        }
        
        // always include an open SMTP provider
        let lastVia:EmailVia = EmailVia(viaLocalizedName: NSLocalizedString("Other SMTP Email Provider", comment:""))
        lastVia.viaType = .SMTPsettings
        lastVia.emailProvider_InternalName = "$Other"
        result.append(lastVia)
        return result
    }
    
    // store an EmailVia is the proper storage respositories
    public func storeEmailVia(via:EmailVia) throws {
        // store the bulk of the EmailVia in the preferences
        let key:String = PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue + via.viaNameLocalized
        AppDelegate.setPreferenceString(prefKeyString: key, value: via.encode())
        
        // store the userid and password in the secure store
        if via.emailProvider_Credentials != nil, via.emailProvider_Credentials!.valid() {
            do {
                try AppDelegate.storeSecureItem(key: via.viaNameLocalized, label: "Email", data: via.emailProvider_Credentials!.data()!)
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: "\(self.mCTAG).storeEmailVia")
                throw appError
            } catch { throw error }
        }
    }
    
    // check whether the stored EmailVia already exists
    public func storedEmailViaExists(localizedName:String) -> Bool {
        let key:String = PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue + localizedName
        let encodedVia:String? = AppDelegate.getPreferenceString(prefKeyString: key)
        if encodedVia == nil { return false }
        return true
    }
    
    // retrieve an EmailVia from the proper storage respositories
    public func getStoredEmailViaNoCredentials(localizedName:String) -> EmailVia? {
        // get the bulk of the EmailVia from the preferences
        let key:String = PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue + localizedName
        let encodedVia:String? = AppDelegate.getPreferenceString(prefKeyString: key)
        if encodedVia == nil { return nil }
        return EmailVia(fromEncode: encodedVia, fromCredentials: nil)
    }
    
    // retrieve an EmailVia from the proper storage respositories
    private func getStoredEmailViaWithCredentials(localizedName:String) throws -> EmailVia? {
        // get the bulk of the EmailVia from the preferences
        let key:String = PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue + localizedName
        let encodedVia:String? = AppDelegate.getPreferenceString(prefKeyString: key)
        if encodedVia == nil { return nil }
        
        // get the userid and password from the secure store
        var encodedCred:Data? = nil
        do {
            encodedCred = try AppDelegate.retrieveSecureItem(key: localizedName, label: "Email")
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getStoredEmailVia")
            throw appError
        } catch { throw error }
        
        return EmailVia(fromEncode: encodedVia, fromCredentials: encodedCred)
    }
    
    // send an email to the developer, optionally including an attachment;
    // initial errors are thrown; email subsystem result success/error is returned via callback
    public func sendEmailToDeveloper(vc:UIViewController, tagI:Int, tagS:String?, delegate:HEM_Delegate?, localizedTitle:String, subject:String?, body:String?, includingAttachment:URL?) throws {
        do {
            try sendEmail(vc: vc, tagI: tagI, tagS: tagS, delegate: delegate, localizedTitle: localizedTitle, via: nil, to: AppDelegate.mDeveloperEmailAddress, cc: nil, subject: subject, body: body, includingAttachment: includingAttachment)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).sendEmailToDeveloper")
            throw appError
        } catch { throw error }
    }

    // send an email, optionally including an attachment;
    // initial errors are thrown; email subsystem result success/error is returned via callback
    public func sendEmail(vc:UIViewController, tagI:Int, tagS:String?, delegate:HEM_Delegate?, localizedTitle:String, via:EmailVia?, to:String?, cc:String?, subject:String?, body:String?, includingAttachment:URL?) throws {
        
        // determine the attachment mime type
        var mimeType = "text/plain"
        if includingAttachment != nil {
            let extString = includingAttachment!.pathExtension
            switch extString {
            case "txt":
                mimeType = "text/tab-separated-values"
                break
            case "csv":
                mimeType = "text/csv"
                break
            case "xml":
                mimeType = "text/xml"
                break
            default:
                break
            }
        }
        
        // determine which EmailVia to use, and expand out the EmailVia with all necessary values
        var usingVia:EmailVia
        do {
            if via == nil {
                // none provided so use the default
                usingVia = try self.getDefaultStoredViaWithCredentials()
            } else if via!.viaType == .None {
                // none provided so use the default
                usingVia = try self.getDefaultStoredViaWithCredentials()
            } else if via!.viaType == .Stored {
                // lookup the indicated stored EmailVia including the securely stored credentials
                let tempVia:EmailVia? = try self.getStoredEmailViaWithCredentials(localizedName: via!.viaNameLocalized)
                if tempVia == nil {
                    throw APP_ERROR(funcName: "\(self.mCTAG).sendEmail", domain: self.mThrowErrorDomain, errorCode: .MISSING_SAVED_EMAIL_ACCOUNT, userErrorDetails: via!.viaNameLocalized)
                }
                usingVia = tempVia!
            } else {
                // directly use the provided EmailVia
                usingVia = via!
            }
            if usingVia.viaType == .SMTPknown {
                // fill in the standard provider information
                let provider:EmailProviderSMTP? = EmailProviderSMTP(localizedName: via!.viaNameLocalized, knownProviderInternalName: via!.emailProvider_InternalName)
                if provider == nil {
                    throw APP_ERROR(funcName: "\(self.mCTAG).sendEmail", domain: self.mThrowErrorDomain, errorCode: .MISSING_KNOWN_EMAIL_PROVIDER, userErrorDetails: "\(via!.viaNameLocalized) -> \(via!.emailProvider_InternalName)")
                }
                usingVia.emailProvider_SMTP = provider
            }
            if (usingVia.viaType == .SMTPknown || usingVia.viaType == .SMTPsettings) && usingVia.emailProvider_Credentials == nil {
                // fill in any secured credentials
                let encodedCred:Data? = try AppDelegate.retrieveSecureItem(key: via!.viaNameLocalized, label: "Email")
                if encodedCred == nil {
                    throw APP_ERROR(funcName: "\(self.mCTAG).sendEmail", domain: self.mThrowErrorDomain, errorCode: .MISSING_EMAIL_ACCOUNT_CREDENTIALS, userErrorDetails: via!.viaNameLocalized)
                }
                usingVia.emailProvider_Credentials = EmailAccountCredentials(localizedName: via!.viaNameLocalized, data: encodedCred!)
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).sendEmail")
            throw appError
        } catch { throw error }
        

        // determine how to send the email from the usingVia
        do {
            switch usingVia.viaType {
            case .None:
                // ??? this should not occur since it was resolved above
                break
            case .Stored:
                // ??? this should not occur since it was resolved above
                break
            case .API:
                // presently the only allowed API is the iOS provided API for the Apple Mail App
                try sendEmailViaAppleMailApp(vc: vc, tagI: tagI, tagS: tagS, delegate: delegate, localizedTitle: localizedTitle, to: to, cc: cc, subject: subject, body: body, includingAttachment: includingAttachment, mimeType: mimeType)
                break
            case .SMTPknown:
                // send using SMTP via a known provider; provider settings and secure credentials have already been obtained
                try sendEmailViaMailCore(vc: vc, tagI: tagI, tagS: tagS, delegate: delegate, localizedTitle: localizedTitle, via: usingVia, to: to, cc: cc, subject: subject, body: body, includingAttachment: includingAttachment, mimeType: mimeType)
                break
            case .SMTPsettings:
                // send using SMTP with providied settings; secure credentials have already been obtained
                try sendEmailViaMailCore(vc: vc, tagI: tagI, tagS: tagS, delegate: delegate, localizedTitle: localizedTitle, via: usingVia, to: to, cc: cc, subject: subject, body: body, includingAttachment: includingAttachment, mimeType: mimeType)
                break
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).sendEmail")
            throw appError
        } catch { throw error }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // private methods
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // get the default stored via, or force the iOS Mail App via
    // case EmailVia_Stored_Named = "emailVia_stored_named_"   // storage of one or more EmailVia as set by the Collector
    // case EmailVia_Default_Name = "emailVia_default_name"    // the name of the default EmailVia as chosen by the Collector
    // if !AppDelegate.doesPreferenceIntExist(prefKey: PreferencesKeys.Ints.APP_FirstTime) { AppDelegate.mFirstTImeStages = 0 }
    // else { AppDelegate.mFirstTImeStages = AppDelegate.getPreferenceInt(prefKey: PreferencesKeys.Ints.APP_FirstTime) }
    private func getDefaultStoredViaWithCredentials() throws -> EmailVia {
        let defaultViaLocalizedName:String? = AppDelegate.getPreferenceString(prefKey: PreferencesKeys.Strings.EmailVia_Default_Name)
        let viaEncodeKeys:[String] = AppDelegate.getAllPreferenceKeys(keyPrefix: PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue)
        if viaEncodeKeys.isEmpty {
            // no stored EmailVia
            return EmailVia()   // default to the iOS Mail App
        } else if viaEncodeKeys.count == 1 || (defaultViaLocalizedName ?? "").isEmpty {
            // use the first/only stored EmailVia
            let size:Int = viaEncodeKeys[0].count - PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue.count
            do {
                return try getStoredEmailViaWithCredentials(localizedName: String(viaEncodeKeys[0].suffix(size)))!
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: "\(self.mCTAG).getDefaultStoredViaWithCredentials")
                throw appError
            } catch { throw error }
        }
        
        // get the specified default EmailVia
        let workingKey = PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue + defaultViaLocalizedName!
        for viaLocalizedName in viaEncodeKeys {
            if viaLocalizedName == workingKey {
                let size:Int = viaLocalizedName.count - PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue.count
                do {
                    return try self.getStoredEmailViaWithCredentials(localizedName: String(viaLocalizedName.suffix(size)))!
                } catch var appError as APP_ERROR {
                    appError.prependCallStack(funcName: "\(self.mCTAG).getDefaultStoredViaWithCredentials")
                    throw appError
                } catch { throw error }
            }
        }
        
        // default could not be found; use the first stored
        let size:Int = viaEncodeKeys[0].count - PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue.count
        do {
            return try self.getStoredEmailViaWithCredentials(localizedName: String(viaEncodeKeys[0].suffix(size)))!
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getDefaultStoredViaWithCredentials")
            throw appError
        } catch { throw error }
    }

    // send the email using the iOS Mail App
    private func sendEmailViaAppleMailApp(vc:UIViewController, tagI:Int, tagS:String?, delegate:HEM_Delegate?, localizedTitle:String, to:String?, cc:String?, subject:String?, body:String?, includingAttachment:URL?, mimeType:String) throws {
//debugPrint("\(self.mCTAG).sendEmailViaAppleMailApp STARTED")
        
        // build up the needed to/cc arrays
        var emailToArray:[String] = []
        var emailCCArray:[String] = []
        if !(to ?? "").isEmpty {
            emailToArray = to!.components(separatedBy: ",")
        }
        if !(cc ?? "").isEmpty {
            emailCCArray = cc!.components(separatedBy: ",")
        }

        // validate the iOS Mail subsystem
        if !MFMailComposeViewController.canSendMail() {
            throw APP_ERROR(funcName: "\(self.mCTAG).sendEmailViaAppleMailApp", during: "MFMailComposeViewController.canSendMail()", domain: self.mThrowErrorDomain, errorCode: .IOS_EMAIL_SUBSYSTEM_DISABLED, userErrorDetails: nil)
        }
        
        // invoke the iOS Mail compose subsystem
        let mailVC = MFMailComposeViewControllerExt()
        mailVC.mailComposeDelegate = self
        mailVC.tagI = tagI
        mailVC.tagS = tagS
        mailVC.delegateHEM = delegate
        mailVC.title = localizedTitle
        if !(to ?? "").isEmpty { mailVC.setToRecipients(emailToArray) }
        if !(cc ?? "").isEmpty { mailVC.setCcRecipients(emailCCArray) }
        if !(subject ?? "").isEmpty { mailVC.setSubject(subject!) }
        if !(body ?? "").isEmpty { mailVC.setMessageBody(body!, isHTML: false) }
        if includingAttachment != nil {
            let fileName:String = includingAttachment!.lastPathComponent
            let fileData:Data = FileManager.default.contents(atPath: includingAttachment!.path)!
            mailVC.addAttachmentData(fileData, mimeType: mimeType, fileName: fileName)
        }
        vc.present(mailVC, animated: true, completion: nil)
    }
    
    // callback from iOS Mail App indicating rejection or success
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//debugPrint("\(self.mCTAG).mailComposeController.didFinishWith for \(controller.title!)")
        if let controllerHEM:MFMailComposeViewControllerExt = controller as? MFMailComposeViewControllerExt {
            if controllerHEM.delegateHEM != nil {
                var errorHEM:APP_ERROR? = nil
                var resultHEM:EmailHandler.EmailHandlerResults
                if error != nil {
                    errorHEM = APP_ERROR(funcName: "\(self.mCTAG).mailComposeController.didFinishWith", domain: self.mThrowErrorDomain, error: error!, errorCode: .IOS_EMAIL_SUBSYSTEM_ERROR, userErrorDetails: nil)
                    resultHEM = .Error
                } else {
                    switch result {
                    case .cancelled:
                        resultHEM = .Cancelled
                        break
                    case .failed:
                        resultHEM = .Error
                        break
                    case .saved:
                        resultHEM = .Saved
                        break
                    case .sent:
                        resultHEM = .Sent
                        break
                    }
                }
                controllerHEM.delegateHEM!.completed_HEM(tagI: controllerHEM.tagI, tagS: controllerHEM.tagS, result: resultHEM, error: errorHEM)
                controller.dismiss(animated: true, completion: nil)
                return
            }
        }
        if error != nil {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mailComposeController.didFinishWith.noDelegate", errorStruct: error!, extra: nil)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    // send the email via SMTP using MailCore
    private func sendEmailViaMailCore(vc:UIViewController, tagI:Int, tagS:String?, delegate:HEM_Delegate?, localizedTitle:String, via:EmailVia, to:String?, cc:String?, subject:String?, body:String?, includingAttachment:URL?, mimeType:String) throws {
debugPrint("\(self.mCTAG).sendEmailViaMailCore STARTED")
        if !(to ?? "").isEmpty && !(cc ?? "").isEmpty {
            throw APP_ERROR(funcName: "\(self.mCTAG).sendEmailViaMailCore", domain: self.mThrowErrorDomain, errorCode: .EMAIL_NO_TO_AND_CC, userErrorDetails: nil)
        }
        
        // build up the needed to/cc arrays
        var emailToArray:[MCOAddress] = []
        var emailCCArray:[MCOAddress] = []
        if !(to ?? "").isEmpty {
            let emails:[String] = to!.components(separatedBy: ",")
            for email in emails {
                emailToArray.append(MCOAddress(displayName: email, mailbox: email))
            }
        }
        if !(cc ?? "").isEmpty {
            let emails:[String] = cc!.components(separatedBy: ",")
            for email in emails {
                emailCCArray.append(MCOAddress(displayName: email, mailbox: email))
            }
        }
        
        // build the email
        let builder = MCOMessageBuilder()
        if !(to ?? "").isEmpty { builder.header.to = emailToArray }
        if !(cc ?? "").isEmpty { builder.header.cc = emailCCArray }
        if !via.userDisplayName.isEmpty {
            builder.header.from = MCOAddress(displayName: via.userDisplayName, mailbox: via.sendingEmailAddress)
        } else {
            builder.header.from = MCOAddress(mailbox: via.sendingEmailAddress)
        }
        if !(subject ?? "").isEmpty { builder.header.subject = subject! }
        if !(body ?? "").isEmpty { builder.textBody = body! }
        
        if includingAttachment != nil {
            let fileName:String = includingAttachment!.lastPathComponent
            let withData:Data? = FileManager.default.contents(atPath: includingAttachment!.path)
            if withData != nil {
                let attachment = MCOAttachment(data: withData!, filename: fileName)
                if attachment != nil {
                    attachment!.mimeType =  mimeType
                    builder.addAttachment(attachment!)
                }
            }
        }

        // open a connection to the email server
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = via.emailProvider_SMTP!.hostname
        smtpSession.port = UInt32(via.emailProvider_SMTP!.port)
        smtpSession.authType =  via.emailProvider_SMTP!.authType
        smtpSession.connectionType = via.emailProvider_SMTP!.connectionType
        smtpSession.username = via.emailProvider_Credentials?.username
        smtpSession.password = via.emailProvider_Credentials?.password
        smtpSession.connectionLogger = {(connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
debugPrint("\(self.mCTAG).sendEmailViaMailCore.Connectionlogger: \(string)")
                }
            }
        }
        
        // send the email; is automatically performed in background thread then callback with results
        let rfc822Data = builder.data()
        let sendOperation = smtpSession.sendOperation(with: rfc822Data!)
        sendOperation?.start { (error) -> Void in
            // ???
            if (error != nil) {
debugPrint("\(self.mCTAG).sendEmailViaMailCore Error sending email: \(error!)")
            } else {
debugPrint("\(self.mCTAG).sendEmailViaMailCore Successfully sent email!")
            }
        }
    }
    
    // test the email connection and credentials via SMTP using MailCore
    public func testEmailViaMailCore(vc:UIViewController, tagI:Int, tagS:String?, delegate:HEM_Delegate?, via:EmailVia) throws {
debugPrint("\(self.mCTAG).testEmailViaMailCore STARTED")
        
        // build the from address
        var from:MCOAddress
        if !via.userDisplayName.isEmpty {
            from = MCOAddress(displayName: via.userDisplayName, mailbox: via.sendingEmailAddress)
        } else {
            from = MCOAddress(mailbox: via.sendingEmailAddress)
        }
        
        // open a connection to the email server
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = via.emailProvider_SMTP!.hostname
        smtpSession.port = UInt32(via.emailProvider_SMTP!.port)
        smtpSession.authType =  via.emailProvider_SMTP!.authType
        smtpSession.connectionType = via.emailProvider_SMTP!.connectionType
        smtpSession.username = via.emailProvider_Credentials?.username
        smtpSession.password = via.emailProvider_Credentials?.password
        smtpSession.connectionLogger = {(connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                    debugPrint("\(self.mCTAG).testEmailViaMailCore.Connectionlogger: \(string)")
                }
            }
        }
        
        // test the connection
        let testOperation = smtpSession.checkAccountOperationWith(from: from)
        testOperation?.start { (error) -> Void in
            // ???
            if (error != nil) {
                debugPrint("\(self.mCTAG).testEmailViaMailCore Error sending email: \(error!)")
            } else {
                debugPrint("\(self.mCTAG).testEmailViaMailCore Successfully sent email!")
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// class extension of MFMailComposeViewController
/////////////////////////////////////////////////////////////////////////

// extend the MFMailComposeViewController class to store some needed callback members
public class MFMailComposeViewControllerExt:MFMailComposeViewController {
    // preset members by invoker
    var tagI:Int = 0
    var tagS:String? = nil
    var delegateHEM:HEM_Delegate? = nil
}
