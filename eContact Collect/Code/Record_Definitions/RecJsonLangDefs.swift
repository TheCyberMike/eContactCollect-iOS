//
//  RecJsonLangDefs.swift
//  eContact Collect
//
//  Created by Yo on 10/28/18.
//

import Foundation

public class RecJsonLangDefs {
    // record members
    public var rLang_Name_English:String?       // Language name in English
    public var rLang_Name_Speaker:String?       // Language name in the speaker's dialec
    public var rLang_Icon_PNG_Blob:Data?        // Language icon as PNG
    
    // class members
    public var mLang_LangRegionCode:String?     // langRegion code
    
    // constructor creates the record from a plist array entry
    init(jsonRecObj:NSDictionary, forDBversion:String) {
        if forDBversion == "1" && jsonRecObj.count <= 4 {
            self.rLang_Name_English = jsonRecObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_EN] as? String
            self.rLang_Name_Speaker = jsonRecObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_TITLE_SHOWN] as? String            
            self.rLang_Icon_PNG_Blob = jsonRecObj[RecOrganizationLangs.COLUMN_ORGLANG_LANG_IMAGE_SHOWN_PNG_BLOB] as? Data
        }
    }
}
