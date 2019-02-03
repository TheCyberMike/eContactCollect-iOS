//
//  RecAlert.swift
//  eContact Collect
//
//  Created by Yo on 9/26/18.
//

import SQLite

// special-use version of the record that is all optional; used for importing JSON records and
// specialized database queries if not every field will to be loaded; this record cannot be saved to the database
public class RecAlert_Optionals {
    // record members
    public var rAlert_DBID:Int64? = -1
    public var rAlert_Timestamp_MS_UTC:Int64? = 0
    public var rAlert_Timezone_MS_UTC_Offset:Int64? = 0
    public var rAlert_SameDay_Dup_Count:Int? = 0
    public var rAlert_Message:String?
    public var rAlert_ExtendedDetails:String? = nil
    
    // default constructor
    init() {}
    
    // constructor creates the record from the results of a database query; is tolerant of missing columns
    init(row:Row) {
        // note: do NOT use the COL_EXPRESSION_* above since these are all set as optional in case the original query did not select all columns
        self.rAlert_DBID = row[Expression<Int64?>(RecAlert.COLUMN_ALERT_ID)]
        self.rAlert_Timestamp_MS_UTC = row[Expression<Int64?>(RecAlert.COLUMN_ALERT_TIMESTAMP_MS_UTC)]
        self.rAlert_Timezone_MS_UTC_Offset = row[Expression<Int64?>(RecAlert.COLUMN_ALERT_TIMEZONE_MS_UTC_OFFSET)]
        self.rAlert_SameDay_Dup_Count = row[Expression<Int?>(RecAlert.COLUMN_ALERT_SAMEDAY_DUP_COUNT)]
        self.rAlert_Message = row[Expression<String?>(RecAlert.COLUMN_ALERT_MESSAGE)]
        self.rAlert_ExtendedDetails = row[Expression<String?>(RecAlert.COLUMN_ALERT_EXTENDED_DETAILS)]
    }
    
    // is the optionals record valid in terms of required content?
    public func validate() -> Bool {
        if self.rAlert_DBID == nil || self.rAlert_Timestamp_MS_UTC == nil || self.rAlert_Timezone_MS_UTC_Offset == nil || self.rAlert_SameDay_Dup_Count == nil || self.rAlert_Message == nil {
            return false
        }
        return true
    }
}

/////////////////////////////////////////////////////////////////////////
// Main Record
/////////////////////////////////////////////////////////////////////////

// full verson of the record; required fields are enforced; can be saved to the database
public class RecAlert {
    // record members
    public var rAlert_DBID:Int64 = -1                      // auto-assigned record index#; primary key
    public var rAlert_Timestamp_MS_UTC:Int64 = 0           // timestamp of the alert
    public var rAlert_Timezone_MS_UTC_Offset:Int64 = 0     // current timezone of the device at the alert
    public var rAlert_SameDay_Dup_Count:Int = 0            // FUTURE??:  duplication count to reduce duplicated entries
    public var rAlert_Message:String                       // alert text; blank text line is allowed
    public var rAlert_ExtendedDetails:String? = nil        // optional multi-line extended details about the alert
    
    // member constants and other static content
    private static let mCTAG:String = "RA"
    public static let TABLE_NAME = "Alerts"
    public static let COLUMN_ALERT_ID = "_id"
    public static let COLUMN_ALERT_TIMESTAMP_MS_UTC = "timestamp_ms_utc"
    public static let COLUMN_ALERT_TIMEZONE_MS_UTC_OFFSET = "timezone_ms_utc_offset"
    public static let COLUMN_ALERT_SAMEDAY_DUP_COUNT = "sameday_dup_count"
    public static let COLUMN_ALERT_MESSAGE = "alert_message"
    public static let COLUMN_ALERT_EXTENDED_DETAILS = "alert_extended_details"
    
    // these are the as-stored in the database expression definitions
    public static let COL_EXPRESSION_ALERT_ID = Expression<Int64>(RecAlert.COLUMN_ALERT_ID)
    public static let COL_EXPRESSION_ALERT_TIMESTAMP_MS_UTC = Expression<Int64>(RecAlert.COLUMN_ALERT_TIMESTAMP_MS_UTC)
    public static let COL_EXPRESSION_ALERT_TIMEZONE_MS_UTC_OFFSET = Expression<Int64>(RecAlert.COLUMN_ALERT_TIMEZONE_MS_UTC_OFFSET)
    public static let COL_EXPRESSION_ALERT_SAMEDAY_DUP_COUNT = Expression<Int>(RecAlert.COLUMN_ALERT_SAMEDAY_DUP_COUNT)
    public static let COL_EXPRESSION_ALERT_MESSAGE = Expression<String>(RecAlert.COLUMN_ALERT_MESSAGE)
    public static let COL_EXPRESSION_ALERT_EXTENDED_DETAILS = Expression<String?>(RecAlert.COLUMN_ALERT_EXTENDED_DETAILS)
    
    // generate the string that will create the table
    public static func generateCreateTableString() -> String {
        return Table(TABLE_NAME).create(ifNotExists: true) { t in
            t.column(COL_EXPRESSION_ALERT_ID, primaryKey: .autoincrement)
            t.column(COL_EXPRESSION_ALERT_TIMESTAMP_MS_UTC)
            t.column(COL_EXPRESSION_ALERT_TIMEZONE_MS_UTC_OFFSET)
            t.column(COL_EXPRESSION_ALERT_SAMEDAY_DUP_COUNT)
            t.column(COL_EXPRESSION_ALERT_MESSAGE)
            t.column(COL_EXPRESSION_ALERT_EXTENDED_DETAILS)
        }
    }

    // constructor creates the record from entered values
    init(timestamp_ms_utc:Int64, timezone_ms_utc_offset:Int64, message:String) {
        self.rAlert_DBID = -1
        self.rAlert_Timestamp_MS_UTC = timestamp_ms_utc
        self.rAlert_Timezone_MS_UTC_Offset = timezone_ms_utc_offset
        self.rAlert_SameDay_Dup_Count = 0
        self.rAlert_Message = message
    }
    
    // constructor creates the record from the results of a database query
    // throws upon missing required columns from the database (already error.log)
    init(row:Row) throws {
        do {
            self.rAlert_DBID = try row.get(RecAlert.COL_EXPRESSION_ALERT_ID)
            self.rAlert_Timestamp_MS_UTC = try row.get(RecAlert.COL_EXPRESSION_ALERT_TIMESTAMP_MS_UTC)
            self.rAlert_Timezone_MS_UTC_Offset = try row.get(RecAlert.COL_EXPRESSION_ALERT_TIMEZONE_MS_UTC_OFFSET)
            self.rAlert_SameDay_Dup_Count = try row.get(RecAlert.COL_EXPRESSION_ALERT_SAMEDAY_DUP_COUNT)
            self.rAlert_Message = try row.get(RecAlert.COL_EXPRESSION_ALERT_MESSAGE)
            self.rAlert_ExtendedDetails = row[Expression<String?>(RecAlert.COLUMN_ALERT_EXTENDED_DETAILS)]
        } catch {
            let appError = APP_ERROR(funcName: "\(RecAlert.mCTAG).init(Row)", domain: DatabaseHandler.ThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: RecAlert.TABLE_NAME)
            throw appError
        }
    }
    
    // create an array of setters usable for Insert or Update; will return nil if the record is incomplete and therefore not eligible to be stored
    // use 'exceptKey' for Update operations to ensure the key fields cannot be changed
    public func buildSetters(exceptKey:Bool=false) -> [Setter] {
        var retArray:[Setter] = []
        
        if !exceptKey {
            if self.rAlert_DBID >= 0 { retArray.append(RecAlert.COL_EXPRESSION_ALERT_ID <- self.rAlert_DBID) } // auto-assigned upon Insert
        }
        retArray.append(RecAlert.COL_EXPRESSION_ALERT_TIMESTAMP_MS_UTC <- self.rAlert_Timestamp_MS_UTC)
        retArray.append(RecAlert.COL_EXPRESSION_ALERT_TIMEZONE_MS_UTC_OFFSET <- self.rAlert_Timezone_MS_UTC_Offset)
        retArray.append(RecAlert.COL_EXPRESSION_ALERT_SAMEDAY_DUP_COUNT <- self.rAlert_SameDay_Dup_Count)
        retArray.append(RecAlert.COL_EXPRESSION_ALERT_MESSAGE <- self.rAlert_Message)
        retArray.append(RecAlert.COL_EXPRESSION_ALERT_EXTENDED_DETAILS <- self.rAlert_ExtendedDetails)
        
        return retArray
    }

#if TESTING
    // compare two RecAlert records; only needed during testing
    public func sameAs(baseRec:RecAlert) -> Bool {
        if self.rAlert_DBID != baseRec.rAlert_DBID { return false }
        if self.rAlert_Timestamp_MS_UTC != baseRec.rAlert_Timestamp_MS_UTC { return false }
        if self.rAlert_Timezone_MS_UTC_Offset != baseRec.rAlert_Timezone_MS_UTC_Offset { return false }
        if self.rAlert_SameDay_Dup_Count != baseRec.rAlert_SameDay_Dup_Count { return false }
        if self.rAlert_Message != baseRec.rAlert_Message { return false }
        if self.rAlert_ExtendedDetails != baseRec.rAlert_ExtendedDetails { return false }
        return true
    }
#endif
    
    /////////////////////////////////////////////////////////////////////////
    // Database interaction methods used throughout the application
    /////////////////////////////////////////////////////////////////////////
    
    // get the quantity of existing Alert records
    // throws exceptions either for local errors or from the database
    public static func alertGetQtyRecs() throws -> Int64 {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).alertGetQtyRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        return try AppDelegate.mDatabaseHandler!.genericQueryQty(method:"\(self.mCTAG).alertGetQtyRecs", table:Table(RecAlert.TABLE_NAME), whereStr:nil, valuesBindArray:nil)
    }
    
    // store the Alert record; ; return is the RowID of the new or replaced record (negative will not be returned);
    // throws exceptions either for local errors or from the database
    public func saveNewToDB() throws -> Int64 {
        // FUTURE?? implement alert counting for duplicated alerts on the same day
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(RecAlert.mCTAG).saveNewToDB", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let setters = self.buildSetters()
        let rowID = try AppDelegate.mDatabaseHandler!.insertRec(method:"\(RecAlert.mCTAG).saveNewToDB", table:Table(RecAlert.TABLE_NAME), cv:setters, orReplace:false, noAlert:true)
        if rowID > 0 && self.rAlert_DBID <= 0 { self.rAlert_DBID = rowID }
        return rowID
    }
    
    // get all Alert records (which could be none); most recent records are first
    // throws exceptions either for local errors or from the database
    public static func alertGetAllRecs() throws -> AnySequence<Row> {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).alertGetAllRecs", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecAlert.TABLE_NAME).select(*).order(RecAlert.COL_EXPRESSION_ALERT_TIMESTAMP_MS_UTC.desc)
        return try AppDelegate.mDatabaseHandler!.genericQuery(method:"\(self.mCTAG).alertGetAllRecs", tableQuery:query)
    }
    
    // delete the Alert record; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public func deleteFromDB() throws -> Int {
        do {
            return try RecAlert.alertDeleteRec(id:self.rAlert_DBID)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(RecAlert.mCTAG).deleteFromDB")
            throw appError
        } catch { throw error }
     }
    
    // delete the indicated Alert; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public static func alertDeleteRec(id:Int64) throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).alertDeleteRec", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecAlert.TABLE_NAME).select(*).filter(RecAlert.COL_EXPRESSION_ALERT_ID == id)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).alertDeleteRec", tableQuery:query)
    }
    
    // delete all the stored Alerts; return is the count of records deleted (negative will not be returned;
    // throws exceptions either for local errors or from the database
    public static func alertDeleteAll() throws -> Int {
        guard AppDelegate.mDatabaseHandler != nil, AppDelegate.mDatabaseHandler!.isReady() else {
            throw APP_ERROR(funcName: "\(self.mCTAG).alertDeleteAll", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "==nil || !.isReady()")
        }
        let query = Table(RecAlert.TABLE_NAME).select(*)
        return try AppDelegate.mDatabaseHandler!.genericDeleteRecs(method:"\(self.mCTAG).alertDeleteAll", tableQuery:query)
    }
}

