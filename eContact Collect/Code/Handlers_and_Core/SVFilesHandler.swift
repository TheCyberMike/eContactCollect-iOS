//
//  SVFilesHandler.swift
//  eContact Collect
//
//  Created by Yo on 10/14/18.
//

import Foundation
import SQLite

// base handler class for the pending and sent SV files
// note: access to the Documents directory has been granted to iTunes and the Files App via keys in the pList:
//      UIFileSharing Enabled ("Application supports iTunes file sharing")
//      LSSupportsOpeningDocumentsInPlace ("Supports opening documents in place")
public class SVFilesHandler {
    // member variables
    public var mSVHstatus_state:HandlerStatusStates = .Unknown
    public var mAppError:APP_ERROR? = nil
    
    // member constants and other static content
    internal var mCTAG:String = "HSV"
    internal var mThrowErrorDomain:String = NSLocalizedString("SVFiles-Handler", comment:"")
    public static let mDateFormatString:String = "yyMMdd'_'HHmmss'_'"
    private let mSVSentDirPath:String = "\(AppDelegate.mDocsApp)/SVfiles_sent"
    private let mSVPendingDirPath:String = "\(AppDelegate.mDocsApp)/SVfiles_pending"
    
    // constructor;
    public init() {}
    
    // initialization; returns true if initialize fully succeeded;
    // errors are stored via the class members and will already be posted to the error.log;
    // this handler must be mindful that the database initialization may have failed
    public func initialize(method:String) -> Bool {
//debugPrint("\(mCTAG).initialize STARTED")
        self.mSVHstatus_state = .Unknown
        
        // ensure directories SVFiles_sent and SVFiles_pending are in Documents
        var success:Bool = true
        if !FileManager.default.fileExists(atPath:self.mSVSentDirPath) {
            do {
                try FileManager.default.createDirectory(atPath:self.mSVSentDirPath, withIntermediateDirectories:false, attributes:nil)
            } catch {
                self.mSVHstatus_state = .Errors
                self.mAppError = APP_ERROR(funcName: "\(method):\(self.mCTAG).initialize", during: "createDirectory", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Initialization", comment:""), developerInfo: self.mSVSentDirPath, noAlert: true)
                AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: nil, noAlert: true)
                success = false
            }
        }
        if !FileManager.default.fileExists(atPath:self.mSVPendingDirPath) {
            do {
                try FileManager.default.createDirectory(atPath:self.mSVPendingDirPath, withIntermediateDirectories:false, attributes:nil)
            } catch {
                self.mSVHstatus_state = .Errors
                self.mAppError = APP_ERROR(funcName: "\(method):\(self.mCTAG).initialize", during: "createDirectory", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Initialization", comment:""), developerInfo: self.mSVPendingDirPath, noAlert: true)
                AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: nil, noAlert: true)
                success = false
            }
        }
        if !success { return false }
        self.mSVHstatus_state = .Valid
        
        // get a list of files in SVFiles_sent
        let agingDate:Date = Calendar.current.date(byAdding:.day, value:-7, to:Date())!
        let targetURL = URL(fileURLWithPath:self.mSVSentDirPath, isDirectory:true)
        var fileURLs:[URL]? = nil
        do {
            fileURLs = try FileManager.default.contentsOfDirectory(at:targetURL, includingPropertiesForKeys:nil)
        } catch {
            self.mSVHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: "\(method):\(self.mCTAG).initialize", during: "contentsOfDirectory", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Initialization", comment:""), developerInfo: self.mSVSentDirPath, noAlert: true)
            AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: nil, noAlert: true)
            return false
        }

        // delete any files in SVFiles_sent that are more than 7 days old
        for url in fileURLs! {
            // get the file's attributes
            var attrs:NSDictionary? = nil
            do {
                attrs = try FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary
            } catch {
                self.mSVHstatus_state = .Errors
                self.mAppError = APP_ERROR(funcName: "\(method):\(self.mCTAG).initialize", during: "attributesOfItem", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Initialization", comment:""), developerInfo: url.path, noAlert: true)
                AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: nil, noAlert: true)
                return false
            }
            var fileDate:Date? = nil
            if attrs != nil {
                if attrs!.fileCreationDate() != nil {
                    fileDate = attrs!.fileCreationDate()!
                } else if attrs!.fileModificationDate() != nil {
                    fileDate = attrs!.fileModificationDate()!
                }
            }
            
            // if attributes did not provide the date, then we can extract it from the file name
            if fileDate == nil {
                let splits = url.lastPathComponent.split(separator: "_")
                if splits.count >= 2 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = SVFilesHandler.mDateFormatString
                    fileDate = dateFormatter.date(from:splits[0]+"_"+splits[1]+"_")
                }
            }
            if fileDate != nil {
                if fileDate! <= agingDate {
                    // file is older than 7 days, delete it
                    do {
                        try FileManager.default.removeItem(atPath:url.path)
                    } catch {
                        self.mSVHstatus_state = .Errors
                        self.mAppError = APP_ERROR(funcName: "\(method):\(self.mCTAG).initialize", during: "removeItem", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Initialization", comment:""), developerInfo: url.path, noAlert: true)
                        AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: nil, noAlert: true)
                        return false
                    }
                }
            }
        }
        return true
    }
    
    // first-time setup is needed;
    // this handler must be mindful that if it or the database handler may not have properly initialized that this should be bypassed;
    // errors are stored via the class members and will already be posted to the error.log
    public func firstTimeSetup(method:String) {
//debugPrint("\(mCTAG).firstTimeSetup STARTED")
        // none at this time
    }

    // return whether the handler is fully operational
    public func isReady() -> Bool {
        if self.mSVHstatus_state == .Valid { return true }
        return false
    }
    
    // this will not get called during normal App operation, but does get called during Unit and UI Testing
    // perform any shutdown that may be needed
    internal func shutdown() {
        self.mSVHstatus_state = .Unknown
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // public methods
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // return the full file path for a filename in the Pending directory
    public func makePendingFullPath(fileName:String) -> String {
        return "\(self.mSVPendingDirPath)/\(fileName)"
    }
    
    // return the full file path for a filename in the Sent directory
    public func makeSentFullPath(fileName:String) -> String {
        return "\(self.mSVSentDirPath)/\(fileName)"
    }
    
    // indicate whether there are any pending files
    // throws exceptions for errors
    public func anyPendingFiles() throws -> Bool {
        let targetURL = URL(fileURLWithPath:self.mSVPendingDirPath, isDirectory:true)
        do {
            let urls:[URL] = try FileManager.default.contentsOfDirectory(at:targetURL, includingPropertiesForKeys: nil)
            for url in urls {
                if !url.lastPathComponent.starts(with: ".") { return true } // ignore all .* files
            }
        } catch {
            throw APP_ERROR(funcName: "\(self.mCTAG).anyPendingFiles", during: "contentsOfDirectory", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: nil, developerInfo: targetURL.path)
        }
        return false
    }

    // return a list of all files in the Pending directory in descending order by filename
    // throws exceptions for errors
    public func getPendingFiles() throws -> [URL] {
        let targetURL = URL(fileURLWithPath:self.mSVPendingDirPath, isDirectory:true)
        do {
            let urls:[URL] = try FileManager.default.contentsOfDirectory(at:targetURL, includingPropertiesForKeys: nil).sorted(by: {$0.lastPathComponent > $1.lastPathComponent })
            var results:[URL] = []
            for url in urls {
                if !url.lastPathComponent.starts(with: ".") { results.append(url) } // ignore all .* files
            }
            return results
        } catch {
            throw APP_ERROR(funcName: "\(self.mCTAG).getPendingFiles", during: "contentsOfDirectory", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: nil, developerInfo: targetURL.path)
        }
    }
    
    // return a list of all files in the Sent directory in descending order by filename
    // throws exceptions for errors
    public func getSentFiles() throws -> [URL] {
        let targetURL = URL(fileURLWithPath:self.mSVSentDirPath, isDirectory:true)
        do {
            let urls:[URL] = try FileManager.default.contentsOfDirectory(at:targetURL, includingPropertiesForKeys: nil).sorted(by: {$0.lastPathComponent > $1.lastPathComponent })
            var results:[URL] = []
            for url in urls {
                if !url.lastPathComponent.starts(with: ".") { results.append(url) } // ignore all .* files
            }
            return results
        } catch {
            throw APP_ERROR(funcName: "\(self.mCTAG).getSentFiles", during: "contentsOfDirectory", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: nil, developerInfo: targetURL.path)
        }
    }
    
    // delete a pending file
    // throws exceptions for errors
    public func deletePendingFile(fileName:String) throws {
        let targetPath:String = self.mSVPendingDirPath + "/" + fileName
        do {
            try FileManager.default.removeItem(atPath:targetPath)
        } catch {
            throw APP_ERROR(funcName: "\(self.mCTAG).deletePendingFile", during: "removeItem", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: nil, developerInfo: targetPath)
        }
    }

    // delete a sent file
    // throws exceptions for errors
    public func deleteSentFile(fileName:String) throws {
        let targetPath:String = self.mSVSentDirPath + "/" + fileName
        do {
            try FileManager.default.removeItem(atPath:targetPath)
        } catch {
            throw APP_ERROR(funcName: "\(self.mCTAG).deleteSentFile", during: "removeItem", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: nil, developerInfo: targetPath)
        }
    }
    
    // move a file from Pending to Sent
    // throws exceptions for errors
    public func movePendingToSent(fileName:String) throws {
        let sourcePath:String = self.mSVPendingDirPath + "/" + fileName
        let targetPath:String = self.mSVSentDirPath + "/" + fileName
        do {
            try FileManager.default.moveItem(atPath:sourcePath, toPath:targetPath)
        } catch {
            throw APP_ERROR(funcName: "\(self.mCTAG).movePendingToSent", during: "moveItem", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: nil, developerInfo: sourcePath + " to " + targetPath)
        }
    }
    
    // private structure for the generateNewSVFiles() function
    private struct OrgFormPair: Equatable {
        var orgShortName:String
        var formShortName:String
        init(org:String, form:String) {
            orgShortName = org
            formShortName = form
        }
        static func == (lhs: OrgFormPair, rhs: OrgFormPair) -> Bool {
            return lhs.orgShortName == rhs.orgShortName && lhs.formShortName == rhs.formShortName
        }
    }
    
    // generate new SV files for all pending contacts in the RecContactsCollected Table
    // throws exceptions for errors
    public func generateNewSVFiles() throws -> Bool {
        // pre-parse the RecCollectedContacts building up a list of Org:Form pairs
        // get all the RecContactsCollected for the particular Org and Form
        let pairs:NSMutableArray = NSMutableArray()
        if AppDelegate.mEntryFormProvisioner != nil {
            let records:AnySequence<Row> = try RecContactsCollected.ccGetAllRecs(forOrgShortName: AppDelegate.mEntryFormProvisioner!.mOrgRec.rOrg_Code_For_SV_File)
            for rowRec in records {
                let ccRec = try RecContactsCollected(row:rowRec)
                let pair = OrgFormPair(org:ccRec.rOrg_Code_For_SV_File, form:ccRec.rForm_Code_For_SV_File)
                var found:Bool = false
                for po in pairs {
                    let havePair:OrgFormPair = po as! OrgFormPair
                    if havePair == pair { found = true }
                }
                if !found { pairs.add(pair) }
            }
        }
        
        // generate a SV file for each Org:Form pair
        for po in pairs {
            let pair:OrgFormPair = po as! OrgFormPair
            do {
                if try generateNewSVFile(forOrgShortName:pair.orgShortName, forFormShortName:pair.formShortName) {
                    // successful; delete any CC records that have status "Generated"
                    let _ = try RecContactsCollected.ccDeleteGeneratedRecs()
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: "\(self.mCTAG).generateNewSVFiles")
                throw appError
            } catch { throw error }
        }
        
        return true
    }
    
    // used only during a factory reset to delete all pending and sent files
    // throws exceptions for errors
    public func deleteAll() throws {
        // get a list of files in SVFiles_pending then delete them all
        
        self.mAppError = nil
        var fileURLs1:[URL]? = nil
        do {
            let targetURL = URL(fileURLWithPath:self.mSVPendingDirPath, isDirectory:true)
            fileURLs1 = try FileManager.default.contentsOfDirectory(at:targetURL, includingPropertiesForKeys:nil)
        } catch {
            self.mSVHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).deleteAll", during: "contentsOfDirectory", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Factory Reset", comment:""), developerInfo: "pending: "+self.mSVPendingDirPath)
            // do not throw yet so deletes in other directory may happen
        }
        if fileURLs1 != nil {
            for url in fileURLs1! {
                do {
                    try FileManager.default.removeItem(atPath:url.path)
                } catch {
                    self.mSVHstatus_state = .Errors
                    self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).deleteAll", during: "removeItem", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Factory Reset", comment:""), developerInfo: "pending: "+url.path)
                }
            }
            if self.mAppError != nil { throw self.mAppError! }  // if got errors at this point then throw
        }
        
        
        // get a list of files in SVFiles_sent then delete them all
        var fileURLs2:[URL]? = nil
        do {
            let targetURL = URL(fileURLWithPath:self.mSVSentDirPath, isDirectory:true)
            fileURLs2 = try FileManager.default.contentsOfDirectory(at:targetURL, includingPropertiesForKeys:nil)
            
        } catch {
            self.mSVHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).deleteAll", during: "contentsOfDirectory", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Factory Reset", comment:""), developerInfo: "sent: "+self.mSVSentDirPath)
            throw self.mAppError!
        }
        if fileURLs2 != nil {
            for url in fileURLs2! {
                do {
                    try FileManager.default.removeItem(atPath:url.path)
                } catch {
                    self.mSVHstatus_state = .Errors
                    self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).deleteAll", during: "removeItem", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Factory Reset", comment:""), developerInfo: "sent: "+url.path)
                }
            }
            if self.mAppError != nil { throw self.mAppError! }  // if got errors at this point then throw
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // private methods
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // generate one new SV file
    // throws exceptions for errors
    private func generateNewSVFile(forOrgShortName:String, forFormShortName:String) throws -> Bool {
        // obtain the Org and OrgForm Records
        var orgRec:RecOrganizationDefs?
        var formRec:RecOrgFormDefs?
        do {
            orgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName:forOrgShortName)
            formRec = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName:forFormShortName, forOrgShortName:forOrgShortName)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).generateNewSVFile")
        } catch { throw error }
        if orgRec == nil {
            throw APP_ERROR(funcName: "\(self.mCTAG).generateNewSVFile", during: "orgGetSpecifiedRecOfShortName", domain: self.mThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: NSLocalizedString("Export Preparation for ", comment:"")+NSLocalizedString("Organization record", comment:""), developerInfo: forOrgShortName)
        }
        if formRec == nil {
            throw APP_ERROR(funcName: "\(self.mCTAG).generateNewSVFile", during: "orgFormGetSpecifiedRecOfShortName", domain: self.mThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: NSLocalizedString("Export Preparation for ", comment:"")+NSLocalizedString("Form record", comment:""), developerInfo: forFormShortName)
        }
        
        // prep the date of the file
        let formatter = DateFormatter()
        formatter.dateFormat = SVFilesHandler.mDateFormatString
        let dateTimeString:String = formatter.string(from: Date())

        // prep the file path and file name and extension
        var filePath:String = self.mSVPendingDirPath + "/\(dateTimeString)\(forOrgShortName)_\(forFormShortName)"
        switch formRec!.rForm_SV_File_Type {
        case .TEXT_TAB_DELIMITED_WITH_HEADERS:
            filePath = filePath + ".txt"
            break
        case .TEXT_COMMA_DELIMITED_WITH_HEADERS:
            filePath = filePath + ".csv"        // add sep=,
            break
        case .TEXT_SEMICOLON_DELIMITED_WITH_HEADERS:
            filePath = filePath + ".csv"        // add sep=;
            break
        case .XML_ATTTRIB_VALUE_PAIRS:
            filePath = filePath + ".xml"
            break
        }
//debugPrint("\(mCTAG).generateNewSVFile PATH=\(filePath)")
        
        // creeate and open the file for writing and initialize it if appropriate
        if !(FileManager.default.createFile(atPath:filePath, contents:nil, attributes: [FileAttributeKey.extensionHidden: false])) {
            throw APP_ERROR(funcName: "\(self.mCTAG).generateNewSVFile", during: "createFile", domain: self.mThrowErrorDomain, errorCode: .COULD_NOT_CREATE, userErrorDetails: NSLocalizedString("Export SV File", comment:""), developerInfo: filePath)
        }
        let fileHandle:FileHandle? = FileHandle(forWritingAtPath:filePath)
        if fileHandle == nil {
            throw APP_ERROR(funcName: "\(self.mCTAG).generateNewSVFile", during: "FileHandle.forWritingAtPath", domain: self.mThrowErrorDomain, errorCode: .COULD_NOT_ACCESS, userErrorDetails: NSLocalizedString("Export SV File", comment:""), developerInfo: filePath)
        }
        switch formRec!.rForm_SV_File_Type {
        case .TEXT_TAB_DELIMITED_WITH_HEADERS:
            break
        case .TEXT_COMMA_DELIMITED_WITH_HEADERS:
            fileHandle!.write("sep=,\r\n".data(using:String.Encoding.utf8)!)
            break
        case .TEXT_SEMICOLON_DELIMITED_WITH_HEADERS:
            fileHandle!.write("sep=;\r\n".data(using:String.Encoding.utf8)!)
            break
        case .XML_ATTTRIB_VALUE_PAIRS:
            fileHandle!.write("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\r\n".data(using:String.Encoding.utf8)!)
            if formRec!.rForm_XML_Collection_Tag.isEmpty {
                fileHandle!.write("<contacts>\r\n".data(using:String.Encoding.utf8)!)
            } else {
                fileHandle!.write("<\(formRec!.rForm_XML_Collection_Tag)>\r\n".data(using:String.Encoding.utf8)!)
            }
            break
        }
        
        // get all the RecContactsCollected for the particular Org and Form
        let records:AnySequence<Row> = try RecContactsCollected.ccGetAllRecs(forOrgShortName:forOrgShortName, forFormShortName:forFormShortName)
        
        // step thru all the retrieved collected contacts
        var xmlRecordTag = "  <contact>\r\n"
        var xmlRecordTagCloser = "  </contact>\r\n"
        if !formRec!.rForm_XML_Record_Tag.isEmpty {
            xmlRecordTag = "  <\(formRec!.rForm_XML_Record_Tag)>\r\n"
            xmlRecordTagCloser = "  </\(formRec!.rForm_XML_Record_Tag)>\r\n"
        }
        var lastHeaders:String = ""
        for rowRec in records {
            let ccRec = try RecContactsCollected(row:rowRec)
            if ccRec.rCC_Importance != nil || ccRec.rCC_Collector_Notes != nil {
                var metaComponents = ccRec.rCC_MetadataValues.components(separatedBy: "\t")
                if ccRec.rCC_Importance != nil {
                    if !(ccRec.rCC_Importance!.isEmpty) {
                        metaComponents[ccRec.rCC_Importance_Position] = ccRec.rCC_Importance!
                    }
                }
                if ccRec.rCC_Collector_Notes != nil {
                    if !(ccRec.rCC_Collector_Notes!.isEmpty) {
                        metaComponents[ccRec.rCC_Collector_Notes_Position] = ccRec.rCC_Collector_Notes!
                    }
                }
                ccRec.rCC_MetadataValues = metaComponents.joined(separator: "\t")
//debugPrint("\(mCTAG).generateNewSVFile \(ccRec.rCC_Composed_Name) INSERT=\(ccRec.rCC_MetadataValues)")
            }
            if formRec!.rForm_SV_File_Type == .XML_ATTTRIB_VALUE_PAIRS {
                // XML format
                var recordString = xmlRecordTag
                recordString = recordString + self.makeXML(attribs:ccRec.rCC_EnteredAttribs, values:ccRec.rCC_EnteredValues)
                recordString = recordString + self.makeXML(attribs:ccRec.rCC_MetadataAttribs, values:ccRec.rCC_MetadataValues)
                recordString = recordString + xmlRecordTagCloser
                fileHandle!.write(recordString.data(using:String.Encoding.utf8)!)
            } else {
                var headers = "H\t" + ccRec.rCC_EnteredAttribs + ccRec.rCC_MetadataAttribs + "\r\n"
                if headers != lastHeaders {
                    if formRec!.rForm_SV_File_Type == .TEXT_COMMA_DELIMITED_WITH_HEADERS {
                        headers = headers.replacingOccurrences(of: "\t", with: ",")
                    } else if formRec!.rForm_SV_File_Type == .TEXT_SEMICOLON_DELIMITED_WITH_HEADERS {
                        headers = headers.replacingOccurrences(of: "\t", with: ";")
                    }
                    fileHandle!.write(headers.data(using:String.Encoding.utf8)!)
                    lastHeaders = headers
                }
                var recordString = "D\t" + ccRec.rCC_EnteredValues + ccRec.rCC_MetadataValues + "\r\n"
                if formRec!.rForm_SV_File_Type == .TEXT_COMMA_DELIMITED_WITH_HEADERS {
                    recordString = recordString.replacingOccurrences(of: "\t", with: ",")
                } else if formRec!.rForm_SV_File_Type == .TEXT_SEMICOLON_DELIMITED_WITH_HEADERS {
                    recordString = recordString.replacingOccurrences(of: "\t", with: ";")
                }
                fileHandle!.write(recordString.data(using:String.Encoding.utf8)!)
            }
            
            // tag the record as having been generated into a SV File
            ccRec.rCC_Status = .Generated
            _ = try ccRec.saveChangesToDB(originalCCRec:ccRec)
        }
        
        // handle any final insertions before closing the file
        switch formRec!.rForm_SV_File_Type {
        case .XML_ATTTRIB_VALUE_PAIRS:
            if formRec!.rForm_XML_Collection_Tag.isEmpty {
                fileHandle!.write("</contacts>\r\n".data(using:String.Encoding.utf8)!)
            } else {
                fileHandle!.write("</\(formRec!.rForm_XML_Collection_Tag)>\r\n".data(using:String.Encoding.utf8)!)
            }
            break
        default:
            break
        }
        fileHandle!.synchronizeFile()
        fileHandle!.closeFile()
        return true
    }
    
    // convert the attrib and value pairs into xml format
    private func makeXML(attribs:String, values:String) -> String {
        var resultsString:String = ""
        let attribsSplit = attribs.split(separator: "\t", omittingEmptySubsequences:false)
        let valuesSplit = values.split(separator: "\t", omittingEmptySubsequences:false)
        for counter in 0...attribsSplit.count - 1 {
            if !(attribsSplit[counter].isEmpty) {
                resultsString = resultsString + "    <\(attribsSplit[counter])>\(valuesSplit[counter])</\(attribsSplit[counter])>\r\n"
            }
        }
        return resultsString
    }
}
