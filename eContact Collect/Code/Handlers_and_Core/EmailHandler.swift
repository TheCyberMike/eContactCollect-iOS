//
//  EmailHandler.swift
//  eContact Collect
//
//  Created by Dev on 1/29/19.
//

import Foundation
import MessageUI
import MobileCoreServices
import OAuthSwift

/////////////////////////////////////////////////////////////////////////
// EmailVia class and its supporting structures
/////////////////////////////////////////////////////////////////////////

// struct for an array to store AuthType definitions
public struct AuthTypeDef {
    public var type:MCOAuthType
    public var typeStr:String
    public var typeStrLocalized:String
}
// struct for an array to store ConnectionType definitions
public struct ConnectionTypeDef {
    public var type:MCOConnectionType
    public var typeStr:String
    public var typeStrLocalized:String
}
// struct for an array to store OAuth ResponseType definitions
public struct OAuthResponseTypeDef {
    public var typeStr:String
    public var typeStrLocalized:String
}
// struct to store Email Account Credentials to and from secure storage
public struct EmailAccountCredentials:Equatable {
    public var viaNameLocalized:String = ""
    public var username:String = ""
    public var password:String = ""
    public var oAuthAccessToken:String = ""
    public var oAuthRefreshToken:String = ""
    public var oAuthAccessTokenExpiresDatetime:Date? = nil

    init() {}
    
    init(localizedName:String, data:Data) {
        self.viaNameLocalized = localizedName
        if data.count > 0 {
            let str = String(data: data, encoding: String.Encoding.utf16)!
            let strComps = str.components(separatedBy: "\t")
            if strComps.count == 1 { self.username = str }
            if strComps.count >= 2 { self.username = strComps[0]; self.password = strComps[1] }
            if strComps.count >= 4 { self.oAuthAccessToken = strComps[2]; self.oAuthRefreshToken = strComps[3] }
            if strComps.count == 5 { self.oAuthAccessTokenExpiresDatetime = Date(timeIntervalSince1970: Double(strComps[4])!) }
        }
    }
    
    init(localizedName:String, fromStoredElements:[String]) {
        self.viaNameLocalized = localizedName
        if fromStoredElements.count >= 2 { self.username = fromStoredElements[1] }
        if fromStoredElements.count >= 3 { self.password = fromStoredElements[2] }
    }
    
    // encoded as <username> \t <password> \t <OAuthAccessToken> \t <OAuthRefreshToken> \t <OAuthAccessTokenExpirationTimestamp>
    public func data() -> Data {
        var sourceString:String = "\(self.username)\t\(self.password)\t\(self.oAuthAccessToken)\t\(self.oAuthRefreshToken)"
        if self.oAuthAccessTokenExpiresDatetime != nil {
            sourceString = sourceString + "\t\(self.oAuthAccessTokenExpiresDatetime!.timeIntervalSince1970)"
        }
        return sourceString.data(using: String.Encoding.utf16)!
    }
    
    // "credentials \t <username> \t <password> "
    public func encodeToStore() -> String {
        return "credentials\t\(self.username)\t\(self.password)"
    }
}
// struct to define a smtp email provider
public struct EmailProviderSMTP:Equatable {
    public var viaNameLocalized:String = ""
    public var providerInternalName:String = ""
    public var hostname:String = ""
    public var port:Int = 0
    public var connectionType:MCOConnectionType = .clear
    public var authType:MCOAuthType = .saslPlain
    public var localizedNotes:String?  = nil
    
    init() {}
    
    init(viaNameLocalized:String, providerInternalName:String, hostname:String, port:Int, connectionType:MCOConnectionType, authType:MCOAuthType, localizedNotes:String?=nil) {
        self.viaNameLocalized = viaNameLocalized
        self.providerInternalName = providerInternalName
        self.hostname = hostname
        self.port = port
        self.connectionType = connectionType
        self.authType = authType
        self.localizedNotes = localizedNotes
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
    
    init(viaNameLocalized:String, fromStoredElements:[String]) {
        self.viaNameLocalized = viaNameLocalized
        if fromStoredElements.count >= 2 { self.providerInternalName = fromStoredElements[1] }
        if fromStoredElements.count >= 3 { self.hostname = fromStoredElements[2] }
        if fromStoredElements.count >= 4 { self.port = Int(fromStoredElements[3]) ?? 0 }
        if fromStoredElements.count >= 5 {
            for aConnTypeDef in EmailHandler.connectionTypeDefs {
                if fromStoredElements[4] == aConnTypeDef.typeStr {
                    self.connectionType = aConnTypeDef.type
                    break
                }
            }
        }
        if fromStoredElements.count >= 6 {
            for anAuthType in EmailHandler.authTypeDefs {
                if fromStoredElements[5] == anAuthType.typeStr {
                    self.authType = anAuthType.type
                    break
                }
            }
        }
    }
    
    // "settingsSMTP \t internalName \t <hostName> \t <port> \t <connectType> \t <authType>"
    public func encodeToStore() -> String {
        var returnString:String = "settingsSMTP\t\(self.providerInternalName)\t\(self.hostname)\t\(self.port)"
        
        for aConnTypeDef in EmailHandler.connectionTypeDefs {
            if self.connectionType == aConnTypeDef.type {
                returnString = returnString  + "\t" + aConnTypeDef.typeStr
                break
            }
        }
        for anAuthType in EmailHandler.authTypeDefs {
            if self.authType == anAuthType.type {
                returnString = returnString  + "\t" + anAuthType.typeStr
                break
            }
        }
        return returnString
    }
}
// struct to define a smtp email provider's OAUTH
public struct EmailProviderSMTP_OAuth:Equatable {
    public var viaNameLocalized:String = ""
    public var providerInternalName:String = ""
    public var oAuthConsumerKey:String = ""
    public var oAuthConsumerSecret:String = ""
    public var oAuthAuthorizeURL:String = ""
    public var oAuthAccessTokenURL:String = ""
    public var oAuthCheckAccessTokenURL:String = ""
    public var oAuthCheckAccessTokenURLParameter:String = ""
    public var oAuthResponseType:String = ""
    public var oAuthScope:String = ""
    public var oAuthCallbackScheme:String = ""
    public var oAuthCallbackHostname:String = ""
    
    init() {}
    
    init(viaNameLocalized:String, providerInternalName:String, oAuthConsumerKey:String, oAuthConsumerSecret:String, oAuthAuthorizeURL:String, oAuthAccessTokenURL:String, oAuthCheckAccessTokenURL:String, oAuthCheckAccessTokenURLParameter:String, oAuthResponseType:String, oAuthScope:String, oAuthCallbackScheme:String, oAuthCallbackHostname:String, localizedNotes:String?=nil) {
        self.viaNameLocalized = viaNameLocalized
        self.providerInternalName = providerInternalName
        self.oAuthConsumerKey = oAuthConsumerKey
        self.oAuthConsumerSecret = oAuthConsumerSecret
        self.oAuthAuthorizeURL = oAuthAuthorizeURL
        self.oAuthAccessTokenURL = oAuthAccessTokenURL
        self.oAuthCheckAccessTokenURL = oAuthCheckAccessTokenURL
        self.oAuthCheckAccessTokenURLParameter = oAuthCheckAccessTokenURLParameter
        self.oAuthResponseType = oAuthResponseType
        self.oAuthScope = oAuthScope
        self.oAuthCallbackScheme = oAuthCallbackScheme
        self.oAuthCallbackHostname = oAuthCallbackHostname
    }
    
    init?(localizedName:String, knownProviderInternalName:String) {
        for provider in EmailHandler.knownSMTPEmailProviders_OAuth {
            if provider.providerInternalName == knownProviderInternalName {
                self.viaNameLocalized = localizedName
                self.providerInternalName = provider.providerInternalName
                self.oAuthConsumerKey = provider.oAuthConsumerKey
                self.oAuthConsumerSecret = provider.oAuthConsumerSecret
                self.oAuthAuthorizeURL = provider.oAuthAuthorizeURL
                self.oAuthAccessTokenURL = provider.oAuthAccessTokenURL
                self.oAuthCheckAccessTokenURL = provider.oAuthCheckAccessTokenURL
                self.oAuthCheckAccessTokenURLParameter = provider.oAuthCheckAccessTokenURLParameter
                self.oAuthResponseType = provider.oAuthResponseType
                self.oAuthScope = provider.oAuthScope
                self.oAuthCallbackScheme = provider.oAuthCallbackScheme
                self.oAuthCallbackHostname = provider.oAuthCallbackHostname
                return
            }
        }
        return nil
    }
    
    init(viaNameLocalized:String, providerInternalName:String, fromStoredElements:[String]) {
        self.viaNameLocalized = viaNameLocalized
        self.providerInternalName = providerInternalName
        if fromStoredElements.count >= 2  { self.oAuthConsumerKey = fromStoredElements[1] }
        if fromStoredElements.count >= 3  { self.oAuthConsumerSecret = fromStoredElements[2] }
        if fromStoredElements.count >= 4  { self.oAuthAuthorizeURL = fromStoredElements[3] }
        if fromStoredElements.count >= 5  { self.oAuthAccessTokenURL = fromStoredElements[4] }
        if fromStoredElements.count >= 6  { self.oAuthCheckAccessTokenURL = fromStoredElements[5] }
        if fromStoredElements.count >= 7  { self.oAuthCheckAccessTokenURLParameter = fromStoredElements[6] }
        if fromStoredElements.count >= 8  { self.oAuthCallbackScheme = fromStoredElements[7] }
        if fromStoredElements.count >= 9  { self.oAuthCallbackHostname = fromStoredElements[8] }
        if fromStoredElements.count >= 10 { self.oAuthScope = fromStoredElements[9] }
        if fromStoredElements.count >= 11 { self.oAuthResponseType = fromStoredElements[10] }
    }
    
    // "settingsOAuth \t <clientID> \t <clientSecret> \t <authURL> \t <tokenURL> \t <checkURL> \t <checkURLparam> \t <callbackScheme> \t <callbackHostname> \t <scope> \t <responseType>"
    public func encodeToStore() -> String {
        return "settingsOAuth\t\(self.oAuthConsumerKey)\t\(self.oAuthConsumerSecret)\t\(self.oAuthAuthorizeURL)\t\(self.oAuthAccessTokenURL)\t\(self.oAuthCheckAccessTokenURL)\t\(self.oAuthCheckAccessTokenURLParameter)\t\(self.oAuthCallbackScheme)t\(self.oAuthCallbackHostname)\t\(self.oAuthScope)\t\(self.oAuthResponseType)"
    }
    
    // create the callback URL aka redirect URL
    public func getCallbackURL(withPath:String?=nil) -> URL? {
        var urlString:String = self.oAuthCallbackScheme
        if !self.oAuthCallbackHostname.isEmpty {
            urlString = urlString + "://" + self.oAuthCallbackHostname
        }
        if !(withPath ?? "").isEmpty {
            if self.oAuthCallbackHostname.isEmpty { urlString = urlString + ":" }
            urlString = urlString + "/" + withPath!
        }
        return URL(string: urlString)
    }
}
// class object to hold information regarding an email account, including provider, credentials, etc.
// since its a class, it will be referenced by object rather than copied
public class EmailVia {
    public var viaNameLocalized:String = NSLocalizedString("iOS Mail App", comment:"")
    public var viaType:ViaType = .API
    public var unsecuredCredentials:Bool = false
    public var emailProvider_InternalName:String = "iOSMail"
    public var userDisplayName:String = ""
    public var sendingEmailAddress:String = ""
    public var emailProvider_SMTP:EmailProviderSMTP? = nil
    public var emailProvider_SMTP_OAuth:EmailProviderSMTP_OAuth? = nil
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
    init?(fromEncode:String?, fromCredentials: Data?) throws {
        try self.decode(fromEncode: fromEncode, fromCredentials: fromCredentials)
    }
    
    // create an instance from a known SMTP Email Provider
    init(fromSMTPProvider:EmailProviderSMTP, withSMTP_OAUTH:EmailProviderSMTP_OAuth?=nil) {
        self.viaNameLocalized = fromSMTPProvider.viaNameLocalized
        self.viaType = .SMTPknown
        self.emailProvider_InternalName = fromSMTPProvider.providerInternalName
        self.emailProvider_SMTP = fromSMTPProvider
        self.emailProvider_SMTP_OAuth = withSMTP_OAUTH
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
        self.emailProvider_SMTP_OAuth = fromExisting.emailProvider_SMTP_OAuth   // structure auto-deep copies
        self.emailProvider_Credentials = fromExisting.emailProvider_Credentials // structure auto-deep copies
    }
    
    // create an encoded string
    // encode formats:
    //   <localizedName> \1 stored
    //   <localizedName> \1 api       \1 api \t <api>
    //   <localizedName> \1 smtpKnown \1 from \t     \1 knownProvider \t <providerInternalName>
    //   <localizedName> \1 smtpSet   \1 from \t ... \1 settingsSMTP \t ... \1 settingsOAuth \t ... \1 credentials \t ...
    //   <localizedName> \1 appScheme \1 from \t ... \1 ??FUTURE
    //
    //   from \t <email display name> \t <email address>
    public func encode() -> String? {
        switch self.viaType {
        case .None:
            return nil
        case .Stored:
            return "\(self.viaNameLocalized)\u{1}stored"
        case .API:
            return "\(self.viaNameLocalized)\u{1}api\u{1}api\t\(self.emailProvider_InternalName)"
        case .SMTPknown:
            return "\(self.viaNameLocalized)\u{1}smtpKnown\u{1}from\t\(self.userDisplayName)\t\(self.sendingEmailAddress)\u{1}knownProvider\t\(self.emailProvider_InternalName)"
        case .SMTPsettings:
            var result = "\(self.viaNameLocalized)\u{1}smtpSet\u{1}from\t\(self.userDisplayName)\t\(self.sendingEmailAddress)"
            if self.emailProvider_SMTP != nil {
                result = result + "\u{1}" + self.emailProvider_SMTP!.encodeToStore()
            }
            if self.emailProvider_SMTP_OAuth != nil {
                result = result + "\u{1}" + self.emailProvider_SMTP_OAuth!.encodeToStore()
            }
            if self.emailProvider_Credentials != nil && self.unsecuredCredentials {
                result = result + "\u{1}" + self.emailProvider_Credentials!.encodeToStore()
            }
            return result
        }
    }
    
    // update this instance with the decoded information
    public func decode(fromEncode:String?, fromCredentials: Data?) throws {
        if fromEncode == nil { return }
        
        // decode the bulk of the via
        let encodeComps:[String] = fromEncode!.components(separatedBy: "\u{1}")
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
                    throw APP_ERROR(funcName: "EmailVia.decode", domain: EmailHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: nil, developerInfo: "Via Type invalid: \(comp)")
                }
            } else {
                let elements:[String] = comp.components(separatedBy: "\t")
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
                case "settingsSMTP":
                    if self.viaType == .SMTPsettings {
                        self.emailProvider_SMTP = EmailProviderSMTP(viaNameLocalized: self.viaNameLocalized, fromStoredElements: elements)
                    }
                    break
                case "settingsOAuth":
                    if self.viaType == .SMTPsettings {
                        self.emailProvider_SMTP_OAuth = EmailProviderSMTP_OAuth(viaNameLocalized: self.viaNameLocalized, providerInternalName: self.emailProvider_SMTP!.providerInternalName, fromStoredElements: elements)
                    }
                    break
                case "credentials":
                    if self.viaType == .SMTPsettings {
                        self.emailProvider_Credentials = EmailAccountCredentials(localizedName: self.viaNameLocalized, fromStoredElements: elements)
                    }
                    break
                default:
                    throw APP_ERROR(funcName: "EmailVia.decode", domain: EmailHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: nil, developerInfo: "Via Element invalid: \(elements[0])")
                }
            }
            inx = inx + 1
        }
        
        // now decode the secure credentials if supplied
        if fromCredentials != nil {
            self.emailProvider_Credentials = EmailAccountCredentials(localizedName: self.viaNameLocalized, data: fromCredentials!)
        }
    }
}
// class to hold information for sending one email or perform one SMTP test through the Email Dispatch Queue into the background thread
public class EmailPending {
    public var emailTag:Int = 0
    public var testTheVia:Bool = false
    public var invoker:String
    public var invoker_tagI:Int = 0
    public var invoker_tagS:String? = nil
    public var via:EmailVia
    public var oAuth2Swift:OAuth2Swift? = nil
    
    // email parameters
    public var to:String? = nil
    public var cc:String? = nil
    public var subject:String? = nil
    public var body:String? = nil
    public var includeAttachment:URL? = nil
    public var attachmentMimeType:String? = nil
    
    init(via:EmailVia, invoker:String, tagI:Int, tagS:String?, test:Bool=false) {
        self.emailTag = EmailHandler.shared.nextEmailPendingTag()
        self.via = via
        self.invoker = invoker
        self.invoker_tagI = tagI
        self.invoker_tagS = tagS
        self.testTheVia = test
    }
}
// struct to hold the results of a queued sent email
public struct EmailResult {
    public var invoker:String
    public var invoker_tagI:Int = 0
    public var invoker_tagS:String? = nil
    public var result:EmailHandler.EmailHandlerResults
    public var error:Error?
    public var extendedDetails:String?
    
    init(invoker:String, tagI:Int, tagS:String?, result:EmailHandler.EmailHandlerResults, error:Error?, extendedDetails:String?) {
        self.invoker = invoker
        self.invoker_tagI = tagI
        self.invoker_tagS = tagS
        self.result = result
        self.error = error
        self.extendedDetails = extendedDetails
    }
}

/////////////////////////////////////////////////////////////////////////
// Main class that handles sending Emails
/////////////////////////////////////////////////////////////////////////

// base handler class for sending emails
public class EmailHandler:NSObject, MFMailComposeViewControllerDelegate {
    // member variables
    public var mEMHstatus_state:HandlerStatusStates = .Unknown
    public var mAppError:APP_ERROR? = nil
    public var mEmailPendingTagCntr:Int = 0
    private let mEmailPendingQueue = DispatchQueue(label: "opensource.thecybermike.econtactcollect.EmailPendingQueu")
    private let mEmailRunningQueue = DispatchQueue(label: "opensource.thecybermike.econtactcollect.EmailRunningQueue")
    
    // member constants and other static content
    public static let shared:EmailHandler = EmailHandler()
    internal var mCTAG:String = "HEM"
    internal var mThrowErrorDomain:String = NSLocalizedString("Email-Handler", comment:"")
    public static var ThrowErrorDomain:String = NSLocalizedString("Email-Handler", comment:"")
    public static var mOAuthCallbackPath:String = "oauth2Callback"
    
    public enum EmailHandlerResults: Int {
        case Cancelled = 0, Error = 1, Saved = 2, Sent = 3
    }
    
    public static var knownSMTPEmailProviders_OAuth:[EmailProviderSMTP_OAuth] = [
        // WARNING: providerInternalName must NOT have any spaces: just letters, digits, and dash
        // WARNING: viaNameLocalized and providerInternalName must match an entry in knownSMTPEmailProviders
        
        // Google GMail - OAuth access; oAuthCallbackHostname must be blank
        // https://developers.google.com/gmail/api/auth/web-server
        EmailProviderSMTP_OAuth(viaNameLocalized: NSLocalizedString("Gmail OAuth2", comment:""), providerInternalName: "Gmail-OAuth2", oAuthConsumerKey: "43164448264-nj75ble1msena7g1jur2eqfq41d2ni9m.apps.googleusercontent.com", oAuthConsumerSecret: "", oAuthAuthorizeURL: "https://accounts.google.com/o/oauth2/auth", oAuthAccessTokenURL: "https://accounts.google.com/o/oauth2/token", oAuthCheckAccessTokenURL: "https://oauth2.googleapis.com/tokeninfo", oAuthCheckAccessTokenURLParameter: "access_token", oAuthResponseType: "code", oAuthScope: "https://mail.google.com/", oAuthCallbackScheme: "com.googleusercontent.apps.43164448264-nj75ble1msena7g1jur2eqfq41d2ni9m", oAuthCallbackHostname: "")
        
        // Yahoo Mail - OAuth access
        // https://developer.yahoo.com/oauth2/guide/flows_authcode/
        // access to Yahoo SMTP email via OAuth has been removed by Yahoo
        //EmailProviderSMTP_OAuth(viaNameLocalized: NSLocalizedString("Yahoo OAuth2", comment:""), providerInternalName: "Yahoo-OAuth2", oAuthConsumerKey: "dj0yJmk9bXdCUThYQWJpc1hNJnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PWMz", oAuthConsumerSecret: "50a5200ed3a951983670e9b30c18ed4942cc5edc", oAuthAuthorizeURL: "https://api.login.yahoo.com/oauth2/request_auth", oAuthAccessTokenURL: "https://api.login.yahoo.com/oauth2/get_token", oAuthResponseType: "code", oAuthScope: "mail-w", oAuthCallbackScheme: "oob", oAuthCallbackHostname: "")
    ]
    
    public static var knownSMTPEmailProviders:[EmailProviderSMTP] = [
        // WARNING: providerInternalName must NOT have any spaces: just letters, digits, and dash
        
        // Google GMail - OAuth access; username is full gmail email address
        EmailProviderSMTP(viaNameLocalized: NSLocalizedString("Gmail OAuth2", comment:""), providerInternalName: "Gmail-OAuth2", hostname: "smtp.gmail.com", port: 465, connectionType: MCOConnectionType.TLS, authType: MCOAuthType.xoAuth2),
        
        // Google GMail - "less secure" access; username is full gmail email address
        // https://support.google.com/mail/answer/7126229
        // https://support.google.com/accounts/answer/6010255
        EmailProviderSMTP(viaNameLocalized: NSLocalizedString("Gmail legacy", comment:""), providerInternalName: "Gmail-Legacy", hostname: "smtp.gmail.com", port: 465, connectionType: MCOConnectionType.TLS, authType: MCOAuthType.saslPlain, localizedNotes: NSLocalizedString("GMail Legacy Notes", comment:"")),
        
        // Yahoo Mail - OAuth access; username is full yahoo email address
        // access to Yahoo SMTP email via OAuth has been removed by Yahoo
        //EmailProviderSMTP(viaNameLocalized: NSLocalizedString("Yahoo OAuth2", comment:""), providerInternalName: "Yahoo-OAuth2", hostname: "smtp.mail.yahoo.com", port: 465, connectionType: MCOConnectionType.TLS, authType: MCOAuthType.xoAuth2),
        
        // Yahoo Mail - "less secure" access; username is full yahoo email address
        // https://help.yahoo.com/kb/pop-settings-sln4724.html
        // https://help.yahoo.com/kb/SLN3792.html
        EmailProviderSMTP(viaNameLocalized: NSLocalizedString("Yahoo legacy", comment:""), providerInternalName: "Yahoo-Legacy", hostname: "smtp.mail.yahoo.com", port: 465, connectionType: MCOConnectionType.TLS, authType: MCOAuthType.saslPlain, localizedNotes: NSLocalizedString("Yahoo Legacy Notes", comment:"")),
        
        // Outlook.com Mail - "less secure" access; username is full outlook email address
        // https://support.office.com/en-us/article/pop-imap-and-smtp-settings-for-outlook-com-d088b986-291d-42b8-9564-9c414e2aa040
        EmailProviderSMTP(viaNameLocalized: NSLocalizedString("Outlook.com legacy", comment:""), providerInternalName: "Outlook-Legacy", hostname: "smtp-mail.outlook.com", port: 587, connectionType: MCOConnectionType.TLS, authType: MCOAuthType.saslPlain),
        
        // iCloud Mail - "less secure" access; username is full icloud email address
        // https://support.office.com/en-us/article/pop-imap-and-smtp-settings-for-outlook-com-d088b986-291d-42b8-9564-9c414e2aa040
        EmailProviderSMTP(viaNameLocalized: NSLocalizedString("iCloud legacy", comment:""), providerInternalName: "iCloud-Legacy", hostname: "smtp.mail.me.com", port: 587, connectionType: MCOConnectionType.TLS, authType: MCOAuthType.saslPlain),
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
    public static var oauthResponseTypeDefs:[OAuthResponseTypeDef] = [
        OAuthResponseTypeDef(typeStr: "code", typeStrLocalized: NSLocalizedString("Code", comment:"")),
        OAuthResponseTypeDef(typeStr: "token", typeStrLocalized: NSLocalizedString("Token", comment:"")),
    ]

    // initialization; returns true if initialize fully succeeded;
    // errors are stored via the class members and will already be posted to the error.log;
    // this handler must be mindful that the database initialization may have failed
    public func initialize(method:String) -> Bool {
//debugPrint("\(mCTAG).initialize STARTED")
        // nothing needed for now
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
    
    // issue the next EmailPending Tag
    public func nextEmailPendingTag() -> Int {
        self.mEmailPendingTagCntr = self.mEmailPendingTagCntr + 1
        return self.mEmailPendingTagCntr
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    // public methods for Email Accounts
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
            let via:EmailVia = EmailVia(fromSMTPProvider: providerSMTP)
            let oauth:EmailProviderSMTP_OAuth? = EmailProviderSMTP_OAuth(localizedName: providerSMTP.viaNameLocalized, knownProviderInternalName: providerSMTP.providerInternalName)
            if oauth != nil { via.emailProvider_SMTP_OAuth = oauth }
            result.append(via)
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
        if via.emailProvider_Credentials != nil {
            do {
                try AppDelegate.storeSecureItem(key: via.viaNameLocalized, label: "Email", data: via.emailProvider_Credentials!.data())
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
        do {
            return try EmailVia(fromEncode: encodedVia, fromCredentials: nil)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).getStoredEmailViaNoCredentials", during: "EmailVia()", errorStruct: error, extra: encodedVia)
            // do not pass up the error
            return nil
        }
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
            return try EmailVia(fromEncode: encodedVia, fromCredentials: encodedCred)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getStoredEmailViaWithCredentials")
            throw appError
        } catch { throw error }
    }
    
    // delete a stored EmailVia including its securely stored credentials
    public func deleteEmailVia(localizedName:String) throws {
        // delete the bulk of the EmailVia
        let key:String = PreferencesKeys.Strings.EmailVia_Stored_Named.rawValue + localizedName
        AppDelegate.deletePreferenceString(prefKeyString: key)
        
        // delete any secure credentials
        do {
            let _ = try AppDelegate.deleteSecureItem(key: localizedName, label: "Email")
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).deleteEmailVia")
            throw appError
        } catch { throw error }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // public methods to send emails and test SMTP Accounts
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // send an email to the developer, optionally including an attachment;
    // initial errors are thrown; email subsystem result success/error is returned via callback
    public func sendEmailToDeveloper(vc:UIViewController, invoker:String, tagI:Int, tagS:String?, localizedTitle:String, subject:String?, body:String?, includingAttachment:URL?) throws {
        do {
            try sendEmail(vc: vc, invoker: invoker, tagI: tagI, tagS: tagS, localizedTitle: localizedTitle, via: nil, to: AppDelegate.mDeveloperEmailAddress, cc: nil, subject: subject, body: body, includingAttachment: includingAttachment)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).sendEmailToDeveloper")
            throw appError
        } catch { throw error }
    }

    // send an email, optionally including an attachment;
    // initial errors are thrown; email subsystem result success/error is returned via callback
    public func sendEmail(vc:UIViewController, invoker:String, tagI:Int, tagS:String?, localizedTitle:String, via:EmailVia?, to:String?, cc:String?, subject:String?, body:String?, includingAttachment:URL?) throws {
        
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
                let provider:EmailProviderSMTP? = EmailProviderSMTP(localizedName: usingVia.viaNameLocalized, knownProviderInternalName: usingVia.emailProvider_InternalName)
                if provider == nil {
                    throw APP_ERROR(funcName: "\(self.mCTAG).sendEmail", domain: self.mThrowErrorDomain, errorCode: .MISSING_KNOWN_EMAIL_PROVIDER, userErrorDetails: "\(usingVia.viaNameLocalized) -> \(usingVia.emailProvider_InternalName)")
                }
                usingVia.emailProvider_SMTP = provider
                usingVia.emailProvider_SMTP_OAuth = EmailProviderSMTP_OAuth(localizedName: usingVia.viaNameLocalized, knownProviderInternalName: usingVia.emailProvider_InternalName)
            }
            if (usingVia.viaType == .SMTPknown || usingVia.viaType == .SMTPsettings) && usingVia.emailProvider_Credentials == nil {
                // fill in any secured credentials
                let encodedCred:Data? = try AppDelegate.retrieveSecureItem(key: usingVia.viaNameLocalized, label: "Email")
                if encodedCred == nil {
                    throw APP_ERROR(funcName: "\(self.mCTAG).sendEmail", domain: self.mThrowErrorDomain, errorCode: .MISSING_EMAIL_ACCOUNT_CREDENTIALS, userErrorDetails: usingVia.viaNameLocalized)
                }
                usingVia.emailProvider_Credentials = EmailAccountCredentials(localizedName: usingVia.viaNameLocalized, data: encodedCred!)
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).sendEmail")
            throw appError
        } catch { throw error }
        

        // determine how to send the email from the usingVia
        do {
            switch usingVia.viaType {
            case .None:
                throw APP_ERROR(funcName: "\(self.mCTAG).sendEmail", domain: self.mThrowErrorDomain, errorCode: .INTERNAL_ERROR, userErrorDetails: usingVia.viaNameLocalized, developerInfo: "usingVia.viaType == .None")
            case .Stored:
                throw APP_ERROR(funcName: "\(self.mCTAG).sendEmail", domain: self.mThrowErrorDomain, errorCode: .INTERNAL_ERROR, userErrorDetails: usingVia.viaNameLocalized, developerInfo: "usingVia.viaType == .Stored")
            case .API:
                // presently the only allowed API is the iOS provided API for the Apple Mail App
                try sendEmailViaAppleMailApp(vc: vc, invoker: invoker, tagI: tagI, tagS: tagS, localizedTitle: localizedTitle, to: to, cc: cc, subject: subject, body: body, includingAttachment: includingAttachment, mimeType: mimeType)
                break
            case .SMTPknown:
                // send using SMTP via a known provider; provider settings and secure credentials have already been obtained
                try sendEmailViaMailCore(vc: vc, invoker: invoker, tagI: tagI, tagS: tagS, localizedTitle: localizedTitle, via: usingVia, to: to, cc: cc, subject: subject, body: body, includingAttachment: includingAttachment, mimeType: mimeType)
                break
            case .SMTPsettings:
                // send using SMTP with providied settings; secure credentials have already been obtained
                try sendEmailViaMailCore(vc: vc, invoker: invoker, tagI: tagI, tagS: tagS, localizedTitle: localizedTitle, via: usingVia, to: to, cc: cc, subject: subject, body: body, includingAttachment: includingAttachment, mimeType: mimeType)
                break
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).sendEmail")
            throw appError
        } catch { throw error }
    }
    
    // test the email connection and credentials via SMTP using MailCore; do the OAuth precheck if necessary
    public func testEmailViaMailCore(vc:UIViewController, invoker:String, tagI:Int, tagS:String?, via:EmailVia) throws {
//debugPrint("\(self.mCTAG).testEmailViaMailCore STARTED")
        if via.emailProvider_SMTP == nil {
            throw APP_ERROR(funcName: "\(self.mCTAG).testEmailViaMailCore", domain: self.mThrowErrorDomain, errorCode: .INTERNAL_ERROR, userErrorDetails: nil, developerInfo: "via.emailProvider_SMTP == nil ")
        }
        if via.emailProvider_Credentials == nil {
            throw APP_ERROR(funcName: "\(self.mCTAG).testEmailViaMailCore", domain: self.mThrowErrorDomain, errorCode: .INTERNAL_ERROR, userErrorDetails: nil, developerInfo: "via.emailProvider_Credentials == nil")
        }
        if via.emailProvider_SMTP!.hostname.isEmpty {
            // this is a user error to fix
            throw USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .INVALID_OR_MISSING_SMTP_PARAMETER, userErrorDetails: NSLocalizedString("Hostname", comment:""))
        }
        if via.emailProvider_SMTP!.port < 1 || via.emailProvider_SMTP!.port > 65535 {
            // this is a user error to fix
            throw USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .INVALID_OR_MISSING_SMTP_PARAMETER, userErrorDetails: NSLocalizedString("Port", comment:""))
        }
        
        // compose the pending obejct
        let pending = EmailPending(via: via, invoker: invoker, tagI: tagI, tagS: tagS, test: true)
        
        if via.emailProvider_SMTP!.authType == .xoAuth2 || via.emailProvider_SMTP!.authType == .xoAuth2Outlook {
            self.validateOAuth(vc: vc, pending: pending, callback: { error in
                pending.oAuth2Swift = nil
                if error == nil {
//debugPrint("\(self.mCTAG).testEmailViaMailCore.validateOAuth.error==nil ")
                    self.enqueueEmail(withEmail: pending)
                } else {
//debugPrint("\(self.mCTAG).testEmailViaMailCore.validateOAuth.error!=nil ")
                    // post a result notification of the OAuth error (its already in the main UI thread)
                    let result:EmailResult
                    if var appError = error as? APP_ERROR {
                        appError.prependCallStack(funcName: "\(self.mCTAG).testEmailViaMailCore")
                        result = EmailResult(invoker: invoker, tagI: tagI, tagS: tagS, result: .Error, error: appError, extendedDetails: nil)
                    } else {
                        result = EmailResult(invoker: invoker, tagI: tagI, tagS: tagS, result: .Error, error: error, extendedDetails: nil)
                    }
                    NotificationCenter.default.post(name: .APP_EmailCompleted, object: result)
                }
            })
        } else {
            self.enqueueEmail(withEmail: pending)
        }
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
    private func sendEmailViaAppleMailApp(vc:UIViewController, invoker:String, tagI:Int, tagS:String?, localizedTitle:String, to:String?, cc:String?, subject:String?, body:String?, includingAttachment:URL?, mimeType:String) throws {
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
            // this is a user problem to fix by installing the iOS Mail App or defining a different SMTP Email Account
            throw USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .IOS_EMAIL_SUBSYSTEM_DISABLED, userErrorDetails: nil)
        }
        
        // invoke the iOS Mail compose subsystem
        let mailVC = MFMailComposeViewControllerExt()
        mailVC.mailComposeDelegate = self
        mailVC.invoker = invoker
        mailVC.invoker_tagI = tagI
        mailVC.invoker_tagS = tagS
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
                default:
                    resultHEM = .Error
                    break
                }
            }
            
            // post a result notification (its already in the main UI thread)
            let result:EmailResult = EmailResult(invoker: controllerHEM.invoker, tagI: controllerHEM.invoker_tagI, tagS: controllerHEM.invoker_tagS, result: resultHEM, error: errorHEM, extendedDetails: nil)
            NotificationCenter.default.post(name: .APP_EmailCompleted, object: result)

            controller.dismiss(animated: true, completion: nil)
            return
        }
        if error != nil {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mailComposeController.didFinishWith.noDelegate", errorStruct: error!, extra: nil)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    // send the email via SMTP using MailCore; do the OAuth precheck if necessary
    private func sendEmailViaMailCore(vc:UIViewController, invoker:String, tagI:Int, tagS:String?, localizedTitle:String, via:EmailVia, to:String?, cc:String?, subject:String?, body:String?, includingAttachment:URL?, mimeType:String) throws {
//debugPrint("\(self.mCTAG).sendEmailViaMailCore STARTED")
        if via.emailProvider_SMTP == nil {
            throw APP_ERROR(funcName: "\(self.mCTAG).sendEmailViaMailCore", domain: self.mThrowErrorDomain, errorCode: .INTERNAL_ERROR, userErrorDetails: nil, developerInfo: "via.emailProvider_SMTP == nil")
        }
        if via.emailProvider_Credentials == nil {
            throw APP_ERROR(funcName: "\(self.mCTAG).sendEmailViaMailCore", domain: self.mThrowErrorDomain, errorCode: .INTERNAL_ERROR, userErrorDetails: nil, developerInfo: "via.emailProvider_Credentials == nil")
        }
        if !(to ?? "").isEmpty && !(cc ?? "").isEmpty {
            // this is a user error to fix in the Org or Form email settings
            throw USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .EMAIL_NO_TO_AND_CC, userErrorDetails: nil)
        }
        if via.emailProvider_SMTP!.hostname.isEmpty {
            // this is a user error to fix
            throw USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .INVALID_OR_MISSING_SMTP_PARAMETER, userErrorDetails: NSLocalizedString("Hostname", comment:""))
        }
        if via.emailProvider_SMTP!.port < 1 || via.emailProvider_SMTP!.port > 65535 {
            // this is a user error to fix
            throw USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .INVALID_OR_MISSING_SMTP_PARAMETER, userErrorDetails: NSLocalizedString("Port", comment:""))
        }
        
        // compose the pending object
        let pending = EmailPending(via: via, invoker: invoker, tagI: tagI, tagS: tagS)
        pending.to = to
        pending.cc = cc
        pending.subject = subject
        pending.body = body
        pending.includeAttachment = includingAttachment
        pending.attachmentMimeType = mimeType
        
        if via.emailProvider_SMTP!.authType == .xoAuth2 || via.emailProvider_SMTP!.authType == .xoAuth2Outlook {
            if pending.via.emailProvider_SMTP_OAuth == nil {
                throw APP_ERROR(funcName: "\(self.mCTAG).validateOAuth", domain: self.mThrowErrorDomain, errorCode: .INTERNAL_ERROR, userErrorDetails: nil, developerInfo: "via.emailProvider_SMTP_OAuth == nil")
            }
            self.validateOAuth(vc: vc, pending: pending, callback: { error in
                pending.oAuth2Swift = nil
                if error == nil {
                    self.enqueueEmail(withEmail: pending)
                } else {
                    // post a result notification of the OAuth error (its already in the main UI thread)
                    let result:EmailResult
                    if var appError = error as? APP_ERROR {
                        appError.prependCallStack(funcName: "\(self.mCTAG).sendEmailViaMailCore")
                        result = EmailResult(invoker: invoker, tagI: tagI, tagS: tagS, result: .Error, error: appError, extendedDetails: nil)
                    } else {
                        result = EmailResult(invoker: invoker, tagI: tagI, tagS: tagS, result: .Error, error: error, extendedDetails: nil)
                    }
                    NotificationCenter.default.post(name: .APP_EmailCompleted, object: result)
                }
            })
        } else {
            self.enqueueEmail(withEmail: pending)
        }
    }
    
    // handle the OAuth necessities; if an acceptable OAuth Access Token has been obtained and stored into the via then invoke the callback
    private func validateOAuth(vc:UIViewController, pending:EmailPending, callback:@escaping ((Error?) -> Void)) {
        // are the OAuth parameters correct?
        if pending.via.emailProvider_SMTP_OAuth!.oAuthConsumerKey.isEmpty || pending.via.emailProvider_SMTP_OAuth!.oAuthResponseType.isEmpty || pending.via.emailProvider_SMTP_OAuth!.oAuthScope.isEmpty || pending.via.emailProvider_SMTP_OAuth!.oAuthCallbackScheme.isEmpty || pending.via.emailProvider_SMTP_OAuth!.oAuthAuthorizeURL.isEmpty || pending.via.emailProvider_SMTP_OAuth!.oAuthAccessTokenURL.isEmpty {
            
            callback(USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .INVALID_OR_MISSING_OAUTH_PARAMETER, userErrorDetails: nil))
            return
        }
        var workURL:URL? = pending.via.emailProvider_SMTP_OAuth!.getCallbackURL(withPath: EmailHandler.mOAuthCallbackPath)
        if workURL == nil {
            callback(USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .INVALID_OAUTH_URL, userErrorDetails: NSLocalizedString("Callback Scheme", comment:"")))
            return
        }
        workURL = URL(string: pending.via.emailProvider_SMTP_OAuth!.oAuthAuthorizeURL)
        if workURL == nil {
            callback(USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .INVALID_OAUTH_URL, userErrorDetails: NSLocalizedString("Authorize URL", comment:"")))
            return
        }
        workURL = URL(string: pending.via.emailProvider_SMTP_OAuth!.oAuthAccessTokenURL)
        if workURL == nil {
            callback(USER_ERROR(domain: self.mThrowErrorDomain, errorCode: .INVALID_OAUTH_URL, userErrorDetails: NSLocalizedString("Token URL", comment:"")))
            return
        }
        
        // what available OAuth credentials are available
        if pending.via.emailProvider_Credentials!.oAuthAccessToken.isEmpty &&
           pending.via.emailProvider_Credentials!.oAuthRefreshToken.isEmpty {
            
            // there are no oAuth credentials at all
//debugPrint("\(self.mCTAG).validateOAuth NO OAUTH CREDENTIALS; ASK FOR AUTH")
            self.validateOAuthAskForAuthorization(vc: vc, pending: pending, callback: callback)
            
        } else if pending.via.emailProvider_Credentials!.oAuthAccessToken.isEmpty &&
                  !pending.via.emailProvider_Credentials!.oAuthRefreshToken.isEmpty {
            
            // strange case; no accessToken but do have a refreshToken; attempt a refresh
//debugPrint("\(self.mCTAG).validateOAuth ONLY REFRESH TOKEN; ASK FOR REFRESH")
            self.validateOAuthRenew(vc: vc, pending: pending, callback: { error in
                if error == nil {
                    // refresh succeeded
                    callback(nil)
                } else {
                    // refresh failed
//debugPrint("\(self.mCTAG).validateOAuth REFRESH FAILED; NEED TO RE-ASK FOR AUTH")
                    self.validateOAuthAskForAuthorization(vc: vc, pending: pending, callback: callback)
                }
            })
            
        } else {
            // we have an access token; just check it since it may have been invalidated much less expired
//debugPrint("\(self.mCTAG).validateOAuth HAVE ACCESS TOKEN; CHECK IT")
            self.validateOAuthCheckExisting(vc: vc, pending: pending, callback: { error in
                if error == nil {
                    // check passed successfully
/*var msg:String = "\(self.mCTAG).validateOAuth CHECKED & AVAILABLE & NOT YET EXPIRED; REUSE"
if pending.via.emailProvider_Credentials!.oAuthAccessTokenExpiresDatetime != nil {
    msg = msg + "; [\(pending.via.emailProvider_Credentials!.oAuthAccessTokenExpiresDatetime!)]"
}
debugPrint(msg)*/
                    callback(nil)
                } else {
                    // check of the existing access token failed
                    if !pending.via.emailProvider_Credentials!.oAuthRefreshToken.isEmpty {
                        // there is a refresh token; attempt to do a refresh
//debugPrint("\(self.mCTAG).validateOAuth CHECK FAILED; REFRESH TOKEN AVAILABLE; ATTEMPT REFRESH")
                        self.validateOAuthRenew(vc: vc, pending: pending, callback: { error in
                            if error == nil {
                                // refresh succeeded
                                callback(nil)
                            } else {
                                // refresh failed
//debugPrint("\(self.mCTAG).validateOAuth REFRESH FAILED; NEED TO RE-ASK FOR AUTH")
                                self.validateOAuthAskForAuthorization(vc: vc, pending: pending, callback: callback)
                            }
                        })
                    } else {
                        // there is no refresh token available; just re-ask for authorization
//debugPrint("\(self.mCTAG).validateOAuth CHECK FAILED; NO REFRESH TOKEN; NEED TO RE-ASK FOR AUTH")
                        self.validateOAuthAskForAuthorization(vc: vc, pending: pending, callback: callback)
                    }
                }
            })
            /*if pending.via.emailProvider_Credentials!.oAuthAccessTokenExpiresDatetime == nil {
                // we do not have any expiration data
            } else if Date() >= pending.via.emailProvider_Credentials!.oAuthAccessTokenExpiresDatetime!   {
                // access token is expired
            }*/
        }
    }
    
    // need to do a full OAuth2 authorization from-scratch
    private func validateOAuthAskForAuthorization(vc:UIViewController, pending:EmailPending, callback:@escaping ((Error?) -> Void)) {
        // setup the oAuth2 parameters
//debugPrint("\(self.mCTAG).validateOAuthAskForAuthorization ASK FOR AUTHORIZATION STARTED")
        pending.oAuth2Swift = OAuth2Swift(
            consumerKey:    pending.via.emailProvider_SMTP_OAuth!.oAuthConsumerKey,
            consumerSecret: pending.via.emailProvider_SMTP_OAuth!.oAuthConsumerSecret,
            authorizeUrl:   pending.via.emailProvider_SMTP_OAuth!.oAuthAuthorizeURL,
            accessTokenUrl: pending.via.emailProvider_SMTP_OAuth!.oAuthAccessTokenURL,
            responseType:   pending.via.emailProvider_SMTP_OAuth!.oAuthResponseType
        )
        
        // perform the user-interaction; if responseType == "code" then the second stage request for the access token is automatically performed
        pending.oAuth2Swift!.authorizeURLHandler = SafariURLHandler(viewController: vc, oauthSwift: pending.oAuth2Swift!)
        let callbackURL:URL = pending.via.emailProvider_SMTP_OAuth!.getCallbackURL(withPath: EmailHandler.mOAuthCallbackPath)!
//debugPrint("\(self.mCTAG).validateOAuthAskForAuthorization RedirectURL=\(callbackURL.absoluteString)")
        let _ = pending.oAuth2Swift!.authorize(
            withCallbackURL: callbackURL,
            scope: pending.via.emailProvider_SMTP_OAuth!.oAuthScope,
            state: pending.via.emailProvider_SMTP_OAuth!.providerInternalName,
            success: { credential, response, parameters in
                // initial authorization interaction with the end-user succceeded;
                // we should have been given an authorization code and a refresh token but the expiration should be ignored
//debugPrint("\(self.mCTAG).validateOAuthAskForAuthorization.authorize.success AT=\(credential.oauthToken), RT=\(credential.oauthRefreshToken), ED=\(credential.oauthTokenExpiresAt), parameters=\(parameters)")
                pending.via.emailProvider_Credentials!.oAuthAccessToken = credential.oauthToken
                pending.via.emailProvider_Credentials!.oAuthRefreshToken = credential.oauthRefreshToken
                pending.via.emailProvider_Credentials!.oAuthAccessTokenExpiresDatetime = credential.oauthTokenExpiresAt
                do {
                    try AppDelegate.storeSecureItem(key: pending.via.viaNameLocalized, label: "Email", data: pending.via.emailProvider_Credentials!.data())
                } catch var appError as APP_ERROR {
                    appError.prependCallStack(funcName: "\(self.mCTAG).validateOAuthAskForAuthorization")
                    callback(appError)
                } catch { callback(error) }
                callback(nil)
                return // from success callback
            },
            failure: { error in
                // initial authorization interaction with the end-user failed or was denied
debugPrint("\(self.mCTAG).validateOAuthAskForAuthorization.authorize.failure \(error.description)")
                callback(APP_ERROR(funcName: "\(self.mCTAG).validateOAuthAskForAuthorization", during: "oauthswift.authorize", domain: self.mThrowErrorDomain, error: error, errorCode: .SMTP_EMAIL_SUBSYSTEM_ERROR, userErrorDetails: NSLocalizedString("OAuth failure", comment: ""), noPost: true))
                return // from failure callback
            }
        )
//debugPrint("\(self.mCTAG).validateOAuthAskForAuthorization ASK FOR AUTHORIZATION POSTED AND ENDED")
    }
    
    // need to do an OAuth renew
    private func validateOAuthRenew(vc:UIViewController, pending:EmailPending, callback:@escaping ((Error?) -> Void)) {
        // setup the oAuth2 parameters
//debugPrint("\(self.mCTAG).validateOAuthRenew RENEW AUTHORIZATION STARTED")
        pending.oAuth2Swift = OAuth2Swift(
            consumerKey:    pending.via.emailProvider_SMTP_OAuth!.oAuthConsumerKey,
            consumerSecret: pending.via.emailProvider_SMTP_OAuth!.oAuthConsumerSecret,
            authorizeUrl:   pending.via.emailProvider_SMTP_OAuth!.oAuthAuthorizeURL,
            accessTokenUrl: pending.via.emailProvider_SMTP_OAuth!.oAuthAccessTokenURL,
            responseType:   pending.via.emailProvider_SMTP_OAuth!.oAuthResponseType
        )
        
        pending.oAuth2Swift!.authorizeURLHandler = SafariURLHandler(viewController: vc, oauthSwift: pending.oAuth2Swift!)
        let _ = pending.oAuth2Swift!.renewAccessToken(
            withRefreshToken: pending.via.emailProvider_Credentials!.oAuthRefreshToken,
            success: { credential, response, parameters in
//debugPrint("\(self.mCTAG).validateOAuthRenew.renewAccessToken.success AT=\(credential.oauthToken), RT=\(credential.oauthRefreshToken), ED=\(credential.oauthTokenExpiresAt), parameters=\(parameters)")
                pending.via.emailProvider_Credentials!.oAuthAccessToken = credential.oauthToken
                if !credential.oauthRefreshToken.isEmpty { pending.via.emailProvider_Credentials!.oAuthRefreshToken = credential.oauthRefreshToken }
                pending.via.emailProvider_Credentials!.oAuthAccessTokenExpiresDatetime = credential.oauthTokenExpiresAt
                do {
                    try AppDelegate.storeSecureItem(key: pending.via.viaNameLocalized, label: "Email", data: pending.via.emailProvider_Credentials!.data())
                } catch var appError as APP_ERROR {
                    appError.prependCallStack(funcName: "\(self.mCTAG).validateOAuthRenew")
                    callback(appError)
                } catch { callback(error) }
                callback(nil)
                return // from success callback
            },
            failure: { error in
                // refresh failed or was denied
debugPrint("\(self.mCTAG).validateOAuthRenew.renewAccessToken.failure \(error.description)")
                callback(APP_ERROR(funcName: "\(self.mCTAG).validateOAuthRenew", during: "oauthswift.renewAccessToken", domain: self.mThrowErrorDomain, error: error, errorCode: .SMTP_EMAIL_SUBSYSTEM_ERROR, userErrorDetails: NSLocalizedString("OAuth failure", comment: ""), noPost: true))
                return // from failure callback
            }
        )
//debugPrint("\(self.mCTAG).validateOAuthRenew RENEW AUTHORIZATION POSTED AND ENDED")
    }
    
    // need to do an OAuth renew
    private func validateOAuthCheckExisting(vc:UIViewController, pending:EmailPending, callback:@escaping ((Error?) -> Void)) {
        // setup the oAuth2 parameters
//debugPrint("\(self.mCTAG).validateOAuthCheckExisting CHECK ACCESS TOKEN STARTED")
        pending.oAuth2Swift = OAuth2Swift(
            consumerKey:    pending.via.emailProvider_SMTP_OAuth!.oAuthConsumerKey,
            consumerSecret: pending.via.emailProvider_SMTP_OAuth!.oAuthConsumerSecret,
            authorizeUrl:   pending.via.emailProvider_SMTP_OAuth!.oAuthAuthorizeURL,
            accessTokenUrl: pending.via.emailProvider_SMTP_OAuth!.oAuthAccessTokenURL,
            responseType:   pending.via.emailProvider_SMTP_OAuth!.oAuthResponseType
        )
        
        pending.oAuth2Swift!.authorizeURLHandler = SafariURLHandler(viewController: vc, oauthSwift: pending.oAuth2Swift!)
        let _ = pending.oAuth2Swift!.checkToken(
            checkURL: pending.via.emailProvider_SMTP_OAuth!.oAuthCheckAccessTokenURL,
            checkURLParameter: pending.via.emailProvider_SMTP_OAuth!.oAuthCheckAccessTokenURLParameter,
            token: pending.via.emailProvider_Credentials!.oAuthAccessToken,
            success: { credential, response, parameters in
//debugPrint("\(self.mCTAG).validateOAuthCheckExisting.checkToken.success parameters=\(parameters)")
                callback(nil)
                return // from success callback
            },
            failure: { error in
                // token is invalid or expired or check failed or was denied
debugPrint("\(self.mCTAG).validateOAuthCheckExisting.checkToken.failure \(error.description)")
                callback(APP_ERROR(funcName: "\(self.mCTAG).validateOAuthCheckExisting", during: "oauthswift.checkAccessToken", domain: self.mThrowErrorDomain, error: error, errorCode: .SMTP_EMAIL_SUBSYSTEM_ERROR, userErrorDetails: NSLocalizedString("OAuth failure", comment: ""), noPost: true))
                return // from failure callback
            }
        )
//debugPrint("\(self.mCTAG).validateOAuthCheckExisting CHECK ACCESS TOKEN POSTED AND ENDED")
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // Threaded methods
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // enqueue an SMTP email or SMTP test for backgrounds thread to handle;
    // the DispatchQueue is FIFO serial
    // OAuth credentials have already been authorized and set
    // THREADING: this will only be called from the Main UI thread
    private func enqueueEmail(withEmail:EmailPending) {
//debugPrint("\(self.mCTAG).enqueueEmail MAIN_UI_THREAD STARTED")
        self.mEmailPendingQueue.async { [weak self] in
            self!.dequeueEmail(withEmail: withEmail)
        }
    }
    
    // THREADING: this will be called by the MailQueue thread
    private func dequeueEmail(withEmail:EmailPending) {
//debugPrint("\(self.mCTAG).dequeueEmail MAILQUEUE_THREAD STARTED")
        if withEmail.testTheVia { self.testEmailViaMailCore_send(withEmail: withEmail) }
        else { self.sendEmailViaMailCore_send(withEmail: withEmail) }
    }
    
    // test the email connection and credentials via SMTP using MailCore
    // THREADING:  this will be called by the MailQueue thread
    private func testEmailViaMailCore_send(withEmail:EmailPending) {
//debugPrint("\(self.mCTAG).testEmailViaMailCore_send MAILQUEUE_THREAD STARTED")
        
        // build the from address
        var from:MCOAddress
        if !withEmail.via.userDisplayName.isEmpty {
            from = MCOAddress(displayName: withEmail.via.userDisplayName, mailbox: withEmail.via.sendingEmailAddress)
        } else {
            from = MCOAddress(mailbox: withEmail.via.sendingEmailAddress)
        }
        
        // open a connection to the email server
        var loggerLines:String = ""
        let smtpSession = MCOSMTPSession()
        smtpSession.dispatchQueue = self.mEmailRunningQueue     // this does not appear to work
        smtpSession.hostname = withEmail.via.emailProvider_SMTP!.hostname
        smtpSession.port = UInt32(withEmail.via.emailProvider_SMTP!.port)
        smtpSession.authType =  withEmail.via.emailProvider_SMTP!.authType
        smtpSession.connectionType = withEmail.via.emailProvider_SMTP!.connectionType
        smtpSession.username = withEmail.via.emailProvider_Credentials!.username
        if withEmail.via.emailProvider_SMTP!.authType == .xoAuth2 || withEmail.via.emailProvider_SMTP!.authType == .xoAuth2Outlook {
            smtpSession.oAuth2Token = withEmail.via.emailProvider_Credentials!.oAuthAccessToken
        } else {
            smtpSession.password = withEmail.via.emailProvider_Credentials!.password
        }
        smtpSession.connectionLogger = {(connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                    var flow:String = ""
                    switch type {
                    case .received:
                        flow = "<= "
                        break
                    case .sent:
                        flow = "=> "
                        break
                    case .sentPrivate:
                        flow = "=> "
                        break
                    case .errorParse:
                        flow = "E "
                        break
                    case .errorReceived:
                        flow = "<E= "
                        break
                    case .errorSent:
                        flow = "=E> "
                        break
                    default:
                        flow = "<=?=> "
                        break
                    }
                    let stringSwift = string as String
debugPrint("\(self.mCTAG).testEmailViaMailCore_send.Connectionlogger: \(flow)\(stringSwift)")
                    loggerLines = loggerLines + flow + stringSwift
                    if stringSwift.starts(with: "334 ") {
                        let string1:String = String(stringSwift.prefix(stringSwift.count - 1))
                        let string2:String = String(string1.suffix(string1.count - 4))
                        let data1:Data? = Data(base64Encoded: string2)
                        if data1 != nil {
                            let decodedString:String? = String(data: data1!, encoding: .utf8)
                            if decodedString != nil {
debugPrint("\(self.mCTAG).testEmailViaMailCore_send.Connectionlogger: \(flow) 334 \(decodedString!)")
                                loggerLines = loggerLines + flow + decodedString! + "\r\n"
                            }
                        }
                    }
                }
            }
        }
        
        // test the connection; is automatically performed in a different background thread then callback with results
        let testOperation = smtpSession.checkAccountOperationWith(from: from)
        testOperation?.start { [weak self] (error) -> Void in
            var errorHEM:APP_ERROR? = nil
            var resultHEM:EmailHandler.EmailHandlerResults
            if error != nil {
                resultHEM = .Error
                loggerLines = loggerLines + NSLocalizedString("SMTP Connection Test FAILED!", comment:"") + "\n"
                errorHEM = APP_ERROR(funcName: "\(self!.mCTAG).testEmailViaMailCore", domain: self!.mThrowErrorDomain, error: error!, errorCode: .SMTP_EMAIL_SUBSYSTEM_ERROR, userErrorDetails: NSLocalizedString("See Alerts for error details", comment:""), noAlert: true)
                AppDelegate.postAlert(message: AppDelegate.endUserErrorMessage(errorStruct: errorHEM!), extendedDetails: loggerLines)
                errorHEM!.noPost = true
            } else {
                resultHEM = .Sent
                loggerLines = loggerLines + NSLocalizedString("SMTP Connection Test Passed", comment:"") + "\n"
            }
            
            // post the result notification into the main UI thread
            let result:EmailResult = EmailResult(invoker: withEmail.invoker, tagI: withEmail.invoker_tagI, tagS: withEmail.invoker_tagS, result: resultHEM, error: errorHEM, extendedDetails: loggerLines)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .APP_EmailCompleted, object: result)
            }
            return
        } // end of callback
//debugPrint("\(self.mCTAG).testEmailViaMailCore_send MAILQUEUE_THREAD ENDED")
    }
    
    // send the email via SMTP using MailCore
    // THREADING:  this will be called by the MailQueue thread
    private func sendEmailViaMailCore_send(withEmail:EmailPending) {
//debugPrint("\(self.mCTAG).sendEmailViaMailCore_send MAILQUEUE_THREAD STARTED")

        // build up the needed to/cc arrays
        var emailToArray:[MCOAddress] = []
        var emailCCArray:[MCOAddress] = []
        if !(withEmail.to ?? "").isEmpty {
            let emails:[String] = withEmail.to!.components(separatedBy: ",")
            for email in emails {
                emailToArray.append(MCOAddress(displayName: email, mailbox: email))
            }
        }
        if !(withEmail.cc ?? "").isEmpty {
            let emails:[String] = withEmail.cc!.components(separatedBy: ",")
            for email in emails {
                emailCCArray.append(MCOAddress(displayName: email, mailbox: email))
            }
        }
        
        // build the email
        let builder = MCOMessageBuilder()
        if !(withEmail.to ?? "").isEmpty { builder.header.to = emailToArray }
        if !(withEmail.cc ?? "").isEmpty { builder.header.cc = emailCCArray }
        if !withEmail.via.userDisplayName.isEmpty {
            builder.header.from = MCOAddress(displayName: withEmail.via.userDisplayName, mailbox: withEmail.via.sendingEmailAddress)
        } else {
            builder.header.from = MCOAddress(mailbox: withEmail.via.sendingEmailAddress)
        }
        if !(withEmail.subject ?? "").isEmpty { builder.header.subject = withEmail.subject! }
        if !(withEmail.body ?? "").isEmpty { builder.textBody = withEmail.body! }
        
        if withEmail.includeAttachment != nil {
            let fileName:String = withEmail.includeAttachment!.lastPathComponent
            let withData:Data? = FileManager.default.contents(atPath: withEmail.includeAttachment!.path)
            if withData != nil {
                let attachment = MCOAttachment(data: withData!, filename: fileName)
                if attachment != nil {
                    attachment!.mimeType =  withEmail.attachmentMimeType
                    builder.addAttachment(attachment!)
                }
            }
        }
        
        // open a connection to the email server
        var loggerLines:String = ""
        let smtpSession = MCOSMTPSession()
        smtpSession.dispatchQueue = self.mEmailRunningQueue     // this does not appear to work
        smtpSession.hostname = withEmail.via.emailProvider_SMTP!.hostname
        smtpSession.port = UInt32(withEmail.via.emailProvider_SMTP!.port)
        smtpSession.authType =  withEmail.via.emailProvider_SMTP!.authType
        smtpSession.connectionType = withEmail.via.emailProvider_SMTP!.connectionType
        smtpSession.username = withEmail.via.emailProvider_Credentials?.username
        if withEmail.via.emailProvider_SMTP!.authType == .xoAuth2 || withEmail.via.emailProvider_SMTP!.authType == .xoAuth2Outlook {
            smtpSession.oAuth2Token = withEmail.via.emailProvider_Credentials?.oAuthAccessToken
        } else {
            smtpSession.password = withEmail.via.emailProvider_Credentials?.password
        }
        smtpSession.connectionLogger = {(connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                    var flow:String = ""
                    switch type {
                    case .received:
                        flow = "<= "
                        break
                    case .sent:
                        flow = "=> "
                        break
                    case .sentPrivate:
                        flow = "=> "
                        break
                    case .errorParse:
                        flow = "E "
                        break
                    case .errorReceived:
                        flow = "<E= "
                        break
                    case .errorSent:
                        flow = "=E> "
                        break
                    default:
                        flow = "<=?=> "
                        break
                    }
                    let stringSwift = string as String
debugPrint("\(self.mCTAG).sendEmailViaMailCore_send.Connectionlogger: \(flow)\(stringSwift)")
                    loggerLines = loggerLines + flow + stringSwift
                    if stringSwift.starts(with: "334 ") {
                        let string1:String = String(stringSwift.prefix(stringSwift.count - 1))
                        let string2:String = String(string1.suffix(string1.count - 4))
                        let data1:Data? = Data(base64Encoded: string2)
                        if data1 != nil {
                            let decodedString:String? = String(data: data1!, encoding: .utf8)
                            if decodedString != nil {
debugPrint("\(self.mCTAG).sendEmailViaMailCore_send.Connectionlogger: \(flow) 334 \(decodedString!)")
                                loggerLines = loggerLines + flow + decodedString! + "\r\n"
                            }
                        }
                    }
                }
            }
        }
        
        // send the email; is automatically performed in a different background thread then callback with results
        let rfc822Data = builder.data()
        let sendOperation = smtpSession.sendOperation(with: rfc822Data!)
        sendOperation?.start { (error) -> Void in
            var errorHEM:APP_ERROR? = nil
            var resultHEM:EmailHandler.EmailHandlerResults
            if error != nil {
                errorHEM = APP_ERROR(funcName: "\(self.mCTAG).sendEmailViaMailCore_send", domain: self.mThrowErrorDomain, error: error!, errorCode: .SMTP_EMAIL_SUBSYSTEM_ERROR, userErrorDetails: nil, noAlert: true)
                resultHEM = .Error
                AppDelegate.postAlert(message: AppDelegate.endUserErrorMessage(errorStruct: errorHEM!), extendedDetails: loggerLines)
                errorHEM!.userErrorDetails = NSLocalizedString("See Alerts for error details", comment:"")
                errorHEM!.noPost = true
            } else {
                resultHEM = .Sent
            }
            
            // post the result notification into the main UI thread
            let result:EmailResult = EmailResult(invoker: withEmail.invoker, tagI: withEmail.invoker_tagI, tagS: withEmail.invoker_tagS, result: resultHEM, error: errorHEM, extendedDetails: loggerLines)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .APP_EmailCompleted, object: result)
            }
            return
        } // end of callback
//debugPrint("\(self.mCTAG).sendEmailViaMailCore_send MAILQUEUE_THREAD ENDED")
    }
}

/////////////////////////////////////////////////////////////////////////
// subclass of MFMailComposeViewController
/////////////////////////////////////////////////////////////////////////

// extend the MFMailComposeViewController class to store some needed callback members
public class MFMailComposeViewControllerExt:MFMailComposeViewController {
    // preset members by invoker
    var invoker:String = ""
    var invoker_tagI:Int = 0
    var invoker_tagS:String? = nil
}
