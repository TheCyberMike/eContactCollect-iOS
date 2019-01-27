//
//  RecLanguageDefs.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import UIKit
import SQLite

// the various visual characteristics for the Organization
// Storage structure:  option,option,...
// option:  element:setting
// elements:  shown below
// settings:  color-rgba;#;#;#;#, font-fssn;<FontFamily>;<styles>;#;<fontName>
public struct OrgVisuals {
    public var rOrgTitle_Background_Color:UIColor = UIColor.white                       // O_OT_B_C
    public var rOrgTitle_TitleText_Font:UIFont = UIFont.systemFont(ofSize: 17).bold()   // O_OT_TT_F
    public var rOrgTitle_TitleText_Color:UIColor = UIColor.black                        // O_OT_TT_C
    
    init(decodeFrom:String) {
        let comps1:[String] = decodeFrom.components(separatedBy: ",")
        for aComp in comps1 {
            let comps2:[String] = aComp.components(separatedBy: ":")
            if comps2.count >= 2 {
                switch comps2[0] {
                case "O_OT_B_C":
                    self.rOrgTitle_Background_Color = AppDelegate.decodeColor(fromString: comps2[1]) ?? UIColor.white
                    break
                case "O_OT_TT_F":
                    self.rOrgTitle_TitleText_Font = AppDelegate.decodeFont(fromString: comps2[1]) ?? UIFont.systemFont(ofSize: 17).bold()
                    break
                case "O_OT_TT_C":
                    self.rOrgTitle_TitleText_Color = AppDelegate.decodeColor(fromString: comps2[1]) ?? UIColor.black
                    break
                default:
                    break
                }
            }
        }
    }
    
    public func encode() -> String {
        var retStr:String = "O_OT_B_C:" + AppDelegate.encodeColor(fromColor: self.rOrgTitle_Background_Color)
        retStr = retStr + ",O_OT_TT_F:" + AppDelegate.encodeFont(fromFont: self.rOrgTitle_TitleText_Font)
        retStr = retStr + ",O_OT_TT_C:" + AppDelegate.encodeColor(fromColor: self.rOrgTitle_TitleText_Color)
        return retStr
    }
}


// special-use version of the record that is all optional; used for importing JSON records and
// specialized database queries if not every field will to be loaded; this record cannot be saved to the database
public class RecOrganizationDefs_Optionals {
    // record members
    public var rOrg_Code_For_SV_File:String?
    public var rOrg_LangRegionCodes_Supported:[String]?
    public var rOrg_LangRegionCode_SV_File:String?
    public var rOrg_Title_Mode:RecOrganizationDefs.ORG_TITLE_MODE? = .ONLY_TITLE
    public var rOrg_Logo_Image_PNG_Blob:Data?
    public var rOrg_Event_Code_For_SV_File:String?
    public var rOrg_Visuals:OrgVisuals?
    public var rOrg_Email_To:String?
    public var rOrg_Email_CC:String?
    public var rOrg_Email_Subject:String? = NSLocalizedString("Contacts collected from eContact Collect", comment:"do not translate the portion: eContact Collect")
    
    // constructor creates the record from the results of a database query; is tolerant of missing columns
    init(row:Row) {
        // note: do NOT use the COL_EXPRESSION_* above since these are all set as optional in case the original query did not select all columns
        self.rOrg_Code_For_SV_File = row[Expression<String?>(RecOrganizationDefs.COLUMN_ORG_CODE_FOR_SV_FILE)]
        self.rOrg_LangRegionCode_SV_File = row[Expression<String?>(RecOrganizationDefs.COLUMN_ORG_LANGREGIONCODE_SV_FILE)]
        self.rOrg_Logo_Image_PNG_Blob = row[Expression<Data?>(RecOrganizationDefs.COL_EXPRESSION_ORG_LOGO_IMAGE_PNG_BLOB)]
        self.rOrg_Event_Code_For_SV_File = row[Expression<String?>(RecOrganizationDefs.COLUMN_ORG_EVENT_CODE_FOR_SV_FILE)]
        self.rOrg_Email_To = row[Expression<String?>(RecOrganizationDefs.COLUMN_ORG_EMAIL_TO)]
        self.rOrg_Email_CC = row[Expression<String?>(RecOrganizationDefs.COLUMN_ORG_EMAIL_CC)]
        self.rOrg_Email_Subject = row[Expression<String?>(RecOrganizationDefs.COLUMN_ORG_EMAIL_SUBJECT)]

        // extract Org Title Mode
        let value1:Int? = row[Expression<Int?>(RecOrganizationDefs.COLUMN_ORG_TITLE_MODE)]
        if value1 != nil { self.rOrg_Title_Mode = RecOrganizationDefs.ORG_TITLE_MODE(rawValue:Int(exactly:value1!)!) }
        else { self.rOrg_Title_Mode = nil }
        
        // break comma-delimited String into an Array
        let value2:String? = row[Expression<String?>(RecOrganizationDefs.COLUMN_ORG_LANGREGIONCODES_SUPPORTED)]
        if value2 != nil { self.rOrg_LangRegionCodes_Supported = value2!.components(separatedBy:",") }
        else { self.rOrg_LangRegionCodes_Supported = nil }
        
        // process stored colors and fonts
        let value3:String? = row[Expression<String?>(RecOrganizationDefs.COLUMN_ORG_VISUALS)]
        if value3 != nil { self.rOrg_Visuals = OrgVisuals(decodeFrom: value3!) }
        else { self.rOrg_Visuals = nil }
    }
    
    // constructor creates the record from a JSON object; is tolerant of missing columns;
    // must be tolerant that Int64's may be encoded as Strings, especially OIDs
    init(jsonObj:NSDictionary) {
        self.rOrg_Code_For_SV_File = jsonObj[RecOrganizationDefs.COLUMN_ORG_CODE_FOR_SV_FILE] as? String
        self.rOrg_LangRegionCode_SV_File = jsonObj[RecOrganizationDefs.COLUMN_ORG_LANGREGIONCODE_SV_FILE] as? String
        self.rOrg_Email_To = jsonObj[RecOrganizationDefs.COLUMN_ORG_EMAIL_TO] as? String
        self.rOrg_Email_CC = jsonObj[RecOrganizationDefs.COLUMN_ORG_EMAIL_CC] as? String
        self.rOrg_Email_Subject = jsonObj[RecOrganizationDefs.COLUMN_ORG_EMAIL_SUBJECT] as? String
        self.rOrg_Event_Code_For_SV_File = jsonObj[RecOrganizationDefs.COLUMN_ORG_EVENT_CODE_FOR_SV_FILE] as? String
        
        // extract Org Title Mode
        let value1obj = jsonObj[RecOrganizationDefs.COLUMN_ORG_TITLE_MODE]
        if value1obj == nil {
            self.rOrg_Title_Mode = RecOrganizationDefs.ORG_TITLE_MODE.BOTH_50_50
        } else {
            if value1obj is String {
                self.rOrg_Title_Mode = RecOrganizationDefs.ORG_TITLE_MODE(rawValue: Int(jsonObj[RecOrganizationDefs.COLUMN_ORG_TITLE_MODE] as! String)!)
            } else if value1obj is Int {
                self.rOrg_Title_Mode = RecOrganizationDefs.ORG_TITLE_MODE(rawValue: jsonObj[RecOrganizationDefs.COLUMN_ORG_TITLE_MODE] as! Int)
            } else {
                self.rOrg_Title_Mode = RecOrganizationDefs.ORG_TITLE_MODE.BOTH_50_50
            }
        }
        
        // break comma-delimited String into an Array
        let value2:String? = jsonObj[RecOrganizationDefs.COLUMN_ORG_LANGREGIONCODES_SUPPORTED] as? String
        if value2 != nil { self.rOrg_LangRegionCodes_Supported = value2!.components(separatedBy:",") } // break comma-delimited String into an Array
        else { self.rOrg_LangRegionCodes_Supported = nil }
        
        // encode the Logo PNG
        let value3:String? = jsonObj[RecOrganizationDefs.COLUMN_ORG_LOGO_IMAGE_PNG_BLOB] as? String
        if value3 != nil { self.rOrg_Logo_Image_PNG_Blob = Data(base64Encoded: value3!) }
        else { self.rOrg_Logo_Image_PNG_Blob = nil }
        
        // process stored colors and fonts
        let value4:String? = jsonObj[RecOrganizationDefs.COLUMN_ORG_VISUALS] as? String
        if value4 != nil { self.rOrg_Visuals = OrgVisuals(decodeFrom: value4!) }
        else { self.rOrg_Visuals = nil }
    }
    
    // is the optionals record valid in terms of required content?
    public func validate() -> Bool {
        if self.rOrg_Code_For_SV_File == nil || self.rOrg_LangRegionCode_SV_File == nil || self.rOrg_LangRegionCodes_Supported == nil {
            return false
        }
        if self.rOrg_Code_For_SV_File!.isEmpty || self.rOrg_LangRegionCode_SV_File!.isEmpty || self.rOrg_LangRegionCodes_Supported!.count == 0 {
            return false
        }
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Main Record
/////////////////////////////////////////////////////////////////////////

// full verson of the record; required fields are enforced; can be saved to the database
public class RecOrganizationDefs {
    public enum ORG_TITLE_MODE:Int {
        case ONLY_TITLE = 0, ONLY_LOGO = 1, BOTH_50_50 = 2, BOTH_LOGO_DOMINATES = 3, BOTH_TITLE_DOMINATES = 4
    }

    // record members
    public var rOrg_Code_For_SV_File:String                         // short code name for the organization; shown only to Collector; primary key
    public var rOrg_LangRegionCodes_Supported:[String] = ["en"]     // ISO language code-region entries that the Organization supports
    public var rOrg_LangRegionCode_SV_File:String = "en"            // ISO language code-region used for SV-File columns and meta-data
    public var rOrg_Title_Mode:ORG_TITLE_MODE = .ONLY_TITLE         // text title vs logo mode
    public var rOrg_Logo_Image_PNG_Blob:Data?                       // organization's logo (stored in 3x size as PNG)
    public var rOrg_Event_Code_For_SV_File:String?                  // optional-event: code for the SV-File
    public var rOrg_Visuals:OrgVisuals                              // visual settings
    public var rOrg_Email_To:String?                                // email TO
    public var rOrg_Email_CC:String?                                // email CC
                                                                    // email Subject
    public var rOrg_Email_Subject:String? = NSLocalizedString("Contacts collected from eContact Collect", comment:"do not translate the portion: eContact Collect")

    // member variables
    public var mOrg_Lang_Recs_are_changed:Bool = false
    public var mOrg_Lang_Recs:[RecOrganizationLangs]? = nil         // automatically loaded RecOrganizationLangs

    // member constants and other static content
    private static let mCTAG:String = "RO"
    public static let TABLE_NAME = "OrganizationDefs"
    public static let COLUMN_ORG_CODE_FOR_SV_FILE = "org_code_sv_file"
    public static let COLUMN_ORG_LANGREGIONCODES_SUPPORTED = "org_langs_supported"
    public static let COLUMN_ORG_LANGREGIONCODE_SV_FILE = "org_lang_sv_file"
    public static let COLUMN_ORG_TITLE_MODE = "org_title_mode"
    public static let COLUMN_ORG_LOGO_IMAGE_PNG_BLOB = "org_logo_image_png_blob"
    public static let COLUMN_ORG_EVENT_CODE_FOR_SV_FILE = "org_event_code_sv_file"
    public static let COLUMN_ORG_EMAIL_TO = "org_email_to"
    public static let COLUMN_ORG_EMAIL_CC = "org_email_cc"
    public static let COLUMN_ORG_EMAIL_SUBJECT = "org_email_subject"
    public static let COLUMN_ORG_VISUALS = "org_visuals"

    // these are the as-stored in the database expression definitions
    public static let COL_EXPRESSION_ORG_CODE_FOR_SV_FILE = Expression<String>(RecOrganizationDefs.COLUMN_ORG_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_ORG_LANGREGIONCODES_SUPPORTED = Expression<String>(RecOrganizationDefs.COLUMN_ORG_LANGREGIONCODES_SUPPORTED)
    public static let COL_EXPRESSION_ORG_LANGREGIONCODE_SV_FILE = Expression<String>(RecOrganizationDefs.COLUMN_ORG_LANGREGIONCODE_SV_FILE)
    public static let COL_EXPRESSION_ORG_TITLE_MODE = Expression<Int>(RecOrganizationDefs.COLUMN_ORG_TITLE_MODE)
    public static let COL_EXPRESSION_ORG_LOGO_IMAGE_PNG_BLOB = Expression<Data?>(RecOrganizationDefs.COLUMN_ORG_LOGO_IMAGE_PNG_BLOB)
    public static let COL_EXPRESSION_ORG_EVENT_CODE_FOR_SV_FILE = Expression<String?>(RecOrganizationDefs.COLUMN_ORG_EVENT_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_ORG_EMAIL_TO = Expression<String?>(RecOrganizationDefs.COLUMN_ORG_EMAIL_TO)
    public static let COL_EXPRESSION_ORG_EMAIL_CC = Expression<String?>(RecOrganizationDefs.COLUMN_ORG_EMAIL_CC)
    public static let COL_EXPRESSION_ORG_EMAIL_SUBJECT = Expression<String?>(RecOrganizationDefs.COLUMN_ORG_EMAIL_SUBJECT)
    public static let COL_EXPRESSION_ORG_VISUALS = Expression<String>(RecOrganizationDefs.COLUMN_ORG_VISUALS)

    // generate the string that will create the table
    public static func generateCreateTableString() -> String {
        return Table(TABLE_NAME).create(ifNotExists: true) { t in
            t.column(COL_EXPRESSION_ORG_CODE_FOR_SV_FILE, primaryKey: true)
            t.column(COL_EXPRESSION_ORG_LANGREGIONCODES_SUPPORTED)
            t.column(COL_EXPRESSION_ORG_LANGREGIONCODE_SV_FILE)
            t.column(COL_EXPRESSION_ORG_TITLE_MODE)
            t.column(COL_EXPRESSION_ORG_LOGO_IMAGE_PNG_BLOB)
            t.column(COL_EXPRESSION_ORG_EVENT_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_ORG_EMAIL_TO)
            t.column(COL_EXPRESSION_ORG_EMAIL_CC)
            t.column(COL_EXPRESSION_ORG_EMAIL_SUBJECT)
            t.column(COL_EXPRESSION_ORG_VISUALS)
        }
    }
    
    // constructor creates a barely initialized record
    init(org_code_sv_file:String) {
        self.rOrg_Code_For_SV_File = org_code_sv_file
        self.rOrg_LangRegionCodes_Supported = [AppDelegate.mDeviceLangRegion]
        self.rOrg_LangRegionCode_SV_File = AppDelegate.mDeviceLangRegion
        self.rOrg_Visuals = OrgVisuals(decodeFrom: "")
    }
    
    // destructor
    deinit {
        if self.mOrg_Lang_Recs != nil { self.mOrg_Lang_Recs = nil } // likely not needed for heap management but cannot hurt
    }
    
    // create a duplicate of an existing record
    init(existingRec:RecOrganizationDefs) {
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File
        self.rOrg_LangRegionCodes_Supported = existingRec.rOrg_LangRegionCodes_Supported
        self.rOrg_LangRegionCode_SV_File = existingRec.rOrg_LangRegionCode_SV_File
        self.rOrg_Title_Mode = existingRec.rOrg_Title_Mode
        self.rOrg_Logo_Image_PNG_Blob = existingRec.rOrg_Logo_Image_PNG_Blob
        self.rOrg_Event_Code_For_SV_File = existingRec.rOrg_Event_Code_For_SV_File
        self.rOrg_Email_To = existingRec.rOrg_Email_To
        self.rOrg_Email_CC = existingRec.rOrg_Email_CC
        self.rOrg_Email_Subject = existingRec.rOrg_Email_Subject
        self.rOrg_Visuals = existingRec.rOrg_Visuals
        
        self.mOrg_Lang_Recs_are_changed = false
        self.mOrg_Lang_Recs = existingRec.mOrg_Lang_Recs
    }
    
    // import an optionals record into the mainline record
    // throws upon missing required fields; caller is responsible to error.log
    init(existingRec:RecOrganizationDefs_Optionals) throws {
        if existingRec.rOrg_Code_For_SV_File == nil || existingRec.rOrg_Title_Mode == nil || existingRec.rOrg_LangRegionCode_SV_File == nil ||
           existingRec.rOrg_LangRegionCodes_Supported == nil {
            throw APP_ERROR(funcName: "\(RecOrganizationDefs.mCTAG).init(RecOrganizationDefs_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required == nil")
        }
        if existingRec.rOrg_Code_For_SV_File!.isEmpty || existingRec.rOrg_LangRegionCode_SV_File!.isEmpty || existingRec.rOrg_LangRegionCodes_Supported!.count == 0 {
            throw APP_ERROR(funcName: "\(RecOrganizationDefs.mCTAG).init(RecOrganizationDefs_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File!
        self.rOrg_LangRegionCodes_Supported = existingRec.rOrg_LangRegionCodes_Supported!
        self.rOrg_LangRegionCode_SV_File = existingRec.rOrg_LangRegionCode_SV_File!
        self.rOrg_Title_Mode = existingRec.rOrg_Title_Mode!
        self.rOrg_Logo_Image_PNG_Blob = existingRec.rOrg_Logo_Image_PNG_Blob
        self.rOrg_Event_Code_For_SV_File = existingRec.rOrg_Event_Code_For_SV_File
        self.rOrg_Email_To = existingRec.rOrg_Email_To
        self.rOrg_Email_CC = existingRec.rOrg_Email_CC
        self.rOrg_Email_Subject = existingRec.rOrg_Email_Subject
        if existingRec.rOrg_Visuals != nil { self.rOrg_Visuals = existingRec.rOrg_Visuals! }
        else { self.rOrg_Visuals = OrgVisuals(decodeFrom: "") }
        
        self.mOrg_Lang_Recs_are_changed = false
        self.mOrg_Lang_Recs = nil
    }
    
    // constructor creates the record from entered values
    init(org_code_sv_file:String, org_title_mode:ORG_TITLE_MODE, org_logo_image_png_blob:Data?, org_email_to:String?, org_email_cc:String?, org_email_subject:String?) {

        self.rOrg_Code_For_SV_File = org_code_sv_file
        self.rOrg_LangRegionCodes_Supported = [AppDelegate.mDeviceLangRegion]
        self.rOrg_LangRegionCode_SV_File = AppDelegate.mDeviceLangRegion
        self.rOrg_Title_Mode = org_title_mode
        self.rOrg_Logo_Image_PNG_Blob = org_logo_image_png_blob
        self.rOrg_Event_Code_For_SV_File = nil
        self.rOrg_Email_To = org_email_to
        self.rOrg_Email_CC = org_email_cc
        self.rOrg_Email_Subject = org_email_subject
        self.rOrg_Visuals = OrgVisuals(decodeFrom: "")
        
        self.mOrg_Lang_Recs_are_changed = false
        self.mOrg_Lang_Recs = nil
    }
    
    // constructor creates the record from the results of a database query
    // throws upon missing required columns from the database (already error.logs them)
    init(row:Row) throws {
        do {
            self.rOrg_Code_For_SV_File = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            self.rOrg_LangRegionCode_SV_File = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_LANGREGIONCODE_SV_FILE)
            let value1:String = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_LANGREGIONCODES_SUPPORTED)
            self.rOrg_LangRegionCodes_Supported = value1.components(separatedBy:",")
            let value2:Int = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_TITLE_MODE)
            self.rOrg_Title_Mode = ORG_TITLE_MODE(rawValue:Int(exactly:value2)!)!
            self.rOrg_Logo_Image_PNG_Blob = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_LOGO_IMAGE_PNG_BLOB)
            self.rOrg_Event_Code_For_SV_File = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_EVENT_CODE_FOR_SV_FILE)
            self.rOrg_Email_To = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_EMAIL_TO)
            self.rOrg_Email_CC = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_EMAIL_CC)
            self.rOrg_Email_Subject = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_EMAIL_SUBJECT)
            let value3:String = try row.get(RecOrganizationDefs.COL_EXPRESSION_ORG_VISUALS)
            self.rOrg_Visuals = OrgVisuals(decodeFrom: value3)
        } catch {
            let appError = APP_ERROR(funcName: "\(RecOrganizationDefs.mCTAG).init(Row)", domain: DatabaseHandler.ThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: RecContactsCollected.TABLE_NAME)
            throw appError
        }
        
        self.mOrg_Lang_Recs_are_changed = false
        self.mOrg_Lang_Recs = nil
    }
    
    // create an array of setters usable for database Insert or Update; will return nil if the record is incomplete and therefore not eligible to be stored
    // use 'exceptKey' for Update operations to ensure the key fields cannot be changed
    // throws errors if record cannot be saved to the database; caller is responsible to error.log them
    private func buildSetters(exceptKey:Bool=false) throws -> [Setter] {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rOrg_LangRegionCode_SV_File.isEmpty || self.rOrg_LangRegionCodes_Supported.count == 0 {
            throw APP_ERROR(funcName: "\(RecOrganizationDefs.mCTAG).buildSetters", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        var retArray:[Setter] = []
        
        if !exceptKey { retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE <- self.rOrg_Code_For_SV_File) }
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_TITLE_MODE <- self.rOrg_Title_Mode.rawValue)
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_LANGREGIONCODE_SV_FILE <- self.rOrg_LangRegionCode_SV_File)
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_LANGREGIONCODES_SUPPORTED <- self.rOrg_LangRegionCodes_Supported.joined(separator:","))
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_LOGO_IMAGE_PNG_BLOB <- self.rOrg_Logo_Image_PNG_Blob)
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_EVENT_CODE_FOR_SV_FILE <- self.rOrg_Event_Code_For_SV_File)
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_EMAIL_TO <- self.rOrg_Email_To)
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_EMAIL_CC <- self.rOrg_Email_CC)
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_EMAIL_SUBJECT <- self.rOrg_Email_Subject)
        retArray.append(RecOrganizationDefs.COL_EXPRESSION_ORG_VISUALS <- self.rOrg_Visuals.encode())

        return retArray
    }
    
    // build the JSON values; will return null if the record is incomplete and therefore not eligible to be sent;
    // since the recipient may be 32-bit, send all Int64 as strings
    // throws errors if record cannot be exported; caller is responsible to error.log them
    public func buildJSONObject() throws -> NSMutableDictionary {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rOrg_LangRegionCode_SV_File.isEmpty || self.rOrg_LangRegionCodes_Supported.count == 0 {
            throw APP_ERROR(funcName: "\(RecOrganizationDefs.mCTAG).buildJSONObject", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        
        let jsonObj:NSMutableDictionary = NSMutableDictionary()
        jsonObj[RecOrganizationDefs.COLUMN_ORG_CODE_FOR_SV_FILE] = self.rOrg_Code_For_SV_File
        jsonObj[RecOrganizationDefs.COLUMN_ORG_TITLE_MODE] = self.rOrg_Title_Mode.rawValue
        jsonObj[RecOrganizationDefs.COLUMN_ORG_LANGREGIONCODES_SUPPORTED] = self.rOrg_LangRegionCodes_Supported.joined(separator:",")
        jsonObj[RecOrganizationDefs.COLUMN_ORG_LANGREGIONCODE_SV_FILE] = self.rOrg_LangRegionCode_SV_File
        jsonObj[RecOrganizationDefs.COLUMN_ORG_EVENT_CODE_FOR_SV_FILE] = self.rOrg_Event_Code_For_SV_File
        jsonObj[RecOrganizationDefs.COLUMN_ORG_EMAIL_TO] = self.rOrg_Email_To
        jsonObj[RecOrganizationDefs.COLUMN_ORG_EMAIL_CC] = self.rOrg_Email_CC
        jsonObj[RecOrganizationDefs.COLUMN_ORG_EMAIL_SUBJECT] = self.rOrg_Email_Subject
        jsonObj[RecOrganizationDefs.COLUMN_ORG_VISUALS] = self.rOrg_Visuals.encode()
        
        // encode the Logo PNG
        if rOrg_Logo_Image_PNG_Blob == nil { jsonObj[RecOrganizationDefs.COLUMN_ORG_LOGO_IMAGE_PNG_BLOB] = nil }
        else { jsonObj[RecOrganizationDefs.COLUMN_ORG_LOGO_IMAGE_PNG_BLOB] = rOrg_Logo_Image_PNG_Blob!.base64EncodedString() }
        
        return jsonObj
    }
    
    // does this Org record have the same name as other Org record
    public func isSameNamed(otherRec: RecOrganizationDefs) -> Bool {
        if self.rOrg_Code_For_SV_File == otherRec.rOrg_Code_For_SV_File { return true }
        return false
    }
    
#if TESTING
    // compare two RecOrganizationDefs records; only needed during testing
    public func sameAs(baseRec:RecOrganizationDefs) -> Bool {
        if self.rOrg_Code_For_SV_File != baseRec.rOrg_Code_For_SV_File { return false }
        if self.rOrg_LangRegionCode_SV_File != baseRec.rOrg_LangRegionCode_SV_File { return false }
        if self.rOrg_Event_Code_For_SV_File != baseRec.rOrg_Event_Code_For_SV_File { return false }
        if self.rOrg_Email_To != baseRec.rOrg_Email_To { return false }
        if self.rOrg_Email_CC != baseRec.rOrg_Email_CC { return false }
        if self.rOrg_Email_Subject != baseRec.rOrg_Email_Subject { return false }
        if self.rOrg_Title_Mode != baseRec.rOrg_Title_Mode { return false }
        
        if (self.rOrg_Logo_Image_PNG_Blob == nil) != (baseRec.rOrg_Logo_Image_PNG_Blob == nil) { return false }
        if self.rOrg_Logo_Image_PNG_Blob != nil {
            if self.rOrg_Logo_Image_PNG_Blob! != baseRec.rOrg_Logo_Image_PNG_Blob! { return false }
        }
        
        if self.rOrg_LangRegionCodes_Supported.count != baseRec.rOrg_LangRegionCodes_Supported.count { return false }
        if self.rOrg_LangRegionCodes_Supported.count > 0 {
            for i in 0...self.rOrg_LangRegionCodes_Supported.count - 1 {
                if self.rOrg_LangRegionCodes_Supported[i] != baseRec.rOrg_LangRegionCodes_Supported[i] { return false }
            }
        }

        let by:CGFloat = 1000000.0
        var srgba = self.rOrg_Visuals.rOrgTitle_Background_Color.rgba()
        var brgba = baseRec.rOrg_Visuals.rOrgTitle_Background_Color.rgba()
        srgba.r = round(srgba.r * by)
        brgba.r = round(brgba.r * by)
        srgba.g = round(srgba.g * by)
        brgba.g = round(brgba.g * by)
        srgba.b = round(srgba.b * by)
        brgba.b = round(brgba.b * by)
        srgba.a = round(srgba.a * by)
        brgba.a = round(brgba.a * by)
        if srgba.r != brgba.r || srgba.g != brgba.g || srgba.b != brgba.b || srgba.a != brgba.a { return false }

        srgba = self.rOrg_Visuals.rOrgTitle_TitleText_Color.rgba()
        brgba = baseRec.rOrg_Visuals.rOrgTitle_TitleText_Color.rgba()
        srgba.r = round(srgba.r * by)
        brgba.r = round(brgba.r * by)
        srgba.g = round(srgba.g * by)
        brgba.g = round(brgba.g * by)
        srgba.b = round(srgba.b * by)
        brgba.b = round(brgba.b * by)
        srgba.a = round(srgba.a * by)
        brgba.a = round(brgba.a * by)
        if srgba.r != brgba.r || srgba.g != brgba.g || srgba.b != brgba.b || srgba.a != brgba.a { return false }

        if self.rOrg_Visuals.rOrgTitle_TitleText_Font.familyName != baseRec.rOrg_Visuals.rOrgTitle_TitleText_Font.familyName { return false }
        if self.rOrg_Visuals.rOrgTitle_TitleText_Font.pointSize != baseRec.rOrg_Visuals.rOrgTitle_TitleText_Font.pointSize { return false }
        if self.rOrg_Visuals.rOrgTitle_TitleText_Font.isBold != baseRec.rOrg_Visuals.rOrgTitle_TitleText_Font.isBold { return false }
        if self.rOrg_Visuals.rOrgTitle_TitleText_Font.isItalic != baseRec.rOrg_Visuals.rOrgTitle_TitleText_Font.isItalic { return false }
        return true
    }
#endif
    
    /////////////////////////////////////////////////////////////////////////
    // Regionalization methods via RecOrganizationLangs
    /////////////////////////////////////////////////////////////////////////
    
    // get the language name in the language itself
    // throws if error in loadLangRecs()
    public func getLangNameInLang(langRegion:String) throws -> String {
        if (self.mOrg_Lang_Recs?.count ?? 0) == 0  { try self.loadLangRecs(method: "\(RecOrganizationDefs.mCTAG).getLangNameInLang") }
        let inx = self.chooseLangRec(langRegion: langRegion)
        if inx >= 0 { return self.mOrg_Lang_Recs![inx].rOrgLang_Lang_Title_Shown }
        return AppDelegate.makeFullDescription(forLangRegion: langRegion, inLangRegion: langRegion, noCode: true)
    }

    // get the organization title for a indicated language
    // throws if error in loadLangRecs()
    public func getOrgTitleShown(langRegion:String) throws -> String? {
        if (self.mOrg_Lang_Recs?.count ?? 0) == 0  { try self.loadLangRecs(method: "\(RecOrganizationDefs.mCTAG).getOrgTitleShown") }
        let inx = self.chooseLangRec(langRegion: langRegion)
        if inx < 0 { return nil }
        return self.mOrg_Lang_Recs![inx].rOrgLang_Org_Title_Shown
    }
    
    // set the organization title for the specified language
    // throws if error in loadLangRecs()
    public func setOrgTitleShown_Editing(langRegion:String, title:String!) throws {
        if (self.mOrg_Lang_Recs?.count ?? 0) == 0 { try self.loadLangRecs(method: "\(RecOrganizationDefs.mCTAG).setOrgTitleShown") }
        var inx = self.chooseLangRec(langRegion: langRegion)
        if inx < 0 { inx = self.addNewPlaceholderLangRec(forLangRegion: langRegion) }
        if inx >= 0 {
            self.mOrg_Lang_Recs![inx].rOrgLang_Org_Title_Shown = title
            self.mOrg_Lang_Recs_are_changed = true
        }
    }
    
    // get the event title for a indicated language
    // throws if error in loadLangRecs()
    public func getEventTitleShown(langRegion:String) throws -> String? {
        if (self.mOrg_Lang_Recs?.count ?? 0) == 0 { try self.loadLangRecs(method: "\(RecOrganizationDefs.mCTAG).getEventTitleShown") }
        let inx = self.chooseLangRec(langRegion: langRegion)
        if inx < 0 { return nil }
        return self.mOrg_Lang_Recs![inx].rOrgLang_Event_Title_Shown
    }
    
    // set the event title for the specified language
    // throws if error in loadLangRecs()
    public func setEventTitleShown_Editing(langRegion:String, title:String!) throws {
        if (self.mOrg_Lang_Recs?.count ?? 0) == 0 { try self.loadLangRecs(method: "\(RecOrganizationDefs.mCTAG).setEventTitleShown") }
        var inx = self.chooseLangRec(langRegion: langRegion)
        if inx < 0 { inx = self.addNewPlaceholderLangRec(forLangRegion: langRegion) }
        if inx >= 0 {
            self.mOrg_Lang_Recs![inx].rOrgLang_Event_Title_Shown = title
            self.mOrg_Lang_Recs_are_changed = true
        }
    }
    
    // does a particular language rec exist?
    public func existsLangRec(forLangRegion:String) -> Bool {
        for orgLangRec in self.mOrg_Lang_Recs! {
            if orgLangRec.rOrgLang_LangRegionCode == forLangRegion && !orgLangRec.mDuringEditing_isDeleted { return true }
        }
        return false
    }

    // get an existing lang rec
    public func getLangRec(forLangRegion:String, includingDeleted:Bool=false) -> RecOrganizationLangs? {
        if self.mOrg_Lang_Recs == nil { return nil }
        for orgLangRec in self.mOrg_Lang_Recs! {
            if orgLangRec.rOrgLang_LangRegionCode == forLangRegion {
                if includingDeleted || !orgLangRec.mDuringEditing_isDeleted { return orgLangRec }
            }
        }
        return nil
    }
    
    // mark an existing lang rec for later deletion (allows auto-recovery during Editing)
    public func markDeletedLangRec(forLangRegion:String) {
        if forLangRegion == self.rOrg_LangRegionCode_SV_File { return } // must not delete the SV-File language
        
        for orgLangRec in self.mOrg_Lang_Recs! {
            if orgLangRec.rOrgLang_LangRegionCode == forLangRegion {
                if !orgLangRec.mDuringEditing_isDeleted {
                    orgLangRec.mDuringEditing_isDeleted = true
                    self.mOrg_Lang_Recs_are_changed = true
                    var inx:Int = 0
                    for orgLangRegionString in self.rOrg_LangRegionCodes_Supported {
                        if orgLangRegionString == forLangRegion {
                            self.rOrg_LangRegionCodes_Supported.remove(at: inx)
                            break
                        }
                        inx = inx + 1
                    }
                }
                break
            }
        }
    }
    
    // undelete a deleted lang rec (allows auto-recovery during Editing)
    public func markUndeletedLangRec(forLangRegion:String) {
        for orgLangRec in self.mOrg_Lang_Recs! {
            if orgLangRec.rOrgLang_LangRegionCode == forLangRegion {
                if orgLangRec.mDuringEditing_isDeleted {
                    orgLangRec.mDuringEditing_isDeleted = false
                    self.mOrg_Lang_Recs_are_changed = true
                    self.rOrg_LangRegionCodes_Supported.append(forLangRegion)
                    break
                }
            }
        }
    }
    
    // add a new placeholder RecOrganizationLangs to the per-language records;
    // returns the index# of the added record; returns -1 if the forLangRegion already exists undeleted;
    // this func does not cause throws which simplifies some handling in OrgEditViewController
    public func addNewPlaceholderLangRec(forLangRegion:String) -> Int {
        if self.mOrg_Lang_Recs == nil { self.mOrg_Lang_Recs = [] }
        
        // first see if we can un-delete a matching deleted one; this allow the end-user to recover their pre-existing per-language Org-Title
        var inx:Int = 0
        for orgLangRec in self.mOrg_Lang_Recs! {
            if orgLangRec.rOrgLang_LangRegionCode == forLangRegion {
                // an existing record of that langRegion is already present
                if orgLangRec.mDuringEditing_isDeleted {
                    // its marked as deleted, so undelete it
                    orgLangRec.mDuringEditing_isDeleted = false
                    self.mOrg_Lang_Recs_are_changed = true
                    if !self.rOrg_LangRegionCodes_Supported.contains(forLangRegion) {
                        self.rOrg_LangRegionCodes_Supported.append(forLangRegion)
                    }
                    return inx
                } else {
                    // its not deleted; cannot add a duplicate OrgLang record
                    return -1
                }
            }
            inx = inx + 1
        }
        
        let newOrgLangRec:RecOrganizationLangs = RecOrganizationLangs(langRegion_code: forLangRegion, withOrgRec: self)
        newOrgLangRec.mDuringEditing_isPartial = true
        if !self.rOrg_LangRegionCodes_Supported.contains(forLangRegion) {
            self.rOrg_LangRegionCodes_Supported.append(forLangRegion)
        }
        self.mOrg_Lang_Recs!.append(newOrgLangRec)
        self.mOrg_Lang_Recs_are_changed = true
        
        return self.mOrg_Lang_Recs!.count - 1
    }
    
    // add a new final RecOrganizationLangs to the per-language records;
    // returns the index# of the added record; returns -1 if the forLangRegion already exists undeleted
    // throws upon filesystem errors getting the language defaults
    public func addNewFinalLangRec(forLangRegion:String) throws -> Int {
        if self.mOrg_Lang_Recs == nil { self.mOrg_Lang_Recs = [] }
        
        // first see if we can un-delete a matching deleted one; this allow the end-user to recover their pre-existing per-language Org-Title
        var inx:Int = 0
        for orgLangRec in self.mOrg_Lang_Recs! {
            if orgLangRec.rOrgLang_LangRegionCode == forLangRegion {
                // an existing record of that langRegion is already present
                if orgLangRec.mDuringEditing_isDeleted {
                    // its marked as deleted, so undelete it
                    orgLangRec.mDuringEditing_isDeleted = false
                    self.mOrg_Lang_Recs_are_changed = true
                    if !self.rOrg_LangRegionCodes_Supported.contains(forLangRegion) {
                        self.rOrg_LangRegionCodes_Supported.append(forLangRegion)
                    }
                    return inx
                } else {
                    // its not deleted; cannot add a duplicate OrgLang record
                    return -1
                }
            }
            inx = inx + 1
        }
        
        // not pre-existing as deleted, so truly add this record
        var jsonLangRec:RecJsonLangDefs?
        var newOrgLangRec:RecOrganizationLangs
        do {
            jsonLangRec = try AppDelegate.mFieldHandler!.getLangInfo(forLangRegion: forLangRegion, noSubstitution: true)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).addNewFinalLangRec")
            throw appError
        } catch { throw error }
        
        if jsonLangRec != nil {
            // found a JSON entry for this language
            let title_svfile = AppDelegate.makeFullDescription(forLangRegion: jsonLangRec!.mLang_LangRegionCode!, inLangRegion: self.rOrg_LangRegionCode_SV_File, noCode: true)
            newOrgLangRec = RecOrganizationLangs(org_code_sv_file: self.rOrg_Code_For_SV_File, langRegion_code: jsonLangRec!.mLang_LangRegionCode!, lang_title_en: jsonLangRec!.rLang_Name_English!, lang_title_shown: jsonLangRec!.rLang_Name_Speaker!, lang_image_png: jsonLangRec!.rLang_Icon_PNG_Blob, lang_title_svfile: title_svfile)
        } else {
            // no JSON found, so build it from scratch using iOS language mappings
            newOrgLangRec = RecOrganizationLangs(langRegion_code: forLangRegion, withOrgRec: self)
        }
        
        if !self.rOrg_LangRegionCodes_Supported.contains(forLangRegion) {
            self.rOrg_LangRegionCodes_Supported.append(forLangRegion)
        }
        self.mOrg_Lang_Recs!.append(newOrgLangRec)
        self.mOrg_Lang_Recs_are_changed = true
        
        return self.mOrg_Lang_Recs!.count - 1
    }
    
    // load all the Organization's per-language records;
    // throws any database or filesystem errors
    public func loadLangRecs(method:String) throws {
        self.mOrg_Lang_Recs = nil
        self.mOrg_Lang_Recs_are_changed = false
        
        // load all records stored in the database
        var SVFileLanRegionFound:Bool = false
        do {
            let records:AnySequence<Row> = try RecOrganizationLangs.orgLangGetAllRecs(orgShortName: self.rOrg_Code_For_SV_File)
            self.mOrg_Lang_Recs = []
            for rowRec in records {
                let orglangRec = try RecOrganizationLangs(row:rowRec)
                if orglangRec.rOrgLang_LangRegionCode == self.rOrg_LangRegionCode_SV_File { SVFileLanRegionFound = true }
                self.mOrg_Lang_Recs!.append(orglangRec)
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(method):\(RecOrganizationDefs.mCTAG).loadLangRecs")
            throw appError
        } catch { throw error }
        
        // safety or during initial creation of a new RecOrganizationDefs; are all the records missing?
        do {
            if self.mOrg_Lang_Recs!.count == 0 {
                // yes, force-create the SV-File language
                let _ = try self.addNewFinalLangRec(forLangRegion: self.rOrg_LangRegionCode_SV_File)
                
                // force-create all languages shown (if missing)
                for langRegion in self.rOrg_LangRegionCodes_Supported {
                    if langRegion != self.rOrg_LangRegionCode_SV_File {
                        let _ = try self.addNewFinalLangRec(forLangRegion: langRegion)
                    }
                }
            } else if !SVFileLanRegionFound {
                // there are record but the SV-File langRegion is missing , force-create the SV-File langRegion
                let _ = try self.addNewFinalLangRec(forLangRegion: self.rOrg_LangRegionCode_SV_File)
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(method):\(RecOrganizationDefs.mCTAG).loadLangRecs")
            throw appError
        } catch { throw error }
    }
    
    // choose the RecOrganizationLangs that will be used
    private func chooseLangRec(langRegion:String) -> Int {
        if self.mOrg_Lang_Recs == nil { return -1 }
        if self.mOrg_Lang_Recs!.count == 0 { return -1 }
        if self.mOrg_Lang_Recs!.count == 1 { return 0 }
        
        var inx:Int = 0
        for orgLangRec in self.mOrg_Lang_Recs! {
            if orgLangRec.rOrgLang_LangRegionCode == langRegion && !orgLangRec.mDuringEditing_isDeleted { return inx }
            inx = inx + 1
        }
        var lang:String = langRegion
        if langRegion.contains("-") {
            lang = langRegion.components(separatedBy: "-")[0]
            inx = 0
            for orgLangRec in self.mOrg_Lang_Recs! {
                if orgLangRec.rOrgLang_LangRegionCode == lang && !orgLangRec.mDuringEditing_isDeleted { return inx }
                inx = inx + 1
            }
        }
        inx = 0
        for orgLangRec in self.mOrg_Lang_Recs! {
            var workingLang:String = orgLangRec.rOrgLang_LangRegionCode
            if workingLang.contains("-") {
                workingLang = workingLang.components(separatedBy: "-")[0]
            }
            if workingLang == lang { return inx }
            inx = inx + 1
        }
        inx = 0
        for orgLangRec in self.mOrg_Lang_Recs! {
            if orgLangRec.rOrgLang_LangRegionCode == self.rOrg_LangRegionCodes_Supported[0] && !orgLangRec.mDuringEditing_isDeleted { return inx }
            inx = inx + 1
        }
        return 0
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Database interaction methods used throughout the application
    /////////////////////////////////////////////////////////////////////////
    
    // return the quantity of Org records
    // throws exceptions either for local errors or from the database
    public static func orgGetQtyRecs() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgGetQtyRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        return try AppDelegate.mDatabaseHandler!.genericQueryQty(method:"\(self.mCTAG).orgGetQtyRecs", table:Table(RecOrganizationDefs.TABLE_NAME), whereStr:nil, valuesBindArray:nil)
    }
    
    // get all Org records (which could be none); sorted in alphanumeric order of the short name aka name_for_sv_file
    // throws exceptions either for local errors or from the database
    public static func orgGetAllRecs() throws -> AnySequence<Row> {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgGetAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrganizationDefs.TABLE_NAME).select(*).order(RecOrganizationDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE.asc)
        return try AppDelegate.mDatabaseHandler!.genericQuery(method:"\(self.mCTAG).orgGetAllRecs", tableQuery:query)
    }
    
    // get one specific Org record by short name
    // throws exceptions either for local errors or from the database
    // null indicates the record was not found
    public static func orgGetSpecifiedRecOfShortName(orgShortName:String) throws -> RecOrganizationDefs? {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgGetSpecifiedRecOfShortName", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrganizationDefs.TABLE_NAME).select(*).filter(RecOrganizationDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == orgShortName)
        let record = try AppDelegate.mDatabaseHandler!.genericQueryOne(method:"\(self.mCTAG).orgGetSpecifiedRecOfShortName", tableQuery:query)
        if record == nil { return nil }
        return try RecOrganizationDefs(row:record!)
    }
    
    // add an Org entry; return is the RowID of the new record (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveNewToDB() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrganizationDefs.mCTAG).saveNewToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).saveNewToDB")
            throw appError
        } catch { throw error}
        
        let rowID = try AppDelegate.mDatabaseHandler!.insertRec(method:"\(RecOrganizationDefs.mCTAG).saveNewToDB", table:Table(RecOrganizationDefs.TABLE_NAME), cv:setters, orReplace:false, noAlert:false)
        if self.mOrg_Lang_Recs_are_changed {
            do {
                try self.addLangRecs()
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).saveNewToDB")
                throw appError
            } catch { throw error}
        }
        return rowID
    }
    
    // replace an Org entry; return is the quantity of replaced records (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveChangesToDB(originalOrgRec:RecOrganizationDefs) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrganizationDefs.mCTAG).saveChangesToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).saveChangesToDB")
            throw appError
        } catch { throw error}
        
        let query = Table(RecOrganizationDefs.TABLE_NAME).select(*).filter(RecOrganizationDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == originalOrgRec.rOrg_Code_For_SV_File)
        let qty = try AppDelegate.mDatabaseHandler!.updateRec(method:"\(RecOrganizationDefs.mCTAG).saveChangesToDB", tableQuery:query, cv:setters)
        if self.mOrg_Lang_Recs_are_changed {
            do {
                try self.updateLangRecs()
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).saveChangesToDB")
                throw appError
            } catch { throw error}
        }
        return qty
    }
    
    // delete the Org record; return is the count of records deleted (negative will not be returned;
    // note: this will also delete all the Org's forms and formfields
    // throws exceptions either for local errors or from the database
    public func deleteFromDB() throws -> Int {
        if self.rOrg_Code_For_SV_File.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrganizationDefs.mCTAG).deleteFromDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "self.rOrg_Code_For_SV_File.isEmpty")
        }
        return try RecOrganizationDefs.orgDeleteRec(orgShortName:self.rOrg_Code_For_SV_File)
    }
    
    // delete the indicated Org record; return is the count of records deleted (negative will not be returned;
    // note: this will also delete all the Org's forms and formfields
    // throws exceptions either for local errors or from the database
    public static func orgDeleteRec(orgShortName:String) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).orgDeleteRec", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrganizationDefs.TABLE_NAME).select(*).filter(RecOrganizationDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == orgShortName)
        let qty = try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).orgDeleteRec", tableQuery:query)

        // maintain referential integrity
        // ?? the custom Fields and FieldLocales
        do {
            _ = try RecOrgFormFieldLocales.formFieldLocalesDeleteAllRecs(forOrgShortName:orgShortName, forFormShortName:nil)
            _ = try RecOrgFormFieldDefs.orgFormFieldDeleteAllRecs(forOrgShortName:orgShortName, forFormShortName:nil)
            _ = try RecOrgFormDefs.orgFormDeleteAllRecs(forOrgShortName:orgShortName)
            _ = try RecOrganizationLangs.orgLangDeleteAllRecs(forOrgShortName:orgShortName)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).orgDeleteRec")
            throw appError
        } catch { throw error}
        return qty
    }
    
    /////////////////////////////////////////////////////////////////////////
    // manage internally stored RecOrganizationLangs
    /////////////////////////////////////////////////////////////////////////
    
    // add/update all stored RecOrganizationLangs records
    private func addLangRecs() throws {
        if self.mOrg_Lang_Recs != nil {
            for orgLangRec in self.mOrg_Lang_Recs! {
                orgLangRec.rOrg_Code_For_SV_File = self.rOrg_Code_For_SV_File   // fill in in-case of deferred setting of Org short name during Editing
                if !orgLangRec.mDuringEditing_isDeleted {
                    // record is not marked as deleted so add it
                    do {
                        _ = try orgLangRec.saveToDB()
                    } catch var appError as APP_ERROR {
                        appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).addLangRecs")
                        throw appError
                    } catch { throw error}
                } else if orgLangRec.rOrgLang_LangRegionCode == self.rOrg_LangRegionCode_SV_File {
                    // must not delete the SV-File language record
                    do {
                        _ = try orgLangRec.saveToDB()
                    } catch var appError as APP_ERROR {
                        appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).addLangRecs")
                        throw appError
                    } catch { throw error}
                }
            }
        }
        self.mOrg_Lang_Recs_are_changed = false
    }
    
    // add/update/delete all stored RecOrganizationLangs records
    private func updateLangRecs() throws {
        if self.mOrg_Lang_Recs != nil {
            for orgLangRec in self.mOrg_Lang_Recs! {
                orgLangRec.rOrg_Code_For_SV_File = self.rOrg_Code_For_SV_File   // fill in in-case of deferred setting of Org short name during Editing
                if !orgLangRec.mDuringEditing_isDeleted {
                    // record is not marked as deleted, so add/update it
                    do {
                        _ = try orgLangRec.saveToDB()
                    } catch var appError as APP_ERROR {
                        appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).updateLangRecs")
                        throw appError
                    } catch { throw error}
                } else if orgLangRec.rOrgLang_LangRegionCode == self.rOrg_LangRegionCode_SV_File {
                    // must not delete the SV-File language record
                    do {
                        _ = try orgLangRec.saveToDB()
                    } catch var appError as APP_ERROR {
                        appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).updateLangRecs")
                        throw appError
                    } catch { throw error}
                } else {
                    // delete the existing language record
                    do {
                        _ = try orgLangRec.deleteFromDB()
                    } catch var appError as APP_ERROR {
                        appError.prependCallStack(funcName: "\(RecOrganizationDefs.mCTAG).updateLangRecs")
                        throw appError
                    } catch { throw error}
                }
            }
        }
        self.mOrg_Lang_Recs_are_changed = false
    }
}
