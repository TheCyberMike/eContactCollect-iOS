//
//  RecOptionSetLocales.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import SQLite

// a composed varient of the baseline RecOptionSetLocales; cannot be saved in the database nor transferred via JSON
public class RecOptionSetLocales_Composed {
    
    // record members
    public var rOptionSetLoc_Code:String?
    public var rOptionSetLoc_Code_Extension:String?
    public var rOptionSetLoc_LangRegionCode:String?
    // Locale 1: this field is in the SV-File language
    public var rFieldLocProp_Options_Code_For_SV_File:FieldAttributes?
    // Locale 2: this field is in the End-user Shown language
    public var rFieldLocProp_Options_Name_Shown:FieldAttributes?
    
    // member variables
    public var mLocale1LangRegion:String? = nil
    public var mLocale2LangRegion:String? = nil

    // constructor creates the record from a JSON record
    init(jsonRec:RecJsonOptionSetLocales) {
        self.rOptionSetLoc_Code = jsonRec.rOptionSetLoc_Code
        self.rOptionSetLoc_Code_Extension = jsonRec.rOptionSetLoc_Code_Extension
        self.rOptionSetLoc_LangRegionCode = jsonRec.mOptionSetLoc_LangRegionCode
        
        // break up the option attribute sets; they could be singletons, pairs, or trios
        if jsonRec.rFieldLocProp_Option_Sets != nil {
            self.rFieldLocProp_Options_Code_For_SV_File = FieldAttributes()
            self.rFieldLocProp_Options_Name_Shown = FieldAttributes()
            for setString in jsonRec.rFieldLocProp_Option_Sets! {
                // format can be one of: tag:SV:shown or SV:shown or SV&Shown
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count == 1 {
                    self.rFieldLocProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[0])
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[0])
                } else if setComponents.count == 2 {
                    self.rFieldLocProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[0])
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else if setComponents.count >= 3 {
                    self.rFieldLocProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[1])
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[2])
                }
            }
        }
        
        self.mLocale1LangRegion = jsonRec.mOptionSetLoc_LangRegionCode
        self.mLocale2LangRegion = jsonRec.mOptionSetLoc_LangRegionCode
    }
}

// special-use version of the record that is all optional; used for importing JSON records and
// specialized database queries if not every field will to be loaded; this record cannot be saved to the database
public class RecOptionSetLocales_Optionals {
    // record members
    public var rOptionSetLoc_Code:String?
    public var rOptionSetLoc_Code_Extension:String?
    public var rOptionSetLoc_LangRegionCode:String?
    public var rFieldLocProp_Options_Code_For_SV_File:FieldAttributes?
    public var rFieldLocProp_Options_Name_Shown:FieldAttributes?
    
    // constructor creates the record from a json record
    init(jsonRec:RecJsonOptionSetLocales) {
        self.rOptionSetLoc_Code = jsonRec.rOptionSetLoc_Code
        self.rOptionSetLoc_Code_Extension = jsonRec.rOptionSetLoc_Code_Extension
        self.rOptionSetLoc_LangRegionCode = jsonRec.mOptionSetLoc_LangRegionCode
        
        // break up the attribute sets; they could be singletons, pairs, or trios
        if jsonRec.rFieldLocProp_Option_Sets != nil {
            self.rFieldLocProp_Options_Code_For_SV_File = FieldAttributes()
            self.rFieldLocProp_Options_Name_Shown = FieldAttributes()
            for setString in jsonRec.rFieldLocProp_Option_Sets! {
                // format can be one of: tag:SV:shown or SV:shown or SV&Shown
                let setComponents = setString.components(separatedBy: ":")
                if setComponents.count == 1 {
                    self.rFieldLocProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[0])
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[0])
                } else if setComponents.count == 2 {
                    self.rFieldLocProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[0])
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[1])
                } else if setComponents.count >= 3 {
                    self.rFieldLocProp_Options_Code_For_SV_File!.append(codeString: setComponents[0], valueString: setComponents[1])
                    self.rFieldLocProp_Options_Name_Shown!.append(codeString: setComponents[0], valueString: setComponents[2])
                }
            }
        }
    }
    
    // constructor creates the record from a JSON object; is tolerant of missing columns;
    // must be tolerant that Int64's may be encoded as Strings, especially OIDs
    init(jsonObj:NSDictionary) {
        self.rOptionSetLoc_Code = jsonObj[RecOptionSetLocales.COLUMN_OPTIONSETLOC_CODE] as? String
        self.rOptionSetLoc_Code_Extension = jsonObj[RecOptionSetLocales.COLUMN_OPTIONSETLOC_CODE_EXTENSION] as? String
        self.rOptionSetLoc_LangRegionCode = jsonObj[RecOptionSetLocales.COLUMN_OPTIONSETLOC_LANGREGIONCODE] as? String
        
        // break comma-delimited String into an Array
        let value1:String? = jsonObj[RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE] as? String
        if value1 != nil { self.rFieldLocProp_Options_Code_For_SV_File = FieldAttributes(duos: value1!.components(separatedBy:",")) }
        else { self.rFieldLocProp_Options_Code_For_SV_File = nil }
        let value2:String? = jsonObj[RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN] as? String
        if value2 != nil { self.rFieldLocProp_Options_Name_Shown = FieldAttributes(duos: value2!.components(separatedBy:",")) }
        else { self.rFieldLocProp_Options_Name_Shown = nil }
    }
    
    // is the optionals record valid in terms of required content?
    public func validate() -> Bool {
        if self.rOptionSetLoc_Code == nil || self.rOptionSetLoc_LangRegionCode == nil { return false }
        if self.rOptionSetLoc_Code!.isEmpty || self.rOptionSetLoc_LangRegionCode!.isEmpty { return false }
        return true
    }
    
}

/////////////////////////////////////////////////////////////////////////
// Main Record
/////////////////////////////////////////////////////////////////////////

public class RecOptionSetLocales {
    // record members
    public var rOptionSetLoc_Code:String                          // Field Attrib Loc Code
    public var rOptionSetLoc_Code_Extension:String?               // Extension to the Field Attrib Loc Code
    public var rOptionSetLoc_LangRegionCode:String                // ISO language-region code; alternate primary key
    public var rFieldLocProp_Options_Code_For_SV_File:FieldAttributes?   // option attributes for selected FRTs: in SV-File
    public var rFieldLocProp_Options_Name_Shown:FieldAttributes?         // option attributes for selected FRTs: as-shown
    
    // member constants and other static content
    private static let mCTAG:String = "ROpSL"
    public static let TABLE_NAME = "OptionSetLocales"
    public static let COLUMN_OPTIONSETLOC_CODE = "optionSetLoc_code"
    public static let COLUMN_OPTIONSETLOC_CODE_EXTENSION = "optionSetLoc_code_extension"
    public static let COLUMN_OPTIONSETLOC_LANGREGIONCODE = "optionSetLoc_langRegionCode"
    public static let COLUMN_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE = "fieldlocprop_options_code_sv_file"
    public static let COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN = "fieldlocprop_options_shown"

    // these are the as-stored in the database expression definitions
    public static let COL_EXPRESSION_OPTIONSETLOC_CODE = Expression<String>(RecOptionSetLocales.COLUMN_OPTIONSETLOC_CODE)
    public static let COL_EXPRESSION_OPTIONSETLOC_CODE_EXTENSION = Expression<String?>(RecOptionSetLocales.COLUMN_OPTIONSETLOC_CODE_EXTENSION)
    public static let COL_EXPRESSION_OPTIONSETLOC_LANGREGIONCODE = Expression<String>(RecOptionSetLocales.COLUMN_OPTIONSETLOC_LANGREGIONCODE)
    public static let COL_EXPRESSION_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE = Expression<String?>(RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FIELDLOCPROP_OPTIONS_NAME_SHOWN = Expression<String?>(RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN)

    // generate the string that will create the table
    public static func generateCreateTableString() -> String {
        return Table(TABLE_NAME).create(ifNotExists: true) { t in
            t.column(COL_EXPRESSION_OPTIONSETLOC_CODE)
            t.column(COL_EXPRESSION_OPTIONSETLOC_CODE_EXTENSION)
            t.column(COL_EXPRESSION_OPTIONSETLOC_LANGREGIONCODE)
            t.column(COL_EXPRESSION_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FIELDLOCPROP_OPTIONS_NAME_SHOWN)
            t.unique(COL_EXPRESSION_OPTIONSETLOC_CODE, COL_EXPRESSION_OPTIONSETLOC_CODE_EXTENSION, COL_EXPRESSION_OPTIONSETLOC_LANGREGIONCODE)
        }
    }
    
    // constructor imports an optionals record into a mainline record
    // throws upon missing required fields; caller is responsible to error.log;
    // FormShortName is allowed to be nil or blank since its filled in when records are saved to the database
    init(existingRec:RecOptionSetLocales_Optionals) throws {
        if existingRec.rOptionSetLoc_Code == nil || existingRec.rOptionSetLoc_LangRegionCode == nil {
            throw APP_ERROR(domain:DatabaseHandler.ThrowErrorDomain, errorCode:.MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo:"init(existingRec:RecOptionSetLocales_Optionals): Required == nil")
        }
        if existingRec.rOptionSetLoc_Code!.isEmpty || existingRec.rOptionSetLoc_LangRegionCode!.isEmpty {
            throw APP_ERROR(domain:DatabaseHandler.ThrowErrorDomain, errorCode:.MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo:"init(existingRec:RecOptionSetLocales_Optionals): Required .isEmpty")
        }
        self.rOptionSetLoc_Code = existingRec.rOptionSetLoc_Code!
        self.rOptionSetLoc_Code_Extension = existingRec.rOptionSetLoc_Code_Extension
        self.rOptionSetLoc_LangRegionCode = existingRec.rOptionSetLoc_LangRegionCode!
        self.rFieldLocProp_Options_Code_For_SV_File = existingRec.rFieldLocProp_Options_Code_For_SV_File
        self.rFieldLocProp_Options_Name_Shown = existingRec.rFieldLocProp_Options_Name_Shown
    }

    // constructor creates the record from the results of a database query
    // throws upon missing required columns from the database (already error.logs them)
    init(row:Row) throws {
        do {
            self.rOptionSetLoc_Code = try row.get(RecOptionSetLocales.COL_EXPRESSION_OPTIONSETLOC_CODE)
            self.rOptionSetLoc_Code_Extension = try row.get(RecOptionSetLocales.COL_EXPRESSION_OPTIONSETLOC_CODE_EXTENSION)
            self.rOptionSetLoc_LangRegionCode = try row.get(RecOptionSetLocales.COL_EXPRESSION_OPTIONSETLOC_LANGREGIONCODE)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(RecOptionSetLocales.mCTAG).init.row", during: "extraction", errorStruct: error, extra: RecOptionSetLocales.TABLE_NAME)
            throw error
        }
        
        // break comma-delimited String into an Array
        let value1:String? = row[Expression<String?>(RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE)]
        if (value1 ?? "").isEmpty { self.rFieldLocProp_Options_Code_For_SV_File = nil }
        else { self.rFieldLocProp_Options_Code_For_SV_File = FieldAttributes(duos: value1!.components(separatedBy:",")) }
        let value2:String? = row[Expression<String?>(RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN)]
        if (value2 ?? "").isEmpty { self.rFieldLocProp_Options_Name_Shown = nil }
        else { self.rFieldLocProp_Options_Name_Shown = FieldAttributes(duos: value2!.components(separatedBy:",")) }
    }
    
    // create an array of setters usable for database Insert or Update; will return nil if the record is incomplete and therefore not eligible to be stored
    // use 'exceptKey' for Update operations to ensure the key fields cannot be changed
    public func buildSetters(exceptKey:Bool=false) throws -> [Setter] {
        if self.rOptionSetLoc_Code.isEmpty || self.rOptionSetLoc_LangRegionCode.isEmpty {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "\(RecOptionSetLocales.mCTAG).buildSetters: Required .isEmpty")
        }
        
        var retArray = [Setter]()
        
        retArray.append(RecOptionSetLocales.COL_EXPRESSION_OPTIONSETLOC_CODE <- self.rOptionSetLoc_Code)
        retArray.append(RecOptionSetLocales.COL_EXPRESSION_OPTIONSETLOC_CODE_EXTENSION <- self.rOptionSetLoc_Code_Extension)
        retArray.append(RecOptionSetLocales.COL_EXPRESSION_OPTIONSETLOC_LANGREGIONCODE <- self.rOptionSetLoc_LangRegionCode)
        
        // place array components back into a comma separated array
        if self.rFieldLocProp_Options_Code_For_SV_File == nil {
            retArray.append(RecOptionSetLocales.COL_EXPRESSION_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE <- nil)
        } else {
            retArray.append(RecOptionSetLocales.COL_EXPRESSION_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE <- self.rFieldLocProp_Options_Code_For_SV_File!.pack())
        }
        if self.rFieldLocProp_Options_Name_Shown == nil {
            retArray.append(RecOptionSetLocales.COL_EXPRESSION_FIELDLOCPROP_OPTIONS_NAME_SHOWN <- nil)
        } else {
            retArray.append(RecOptionSetLocales.COL_EXPRESSION_FIELDLOCPROP_OPTIONS_NAME_SHOWN <- self.rFieldLocProp_Options_Name_Shown!.pack())
        }
        
        return retArray
    }
    
    // build the JSON values; will return null if the record is incomplete and therefore not eligible to be sent;
    // since the recipient may be 32-bit, send all Int64 as strings
    public func buildJSONObject() -> NSMutableDictionary? {
        if self.rOptionSetLoc_Code.isEmpty || self.rOptionSetLoc_LangRegionCode.isEmpty { return nil }
        
        let jsonObj:NSMutableDictionary = NSMutableDictionary()
        jsonObj[RecOptionSetLocales.COLUMN_OPTIONSETLOC_CODE] = String(self.rOptionSetLoc_Code)
        jsonObj[RecOptionSetLocales.COLUMN_OPTIONSETLOC_CODE_EXTENSION] = self.rOptionSetLoc_Code_Extension
        jsonObj[RecOptionSetLocales.COLUMN_OPTIONSETLOC_LANGREGIONCODE] = self.rOptionSetLoc_LangRegionCode
        
        // place array components back into a comma separated array
        if self.rFieldLocProp_Options_Code_For_SV_File == nil { jsonObj[RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE] = nil }
        else { jsonObj[RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_CODE_FOR_SV_FILE] = self.rFieldLocProp_Options_Code_For_SV_File!.pack() }
        if self.rFieldLocProp_Options_Name_Shown == nil { jsonObj[RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN] = nil }
        else { jsonObj[RecOptionSetLocales.COLUMN_FIELDLOCPROP_OPTIONS_NAME_SHOWN] = self.rFieldLocProp_Options_Name_Shown!.pack() }
        
        return jsonObj
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Database interaction methods used throughout the application
    /////////////////////////////////////////////////////////////////////////
    
    // return the quantity of Field records
    // throws exceptions either for local errors or from the database
    public static func optionSetLocalesGetQtyRecs() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        return try AppDelegate.mDatabaseHandler!.genericQueryQty(method:"\(self.mCTAG).optionSetLocalesGetQtyRecs", table:Table(RecOptionSetLocales.TABLE_NAME), whereStr:nil, valuesBindArray:nil)
    }
    
    // get all Field records (which could be none); unsorted
    // throws exceptions either for local errors or from the database
    public static func optionSetLocalesGetAllRecs(forOptionSetLoc_Code:String?=nil) throws -> AnySequence<Row> {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        var optionStr:String = ""
        var query:Table = Table(RecOptionSetLocales.TABLE_NAME)
        if !(forOptionSetLoc_Code ?? "").isEmpty {
            optionStr = ".C"
            query = query.select(*).filter(RecOptionSetLocales.COL_EXPRESSION_OPTIONSETLOC_CODE == forOptionSetLoc_Code!)
        } else {
            query = query.select(*)
        }
        return try AppDelegate.mDatabaseHandler!.genericQuery(method:"\(self.mCTAG).optionSetLocalesGetAllRecs\(optionStr)", tableQuery:query)
    }
    
    // get one specific Field record by IDCode
    // throws exceptions either for local errors or from the database
    // null indicates the record was not found
    /*public static func fieldAttribGetSpecifiedRecOfIDCode(fieldIDCode:String) throws -> RecFieldAttribDefs? {
     guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
     throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
     }
        let query = Table(RecFieldAttribDefs.TABLE_NAME).select(*).filter(RecFieldAttribDefs.COL_EXPRESSION_FIELD_IDCODE == fieldIDCode)
        let record = try AppDelegate.mDatabaseHandler!.genericQueryOne(method:"\(self.mCTAG).fieldGetSpecifiedRecOfIDCode", tableQuery:query)
        if record == nil { return nil }
        return RecFieldAttribDefs(row:record!)
    }*/
    
    // add a fieldAttribLocale entry; return is the RowID of the new record (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveNewToDB(ignoreDups:Bool=false) throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(RecOptionSetLocales.mCTAG).saveNewToDB", during: ".buildSetters", errorStruct: error, extra: RecOptionSetLocales.TABLE_NAME)
            throw error
        }
        let rowID = try AppDelegate.mDatabaseHandler!.insertRec(method:"\(RecOptionSetLocales.mCTAG).saveNewToDB", table:Table(RecOptionSetLocales.TABLE_NAME), cv:setters, orReplace:ignoreDups, noAlert:false)
        return rowID
    }
    
    // replace a Field entry; return is the quantity of the replaced records (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    /*public func saveChangesToDB(originalFieldRec:RecFieldAttribDefs) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
        }
        let setters = self.buildSetters(exceptKey:true)
        if setters == nil {
            AppDelegate.postToErrorLogAndAlert(method: "\(RecFieldAttribDefs.mCTAG).saveChangesToDB", during:"verification", errorMessage:"Required value is nil or empty", extra:RecFieldAttribDefs.TABLE_NAME, noAlert:true)
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_MISSING_REQUIRED_CONTENT, userInfo: nil)
        }
        let query = Table(RecFieldAttribDefs.TABLE_NAME).select(*).filter(RecFieldAttribDefs.COL_EXPRESSION_FIELD_ROW_TYPE == originalFieldRec.rField_Row_Type!.rawValue && RecFieldAttribDefs.COL_EXPRESSION_FIELD_ROW_TYPE_EXTENSION == originalFieldRec.rField_Row_Type_Extension!)
        let qty = try AppDelegate.mDatabaseHandler!.updateRec(method:"\(RecFieldAttribDefs.mCTAG).saveChangesToDB", tableQuery:query, cv:setters!)
        return qty
    }*/
    
    // delete the Field record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    /*public func deleteFromDB() throws -> Int {
        if self.rField_IDCode == nil {
            throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_MISSING_REQUIRED_CONTENT, userInfo: nil)
        }
        return try RecFieldAttribDefs.fieldAttribDeleteRec(fieldIDCode:self.rField_IDCode!)
    }*/
    
    // delete the indicated Field record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    /*public static func fieldAttribDeleteRec(fieldIDCode:String) throws -> Int {
     guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
     throw NSError(domain:DatabaseHandler.ThrowErrorDomain, code:APP_ERROR_DATABASE_IS_NOT_ENABLED, userInfo: nil)
     }
        let query = Table(RecFieldAttribDefs.TABLE_NAME).select(*).filter(RecFieldAttribDefs.COL_EXPRESSION_FIELD_IDCODE == fieldIDCode)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).fieldDeleteRec", tableQuery:query)
    }*/
}
