//
//  RecJsonOptionSetLocales.swift
//  eContact Collect
//
//  Created by Yo on 11/8/18.
//

import Foundation

public class RecJsonOptionSetLocales {
    // record members
    public var rOptionSetLoc_Code:String?               // Option Set's code; always starts with "OSLC_"
    public var rOptionSetLoc_Code_Extension:String?     // optional subset: example: the country-code for separate sets of state codes per country
    // field properties
    public var rFieldLocProp_Option_Sets:[String]?      // comma-separated array of colon-separated pairs or trios
    
    // class members
    public var mOptionSetLoc_LangRegionCode:String?  // langRegion code
    
    // constructor creates the record from a plist array entry
    init(jsonRecObj:NSDictionary, forDBversion:Int64) {
        if forDBversion == 1 && jsonRecObj.count <= 3 {
            self.rOptionSetLoc_Code = jsonRecObj[RecOptionSetLocales.COLUMN_OPTIONSETLOC_CODE] as? String
            let value1:String? = jsonRecObj[RecOptionSetLocales.COLUMN_OPTIONSETLOC_CODE_EXTENSION] as? String
            if (value1 ?? "").isEmpty { self.rOptionSetLoc_Code_Extension = "" }      // do not want this to be nil
            else { self.rOptionSetLoc_Code_Extension = value1 }
            
            // break comma-delimited String into an Array
            let value2:NSArray? = jsonRecObj["optionSetLoc_option_sets"] as? NSArray
            if (value2?.count ?? 0) == 0 { self.rFieldLocProp_Option_Sets = nil }
            else {
                self.rFieldLocProp_Option_Sets = []
                for setStringObj in value2! {
                    self.rFieldLocProp_Option_Sets!.append(setStringObj as! String)
                }
            }
        }
    }    
}

