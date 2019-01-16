//
//  RecJsonFieldLocales.swift
//  eContact Collect
//
//  Created by Yo on 10/25/18.
//

import Foundation

public class RecJsonFieldLocales {
    // record members
    public var rField_IDCode:String?                        // Field's unique ID Code string
    public var rFieldLocProp_Name_For_Collector:String?     // shown text table for the field
    public var rFieldLocProp_Col_Name_For_SV_File:String?   // short column name for the field in the SV file
    public var rFieldLocProp_Name_Shown:String?             // shown text label for the field
    public var rFieldLocProp_Placeholder_Shown:String?      // shown text placeholder for the field (for text field's only)
    public var rFieldLocProp_Option_Trios:[String]?         // comma-separated array of option colon-separated trios
    public var rFieldLocProp_Metadata_Trios:[String]?       // comma-separated array of metadata colon-separated trios
    
    // class members
    public var mFormFieldLoc_LangRegionCode:String?         // langRegion code
    
    // member constants and other static content
    public static let COLUMN_FIELDLOCPROP_ATTRIBS = "fieldlocprop_options"
    public static let COLUMN_FIELDLOCPROP_METADATAS = "fieldlocprop_metadatas"
    
    // constructor creates the record from a json entry
    init(jsonRecObj:NSDictionary, forDBversion:String) {
        if forDBversion == "1" {
            let value1 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_IDCODE] as? String
            if (value1 ?? "").isEmpty { self.rField_IDCode = nil }
            else { self.rField_IDCode = value1 }
            let value2 = jsonRecObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_FOR_COLLECTOR] as? String
            if (value2 ?? "").isEmpty { self.rFieldLocProp_Name_For_Collector = nil }
            else { self.rFieldLocProp_Name_For_Collector = value2 }
            let value3 = jsonRecObj[RecOrgFormFieldDefs.COLUMN_FIELDPROP_COL_NAME_FOR_SV_FILE] as? String
            if (value3 ?? "").isEmpty { self.rFieldLocProp_Col_Name_For_SV_File = nil }
            else { self.rFieldLocProp_Col_Name_For_SV_File = value3 }
            let value4 = jsonRecObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_SHOWN] as? String
            if (value4 ?? "").isEmpty { self.rFieldLocProp_Name_Shown = nil }
            else { self.rFieldLocProp_Name_Shown = value4 }
            let value5 = jsonRecObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_PLACEHOLDER_SHOWN] as? String
            if (value5 ?? "").isEmpty { self.rFieldLocProp_Placeholder_Shown = nil }
            else { self.rFieldLocProp_Placeholder_Shown = value5 }
            
            // break comma-delimited String into an Array
            let value6:String? = jsonRecObj[RecJsonFieldLocales.COLUMN_FIELDLOCPROP_ATTRIBS] as? String
            if value6 != nil { self.rFieldLocProp_Option_Trios = value6!.components(separatedBy:",") }
            else { self.rFieldLocProp_Option_Trios = nil }
            let value7:String? = jsonRecObj[RecJsonFieldLocales.COLUMN_FIELDLOCPROP_METADATAS] as? String
            if value7 != nil { self.rFieldLocProp_Metadata_Trios = value7!.components(separatedBy:",") }
            else { self.rFieldLocProp_Metadata_Trios = nil }
        }
    }
}
