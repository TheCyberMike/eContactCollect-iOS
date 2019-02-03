//
//  RecOrgFormFieldLocales.swift
//  eContact Collect
//
//  Created by Yo on 10/25/18.
//

import SQLite

// a composed varient of the baseline RecOrgFormFieldLocales; cannot be saved in the database nor transferred via JSON
public class RecOrgFormFieldLocales_Composed {
    // record members
    public var rFormFieldLoc_Index:Int64? = -1
    public var rOrg_Code_For_SV_File:String?
    public var rForm_Code_For_SV_File:String?
    public var rFormField_Index:Int64?
    public var rFormFieldLoc_LangRegionCode:String?
    // Locale 1: this field is in the SV-File language which is assumed to be the Collector's language
    public var rFieldLocProp_Name_For_Collector:String?
    
    // Locale 2: these fields are in the End-user Shown language
    public var rFieldLocProp_Name_Shown:String?
    public var rFieldLocProp_Placeholder_Shown:String?
    public var rFieldLocProp_Options_Name_Shown:FieldAttributes?
    public var rFieldLocProp_Metadatas_Name_Shown:FieldAttributes?
    
    // member variables
    // Locale 3: 2nd bilingual shown to end-user
    public var mFieldLocProp_Name_Shown_Bilingual_2nd:String?                       // 2nd bilingual shown text label for the field
    public var mFieldLocProp_Options_Name_Shown_Bilingual_2nd:FieldAttributes?      // 2nd bilingual option attributes or selected FRTs
    public var mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd:FieldAttributes?    // 2nd bilingual metadata attributes for selected FRTs
    
    public var mLocale1LangRegion:String? = nil
    public var mLocale2LangRegion:String? = nil
    public var mLocale3LangRegion:String? = nil
    
    // default constructor
    init () {}
    
    // constructor creates a duplicate instance of the record
    init(existingRec:RecOrgFormFieldLocales_Composed) {
        self.rFormFieldLoc_Index = existingRec.rFormFieldLoc_Index
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File
        self.rFormField_Index = existingRec.rFormField_Index
        self.rFormFieldLoc_LangRegionCode = existingRec.rFormFieldLoc_LangRegionCode
        
        self.rFieldLocProp_Name_For_Collector = existingRec.rFieldLocProp_Name_For_Collector
        self.rFieldLocProp_Name_Shown = existingRec.rFieldLocProp_Name_Shown
        self.rFieldLocProp_Placeholder_Shown = existingRec.rFieldLocProp_Placeholder_Shown
        self.rFieldLocProp_Options_Name_Shown = existingRec.rFieldLocProp_Options_Name_Shown
        self.rFieldLocProp_Metadatas_Name_Shown = existingRec.rFieldLocProp_Metadatas_Name_Shown
        
        self.mFieldLocProp_Name_Shown_Bilingual_2nd = existingRec.mFieldLocProp_Name_Shown_Bilingual_2nd
        self.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = existingRec.mFieldLocProp_Options_Name_Shown_Bilingual_2nd
        self.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd = existingRec.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd
        self.mLocale1LangRegion = existingRec.mLocale1LangRegion
        self.mLocale2LangRegion = existingRec.mLocale2LangRegion
        self.mLocale3LangRegion = existingRec.mLocale3LangRegion
    }
    
    // constructor creates an instance of the record from a RecOrgFormFieldLocales
    init(existingRec:RecOrgFormFieldLocales) {
        self.rFormFieldLoc_Index = existingRec.rFormFieldLoc_Index
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File
        self.rFormField_Index = existingRec.rFormField_Index
        self.rFormFieldLoc_LangRegionCode = existingRec.rFormFieldLoc_LangRegionCode
        
        self.rFieldLocProp_Name_For_Collector = existingRec.rFieldLocProp_Name_For_Collector
        self.rFieldLocProp_Name_Shown = existingRec.rFieldLocProp_Name_Shown
        self.rFieldLocProp_Placeholder_Shown = existingRec.rFieldLocProp_Placeholder_Shown
        self.rFieldLocProp_Options_Name_Shown = existingRec.rFieldLocProp_Options_Name_Shown
        self.rFieldLocProp_Metadatas_Name_Shown = existingRec.rFieldLocProp_Metadatas_Name_Shown
        
        self.mFieldLocProp_Name_Shown_Bilingual_2nd = nil
        self.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = nil
        self.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd = nil
        self.mLocale1LangRegion = existingRec.rFormFieldLoc_LangRegionCode
        self.mLocale2LangRegion = existingRec.rFormFieldLoc_LangRegionCode
        self.mLocale3LangRegion = existingRec.rFormFieldLoc_LangRegionCode
    }
    
    // constructor creates an instance record from a JSON record and partner FormFieldDefs record
    init(jsonRec:RecJsonFieldLocales, forFormFieldRec:RecOrgFormFieldDefs) {
        self.rFormFieldLoc_Index = -1
        self.rOrg_Code_For_SV_File = forFormFieldRec.rOrg_Code_For_SV_File
        self.rForm_Code_For_SV_File = forFormFieldRec.rForm_Code_For_SV_File
        self.rFormField_Index = forFormFieldRec.rFormField_Index
        self.rFormFieldLoc_LangRegionCode = jsonRec.mFormFieldLoc_LangRegionCode
        self.rFieldLocProp_Name_For_Collector = jsonRec.rFieldLocProp_Name_For_Collector
        self.rFieldLocProp_Name_Shown = jsonRec.rFieldLocProp_Name_Shown
        self.rFieldLocProp_Placeholder_Shown = jsonRec.rFieldLocProp_Placeholder_Shown
        
        self.mFieldLocProp_Name_Shown_Bilingual_2nd = nil
        self.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = nil
        self.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd = nil
        self.mLocale1LangRegion = jsonRec.mFormFieldLoc_LangRegionCode
        self.mLocale2LangRegion = jsonRec.mFormFieldLoc_LangRegionCode
        self.mLocale3LangRegion = jsonRec.mFormFieldLoc_LangRegionCode
        
        // break up the attribute sets; they could be singletons, pairs, or trios
        // break up the attribute sets; they could be singletons, pairs, or trios
        if (jsonRec.rFieldLocProp_Option_Trios?.count ?? 0) > 0 {
            self.rFieldLocProp_Options_Name_Shown = FieldAttributes()
            for setString in jsonRec.rFieldLocProp_Option_Trios! {
                // format can be one of: tag:SV:shown or SV:shown or SV&Shown or
                //                       tag:[SVitem;SVitem;...]:[ShowItem;ShowItem;...] which is only used for Pronouns
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count == 1 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[0])
                } else if setComponents.count == 2 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else if setComponents.count >= 3 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[2])
                }
            }
        }
        
        // break up the metadata sets; they could be singletons, pairs, or trios
        if (jsonRec.rFieldLocProp_Metadata_Trios?.count ?? 0) > 0 {
            self.rFieldLocProp_Metadatas_Name_Shown = FieldAttributes()
            for setString in jsonRec.rFieldLocProp_Metadata_Trios! {
                // format can be one of: tag:SV:shown or SV:shown or SV&Shown
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count == 1 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[0])
                } else if setComponents.count == 2 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else if setComponents.count >= 3 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[2])
                }
            }
        }
    }
}

// special-use version of the record that is all optional; used for importing JSON records and
// specialized database queries if not every field will to be loaded; this record cannot be saved to the database
public class RecOrgFormFieldLocales_Optionals {
    // record members
    public var rFormFieldLoc_Index:Int64? = -1
    public var rOrg_Code_For_SV_File:String?
    public var rForm_Code_For_SV_File:String?
    public var rFormField_Index:Int64?
    public var rFormFieldLoc_LangRegionCode:String?
    public var rFieldLocProp_Name_For_Collector:String?
    public var rFieldLocProp_Name_Shown:String?
    public var rFieldLocProp_Placeholder_Shown:String?
    public var rFieldLocProp_Options_Name_Shown:FieldAttributes?
    public var rFieldLocProp_Metadatas_Name_Shown:FieldAttributes?
    
    // constructor creates the record from the results of a database query; is tolerant of missing columns
    init(row:Row) {
        // note: do NOT use the COL_EXPRESSION_* above since these are all set as optional in case the original query did not select all columns
        self.rFormFieldLoc_Index = row[Expression<Int64?>(RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_INDEX)]
        self.rFormField_Index = row[Expression<Int64?>(RecOrgFormFieldLocales.COLUMN_FORMFIELD_INDEX)]
        self.rFormFieldLoc_LangRegionCode = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_LANGREGIONCODE)]
        self.rOrg_Code_For_SV_File = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_ORG_CODE_FOR_SV_FILE)]
        self.rForm_Code_For_SV_File = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FORM_CODE_FOR_SV_FILE)]
        
        self.rFieldLocProp_Name_For_Collector = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_FOR_COLLECTOR)]
        self.rFieldLocProp_Name_Shown = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_SHOWN)]
        self.rFieldLocProp_Placeholder_Shown = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_PLACEHOLDER_SHOWN)]
        
        // break comma-delimited String into an Array
        let value1:String? = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN)]
        if (value1 ?? "").isEmpty { self.rFieldLocProp_Options_Name_Shown = nil }
        else { self.rFieldLocProp_Options_Name_Shown = FieldAttributes(duos: value1!.components(separatedBy:",")) }
        let value2:String? = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_METADATAS_NAME_SHOWN)]
        if (value2 ?? "").isEmpty { self.rFieldLocProp_Metadatas_Name_Shown = nil }
        else { self.rFieldLocProp_Metadatas_Name_Shown = FieldAttributes(duos: value2!.components(separatedBy:",")) }
    }
    
    // constructor creates the record from a JSON record
    init(jsonRec:RecJsonFieldLocales, forFormFieldRec:RecOrgFormFieldDefs, withJsonFormFieldRec:RecJsonFieldDefs) {
        self.rFormFieldLoc_Index = -1
        self.rOrg_Code_For_SV_File = forFormFieldRec.rOrg_Code_For_SV_File
        self.rForm_Code_For_SV_File = forFormFieldRec.rForm_Code_For_SV_File
        self.rFormField_Index = forFormFieldRec.rFormField_Index
        self.rFormFieldLoc_LangRegionCode = jsonRec.mFormFieldLoc_LangRegionCode
        self.rFieldLocProp_Name_For_Collector = jsonRec.rFieldLocProp_Name_For_Collector
        self.rFieldLocProp_Name_Shown = jsonRec.rFieldLocProp_Name_Shown
        self.rFieldLocProp_Placeholder_Shown = jsonRec.rFieldLocProp_Placeholder_Shown
        
        // break up the attribute sets; they could be singletons, pairs, or trios
        if (jsonRec.rFieldLocProp_Option_Trios?.count ?? 0) > 0 {
            self.rFieldLocProp_Options_Name_Shown = FieldAttributes()
            for setString in jsonRec.rFieldLocProp_Option_Trios! {
                // format can be one of: tag:SV:shown or SV:shown or SV&Shown or
                //                       tag:[SVitem;SVitem;...]:[ShowItem;ShowItem;...] which is only used for Pronouns
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count == 1 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[0])
                } else if setComponents.count == 2 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else if setComponents.count >= 3 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[2])
                }
            }
        } else if (withJsonFormFieldRec.rFieldProp_Option_Tags?.count ?? 0) > 0 {
            self.rFieldLocProp_Options_Name_Shown = FieldAttributes()
            for setString in withJsonFormFieldRec.rFieldProp_Option_Tags! {
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count == 1 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[0])
                } else if setComponents.count == 2 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else if setComponents.count >= 3 {
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[2])
                }
            }
        }
        
        // break up the metadata sets; they could be singletons, pairs, or trios
        if (jsonRec.rFieldLocProp_Metadata_Trios?.count ?? 0) > 0 {
            self.rFieldLocProp_Metadatas_Name_Shown = FieldAttributes()
            for setString in jsonRec.rFieldLocProp_Metadata_Trios! {
                // format can be one of: tag:SV:shown or SV:shown or SV&Shown
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count == 1 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[0])
                } else if setComponents.count == 2 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else if setComponents.count >= 3 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[2])
                }
            }
        } else if (withJsonFormFieldRec.rFieldProp_Metadata_Tags?.count ?? 0) > 0 {
            self.rFieldLocProp_Metadatas_Name_Shown = FieldAttributes()
            for setString in withJsonFormFieldRec.rFieldProp_Metadata_Tags! {
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count == 1 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[0])
                } else if setComponents.count == 2 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else if setComponents.count >= 3 {
                    self.rFieldLocProp_Metadatas_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[2])
                }
            }
        }
    }
    
    // constructor creates the record from a JSON object; is tolerant of missing columns;
    // must be tolerant that Int64's may be encoded as Strings, especially OIDs;
    // context is provided in case database version or language of the JSON file is important
    init(jsonObj:NSDictionary, context:DatabaseHandler.ValidateJSONdbFile_Result) {
        if let oidObj1 = jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_INDEX] {
            if oidObj1 is String {
                self.rFormFieldLoc_Index = Int64(jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_INDEX] as! String)
            } else if oidObj1 is NSNumber {
                self.rFormFieldLoc_Index = (jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_INDEX] as! NSNumber).int64Value
            } else {
                self.rFormFieldLoc_Index = nil
            }
        } else { self.rFormFieldLoc_Index = nil }
        if let oidObj2 = jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELD_INDEX] {
            if oidObj2 is String {
                self.rFormField_Index = Int64(jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELD_INDEX] as! String)
            } else if oidObj2 is NSNumber {
                self.rFormField_Index = (jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELD_INDEX] as! NSNumber).int64Value
            } else {
                self.rFormField_Index = nil
            }
        } else { self.rFormField_Index = nil }
        
        
        self.rOrg_Code_For_SV_File = jsonObj[RecOrgFormFieldLocales.COLUMN_ORG_CODE_FOR_SV_FILE] as? String
        self.rForm_Code_For_SV_File = jsonObj[RecOrgFormFieldLocales.COLUMN_FORM_CODE_FOR_SV_FILE] as? String
        self.rFormFieldLoc_LangRegionCode = jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_LANGREGIONCODE] as? String
        
        self.rFieldLocProp_Name_For_Collector = jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_FOR_COLLECTOR] as? String
        self.rFieldLocProp_Name_Shown = jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_SHOWN] as? String
        self.rFieldLocProp_Placeholder_Shown = jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_PLACEHOLDER_SHOWN] as? String
        
        // break comma-delimited String into an Array
        let value5:String? = jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN] as? String
        if value5 != nil { self.rFieldLocProp_Options_Name_Shown = FieldAttributes(duos: value5!.components(separatedBy:",")) }
        else { self.rFieldLocProp_Options_Name_Shown = nil }
        let value6:String? = jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_METADATAS_NAME_SHOWN] as? String
        if value6 != nil { self.rFieldLocProp_Metadatas_Name_Shown = FieldAttributes(duos: value6!.components(separatedBy:",")) }
        else { self.rFieldLocProp_Metadatas_Name_Shown = nil }
    }
    
    // is the optionals record valid in terms of required content?
    // FormShortName is allowed to be nil or blank since its usually filled in when records are saved to the database during Editing
    public func validate() -> Bool {
        if self.rFormFieldLoc_Index == nil || self.rFormField_Index == nil || self.rFormFieldLoc_LangRegionCode == nil || self.rOrg_Code_For_SV_File == nil || self.rFieldLocProp_Name_For_Collector == nil { return false }
        if self.rFormFieldLoc_LangRegionCode!.isEmpty || self.rOrg_Code_For_SV_File!.isEmpty || self.rFieldLocProp_Name_For_Collector!.isEmpty { return false }
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Main Record
/////////////////////////////////////////////////////////////////////////

// this is effectively a subtable for RecOrgFormFieldDefs with many-to-one relationship
public class RecOrgFormFieldLocales {
    // record members
    public var rFormFieldLoc_Index:Int64 = -1                       // Record's index#; needed for updating of composed records; primary key
    public var rOrg_Code_For_SV_File:String                         // org's short name
    public var rForm_Code_For_SV_File:String                        // form's short name
    public var rFormField_Index:Int64                               // FormField index#; alternate primary key
    public var rFormFieldLoc_LangRegionCode:String                  // ISO language-region code; alternate primary key
    public var rFieldLocProp_Name_For_Collector:String              // shown text table for the field
    public var rFieldLocProp_Name_Shown:String?                     // shown text label for the field
    public var rFieldLocProp_Placeholder_Shown:String?              // shown text placeholder for the field (for text fields only)
    public var rFieldLocProp_Options_Name_Shown:FieldAttributes?    // option attribute for selected FRTs: as-shown
    public var rFieldLocProp_Metadatas_Name_Shown:FieldAttributes?  // metadata attributes for selected FRTs: as-shown
    
    // member variables
    public var mDuringEditing_isDeleted:Bool = false                // during Editing, the record is marked as deleted

    // member constants and other static content
    private static let mCTAG:String = "ROFFL"
    public static let TABLE_NAME = "OrgFormFieldLocales"
    public static let COLUMN_FORMFIELDLOC_INDEX = "_id"
    public static let COLUMN_ORG_CODE_FOR_SV_FILE = "org_code_sv_file"
    public static let COLUMN_FORM_CODE_FOR_SV_FILE = "form_code_sv_file"
    public static let COLUMN_FORMFIELD_INDEX = "formfield_index"
    public static let COLUMN_FORMFIELDLOC_LANGREGIONCODE = "formfieldloc_langRegionCode"

    public static let COLUMN_FIELDLOCPROP_NAME_FOR_COLLECTOR = "fieldlocprop_name_for_collector"
    public static let COLUMN_FIELDLOCPROP_NAME_SHOWN = "fieldlocprop_name_shown"
    public static let COLUMN_FIELDLOCPROP_PLACEHOLDER_SHOWN = "fieldlocprop_placeholder_shown"
    public static let COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN = "fieldlocprop_options_shown"
    public static let COLUMN_FIELDLOCPROP_METADATAS_NAME_SHOWN = "fieldlocprop_metadatas_shown"
    
    // these are the as-stored in the database expression definitions
    public static let COL_EXPRESSION_FORMFIELDLOC_INDEX = Expression<Int64>(RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_INDEX)
    public static let COL_EXPRESSION_ORG_CODE_FOR_SV_FILE = Expression<String>(RecOrgFormFieldDefs.COLUMN_ORG_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FORM_CODE_FOR_SV_FILE = Expression<String>(RecOrgFormFieldDefs.COLUMN_FORM_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FORMFIELD_INDEX = Expression<Int64>(RecOrgFormFieldLocales.COLUMN_FORMFIELD_INDEX)
    public static let COL_EXPRESSION_FORMFIELDLOC_LANGREGIONCODE = Expression<String>(RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_LANGREGIONCODE)
    
    public static let COL_EXPRESSION_FIELDLOCPROP_NAME_FOR_COLLECTOR =
        Expression<String>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_FOR_COLLECTOR)
    public static let COL_EXPRESSION_FIELDLOCPROP_NAME_SHOWN =
        Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_SHOWN)
    public static let COL_EXPRESSION_FIELDLOCPROP_PLACEHOLDER_SHOWN =
        Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_PLACEHOLDER_SHOWN)
    public static let COL_EXPRESSION_FIELDLOCPROP_OPTIONS_NAME_SHOWN =
        Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN)
    public static let COL_EXPRESSION_FIELDLOCPROP_METADATAS_NAME_SHOWN =
        Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_METADATAS_NAME_SHOWN)
    
    // generate the string that will create the table
    public static func generateCreateTableString() -> String {
        return Table(TABLE_NAME).create(ifNotExists: true) { t in
            t.column(COL_EXPRESSION_FORMFIELDLOC_INDEX, primaryKey: .autoincrement)
            t.column(COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FORMFIELD_INDEX)
            t.column(COL_EXPRESSION_FORMFIELDLOC_LANGREGIONCODE)
            
            t.column(COL_EXPRESSION_FIELDLOCPROP_NAME_FOR_COLLECTOR)
            t.column(COL_EXPRESSION_FIELDLOCPROP_NAME_SHOWN)
            t.column(COL_EXPRESSION_FIELDLOCPROP_PLACEHOLDER_SHOWN)
            t.column(COL_EXPRESSION_FIELDLOCPROP_OPTIONS_NAME_SHOWN)
            t.column(COL_EXPRESSION_FIELDLOCPROP_METADATAS_NAME_SHOWN)
        }
    }
    
    // constructor creates an instance record with provided values
    init(formfieldloc_index:Int64, orgShortName:String, formShortName:String, formfield_index:Int64, langRegion:String, nameForCollector:String) {
        self.rFormFieldLoc_Index = formfieldloc_index
        self.rOrg_Code_For_SV_File = orgShortName
        self.rForm_Code_For_SV_File = formShortName
        self.rFormField_Index = formfield_index
        self.rFormFieldLoc_LangRegionCode = langRegion
        self.rFieldLocProp_Name_For_Collector = nameForCollector
    }
    
    // constructor creates a duplicate of an existing record
    init(existingRec:RecOrgFormFieldLocales) {
        self.rFormFieldLoc_Index = existingRec.rFormFieldLoc_Index
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File
        self.rFormField_Index = existingRec.rFormField_Index
        self.rFormFieldLoc_LangRegionCode = existingRec.rFormFieldLoc_LangRegionCode
        
        self.rFieldLocProp_Name_For_Collector = existingRec.rFieldLocProp_Name_For_Collector
        self.rFieldLocProp_Name_Shown = existingRec.rFieldLocProp_Name_Shown
        self.rFieldLocProp_Placeholder_Shown = existingRec.rFieldLocProp_Placeholder_Shown
        self.rFieldLocProp_Options_Name_Shown = existingRec.rFieldLocProp_Options_Name_Shown
        self.rFieldLocProp_Metadatas_Name_Shown = existingRec.rFieldLocProp_Metadatas_Name_Shown
    }
    
    // constructor imports an optionals record into a mainline record
    // throws upon missing required fields; caller is responsible to error.log;
    // FormShortName is allowed to be nil or blank since its filled in when records are saved to the database
    init(existingRec:RecOrgFormFieldLocales_Optionals) throws {
        if existingRec.rFormFieldLoc_Index == nil || existingRec.rFormField_Index == nil || existingRec.rFormFieldLoc_LangRegionCode == nil || existingRec.rOrg_Code_For_SV_File == nil || existingRec.rFieldLocProp_Name_For_Collector == nil {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).init(RecOrgFormFieldLocales_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required == nil")
        }
        if existingRec.rFormFieldLoc_LangRegionCode!.isEmpty || existingRec.rOrg_Code_For_SV_File!.isEmpty || existingRec.rFieldLocProp_Name_For_Collector!.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).init(RecOrgFormFieldLocales_Optionals)", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        self.rFormFieldLoc_Index = existingRec.rFormFieldLoc_Index!
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File!
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File ?? ""
        self.rFormField_Index = existingRec.rFormField_Index!
        self.rFormFieldLoc_LangRegionCode = existingRec.rFormFieldLoc_LangRegionCode!
        
        self.rFieldLocProp_Name_For_Collector = existingRec.rFieldLocProp_Name_For_Collector!
        self.rFieldLocProp_Name_Shown = existingRec.rFieldLocProp_Name_Shown
        self.rFieldLocProp_Placeholder_Shown = existingRec.rFieldLocProp_Placeholder_Shown
        self.rFieldLocProp_Options_Name_Shown = existingRec.rFieldLocProp_Options_Name_Shown
        self.rFieldLocProp_Metadatas_Name_Shown = existingRec.rFieldLocProp_Metadatas_Name_Shown
    }
    
    // constructor creates the record from the results of a database query
    // throws upon missing required columns from the database (already error.logs them)
    init(row:Row) throws {
        do {
            self.rFormFieldLoc_Index = try row.get(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELDLOC_INDEX)
            self.rOrg_Code_For_SV_File = try row.get(RecOrgFormFieldLocales.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            self.rForm_Code_For_SV_File = try row.get(RecOrgFormFieldLocales.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
            self.rFormField_Index = try row.get(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELD_INDEX)
            self.rFormFieldLoc_LangRegionCode = try row.get(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELDLOC_LANGREGIONCODE)
            
            self.rFieldLocProp_Name_For_Collector = try row.get(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_NAME_FOR_COLLECTOR)
            self.rFieldLocProp_Name_Shown = try row.get(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_NAME_SHOWN)
            self.rFieldLocProp_Placeholder_Shown = try row.get(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_PLACEHOLDER_SHOWN)
        } catch {
            let appError = APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).init(Row)", domain: DatabaseHandler.ThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: RecOrgFormFieldLocales.TABLE_NAME)
            throw appError
        }
        
        // break comma-delimited String into an Array
        let value1:String? = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN)]
        if (value1 ?? "").isEmpty { self.rFieldLocProp_Options_Name_Shown = nil }
        else { self.rFieldLocProp_Options_Name_Shown = FieldAttributes(duos: value1!.components(separatedBy:",")) }
        let value2:String? = row[Expression<String?>(RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_METADATAS_NAME_SHOWN)]
        if (value2 ?? "").isEmpty { self.rFieldLocProp_Metadatas_Name_Shown = nil }
        else { self.rFieldLocProp_Metadatas_Name_Shown = FieldAttributes(duos: value2!.components(separatedBy:",")) }
    }
        
    // create an array of setters usable for database Insert or Update; will return nil if the record is incomplete and therefore not eligible to be stored
    // use 'exceptKey' for Update operations to ensure the key fields cannot be changed
    public func buildSetters(exceptKey:Bool=false) throws -> [Setter] {
        if self.rFormFieldLoc_LangRegionCode.isEmpty || self.rOrg_Code_For_SV_File.isEmpty || self.rForm_Code_For_SV_File.isEmpty || self.rFieldLocProp_Name_For_Collector.isEmpty {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).buildSetters", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "Required .isEmpty")
        }
        
        var retArray = [Setter]()
        
        if !exceptKey {
            if self.rFormFieldLoc_Index >= 0 {
                retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELDLOC_INDEX <- self.rFormFieldLoc_Index)  // auto-assigned upon Insert
            }
        }
        retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE <- self.rOrg_Code_For_SV_File)
        retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE <- self.rForm_Code_For_SV_File)
        retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELD_INDEX <- self.rFormField_Index)
        retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELDLOC_LANGREGIONCODE <- self.rFormFieldLoc_LangRegionCode)
        
        retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_NAME_FOR_COLLECTOR <- self.rFieldLocProp_Name_For_Collector)
        retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_NAME_SHOWN <- self.rFieldLocProp_Name_Shown)
        retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_PLACEHOLDER_SHOWN <- self.rFieldLocProp_Placeholder_Shown)
        
        // place array components back into a comma separated array
        if self.rFieldLocProp_Options_Name_Shown == nil {
            retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_OPTIONS_NAME_SHOWN <- nil)
        } else {
            retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_OPTIONS_NAME_SHOWN <- self.rFieldLocProp_Options_Name_Shown!.pack())
        }
        if self.rFieldLocProp_Metadatas_Name_Shown == nil {
            retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_METADATAS_NAME_SHOWN <- nil)
        } else {
            retArray.append(RecOrgFormFieldLocales.COL_EXPRESSION_FIELDLOCPROP_METADATAS_NAME_SHOWN <- self.rFieldLocProp_Metadatas_Name_Shown!.pack())
        }
        return retArray
    }

    // build the JSON values; will return null if the record is incomplete and therefore not eligible to be sent;
    // since the recipient may be 32-bit, send all Int64 as strings
    public func buildJSONObject() -> NSMutableDictionary? {
        if self.rFormFieldLoc_LangRegionCode.isEmpty || self.rOrg_Code_For_SV_File.isEmpty || self.rForm_Code_For_SV_File.isEmpty || self.rFieldLocProp_Name_For_Collector.isEmpty{ return nil }
        
        let jsonObj:NSMutableDictionary = NSMutableDictionary()
        jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_INDEX] = String(self.rFormFieldLoc_Index)
        jsonObj[RecOrgFormFieldLocales.COLUMN_ORG_CODE_FOR_SV_FILE] = self.rOrg_Code_For_SV_File
        jsonObj[RecOrgFormFieldLocales.COLUMN_FORM_CODE_FOR_SV_FILE] = self.rForm_Code_For_SV_File
        jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELD_INDEX] = String(self.rFormField_Index)
        jsonObj[RecOrgFormFieldLocales.COLUMN_FORMFIELDLOC_LANGREGIONCODE] = self.rFormFieldLoc_LangRegionCode
        
        jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_FOR_COLLECTOR] = self.rFieldLocProp_Name_For_Collector
        jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_NAME_SHOWN] = self.rFieldLocProp_Name_Shown
        jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_PLACEHOLDER_SHOWN] = self.rFieldLocProp_Placeholder_Shown
        
        // place array components back into a comma separated array
        if self.rFieldLocProp_Options_Name_Shown == nil { jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN] = nil }
        else { jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN] = self.rFieldLocProp_Options_Name_Shown!.pack() }
        if self.rFieldLocProp_Metadatas_Name_Shown == nil { jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_METADATAS_NAME_SHOWN] = nil }
        else { jsonObj[RecOrgFormFieldLocales.COLUMN_FIELDLOCPROP_METADATAS_NAME_SHOWN] = self.rFieldLocProp_Metadatas_Name_Shown!.pack() }
        
        return jsonObj
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Database interaction methods used throughout the application
    /////////////////////////////////////////////////////////////////////////
    
    // return the quantity of Field records
    // throws exceptions either for local errors or from the database
    /*public static func fieldGetQtyRecs() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
        }
        return try AppDelegate.mDatabaseHandler!.genericQueryQty(method:"\(self.mCTAG).fieldGetQtyRecs", table:Table(RecFieldDefs.TABLE_NAME), whereStr:nil, valuesBindArray:nil)
    }*/
    
    // get all Field records (which could be none) for a field_IDCode which includes all languages and all overrides;
    // sorted in such that overrides are found before non-overrides and lang-region are found before lang
    // throws exceptions either for local errors or from the database
    public static func formFieldLocalesGetAllRecs(forOrgShortName:String, forFormShortName:String?) throws -> AnySequence<Row> {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).formFieldLocalesGetAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        var optionStr:String = ".O"
        var query = Table(RecOrgFormFieldLocales.TABLE_NAME)
        if !((forFormShortName ?? "").isEmpty) {
            optionStr = optionStr + "F"
            query = query.select(*).filter(RecOrgFormFieldLocales.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName && RecOrgFormFieldLocales.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == forFormShortName!)
        } else {
            query = query.select(*).filter(RecOrgFormFieldLocales.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName)
        }
        query = query.order(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELD_INDEX.asc, RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELDLOC_LANGREGIONCODE.asc)
        return try AppDelegate.mDatabaseHandler!.genericQuery(method:"\(self.mCTAG).formFieldLocalesGetAllRecs.\(optionStr)", tableQuery:query)
    }
    
    // get one specific Field record by IDCode
    // throws exceptions either for local errors or from the database
    // null indicates the record was not found
    public static func formFieldLocalesGetSpecifiedRecIndex(index:Int64) throws -> RecOrgFormFieldLocales? {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).formFieldLocalesGetSpecifiedRecIndex", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrgFormFieldLocales.TABLE_NAME).select(*).filter(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELDLOC_INDEX == index)
        let record = try AppDelegate.mDatabaseHandler!.genericQueryOne(method:"\(self.mCTAG).formFieldLocalesGetSpecifiedRecIndex", tableQuery:query)
        if record == nil { return nil }
        return try RecOrgFormFieldLocales(row:record!)
    }
    
    // add a FieldLocale entry; return is the RowID of the new record (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveNewToDB(ignoreDups:Bool=false) throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).saveNewToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        guard !self.mDuringEditing_isDeleted else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).saveNewToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_MARKED_DELETED, userErrorDetails: nil, developerInfo: RecOrganizationLangs.TABLE_NAME, noAlert: true)
        }
        
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormFieldLocales.mCTAG).saveNewToDB")
            throw appError
        } catch { throw error}
        
        let rowID = try AppDelegate.mDatabaseHandler!.insertRec(method:"\(RecOrgFormFieldLocales.mCTAG).saveNewToDB", table:Table(RecOrgFormFieldLocales.TABLE_NAME), cv:setters, orReplace:ignoreDups, noAlert:false)
        self.rFormFieldLoc_Index = rowID
        return rowID
    }
    
    // replace a FieldLocale entry; return is the quantity of the replaced records (negative will not be returned);
    // this method supports changing the original records if it is a composed record (but does not *create* RecOrgFormFieldDefs override records);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveChangesToDB(originalRec:RecOrgFormFieldLocales) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).saveChangesToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        guard !self.mDuringEditing_isDeleted else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).saveChangesToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_MARKED_DELETED, userErrorDetails: nil, developerInfo: RecOrganizationLangs.TABLE_NAME, noAlert: true)
        }
        
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecOrgFormFieldLocales.mCTAG).saveChangesToDB")
            throw appError
        } catch { throw error}
        
        let query = Table(RecOrgFormFieldLocales.TABLE_NAME).select(*).filter(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELDLOC_INDEX == self.rFormFieldLoc_Index)
        return try AppDelegate.mDatabaseHandler!.updateRec(method:"\(RecOrgFormFieldLocales.mCTAG).saveChangesToDB", tableQuery:query, cv:setters)
    }
    
    // delete the Field record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    /*public func deleteFromDB() throws -> Int {
        if self.rField_IDCode == nil {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_MISSING_REQUIRED_CONTENT, userInfo: nil)
        }
        return try RecFieldDefs.fieldDeleteRec(fieldIDCode:self.rField_IDCode!)
    }
    
    // delete the indicated Field record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public static func fieldDeleteRec(fieldIDCode:String) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
        }
        let query = Table(RecFieldDefs.TABLE_NAME).select(*).filter(RecFieldDefs.COL_EXPRESSION_FIELD_IDCODE == fieldIDCode)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).fieldDeleteRec", tableQuery:query)
    }*/
    
    // delete the indicated Field record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public static func formFieldLocalesDeleteAllRecWithFormFieldIndex(index:Int64) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).formFieldLocalesDeleteAllRecWithFormFieldIndex", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecOrgFormFieldLocales.TABLE_NAME).select(*).filter(RecOrgFormFieldLocales.COL_EXPRESSION_FORMFIELD_INDEX == index)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).fieldLocaleDeleteAllRecWithFormFieldIndex", tableQuery:query)
    }
    
    // delete all necessary FormField records when a Form or an Org is deleted; return is the count of records deleted (negative will not be returned;
    // forFormShortName can be nil to delete all formfields in all forms for an Organization
    // throws exceptions either for local errors or from the database
    public static func formFieldLocalesDeleteAllRecs(forOrgShortName:String, forFormShortName:String?) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecOrgFormFieldLocales.mCTAG).formFieldLocalesDeleteAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        var optionStr:String = ".O"
        var query = Table(RecOrgFormFieldLocales.TABLE_NAME)
        if !((forFormShortName ?? "").isEmpty) {
            optionStr = optionStr + "F"
            query = query.select(*).filter(RecOrgFormFieldLocales.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName && RecOrgFormFieldLocales.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == forFormShortName!)
        } else {
            query = query.select(*).filter(RecOrgFormFieldLocales.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName)
        }
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).formFieldLocalesDeleteAllRecs.\(optionStr)", tableQuery:query)
    }
}
