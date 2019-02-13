//
//  RecOrgFormDefs.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import UIKit
import SQLite

// the various visual characteristics of the main Entry Form with preset defaults
// Storage structure:  option,option,...
// option:  element:setting
// elements:  shown below
// settings:  color-rgba;#;#;#;#, font-fssn;<FontFamily>;<styles>;#;<fontName>
public struct FormVisuals {
    public var headerArea_Background_Color:UIColor = UIColor.white                              // F_HA_B_C
    public var headerArea_Event_Text_Color:UIColor = UIColor.black                              // F_HA_EV_T_C
    public var headerArea_Event_Text_Font:UIFont = UIFont.systemFont(ofSize: 17).bold()         // F_HA_EV_T_F
    public var HeaderArea_SubmitButton_Background_Color:UIColor = UIColor.yellow    // ??       // F_HA_SB_B_C
    public var headerArea_SubmitButton_Text_Color:UIColor = UIColor.black                       // F_HA_SB_T_C
    public var headerArea_SubmitButton_Text_Font:UIFont = UIFont.systemFont(ofSize: 17).bold()  // F_HA_SB_T_F
    public var headerArea_LangButtons_Background_Color:UIColor = UIColor.gray   // ??           // F_HA_LB_B_C
    public var headerArea_LangButtons_Text_Color:UIColor = UIColor.black                        // F_HA_LB_T_C
    public var headerArea_LangButtons_Text_Font:UIFont = UIFont.systemFont(ofSize: 14)          // F_HA_LB_T_F
    public var sectionArea_Background_Color:UIColor = UIColor.gray  // ??                       // F_SA_B_C
    public var sectionArea_Text_Color:UIColor = UIColor.gray    // ??                           // F_SA_T_C
    public var sectionArea_Text_Font:UIFont = UIFont.systemFont(ofSize: 17)                     // F_SA_T_F
    public var fieldArea_Background_Color:UIColor = UIColor.white                               // F_FA_B_C
    public var fieldArea_Title_Text_Color_Normal:UIColor = UIColor.black                        // F_FA_TT_C_N
    public var fieldArea_Title_Text_Color_Selected:UIColor = UIColor.blue                       // F_FA_TT_C_S
    public var fieldArea_Title_Text_Color_Error:UIColor = UIColor.red                           // F_FA_TT_C_E
    public var FieldArea_Title_Text_Font:UIFont = UIFont.systemFont(ofSize: 17)                 // F_FA_TT_F
    
    init(decodeFrom:String) {
        // ??
    }
    
    public func encode() -> String {
        return ""   // ??
    }
}

// special-use version of the record that is all optional; used for importing JSON records and
// specialized database queries if not every field will to be loaded; this record cannot be saved to the database
public class RecOrgFormDefs_Optionals {
    // record members
    public var rOrg_Code_For_SV_File:String?
    public var rForm_Code_For_SV_File:String?
    public var rForm_Lingual_LangRegions:[String]?
    public var rForm_SV_File_Type:RecOrgFormDefs.FORMFIELD_SV_FILE_TYPE? = .TEXT_TAB_DELIMITED_WITH_HEADERS
    public var rForm_XML_Collection_Tag:String? = "contacts"
    public var rForm_XML_Record_Tag:String? = "contact"
    public var rForm_Override_Email_Via:String?
    public var rForm_Override_Email_To:String?
    public var rForm_Override_Email_CC:String?
    public var rForm_Override_Email_Subject:String?
    public var rForm_Visuals:FormVisuals?
    
    // constructor creates the record from the results of a database query; is tolerant of missing columns
    init(row:Row) {
        // note: do NOT use the COL_EXPRESSION_* above since these are all set as optional in case the original query did not select all columns
        self.rOrg_Code_For_SV_File = row[Expression<String?>(RecOrgFormDefs.COLUMN_ORG_CODE_FOR_SV_FILE)]
        self.rForm_Code_For_SV_File = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_CODE_FOR_SV_FILE)]
        self.rForm_XML_Collection_Tag  = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_XML_COLLECTION_TAG)]
        self.rForm_XML_Record_Tag = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_XML_RECORD_TAG)]
        self.rForm_Override_Email_Via = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_VIA)]
        self.rForm_Override_Email_To = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_TO)]
        self.rForm_Override_Email_CC = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_CC)]
        self.rForm_Override_Email_Subject = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_SUBJECT)]
        
        // decode the SV File Type
        let value1:Int? = row[Expression<Int?>(RecOrgFormDefs.COLUMN_FORM_SV_FILE_TYPE)]
        if value1 != nil { self.rForm_SV_File_Type = RecOrgFormDefs.FORMFIELD_SV_FILE_TYPE(rawValue:Int(exactly:value1!)!) }
        else { self.rForm_SV_File_Type = nil }

        // string splitting
        let value2:String? = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_LINGUAL_LANGREGIONS)]
        if value2 != nil { self.rForm_Lingual_LangRegions = value2!.components(separatedBy:",") }
        else { self.rForm_Lingual_LangRegions = nil }
        
        // process stored colors and fonts
        let value3:String? = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_VISUALS)]
        if value3 != nil { self.rForm_Visuals = FormVisuals(decodeFrom: value3!) }
        else { self.rForm_Visuals = nil }
    }
    
    // constructor creates the record from a JSON object; is tolerant of missing columns;
    // must be tolerant that Int64's may be encoded as Strings, especially OIDs;
    // context is provided in case database version or language of the JSON file is important
    init(jsonObj:NSDictionary, context:DatabaseHandler.ValidateJSONdbFile_Result) {
        self.rOrg_Code_For_SV_File = jsonObj[RecOrgFormDefs.COLUMN_ORG_CODE_FOR_SV_FILE] as? String
        self.rForm_Code_For_SV_File = jsonObj[RecOrgFormDefs.COLUMN_FORM_CODE_FOR_SV_FILE] as? String
        self.rForm_Override_Email_Via = jsonObj[RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_VIA] as? String
        self.rForm_Override_Email_To = jsonObj[RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_TO] as? String
        self.rForm_Override_Email_CC = jsonObj[RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_CC] as? String
        self.rForm_Override_Email_Subject = jsonObj[RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_SUBJECT] as? String
        self.rForm_XML_Collection_Tag = jsonObj[RecOrgFormDefs.COLUMN_FORM_XML_COLLECTION_TAG] as? String
        self.rForm_XML_Record_Tag = jsonObj[RecOrgFormDefs.COLUMN_FORM_XML_RECORD_TAG] as? String

        // decode the SV File Type
        let value1obj = jsonObj[RecOrgFormDefs.COLUMN_FORM_SV_FILE_TYPE]
        if value1obj == nil {
            self.rForm_SV_File_Type = RecOrgFormDefs.FORMFIELD_SV_FILE_TYPE.TEXT_TAB_DELIMITED_WITH_HEADERS
        } else {
            if value1obj is String {
                self.rForm_SV_File_Type = RecOrgFormDefs.FORMFIELD_SV_FILE_TYPE(rawValue: Int(jsonObj[RecOrgFormDefs.COLUMN_FORM_SV_FILE_TYPE] as! String)!)
            } else if value1obj is Int {
                self.rForm_SV_File_Type = RecOrgFormDefs.FORMFIELD_SV_FILE_TYPE(rawValue: jsonObj[RecOrgFormDefs.COLUMN_FORM_SV_FILE_TYPE] as! Int)
            } else {
                self.rForm_SV_File_Type = RecOrgFormDefs.FORMFIELD_SV_FILE_TYPE.TEXT_TAB_DELIMITED_WITH_HEADERS
            }
        }

        // string splitting
        let value2 = jsonObj[RecOrgFormDefs.COLUMN_FORM_LINGUAL_LANGREGIONS] as? String
        if (value2 ?? "").isEmpty { self.rForm_Lingual_LangRegions = nil }
        else { self.rForm_Lingual_LangRegions = value2!.components(separatedBy:",") }
        
        // process stored colors and fonts
        let value3 = jsonObj[RecOrgFormDefs.COLUMN_FORM_VISUALS] as? String
        if (value3 ?? "").isEmpty { self.rForm_Visuals = FormVisuals(decodeFrom: "") }
        else { self.rForm_Visuals = FormVisuals(decodeFrom: value3!) }
    }

    // is the optionals record valid in terms of required content?
    public func validate() -> Bool {
        if self.rOrg_Code_For_SV_File == nil || self.rForm_Code_For_SV_File == nil || self.rForm_SV_File_Type == nil { return false }
        if self.rOrg_Code_For_SV_File!.isEmpty || self.rForm_Code_For_SV_File!.isEmpty { return false }
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Main Record
/////////////////////////////////////////////////////////////////////////

// full verson of the record; required fields are enforced; can be saved to the database
public class RecOrgFormDefs {
    // selected internal fields with pre-defined "formfield_order_sv_file" codes
    public enum FORMFIELD_SV_FILE_TYPE:Int {
        case TEXT_TAB_DELIMITED_WITH_HEADERS = 0, TEXT_COMMA_DELIMITED_WITH_HEADERS = 1,
             TEXT_SEMICOLON_DELIMITED_WITH_HEADERS = 2, XML_ATTTRIB_VALUE_PAIRS = 3
    }

    // record members
    public var rOrg_Code_For_SV_File:String                     // org's short code name; shown only to Collector; primary key
    public var rForm_Code_For_SV_File:String                    // form's short code name; shown only to Collector; primary key
    public var rForm_SV_File_Type:FORMFIELD_SV_FILE_TYPE = .TEXT_TAB_DELIMITED_WITH_HEADERS       // SV-File type
    public var rForm_Lingual_LangRegions:[String]?              // show the form as MonoLingual or BiLingual if specified
    public var rForm_XML_Collection_Tag:String = "contacts"     // tag used for the collection of records
    public var rForm_XML_Record_Tag:String = "contact"          // tag used for each record
    public var rForm_Override_Email_Via:String?                 // override email Via; see EmailHandler.swift
    public var rForm_Override_Email_To:String?                  // override email TO
    public var rForm_Override_Email_CC:String?                  // override email CC
    public var rForm_Override_Email_Subject:String?             // override email Subject
    public var rForm_Visuals:FormVisuals                        // form's visual characteristics

    // member constants and other static content
    private static let mCTAG:String = "ROF"
    public static let TABLE_NAME = "OrgFormDefs"
    public static let COLUMN_ORG_CODE_FOR_SV_FILE = "org_code_sv_file"
    public static let COLUMN_FORM_CODE_FOR_SV_FILE = "form_code_sv_file"
    public static let COLUMN_FORM_SV_FILE_TYPE = "form_sv_file_type"
    public static let COLUMN_FORM_LINGUAL_LANGREGIONS = "form_lingual_langregions"
    public static let COLUMN_FORM_OVERRIDE_EMAIL_VIA = "form_override_email_via"
    public static let COLUMN_FORM_OVERRIDE_EMAIL_TO = "form_override_email_to"
    public static let COLUMN_FORM_OVERRIDE_EMAIL_CC = "form_override_email_cc"
    public static let COLUMN_FORM_OVERRIDE_EMAIL_SUBJECT = "form_override_email_subject"
    public static let COLUMN_FORM_XML_COLLECTION_TAG = "form_xml_collection_tag"
    public static let COLUMN_FORM_XML_RECORD_TAG = "form_xml_record_tag"
    public static let COLUMN_FORM_VISUALS = "form_visuals"

    // these are the as-stored in the database expression definitions
    public static let COL_EXPRESSION_ORG_CODE_FOR_SV_FILE = Expression<String>(RecOrgFormDefs.COLUMN_ORG_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FORM_CODE_FOR_SV_FILE = Expression<String>(RecOrgFormDefs.COLUMN_FORM_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FORM_SV_FILE_TYPE = Expression<Int>(RecOrgFormDefs.COLUMN_FORM_SV_FILE_TYPE)
    public static let COL_EXPRESSION_FORM_LINGUAL_LANGREGIONS = Expression<String?>(RecOrgFormDefs.COLUMN_FORM_LINGUAL_LANGREGIONS)
    public static let COL_EXPRESSION_FORM_OVERRIDE_EMAIL_VIA = Expression<String?>(RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_VIA)
    public static let COL_EXPRESSION_FORM_OVERRIDE_EMAIL_TO = Expression<String?>(RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_TO)
    public static let COL_EXPRESSION_FORM_OVERRIDE_EMAIL_CC = Expression<String?>(RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_CC)
    public static let COL_EXPRESSION_FORM_OVERRIDE_EMAIL_SUBJECT = Expression<String?>(RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_SUBJECT)
    public static let COL_EXPRESSION_FORM_XML_COLLECTION_TAG = Expression<String>(RecOrgFormDefs.COLUMN_FORM_XML_COLLECTION_TAG)
    public static let COL_EXPRESSION_FORM_XML_RECORD_TAG = Expression<String>(RecOrgFormDefs.COLUMN_FORM_XML_RECORD_TAG)
    public static let COL_EXPRESSION_FORM_VISUALS = Expression<String>(RecOrgFormDefs.COLUMN_FORM_VISUALS)
    
    // generate the string that will create the table
    public static func generateCreateTableString() -> String {
        return Table(TABLE_NAME).create(ifNotExists: true) { t in
            t.column(COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FORM_SV_FILE_TYPE)
            t.column(COL_EXPRESSION_FORM_LINGUAL_LANGREGIONS)
            t.column(COL_EXPRESSION_FORM_OVERRIDE_EMAIL_VIA)
            t.column(COL_EXPRESSION_FORM_OVERRIDE_EMAIL_TO)
            t.column(COL_EXPRESSION_FORM_OVERRIDE_EMAIL_CC)
            t.column(COL_EXPRESSION_FORM_OVERRIDE_EMAIL_SUBJECT)
            t.column(COL_EXPRESSION_FORM_XML_COLLECTION_TAG)
            t.column(COL_EXPRESSION_FORM_XML_RECORD_TAG)
            t.column(COL_EXPRESSION_FORM_VISUALS)
            t.primaryKey(COL_EXPRESSION_ORG_CODE_FOR_SV_FILE, COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
        }
    }
    
    // upgrade the table going from db version 1 to 2;
    // upgrades:  add column "form_override_email_via"
    public static func upgrade_1_to_2(db:Connection) throws {
        do {
            try db.run(Table(TABLE_NAME).addColumn(COL_EXPRESSION_FORM_OVERRIDE_EMAIL_VIA))
        } catch {
            let appError = APP_ERROR(funcName: "\(self.mCTAG).upgrade_1_to_2", during: "Run(addColumn).form_override_email_via", domain: DatabaseHandler.ThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: "DB table \(TABLE_NAME)", noAlert: false)
            throw appError
        }
    }
    
    // constructor creates a barely initialized record
    init(org_code_sv_file:String, form_code_sv_file:String) {
        self.rOrg_Code_For_SV_File = org_code_sv_file
        self.rForm_Code_For_SV_File = form_code_sv_file
        self.rForm_Visuals = FormVisuals(decodeFrom: "")
    }

    // create a duplicate of an existing record
    init(existingRec:RecOrgFormDefs) {
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File
        self.rForm_Lingual_LangRegions = existingRec.rForm_Lingual_LangRegions
        self.rForm_SV_File_Type = existingRec.rForm_SV_File_Type
        self.rForm_Override_Email_Via = existingRec.rForm_Override_Email_Via
        self.rForm_Override_Email_To = existingRec.rForm_Override_Email_To
        self.rForm_Override_Email_CC = existingRec.rForm_Override_Email_CC
        self.rForm_Override_Email_Subject = existingRec.rForm_Override_Email_Subject
        self.rForm_XML_Collection_Tag = existingRec.rForm_XML_Collection_Tag
        self.rForm_XML_Record_Tag = existingRec.rForm_XML_Record_Tag
        self.rForm_Visuals = existingRec.rForm_Visuals
    }
    
    // import an optionals record into the mainline record
    // throws upon missing required fields; caller is responsible to error.log
    init(existingRec:RecOrgFormDefs_Optionals) throws {
        if existingRec.rOrg_Code_For_SV_File == nil || existingRec.rForm_Code_For_SV_File == nil || existingRec.rForm_SV_File_Type == nil {
            throw APP_ERROR(funcName: "\(RecOrgFormDefs.mCTAG).init(RecOrgFormDefs_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required == nil")
        }
        if existingRec.rOrg_Code_For_SV_File!.isEmpty || existingRec.rForm_Code_For_SV_File!.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrgFormDefs.mCTAG).init(RecOrgFormDefs_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File!
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File!
        self.rForm_SV_File_Type = existingRec.rForm_SV_File_Type!

        if existingRec.rForm_XML_Collection_Tag != nil { self.rForm_XML_Collection_Tag = existingRec.rForm_XML_Collection_Tag! }
        if existingRec.rForm_XML_Record_Tag != nil { self.rForm_XML_Record_Tag = existingRec.rForm_XML_Record_Tag! }

        self.rForm_Lingual_LangRegions = existingRec.rForm_Lingual_LangRegions
        self.rForm_Override_Email_Via = existingRec.rForm_Override_Email_Via
        self.rForm_Override_Email_To = existingRec.rForm_Override_Email_To
        self.rForm_Override_Email_CC = existingRec.rForm_Override_Email_CC
        self.rForm_Override_Email_Subject = existingRec.rForm_Override_Email_Subject
        
        if existingRec.rForm_Visuals != nil { self.rForm_Visuals = existingRec.rForm_Visuals! }
        else { self.rForm_Visuals = FormVisuals(decodeFrom: "") }
    }
    
    // constructor creates the record from the results of a database query
    // throws upon missing required columns from the database (already error.logs them)
    init(row:Row) throws {
        do {
            self.rOrg_Code_For_SV_File = try row.get(RecOrgFormDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            self.rForm_Code_For_SV_File = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
            let value1:Int = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_SV_FILE_TYPE)
            self.rForm_SV_File_Type = FORMFIELD_SV_FILE_TYPE(rawValue:Int(exactly:value1)!)!
            self.rForm_XML_Collection_Tag = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_XML_COLLECTION_TAG)
            self.rForm_XML_Record_Tag = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_XML_RECORD_TAG)
            self.rForm_Override_Email_Via = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_OVERRIDE_EMAIL_VIA)
            self.rForm_Override_Email_To = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_OVERRIDE_EMAIL_TO)
            self.rForm_Override_Email_CC = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_OVERRIDE_EMAIL_CC)
            self.rForm_Override_Email_Subject = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_OVERRIDE_EMAIL_SUBJECT)
            let value2:String = try row.get(RecOrgFormDefs.COL_EXPRESSION_FORM_VISUALS)
            self.rForm_Visuals = FormVisuals(decodeFrom: value2)
        } catch {
            let appError = APP_ERROR(funcName: "\(RecOrgFormDefs.mCTAG).init(Row)", domain: DatabaseHandler.ThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: RecOrgFormDefs.TABLE_NAME)
            throw appError
        }

        // string splitting
        let value6:String? = row[Expression<String?>(RecOrgFormDefs.COLUMN_FORM_LINGUAL_LANGREGIONS)]
        if value6 != nil { self.rForm_Lingual_LangRegions = value6!.components(separatedBy:",") }
        else { self.rForm_Lingual_LangRegions = nil }
    }
    
    // create an array of setters usable for database Insert or Update; will return nil if the record is incomplete and therefore not eligible to be stored
    // use 'exceptKey' for Update operations to ensure the key fields cannot be changed
    public func buildSetters(exceptKey:Bool=false) throws -> [Setter] {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rForm_Code_For_SV_File.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrgFormDefs.mCTAG).buildSetters", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        
        var retArray = [Setter]()
        
        if !exceptKey {
            retArray.append(RecOrgFormDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE <- self.rOrg_Code_For_SV_File)
            retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE <- self.rForm_Code_For_SV_File)
        }
        retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_SV_FILE_TYPE <- self.rForm_SV_File_Type.rawValue)
        retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_OVERRIDE_EMAIL_VIA <- self.rForm_Override_Email_Via)
        retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_OVERRIDE_EMAIL_TO <- self.rForm_Override_Email_To)
        retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_OVERRIDE_EMAIL_CC <- self.rForm_Override_Email_CC)
        retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_OVERRIDE_EMAIL_SUBJECT <- self.rForm_Override_Email_Subject)
        retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_XML_COLLECTION_TAG <- self.rForm_XML_Collection_Tag)
        retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_XML_RECORD_TAG <- self.rForm_XML_Record_Tag)
        retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_VISUALS <- self.rForm_Visuals.encode())

        // string composing
        if rForm_Lingual_LangRegions == nil { retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_LINGUAL_LANGREGIONS <- nil) }
        else { retArray.append(RecOrgFormDefs.COL_EXPRESSION_FORM_LINGUAL_LANGREGIONS <- self.rForm_Lingual_LangRegions!.joined(separator:",")) }

        return retArray
    }
    
    
    // build the JSON values; will return null if the record is incomplete and therefore not eligible to be sent;
    // since the recipient may be 32-bit, send all Int64 as strings
    public func buildJSONObject() -> NSMutableDictionary? {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rForm_Code_For_SV_File.isEmpty { return nil }
        
        let jsonObj:NSMutableDictionary = NSMutableDictionary()
        jsonObj[RecOrgFormDefs.COLUMN_ORG_CODE_FOR_SV_FILE] = self.rOrg_Code_For_SV_File
        jsonObj[RecOrgFormDefs.COLUMN_FORM_CODE_FOR_SV_FILE] = self.rForm_Code_For_SV_File
        jsonObj[RecOrgFormDefs.COLUMN_FORM_SV_FILE_TYPE] = self.rForm_SV_File_Type.rawValue
        jsonObj[RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_VIA] = self.rForm_Override_Email_Via
        jsonObj[RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_TO] = self.rForm_Override_Email_To
        jsonObj[RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_CC] = self.rForm_Override_Email_CC
        jsonObj[RecOrgFormDefs.COLUMN_FORM_OVERRIDE_EMAIL_SUBJECT] = self.rForm_Override_Email_Subject
        jsonObj[RecOrgFormDefs.COLUMN_FORM_XML_COLLECTION_TAG] = self.rForm_XML_Collection_Tag
        jsonObj[RecOrgFormDefs.COLUMN_FORM_XML_RECORD_TAG] = self.rForm_XML_Record_Tag
        jsonObj[RecOrgFormDefs.COLUMN_FORM_VISUALS] = self.rForm_Visuals.encode()
        
        // string composing
        if self.rForm_Lingual_LangRegions == nil { jsonObj[RecOrgFormDefs.COLUMN_FORM_LINGUAL_LANGREGIONS] = nil }
        else { jsonObj[RecOrgFormDefs.COLUMN_FORM_LINGUAL_LANGREGIONS] = self.rForm_Lingual_LangRegions!.joined(separator:",") }
        
        return jsonObj
    }
    
    // does this Form record have the same name as other Form record
    public func isSameNamed(otherRec: RecOrgFormDefs) -> Bool {
        if self.rOrg_Code_For_SV_File == otherRec.rOrg_Code_For_SV_File &&
           self.rForm_Code_For_SV_File == otherRec.rForm_Code_For_SV_File { return true }
        return false
    }
    
    // does this Form record have the same name as other Form record
    public func isPartOfOrg(orgRec: RecOrganizationDefs) -> Bool {
        if self.rOrg_Code_For_SV_File == orgRec.rOrg_Code_For_SV_File { return true }
        return false
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Database interaction methods used throughout the application
    /////////////////////////////////////////////////////////////////////////
    
    // return the quantity of Form records
    // throws exceptions either for local errors or from the database
    public static func orgFormGetQtyRecs(forOrgShortName:String) throws -> Int64 {
        guard DatabaseHandler.shared.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgFormGetQtyRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let whereClause:String = "(\"\(RecOrgFormDefs.COLUMN_ORG_CODE_FOR_SV_FILE)\" = \"\(forOrgShortName)\")"
        return try DatabaseHandler.shared.genericQueryQty(method:"\(self.mCTAG).orgFormGetQtyRecs", table:Table(RecOrgFormDefs.TABLE_NAME), whereStr:whereClause, valuesBindArray:nil)
    }
    
    // get all Form records (which could be none); sorted in alphanumeric order of the short name aka name_for_sv_file
    // throws exceptions either for local errors or from the database
    public static func orgFormGetAllRecs(forOrgShortName:String) throws -> AnySequence<Row> {
        guard DatabaseHandler.shared.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgFormGetAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrgFormDefs.TABLE_NAME).select(*).filter(RecOrgFormDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName).order(RecOrgFormDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE.asc)
        return try DatabaseHandler.shared.genericQuery(method:"\(self.mCTAG).orgFormGetAllRecs", tableQuery:query)
    }
    
    // get one specific Form record by short name
    // throws exceptions either for local errors or from the database
    // null indicates the record was not found
    public static func orgFormGetSpecifiedRecOfShortName(formShortName:String, forOrgShortName:String) throws -> RecOrgFormDefs? {
        guard DatabaseHandler.shared.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgFormGetSpecifiedRecOfShortName", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrgFormDefs.TABLE_NAME).select(*).filter(RecOrgFormDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName && RecOrgFormDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == formShortName)
        let record = try DatabaseHandler.shared.genericQueryOne(method:"\(self.mCTAG).orgFormGetSpecifiedRecOfShortName", tableQuery:query)
        if record == nil { return nil }
        return try RecOrgFormDefs(row:record!)
    }
    
    // add a Form entry; return is the RowID of the new record (negative will not be returned);
    // NOTE: all the Forms default not-shown FormFields will also be auto-loaded unless explicitly told not to;
    // WARNING: if the key fields have been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveNewToDB(withOrgRec:RecOrganizationDefs?) throws -> Int64 {
        guard DatabaseHandler.shared.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormDefs.mCTAG).saveNewToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        
        if withOrgRec != nil { self.rOrg_Code_For_SV_File = withOrgRec!.rOrg_Code_For_SV_File }
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).saveNewToDB")
            throw appError
        } catch { throw error}
        
        let rowID = try DatabaseHandler.shared.insertRec(method:"\(RecOrgFormDefs.mCTAG).saveNewToDB", table:Table(RecOrgFormDefs.TABLE_NAME), cv:setters, orReplace:false, noAlert:false)
        if withOrgRec != nil {
            do {
                try FieldHandler.shared.addMetadataFormFieldsToNewForm(forFormRec: self, withOrgRec: withOrgRec!)
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).saveNewToDB")
                throw appError
            } catch { throw error }
        }
        return rowID
    }
    
    // replace a Form entry; return is the quantity of replaced records (negative will not be returned);
    // WARNING: if the key fields have been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveChangesToDB(originalFormRec:RecOrgFormDefs) throws -> Int {
        guard DatabaseHandler.shared.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormDefs.mCTAG).saveChangesToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).saveChangesToDB")
            throw appError
        } catch { throw error}
        
        let query = Table(RecOrgFormDefs.TABLE_NAME).select(*).filter(RecOrgFormDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == originalFormRec.rOrg_Code_For_SV_File && RecOrgFormDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == originalFormRec.rForm_Code_For_SV_File)
        return try DatabaseHandler.shared.updateRec(method:"\(RecOrgFormDefs.mCTAG).saveChangesToDB", tableQuery:query, cv:setters)
    }
    
    // delete the Form record; return is the count of records deleted (negative will not be returned;
    // note: this will also delete all the Form's formfields
    // throws exceptions either for local errors or from the database
    public func deleteFromDB(forOrgShortName:String) throws -> Int {
        var result:Int
        do {
            result = try RecOrgFormDefs.orgFormDeleteRec(formShortName:self.rForm_Code_For_SV_File, forOrgShortName:forOrgShortName)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).deleteFromDB")
            throw appError
        } catch { throw error }
        return result
    }
    
    // delete the indicated Form record; return is the count of records deleted (negative will not be returned;
    // note: this will also delete all the Form's formFields and formFieldLocales
    // throws exceptions either for local errors or from the database
    public static func orgFormDeleteRec(formShortName:String, forOrgShortName:String) throws -> Int {
        guard DatabaseHandler.shared.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgFormDeleteRec", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrgFormDefs.TABLE_NAME).select(*).filter(RecOrgFormDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName && RecOrgFormDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == formShortName)
        let qty = try DatabaseHandler.shared.genericDeleteRecs(method:"\(self.mCTAG).orgFormDeleteRec", tableQuery:query)
        
        // maintain referential integrity
        do {
            _ = try RecOrgFormFieldLocales.formFieldLocalesDeleteAllRecs(forOrgShortName:forOrgShortName, forFormShortName:formShortName)
            _ = try RecOrgFormFieldDefs.orgFormFieldDeleteAllRecs(forOrgShortName:forOrgShortName, forFormShortName:formShortName)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).orgFormDeleteRec")
            throw appError
        } catch { throw error }
        return qty
    }
    
    // delete all Form records for an organization; return is the count of records deleted (negative will not be returned;
    // note: this is only called when an Org record is being deleted, and that Record's delete function also deletes all FormField and FormFieldLocales;
    // throws exceptions either for local errors or from the database
    public static func orgFormDeleteAllRecs(forOrgShortName:String) throws -> Int {
        guard DatabaseHandler.shared.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgFormDeleteAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrgFormDefs.TABLE_NAME).select(*).filter(RecOrgFormDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName)
        return try DatabaseHandler.shared.genericDeleteRecs(method:"\(self.mCTAG).orgFormDeleteAllRecs", tableQuery:query)
    }
    
    // clone this Form and all its associated records to a new Form as named;
    // throws exceptions either for local errors or from the database
    public func clone(newFormName:String, withOrgRec:RecOrganizationDefs) throws {
        let newFormRec:RecOrgFormDefs = RecOrgFormDefs(existingRec: self)
        newFormRec.rForm_Code_For_SV_File = newFormName
        do {
            let _ = try newFormRec.saveNewToDB(withOrgRec: nil) // do not want to auto-load meta-data fields
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).clone")
            throw appError
        } catch { throw error }
        
        // get and copy all primary RecOrgFormFieldDefs, building a mapping index
        var remappingFFI:[Int64:Int64] = [:]
        do {
            let records1:AnySequence<Row> = try RecOrgFormFieldDefs.orgFormFieldGetAllRecs(forOrgShortName: withOrgRec.rOrg_Code_For_SV_File, forFormShortName: self.rForm_Code_For_SV_File, sortedBySVFileOrder: false)
            for rowRec in records1 {
                let formFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(row:rowRec)
                if formFieldRec.rFormField_SubField_Within_FormField_Index == nil {
                    let originalIndex = formFieldRec.rFormField_Index
                    formFieldRec.rForm_Code_For_SV_File = newFormName
                    formFieldRec.rFormField_Index = -1
                    formFieldRec.rFormField_Index = try formFieldRec.saveNewToDB()
                    remappingFFI[originalIndex] = formFieldRec.rFormField_Index
                }
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).clone")
            throw appError
        } catch { throw error }
        
        // get and copy all subfield RecOrgFormFieldDefs, remapping their linkages
        do {
            let records2:AnySequence<Row> = try RecOrgFormFieldDefs.orgFormFieldGetAllRecs(forOrgShortName: withOrgRec.rOrg_Code_For_SV_File, forFormShortName: self.rForm_Code_For_SV_File, sortedBySVFileOrder: false)
            for rowRec in records2 {
                let formFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(row:rowRec)
                if formFieldRec.rFormField_SubField_Within_FormField_Index != nil {
                    let originalIndex = formFieldRec.rFormField_Index
                    formFieldRec.rFormField_SubField_Within_FormField_Index = remappingFFI[formFieldRec.rFormField_SubField_Within_FormField_Index!]
                    formFieldRec.rForm_Code_For_SV_File = newFormName
                    formFieldRec.rFormField_Index = -1
                    formFieldRec.rFormField_Index = try formFieldRec.saveNewToDB()
                    remappingFFI[originalIndex] = formFieldRec.rFormField_Index
                }
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).clone")
            throw appError
        } catch { throw error }

        // get and copy all RecOrgFormFieldLocales, remapping their linkages
        do {
            let records3:AnySequence<Row> = try RecOrgFormFieldLocales.formFieldLocalesGetAllRecs(forOrgShortName: withOrgRec.rOrg_Code_For_SV_File, forFormShortName: self.rForm_Code_For_SV_File)
            for rowRec in records3 {
                let formFieldLocaleRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(row:rowRec)
                formFieldLocaleRec.rFormFieldLoc_Index = -1
                formFieldLocaleRec.rForm_Code_For_SV_File = newFormName
                formFieldLocaleRec.rFormField_Index = remappingFFI[formFieldLocaleRec.rFormField_Index] ?? -1
                formFieldLocaleRec.rFormFieldLoc_Index = try formFieldLocaleRec.saveNewToDB()
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormDefs.mCTAG).clone")
            throw appError
        } catch { throw error }
    }
}
