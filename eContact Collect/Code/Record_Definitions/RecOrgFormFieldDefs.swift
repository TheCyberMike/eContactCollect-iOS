//
//  RecOrgFormFieldDefs.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import SQLite

// field data format types; these are not vCard properties
// note: data format types such as credit card#, bank account#, drivers license#, national ID#, etc are deliberately left out
//       as the App is not sufficiently secure to store or transmit them
public enum FIELD_ROW_TYPE: Int {
    case SECTION = 1                        // no data entry
    case LABEL = 2                          // no data entry
    case TEXT = 3                           // any characters, one line
    case TEXT_MULTILINE = 4                 // any characters, multiple lines
    case ALPHANUMERIC = 5                   // a thru z, A thru Z, 0 thru 9, space
    case NUMBER = 6                         // 0 thru 9, additionally: + - . 
    case DIGITS = 7                         // 0 thru 9 only
    case HEXADECIMAL = 8                    // 0 thru 9, A thru F case-insensitive
    //case CURRENCY = 9                       // 0 thru 9, additionally: $ + - .
    /*{"field_sort_order":"50_009","fieldprop_idcode":"FC_GNumCurrency","fieldprop_row_type":"FRT_currency"},*/
    /*{"fieldprop_idcode":"FC_GNumCurrency","fieldlocprop_name_for_collector":"Number-Currency","fieldprop_name_sv_file":"Amount",
      "fieldlocprop_name_shown":"Amount"},*/
    /*{"fieldprop_idcode":"FC_GNumCurrency","fieldlocprop_name_for_collector":"Number-Currency","fieldprop_name_sv_file":"Amount",
      "fieldlocprop_name_shown":"Amount"},*/
    case DATE = 10                           // stored as YYYY/MM/DD
    case DATE_BEFORE_TODAY = 11             // stored as YYYY/MM/DD
    case TIME_12 = 12                       // stored as HH:MM:SS.mm *M
    case TIME_24 = 13                       // stored as HH:MM:SS.mm
    //case TIMEZONE_OFFSET_UTC_MIN = 14       // stored as +/- integer minutes from UTC
    case NAME_PERSON = 15                   // any characters; Word capitalization
    case NAME_PERSON_HONOR = 16             // any characters; Word capitalization
    case NAME_PERSON_CONTAINER = 17         // any characters; Word capitalization, [prefix, first, middle, last, post]
    case NAME_ORGANIZATION = 18             // any characters; Word capitalization
    case PHONE_CONTAINER = 19               // [use, intl, phone, extension]
    case PHONE_WORK = 20                    // phone + extension
    case PHONE_3 = 21                       // 3-component basic phone number
    case PHONE_EXT = 22                     // 0 thru 9, additionally: #, *
    case PHONE_INTL_CODE = 23               // intl standard + codes
    case PRONOUNS = 24                      // expanded set
    case LANGUAGE_ISO_CODE = 25             // ISO two-char language codes
    case EMAIL = 26                         // userid@domain
    case URL = 27
    //case SOCIAL_MEDIA = 28                  // site-name @ userid
    /*{"field_sort_order":"03_007","fieldprop_idcode":"FC_SocMed","fieldprop_row_type":"FRT_social_media",
      "fieldprop_flags":"V","fieldprop_attribs_tag":"$f,$i,$t,$l,$s"},*/
    /*{"fieldprop_idcode":"FC_SocMed","fieldlocprop_name_for_collector":"SocialMedia","fieldprop_name_sv_file":"SocialMedia","fieldlocprop_name_shown":"Social Media",
      "fieldlocprop_attribs":"$f:facebook.com:FaceBook,$i:instagram.com:Instagram,$t:twitter.com:Twitter,$l:linkedin.com:Linkedin,$s:APP.snapchat:Snapchat"},*/
    /*{"fieldprop_idcode":"FC_SocMed","fieldlocprop_name_for_collector":"SocialMedia","fieldprop_name_sv_file":"SocialMedia","fieldlocprop_name_shown":"Social Media",
      "fieldlocprop_attribs":"$f:facebook.com:FaceBook,$i:instagram.com:Instagram,$t:twitter.com:Twitter,$l:linkedin.com:Linkedin,$s:APP.snapchat:Snapchat"},*/
    case ADDRESS_CONTAINER = 29             // [country, extra, street, city, state-prov-code, postal-code]
    case ADDRESS_COUNTRY_ISO_CODE = 30
    case STATE_PROVINCE_CODE_BY_COUNTRY_ISO_CODE = 31
    case POSTAL_CODE_NUMERIC = 32      // A thru Z, 0 thru 9, space, dash
    case POSTAL_CODE_ALPHANUMERIC = 33      // A thru Z, 0 thru 9, space, dash
    case CHOOSE_1 = 34
    case CHOOSE_ANY = 35
    case CHOOSE_1_OTHER = 36
    case CHOOSE_ANY_OTHER = 37
    case YESNO = 38
    case YESNOMAYBE = 39
    
    public static func getFieldRowType(fromString:String) -> FIELD_ROW_TYPE {
        switch fromString {
        case "FRT_section": return .SECTION
        case "FRT_label": return .LABEL
        case "FRT_text": return .TEXT
        case "FRT_text_multiline": return .TEXT_MULTILINE
        case "FRT_alphanumeric": return .ALPHANUMERIC
        case "FRT_number": return .NUMBER
        case "FRT_digits": return .DIGITS
        case "FRT_hex": return .HEXADECIMAL
        //case "FRT_currency": return .CURRENCY
        case "FRT_date": return .DATE
        case "FRT_date_before_today": return .DATE_BEFORE_TODAY
        case "FRT_time12": return .TIME_12
        case "FRT_time24": return .TIME_24
        //case "FRT_tz_off_utc_min": return .TIMEZONE_OFFSET_UTC_MIN
        case "FRT_name_person": return .NAME_PERSON
        case "FRT_name_person_honor": return .NAME_PERSON_HONOR
        case "FRT_name_person_container": return .NAME_PERSON_CONTAINER
        case "FRT_name_organization": return .NAME_ORGANIZATION
        case "FRT_phone_container": return .PHONE_CONTAINER
        case "FRT_phone_work": return .PHONE_WORK
        case "FRT_phone_3": return .PHONE_3
        case "FRT_phone_ext": return .PHONE_EXT
        case "FRT_phone_intl_code": return .PHONE_INTL_CODE
        case "FRT_pronouns": return .PRONOUNS
        case "FRT_lang_ISO_code": return .LANGUAGE_ISO_CODE
        case "FRT_email": return .EMAIL
        case "FRT_URL": return .URL
        //case "FRT_social_media": return .SOCIAL_MEDIA
        case "FRT_addr_container": return .ADDRESS_CONTAINER
        case "FRT_addr_country_code": return .ADDRESS_COUNTRY_ISO_CODE
        case "FRT_addr_state_prov_code": return .STATE_PROVINCE_CODE_BY_COUNTRY_ISO_CODE
        case "FRT_addr_postal_numeric": return .POSTAL_CODE_NUMERIC
        case "FRT_addr_postal_alpha": return .POSTAL_CODE_ALPHANUMERIC
        case "FRT_choose_1": return .CHOOSE_1
        case "FRT_choose_any": return .CHOOSE_ANY
        case "FRT_choose_1_other": return .CHOOSE_1_OTHER
        case "FRT_choose_any_other": return .CHOOSE_ANY_OTHER
        case "FRT_yesNo": return .YESNO
        case "FRT_yesNoMaybe": return .YESNOMAYBE
        default:
assertionFailure("Unknown FRT in FieldDefs.json")
            return .TEXT
        }
    }
    public static func getFieldRowTypeString(fromType:FIELD_ROW_TYPE) -> String {
        switch fromType {
        case .SECTION: return "FRT_section"
        case .LABEL: return "FRT_label"
        case .TEXT: return "FRT_text"
        case .TEXT_MULTILINE: return "FRT_text_multiline"
        case .ALPHANUMERIC: return "FRT_alphanumeric"
        case .NUMBER: return "FRT_number"
        case .DIGITS: return "FRT_digits"
        case .HEXADECIMAL: return "FRT_hex"
        //case .CURRENCY: return "FRT_currency"
        case .DATE: return "FRT_date"
        case .DATE_BEFORE_TODAY: return "FRT_date_before_today"
        case .TIME_12: return "FRT_time12"
        case .TIME_24: return "FRT_time24"
        //case .TIMEZONE_OFFSET_UTC_MIN: return "FRT_tz_off_utc_min"
        case .NAME_PERSON: return "FRT_name_person"
        case .NAME_PERSON_HONOR: return "FRT_name_person_honor"
        case .NAME_PERSON_CONTAINER: return "FRT_name_person_container"
        case .NAME_ORGANIZATION: return "FRT_name_organization"
        case .PHONE_CONTAINER: return "FRT_phone_container"
        case .PHONE_WORK: return "FRT_phone_work"
        case .PHONE_3: return "FRT_phone_3"
        case .PHONE_EXT: return "FRT_phone_ext"
        case .PHONE_INTL_CODE: return "FRT_phone_intl_code"
        case .PRONOUNS: return "FRT_pronouns"
        case .LANGUAGE_ISO_CODE: return "FRT_lang_ISO_code"
        case .EMAIL: return "FRT_email"
        case .URL: return "FRT_URL"
        //case .SOCIAL_MEDIA: return "FRT_social_media"
        case .ADDRESS_CONTAINER: return "FRT_addr_container"
        case .ADDRESS_COUNTRY_ISO_CODE: return "FRT_addr_country_code"
        case .STATE_PROVINCE_CODE_BY_COUNTRY_ISO_CODE: return "FRT_addr_state_prov_code"
        case .POSTAL_CODE_NUMERIC: return "FRT_addr_postal_numeric"
        case .POSTAL_CODE_ALPHANUMERIC: return "FRT_addr_postal_alpha"
        case .CHOOSE_1: return "FRT_choose_1"
        case .CHOOSE_ANY: return "FRT_choose_any"
        case .CHOOSE_1_OTHER: return "FRT_choose_1_other"
        case .CHOOSE_ANY_OTHER: return "FRT_choose_any_other"
        case .YESNO: return "FRT_yesNo"
        case .YESNOMAYBE: return "FRT_yesNoMaybe"
        }
    }
}

// MetaData field_IDCodes
public enum FIELD_IDCODE_METADATA:String {
    case SUBMIT_BUTTON = "FC_$ButtonSubmit"
    case NAME_FULL = "FC_$NameFull"
    case NAME_COLLECT_DATE = "FC_$CollectDate"
    case NAME_COLLECT_TIME = "FC_$CollectTime"
    case NAME_COLLECT_ORG = "FC_$CollectOrg"
    case NAME_COLLECT_FORM = "FC_$CollectForm"
    case NAME_COLLECT_EVENT = "FC_$CollectEvent"
    case NAME_COLLECT_COLLECTED_BY = "FC_$CollectBy"
    case NAME_COLLECT_LANG_USED = "FC_$LangUsed"
    case NAME_COLLECT_COLLECTOR_IMPORTANCE = "FC_$CollectImp"
    case NAME_COLLECT_COLLECTOR_NOTES = "FC_$CollectNotes"
}

/*
    rFieldProp_Flags:
    S = meta-field entry used to create section titles in the list of available fields; not an actual entrable or meta-data field
    M = meta-data field; end-user cannot delete or add these; only change their Column names or in the case of the Submit button its Shown name
    F = options contains ONLY fixed attributes (can be edited but not add/move/delete); may also include meta-data
    V = options contains Variable attributes (can add, delete, or re-order them); it may also include Fixed attributes or Metadata attributes
*/

// special-use version of the record that is all optional; used for importing JSON records and
// specialized database queries if not every field will to be loaded; this record cannot be saved to the database
public class RecOrgFormFieldDefs_Optionals {
    // record members
    public var rFormField_Index:Int64?
    public var rOrg_Code_For_SV_File:String?
    public var rForm_Code_For_SV_File:String?
    public var rFormField_Order_Shown:Int? = 0
    public var rFormField_Order_SV_File:Int? = 0
    public var rFormField_SubField_Within_FormField_Index:Int64?
    public var rFieldProp_IDCode:String?
    public var rFieldProp_Col_Name_For_SV_File:String?
    public var rFieldProp_Row_Type:FIELD_ROW_TYPE?
    public var rFieldProp_Flags:String?
    public var rFieldProp_vCard_Property:String?
    public var rFieldProp_vCard_Subproperty_No:Int?
    public var rFieldProp_vCard_Property_Subtype:String?
    public var rFieldProp_Contains_Field_IDCodes:[String]?
    public var rFieldProp_Options_Code_For_SV_File:FieldAttributes?
    public var rFieldProp_Metadatas_Code_For_SV_File:FieldAttributes?
    
    // constructor creates the record from a pair of json records
    init(jsonRec:RecJsonFieldDefs, forOrgShortName:String, forFormShortName:String?, withJsonFieldLocaleRec:RecJsonFieldLocales) {
        self.rFormField_Index = -1
        self.rOrg_Code_For_SV_File = forOrgShortName
        self.rForm_Code_For_SV_File = forFormShortName
        self.rFormField_Order_Shown = 0
        self.rFormField_Order_SV_File = 0
        self.rFormField_SubField_Within_FormField_Index = nil
        
        self.rFieldProp_IDCode = jsonRec.rFieldProp_IDCode
        self.rFieldProp_Col_Name_For_SV_File = withJsonFieldLocaleRec.rFieldLocProp_Col_Name_For_SV_File
        self.rFieldProp_Row_Type = jsonRec.rFieldProp_Row_Type
        self.rFieldProp_Flags = jsonRec.rFieldProp_Flags
        self.rFieldProp_vCard_Property = jsonRec.rFieldProp_vCard_Property
        self.rFieldProp_vCard_Subproperty_No = jsonRec.rFieldProp_vCard_Subproperty_No
        self.rFieldProp_vCard_Property_Subtype = jsonRec.rFieldProp_vCard_Property_Subtype
        self.rFieldProp_Contains_Field_IDCodes = jsonRec.rFieldProp_Initial_Field_IDCodes
        
        // break up the localizable option attribute sets; they could be singletons, pairs, or trios
        if (withJsonFieldLocaleRec.rFieldLocProp_Option_Trios?.count ?? 0) > 0 {
            self.rFieldProp_Options_Code_For_SV_File = FieldAttributes()
            for setString in withJsonFieldLocaleRec.rFieldLocProp_Option_Trios! {
                // format can be one of: tag:SV:shown or SV:shown or SV&Shown or
                //                       tag:[SVitem;SVitem;...]:[ShowItem;ShowItem;...] which is only used for Pronouns
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count >= 2 {
                    self.rFieldProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else {
                    self.rFieldProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[0])
                }
            }
        } else if (jsonRec.rFieldProp_Option_Tags?.count ?? 0) > 0 {
            // localized appear to be missing
            self.rFieldProp_Options_Code_For_SV_File = FieldAttributes()
            for setString in jsonRec.rFieldProp_Option_Tags! {
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count >= 2 {
                    self.rFieldProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else {
                    self.rFieldProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[0])
                }
            }
        }
        
        // break up the localizable metadata attribute sets; they could be singletons, pairs, or trios
        if (withJsonFieldLocaleRec.rFieldLocProp_Metadata_Trios?.count ?? 0) > 0 {
            self.rFieldProp_Metadatas_Code_For_SV_File = FieldAttributes()
            for setString in withJsonFieldLocaleRec.rFieldLocProp_Metadata_Trios! {
                // format can be one of: tag:SV:shown or SV:shown or SV&Shown
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count >= 2 {
                    self.rFieldProp_Metadatas_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else {
                    self.rFieldProp_Metadatas_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[0])
                }
            }
        }
        // also check for non-localizable meta-data attributes
        if (jsonRec.rFieldProp_Metadata_Tags?.count ?? 0) > 0 {
            if self.rFieldProp_Metadatas_Code_For_SV_File == nil { self.rFieldProp_Metadatas_Code_For_SV_File = FieldAttributes() }
            for setString in jsonRec.rFieldProp_Metadata_Tags! {
                let setComponents = setString.components(separatedBy: ":")
                if !self.rFieldProp_Metadatas_Code_For_SV_File!.codeExists(givenCode: setComponents[0]) {
                    if setComponents.count >= 2 {
                        self.rFieldProp_Metadatas_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[1])
                    } else {
                        self.rFieldProp_Metadatas_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[0])
                    }
                }
            }
        }
    }
    
    // constructor creates the record from a JSON object; is tolerant of missing columns;
    // must be tolerant that Int64's may be encoded as Strings, especially OIDs
    init(jsonRecObj:NSDictionary) {
        if let oidObj1 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_INDEX] {
            if oidObj1 is String {
                self.rFormField_Index = Int64(jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_INDEX] as! String)
            } else if oidObj1 is NSNumber {
                self.rFormField_Index = (jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_INDEX] as! NSNumber).int64Value
            } else {
                self.rFormField_Index = nil
            }
        } else { self.rFormField_Index = nil }
        if let oidObj2 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX] {
            if oidObj2 is String {
                self.rFormField_SubField_Within_FormField_Index = Int64(jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX] as! String)
            } else if oidObj2 is NSNumber {
                self.rFormField_SubField_Within_FormField_Index = (jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX] as! NSNumber).int64Value
            } else {
                self.rFormField_SubField_Within_FormField_Index = nil
            }
        } else { self.rFormField_SubField_Within_FormField_Index = nil }
        if let oidObj3 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO] {
            if oidObj3 is String {
                self.rFieldProp_vCard_Subproperty_No = Int(jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO] as! String)
            } else if oidObj3 is NSNumber {
                self.rFieldProp_vCard_Subproperty_No = (jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO] as! Int)
            } else {
                self.rFieldProp_vCard_Subproperty_No = nil
            }
        } else { self.rFieldProp_vCard_Subproperty_No = nil }
        
        self.rOrg_Code_For_SV_File = jsonRecObj[RecOrgFormFieldDefs.COLUMN_ORG_CODE_FOR_SV_FILE] as? String
        self.rForm_Code_For_SV_File = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORM_CODE_FOR_SV_FILE] as? String
        self.rFormField_Order_Shown = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_ORDER_SHOWN] as? Int
        self.rFormField_Order_SV_File = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_ORDER_SV_FILE] as? Int
        self.rFieldProp_IDCode = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_IDCODE] as? String
        self.rFieldProp_Col_Name_For_SV_File = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_COL_NAME_FOR_SV_FILE] as? String
        self.rFieldProp_vCard_Property = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_PROPERTY] as? String
        self.rFieldProp_vCard_Property_Subtype = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_PROPERTY_SUBTYPE] as? String
        self.rFieldProp_Flags = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_FLAGS] as? String

        let value1 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_ROW_TYPE] as? String
        if (value1 ?? "").isEmpty { self.rFieldProp_Row_Type = nil }
        else { self.rFieldProp_Row_Type = FIELD_ROW_TYPE.getFieldRowType(fromString: value1!) }
        
        // break comma-delimited String into an Array
        let value2:String? = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_CONTAINS_FIELD_IDCODES] as? String
        if !(value2 ?? "").isEmpty { self.rFieldProp_Contains_Field_IDCodes = value2!.components(separatedBy:",") }
        else { self.rFieldProp_Contains_Field_IDCodes = nil }
        let value3:String? = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE] as? String
        if !(value3 ?? "").isEmpty { self.rFieldProp_Options_Code_For_SV_File = FieldAttributes(duos: value3!.components(separatedBy:",")) }
        else { self.rFieldProp_Options_Code_For_SV_File = nil }
        let value4:String? = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_METADATAS_CODE_FOR_SV_FILE] as? String
        if !(value4 ?? "").isEmpty { self.rFieldProp_Metadatas_Code_For_SV_File = FieldAttributes(duos: value4!.components(separatedBy:",")) }
        else { self.rFieldProp_Metadatas_Code_For_SV_File = nil }
    }
    
    // is the optionals record valid in terms of required content?
    public func validate() -> Bool {
        if self.rFormField_Index == nil || self.rOrg_Code_For_SV_File == nil || self.rFormField_Order_Shown == nil ||
           self.rFormField_Order_SV_File == nil || self.rFieldProp_IDCode == nil || self.rFieldProp_Row_Type == nil || 
           self.rFieldProp_Col_Name_For_SV_File == nil { return false }
        if self.rOrg_Code_For_SV_File!.isEmpty || self.rFieldProp_IDCode!.isEmpty || self.rFieldProp_Col_Name_For_SV_File!.isEmpty { return false }
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Main Record
/////////////////////////////////////////////////////////////////////////

// full verson of the record; required fields are enforced; can be saved to the database
public class RecOrgFormFieldDefs {
    // record members
    public var rFormField_Index:Int64                           // auto-assigned index#; primary key; allows duplicate rFieldProp_IDCode in the same form
    public var rOrg_Code_For_SV_File:String                     // org's short name
    public var rForm_Code_For_SV_File:String                    // form's short name
    public var rFormField_Order_Shown:Int = 0                   // numeric ordering of the fields as shown to end-user; used only for sorting purposes
    public var rFormField_Order_SV_File:Int = 0                 // numeric ordering of the fields placed into the SV File; used only for sorting purposes
    public var rFormField_SubField_Within_FormField_Index:Int64?    // if present indicates this is a subfield of a container FormField with index#
        // field properties
    public var rFieldProp_IDCode:String                         // field IDCode
    public var rFieldProp_Col_Name_For_SV_File:String           // short column name for the field in the SV file
    public var rFieldProp_Row_Type:FIELD_ROW_TYPE               // FRT aka Field Row Type; the App's "handler" for each type of data
    public var rFieldProp_Flags:String?                         // field's flags ("M"; one of "V","F"; "S")
    public var rFieldProp_vCard_Property:String?                // field's primary vCard code; nil if none
    public var rFieldProp_vCard_Subproperty_No:Int?             // subfield within a vCard entry with multiple comma-delimited fields
    public var rFieldProp_vCard_Property_Subtype:String?        // qualifier within a vCard entry; usually a Type=
    public var rFieldProp_Contains_Field_IDCodes:[String]?      // defines the fields shown in a Container FRT
    public var rFieldProp_Options_Code_For_SV_File:FieldAttributes?    // option attributes for selected FRTs: in SV-File
    public var rFieldProp_Metadatas_Code_For_SV_File:FieldAttributes?  // metadata attributes for selected FRTs: in SV-File
    
    // member variables
    public var mFormFieldLocalesRecs_are_changed:Bool = false
    public var mFormFieldLocalesRecs:[RecOrgFormFieldLocales]? = nil

    // selected internal fields with pre-defined "formfield_order_sv_file" codes
    public static let FORMFIELD_ORDER_UPPERSTART:Int = 32000
    public static let FORMFIELD_ORDER_SUBMIT_BUTTON:Int = -999
    public static let FORMFIELD_ORDER_NAME_FULL:Int = -900
    public static let FORMFIELD_ORDER_IMPORTANCE:Int = 32000
    public static let FORMFIELD_ORDER_COLLECTED_BY:Int = 32001
    public static let FORMFIELD_ORDER_AT_EVENT:Int = 32002
    public static let FORMFIELD_ORDER_COLLECTOR_NOTES:Int = 32003
    public static let FORMFIELD_ORDER_DATE:Int = 32004
    public static let FORMFIELD_ORDER_TIME:Int = 32005
    public static let FORMFIELD_ORDER_USED_LANG:Int = 32006
    public static let FORMFIELD_ORDER_FORM:Int = 32007
    public static let FORMFIELD_ORDER_ORG:Int = 32008
    
    public static func getInternalSortOrderFromString(fromString:String) -> Int {
        switch fromString {
        case "$A_001": return FORMFIELD_ORDER_SUBMIT_BUTTON
        case "$A_002": return FORMFIELD_ORDER_NAME_FULL
        case "$B_001": return FORMFIELD_ORDER_DATE
        case "$B_002": return FORMFIELD_ORDER_TIME
        case "$B_003": return FORMFIELD_ORDER_ORG
        case "$B_004": return FORMFIELD_ORDER_AT_EVENT
        case "$B_005": return FORMFIELD_ORDER_FORM
        case "$B_006": return FORMFIELD_ORDER_COLLECTED_BY
        case "$B_007": return FORMFIELD_ORDER_USED_LANG
        case "$B_008": return FORMFIELD_ORDER_IMPORTANCE
        case "$B_009": return FORMFIELD_ORDER_COLLECTOR_NOTES
        default: return 0
        }
    }

    // member constants and other static content
    private static let mCTAG:String = "ROFF"
    public static let TABLE_NAME = "OrgFormFieldDefs"
    public static let COLUMN_FORMFIELD_INDEX = "_id"
    public static let COLUMN_ORG_CODE_FOR_SV_FILE = "org_code_sv_file"
    public static let COLUMN_FORM_CODE_FOR_SV_FILE = "form_code_sv_file"
    public static let COLUMN_FORMFIELD_ORDER_SHOWN = "formfield_order_shown"
    public static let COLUMN_FORMFIELD_ORDER_SV_FILE = "formfield_order_sv_file"
    public static let COLUMN_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX = "formfield_subfield_of_index"
    
    public static let COLUMN_FIELDPROP_IDCODE = "fieldprop_idcode"
    public static let COLUMN_FIELDPROP_COL_NAME_FOR_SV_FILE = "fieldprop_name_sv_file"
    public static let COLUMN_FIELDPROP_ROW_TYPE = "fieldprop_row_type"
    public static let COLUMN_FIELDPROP_FLAGS = "fieldprop_flags"
    public static let COLUMN_FIELDPROP_VCARD_PROPERTY = "fieldprop_vcard_property"
    public static let COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO = "fieldprop_vcard_subproperty_no"
    public static let COLUMN_FIELDPROP_VCARD_PROPERTY_SUBTYPE = "fieldprop_vcard_property_subtype"
    public static let COLUMN_FIELDPROP_CONTAINS_FIELD_IDCODES = "fieldprop_contains_IDcodes"
    public static let COLUMN_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE = "fieldprop_options_code_sv_file"
    public static let COLUMN_FIELDPROP_METADATAS_CODE_FOR_SV_FILE = "fieldprop_metadatas_code_sv_file"

    // these are the as-stored in the database expression definitions
    public static let COL_EXPRESSION_FORMFIELD_INDEX = Expression<Int64>(RecOrgFormFieldDefs.COLUMN_FORMFIELD_INDEX)
    public static let COL_EXPRESSION_ORG_CODE_FOR_SV_FILE = Expression<String>(RecOrgFormFieldDefs.COLUMN_ORG_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FORM_CODE_FOR_SV_FILE = Expression<String>(RecOrgFormFieldDefs.COLUMN_FORM_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FORMFIELD_ORDER_SHOWN = Expression<Int>(RecOrgFormFieldDefs.COLUMN_FORMFIELD_ORDER_SHOWN)
    public static let COL_EXPRESSION_FORMFIELD_ORDER_SV_FILE = Expression<Int>(RecOrgFormFieldDefs.COLUMN_FORMFIELD_ORDER_SV_FILE)
    public static let COL_EXPRESSION_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX =
        Expression<Int64?>(RecOrgFormFieldDefs.COLUMN_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX)
    
    public static let COL_EXPRESSION_FIELDPROP_IDCODE = Expression<String>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_IDCODE)
    public static let COL_EXPRESSION_FIELDPROP_COL_NAME_FOR_SV_FILE = Expression<String>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_COL_NAME_FOR_SV_FILE)
    public static let COL_EXPRESSION_FIELDPROP_ROW_TYPE = Expression<Int>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_ROW_TYPE)
    public static let COL_EXPRESSION_FIELDPROP_FLAGS = Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_FLAGS)
    public static let COL_EXPRESSION_FIELDPROP_VCARD_PROPERTY = Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_PROPERTY)
    public static let COL_EXPRESSION_FIELDPROP_VCARD_SUBPROPERTY_NO = Expression<Int?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO)
    public static let COL_EXPRESSION_FIELDPROP_VCARD_PROPERTY_SUBTYPE = Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_PROPERTY_SUBTYPE)
    public static let COL_EXPRESSION_FIELDPROP_CONTAINS_FIELD_IDCODES = Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_CONTAINS_FIELD_IDCODES)
    public static let COL_EXPRESSION_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE = Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FIELDPROP_METADATAS_CODE_FOR_SV_FILE = Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_METADATAS_CODE_FOR_SV_FILE)
    
    // generate the string that will create the table
    public static func generateCreateTableString() -> String {
        return Table(TABLE_NAME).create(ifNotExists: true) { t in
            t.column(COL_EXPRESSION_FORMFIELD_INDEX, primaryKey: .autoincrement)
            t.column(COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FORMFIELD_ORDER_SHOWN)
            t.column(COL_EXPRESSION_FORMFIELD_ORDER_SV_FILE)
            t.column(COL_EXPRESSION_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX)
            
            t.column(COL_EXPRESSION_FIELDPROP_IDCODE)
            t.column(COL_EXPRESSION_FIELDPROP_COL_NAME_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FIELDPROP_ROW_TYPE)
            t.column(COL_EXPRESSION_FIELDPROP_FLAGS)
            t.column(COL_EXPRESSION_FIELDPROP_VCARD_PROPERTY)
            t.column(COL_EXPRESSION_FIELDPROP_VCARD_SUBPROPERTY_NO)
            t.column(COL_EXPRESSION_FIELDPROP_VCARD_PROPERTY_SUBTYPE)
            t.column(COL_EXPRESSION_FIELDPROP_CONTAINS_FIELD_IDCODES)
            t.column(COL_EXPRESSION_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FIELDPROP_METADATAS_CODE_FOR_SV_FILE)
        }
    }

    // destructor
    deinit {
        if self.mFormFieldLocalesRecs != nil { self.mFormFieldLocalesRecs = nil } // likely not needed for heap management but cannot hurt
    }
    
    // create a duplicate of an existing record, including duplicates of all internally stored RecOrgFormFieldLocales records
    init(existingRec:RecOrgFormFieldDefs) {
        self.rFormField_Index = existingRec.rFormField_Index
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File
        self.rFormField_Order_Shown = existingRec.rFormField_Order_Shown
        self.rFormField_Order_SV_File = existingRec.rFormField_Order_SV_File
        self.rFormField_SubField_Within_FormField_Index = existingRec.rFormField_SubField_Within_FormField_Index

        self.rFieldProp_IDCode = existingRec.rFieldProp_IDCode
        self.rFieldProp_Col_Name_For_SV_File = existingRec.rFieldProp_Col_Name_For_SV_File
        self.rFieldProp_Row_Type = existingRec.rFieldProp_Row_Type
        self.rFieldProp_Flags = existingRec.rFieldProp_Flags
        self.rFieldProp_vCard_Property = existingRec.rFieldProp_vCard_Property
        self.rFieldProp_vCard_Subproperty_No = existingRec.rFieldProp_vCard_Subproperty_No
        self.rFieldProp_vCard_Property_Subtype = existingRec.rFieldProp_vCard_Property_Subtype
        self.rFieldProp_Contains_Field_IDCodes = existingRec.rFieldProp_Contains_Field_IDCodes
        self.rFieldProp_Options_Code_For_SV_File = existingRec.rFieldProp_Options_Code_For_SV_File
        self.rFieldProp_Metadatas_Code_For_SV_File = existingRec.rFieldProp_Metadatas_Code_For_SV_File
        
        // do a deep copy of all the internally stored RecOrgFormFieldLocales records
        self.mFormFieldLocalesRecs_are_changed = existingRec.mFormFieldLocalesRecs_are_changed
        if existingRec.mFormFieldLocalesRecs != nil {
            self.mFormFieldLocalesRecs = []
            for lRec:RecOrgFormFieldLocales in existingRec.mFormFieldLocalesRecs! {
                self.mFormFieldLocalesRecs!.append(RecOrgFormFieldLocales(existingRec: lRec))
            }
        } else { self.mFormFieldLocalesRecs = nil }
        self.mFormFieldLocalesRecs = existingRec.mFormFieldLocalesRecs
    }
    
    // import an optionals record into the mainline record
    // throws upon missing required fields; caller is responsible to error.log
    init(existingRec:RecOrgFormFieldDefs_Optionals) throws {
        if existingRec.rFormField_Index == nil || existingRec.rOrg_Code_For_SV_File == nil || existingRec.rFormField_Order_Shown == nil ||
            existingRec.rFormField_Order_SV_File == nil || existingRec.rFieldProp_IDCode == nil || existingRec.rFieldProp_Row_Type == nil ||
            existingRec.rFieldProp_Col_Name_For_SV_File == nil {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).init(RecOrgFormFieldDefs_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required == nil")
        }
        if existingRec.rOrg_Code_For_SV_File!.isEmpty || existingRec.rFieldProp_IDCode!.isEmpty || existingRec.rFieldProp_Col_Name_For_SV_File!.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).init(RecOrgFormFieldDefs_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        self.rFormField_Index = existingRec.rFormField_Index!
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File!
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File ?? ""  // this may be nil during Form Editing
        self.rFormField_Order_Shown = existingRec.rFormField_Order_Shown!
        self.rFormField_Order_SV_File = existingRec.rFormField_Order_SV_File!
        self.rFormField_SubField_Within_FormField_Index = existingRec.rFormField_SubField_Within_FormField_Index
        
        self.rFieldProp_IDCode = existingRec.rFieldProp_IDCode!
        self.rFieldProp_Col_Name_For_SV_File = existingRec.rFieldProp_Col_Name_For_SV_File!
        self.rFieldProp_Row_Type = existingRec.rFieldProp_Row_Type!
        self.rFieldProp_Flags = existingRec.rFieldProp_Flags
        self.rFieldProp_vCard_Property = existingRec.rFieldProp_vCard_Property
        self.rFieldProp_vCard_Subproperty_No = existingRec.rFieldProp_vCard_Subproperty_No
        self.rFieldProp_vCard_Property_Subtype = existingRec.rFieldProp_vCard_Property_Subtype
        self.rFieldProp_Contains_Field_IDCodes = existingRec.rFieldProp_Contains_Field_IDCodes
        self.rFieldProp_Options_Code_For_SV_File = existingRec.rFieldProp_Options_Code_For_SV_File
        self.rFieldProp_Metadatas_Code_For_SV_File = existingRec.rFieldProp_Metadatas_Code_For_SV_File
        
        self.mFormFieldLocalesRecs_are_changed = false
        self.mFormFieldLocalesRecs = nil
    }

    // constructor creates the record from the results of a database query
    // throws upon missing required columns from the database (already error.logs them)
    init(row:Row) throws {
        do {
            self.rFormField_Index = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_INDEX)
            self.rOrg_Code_For_SV_File = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            self.rForm_Code_For_SV_File = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
            self.rFormField_Order_Shown = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_ORDER_SHOWN)
            self.rFormField_Order_SV_File = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_ORDER_SV_FILE)
            self.rFieldProp_IDCode = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_IDCODE)
            self.rFieldProp_Col_Name_For_SV_File = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_COL_NAME_FOR_SV_FILE)
            self.rFieldProp_vCard_Property = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_VCARD_PROPERTY)
            self.rFieldProp_vCard_Subproperty_No = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_VCARD_SUBPROPERTY_NO)
            self.rFieldProp_vCard_Property_Subtype = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_VCARD_PROPERTY_SUBTYPE)
            self.rFieldProp_Flags = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_FLAGS)
            let value1:Int = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_ROW_TYPE)
            self.rFieldProp_Row_Type = FIELD_ROW_TYPE(rawValue:Int(exactly:value1)!)!
            self.rFormField_SubField_Within_FormField_Index = try row.get(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX)
        } catch {
            let appError = APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).init(Row)", domain: DatabaseHandler.ThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: RecOrgFormFieldDefs.TABLE_NAME)
            throw appError
        }
        
        // break comma-delimited String into an Array
        let value1:String? = row[Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_CONTAINS_FIELD_IDCODES)]
        if (value1 ?? "").isEmpty { self.rFieldProp_Contains_Field_IDCodes = nil }
        else { self.rFieldProp_Contains_Field_IDCodes = value1!.components(separatedBy:",") }
        let value2:String? = row[Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE)]
        if (value2 ?? "").isEmpty { self.rFieldProp_Options_Code_For_SV_File = nil }
        else { self.rFieldProp_Options_Code_For_SV_File = FieldAttributes(duos: value2!.components(separatedBy:",")) }
        let value3:String? = row[Expression<String?>(RecOrgFormFieldDefs.COLUMN_FIELDPROP_METADATAS_CODE_FOR_SV_FILE)]
        if (value3 ?? "").isEmpty { self.rFieldProp_Metadatas_Code_For_SV_File = nil }
        else { self.rFieldProp_Metadatas_Code_For_SV_File = FieldAttributes(duos: value3!.components(separatedBy:",")) }
    }
    
    // indicates whether this record is for metadata or entry data
    public func isMetaData() -> Bool {
        if rFieldProp_Flags == nil { return false }
        if rFieldProp_Flags!.contains("M") { return true }
        return false
    }
    
    // create an array of setters usable for database Insert or Update; will return nil if the record is incomplete and therefore not eligible to be stored
    // use 'exceptKey' for Update operations to ensure the key fields cannot be changed
    public func buildSetters(exceptKey:Bool=false) throws -> [Setter] {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rForm_Code_For_SV_File.isEmpty || self.rFieldProp_IDCode.isEmpty || self.rFieldProp_Col_Name_For_SV_File.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).buildSetters", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        
        var retArray = [Setter]()
        
        if !exceptKey {
            // auto-assigned upon Insert
            if self.rFormField_Index >= 0 { retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_INDEX <- self.rFormField_Index) }
        }
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE <- self.rOrg_Code_For_SV_File)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE <- self.rForm_Code_For_SV_File)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_ORDER_SHOWN <- self.rFormField_Order_Shown)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_ORDER_SV_FILE <- self.rFormField_Order_SV_File)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_IDCODE <- self.rFieldProp_IDCode)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_COL_NAME_FOR_SV_FILE <- self.rFieldProp_Col_Name_For_SV_File)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_ROW_TYPE <- self.rFieldProp_Row_Type.rawValue)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_VCARD_PROPERTY <- self.rFieldProp_vCard_Property)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_VCARD_PROPERTY_SUBTYPE <- self.rFieldProp_vCard_Property_Subtype)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_VCARD_SUBPROPERTY_NO <- self.rFieldProp_vCard_Subproperty_No)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_FLAGS <- self.rFieldProp_Flags)
        retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX <- self.rFormField_SubField_Within_FormField_Index)
        
        // break comma-delimited String into an Array
        if self.rFieldProp_Contains_Field_IDCodes == nil {
            retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_CONTAINS_FIELD_IDCODES <- nil)
        } else {
            retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_CONTAINS_FIELD_IDCODES <- self.rFieldProp_Contains_Field_IDCodes!.joined(separator:","))
        }
        if self.rFieldProp_Options_Code_For_SV_File == nil {
            retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE <- nil)
        } else {
            retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE <- self.rFieldProp_Options_Code_For_SV_File!.pack())
        }
        if self.rFieldProp_Metadatas_Code_For_SV_File == nil {
            retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_METADATAS_CODE_FOR_SV_FILE <- nil)
        } else {
            retArray.append(RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_METADATAS_CODE_FOR_SV_FILE <- self.rFieldProp_Metadatas_Code_For_SV_File!.pack())
        }

        return retArray
    }
    
    // build the JSON values; will return null if the record is incomplete and therefore not eligible to be sent;
    // since the recipient may be 32-bit, send all Int64 as strings
    public func buildJSONObject() -> NSMutableDictionary? {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rForm_Code_For_SV_File.isEmpty || self.rFieldProp_IDCode.isEmpty || self.rFieldProp_Col_Name_For_SV_File.isEmpty { return nil }
        
        let jsonObj:NSMutableDictionary = NSMutableDictionary()
        jsonObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_INDEX] = String(self.rFormField_Index)
        jsonObj[RecOrgFormFieldDefs.COLUMN_ORG_CODE_FOR_SV_FILE] = self.rOrg_Code_For_SV_File
        jsonObj[RecOrgFormFieldDefs.COLUMN_FORM_CODE_FOR_SV_FILE] = self.rForm_Code_For_SV_File
        jsonObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_ORDER_SHOWN] = self.rFormField_Order_Shown
        jsonObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_ORDER_SV_FILE] = self.rFormField_Order_SV_File
        jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_IDCODE] = self.rFieldProp_IDCode
        jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_COL_NAME_FOR_SV_FILE] = self.rFieldProp_Col_Name_For_SV_File
        jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_ROW_TYPE] = FIELD_ROW_TYPE.getFieldRowTypeString(fromType: self.rFieldProp_Row_Type)
        jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO] = self.rFieldProp_vCard_Subproperty_No
        jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_PROPERTY_SUBTYPE] = self.rFieldProp_vCard_Property_Subtype
        jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_FLAGS] = self.rFieldProp_Flags

        if self.rFieldProp_vCard_Property == nil { jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_CONTAINS_FIELD_IDCODES] = nil }
        else { jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_CONTAINS_FIELD_IDCODES] = String(self.rFieldProp_vCard_Property!) }
        if self.rFormField_SubField_Within_FormField_Index == nil { jsonObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX] = nil }
        else { jsonObj[RecOrgFormFieldDefs.COLUMN_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX] = String(self.rFormField_SubField_Within_FormField_Index!) }
        
        // break comma-delimited String into an Array
        if self.rFieldProp_Contains_Field_IDCodes == nil { jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_CONTAINS_FIELD_IDCODES] = nil }
        else { jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_CONTAINS_FIELD_IDCODES] = self.rFieldProp_Contains_Field_IDCodes!.joined(separator:",") }
        if self.rFieldProp_Options_Code_For_SV_File == nil { jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE] = nil }
        else { jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_OPTIONS_CODE_FOR_SV_FILE] = self.rFieldProp_Options_Code_For_SV_File!.pack() }
        if self.rFieldProp_Metadatas_Code_For_SV_File == nil { jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_METADATAS_CODE_FOR_SV_FILE] = nil }
        else { jsonObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_METADATAS_CODE_FOR_SV_FILE] = self.rFieldProp_Metadatas_Code_For_SV_File!.pack() }
        
        return jsonObj
    }

    /////////////////////////////////////////////////////////////////////////
    // Database interaction methods used throughout the application
    /////////////////////////////////////////////////////////////////////////
    
    // return the quantity of FormField records
    // throws exceptions either for local errors or from the database
    public static func orgFormFieldGetQtyRecs(forOrgShortName:String, forFormShortName:String) throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).orgFormFieldGetQtyRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let whereClause:String = "(\"\(RecOrgFormFieldDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)\" = \"\(forOrgShortName)\" AND \"\(RecOrgFormFieldDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)\" = \"\(forFormShortName)\")"
        return try AppDelegate.mDatabaseHandler!.genericQueryQty(method:"\(self.mCTAG).orgFormFieldGetQtyRecs", table:Table(RecOrgFormFieldDefs.TABLE_NAME), whereStr:whereClause, valuesBindArray:nil)
    }
    
    // get all FormField records (which could be none); sorted in numeric order of the SortOrder
    // throws exceptions either for local errors or from the database
    public static func orgFormFieldGetAllRecs(forOrgShortName:String, forFormShortName:String?, sortedBySVFileOrder:Bool) throws -> AnySequence<Row> {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).orgFormFieldGetAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        var methodDetails = "orgFormFieldGetAllRecs.forOrgShortName"
        var query = Table(RecOrgFormFieldDefs.TABLE_NAME)
        if !((forFormShortName ?? "").isEmpty) {
            methodDetails = methodDetails + ".OF"
            query = query.select(*).filter(RecOrgFormFieldDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName && RecOrgFormFieldDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == forFormShortName!)
        } else {
            methodDetails = methodDetails + ".O*"
            query = query.select(*).filter(RecOrgFormFieldDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName)
        }
        if sortedBySVFileOrder {
            methodDetails = methodDetails + "SV"
            query = query.order(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_ORDER_SV_FILE.asc)
        } else {
            methodDetails = methodDetails + "SH"
            query = query.order(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_ORDER_SHOWN.asc)
        }
        return try AppDelegate.mDatabaseHandler!.genericQuery(method:"\(self.mCTAG).\(methodDetails)", tableQuery:query)
    }
    
    // get all FormField records (which could be none) that are linked to their primary container form; unsorted
    // throws exceptions either for local errors or from the database
    public static func orgFormFieldGetAllRecs(withSubfieldIndex:Int64) throws -> AnySequence<Row> {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).orgFormFieldGetAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrgFormFieldDefs.TABLE_NAME).select(*).filter(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_SUBFIELD_WITHIN_FORMFIELD_INDEX == withSubfieldIndex)
        return try AppDelegate.mDatabaseHandler!.genericQuery(method:"\(self.mCTAG).orgFormFieldGetAllRecs.withSubfieldIndex", tableQuery:query)
    }
    
    // get one specific FormField record by field_idcode
    // throws exceptions either for local errors or from the database
    // null indicates the record was not found
    /*public static func orgFormFieldGetSpecifiedRecOfIDCode(fieldIDCode:String, forOrgShortName:String, forFormShortName:String) throws -> RecOrgFormFieldDefs? {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
        }
        let query = Table(RecOrgFormFieldDefs.TABLE_NAME).select(*).filter(RecOrgFormFieldDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName && RecOrgFormFieldDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == forFormShortName && RecOrgFormFieldDefs.COL_EXPRESSION_FIELDPROP_IDCODE == fieldIDCode)
        let record = try AppDelegate.mDatabaseHandler!.genericQueryOne(method:"\(self.mCTAG).orgFormFieldGetSpecifiedRecOfIDCode", tableQuery:query)
        if record == nil { return nil }
        return RecOrgFormFieldDefs(row:record!)
    }*/
    
    // add a FormField entry; return is the RowID of the newrecord (negative will not be returned);
    // WARNING: if the key fields have been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveNewToDB() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).saveNewToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormFieldDefs.mCTAG).saveNewToDB")
            throw appError
        } catch { throw error}
        
        let rowID = try AppDelegate.mDatabaseHandler!.insertRec(method:"\(RecOrgFormFieldDefs.mCTAG).saveNewToDB", table:Table(RecOrgFormFieldDefs.TABLE_NAME), cv:setters, orReplace:false, noAlert:false)
        self.rFormField_Index = rowID
        if self.mFormFieldLocalesRecs_are_changed { try self.addLocaleRecs() }
        return rowID
    }
    
    // replace a FormField entry; return is the quantity of replaced records (negative will not be returned);
    // WARNING: if the key fields have been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveChangesToDB(originalRec:RecOrgFormFieldDefs) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).saveChangesToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormFieldDefs.mCTAG).saveChangesToDB")
            throw appError
        } catch { throw error}
        
        let query = Table(RecOrgFormFieldDefs.TABLE_NAME).select(*).filter(RecOrgFormFieldDefs.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == originalRec.rOrg_Code_For_SV_File && RecOrgFormFieldDefs.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == originalRec.rForm_Code_For_SV_File && RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_INDEX == originalRec.rFormField_Index)
        let qty = try AppDelegate.mDatabaseHandler!.updateRec(method:"\(RecOrgFormFieldDefs.mCTAG).saveChangesToDB", tableQuery:query, cv:setters)
        if self.mFormFieldLocalesRecs_are_changed { try self.updateLocaleRecs() }
        return qty
    }
    
    // delete the FormField record; return is the count of records deleted (negative will not be returned;
    // note: this will also delete all the FormField's linked RecFieldLocales
    // throws exceptions either for local errors or from the database
    public func deleteFromDB() throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).deleteFromDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrgFormFieldDefs.TABLE_NAME).select(*).filter(RecOrgFormFieldDefs.COL_EXPRESSION_FORMFIELD_INDEX == self.rFormField_Index)
        let qty = try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(RecOrgFormFieldDefs.mCTAG).deleteFromDB", tableQuery:query)
        
        // need to also delete any and all RecFieldLocales that are specific to this FormField record
        // and if this is a container form field, delete any sub-fields linked to it
        do {
            _ = try RecOrgFormFieldLocales.formFieldLocalesDeleteAllRecWithFormFieldIndex(index: self.rFormField_Index)
            _ = try RecOrgFormFieldDefs.orgFormFieldDeleteAllRecsWithSubfieldIndex(index: self.rFormField_Index)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormFieldDefs.mCTAG).deleteFromDB")
            throw appError
        } catch { throw error }
        
        return qty
    }
    
    // delete the FormField record; return is the count of records deleted (negative will not be returned;
    // note: this will also delete all the FormField's linked RecFieldLocales
    // throws exceptions either for local errors or from the database
    public static func orgFormFieldDeleteAllRecsWithSubfieldIndex(index:Int64) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).orgFormFieldDeleteAllRecsWithSubfieldIndex", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        // need to do a loop and delete each one individually since the deleteFromDB
        // also handles referential integrity of subfields and RecOrgFormFieldLocales
        var qty:Int = 0
        let rows:AnySequence<Row> = try RecOrgFormFieldDefs.orgFormFieldGetAllRecs(withSubfieldIndex: index)
        for row in rows {
            let formFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(row:row)
            let q = try formFieldRec.deleteFromDB()
            qty = qty + q
        }
        return qty
    }
    
    // delete all necessary FormField records when a Form or an Org is deleted; return is the count of records deleted (negative will not be returned;
    // forFormShortName can be nil to delete all formfields in all forms for an Organization
    // note: this will also delete all the required RecOrgFormFieldLocales
    // throws exceptions either for local errors or from the database
    public static func orgFormFieldDeleteAllRecs(forOrgShortName:String, forFormShortName:String?) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldDefs.mCTAG).orgFormFieldDeleteAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        // need to do a loop and delete each one individually since the deleteFromDB
        // also handles referential integrity of subfields and RecOrgFormFieldLocales
        var qty:Int = 0
        let rows:AnySequence<Row> = try RecOrgFormFieldDefs.orgFormFieldGetAllRecs(forOrgShortName: forOrgShortName, forFormShortName: forFormShortName, sortedBySVFileOrder: false)
        for row in rows {
            let formFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(row:row)
            let q = try formFieldRec.deleteFromDB()
            qty = qty + q
        }
        return qty
    }
    
    // add/update all stored RecOrgFormFieldLocales records
    private func addLocaleRecs() throws {
        try updateLocaleRecs()
    }
    
    // add/update all stored RecOrgFormFieldLocales records
    private func updateLocaleRecs() throws {
        if self.mFormFieldLocalesRecs != nil {
            for formFieldLocalesRec in self.mFormFieldLocalesRecs! {
                formFieldLocalesRec.rFormField_Index = self.rFormField_Index   // force link the locale records
                formFieldLocalesRec.rForm_Code_For_SV_File = self.rForm_Code_For_SV_File    // these might not have been pre-set during Editing
                formFieldLocalesRec.rOrg_Code_For_SV_File = self.rOrg_Code_For_SV_File
                _ = try formFieldLocalesRec.saveNewToDB(ignoreDups:true)
            }
        }
        self.mFormFieldLocalesRecs_are_changed = false
    }
}
