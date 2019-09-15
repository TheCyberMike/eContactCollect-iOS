//
//  DatabaseHandler.swift
//  eContact Collect
//
//  Created by Yo on 9/25/18.
//

import UIKit
import SQLite

// extension to SQLite.swift Connection class to access the user_version PRAGMA of a SQLite database
extension Connection {
    public func getUserVersion() throws -> Int64 {
        return try scalar("PRAGMA user_version") as! Int64
    }
    public func setUserVersion(newVersion:Int64) throws {
        try run("PRAGMA user_version = \(newVersion)")
    }
}

// handler class for the database
public class DatabaseHandler {
    // member variables
    public var mDB:Connection? = nil
    public var mVersion:Int64 = 0
    public var mDBstatus_state:HandlerStatusStates = .Unknown
    public var mAppError:APP_ERROR? = nil

    // member constants and other static content
    public static let shared:DatabaseHandler = DatabaseHandler()
    internal static let CTAG:String = "HBD"
    internal let mCTAG:String = CTAG
    public static let ThrowErrorDomain:String = NSLocalizedString("Database-Handler", comment:"")
    private let mThrowErrorDomain:String = ThrowErrorDomain
    internal let mDATABASE_NAME:String = "eContactCollect_DB.sqlite"
    internal static var mDATABASE_VERSION:Int64 = 3    // WARNING: changing this value will cause invocation of init_onUpgrade

    // constructor;
    public init() {}
    
    // initialization; returns true if initialize fully succeeded;
    // errors are stored via the class members and will already be posted to the error.log
    public func initialize(method:String) -> Bool {
//debugPrint("\(mCTAG).initialize STARTED")
        // define where the database will be; this App exposes the Documents folder to iTunes and the Files APP so the database should be in Library
        let fullPath = "\(AppDelegate.mLibApp)/\(self.mDATABASE_NAME)"
        self.mDBstatus_state = .Unknown
        self.mAppError = nil

#if TESTING
        // delete the temporary database so its always empty
        do {
            try FileManager.default.removeItem(atPath: fullPath)
        } catch {}  // for TESTING only; no need to post this or report this
#endif
        
        // detect whether the database file already exists
        var alreadyExists = false
        if FileManager.default.fileExists(atPath: fullPath) { alreadyExists = true }
        else { self.mDBstatus_state = .Missing }
        
        // connect to the database; it will be auto-created and empty if it did not already exist
        do {
            // connect to/create the database
            self.mDB = try Connection(fullPath, readonly: false)
        } catch {
            self.mDB = nil
            self.mDBstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: "\(method):\(self.mCTAG).initialize", during: "Connection", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Connect to Database", comment:""))
            AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: fullPath, noAlert: true)
            return false
        }
        if self.mDB == nil {
            // this should never happen as Connection does not return a nil
            self.mDBstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: "\(method):\(self.mCTAG).initialize", during: "Connection", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Connect to Database", comment:""), developerInfo: "Failed: self.mDB == nil; unknown error")
            AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: fullPath, noAlert: true)
            return false
        }
        
        // Connection to a new-empty or existing database succeeded
        if !alreadyExists {
            // database file did not previously exist, so initialize it as new
            do {
                try self.init_onNew()
            } catch {
                self.mAppError!.prependCallStack(funcName: "\(method):\(self.mCTAG).initialize")
                AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: fullPath, noAlert: true)
                return false
            }
        } else {
            // database file did already exist, so get its internal database version code
            do {
                self.mVersion = try self.mDB!.getUserVersion()
            } catch {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(method):\(self.mCTAG).initialize", during: "getUserVersion", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Verify the Database", comment:""))
                AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: error, extra: fullPath, noAlert: true)
                return false
            }
            
            // now check if it needs an upgrade to the database version this App version neeeds
            if self.mVersion != DatabaseHandler.mDATABASE_VERSION {
                // database version number does not match this App version's expectation of database version; activate the upgrade process to resolve it
                self.mDBstatus_state = .Obsolete
                do {
                    try self.init_onUpgrade(currentVersion: self.mVersion, targetVersion: DatabaseHandler.mDATABASE_VERSION)
                } catch {
                    self.mAppError!.prependCallStack(funcName: "\(method):\(self.mCTAG).initialize")
                    AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).initialize", errorStruct: self.mAppError!, extra: fullPath, noAlert: true)
                    return false
                }
debugPrint("\(mCTAG).initialize DATABASE successfully upgraded to version \(self.mVersion)")
                AppDelegate.postAlert(message: NSLocalizedString("Database successfully upgraded to version ", comment:"") + String(self.mVersion))
            } else {
                self.mDBstatus_state = .Valid
                // ?? temporary for version 1.2 only
                do {
                    try RecAlert.test_upgrade_1_to_2(db: self.mDB!)
                } catch {}
            }

        }
//debugPrint("\(mCTAG).initialize COMPLETED")
        return true
    }
    
    // this will not get called during normal App operation, but does get called during Unit and UI Testing
    // perform any shutdown that may be needed
    internal func shutdown() {
        let _ = sqlite3_close(self.mDB!.handle) // close the database first
        self.mDB = nil  // the dealloc process should also close the database
        self.mDBstatus_state = .Unknown
    }

    // called only when the database has not yet existed and thus must be initialized;
    // perform the necessary new creations actions
    internal func init_onNew() throws {
//debugPrint("\(mCTAG).init_onNew STARTED TO INITIALIZE NEW DATABASE")
        do {
            try self.createAlertsTable()
            try self.createOrganizationDefsTable()
            try self.createOrganizationLangsTable()
            try self.createOrgFormDefsTable()
            try self.createOrgFormFieldDefsTable()
            try self.createOrgFormFieldLocalesTable()
            try self.createOptionSetLocalesTable()
            //??try self.createOrgCustomFieldDefsTable()
            //??try self.createOrgCustomFieldLocalesTable()
            try self.createContactsCollectedTable()
        } catch {
            self.mAppError?.prependCallStack(funcName: "\(self.mCTAG).init_onNew")
            throw error
        }
        
        // all succeeded; set the versioning properly
        do {
            try self.mDB!.setUserVersion(newVersion: DatabaseHandler.mDATABASE_VERSION)
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onNew", during: "setUserVersion", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: self.mDATABASE_NAME)
            throw self.mAppError!
        }
        
        // all good; finalize
        self.mVersion = DatabaseHandler.mDATABASE_VERSION
        self.mDBstatus_state = .Valid
    }
    
    // called only when the database 'user_version' does not match the expected version;
    // perform the necessary upgrade actions;
    // be sure to also update DatabaseHandler.validateJSONdbFile() databaseVersion logic as needed;
    // be sure to also update <record>_Optionals.init(jsonObj:, context:) methods as needed
    internal func init_onUpgrade(currentVersion:Int64, targetVersion:Int64) throws {
        self.mVersion = currentVersion
        
        // upgrade from version 1 to version 2
        if self.mVersion == 1 {
            do {
                // invoke/perform upgrade activities inside a transaction so database integrity is preserved
                try self.mDB!.transaction {     // throws Result
                    try RecAlert.upgrade_1_to_2(db: self.mDB!)              // throws APP_ERROR
                    try RecOrganizationDefs.upgrade_1_to_2(db: self.mDB!)   // throws APP_ERROR
                    try RecOrgFormDefs.upgrade_1_to_2(db: self.mDB!)        // throws APP_ERROR
                }
            } catch let appError as APP_ERROR {
                self.mDBstatus_state = .Invalid
                self.mAppError = appError
                self.mAppError?.prependCallStack(funcName: "\(self.mCTAG).init_onUpgrade.1")
                throw self.mAppError!
            } catch let sqlResult as Result {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.1", during:"self.mDB!.transaction", domain: self.mThrowErrorDomain, error: sqlResult, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            } catch {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.1", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            }
            // success; set the intermediate/final version state in-case of later throws
            do {
                try self.mDB!.setUserVersion(newVersion: 2)     // throws Result
                self.mVersion = 2
            } catch {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.1", during: "setUserVersion", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            }
        }
        
        // for future upgrades
        if self.mVersion == 2 {
            do {
                // invoke/perform upgrade activities inside a transaction so database integrity is preserved
                try self.mDB!.transaction {     // throws Result
                    try RecOrgFormFieldDefs.upgrade_2_to_3(db: self.mDB!)              // throws APP_ERROR
                }
            } catch let appError as APP_ERROR {
                self.mDBstatus_state = .Invalid
                self.mAppError = appError
                self.mAppError?.prependCallStack(funcName: "\(self.mCTAG).init_onUpgrade.2")
                throw self.mAppError!
            } catch let sqlResult as Result {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.2", during:"self.mDB!.transaction", domain: self.mThrowErrorDomain, error: sqlResult, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            } catch {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.2", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            }
            // success; set the intermediate/final version state in-case of later throws
            do {
                try self.mDB!.setUserVersion(newVersion: 3)     // throws Result
                self.mVersion = 3
            } catch {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.2", during: "setUserVersion", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            }
        }
        
        // for future upgrades
        /*if self.mVersion == 3 {
            do {
                // invoke/perform upgrade activities inside a transaction so database integrity is preserved
                try self.mDB!.transaction {     // throws Result
                    // FUTURE
                }
            } catch let appError as APP_ERROR {
                self.mDBstatus_state = .Invalid
                self.mAppError = appError
                self.mAppError?.prependCallStack(funcName: "\(self.mCTAG).init_onUpgrade.3")
                throw self.mAppError!
            } catch let sqlResult as Result {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.3", during:"self.mDB!.transaction", domain: self.mThrowErrorDomain, error: sqlResult, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            } catch {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.3", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            }
            // success; set the intermediate/final version state in-case of later throws
            do {
                try self.mDB!.setUserVersion(newVersion: 4)     // throws Result
                self.mVersion = 4
            } catch {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).init_onUpgrade.3", during: "setUserVersion", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Upgrade the Database", comment:""), developerInfo: self.mDATABASE_NAME)
                throw self.mAppError!
            }
        }*/

        // all good; finalize
        self.mDBstatus_state = .Valid
        AppDelegate.noticeToErrorLogAndAlert(method: "\(AppDelegate.mCTAG).initialize", during: nil, notice: "Database successfully upgraded from version \(currentVersion) to version \(self.mVersion)", extra: nil, noAlert: true)
    }
    
    // perform any handler first time setups that have not already been performed; the sequence# allows later versions to retro-add a first-time setup;
    // the database handler must be especially mindful that it may not have properly initialized and should bypass this;
    // errors are stored via the class members and will already be posted to the error.log
    public func firstTimeSetup(method:String) {
//debugPrint("\(mCTAG).firstTimeSetup STARTED")
        if AppDelegate.getPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Handler_Database_FirstTime_Done) != 1 {
            // none at this time; this handler auto-detects database create/upgrade situations in its initialize() method
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Handler_Database_FirstTime_Done, value: 1)
        }
    }
    
    // return whether the database is fully operational
    public func isReady() -> Bool {
        if self.mDBstatus_state == .Valid { return true }
        return false
    }
    
    // return various database versions codes suitable for error.log and About popup use
    public func getVersioning() -> String {
        return "\(self.mVersion)"
    }
    
    // used only to do a factory reset ... the entire database is deleted then rebuilt ... all data is lost!
    // returns false if new database initialization failed; all errors will have already been posted to error.log
    public func factoryResetEntireDB() -> Bool {
        // close the database first
        let _ = sqlite3_close(self.mDB!.handle)
        self.mDB = nil  // the dealloc process should also close the database
        
        // delete the database entirely
        let fullPath = "\(AppDelegate.mLibApp)/\(self.mDATABASE_NAME)"
        do {
            try FileManager.default.removeItem(atPath: fullPath)
        } catch {
            self.mDBstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).factoryResetEntireDB", during: "FileManager.default.removeItem", domain: self.mThrowErrorDomain, error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Delete the Database", comment:""))
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).factoryResetEntireDB", errorStruct: self.mAppError!, extra: fullPath, noAlert: true)
            return false
        }
        
        // re-create, rebuild, and re-initialize the database
        self.mDBstatus_state = .Missing
        AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Handler_Database_FirstTime_Done, value: 0)
        if !self.initialize(method: "\(self.mCTAG).factoryResetEntireDB") { return false }  // init_onNew will be auto-invoked
        self.firstTimeSetup(method: "\(self.mCTAG).factoryResetEntireDB")
        return true
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Table creation methods
    /////////////////////////////////////////////////////////////////////////
    
    // create the alerts table
    private func createAlertsTable() throws {
        do {
            try self.mDB!.run(RecAlert.generateCreateTableString())
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createAlertsTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecAlert.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    // create the organizations table
    private func createOrganizationDefsTable() throws {
        do {
            try self.mDB!.run(RecOrganizationDefs.generateCreateTableString())
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createOrganizationDefsTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecOrganizationDefs.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    // create the organization languagess table
    private func createOrganizationLangsTable() throws {
        do {
            try self.mDB!.run(RecOrganizationLangs.generateCreateTableString())
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createOrganizationLangsTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecOrganizationLangs.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    // create the organization forms table
    private func createOrgFormDefsTable() throws {
        do {
            try self.mDB!.run(RecOrgFormDefs.generateCreateTableString())
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createOrgFormDefsTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecOrgFormDefs.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    // create the organization form fields table
    private func createOrgFormFieldDefsTable() throws {
        do {
            try self.mDB!.run(RecOrgFormFieldDefs.generateCreateTableString())
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createOrgFormFieldDefsTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecOrgFormFieldDefs.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    // create the organization form fields table
    private func createOrgFormFieldLocalesTable() throws {
        do {
            try self.mDB!.run(RecOrgFormFieldLocales.generateCreateTableString())
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createOrgFormFieldLocalesTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecOrgFormFieldLocales.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    // create the fields table
    /*??private func createOrgCustomFieldDefsTable() throws {
        do {
            try self.mDB!.run(RecOrgCustomFieldDefs.generateCreateTableString())
            return true;
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createOrgCustomFieldDefsTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecOrgCustomFieldDefs.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    // create the fields table
    private func createOrgCustomFieldLocalesTable() throws {
        do {
            try self.mDB!.run(RecOrgCustomFieldLocales.generateCreateTableString())
            return true;
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createOrgCustomFieldLocalesTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecOrgCustomFieldLocales.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }*/
    
    // create the optionSet locales table
    private func createOptionSetLocalesTable() throws {
        do {
            try self.mDB!.run(RecOptionSetLocales.generateCreateTableString())
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createOptionSetLocalesTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecOptionSetLocales.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    // create the contacts collected table
    private func createContactsCollectedTable() throws {
        do {
            try self.mDB!.run(RecContactsCollected.generateCreateTableString())
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(funcName: "\(self.mCTAG).createContactsCollectedTable", during: "Run(Create)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Create the Database", comment:""), developerInfo: "DB table \(RecContactsCollected.TABLE_NAME)", noAlert: true)
            throw self.mAppError!
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // The following methods perform write or delete record operation for the rest of the App
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // perform an insert of a new record (optionally replace an existing one); works for all database tables;
    // returns the rowID that was inserted (or replaced); remember for some records the rowID is an OID and most negative values are acceptable;
    // throws exceptions for SQLite and other errors
    internal func insertRec(method:String, table:Table, cv:[Setter], orReplace:Bool, noAlert:Bool) throws -> Int64 {
        if self.mDB == nil {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).insertRec", during: "self.mDB== nil", domain: self.mThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "DB table \(table.clauses.from.name)", noAlert: noAlert)
        }
        var duringdText:String = "Run(Insert"
        if orReplace { duringdText = duringdText + "|Replace" }
        duringdText = duringdText + ")"
        do {
            // unlike Android, these do not return negatives for error conditions
            if orReplace { return try self.mDB!.run(table.insert(or: .replace, cv)) }
            else { return try self.mDB!.run(table.insert(cv)) }
        } catch {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).insertRec", during: duringdText, domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: "DB table \(table.clauses.from.name)")
        }
    }
    
    // perform an update of selected fields in an existing record; !!will not add the record if it does not exist!!; works for all database tables;
    // !!a query MUST be supplied else all records will get updated!!;
    // returns the quantity of rows updated;
    // throws exceptions for SQLite and other errors
    internal func updateRec(method:String, tableQuery:Table, cv:[Setter]) throws -> Int {
        if self.mDB == nil {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).updateRec", during: "self.mDB==nil", domain: self.mThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "DB table \(tableQuery.clauses.from.name)")
        }
        do {
            return try self.mDB!.run(tableQuery.update(cv))      // unlike Android, these do not return negatives for error conditions
        } catch {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).updateRec", during: "Run(Query)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: "DB table \(tableQuery.clauses.from.name)")
        }
    }
    
    // standard query to return the quantity of records found;
    // throws exceptions for SQLite and other errors
    internal func genericQueryQty(method:String, table:Table, whereStr:String?, valuesBindArray:[Binding?]?) throws -> Int64 {
        if self.mDB == nil {
            // do not error log this condition
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).genericQueryQty", during: "self.mDB==nil", domain: self.mThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "DB table \(table.clauses.from.name)")

        }
        var sql = "SELECT COUNT(*) FROM \(table.clauses.from.name)"
        if whereStr != nil { sql = sql + " WHERE " + whereStr! }
        do {
            var qty:Int64 = 0
            // unlike Android, these do not return negatives for error conditions
            if whereStr != nil && valuesBindArray != nil  { qty = try self.mDB!.scalar(sql, valuesBindArray!) as! Int64}
            else { qty = try self.mDB!.scalar(sql) as! Int64 }
            return qty
        } catch {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).genericQueryQty", during: "Scalar", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: "DB table \(table.clauses.from.name)")
        }
    }
    
    // standard query to get a set of found records
    // throws exceptions for SQLite and other errors
    internal func genericQuery(method:String, tableQuery:Table) throws -> AnySequence<Row> {
        if self.mDB == nil {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).genericQuery", during: "self.mDB==nil", domain: self.mThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "DB table \(tableQuery.clauses.from.name)")
        }
        do {
            return try self.mDB!.prepare(tableQuery)   // unlike Android, does not return nil
        } catch {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).genericQuery", during: "Prepare", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: "DB table \(tableQuery.clauses.from.name)")
        }
    }

    // standard query to get only the first found record
    // throws exceptions for SQLite and other errors
    internal func genericQueryOne(method:String, tableQuery:Table) throws -> Row? {
        if self.mDB == nil {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).genericQueryOne", during: "self.mDB==nil", domain: self.mThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "DB table \(tableQuery.clauses.from.name)")
        }
        do {
            return try self.mDB!.pluck(tableQuery)
        } catch {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).genericQueryOne", during: "Pluck", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: "DB table \(tableQuery.clauses.from.name)")
        }
    }
    
    // perform a delete of a record or records; works for all database tables;
    // throws exceptions for SQLite and other errors
    internal func genericDeleteRecs(method:String, tableQuery:Table) throws -> Int {
        if self.mDB == nil {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).genericDeleteRecs", during: "self.mDB==nil", domain: self.mThrowErrorDomain, errorCode: .HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo: "DB table \(tableQuery.clauses.from.name)")
        }
        do {
            return try self.mDB!.run(tableQuery.delete())   // unlike Android, does not return negative error codes
        } catch {
            throw APP_ERROR(funcName: "\(method):\(self.mCTAG).genericDeleteRecs", during: "Run(Delete)", domain: self.mThrowErrorDomain, error: error, errorCode: .DATABASE_ERROR, userErrorDetails: nil, developerInfo: "DB table \(tableQuery.clauses.from.name)")
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // The following methods perform exports and imports of organizational definitions
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // create a default Organization
    public func createDefaultOrg() throws -> RecOrganizationDefs {
        // create a default Organization
        var orgRec:RecOrganizationDefs
        do {
            orgRec = RecOrganizationDefs(org_code_sv_file: "Org1", org_title_mode: RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE, org_logo_image_png_blob: nil, org_email_to: nil, org_email_cc: nil, org_email_subject: "Contacts collected from eContact Collect")
            orgRec.rOrg_Visuals.rOrgTitle_Background_Color = UIColor.lightGray
            if AppDelegate.mDeviceLanguage != "en" {
                let _ = try orgRec.addNewFinalLangRec(forLangRegion: "en")
                try orgRec.setOrgTitleShown_Editing(langRegion: "en", title: "The Organization's Name")
            } else {
                try orgRec.setOrgTitleShown_Editing(langRegion: AppDelegate.mDeviceLangRegion, title: "The Organization's Name")
            }
            orgRec.mOrg_Lang_Recs_are_changed = true
            let _ = try orgRec.saveNewToDB()
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).createDefaultOrg")
            throw appError
        } catch { throw error }
        return orgRec
    }
    
    // create a default Form for an Organization
    public func createDefaultForm(forOrgRec: RecOrganizationDefs) throws -> RecOrgFormDefs {
        // create a default Organization
        var formRec:RecOrgFormDefs
        do {
            // create a default Form
            formRec = RecOrgFormDefs(org_code_sv_file: forOrgRec.rOrg_Code_For_SV_File, form_code_sv_file: "Form1")
            let _ = try formRec.saveNewToDB(withOrgRec: forOrgRec)     // allow all the default meta-data fields be auto-created
            
            // now add all the selected form fields
            var orderSVfile:Int = 10
            var orderShown:Int = 10
            try FieldHandler.shared.addFieldstoForm(field_IDCodes: ["FC_Name1st","FC_NameLast","FC_Email","FC_AddrAll","FC_PhFull"], forFormRec: formRec, withOrgRec: forOrgRec, orderSVfile: &orderSVfile, orderShown: &orderShown)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).createDefaultForm")
            throw appError
        } catch { throw error }
        return formRec
    }
    
    /* File structure -- loosely based upon Google's JSON Style Gude : https://raw.githubusercontent.com/google/styleguide/gh-pages/jsoncstyleguide.xml
     Format: JSON
     Filename:  org_config_for_xxx.eContactCollectConfig"
     Structure for entire Organization:
        apiVersion
        method = "eContactCollect.db.org.export"
        context = organization short name
        id
        data {
             created
             originOS
             appCode
             appName
             appVersion
             appBuild
             forDatabaseVersion
             languages
             tables {
                org:{
                    tableName:
                    item: {}
                 orgLangs:
                    tableName:
                    items: [{},...]
                 forms:
                     tableName:
                     items: [{},...]
                 formFields:
                     tableName:
                     items: [{},...]
                 formFieldLocales:
                     tableName:
                     items: [{},...]
                 customFields:
                     tableName:
                     items: [{},...]
                 customFieldLocales:
                     tableName:
                     items: [{},...]
                 fieldAttribLocales:
                     tableName:
                     items: [{},...]
             }
        }
     
     Filename:  form_config_for_xxx_of_xxx.eContactCollectConfig"
     Structure for entire Form within an Organization:
        :
        method = "eContactCollect.db.form.export"
        context = organization short name,form short name
            :
            tables {
                form:
                    tableName:
                    item: {}
                formFields:
                    tableName:
                    items: [{},...]
                formFieldLocales:
                    tableName:
                    items: [{},...]
                fieldAttribLocales:
                    tableName:
                    items: [{},...]
            }
    */
    // exports an organization's entire definition (languages, forms, formfields) to a JSON file in /Documents;
    // can also export just one form's entire definition (languages, forms, formfields) to a JSON file in /Documents;
    // returns the filename if successful, or throws if error;
    // throws exceptions for all errors; caller must post them to error.log and display them to the end-user;
    // Threading: this should be run in a Utility Thread instead of the UI Thread
    public static func exportOrgOrForm(forOrgShortName:String, forFormShortName:String?=nil) throws -> String {
        // first load the chosen Org record and other preps
        var funcString:String = "\(self.CTAG).exportOrgOrForm"
        var orgRec:RecOrganizationDefs? = nil
        var formRec:RecOrgFormDefs? = nil
        var formNames:String = ""
        do {
            orgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: forOrgShortName)
            if orgRec == nil {
                // this should not happen
                throw APP_ERROR(funcName: funcString, during: "orgGetSpecifiedRecOfShortName", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: NSLocalizedString("Export Preparation", comment:""), developerInfo: "orgRec == nil")
            }
            if forFormShortName != nil {
                // this is a form-only export
                funcString = funcString + ".formOnly"
                
                formRec = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName: forFormShortName!, forOrgShortName: forOrgShortName)
                if formRec == nil {
                    // this should not happen
                    throw APP_ERROR(funcName: funcString, during: "orgFormGetSpecifiedRecOfShortName", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .RECORD_NOT_FOUND, userErrorDetails: NSLocalizedString("Export Preparation", comment:""), developerInfo: "formRec == nil")
                }
            } else {
                // this is an entire-Org export
                try orgRec!.loadLangRecs(method: funcString)
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: funcString)
            throw appError
        } catch { throw error }
    
        let mydateFormatter = DateFormatter()
        mydateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        var foundFormLangRegions:[String] = []
        var jsonOrgObj:NSMutableDictionary? = nil
        var jsonOrgLangsObj:NSMutableDictionary? = nil
        var jsonFormsObj:NSMutableDictionary? = nil
        var jsonFormObj:NSMutableDictionary? = nil
        let jsonFormFieldsObj:NSMutableDictionary = NSMutableDictionary()
        let jsonFormFieldLocalesObj:NSMutableDictionary = NSMutableDictionary()
        let jsonOptionSetLocalesObj:NSMutableDictionary = NSMutableDictionary()
        do {
            if forFormShortName == nil {
                // build the Org's json object and validate it
                var jsonRecObj:NSMutableDictionary
                do {
                    jsonRecObj = try orgRec!.buildJSONObject()
                } catch var appError as APP_ERROR {
                    appError.prependCallStack(funcName: funcString)
                    throw appError
                } catch { throw error }
                
                jsonOrgObj = NSMutableDictionary()
                jsonOrgObj!["item"] = jsonRecObj
                jsonOrgObj!["tableName"] = RecOrganizationDefs.TABLE_NAME
                if !JSONSerialization.isValidJSONObject(jsonOrgObj!) {
                    throw APP_ERROR(funcName: funcString, during: "isValidJSONObject.jsonOrgObj", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Export Generation", comment:""))
                }
                
                // build the Org's Language records into json array and validate them all
                let jsonOrgLangsItemsObj:NSMutableArray = NSMutableArray()
                if orgRec!.mOrg_Lang_Recs != nil {
                    for orgLangRec in orgRec!.mOrg_Lang_Recs! {
                        let jsonOrgLangObj = orgLangRec.buildJSONObject()
                        jsonOrgLangsItemsObj.add(jsonOrgLangObj!)
                    }
                }
                jsonOrgLangsObj = NSMutableDictionary()
                jsonOrgLangsObj!["items"] = jsonOrgLangsItemsObj
                jsonOrgLangsObj!["tableName"] = RecOrganizationLangs.TABLE_NAME
                if !JSONSerialization.isValidJSONObject(jsonOrgLangsObj!) {
                    throw APP_ERROR(funcName: funcString, during: "isValidJSONObject.jsonOrgLangsObj", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Export Generation", comment:""))
                }
                
                // load and build all the Org's Form records into json array and validate them all
                let jsonFormsItemsObj:NSMutableArray = NSMutableArray()
                let records1:AnySequence<Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: forOrgShortName)
                for rowObj in records1 {
                    let orgFormRec:RecOrgFormDefs = try RecOrgFormDefs(row:rowObj)
                    let jsonFormObj = orgFormRec.buildJSONObject()
                    jsonFormsItemsObj.add(jsonFormObj!)
                    if formNames.isEmpty { formNames = orgFormRec.rForm_Code_For_SV_File }
                    else { formNames = formNames + "," + orgFormRec.rForm_Code_For_SV_File }
                }
                jsonFormsObj = NSMutableDictionary()
                jsonFormsObj!["items"] = jsonFormsItemsObj
                jsonFormsObj!["tableName"] = RecOrgFormDefs.TABLE_NAME
                if !JSONSerialization.isValidJSONObject(jsonFormsObj!) {
                    throw APP_ERROR(funcName: funcString, during: "isValidJSONObject.jsonFormsObj", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Export Generation", comment:""))
                }
            } else {
                // build the Form's json object and validate it
                let jsonRecObj = formRec!.buildJSONObject()
                jsonFormObj = NSMutableDictionary()
                jsonFormObj!["item"] = jsonRecObj!
                jsonFormObj!["tableName"] = RecOrgFormDefs.TABLE_NAME
                if !JSONSerialization.isValidJSONObject(jsonFormObj!) {
                    throw APP_ERROR(funcName: funcString, during: "isValidJSONObject.jsonFormObj", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Export Generation", comment:""))
                }
            }
            
            // load and build all the Org's or Form's FormField records into json array and validate them all
            let jsonFormFieldsItemsObj:NSMutableArray = NSMutableArray()
            let records2:AnySequence<Row> = try RecOrgFormFieldDefs.orgFormFieldGetAllRecs(forOrgShortName: forOrgShortName, forFormShortName: forFormShortName, sortedBySVFileOrder: false)
            for rowObj in records2 {
                let orgFormFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(row:rowObj)
                let jsonFormFieldObj = orgFormFieldRec.buildJSONObject()
                jsonFormFieldsItemsObj.add(jsonFormFieldObj!)
            }
            jsonFormFieldsObj["items"] = jsonFormFieldsItemsObj
            jsonFormFieldsObj["tableName"] = RecOrgFormFieldDefs.TABLE_NAME
            if !JSONSerialization.isValidJSONObject(jsonFormFieldsObj) {
                throw APP_ERROR(funcName: funcString, during: "isValidJSONObject.jsonFormFieldsObj", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Export Generation", comment:""))
            }
            
            // load and build all the Org's or Form's FormFieldLocale records into json array and validate them all
            let jsonFormFieldLocalesItemsObj:NSMutableArray = NSMutableArray()
            let records3:AnySequence<Row> = try RecOrgFormFieldLocales.formFieldLocalesGetAllRecs(forOrgShortName: forOrgShortName, forFormShortName: forFormShortName)
            for rowObj in records3 {
                let orgFormFieldLocaleRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(row:rowObj)
                let jsonFormFieldLocaleObj = orgFormFieldLocaleRec.buildJSONObject()
                jsonFormFieldLocalesItemsObj.add(jsonFormFieldLocaleObj!)
                if !foundFormLangRegions.contains(orgFormFieldLocaleRec.rFormFieldLoc_LangRegionCode) {
                    foundFormLangRegions.append(orgFormFieldLocaleRec.rFormFieldLoc_LangRegionCode)
                }
            }
            jsonFormFieldLocalesObj["items"] = jsonFormFieldLocalesItemsObj
            jsonFormFieldLocalesObj["tableName"] = RecOrgFormFieldLocales.TABLE_NAME
            if !JSONSerialization.isValidJSONObject(jsonFormFieldLocalesObj) {
                throw APP_ERROR(funcName: funcString, during: "isValidJSONObject.jsonFormFieldLocalesObj", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Export Generation", comment:""))
            }
            
            // load and build all the Org's CustomField records into json array and validate them all
            // ??
            
            // load and build all the Org's CustomFieldLocale records into json array and validate them all
            // ??
            
            // load and build all the custom OptionSetLocale records into json array and validate them all
            let jsonOptionSetLocalesItemsObj:NSMutableArray = NSMutableArray()
            let records6:AnySequence<Row> = try RecOptionSetLocales.optionSetLocalesGetAllRecs()
            for rowObj in records6 {
                let oslRec:RecOptionSetLocales = try RecOptionSetLocales(row:rowObj)
                let jsonOptionSetLocaleObj = oslRec.buildJSONObject()
                jsonOptionSetLocalesItemsObj.add(jsonOptionSetLocaleObj!)
            }
            jsonOptionSetLocalesObj["items"] = jsonOptionSetLocalesItemsObj
            jsonOptionSetLocalesObj["tableName"] = RecOptionSetLocales.TABLE_NAME
            if !JSONSerialization.isValidJSONObject(jsonOptionSetLocalesObj) {
                throw APP_ERROR(funcName: funcString, during: "isValidJSONObject.jsonOptionSetLocalesObj", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Export Generation", comment:""))
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: funcString)
            throw appError
        } catch { throw error }
        
        // convert the entire JSON object structure to a serialized textual file
        var filename:String
        if forFormShortName == nil { filename = "org_\(forOrgShortName).eContactCollectConfig" }
        else { filename = "form_\(forFormShortName!)_of_\(forOrgShortName).eContactCollectConfig" }
        let path = "\(AppDelegate.mDocsApp)/\(filename)"
        let stream = OutputStream(toFileAtPath: path, append: false)
        if stream == nil {
            throw APP_ERROR(funcName: funcString, during: "OutputStream create", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .COULD_NOT_CREATE, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
        }
        stream!.open()
        
        var str:String = "{\"apiVersion\":\"1.0\",\n"
        stream!.write(str, maxLength: str.count)
        if forFormShortName == nil {
            str = "\"method\":\"eContactCollect.db.org.export\",\n"
            stream!.write(str, maxLength: str.count)
            str = "\"context\":\"\(forOrgShortName);\(formNames)\",\n"
            stream!.write(str, maxLength: str.count)
        } else {
            str = "\"method\":\"eContactCollect.db.form.export\",\n"
            stream!.write(str, maxLength: str.count)
            str = "\"context\":\"\(forOrgShortName);\(forFormShortName!)\",\n"
            stream!.write(str, maxLength: str.count)
        }
        str = "\"id\":\"1\",\n"
        stream!.write(str, maxLength: str.count)
        str = "\"data\":{\n"
        stream!.write(str, maxLength: str.count)
        
        str = "  \"created\":\"\(mydateFormatter.string(from: Date()))\",\n"
        stream!.write(str, maxLength: str.count)
        str = "  \"originOS\":\"iOS\",\n"
        stream!.write(str, maxLength: str.count)
        str = "  \"appCode\":\"\(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String)\",\n"
        stream!.write(str, maxLength: str.count)
        str = "  \"appName\":\"\(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String)\",\n"
        stream!.write(str, maxLength: str.count)
        str = "  \"appVersion\":\"\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)\",\n"
        stream!.write(str, maxLength: str.count)
        str = "  \"appBuild\":\"\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)\",\n"
        stream!.write(str, maxLength: str.count)
        str = "  \"forDatabaseVersion\":\"\(DatabaseHandler.shared.getVersioning())\",\n"
        stream!.write(str, maxLength: str.count)
        if forFormShortName == nil {
            str = "  \"languages\":\"" + orgRec!.rOrg_LangRegionCodes_Supported.joined(separator: ",") + "\",\n"
            stream!.write(str, maxLength: str.count)
        } else {
            str = "  \"languages\":\"" + foundFormLangRegions.joined(separator: ",") + "\",\n"
            stream!.write(str, maxLength: str.count)
        }
        str = "  \"tables\":{\n"
        stream!.write(str, maxLength: str.count)

        var error:NSError?
        if forFormShortName == nil {
            str = "    \"org\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonOrgObj!, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonOrgObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
            }
            
            str = ",\n    \"orgLangs\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonOrgLangsObj!, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonOrgLangsObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
            }
            
            str = ",\n    \"forms\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonFormsObj!, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonFormsObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
            }
        } else {
            str = "    \"form\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonFormObj!, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonFormObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
            }
        }
        
        str = ",\n    \"formFields\":\n"
        stream!.write(str, maxLength: str.count)
        JSONSerialization.writeJSONObject(jsonFormFieldsObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
        if error != nil {
            stream!.close()
            throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonFormFieldsObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
        }
        
        str = ",\n    \"formFieldLocales\":\n"
        stream!.write(str, maxLength: str.count)
        JSONSerialization.writeJSONObject(jsonFormFieldLocalesObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
        if error != nil {
            stream!.close()
            throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonFormFieldLocalesObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
        }
        
        if forFormShortName == nil {
        /* ??
            str = ",\n    \"customFields\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonCustomFieldsObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonCustomFieldsObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
            }
            
            str = ",\n    \"customFieldLocales\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonCustomFieldLocalesObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonCustomFieldLocalesObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
            }*/
        }
        
        str = ",\n    \"optionSetLocales\":\n"
        stream!.write(str, maxLength: str.count)
        JSONSerialization.writeJSONObject(jsonOptionSetLocalesObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
        if error != nil {
            stream!.close()
            throw APP_ERROR(funcName: funcString, during: "writeJSONObject.jsonOptionSetLocalesObj", domain: DatabaseHandler.ThrowErrorDomain, error: error!, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Export File", comment:""), developerInfo: path)
        }
        
        str = "\n}}}\n"
        stream!.write(str, maxLength: str.count)
        stream!.close()
        return filename
    }
    
    // return structure for importOrgOrForm
    public enum ImportOrgOrFormLangMode { case NO_CHANGES_NEEDED, APPEND_MISSING_LANGS_TO_ORG, BEST_FIT }
    public struct ImportOrgOrForm_Result {
        public var wasFormOnly:Bool = false
        public var wasOrgShortName:String = ""
        public var wasFormShortName:String = ""
    }
    
    // Imports an eContactCollect configuration export file, either Org & Forms, or one Org's Form, or a Sample Form;
    // Default behavior:
    // - Org & Forms: if the Org short name is already present, it and all its sub records are deleted first
    // - Form-only:   if the Form short is already present, it and all its sub records are deleted first; Org must pre-exist
    // Overrides:
    // - Org & Forms: intoOrgShortName can override the file's Org name; asFormShortName is ignored
    // - Form-only:   intoOrgShortName can override the file's Org name, it is required if the file is a Sample Form;
    //                asFormShortName can override the file's Form name
    // throws exceptions for all errors (does not post them to error.log nor alert)
    public static func importOrgOrForm(fromFileAtPath:String, intoOrgShortName:String?, asFormShortName:String?, langMode:ImportOrgOrFormLangMode) throws -> ImportOrgOrForm_Result {
        var result:ImportOrgOrForm_Result = ImportOrgOrForm_Result()
        var funcString:String = "\(self.CTAG).importOrgOrForm"
        
        // get the file and its contents and do an initial validation
        let jsonContents = FileManager.default.contents(atPath: fromFileAtPath)   // obtain the data in JSON format
        if jsonContents == nil {
            throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .NOT_AN_EXPORTED_FILE, userErrorDetails: NSLocalizedString("Import File", comment:""))
        }
        var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
        do {
            validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents!, isFactory: false)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: funcString)
            throw appError
        } catch { throw error }
        let methodStr:String = validationResult.jsonTopLevel!["method"] as! String      // these are verified as present and have content
        let contextStr:String = validationResult.jsonTopLevel!["context"] as! String
        
        // validate the import type
        var userMsg:String = NSLocalizedString("Content Error: ", comment:"") + "1st " + NSLocalizedString("level improperly formatted", comment:"")
        var formOnlyMode:Bool = false
        if methodStr == "eContactCollect.db.org.export" {
            // do nothing
        } else if methodStr == "eContactCollect.db.form.export" {
            funcString = funcString + ".FormOnly"
            result.wasFormOnly = true
            formOnlyMode = true
        } else {
            throw APP_ERROR(funcName: funcString, during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Import File", comment:""), developerInfo: "'method' != acceptable values (\"\(methodStr)\"); " + fromFileAtPath)
        }
        
        // obtain and validate the context's information
        let nameComponents1 = contextStr.components(separatedBy: ";")
        if nameComponents1.count >= 2 {
            // new format of 'context' for Org & Forms:  Org;Form,Form,...
            // new format of 'context' for Form-only:    Org;Form        ;Form
            result.wasOrgShortName = nameComponents1[0]     // can be blank or nil at this stage if formOnlyMode
            if formOnlyMode {
                let nameComponents2 = nameComponents1[1].components(separatedBy: ",")
                result.wasFormShortName = nameComponents2[0]
            }
        } else {
            // old format of 'context' for Org & Forms:  Org
            // old format of 'context' for Form-only:    Org,Form
            let nameComponents2 = contextStr.components(separatedBy: ",")
            result.wasOrgShortName = nameComponents2[0]
            if formOnlyMode {
                if nameComponents2.count < 2 {
                    throw APP_ERROR(funcName: funcString, during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Import File", comment:""), developerInfo: "Form-only import; 'context'.components.count < 2 (\"\(contextStr)\"); " + fromFileAtPath)
                }
                result.wasFormShortName = nameComponents2[1]
            }
        }
        
        // any name overrides?
        if !(intoOrgShortName ?? "").isEmpty {
            result.wasOrgShortName = intoOrgShortName!
        }
        if formOnlyMode && !(asFormShortName ?? "").isEmpty {
            result.wasFormShortName = asFormShortName!
        }
        
        // is the import possible?
        if result.wasOrgShortName.isEmpty {
            // this is a user problem to resolve and should not be posted into the error.log
            throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .ORG_DOES_NOT_EXIST, userErrorDetails: NSLocalizedString("Into Organization short code has not been specified", comment:""))
        }

        // start importing; is this an entire Org import?
        var inx:Int = 1
        if !formOnlyMode {
            ///////////////////////////////
            // yes entire Org and its Forms
            ///////////////////////////////
            // import first the single Org record
            do {
                let getResult1:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "org", forTableName: RecOrganizationDefs.TABLE_NAME, needsItem: true, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult1.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")

                let tempNewOrgRec:RecOrganizationDefs_Optionals = RecOrganizationDefs_Optionals(jsonObj: getResult1.jsonItemLevel!, context: validationResult)
                tempNewOrgRec.rOrg_Code_For_SV_File = result.wasOrgShortName
                
                if !tempNewOrgRec.validate() {
                    var developer_error_message = "Validate \(getResult1.tableName) 'table' entries; ; record \(inx) did not validate"
                    if !(tempNewOrgRec.rOrg_Code_For_SV_File ?? "").isEmpty {
                        developer_error_message = developer_error_message + "; for \(tempNewOrgRec.rOrg_Code_For_SV_File!)"
                    }
                    throw APP_ERROR(funcName: funcString, during: "Validate \(getResult1.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                }
                let newOrgRec:RecOrganizationDefs = try RecOrganizationDefs(existingRec: tempNewOrgRec)
            
                // first delete the Org record if it pre-exists and its linked entries in every other table
                let _ = try RecOrganizationDefs.orgDeleteRec(orgShortName: newOrgRec.rOrg_Code_For_SV_File)
                let _ = try newOrgRec.saveNewToDB()
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // now all OrgLang records
            do {
                let getResult2:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "orgLangs", forTableName: RecOrganizationLangs.TABLE_NAME, needsItem: false, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult2.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                inx = 1
                for jsonItemObj in getResult2.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newOrgLangRecOpt:RecOrganizationLangs_Optionals = RecOrganizationLangs_Optionals(jsonObj: jsonItem!, context: validationResult)
                        newOrgLangRecOpt.rOrg_Code_For_SV_File = result.wasOrgShortName
                        if !newOrgLangRecOpt.validate() {
                            var developer_error_message = "record \(inx) did not validate"
                            if !(newOrgLangRecOpt.rOrgLang_LangRegionCode ?? "").isEmpty {
                                developer_error_message = developer_error_message + "; for \(newOrgLangRecOpt.rOrgLang_LangRegionCode!)"
                            }
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult2.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newOrgLangRec:RecOrganizationLangs = try RecOrganizationLangs(existingRec: newOrgLangRecOpt)
                        let _ = try newOrgLangRec.saveToDB()
                    }
                    inx = inx + 1
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // now all Form records
            do {
                let getResult3:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "forms", forTableName: RecOrgFormDefs.TABLE_NAME, needsItem: false, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult3.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                inx = 1
                for jsonItemObj in getResult3.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newFormRecOpt:RecOrgFormDefs_Optionals = RecOrgFormDefs_Optionals(jsonObj: jsonItem!, context: validationResult)
                        newFormRecOpt.rOrg_Code_For_SV_File = result.wasOrgShortName
                        if !newFormRecOpt.validate() {
                            var developer_error_message = "record \(inx) did not validate"
                            if !(newFormRecOpt.rForm_Code_For_SV_File ?? "").isEmpty {
                                developer_error_message = developer_error_message + "; for \(newFormRecOpt.rForm_Code_For_SV_File!)"
                            }
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult3.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newFormRec:RecOrgFormDefs = try RecOrgFormDefs(existingRec: newFormRecOpt)
                        let _ = try newFormRec.saveNewToDB(withOrgRec: nil) // do not auto-include the meta-data fields
                    }
                    inx = inx + 1
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // now all FormField records; note that all subfields need to be re-linked to the primary field's new index# so do this in two passes
            var remappingFFI:[Int64:Int64] = [:]
            do {
                let getResult4:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "formFields", forTableName: RecOrgFormFieldDefs.TABLE_NAME, needsItem: false, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult4.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                // first add all primary formfields
                inx = 1
                for jsonItemObj in getResult4.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newFormFieldRecOpt:RecOrgFormFieldDefs_Optionals = RecOrgFormFieldDefs_Optionals(jsonRecObj: jsonItem!, context: validationResult)
                        newFormFieldRecOpt.rOrg_Code_For_SV_File = result.wasOrgShortName
                        if formOnlyMode { newFormFieldRecOpt.rForm_Code_For_SV_File = result.wasFormShortName }
                        if !newFormFieldRecOpt.validate() {
                            var developer_error_message = "Validate \(getResult4.tableName) 'table' entries; ; record \(inx) did not validate"
                            if newFormFieldRecOpt.rFormField_Index != nil {
                                developer_error_message = developer_error_message + "; for \(newFormFieldRecOpt.rFormField_Index!)"
                            }
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult4.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newFormFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(existingRec: newFormFieldRecOpt)
                        if !newFormFieldRec.isSubFormField() {
                            let originalIndex = newFormFieldRec.rFormField_Index
                            newFormFieldRec.rFormField_Index = -1
                            newFormFieldRec.rFormField_Index = try newFormFieldRec.saveNewToDB()
                            remappingFFI[originalIndex] = newFormFieldRec.rFormField_Index
                        }
                    }
                    inx = inx + 1
                }
                // now add all subfields since the remapping of the primary fields is complete
                inx = 1
                for jsonItemObj in getResult4.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newFormFieldRecOpt:RecOrgFormFieldDefs_Optionals = RecOrgFormFieldDefs_Optionals(jsonRecObj: jsonItem!, context: validationResult)
                        newFormFieldRecOpt.rOrg_Code_For_SV_File = result.wasOrgShortName
                        if formOnlyMode { newFormFieldRecOpt.rForm_Code_For_SV_File = result.wasFormShortName }
                        if !newFormFieldRecOpt.validate() {
                            var developer_error_message = "record \(inx) did not validate"
                            if newFormFieldRecOpt.rFormField_Index != nil {
                                developer_error_message = developer_error_message + "; for \(newFormFieldRecOpt.rFormField_Index!)"
                            }
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult4.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newFormFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(existingRec: newFormFieldRecOpt)
                        if newFormFieldRec.isSubFormField() {
                            newFormFieldRec.rFormField_SubField_Within_FormField_Index = remappingFFI[newFormFieldRec.rFormField_SubField_Within_FormField_Index!]
                            let originalIndex = newFormFieldRec.rFormField_Index
                            newFormFieldRec.rFormField_Index = -1
                            newFormFieldRec.rFormField_Index = try newFormFieldRec.saveNewToDB()
                            remappingFFI[originalIndex] = newFormFieldRec.rFormField_Index
                        }
                    }
                    inx = inx + 1
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // now all FormFieldLocale records; note that every record needs to be re-linked to its corresponding RecOrgFormFieldDefs
            do {
                let getResult5:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "formFieldLocales", forTableName: RecOrgFormFieldLocales.TABLE_NAME, needsItem: false, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult5.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                inx = 1
                for jsonItemObj in getResult5.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newFormFieldLocaleOptRec:RecOrgFormFieldLocales_Optionals = RecOrgFormFieldLocales_Optionals(jsonObj: jsonItem!, context: validationResult)
                        newFormFieldLocaleOptRec.rOrg_Code_For_SV_File = result.wasOrgShortName
                        if formOnlyMode { newFormFieldLocaleOptRec.rForm_Code_For_SV_File = result.wasFormShortName }
                        if !newFormFieldLocaleOptRec.validate() {
                            var developer_error_message = "record \(inx) did not validate"
                            if newFormFieldLocaleOptRec.rFormFieldLoc_Index != nil {
                                developer_error_message = developer_error_message + "; for \(newFormFieldLocaleOptRec.rFormFieldLoc_Index!)"
                            }
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult5.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newFormFieldLocaleRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(existingRec: newFormFieldLocaleOptRec)
                        newFormFieldLocaleRec.rFormField_Index = remappingFFI[newFormFieldLocaleRec.rFormField_Index] ?? -1
                        newFormFieldLocaleRec.rFormFieldLoc_Index = -1
                        newFormFieldLocaleRec.rFormFieldLoc_Index = try newFormFieldLocaleRec.saveNewToDB()
                    }
                    inx = inx + 1
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // now all custom OptionSetLocale records;
            // ?? since these are not tagged by Organization there could be conflicts
            do {
                let getResult6:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "optionSetLocales", forTableName: RecOptionSetLocales.TABLE_NAME, needsItem: false, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult6.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                inx = 1
                for jsonItemObj in getResult6.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newOSLoptRec:RecOptionSetLocales_Optionals = RecOptionSetLocales_Optionals(jsonObj: jsonItem!, context: validationResult)
                        if !newOSLoptRec.validate() {
                            let developer_error_message = "record \(inx) did not validate"
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult6.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newOSLrec:RecOptionSetLocales = try RecOptionSetLocales(existingRec: newOSLoptRec)
                        let _ = try newOSLrec.saveNewToDB()
                    }
                    inx = inx + 1
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // ?? custom tables
        } else {
            ///////////////////////////////////
            // import just a single form record
            ///////////////////////////////////
            // is the import possible?
            if result.wasFormShortName.isEmpty {
                // this is a user problem to resolve and should not be posted into the error.log
                throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .FORM_DOES_NOT_EXIST, userErrorDetails: NSLocalizedString("As Form short code has not been specified", comment:""))
            }
            
            // find the target Organization's record
            var existingOrgRec:RecOrganizationDefs? = nil
            do {
                existingOrgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: result.wasOrgShortName)
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            if existingOrgRec == nil {
                // this is a user problem to resolve and should not be posted into the error.log
                throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .ORG_DOES_NOT_EXIST, userErrorDetails: NSLocalizedString("Organization for the Form must pre-exist: ", comment:"") + result.wasOrgShortName)
            }
            
            // import first the single Form record; do not save it yet as later code has throws
            var newFormRec:RecOrgFormDefs
            do {
                let getResult1:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "form", forTableName: RecOrgFormDefs.TABLE_NAME, needsItem: true, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult1.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                
                let newFormRecOpt:RecOrgFormDefs_Optionals = RecOrgFormDefs_Optionals(jsonObj: getResult1.jsonItemLevel!, context: validationResult)
                newFormRecOpt.rOrg_Code_For_SV_File = result.wasOrgShortName
                newFormRecOpt.rForm_Code_For_SV_File = result.wasFormShortName
                inx = 1
                if !newFormRecOpt.validate() {
                    var developer_error_message = "record \(inx) did not validate"
                    if !(newFormRecOpt.rForm_Code_For_SV_File ?? "").isEmpty {
                        developer_error_message = developer_error_message + "; for \(newFormRecOpt.rForm_Code_For_SV_File!)"
                    }
                    throw APP_ERROR(funcName: funcString, during: "Validate \(getResult1.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                }
                newFormRec = try RecOrgFormDefs(existingRec: newFormRecOpt)
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // now build up an OrgFormFields of all Form Fields and their Locales; these are not yet saved into the database; this will include the meta fields
            let sourceFormFields:OrgFormFields = OrgFormFields()
            do {
                let getResult4:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "formFields", forTableName: RecOrgFormFieldDefs.TABLE_NAME, needsItem: false, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult4.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                // first retain all formfields; they retain their index# integrity from the origin form at this stage
                inx = 1
                for jsonItemObj in getResult4.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newFormFieldRecOpt:RecOrgFormFieldDefs_Optionals = RecOrgFormFieldDefs_Optionals(jsonRecObj: jsonItem!, context: validationResult)
                        newFormFieldRecOpt.rOrg_Code_For_SV_File = result.wasOrgShortName
                        if formOnlyMode { newFormFieldRecOpt.rForm_Code_For_SV_File = result.wasFormShortName }
                        if !newFormFieldRecOpt.validate() {
                            var developer_error_message = "Validate \(getResult4.tableName) 'table' entries; ; record \(inx) did not validate"
                            if newFormFieldRecOpt.rFormField_Index != nil {
                                developer_error_message = developer_error_message + "; for \(newFormFieldRecOpt.rFormField_Index!)"
                            }
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult4.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newFormFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(existingRec: newFormFieldRecOpt)
                        let entry:OrgFormFieldsEntry = OrgFormFieldsEntry(formFieldRec: newFormFieldRec, composedFormFieldLocalesRec: RecOrgFormFieldLocales_Composed(), composedOptionSetLocalesRecs: nil)
                        sourceFormFields.appendFromDatabase(entry)
                    }
                    inx = inx + 1
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // now all FormFieldLocale records; note that every record needs to be inserted into its corresponding RecOrgFormFieldDefs
            do {
                let getResult5:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "formFieldLocales", forTableName: RecOrgFormFieldLocales.TABLE_NAME, needsItem: false, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult5.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                inx = 1
                for jsonItemObj in getResult5.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newFormFieldLocaleOptRec:RecOrgFormFieldLocales_Optionals = RecOrgFormFieldLocales_Optionals(jsonObj: jsonItem!, context: validationResult)
                        newFormFieldLocaleOptRec.rOrg_Code_For_SV_File = result.wasOrgShortName
                        if formOnlyMode { newFormFieldLocaleOptRec.rForm_Code_For_SV_File = result.wasFormShortName }
                        if !newFormFieldLocaleOptRec.validate() {
                            var developer_error_message = "record \(inx) did not validate"
                            if newFormFieldLocaleOptRec.rFormFieldLoc_Index != nil {
                                developer_error_message = developer_error_message + "; for \(newFormFieldLocaleOptRec.rFormFieldLoc_Index!)"
                            }
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult5.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newFormFieldLocaleRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(existingRec: newFormFieldLocaleOptRec)
                        sourceFormFields.includeLocaleFromDatabase(rec: newFormFieldLocaleRec)
                    }
                    inx = inx + 1
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // now make all the source form fields into new target form fields by assigning temporary index#s plus all the subfield cross-linking
            let newTargetFormFields:OrgFormFields = OrgFormFields()
            newTargetFormFields.appendNewDuringEditing(fromFormFields: sourceFormFields, forOrgCode: existingOrgRec!.rOrg_Code_For_SV_File, forFormCode: newFormRec.rForm_Code_For_SV_File)
            
            // now make a first assessment of languages
            var langResults:FieldHandler.AssessLangRegions_Results = FieldHandler.assessLangRegions(sourceEntries: newTargetFormFields, targetOrgRec: existingOrgRec!, targetFormRec: newFormRec)
            if langResults.mode == .IMPOSSIBLE && langMode != .APPEND_MISSING_LANGS_TO_ORG {
                throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .NO_MATCHING_LANGREGIONS, userErrorDetails: NSLocalizedString("Import File", comment:""))
            }
            if langMode == .APPEND_MISSING_LANGS_TO_ORG && langResults.mode != .NO_CHANGES_NEEDED && langResults.unmatchedSourceLangRegions.count > 0 {
                do {
                    // add missing source languages into the Org record
                    for langRegion in langResults.unmatchedSourceLangRegions {
                        let _ = try existingOrgRec!.addNewFinalLangRec(forLangRegion: langRegion)
                    }
                    // save the updated Org record into the database
                    let _ = try existingOrgRec!.saveChangesToDB(originalOrgRec: existingOrgRec!)
                } catch var appError as APP_ERROR {
                    appError.prependCallStack(funcName: funcString)
                    throw appError
                } catch { throw error }
                
                // re-assess now that Org has all the necessary languages
                langResults = FieldHandler.assessLangRegions(sourceEntries: newTargetFormFields, targetOrgRec: existingOrgRec!, targetFormRec: newFormRec)
            }
            
            // now perform language changes if needed
            assert(langResults.mode != .IMPOSSIBLE, "langResults.mode == .IMPOSSIBLE")
            if langResults.mode != .NO_CHANGES_NEEDED {
                for formFieldEntry in newTargetFormFields {
                    FieldHandler.shared.adjustLangRegions(results: langResults, forEntry: formFieldEntry, targetOrgRec: existingOrgRec!, targetFormRec: newFormRec)
                }
            }
            
            // store the Form record itself into the database;
            // first delete the Form record if it pre-exists and its linked entries in every other table
            do {
                let _ = try RecOrgFormDefs.orgFormDeleteRec(formShortName: newFormRec.rForm_Code_For_SV_File, forOrgShortName: newFormRec.rOrg_Code_For_SV_File)
                let _ = try newFormRec.saveNewToDB(withOrgRec: nil)    // do not auto-include the meta-data fields
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // then store all the form-fields and their locales into the database
            for formFieldEntry in newTargetFormFields {
                do {
                    let _ = try formFieldEntry.mFormFieldRec.saveNewToDB()     // this will auto-save all retained RecOrgFormFieldLocales
                } catch var appError as APP_ERROR {
                    appError.prependCallStack(funcName: funcString)
                    throw appError
                } catch { throw error }
            }
            
            // now all custom OptionSetLocale records;
            // ?? since these are not tagged by Organization there could be conflicts; language conflicts as well
            do {
                let getResult6:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "optionSetLocales", forTableName: RecOptionSetLocales.TABLE_NAME, needsItem: false, priorResult: validationResult)
                userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult6.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
                inx = 1
                for jsonItemObj in getResult6.jsonItemsLevel! {
                    let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                    if jsonItem != nil {
                        let newOSLoptRec:RecOptionSetLocales_Optionals = RecOptionSetLocales_Optionals(jsonObj: jsonItem!, context: validationResult)
                        if !newOSLoptRec.validate() {
                            let developer_error_message = "record \(inx) did not validate"
                            throw APP_ERROR(funcName: funcString, during: "Validate \(getResult6.tableName) 'table' entries", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                        }
                        let newOSLrec:RecOptionSetLocales = try RecOptionSetLocales(existingRec: newOSLoptRec)
                        let _ = try newOSLrec.saveNewToDB()
                    }
                    inx = inx + 1
                }
            } catch var appError as APP_ERROR {
                appError.prependCallStack(funcName: funcString)
                throw appError
            } catch { throw error }
            
            // ?? custom tables
        }
        return result
    }
    
    // return structure for validateJSONdbFile
    public struct ValidateJSONdbFile_Result {
        public var databaseVersion:Int64 = 0
        public var languages:[String] = []
        
        // top level contains: "apiVersion","method","context","id","data"
        public var jsonTopLevel:[String:Any?]? = nil
        
        // contents of data: "created", "originOS", "appCode", "appName", "appVersion", "appBuild", "forDatabaseVersion", "language", "tables"
        public var jsonDataLevel:[String:Any?]? = nil
        
        // contents of tables: "org", "orgLangs", "form", "forms", "formFields", "formFieldLocales", "customFields", "customFieldLocales", "fieldAttribLocales", "fieldAttribLocales_packed"
        public var jsonTablesLevel:[String:Any?]? = nil
    }
    
    // validate the header of a JSON database export file;
    // this method only throws errors; it does NOT post them to error.log
    public static func validateJSONdbFile(contents:Data, isFactory:Bool) throws -> ValidateJSONdbFile_Result {
        var result:ValidateJSONdbFile_Result = ValidateJSONdbFile_Result()
        var userErrorMsg:String = NSLocalizedString("Content Error: ", comment:"") + NSLocalizedString("File improperly formatted", comment:"")
        var jsonData:Any? = nil
        do {
            jsonData = try JSONSerialization.jsonObject(with: contents, options: .allowFragments)
        } catch {
            if isFactory {
                throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "JSON Parse", domain: DatabaseHandler.ThrowErrorDomain, error: error, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: nil)
            } else {
                throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .NOT_AN_EXPORTED_FILE, userErrorDetails: userErrorMsg)
            }
        }
        
        // first check whether this is an eContactCollect file in the first place
        result.jsonTopLevel = jsonData as? [String:Any?]
        userErrorMsg = NSLocalizedString("Content Error: ", comment:"") + "1st " + NSLocalizedString("level improperly formatted", comment:"")
        if result.jsonTopLevel == nil {
            if isFactory {
                throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is not NSDictionary")
            } else {
                throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .NOT_AN_EXPORTED_FILE, userErrorDetails: userErrorMsg)
            }
        } else if (result.jsonTopLevel!["method"] as? String) == nil {
            if isFactory {
                throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing 'method'")
            } else {
                throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .NOT_AN_EXPORTED_FILE, userErrorDetails: userErrorMsg)
            }
        } else if (result.jsonTopLevel!["method"] as! String).isEmpty {
            if isFactory {
                throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level 'method' isEmpty")
            } else {
                throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .NOT_AN_EXPORTED_FILE, userErrorDetails: userErrorMsg)
            }
        } else if !((result.jsonTopLevel!["method"] as! String).starts(with: "eContactCollect.db.")) {
            if isFactory {
                throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "'method' prefix is incorrect: \((result.jsonTopLevel!["method"] as! String))")
            } else {
                throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .NOT_AN_EXPORTED_FILE, userErrorDetails: userErrorMsg)
            }
        }
        
        // it is, so most remaining errors are APP_ERRORS, with one exception
        if (result.jsonTopLevel!["apiVersion"] as? String) == nil || (result.jsonTopLevel!["context"] as? String) == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing 'apiVersion' or 'context'")
        } else if (result.jsonTopLevel!["context"] as! String).isEmpty {
            throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level 'context' isEmpty")
        } else if (result.jsonTopLevel!["apiVersion"] as! String) != "1.0" {
            throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate top level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "'apiVersion' is incorrect: \(result.jsonTopLevel!["apiVersion"] as! String)")
        }

        userErrorMsg = NSLocalizedString("Content Error: ", comment:"") + "2nd " + NSLocalizedString("level improperly formatted", comment:"")
        result.jsonDataLevel = result.jsonTopLevel!["data"] as? [String:Any?]
        if result.jsonDataLevel == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate 'data' level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is not NSDictionary")
        } else if (result.jsonDataLevel!["forDatabaseVersion"] as? String) == nil || (result.jsonDataLevel!["tables"] as? [String:Any?]) == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate 'data' level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing 'forDatabaseVersion', 'tables'")
        }
        result.databaseVersion = Int64((result.jsonDataLevel!["forDatabaseVersion"] as! String)) ?? 0
        
        if let hasLang:String = (result.jsonDataLevel!["language"] as? String) {
            // factory json files as well as older export files (which do not have their languages recorded in the header)
            if hasLang != "$$" { result.languages.append(hasLang) }
        } else if let hasLangs:String = (result.jsonDataLevel!["languages"] as? String) {
            // newer export files
            result.languages = hasLangs.components(separatedBy: ",")
        } else {
            throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate 'data' level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing 'language', 'languages'")
        }
        
        // this logic needs to be revised as the database version grows;
        // this app can import up-to the indicated database version below
        if result.databaseVersion > DatabaseHandler.mDATABASE_VERSION {
            userErrorMsg = NSLocalizedString("File DB version ", comment:"") + String(result.databaseVersion) + NSLocalizedString("> App's DB version ", comment:"") + String(DatabaseHandler.mDATABASE_VERSION)
            throw USER_ERROR(domain: DatabaseHandler.ThrowErrorDomain, errorCode: .VERSION_TOO_NEW, userErrorDetails: userErrorMsg)
        }

        userErrorMsg = NSLocalizedString("Content Error: ", comment:"") + "3rd " + NSLocalizedString("level improperly formatted", comment:"")
        result.jsonTablesLevel = result.jsonDataLevel!["tables"] as? [String:Any?]
        if result.jsonTablesLevel == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).validateJSONdbFile", during: "Validate 'tables' level", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "'tables' is missing or not NSDictionary")
        }
        return result
    }
    
    // return structure for getJSONdbFileTable
    public struct GetJSONdbFileTable_Result {
        public var tableName:String = ""
        
        // top level contains: "tableName","item","items"
        public var jsonTableLevel:[String:Any?]? = nil
        
        // contents of item: single JSON record
        public var jsonItemLevel:NSDictionary? = nil
        
        // contents of items: array of JSON object records
        public var jsonItemsLevel:NSArray? = nil
    }
    
    // validate the a table subheader of a JSON database export file;
    // this method only throws errors; it does NOT post them to error.log
    public static func getJSONdbFileTable(forTableCode:String, forTableName:String, needsItem:Bool, priorResult:ValidateJSONdbFile_Result) throws -> GetJSONdbFileTable_Result {
        var result:GetJSONdbFileTable_Result = GetJSONdbFileTable_Result()
        let userErrorMsg:String = NSLocalizedString("Content Error: ", comment:"") + "\(forTableCode): " + "4th " + NSLocalizedString("level improperly formatted", comment:"")
        let duringMsg:String = "Validate \(forTableCode) 'table' level"

        result.jsonTableLevel = priorResult.jsonTablesLevel![forTableCode] as? [String:Any?]
        if result.jsonTableLevel == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).getJSONdbFileTable", during: duringMsg, domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing or not NSDictionary")
        } else if (result.jsonTableLevel!["tableName"] as? String) == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).getJSONdbFileTable", during: duringMsg, domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing 'tableName' key")
        } else if result.jsonTableLevel!["tableName"] as! String != forTableName {
            throw APP_ERROR(funcName: "\(self.CTAG)).getJSONdbFileTable", during: duringMsg, domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level 'tableName' needed \(forTableName) and is incorrect: \(result.jsonTableLevel!["tableName"] as! String)")
        }
    
        result.tableName = (result.jsonTableLevel!["tableName"] as! String)
        result.jsonItemLevel = result.jsonTableLevel!["item"] as? NSDictionary
        result.jsonItemsLevel = result.jsonTableLevel!["items"] as? NSArray
        
        if result.jsonItemLevel == nil && result.jsonItemsLevel == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).getJSONdbFileTable", during: duringMsg, domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing both 'item' and 'items'")
        } else if needsItem && result.jsonItemLevel == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).getJSONdbFileTable", during: duringMsg, domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing 'item'")
        } else if !needsItem && result.jsonItemsLevel == nil {
            throw APP_ERROR(funcName: "\(self.CTAG)).getJSONdbFileTable", during: duringMsg, domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: userErrorMsg, developerInfo: "Level is missing 'items'")
        }
        return result
    }
}
