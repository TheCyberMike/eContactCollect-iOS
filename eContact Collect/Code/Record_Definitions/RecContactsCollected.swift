//
//  RecContactsCollected.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import SQLite

// special-use version of the record that is all optional; used for importing JSON records and
// specialized database queries if not every field will to be loaded; this record cannot be saved to the database
public class RecContactsCollected_Optionals {
    // record members
    public var rCC_index:Int64? = -1
    public var rOrg_Code_For_SV_File:String?
    public var rForm_Code_For_SV_File:String?
    public var rCC_DateTime:String?
    public var rCC_Status:RecContactsCollected.RecContactsCollectedStatus?
    public var rCC_Composed_Name:String?
    public var rCC_Importance_Position:Int? = -1
    public var rCC_Collector_Notes_Position:Int? = -1
    public var rCC_Importance:String?
    public var rCC_Collector_Notes:String?
    public var rCC_MetadataAttribs:String?
    public var rCC_MetadataValues:String?
    public var rCC_EnteredAttribs:String?
    public var rCC_EnteredValues:String?
    
    // constructor creates the record from the results of a database query; is tolerant of missing columns
    init(row:Row) {
        // note: do NOT use the COL_EXPRESSION_* above since these are all set as optional in case the original query did not select all columns
        self.rCC_index = row[Expression<Int64?>(RecContactsCollected.COLUMN_CC_INDEX)]
        self.rOrg_Code_For_SV_File = row[Expression<String?>(RecContactsCollected.COLUMN_ORG_CODE_FOR_SV_FILE)]
        self.rForm_Code_For_SV_File = row[Expression<String?>(RecContactsCollected.COLUMN_FORM_CODE_FOR_SV_FILE)]
        self.rCC_DateTime = row[Expression<String?>(RecContactsCollected.COLUMN_CC_DATETIME)]
        self.rCC_Composed_Name = row[Expression<String?>(RecContactsCollected.COL_EXPRESSION_CC_COMPOSED_NAME)]
        self.rCC_Importance = row[Expression<String?>(RecContactsCollected.COL_EXPRESSION_CC_IMPORTANCE)]
        self.rCC_Collector_Notes = row[Expression<String?>(RecContactsCollected.COL_EXPRESSION_CC_COLLECTOR_NOTES)]
        self.rCC_Importance_Position = row[Expression<Int?>(RecContactsCollected.COL_EXPRESSION_CC_IMPORTANCE_POSITION)]
        self.rCC_Collector_Notes_Position = row[Expression<Int?>(RecContactsCollected.COL_EXPRESSION_CC_COLLECTOR_NOTES_POSITION)]
        
        self.rCC_MetadataAttribs = row[Expression<String?>(RecContactsCollected.COL_EXPRESSION_CC_METADATA_ATTRIBS)]
        self.rCC_MetadataValues = row[Expression<String?>(RecContactsCollected.COL_EXPRESSION_CC_METADATA_VALUES)]
        self.rCC_EnteredAttribs = row[Expression<String?>(RecContactsCollected.COL_EXPRESSION_CC_ENTERED_ATTRIBS)]
        self.rCC_EnteredValues = row[Expression<String?>(RecContactsCollected.COL_EXPRESSION_CC_ENTERED_VALUES)]

        let value4:Int64? = row[Expression<Int64?>(RecContactsCollected.COL_EXPRESSION_CC_STATUS)]
        if value4 != nil { self.rCC_Status = RecContactsCollected.RecContactsCollectedStatus(rawValue:Int(exactly:value4!)!) }
        else { self.rCC_Status = nil }
    }
    
    // is the optionals record valid in terms of required content?
    public func validate() -> Bool {
        if self.rCC_index == nil || self.rOrg_Code_For_SV_File == nil || self.rCC_DateTime == nil || self.rCC_Status == nil ||
           self.rCC_Composed_Name == nil || self.rCC_MetadataAttribs == nil || self.rCC_MetadataValues == nil ||
           self.rCC_EnteredAttribs == nil || self.rCC_EnteredValues == nil { return false }
        
        if self.rOrg_Code_For_SV_File!.isEmpty || self.rCC_DateTime!.isEmpty || self.rCC_MetadataAttribs!.isEmpty ||
           self.rCC_MetadataValues!.isEmpty || self.rCC_EnteredAttribs!.isEmpty || self.rCC_EnteredValues!.isEmpty { return false }
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Main Record
/////////////////////////////////////////////////////////////////////////

// full verson of the record; required fields are enforced; can be saved to the database
public class RecContactsCollected {
    // status field
    public enum RecContactsCollectedStatus: Int {
        case Stored = 0, Generated = 1
    }
    
    // record members
    public var rCC_index:Int64 = -1                     // auto-assigned record#; primary key
    public var rOrg_Code_For_SV_File:String             // used to ensure organizational separation
    public var rForm_Code_For_SV_File:String            // used for query purposes
    public var rCC_DateTime:String                      // used for sorting purposes only
    public var rCC_Status:RecContactsCollectedStatus    // used to tag records that were placed into a SV file for deletion
    public var rCC_Composed_Name:String                 // used for sorting purposes only
    public var rCC_Importance_Position:Int = -1         // used to insert Importance into the metadata
    public var rCC_Collector_Notes_Position:Int = -1    // used to insert Collector Notes into the metadata
    public var rCC_Importance:String?                   // optional add-in
    public var rCC_Collector_Notes:String?              // optional add-in
    public var rCC_MetadataAttribs:String               // string of tab-separated metadata col-headers
    public var rCC_MetadataValues:String                // string of tab-separated metadata values
    public var rCC_EnteredAttribs:String                // string of tab-separated entered-data col-headers
    public var rCC_EnteredValues:String                 // string of tab-separated entered-data values

    // member constants and other static content
    private static let mCTAG:String = "RCC"
    public static let TABLE_NAME = "ContactsCollected"
    public static let COLUMN_CC_INDEX = "_id"
    public static let COLUMN_ORG_CODE_FOR_SV_FILE = "org_code_sv_file"
    public static let COLUMN_FORM_CODE_FOR_SV_FILE = "form_code_sv_file"
    public static let COLUMN_CC_DATETIME = "cc_dateTime"
    public static let COLUMN_CC_STATUS = "cc_status"
    public static let COLUMN_CC_COMPOSED_NAME = "cc_composed_name"
    public static let COLUMN_CC_METADATA_ATTRIBS = "cc_metadata_attribs"
    public static let COLUMN_CC_METADATA_VALUES = "cc_metadata_values"
    public static let COLUMN_CC_ENTERED_ATTRIBS = "cc_entered_attribs"
    public static let COLUMN_CC_ENTERED_VALUES = "cc_entered_values"
    public static let COLUMN_CC_IMPORTANCE = "cc_importance"
    public static let COLUMN_CC_COLLECTOR_NOTES = "cc_collector_notes"
    public static let COLUMN_CC_IMPORTANCE_POSITION = "cc_position_importance"
    public static let COLUMN_CC_COLLECTOR_NOTES_POSITION = "cc_position_collector_notes"

    // these are the as-stored in the database expression definitions
    public static let COL_EXPRESSION_CC_INDEX = Expression<Int64>(RecContactsCollected.COLUMN_CC_INDEX)
    public static let COL_EXPRESSION_ORG_CODE_FOR_SV_FILE = Expression<String>(RecContactsCollected.COLUMN_ORG_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_FORM_CODE_FOR_SV_FILE = Expression<String>(RecContactsCollected.COLUMN_FORM_CODE_FOR_SV_FILE)
    public static let COL_EXPRESSION_CC_DATETIME = Expression<String>(RecContactsCollected.COLUMN_CC_DATETIME)
    public static let COL_EXPRESSION_CC_STATUS = Expression<Int64>(RecContactsCollected.COLUMN_CC_STATUS)
    public static let COL_EXPRESSION_CC_COMPOSED_NAME = Expression<String>(RecContactsCollected.COLUMN_CC_COMPOSED_NAME)
    public static let COL_EXPRESSION_CC_METADATA_ATTRIBS = Expression<String>(RecContactsCollected.COLUMN_CC_METADATA_ATTRIBS)
    public static let COL_EXPRESSION_CC_METADATA_VALUES = Expression<String>(RecContactsCollected.COLUMN_CC_METADATA_VALUES)
    public static let COL_EXPRESSION_CC_ENTERED_ATTRIBS = Expression<String>(RecContactsCollected.COLUMN_CC_ENTERED_ATTRIBS)
    public static let COL_EXPRESSION_CC_ENTERED_VALUES = Expression<String>(RecContactsCollected.COLUMN_CC_ENTERED_VALUES)
    public static let COL_EXPRESSION_CC_IMPORTANCE = Expression<String?>(RecContactsCollected.COLUMN_CC_IMPORTANCE)
    public static let COL_EXPRESSION_CC_COLLECTOR_NOTES = Expression<String?>(RecContactsCollected.COLUMN_CC_COLLECTOR_NOTES)
    public static let COL_EXPRESSION_CC_IMPORTANCE_POSITION = Expression<Int>(RecContactsCollected.COLUMN_CC_IMPORTANCE_POSITION)
    public static let COL_EXPRESSION_CC_COLLECTOR_NOTES_POSITION = Expression<Int>(RecContactsCollected.COLUMN_CC_COLLECTOR_NOTES_POSITION)

    // generate the string that will create the table
    public static func generateCreateTableString() -> String {
        return Table(TABLE_NAME).create(ifNotExists: true) { t in
            t.column(COL_EXPRESSION_CC_INDEX, primaryKey: .autoincrement)
            t.column(COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
            t.column(COL_EXPRESSION_CC_DATETIME)
            t.column(COL_EXPRESSION_CC_STATUS)
            t.column(COL_EXPRESSION_CC_COMPOSED_NAME)
            t.column(COL_EXPRESSION_CC_IMPORTANCE_POSITION)
            t.column(COL_EXPRESSION_CC_COLLECTOR_NOTES_POSITION)
            t.column(COL_EXPRESSION_CC_IMPORTANCE)
            t.column(COL_EXPRESSION_CC_COLLECTOR_NOTES)
            t.column(COL_EXPRESSION_CC_METADATA_ATTRIBS)
            t.column(COL_EXPRESSION_CC_METADATA_VALUES)
            t.column(COL_EXPRESSION_CC_ENTERED_ATTRIBS)
            t.column(COL_EXPRESSION_CC_ENTERED_VALUES)
        }
    }
    
    // create a duplicate of an existing record
    init(existingRec:RecContactsCollected) {
        self.rCC_index = existingRec.rCC_index
        self.rOrg_Code_For_SV_File = existingRec.rOrg_Code_For_SV_File
        self.rForm_Code_For_SV_File = existingRec.rForm_Code_For_SV_File
        self.rCC_DateTime = existingRec.rCC_DateTime
        self.rCC_Status = existingRec.rCC_Status
        self.rCC_Composed_Name = existingRec.rCC_Composed_Name
        self.rCC_MetadataAttribs = existingRec.rCC_MetadataAttribs
        self.rCC_MetadataValues = existingRec.rCC_MetadataValues
        self.rCC_EnteredAttribs = existingRec.rCC_EnteredAttribs
        self.rCC_EnteredValues = existingRec.rCC_EnteredValues
        self.rCC_Importance = existingRec.rCC_Importance
        self.rCC_Collector_Notes = existingRec.rCC_Collector_Notes
        self.rCC_Importance_Position = existingRec.rCC_Importance_Position
        self.rCC_Collector_Notes_Position = existingRec.rCC_Collector_Notes_Position
    }
    
    // constructor creates the record from entered values
    init(org_code_sv_file:String, form_code_sv_file:String, dateTime:String, status:RecContactsCollectedStatus, composed_name:String, meta_attribs:String, meta_values:String, entered_attribs:String, entered_values:String) {
        self.rCC_index = -1
        self.rOrg_Code_For_SV_File = org_code_sv_file
        self.rForm_Code_For_SV_File = form_code_sv_file
        self.rCC_DateTime = dateTime
        self.rCC_Status = status
        self.rCC_Composed_Name = composed_name
        self.rCC_MetadataAttribs = meta_attribs
        self.rCC_MetadataValues = meta_values
        self.rCC_EnteredAttribs = entered_attribs
        self.rCC_EnteredValues = entered_values
        self.rCC_Importance = nil
        self.rCC_Collector_Notes = nil
        self.rCC_Importance_Position = 0
        self.rCC_Collector_Notes_Position = 0
    }
    
    // constructor creates the record from the results of a database query
    // throws upon missing required columns from the database (already error.logs them)
    init(row:Row) throws {
        do {
            self.rCC_index = try row.get(RecContactsCollected.COL_EXPRESSION_CC_INDEX)
            self.rOrg_Code_For_SV_File = try row.get(RecContactsCollected.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE)
            self.rForm_Code_For_SV_File = try row.get(RecContactsCollected.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE)
            self.rCC_DateTime = try row.get(RecContactsCollected.COL_EXPRESSION_CC_DATETIME)
            let value1:Int64 = try row.get(RecContactsCollected.COL_EXPRESSION_CC_STATUS)
            self.rCC_Status = RecContactsCollectedStatus(rawValue:Int(exactly:value1)!)!
            self.rCC_Composed_Name = try row.get(RecContactsCollected.COL_EXPRESSION_CC_COMPOSED_NAME)
            self.rCC_Importance_Position = try row.get(RecContactsCollected.COL_EXPRESSION_CC_IMPORTANCE_POSITION)
            self.rCC_Collector_Notes_Position = try row.get(RecContactsCollected.COL_EXPRESSION_CC_COLLECTOR_NOTES_POSITION)
            self.rCC_MetadataAttribs = try row.get(RecContactsCollected.COL_EXPRESSION_CC_METADATA_ATTRIBS)
            self.rCC_MetadataValues = try row.get(RecContactsCollected.COL_EXPRESSION_CC_METADATA_VALUES)
            self.rCC_EnteredAttribs = try row.get(RecContactsCollected.COL_EXPRESSION_CC_ENTERED_ATTRIBS)
            self.rCC_EnteredValues = try row.get(RecContactsCollected.COL_EXPRESSION_CC_ENTERED_VALUES)
            self.rCC_Importance = try row.get(RecContactsCollected.COL_EXPRESSION_CC_IMPORTANCE)
            self.rCC_Collector_Notes = try row.get(RecContactsCollected.COL_EXPRESSION_CC_COLLECTOR_NOTES)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(RecContactsCollected.mCTAG).init.row", during: "extraction", errorStruct: error, extra: RecContactsCollected.TABLE_NAME)
            throw error
        }
    }
    
    // create an array of setters usable for database Insert or Update; will return nil if the record is incomplete and therefore not eligible to be stored
    // use 'exceptKey' for Update operations to ensure the key fields cannot be changed
    public func buildSetters(exceptKey:Bool=false) throws -> [Setter] {
        if self.rOrg_Code_For_SV_File.isEmpty || self.rCC_DateTime.isEmpty || self.rCC_MetadataAttribs.isEmpty || self.rCC_MetadataValues.isEmpty || self.rCC_EnteredAttribs.isEmpty || self.rCC_EnteredValues.isEmpty {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .MISSING_REQUIRED_CONTENT, userErrorDetails: nil, developerInfo: "\(RecContactsCollected.mCTAG).buildSetters: Required .isEmpty")
            
        }
        
        var retArray = [Setter]()
        
        if !exceptKey {
            if self.rCC_index >= 0 { retArray.append(RecContactsCollected.COL_EXPRESSION_CC_INDEX <- self.rCC_index) }    // auto-assigned upon Insert
        }
        retArray.append(RecContactsCollected.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE <- self.rOrg_Code_For_SV_File)
        retArray.append(RecContactsCollected.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE <- self.rForm_Code_For_SV_File)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_DATETIME <- self.rCC_DateTime)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_STATUS <- Int64(self.rCC_Status.rawValue))
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_COMPOSED_NAME <- self.rCC_Composed_Name)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_METADATA_ATTRIBS <- self.rCC_MetadataAttribs)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_METADATA_VALUES <- self.rCC_MetadataValues)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_ENTERED_ATTRIBS <- self.rCC_EnteredAttribs)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_ENTERED_VALUES <- self.rCC_EnteredValues)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_IMPORTANCE_POSITION <- self.rCC_Importance_Position)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_COLLECTOR_NOTES_POSITION <- self.rCC_Collector_Notes_Position)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_IMPORTANCE <- self.rCC_Importance)
        retArray.append(RecContactsCollected.COL_EXPRESSION_CC_COLLECTOR_NOTES <- self.rCC_Collector_Notes)
        
        return retArray
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Database interaction methods used throughout the application
    /////////////////////////////////////////////////////////////////////////
    
    // return the quantity of CC records for a specific organization
    // throws exceptions either for local errors or from the database
    public static func ccGetQtyRecs(forOrgShortName:String) throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        return try AppDelegate.mDatabaseHandler!.genericQueryQty(method:"\(self.mCTAG).ccGetQtyRecs", table:Table(RecContactsCollected.TABLE_NAME), whereStr:"(\"\(RecContactsCollected.COLUMN_ORG_CODE_FOR_SV_FILE)\" = \"\(forOrgShortName)\")", valuesBindArray:nil)
    }
    
    // get all CC records for a specific organization (which could be none); sorted most recent first
    // throws exceptions either for local errors or from the database
    public static func ccGetAllRecs(forOrgShortName:String, forFormShortName:String? = nil) throws -> AnySequence<Row> {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        var query = Table(RecContactsCollected.TABLE_NAME).select(*)
        if forFormShortName != nil {
            query = query.filter(RecContactsCollected.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName && RecContactsCollected.COL_EXPRESSION_FORM_CODE_FOR_SV_FILE == forFormShortName!).order(RecContactsCollected.COL_EXPRESSION_CC_DATETIME.desc)
        } else {
            query = query.filter(RecContactsCollected.COL_EXPRESSION_ORG_CODE_FOR_SV_FILE == forOrgShortName).order(RecContactsCollected.COL_EXPRESSION_CC_DATETIME.desc)
        }
        return try AppDelegate.mDatabaseHandler!.genericQuery(method:"\(self.mCTAG).ccGetAllRecs", tableQuery:query)
    }
    
    // get one specific CC record by index#
    // throws exceptions either for local errors or from the database
    // null indicates the record was not found
    public static func ccGetSpecifiedRecOfIndex(index:Int64) throws -> RecContactsCollected? {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecContactsCollected.TABLE_NAME).select(*).filter(RecContactsCollected.COL_EXPRESSION_CC_INDEX == index)
        let record = try AppDelegate.mDatabaseHandler!.genericQueryOne(method:"\(self.mCTAG).ccGetSpecifiedRecOfIndex", tableQuery:query)
        if record == nil { return nil }
        return try RecContactsCollected(row:record!)
    }
    
    // add a CC entry; return is the RowID of the new record (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveNewToDB() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(RecContactsCollected.mCTAG).saveNewToDB", during: ".buildSetters", errorStruct: error, extra: RecContactsCollected.TABLE_NAME)
            throw error
        }
        let rowID = try AppDelegate.mDatabaseHandler!.insertRec(method:"\(RecContactsCollected.mCTAG).saveNewToDB", table:Table(RecContactsCollected.TABLE_NAME), cv:setters, orReplace:false, noAlert:false)
        self.rCC_index = rowID
        return rowID
    }
    
    // replace a CC entry; return is the quantity of the replaced records (negative will not be returned);
    // WARNING: if the key field has been changed, all existing records in all Tables will need renaming;
    // throws exceptions either for local errors or from the database
    public func saveChangesToDB(originalCCRec:RecContactsCollected) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        var setters:[Setter]
        do {
            setters = try self.buildSetters()
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(RecContactsCollected.mCTAG).saveChangesToDB", during: ".buildSetters", errorStruct: error, extra: RecContactsCollected.TABLE_NAME)
            throw error
        }
        let query = Table(RecContactsCollected.TABLE_NAME).select(*).filter(RecContactsCollected.COL_EXPRESSION_CC_INDEX == originalCCRec.rCC_index)
        let qty = try AppDelegate.mDatabaseHandler!.updateRec(method:"\(RecContactsCollected.mCTAG).saveChangesToDB", tableQuery:query, cv:setters)
        return qty
    }
    
    // delete the indicated CC record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public static func ccDeleteRec(index:Int64) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecContactsCollected.TABLE_NAME).select(*).filter(RecContactsCollected.COL_EXPRESSION_CC_INDEX == index)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).ccDeleteRec", tableQuery:query)
    }
    
    // delete all CC records that are marked as generated; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public static func ccDeleteGeneratedRecs() throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecContactsCollected.TABLE_NAME).select(*).filter(RecContactsCollected.COL_EXPRESSION_CC_STATUS == 1)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).ccDeleteGeneratedRecs", tableQuery:query)
    }
}
