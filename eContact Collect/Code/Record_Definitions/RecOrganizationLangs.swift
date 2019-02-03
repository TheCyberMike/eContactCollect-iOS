//
//  RecOrganizationLangs.swift
//  eContact Collect
//
//  Created by Yo on 10/25/18.
//

import UIKit
import SQLite

// special-use version of the record that is all optional; used for importing JSON records and
// specialized database queries if not every field will to be loaded; this record cannot be saved to the database
public class RecOrganizationLangs_Optionals {
    // record members
    public var rOrg_Code_For_SV_File:String?
    public var rOrgLang_LangRegionCode:String?
    public var rOrgLang_Lang_Title_EN:String?
    public var rOrgLang_Lang_Title_SVFile:String?
    public var rOrgLang_Lang_Title_Shown:String?
    public var rOrgLang_Lang_Image_PNG_Blob:Data?
    public var rOrgLang_Org_Title_Shown:String?
    public var rOrgLang_Event_Title_Shown:String?

    // constructor creates the record from the results of a database query; is tolerant of missing columns
    init(row:Row) {
        // note: do NOT use the COL_EXPRESSION_* above since these are all set as optional in case the original query did not select all columns
        self.rOrg_Code_For_SV_File = row[Expression<String?>(RecOrganizationLangs.COLUMN_ORG_CODE_FOR_SV_FILE)]
        self.rOrgLang_LangRegionCode = row[Expression<String?>(RecOrganizationLangs.COLUMN_ORGLANG_LANGREGIONCODE)]
        self.rOrgLang_Lang_Title_EN = row[Expression<String?>(RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_EN)]
        self.rOrgLang_Lang_Title_Shown = row[Expression<String?>(RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SHOWN)]
        self.rOrgLang_Lang_Title_SVFile = row[Expression<String?>(RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SVFILE)]
        self.rOrgLang_Org_Title_Shown = row[Expression<String?>(RecOrganizationLangs.COLUMN_ORGLANG_ORG_TITLE_SHOWN)]
        self.rOrgLang_Event_Title_Shown = row[Expression<String?>(RecOrganizationLangs.COLUMN_ORGLANG_EVENT_TITLE_SHOWN)]
        self.rOrgLang_Lang_Image_PNG_Blob = row[Expression<Data?>(RecOrganizationLangs.COLUMN_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB)]
    }
    
    // constructor creates the record from a json record
    init(jsonRec:RecJsonLangDefs, forOrgShortName:String) {
        self.rOrg_Code_For_SV_File = forOrgShortName
        self.rOrgLang_LangRegionCode = jsonRec.mLang_LangRegionCode
        self.rOrgLang_Lang_Title_EN = jsonRec.rLang_Name_English
        self.rOrgLang_Lang_Title_Shown = jsonRec.rLang_Name_Speaker
        self.rOrgLang_Lang_Image_PNG_Blob = jsonRec.rLang_Icon_PNG_Blob
        self.rOrgLang_Lang_Title_SVFile = nil
        self.rOrgLang_Org_Title_Shown = nil
        self.rOrgLang_Event_Title_Shown = nil
    }

    // constructor creates the record from a JSON object; is tolerant of missing columns;
    // must be tolerant that Int64's may be encoded as Strings, especially OIDs;
    // context is provided in case database version or language of the JSON file is important
    init(jsonObj:NSDictionary, context:DatabaseHandler.ValidateJSONdbFile_Result) {
        self.rOrg_Code_For_SV_File = jsonObj[RecOrganizationLangs.COLUMN_ORG_CODE_FOR_SV_FILE] as? String
        self.rOrgLang_LangRegionCode = jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANGREGIONCODE] as? String
        self.rOrgLang_Lang_Title_EN = jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_EN] as? String
        self.rOrgLang_Lang_Title_Shown = jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SHOWN] as? String
        self.rOrgLang_Lang_Title_SVFile = jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SVFILE] as? String
        self.rOrgLang_Org_Title_Shown = jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_ORG_TITLE_SHOWN] as? String
        self.rOrgLang_Event_Title_Shown = jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_EVENT_TITLE_SHOWN] as? String

        // encode the language logo PNG
        let value50:String? = jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB] as? String
        if value50 != nil { self.rOrgLang_Lang_Image_PNG_Blob = Data(base64Encoded: value50!) }
        else { self.rOrgLang_Lang_Image_PNG_Blob = nil }
    }
    
    // is the optionals record valid in terms of required content?
    public func validate() -> Bool {
        if self.rOrg_Code_For_SV_File == nil || self.rOrgLang_LangRegionCode == nil || self.rOrgLang_Lang_Title_SVFile == nil || self.rOrgLang_Lang_Title_Shown == nil { return false }
        if self.rOrg_Code_For_SV_File!.isEmpty || self.rOrgLang_LangRegionCode!.isEmpty || self.rOrgLang_Lang_Title_SVFile!.isEmpty || self.rOrgLang_Lang_Title_Shown!.isEmpty { return false }
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Main Record
/////////////////////////////////////////////////////////////////////////

// full verson of the record; required fields are enforced; can be saved to the database
// this is effectively a subtable of RecOrganizationDefs with a many-to-one relationship
public class RecOrganizationLangs {
    // record members
    public var rOrg_Code_For_SV_File:String             // short code name for the organization; shown only to Collector; primary key
    public var rOrgLang_LangRegionCode:String           // ISO language-region code; primary key
    public var rOrgLang_Lang_Title_EN:String            // name of the language written in English
    public var rOrgLang_Lang_Title_SVFile:String        // name of the language written in the SV-File's language
    public var rOrgLang_Lang_Title_Shown:String         // name of the language written in the languages speaker's language
    public var rOrgLang_Lang_Image_PNG_Blob:Data?       // small flag or icon that represents the language (stored in 3x size as PNG)
    public var rOrgLang_Org_Title_Shown:String?         // text title for the organization shown to end-users
    public var rOrgLang_Event_Title_Shown:String?       // optional-event: name shown to end-users
    
    // member variables
    public var mDuringEditing_isPartial:Bool = false    // during Editing, the record is marked as placeholder added
    public var mDuringEditing_isDeleted:Bool = false    // during Editing, the record is marked as deleted
    
    // member constants and other static content
    private static let mCTAG:String = "ROL"
    public static let TABLE_NAME = "OrganizationLangs"
    public static let COLUMN_ORG_CODE_FOR_SV_FILE = "org_code_sv_file"
    public static let COLUMN_ORGLANG_LANGREGIONCODE = "orglang_langregioncode"
    public static let COLUMN_ORGLANG_LANG_TITLE_EN = "orglang_lang_title_en"
    public static let COLUMN_ORGLANG_LANG_TITLE_SHOWN = "orglang_lang_title_shown"
    public static let COLUMN_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB = "orglang_lang_image_png_blob"
    public static let COLUMN_ORGLANG_LANG_TITLE_SVFILE = "orglang_lang_title_sv_file"
    public static let COLUMN_ORGLANG_ORG_TITLE_SHOWN = "orglang_org_title_shown"
    public static let COLUMN_ORGLANG_EVENT_TITLE_SHOWN = "orglang_event_title_shown"
    
    // these are the as-stored in the database expression definitions
    public static let COL_EXPRESSION_ORG_CODE_FOR_SV_FILE = Expression<String>(RecOrganizationLangs.COLUMN_ORG_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_ORGLANG_LANGREGIONCODE = Expression<String>(RecOrganizationLangs.COLUMN_ORGLANG_LANGREGIONCODE)
    public static let COL_EXPRESSION_ORGLANG_LANG_TITLE_EN = Expression<String>(RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_EN)
    public static let COL_EXPRESSION_ORGLANG_LANG_TITLE_SHOWN = Expression<String>(RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SHOWN)
    public static let COL_EXPRESSION_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB = Expression<Data?>(RecOrganizationLangs.COLUMN_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB)
    public static let COL_EXPRESSION_ORGLANG_LANG_TITLE_SVFILE = Expression<String>(RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SVFILE)
    public static let COL_EXPRESSION_ORGLANG_ORG_TITLE_SHOWN = Expression<String?>(RecOrganizationLangs.COLUMN_ORGLANG_ORG_TITLE_SHOWN)
    public static let COL_EXPRESSION_ORGLANG_EVENT_TITLE_SHOWN = Expression<String?>(RecOrganizationLangs.COLUMN_ORGLANG_EVENT_TITLE_SHOWN)
    
    // generate the string that will create the table
    public static func generateCreateTableString() -> String {
        return Table(TABLE_NAME).create(ifNotExists: true) { t in
            t.column(COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_ORGLANG_LANGREGIONCODE)
            t.column(COL_EXPRESSION_ORGLANG_LANG_TITLE_EN)
            t.column(COL_EXPRESSION_ORGLANG_LANG_TITLE_SHOWN)
            t.column(COL_EXPRESSION_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB)
            t.column(COL_EXPRESSION_ORGLANG_LANG_TITLE_SVFILE)
            t.column(COL_EXPRESSION_ORGLANG_ORG_TITLE_SHOWN)
            t.column(COL_EXPRESSION_ORGLANG_EVENT_TITLE_SHOWN)
            t.primaryKey(COL_EXPRESSION_ORG_CODE_FOR_SV_FILE, COL_EXPRESSION_ORGLANG_LANGREGIONCODE)
        }
    }
    
    // constructor creates the record from default iOS values which can be overriden later
    init(langRegion_code:String, withOrgRec:RecOrganizationDefs) {
        self.rOrg_Code_For_SV_File = withOrgRec.rOrg_Code_For_SV_File
        self.rOrgLang_LangRegionCode = langRegion_code
        self.rOrgLang_Lang_Title_SVFile = AppDelegate.makeFullDescription(forLangRegion: langRegion_code, inLangRegion: withOrgRec.rOrg_LangRegionCode_SV_File, noCode: true)
        self.rOrgLang_Lang_Title_Shown = AppDelegate.makeFullDescription(forLangRegion: langRegion_code, inLangRegion: langRegion_code, noCode: true)
        self.rOrgLang_Lang_Title_EN = AppDelegate.makeFullDescription(forLangRegion: langRegion_code, inLangRegion: "en", noCode: true)
    }
    
    // constructor creates the record from entered values; allow for a deferred setting of the rOrg_Code_For_SV_File
    init(org_code_sv_file:String, langRegion_code:String, lang_title_en:String, lang_title_shown:String, lang_image_png:Data?, lang_title_svfile:String) {
        self.rOrg_Code_For_SV_File = org_code_sv_file
        self.rOrgLang_LangRegionCode = langRegion_code
        self.rOrgLang_Lang_Title_EN = lang_title_en
        self.rOrgLang_Lang_Title_Shown = lang_title_shown
        self.rOrgLang_Lang_Image_PNG_Blob = lang_image_png
        self.rOrgLang_Lang_Title_SVFile = lang_title_svfile
        self.rOrgLang_Org_Title_Shown = nil
        self.rOrgLang_Event_Title_Shown = nil
    }
    
    // import an optionals record into the mainline record
    // throws upon missing required fields; caller is responsible to error.log
    init(existingRec:RecOrganizationLangs_Optionals) throws {
        if existingRec.rOrg_Code_For_SV_File == nil || existingRec.rOrgLang_LangRegionCode == nil || existingRec.rOrgLang_Lang_Title_SVFile == nil || existingRec.rOrgLang_Lang_Title_Shown == nil {
            throw APP_ERROR(funcName: "\(RecOrganizationLangs.mCTAG).init(RecOrganizationLangs_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required == nil")
        }
        if existingRec.rOrg_Code_For_SV_File!.isEmpty || existingRec.rOrgLang_LangRegionCode!.isEmpty || existingRec.rOrgLang_Lang_Title_SVFile!.isEmpty || existingRec.rOrgLang_Lang_Title_Shown!.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrganizationLangs.mCTAG).init(RecOrganizationLangs_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }

        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File!
        self.rOrgLang_LangRegionCode = existingRec.rOrgLang_LangRegionCode!
        self.rOrgLang_Lang_Title_EN = existingRec.rOrgLang_Lang_Title_EN!
        self.rOrgLang_Lang_Title_Shown = existingRec.rOrgLang_Lang_Title_Shown!
        self.rOrgLang_Lang_Title_SVFile = existingRec.rOrgLang_Lang_Title_SVFile!
        self.rOrgLang_Lang_Image_PNG_Blob = existingRec.rOrgLang_Lang_Image_PNG_Blob
        self.rOrgLang_Org_Title_Shown = existingRec.rOrgLang_Org_Title_Shown
        self.rOrgLang_Event_Title_Shown = existingRec.rOrgLang_Event_Title_Shown
    }
    
    // constructor creates the record from the results of a database query
    // throws upon missing required columns from the database (already error.logs them)
    init(row:Row) throws {
        do {
            self.rOrg_Code_For_SV_File = try row.get(RecOrganizationLangs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            self.rOrgLang_LangRegionCode = try row.get(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANGREGIONCODE)
            self.rOrgLang_Lang_Title_EN = try row.get(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANG_TITLE_EN)
            self.rOrgLang_Lang_Title_Shown = try row.get(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANG_TITLE_SHOWN)
            self.rOrgLang_Lang_Title_SVFile = try row.get(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANG_TITLE_SVFILE)
            self.rOrgLang_Lang_Image_PNG_Blob = try row.get(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB)
            self.rOrgLang_Org_Title_Shown = try row.get(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_ORG_TITLE_SHOWN)
            self.rOrgLang_Event_Title_Shown = try row.get(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_EVENT_TITLE_SHOWN)
        } catch {
            let appError = APP_ERROR(funcName: "\(RecOrganizationLangs.mCTAG).init(Row)", domain: DatabaseHandler.ThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: RecOrganizationLangs.TABLE_NAME)
            throw appError
        }
    }
    
    // create an array of setters usable for database Insert or Update; will return nil if the record is incomplete and therefore not eligible to be stored
    // use 'exceptKey' for Update operations to ensure the key fields cannot be changed
    // throws errors if record cannot be saved to the database; caller is responsible to error.log them
    public func buildSetters(exceptKey:Bool=false) throws -> [Setter] {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rOrgLang_LangRegionCode.isEmpty || self.rOrgLang_Lang_Title_SVFile.isEmpty || self.rOrgLang_Lang_Title_Shown.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrganizationLangs.mCTAG).buildSetters", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        
        var retArray = [Setter]()
        
        if !exceptKey { retArray.append(RecOrganizationLangs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE <- self.rOrg_Code_For_SV_File) }
        retArray.append(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANGREGIONCODE <- self.rOrgLang_LangRegionCode)
        retArray.append(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANG_TITLE_EN <- self.rOrgLang_Lang_Title_EN)
        retArray.append(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANG_TITLE_SHOWN <- self.rOrgLang_Lang_Title_Shown)
        retArray.append(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANG_TITLE_SVFILE <- self.rOrgLang_Lang_Title_SVFile)
        retArray.append(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_ORG_TITLE_SHOWN <- self.rOrgLang_Org_Title_Shown)
        retArray.append(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_EVENT_TITLE_SHOWN <- self.rOrgLang_Event_Title_Shown)
        retArray.append(RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB <- self.rOrgLang_Lang_Image_PNG_Blob)
        
        return retArray
    }

    // build the JSON values; will return null if the record is incomplete and therefore not eligible to be sent;
    // since the recipient may be 32-bit, send all Int64 as strings
    public func buildJSONObject() -> NSMutableDictionary? {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rOrgLang_LangRegionCode.isEmpty || self.rOrgLang_Lang_Title_SVFile.isEmpty || self.rOrgLang_Lang_Title_Shown.isEmpty { return nil }
        
        let jsonObj:NSMutableDictionary = NSMutableDictionary()
        jsonObj[RecOrganizationLangs.COLUMN_ORG_CODE_FOR_SV_FILE] = self.rOrg_Code_For_SV_File
        jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANGREGIONCODE] = self.rOrgLang_LangRegionCode
        jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_EN] = self.rOrgLang_Lang_Title_EN
        jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SHOWN] = self.rOrgLang_Lang_Title_Shown
        jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SVFILE] = self.rOrgLang_Lang_Title_SVFile
        jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_ORG_TITLE_SHOWN] = self.rOrgLang_Org_Title_Shown
        jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_EVENT_TITLE_SHOWN] = self.rOrgLang_Event_Title_Shown

        // encode the Language Logo PNG
        if self.rOrgLang_Lang_Image_PNG_Blob == nil { jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB] = nil }
        else { jsonObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB] = self.rOrgLang_Lang_Image_PNG_Blob!.base64EncodedString() }
        
        return jsonObj
    }
    
    // finalize a partial/placeholder language record;
    // will be marked as finalized even if an error is thrown;
    // throws filesystem errors when attempting to load from the json defaults files
    public func finalizePartial(svFileLangRegion:String) throws {
        self.mDuringEditing_isPartial = false
        var jsonLangRec:RecJsonLangDefs?
        do {
            jsonLangRec = try AppDelegate.mFieldHandler!.getLangInfo(forLangRegion: self.rOrgLang_LangRegionCode, noSubstitution: true)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrganizationLangs.mCTAG).finalizePartial")
            throw appError
        } catch { throw error }
        
        if jsonLangRec != nil {
            // found a JSON entry for this language
            self.rOrgLang_Lang_Title_EN = jsonLangRec!.rLang_Name_English!
            self.rOrgLang_Lang_Title_Shown = jsonLangRec!.rLang_Name_Speaker!
            self.rOrgLang_Lang_Image_PNG_Blob = jsonLangRec!.rLang_Icon_PNG_Blob
            self.rOrgLang_Lang_Title_SVFile = AppDelegate.makeFullDescription(forLangRegion: jsonLangRec!.mLang_LangRegionCode!, inLangRegion: svFileLangRegion, noCode: true)
        }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Database interaction methods used throughout the application
    /////////////////////////////////////////////////////////////////////////
    
    // return the quantity of Org records
    // throws exceptions either for local errors or from the database
    /*public static func orgGetQtyRecs() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
        }
        return try AppDelegate.mDatabaseHandler!.genericQueryQty(method:"\(self.mCTAG).orgGetQtyRecs", table:Table(RecOrganizationLangs.TABLE_NAME), whereStr:nil, valuesBindArray:nil)
    }*/
    
    // get all OrgLang records (which could be none)
    // throws exceptions either for local errors or from the database
    public static func orgLangGetAllRecs(orgShortName:String) throws -> AnySequence<Row> {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgLangGetAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrganizationLangs.TABLE_NAME).select(*).filter(RecOrganizationLangs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == orgShortName)
        return try AppDelegate.mDatabaseHandler!.genericQuery(method:"\(self.mCTAG).orgLangGetAllRecs", tableQuery:query)
    }
    
    // get one specific Org record by short name
    // throws exceptions either for local errors or from the database
    // null indicates the record was not found
    /*public static func orgGetSpecifiedRecOfShortName(orgShortName:String) throws -> RecOrganizationLangs? {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
        }
        let query = Table(RecOrganizationLangs.TABLE_NAME).select(*).filter(RecOrganizationLangs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == orgShortName)
        let record = try AppDelegate.mDatabaseHandler!.genericQueryOne(method:"\(self.mCTAG).orgGetSpecifiedRecOfShortName", tableQuery:query)
        if record == nil { return nil }
        return RecOrganizationLangs(row:record!)
    }*/
    
    // add an Org entry; return is the RowID of the new record (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveToDB() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrganizationLangs.mCTAG).saveToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        guard !self.mDuringEditing_isDeleted else {
            throw APP_ERROR(funcName: "\(RecOrganizationLangs.mCTAG).saveToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_MARKED_DELETED, userErrorDetails: nil, developerInfo: RecOrganizationLangs.TABLE_NAME, noAlert: true)
        }
        guard !self.mDuringEditing_isPartial else {
            throw APP_ERROR(funcName: "\(RecOrganizationLangs.mCTAG).saveToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_MARKED_PARTIAL, userErrorDetails: nil, developerInfo: RecOrganizationLangs.TABLE_NAME, noAlert: true)
        }
        
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrganizationLangs.mCTAG).saveToDB")
            throw appError
        } catch { throw error}
        
        return try AppDelegate.mDatabaseHandler!.insertRec(method: "\(RecOrganizationLangs.mCTAG).saveToDB", table: Table(RecOrganizationLangs.TABLE_NAME), cv: setters, orReplace: true, noAlert: false)
    }
    
    // replace an Org entry; return is the quantity of replaced records (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    /*public func saveChangesToDB(originalOrgRec:RecOrganizationLangs) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
        }
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrganizationLangs.mCTAG).saveChangesToDB")
            throw appError
        } catch { throw error}
        let query = Table(RecOrganizationLangs.TABLE_NAME).select(*).filter(RecOrganizationLangs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == originalOrgRec.rOrg_Code_For_SV_File!)
        let qty = try AppDelegate.mDatabaseHandler!.updateRec(method:"\(RecOrganizationLangs.mCTAG).saveChangesToDB", tableQuery:query, cv:setters!)
        return qty
    }*/
    
    // delete the OrgLang record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public func deleteFromDB() throws -> Int {
        do {
            return try RecOrganizationLangs.orgLangDeleteRec(orgShortName: self.rOrg_Code_For_SV_File, langRegionCode: self.rOrgLang_LangRegionCode)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrganizationLangs.mCTAG).deleteFromDB")
            throw appError
        } catch { throw error }
    }
    
    // delete the indicated OrgLang record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public static func orgLangDeleteRec(orgShortName:String, langRegionCode:String) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgLangDeleteRec", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrganizationLangs.TABLE_NAME).select(*).filter(RecOrganizationLangs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == orgShortName && RecOrganizationLangs.COL_EXPRESSION_ORGLANG_LANGREGIONCODE == langRegionCode)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method: "\(self.mCTAG).orgLangDeleteRec", tableQuery: query)
    }
    
    // delete all Language records for an organization; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public static func orgLangDeleteAllRecs(forOrgShortName:String) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgLangDeleteAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrganizationLangs.TABLE_NAME).select(*).filter(RecOrganizationLangs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method: "\(self.mCTAG).orgLangDeleteAllRecs", tableQuery: query)
    }
}

