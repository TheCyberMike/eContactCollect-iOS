//
//  RecJsonFieldDefs.swift
//  eContact Collect
//
//  Created by Yo on 10/25/18.
//

import Foundation

public class RecJsonFieldDefs {
    // record members
    public var rField_Sort_Order:String?                            // Sort order as shown to the Collector during Form definition
    // field properties
    public var rFieldProp_IDCode:String?                            // Field's unique ID Code string
    public var rFieldProp_Row_Type:FIELD_ROW_TYPE?                  // FRT aka Field Row Type (see list above); the App's "handler" for each type of data
    public var rFieldProp_Flags:String?                             // field's flags
    public var rFieldProp_vCard_Property:String?                    // field's primary vCard code; nil if none
    public var rFieldProp_vCard_Subproperty_No:Int?                 // subfield within a vCard entry with multiple comma-delimited fields
    public var rFieldProp_vCard_Property_Subtype:String?            // qualifier within a vCard entry; usually a Type=
    public var rFieldProp_Allows_Field_IDCodes:[String]?            // defines the fields shown in a Container FRT
    public var rFieldProp_Initial_Field_IDCodes:[String]?           // defines the fields shown in a Container FRT
    public var rFieldProp_Option_Tags:[String]?                     // the list of expected Option tags
    public var rFieldProp_Metadata_Tags:[String]?                   // the list of expected Metadata tags

    // member variables
    public var mJsonFieldLocalesRecs:[RecJsonFieldLocales]? = nil   // convenience working storage of its related RecJsonFieldLocales
    
    // member constants and other static content
    public static let COLUMN_FIELDPROP_ALLOWS_FIELD_IDCODES = "fieldprop_allows_IDcodes"
    public static let COLUMN_FIELDPROP_INITIAL_FIELD_IDCODES = "fieldprop_initial_IDcodes"
    public static let COLUMN_FIELDPROP_OPTION_TAGS = "fieldprop_option_tags"
    public static let COLUMN_FIELDPROP_METADATA_TAGS = "fieldprop_metadata_tags"
    public static let COLUMN_FIELDPROP_SORT_ORDER = "field_sort_order"

    // constructor creates the record from a json entry
    init(jsonRecObj:NSDictionary, forDBversion:Int64) {
        if forDBversion == 1 {
            if let oidObj3 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO] {
                if oidObj3 is String {
                    self.rFieldProp_vCard_Subproperty_No = Int(jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO] as! String)
                } else if oidObj3 is NSNumber {
                    self.rFieldProp_vCard_Subproperty_No = (jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_SUBPROPERTY_NO] as! Int)
                } else {
                    self.rFieldProp_vCard_Subproperty_No = nil
                }
            } else { self.rFieldProp_vCard_Subproperty_No = nil }
            
            self.rField_Sort_Order = jsonRecObj[RecJsonFieldDefs.COLUMN_FIELDPROP_SORT_ORDER] as? String
            self.rFieldProp_IDCode = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_IDCODE] as? String
            
            let value1 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_ROW_TYPE] as? String
            if (value1 ?? "").isEmpty { self.rFieldProp_Row_Type = nil }
            else { self.rFieldProp_Row_Type = FIELD_ROW_TYPE.getFieldRowType(fromString: value1!) }
            let value2 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_FLAGS] as? String
            if (value2 ?? "").isEmpty { self.rFieldProp_Flags = nil }
            else { self.rFieldProp_Flags = value2 }

            let value3 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_PROPERTY] as? String
            if (value3 ?? "").isEmpty { self.rFieldProp_vCard_Property = nil }
            else { self.rFieldProp_vCard_Property = value3 }
            let value4 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_VCARD_PROPERTY_SUBTYPE] as? String
            if (value4 ?? "").isEmpty { self.rFieldProp_vCard_Property_Subtype = nil }
            else { self.rFieldProp_vCard_Property_Subtype = value4 }
            
            // break comma-delimited String into an Array
            let value5:String? = jsonRecObj[RecJsonFieldDefs.COLUMN_FIELDPROP_ALLOWS_FIELD_IDCODES] as? String
            if value5 != nil { self.rFieldProp_Allows_Field_IDCodes = value5!.components(separatedBy:",") }
            else { self.rFieldProp_Allows_Field_IDCodes = nil }
            let value6:String? = jsonRecObj[RecJsonFieldDefs.COLUMN_FIELDPROP_INITIAL_FIELD_IDCODES] as? String
            if value6 != nil { self.rFieldProp_Initial_Field_IDCodes = value6!.components(separatedBy:",") }
            else { self.rFieldProp_Initial_Field_IDCodes = nil }
            let value7:String? = jsonRecObj[RecJsonFieldDefs.COLUMN_FIELDPROP_OPTION_TAGS] as? String
            if value7 != nil { self.rFieldProp_Option_Tags = value7!.components(separatedBy:",") }
            else { self.rFieldProp_Option_Tags = nil }
            let value8:String? = jsonRecObj[RecJsonFieldDefs.COLUMN_FIELDPROP_METADATA_TAGS] as? String
            if value8 != nil { self.rFieldProp_Metadata_Tags = value8!.components(separatedBy:",") }
            else { self.rFieldProp_Metadata_Tags = nil }
        }
    }
    
    // indicates whether this record is for metadata or entry data
    public func isMetaData() -> Bool {
        if rFieldProp_Flags == nil { return false }
        if rFieldProp_Flags!.contains("M") { return true }
        return false
    }
    
    // indicates whether this record is for metadata or entry data
    public func isSectionHeader() -> Bool {
        if rFieldProp_Flags == nil { return false }
        if rFieldProp_Flags!.contains("S") { return true }
        return false
    }
}
