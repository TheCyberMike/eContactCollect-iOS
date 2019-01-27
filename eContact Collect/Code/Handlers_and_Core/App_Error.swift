//
//  App_Error.swift
//  eContact Collect
//
//  Created by Dev on 1/25/19.
//

import Foundation

// App error handling struct that conforms to iOS Error system
public struct APP_ERROR:Error, CustomStringConvertible {
    // member variables
    // user and developer info; these should always be localized
    var domain:String
    var userErrorDetails:String? = nil
    var error:Error? = nil
    var errorCode:APP_ERROR_CODE
    
    // member variables
    // developer info
    var noAlert:Bool = false
    var noPost:Bool = false
    var callStack:String = ""
    var during:String? = nil
    var developerInfo:String? = nil
    
    // init from some other Error
    public init(funcName:String, during:String?=nil, domain:String, error:Error, errorCode:APP_ERROR_CODE, userErrorDetails:String?, developerInfo:String?=nil, noAlert:Bool=false) {
        self.noAlert = noAlert
        self.callStack = funcName
        self.during = during
        self.domain = domain
        self.error = error
        self.errorCode = errorCode
        self.userErrorDetails = userErrorDetails
        self.developerInfo = developerInfo
    }
    
    // init for an App Error
    public init(funcName:String, during:String?=nil, domain:String, errorCode:APP_ERROR_CODE, userErrorDetails:String?, developerInfo:String?=nil, noAlert:Bool=false, noPost:Bool=false) {
        self.noAlert = noAlert
        self.noPost = noPost
        self.callStack = funcName
        self.during = during
        self.domain = domain
        self.error = nil
        self.errorCode = errorCode
        self.userErrorDetails = userErrorDetails
        self.developerInfo = developerInfo
    }
    
#if TESTING
    // compare two APP_ERRORs to an extent possible; only needed during testing
    public func sameAs(baseError:Error) -> Bool {
        if let appError = baseError as? APP_ERROR {
            if self.noAlert != appError.noAlert { return false }
            if self.noPost != appError.noPost { return false }
            if self.callStack != appError.callStack { return false }
            if self.during != appError.during { return false }
            if self.domain != appError.domain { return false }
            if self.errorCode != appError.errorCode { return false }
            if self.userErrorDetails != appError.userErrorDetails { return false }
            if self.developerInfo != appError.developerInfo { return false }
            
            if (self.error != nil && appError.error == nil) || (self.error == nil && appError.error != nil) { return false }
            
        } else { return false }
        return true
    }
#endif
    
    // prepend a function into the internal callstack since symbols are missing from distributed Apps
    public mutating func prependCallStack(funcName:String) {
        self.callStack = funcName + ":" + self.callStack
    }
    
    // get a localized description suitable for an end-user
    public var localizedDescription:String {
        var messageStr:String = "\(self.domain): "
        if !(self.userErrorDetails ?? "").isEmpty { messageStr = messageStr + self.userErrorDetails! + ": " }
        if self.error != nil {
            messageStr = messageStr + "\(self.errorCode.localizedDescription): \(self.error!.localizedDescription)"
        } else {
            messageStr = messageStr + "(\(self.errorCode.rawValue)) \"\(self.errorCode.localizedDescription)\""
        }
        return messageStr
    }
    
    // get a description in english suitable for the developer
    public var description:String {
        var messageStr:String = self.callStack
        if self.during != nil { messageStr = messageStr + " @ \(self.during!)" }
        messageStr = messageStr + " \(self.domain): "
        if !(self.userErrorDetails ?? "").isEmpty { messageStr = messageStr + self.userErrorDetails! + ": " }
        if self.error != nil {
            messageStr = messageStr + "\(self.errorCode.rawValue); \(self.error!.localizedDescription)"
        } else {
            messageStr = messageStr + "(\(self.errorCode.rawValue)) \"\(self.errorCode.description)\""
        }
        if !(self.developerInfo ?? "").isEmpty { messageStr = messageStr + "; " + self.developerInfo! }
        return messageStr
    }
    
    // get a description in english suitable for the developer in multi-line format for the error.log
    public var descriptionForErrorLog:String {
        var messageStr:String = self.callStack
        if self.during != nil { messageStr = messageStr + " @ \(self.during!)" }
        messageStr = messageStr + "\n             " + "\(self.domain): "
        messageStr = messageStr + "(\(self.errorCode.rawValue)) \"\(self.errorCode.description)\""
        if !(self.userErrorDetails ?? "").isEmpty { messageStr = messageStr + "\n             UserMsg: " + self.userErrorDetails! }
        if !(self.developerInfo ?? "").isEmpty { messageStr = messageStr + "\n             DevInfo: " + self.developerInfo! }
        return messageStr
    }
}

// App error codes and their meanings
public enum APP_ERROR_CODE:Int, CustomStringConvertible {
    // APP error codes
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
    case RECORD_MARKED_PARTIAL = -53
    case MISSING_OR_MISMATCHED_FIELD_METADATA = -54
    case MISSING_OR_MISMATCHED_FIELD_OPTIONS = -55
    case MISSING_OR_MISMATCHED_FIELD_OPTIONSET = -56
    
    // provide a description for the end-user in proper language
    public var localizedDescription:String {
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
        case .RECORD_MARKED_PARTIAL:
            return NSLocalizedString("Record is marked partial and cannot be saved", comment:"")
        case .MISSING_OR_MISMATCHED_FIELD_METADATA:
            return NSLocalizedString("Field's metadata is missing or mismatched", comment:"")
        case .MISSING_OR_MISMATCHED_FIELD_OPTIONS:
            return NSLocalizedString("Field's options are missing or mismatched", comment:"")
        case .MISSING_OR_MISMATCHED_FIELD_OPTIONSET:
            return NSLocalizedString("Field's optionSet is missing or mismatched", comment:"")
        }
    }
    
    // provide description for the developer in english
    public var description:String {
        switch self {
        case .NO_ERROR:
            return "No error"
        case .UNKNOWN_ERROR:
            return "Unknown error"
        case .HANDLER_IS_NOT_ENABLED:
            return "Handler is not enabled"
        case .FILESYSTEM_ERROR:
            return "Filesystem Error"
        case .DATABASE_ERROR:
            return "Database Error"
        case .INTERNAL_ERROR:
            return "Internal Error"
        case .MISSING_REQUIRED_CONTENT:
            return "Missing required content"
        case .RECORD_IS_COMPOSED:
            return "Record is composed"
        case .RECORD_NOT_FOUND:
            return "Record not found"
        case .COULD_NOT_CREATE:
            return "Could not create"
        case .COULD_NOT_ACCESS:
            return "Could not access"
        case .DID_NOT_VALIDATE:
            return "Did not validate"
        case .DID_NOT_OPEN:
            return "Did not open"
        case .ORG_DOES_NOT_EXIST:
            return "Oganization does not exist"
        case .RECORD_MARKED_DELETED:
            return "Record is marked deleted and cannot be saved"
        case .RECORD_MARKED_PARTIAL:
            return "Record is marked partial and cannot be saved"
        case .MISSING_OR_MISMATCHED_FIELD_METADATA:
            return "Field's metadata is missing or mismatched"
        case .MISSING_OR_MISMATCHED_FIELD_OPTIONS:
            return "Field's options are missing or mismatched"
        case .MISSING_OR_MISMATCHED_FIELD_OPTIONSET:
            return "Field's optionSet is missing or mismatched"
        }
    }
}
