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

// base handler class for the all the database handlers
public class DatabaseHandler {
    // member variables
    public var mDB:Connection? = nil
    public var mVersion:Int64 = 0
    public var mDBstatus_state:HandlerStatusStates = .Unknown
    public var mAppError:APP_ERROR? = nil

    // member constants and other static content
    internal static let CTAG:String = "HBD"
    internal let mCTAG:String = CTAG
    public static let ThrowErrorDomain:String = NSLocalizedString("DatabaseHandler", comment:"")
    private let mThrowErrorDomain:String = ThrowErrorDomain
    internal let mDATABASE_NAME:String = "eContactCollect_DB.sqlite"
    internal var mDATABASE_VERSION:Int64 = 1    // WARNING: changing this value will cause invocation of init_onUpgrade

    // constructor;
    public init() {}
    
    // initialization; returns true if initialize fully succeeded; errors are stored via the class members
    public func initialize() -> Bool {
//debugPrint("\(mCTAG).initialize STARTED")
        // define where the database will be; this App exposes the Documents folder to iTunes and the Files APP so the database should be in Library
        let fullPath = "\(AppDelegate.mLibApp)/\(self.mDATABASE_NAME)"
        self.mDBstatus_state = .Unknown
        self.mAppError = nil

#if TESTING
        // delete the temporary database so its always empty
        do {
            try FileManager.default.removeItem(atPath: fullPath)
        } catch {}
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
            self.mAppError = APP_ERROR(during: NSLocalizedString("Connection", comment:""), domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).initialize", during: "Connection", errorStruct: error, extra: fullPath, noAlert: true)
            return false
        }
        if self.mDB == nil {
            // this should never happen as Connection does not return a nil
            self.mDBstatus_state = .Errors
            self.mAppError = APP_ERROR(during: NSLocalizedString("Connection", comment:""), domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: NSLocalizedString("Unknown error", comment:""))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).initialize", during:"Connection", errorMessage:"Failed: self.mDB == nil; unknown error", extra:fullPath, noAlert:true)
            return false
        }
        
        // Connection to a new-empty or existing database succeeded
        if !alreadyExists {
            // database file did not previously exist, so initialize it as new
            if !self.init_onNew() { return false }
        } else {
            // database file did already exist, so get its internal database version code
            do {
                self.mVersion = try self.mDB!.getUserVersion()
            } catch {
                self.mDBstatus_state = .Invalid
                self.mAppError = APP_ERROR(during: NSLocalizedString("Verification", comment:""), domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
                AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).initialize", during:"getUserVersion", errorStruct:error, extra:fullPath, noAlert:true)
                return false
            }
            
            // now check if it needs an upgrade to the database version this App version neeeds
            if self.mVersion != self.mDATABASE_VERSION {
                // database version number does not match this App version's expectation of database version; activate the upgrade process to resolve it
                self.mDBstatus_state = .Obsolete
                if !self.init_onUpgrade(currentVersion: self.mVersion, targetVersion: self.mDATABASE_VERSION) { return false }
            } else {
                self.mDBstatus_state = .Valid
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
    internal func init_onNew() -> Bool {
//debugPrint("\(mCTAG).init_onNew STARTED TO INITIALIZE NEW DATABASE")
        if !self.createAlertsTable() { return false }
        if !self.createOrganizationDefsTable() { return false }
        if !self.createOrganizationLangsTable() { return false }
        if !self.createOrgFormDefsTable() { return false }
        if !self.createOrgFormFieldDefsTable() { return false }
        if !self.createOrgFormFieldLocalesTable() { return false }
        if !self.createOptionSetLocalesTable() { return false }
        //??if !self.createOrgCustomFieldDefsTable() { return false }
        //??if !self.createOrgCustomFieldLocalesTable() { return false }
        if !self.createContactsCollectedTable() { return false }
        
        // all succeeded; set the versioning properly
        do {
            try self.mDB!.setUserVersion(newVersion: self.mDATABASE_VERSION)
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Initialization", comment:""), domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).init_onNew", during:"setUserVersion", errorStruct:error, extra:self.mDATABASE_NAME)
            return false
        }
        
        // all good; finalize
        self.mVersion = self.mDATABASE_VERSION
        self.mDBstatus_state = .Valid
        return true
    }
    
    // called only when the database 'user_version' does not match the expected version;
    // perform the necessary upgrade actions
    internal func init_onUpgrade(currentVersion:Int64, targetVersion:Int64) -> Bool {
        self.mVersion = currentVersion
        
        // placeholder for future database upgrade actions;
        // attempt to post upgrade failures into the Alerts
        
        // all succeeded; set the versioning properly
        do {
            try self.mDB!.setUserVersion(newVersion: self.mDATABASE_VERSION)
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Upgrade", comment:""), domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).init_onNew", during:"setUserVersion", errorStruct:error, extra:self.mDATABASE_NAME)
            return false
        }
        
        // all good; finalize
        self.mVersion = self.mDATABASE_VERSION
        self.mDBstatus_state = .Valid
        return true
    }
    
    // perform any App first time setups that have not already been performed;
    // the database handler must be especially mindful that it may not have properly initialized and should bypass this
    public func firstTimeSetup() throws {
//debugPrint("\(mCTAG).firstTimeSetup STARTED")
        // none at this time
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
            self.mAppError = APP_ERROR(during: NSLocalizedString("Factory Reset", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).factoryResetEntireDB", during:"removeItem", errorStruct:error, extra:fullPath, noAlert:true)
            return false
        }
        
        // re-create and rebuild the database
        self.mDBstatus_state = .Missing
        return self.initialize()
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Table creation methods
    /////////////////////////////////////////////////////////////////////////
    
    // create the alerts table
    private func createAlertsTable() -> Bool {
        do {
            try self.mDB!.run(RecAlert.generateCreateTableString())
            return true
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Create", comment:"") + " \(RecAlert.TABLE_NAME)", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createAlertsTable", during:"Run(Create)", errorStruct:error, extra:"DB table \(RecAlert.TABLE_NAME)", noAlert:true)
            return false
        }
    }
    
    // create the organizations table
    private func createOrganizationDefsTable() -> Bool {
        do {
            try self.mDB!.run(RecOrganizationDefs.generateCreateTableString())
            return true
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Create", comment:"") + " \(RecOrganizationDefs.TABLE_NAME)", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createOrganizationDefsTable", during:"Run(Create)", errorStruct:error, extra:"DB table \(RecOrganizationDefs.TABLE_NAME)", noAlert:true)
            return false
        }
    }
    
    // create the organization languagess table
    private func createOrganizationLangsTable() -> Bool {
        do {
            try self.mDB!.run(RecOrganizationLangs.generateCreateTableString())
            return true
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Create", comment:"") + " \(RecOrganizationLangs.TABLE_NAME)", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createOrganizationLangsTable", during:"Run(Create)", errorStruct:error, extra:"DB table \(RecOrganizationLangs.TABLE_NAME)", noAlert:true)
            return false
        }
    }
    
    // create the organization forms table
    private func createOrgFormDefsTable() -> Bool {
        do {
            try self.mDB!.run(RecOrgFormDefs.generateCreateTableString())
            return true
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Create", comment:"") + " \(RecOrgFormDefs.TABLE_NAME)", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createOrgCollectFormDefsTable", during:"Run(Create)", errorStruct:error, extra:"DB table \(RecOrgFormDefs.TABLE_NAME)", noAlert:true)
            return false
        }
    }
    
    // create the organization form fields table
    private func createOrgFormFieldDefsTable() -> Bool {
        do {
            try self.mDB!.run(RecOrgFormFieldDefs.generateCreateTableString())
            return true
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Create", comment:"") + " \(RecOrgFormFieldDefs.TABLE_NAME)", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createOrgCollectFormFieldDefsTable", during:"Run(Create)", errorStruct:error, extra:"DB table \(RecOrgFormFieldDefs.TABLE_NAME)", noAlert:true)
            return false
        }
    }
    
    // create the organization form fields table
    private func createOrgFormFieldLocalesTable() -> Bool {
        do {
            try self.mDB!.run(RecOrgFormFieldLocales.generateCreateTableString())
            return true
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Create", comment:"") + " \(RecOrgFormFieldLocales.TABLE_NAME)", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createOrgFormFieldLocalesTable", during:"Run(Create)", errorStruct:error, extra:"DB table \(RecOrgFormFieldLocales.TABLE_NAME)", noAlert:true)
            return false
        }
    }
    
    // create the fields table
    /*??private func createOrgCustomFieldDefsTable() -> Bool {
        do {
            try self.mDB!.run(RecOrgCustomFieldDefs.generateCreateTableString())
            return true;
        } catch {
            self.mDBstatus_state = .Invalid
            self.mDBstatus_user_message = "\(NSLocalizedString("Create database table failed",comment:"")): [\(RecOrgCustomFieldDefs.TABLE_NAME)]: \(error._domain) \(NSLocalizedString("ErrCode",comment:""))=\(error._code)"
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createOrgCustomFieldDefsTable", during:"Run(Create)", errorType:error, extra:"DB table \(RecOrgCustomFieldDefs.TABLE_NAME)", noAlert:true)
        }
        return false;
    }
    
    // create the fields table
    private func createOrgCustomFieldLocalesTable() -> Bool {
        do {
            try self.mDB!.run(RecOrgCustomFieldLocales.generateCreateTableString())
            return true;
        } catch {
            self.mDBstatus_state = .Invalid
            self.mDBstatus_user_message = "\(NSLocalizedString("Create database table failed",comment:"")): [\(RecOrgCustomFieldLocales.TABLE_NAME)]: \(error._domain) \(NSLocalizedString("ErrCode",comment:""))=\(error._code)"
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createOrgCustomFieldLocalesTable", during:"Run(Create)", errorType:error, extra:"DB table \(RecOrgCustomFieldLocales.TABLE_NAME)", noAlert:true)
        }
        return false;
    }*/
    
    // create the optionSet locales table
    private func createOptionSetLocalesTable() -> Bool {
        do {
            try self.mDB!.run(RecOptionSetLocales.generateCreateTableString())
            return true
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Create", comment:"") + " \(RecOptionSetLocales.TABLE_NAME)", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createOptionSetLocalesTable", during:"Run(Create)", errorStruct:error, extra:"DB table \(RecOptionSetLocales.TABLE_NAME)", noAlert:true)
            return false
        }
    }
    
    // create the contacts collected table
    private func createContactsCollectedTable() -> Bool {
        do {
            try self.mDB!.run(RecContactsCollected.generateCreateTableString())
            return true
        } catch {
            self.mDBstatus_state = .Invalid
            self.mAppError = APP_ERROR(during: NSLocalizedString("Create", comment:"") + " \(RecContactsCollected.TABLE_NAME)", domain: self.mThrowErrorDomain, errorCode: .DATABASE_ERROR, userErrorDetails: AppDelegate.endUserErrorMessage(errorStruct: error))
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).createContactsCollectedTable", during:"Run(Create)", errorStruct:error, extra:"DB table \(RecContactsCollected.TABLE_NAME)", noAlert:true)
            return false
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // The following methods perform write or delete record operation for the rest of the App
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // perform an insert of a new record (optionally replace an existing one); works for all database tables;
    // throws exceptions for SQLite errors after logging them
    // returns the rowID that was inserted (or replaced); remember for some records the rowID is an OID and most negative values are acceptable
    internal func insertRec(method:String, table:Table, cv:[Setter], orReplace:Bool, noAlert:Bool) throws -> Int64 {
        if self.mDB == nil {
            // do not error log this condition
            throw APP_ERROR(during:method, domain:self.mThrowErrorDomain, errorCode:.HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo:"\(self.mCTAG).insertRec self.mDB == nil")
        }
        var duringdText:String = "Run(Insert"
        if orReplace { duringdText = duringdText + "|Replace" }
        duringdText = duringdText + ")"
        do {
            // unlike Android, these do not return negatives for error conditions
            if orReplace { return try self.mDB!.run(table.insert(or: .replace, cv)) }
            else { return try self.mDB!.run(table.insert(cv)) }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).insertRecs: \(method)", during:duringdText, errorStruct:error, extra:"DB table \(table.clauses.from.name)", noAlert:noAlert)
            throw error
        }
    }
    
    // perform an update of selected fields in an existing record; !!will not add the record if it does not exist!!; works for all database tables;
    // !!a query MUST be supplied else all records will get updated!!
    // throws exceptions for SQLite errors after logging them
    // returns the quantity of rows updated
    internal func updateRec(method:String, tableQuery:Table, cv:[Setter]) throws -> Int {
        if self.mDB == nil {
            // do not error log this condition
            throw APP_ERROR(during:method, domain:self.mThrowErrorDomain, errorCode:.HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo:"\(self.mCTAG).updateRec self.mDB == nil")
        }
        do {
            return try self.mDB!.run(tableQuery.update(cv))      // unlike Android, these do not return negatives for error conditions
        } catch {
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).updateRecs: \(method)", during:"Run(Query)", errorStruct:error, extra:"DB table \(tableQuery.clauses.from.name)")
            throw error
        }
    }
    
    // standard query to return the quantity of records found
    // throws exceptions for SQLite errors after logging them
    internal func genericQueryQty(method:String, table:Table, whereStr:String?, valuesBindArray:[Binding?]?) throws -> Int64 {
        if self.mDB == nil {
            // do not error log this condition
            throw APP_ERROR(during:method, domain:self.mThrowErrorDomain, errorCode:.HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo:"\(self.mCTAG).genericQueryQty self.mDB == nil")
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
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).genericQueryQty: \(method)", during:"Scalar", errorStruct:error, extra:"DB table \(table.clauses.from.name)")
            throw error
        }
    }
    
    // standard query to get a set of found records
    // throws exceptions for SQLite errors after logging them
    internal func genericQuery(method:String, tableQuery:Table) throws -> AnySequence<Row> {
        if self.mDB == nil {
            // do not error log this condition
            throw APP_ERROR(during:method, domain:self.mThrowErrorDomain, errorCode:.HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo:"\(self.mCTAG).genericQuery self.mDB == nil")
        }
        do {
            return try self.mDB!.prepare(tableQuery)   // unlike Android, does not return nil
        } catch {
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).genericQuery.tableQuery: \(method)", during:"Prepare", errorStruct:error, extra:"DB table \(tableQuery.clauses.from.name), SQL: \(tableQuery.asSQL())")
            throw error
        }
    }
    /*internal func genericQuery(method:String, table:Table, columns:[String]?, whereStr:String?, valuesBindArray:[Binding?]?, sortOrder:[String]?) throws -> AnySequence<Row> {
     }*/
    
    // standard query to get only the first found record
    // throws exceptions for SQLite errors after logging them
    internal func genericQueryOne(method:String, tableQuery:Table) throws -> Row? {
        if self.mDB == nil {
            // do not error log this condition
            throw APP_ERROR(during:method, domain:self.mThrowErrorDomain, errorCode:.HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo:"\(self.mCTAG).genericQueryOne self.mDB == nil")
        }
        do {
            return try self.mDB!.pluck(tableQuery)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).genericQueryOne: \(method)", during:"Pluck", errorStruct:error, extra:"DB table \(tableQuery.clauses.from.name)")
            throw error
        }
    }
    
    // perform a delete of a record or records; works for all database tables;
    // throws exceptions for SQLite errors after logging them
    internal func genericDeleteRecs(method:String, tableQuery:Table) throws -> Int {
        if self.mDB == nil {
            // do not error log this condition
            throw APP_ERROR(during:method, domain:self.mThrowErrorDomain, errorCode:.HANDLER_IS_NOT_ENABLED, userErrorDetails: nil, developerInfo:"\(self.mCTAG).genericDeleteRecs self.mDB == nil")
        }
        do {
            return try self.mDB!.run(tableQuery.delete())   // unlike Android, does not return negative error codes
        } catch {
            AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).genericDeleteRecs: \(method)", during:"Run(Delete)", errorStruct:error, extra:"DB table \(tableQuery.clauses.from.name)")
            throw error
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // The following methods perform exports and imports of organizational definitions
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // create a default Organization and Form
    public func createDefaultOrgAndForm() throws -> (RecOrganizationDefs, RecOrgFormDefs) {
        // create a default Organization
        let orgRec:RecOrganizationDefs = RecOrganizationDefs(org_code_sv_file: "Org1", org_title_mode: RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE, org_logo_image_png_blob: nil, org_email_to: nil, org_email_cc: nil, org_email_subject: "Contacts collected from eContact Collect")
        orgRec.rOrg_Visuals.rOrgTitle_Background_Color = UIColor.lightGray
        let _ = orgRec.addNewLangRec(forLangRegion: "en")
        try orgRec.setOrgTitleShown(langRegion: "en", title: "Organization's Name")
        orgRec.mOrg_Lang_Recs_are_changed = true
        let _ = try orgRec.saveNewToDB()
        
        // create a default Form
        let formRec:RecOrgFormDefs = RecOrgFormDefs(org_code_sv_file: "Org1", form_code_sv_file: "Form1")
        let _ = try formRec.saveNewToDB(withOrgRec: orgRec)     // allow all the default meta-data fields be auto-created
        
        // now add all the selected form fields
        var orderSVfile:Int = 10
        var orderShown:Int = 10
        try AppDelegate.mFieldHandler!.addFieldstoForm(field_IDCodes: ["FC_Name1st","FC_NameLast","FC_Email","FC_PhFull"], forFormRec: formRec, withOrgRec: orgRec, orderSVfile: &orderSVfile, orderShown: &orderShown)
        return (orgRec, formRec)
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
             language
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
    // throws exceptions for all errors after posting them to error.log and alert
    // Threading: this is run in a Utility Thread instead of the UI Thread
    public static func exportOrgOrForm(forOrgShortName:String, forFormShortName:String?=nil) throws -> String {
        // first load the chosen Org record and other preps
        var orgRec:RecOrganizationDefs? = nil
        orgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: forOrgShortName)
        if orgRec == nil {
            // this should not happen
            AppDelegate.postToErrorLogAndAlert(method:"\(DatabaseHandler.CTAG).exportOrgOrForm", during:"orgGetSpecifiedRecOfShortName", errorMessage:"orgRec == nil", extra:"DB table \(RecOrganizationDefs.TABLE_NAME)")
            throw APP_ERROR(during:NSLocalizedString("Export Preparation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.RECORD_NOT_FOUND, userErrorDetails: nil)
        }
        var formRec:RecOrgFormDefs? = nil
        if forFormShortName != nil {
            // this is a form-only export
            formRec = try RecOrgFormDefs.orgFormGetSpecifiedRecOfShortName(formShortName: forFormShortName!, forOrgShortName: forOrgShortName)
            if formRec == nil {
                // this should not happen
                AppDelegate.postToErrorLogAndAlert(method:"\(DatabaseHandler.CTAG).exportOrgOrForm", during:"orgFormGetSpecifiedRecOfShortName", errorMessage:"formRec == nil", extra:"DB table \(RecOrgFormDefs.TABLE_NAME)")
                throw APP_ERROR(during:NSLocalizedString("Export Preparation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.RECORD_NOT_FOUND, userErrorDetails: nil)
            }
        } else {
            // this is an entire-Org export
            try orgRec!.loadLangRecs()
        }
    
        let mydateFormatter = DateFormatter()
        mydateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        var methodString:String = "\(self.CTAG).exportOrg"
        var jsonOrgObj:NSMutableDictionary? = nil
        var jsonOrgLangsObj:NSMutableDictionary? = nil
        var jsonFormsObj:NSMutableDictionary? = nil
        var jsonFormObj:NSMutableDictionary? = nil
        if forFormShortName == nil {
            // build the Org's json object and validate it
            var jsonRecObj:NSMutableDictionary
            do {
                jsonRecObj = try orgRec!.buildJSONObject()
            } catch {
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"orgRec!.buildJSONObject", errorStruct:error, extra:RecOrganizationDefs.TABLE_NAME)
                throw error
            }
            jsonOrgObj = NSMutableDictionary()
            jsonOrgObj!["item"] = jsonRecObj
            jsonOrgObj!["tableName"] = RecOrganizationDefs.TABLE_NAME
            if !JSONSerialization.isValidJSONObject(jsonOrgObj!) {
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"isValidJSONObject.jsonOrgObj", errorMessage:"Error validating the JSON objects", extra:nil)
                throw APP_ERROR(during:NSLocalizedString("Export Generation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: nil)
            }
            
            // build the Org's Language records into json array and validate them all
            let jsonOrgLangsItemsObj:NSMutableArray = NSMutableArray()
            if orgRec!.mOrg_Lang_Recs != nil {
                for orgLangRec in orgRec!.mOrg_Lang_Recs! {
                    let jsonOrgLangObj = orgLangRec.buildJSONObject()
                    jsonOrgLangsItemsObj.add(jsonOrgLangObj!)
                }
            }
            orgRec = nil    // clean up heap since no longer needed
            jsonOrgLangsObj = NSMutableDictionary()
            jsonOrgLangsObj!["items"] = jsonOrgLangsItemsObj
            jsonOrgLangsObj!["tableName"] = RecOrganizationLangs.TABLE_NAME
            if !JSONSerialization.isValidJSONObject(jsonOrgLangsObj!) {
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"isValidJSONObject.jsonOrgLangsObj", errorMessage:"Error validating the JSON objects", extra:nil)
                throw APP_ERROR(during:NSLocalizedString("Export Generation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: nil)
            }
            
            // load and build all the Org's Form records into json array and validate them all
            let jsonFormsItemsObj:NSMutableArray = NSMutableArray()
            let records1:AnySequence<Row> = try RecOrgFormDefs.orgFormGetAllRecs(forOrgShortName: forOrgShortName)
            for rowObj in records1 {
                let orgFormRec:RecOrgFormDefs = try RecOrgFormDefs(row:rowObj)
                let jsonFormObj = orgFormRec.buildJSONObject()
                jsonFormsItemsObj.add(jsonFormObj!)
            }
            jsonFormsObj = NSMutableDictionary()
            jsonFormsObj!["items"] = jsonFormsItemsObj
            jsonFormsObj!["tableName"] = RecOrgFormDefs.TABLE_NAME
            if !JSONSerialization.isValidJSONObject(jsonFormsObj!) {
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"isValidJSONObject.jsonFormsObj", errorMessage:"Error validating the JSON objects", extra:nil)
                throw APP_ERROR(during:NSLocalizedString("Export Generation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: nil)
            }
        } else {
            // build the Form's json object and validate it
            methodString = methodString + ".Form-only"
            let jsonRecObj = formRec!.buildJSONObject()
            jsonFormObj = NSMutableDictionary()
            jsonFormObj!["item"] = jsonRecObj!
            jsonFormObj!["tableName"] = RecOrgFormDefs.TABLE_NAME
            if !JSONSerialization.isValidJSONObject(jsonFormObj!) {
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"isValidJSONObject.jsonFormObj", errorMessage:"Error validating the JSON objects", extra:nil)
                throw APP_ERROR(during:NSLocalizedString("Export Generation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: nil)
            }
        }
        
        // load and build all the Org's or Form's FormField records into json array and validate them all
        let jsonFormFieldsItemsObj:NSMutableArray = NSMutableArray()
        let records2:AnySequence<Row> = try RecOrgFormFieldDefs.orgFormFieldGetAllRecs(forOrgShortName: forOrgShortName, forFormShortName: nil, sortedBySVFileOrder: false)
        for rowObj in records2 {
            let orgFormFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(row:rowObj)
            let jsonFormFieldObj = orgFormFieldRec.buildJSONObject()
            jsonFormFieldsItemsObj.add(jsonFormFieldObj!)
        }
        let jsonFormFieldsObj:NSMutableDictionary = NSMutableDictionary()
        jsonFormFieldsObj["items"] = jsonFormFieldsItemsObj
        jsonFormFieldsObj["tableName"] = RecOrgFormFieldDefs.TABLE_NAME
        if !JSONSerialization.isValidJSONObject(jsonFormFieldsObj) {
            AppDelegate.postToErrorLogAndAlert(method:methodString, during:"isValidJSONObject.jsonFormFieldsObj", errorMessage:"Error validating the JSON objects", extra:nil)
            throw APP_ERROR(during:NSLocalizedString("Export Generation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: nil)
        }
        
        // load and build all the Org's or Form's FormFieldLocale records into json array and validate them all
        let jsonFormFieldLocalesItemsObj:NSMutableArray = NSMutableArray()
        let records3:AnySequence<Row> = try RecOrgFormFieldLocales.formFieldLocalesGetAllRecs(forOrgShortName: forOrgShortName, forFormShortName: nil)
        for rowObj in records3 {
            let orgFormFieldLocaleRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(row:rowObj)
            let jsonFormFieldLocaleObj = orgFormFieldLocaleRec.buildJSONObject()
            jsonFormFieldLocalesItemsObj.add(jsonFormFieldLocaleObj!)
        }
        let jsonFormFieldLocalesObj:NSMutableDictionary = NSMutableDictionary()
        jsonFormFieldLocalesObj["items"] = jsonFormFieldLocalesItemsObj
        jsonFormFieldLocalesObj["tableName"] = RecOrgFormFieldLocales.TABLE_NAME
        if !JSONSerialization.isValidJSONObject(jsonFormFieldLocalesObj) {
            AppDelegate.postToErrorLogAndAlert(method:methodString, during:"isValidJSONObject.jsonFormFieldLocalesObj", errorMessage:"Error validating the JSON objects", extra:nil)
            throw APP_ERROR(during:NSLocalizedString("Export Generation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: nil)
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
        let jsonOptionSetLocalesObj:NSMutableDictionary = NSMutableDictionary()
        jsonOptionSetLocalesObj["items"] = jsonOptionSetLocalesItemsObj
        jsonOptionSetLocalesObj["tableName"] = RecOptionSetLocales.TABLE_NAME
        if !JSONSerialization.isValidJSONObject(jsonOptionSetLocalesObj) {
            AppDelegate.postToErrorLogAndAlert(method:methodString, during:"isValidJSONObject.jsonOptionSetLocalesObj", errorMessage:"Error validating the JSON objects", extra:nil)
            throw APP_ERROR(during:NSLocalizedString("Export Generation", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: nil)
        }
        
        // convert the entire JSON object structure to a serialized textual file
        var filename:String
        if forFormShortName == nil { filename = "org_config_for_\(forOrgShortName).eContactCollectConfig" }
        else { filename = "form_config_for_\(forOrgShortName)_of_\(forFormShortName!).eContactCollectConfig" }
        let path = "\(AppDelegate.mDocsApp)/\(filename)"
        let stream = OutputStream(toFileAtPath: path, append: false)
        if stream == nil {
            AppDelegate.postToErrorLogAndAlert(method:methodString, during:"OutputStream create", errorMessage:"Error creating org export stream", extra:nil)
            throw APP_ERROR(during:NSLocalizedString("Export File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.COULD_NOT_CREATE, userErrorDetails: nil)
        }
        stream!.open()
        
        var str:String = "{\"apiVersion\":\"1.0\",\n"
        stream!.write(str, maxLength: str.count)
        if forFormShortName == nil {
            str = "\"method\":\"eContactCollect.db.org.export\",\n"
            stream!.write(str, maxLength: str.count)
            str = "\"context\":\"\(forOrgShortName)\",\n"
            stream!.write(str, maxLength: str.count)
        } else {
            str = "\"method\":\"eContactCollect.db.form.export\",\n"
            stream!.write(str, maxLength: str.count)
            str = "\"context\":\"\(forOrgShortName),\(forFormShortName!)\",\n"
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
        str = "  \"forDatabaseVersion\":\"\(AppDelegate.mDatabaseHandler!.getVersioning())\",\n"
        stream!.write(str, maxLength: str.count)
        str = "  \"language\":\"$$\",\n"
        stream!.write(str, maxLength: str.count)
        str = "  \"tables\":{\n"
        stream!.write(str, maxLength: str.count)

        var error:NSError?
        if forFormShortName == nil {
            str = "    \"org\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonOrgObj!, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonOrgObj", errorStruct:error!, extra:nil)
                throw error!
            }
            
            str = ",\n    \"orgLangs\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonOrgLangsObj!, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonOrgLangsObj", errorStruct:error!, extra:nil)
                throw error!
            }
            
            str = ",\n    \"forms\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonFormsObj!, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonFormsObj", errorStruct:error!, extra:nil)
                throw error!
            }
        } else {
            str = "    \"form\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonFormObj!, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonFormObj", errorStruct:error!, extra:nil)
                throw error!
            }
        }
        
        str = ",\n    \"formFields\":\n"
        stream!.write(str, maxLength: str.count)
        JSONSerialization.writeJSONObject(jsonFormFieldsObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
        if error != nil {
            stream!.close()
            AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonFormFieldsObj", errorStruct:error!, extra:nil)
            throw error!
        }
        
        str = ",\n    \"formFieldLocales\":\n"
        stream!.write(str, maxLength: str.count)
        JSONSerialization.writeJSONObject(jsonFormFieldLocalesObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
        if error != nil {
            stream!.close()
            AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonFormFieldLocalesObj", errorStruct:error!, extra:nil)
            throw error!
        }
        
        if forFormShortName == nil {
        /* ??
            str = ",\n    \"customFields\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonCustomFieldsObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonCustomFieldsObj", errorType:error!, extra:nil)
                throw error!
            }
            
            str = ",\n    \"customFieldLocales\":\n"
            stream!.write(str, maxLength: str.count)
            JSONSerialization.writeJSONObject(jsonCustomFieldLocalesObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
            if error != nil {
                stream!.close()
                AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonCustomFieldLocalesObj", errorType:error!, extra:nil)
                throw error!
            }*/
        }
        
        str = ",\n    \"optionSetLocales\":\n"
        stream!.write(str, maxLength: str.count)
        JSONSerialization.writeJSONObject(jsonOptionSetLocalesObj, to: stream!, options: JSONSerialization.WritingOptions(), error: &error)
        if error != nil {
            stream!.close()
            AppDelegate.postToErrorLogAndAlert(method:methodString, during:"writeJSONObject.jsonOptionSetLocalesObj", errorStruct:error!, extra:nil)
            throw error!
        }
        
        str = "\n}}}\n"
        stream!.write(str, maxLength: str.count)
        stream!.close()
        return filename
    }
    
    // return structure for validateJSONdbFile
    public struct ImportOrgOrForm_Result {
        public var wasForm:Bool = false
        public var wasOrgShortName:String = ""
        public var wasFormShortName:String = ""
    }
    
    // imports an organization's entire definition (languages, forms, formfields) to a JSON file
    // if the Org Short Name (rOrg_Code_For_SV_File) is already present, it and all its sub records are deleted first;
    // can also import just a form if its Organization already exists;
    // throws exceptions for all errors (does not post them to error.log nor alert)
    public static func importOrgOrForm(fromFileAtPath:String) throws -> ImportOrgOrForm_Result {
        var result:ImportOrgOrForm_Result = ImportOrgOrForm_Result()
        
        // get the file and its contents and do an initial validation
        let jsonContents = FileManager.default.contents(atPath: fromFileAtPath)   // obtain the data in JSON format
        if jsonContents == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_OPEN, userErrorDetails: NSLocalizedString("Could not open the file", comment:""))
        }
        let validationResult:DatabaseHandler.ValidateJSONdbFile_Result = try DatabaseHandler.validateJSONdbFile(contents: jsonContents!)
        let methodStr:String = validationResult.jsonTopLevel!["method"] as! String  // these are verified as present and have content
        let contextStr:String = validationResult.jsonTopLevel!["context"] as! String
        
        // validate the import type
        var userMsg:String = NSLocalizedString("Content Error: ", comment:"") + "1st " + NSLocalizedString("level improperly formatted", comment:"")
        var existingOrgRec:RecOrganizationDefs? = nil
        var formOnlyMode:Bool = false
        if methodStr == "eContactCollect.db.org.export" {
            // do nothing
        } else if methodStr == "eContactCollect.db.form.export" {
            result.wasForm = true
            formOnlyMode = true
            let nameComponents = contextStr.components(separatedBy: ",")
            if nameComponents.count < 2 {
                throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: userMsg, developerInfo: "Validate top level; Form-only import; 'context'.components.count < 2")
            }
            result.wasOrgShortName = nameComponents[0]
            result.wasFormShortName = nameComponents[1]
            existingOrgRec = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: nameComponents[0])
            if existingOrgRec == nil {
                throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.ORG_DOES_NOT_EXIST, userErrorDetails: NSLocalizedString("Organization for the Form must pre-exist: ", comment:"") + nameComponents[0], developerInfo: "Validate top level; Form-only import; existingOrgRec == nil: \(nameComponents[0])")
            }
        } else {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: userMsg, developerInfo: "Validate top level; 'method' != acceptable values")
        }
        
        // start importing; is this an entire Org import
        if !formOnlyMode {
            // yes, import first the single Org record
            let getResult1:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "org", forTableName: RecOrganizationDefs.TABLE_NAME, needsItem: true, priorResult: validationResult)
            userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult1.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")

            let tempNewOrgRec:RecOrganizationDefs_Optionals = RecOrganizationDefs_Optionals(jsonObj: getResult1.jsonItemLevel!)
            var inx:Int = 1
            if !tempNewOrgRec.validate() {
                var developer_error_message = "Validate \(getResult1.tableName) 'table' entries; ; record \(inx) did not validate"
                if !(tempNewOrgRec.rOrg_Code_For_SV_File ?? "").isEmpty {
                    developer_error_message = developer_error_message + "; for \(tempNewOrgRec.rOrg_Code_For_SV_File!)"
                }
                throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
            }
            let newOrgRec:RecOrganizationDefs = try RecOrganizationDefs(existingRec: tempNewOrgRec)
            let _ = try RecOrganizationDefs.orgDeleteRec(orgShortName: newOrgRec.rOrg_Code_For_SV_File)    // this will delete its linked entries in every other table
            let _ = try newOrgRec.saveNewToDB()
            
            // now all OrgLang records
            let getResult2:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "orgLangs", forTableName: RecOrganizationLangs.TABLE_NAME, needsItem: false, priorResult: validationResult)
            userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult2.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
            inx = 1
            for jsonItemObj in getResult2.jsonItemsLevel! {
                let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                if jsonItem != nil {
                    let newOrgLangRecOpt:RecOrganizationLangs_Optionals = RecOrganizationLangs_Optionals(jsonObj: jsonItem!)
                    if !newOrgLangRecOpt.validate() {
                        var developer_error_message = "Validate \(getResult2.tableName) 'table' entries; ; record \(inx) did not validate"
                        if !(newOrgLangRecOpt.rOrgLang_LangRegionCode ?? "").isEmpty {
                            developer_error_message = developer_error_message + "; for \(newOrgLangRecOpt.rOrgLang_LangRegionCode!)"
                        }
                        throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                    }
                    let newOrgLangRec:RecOrganizationLangs = try RecOrganizationLangs(existingRec: newOrgLangRecOpt)
                    let _ = try newOrgLangRec.saveToDB()
                }
                inx = inx + 1
            }
            
            // now all Form records
            let getResult3:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "forms", forTableName: RecOrgFormDefs.TABLE_NAME, needsItem: false, priorResult: validationResult)
            userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult3.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
            inx = 1
            for jsonItemObj in getResult3.jsonItemsLevel! {
                let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
                if jsonItem != nil {
                    let newFormRecOpt:RecOrgFormDefs_Optionals = RecOrgFormDefs_Optionals(jsonObj: jsonItem!)
                    if !newFormRecOpt.validate() {
                        var developer_error_message = "Validate \(getResult3.tableName) 'table' entries; ; record \(inx) did not validate"
                        if !(newFormRecOpt.rForm_Code_For_SV_File ?? "").isEmpty {
                            developer_error_message = developer_error_message + "; for \(newFormRecOpt.rForm_Code_For_SV_File!)"
                        }
                        throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                    }
                    let newFormRec:RecOrgFormDefs = try RecOrgFormDefs(existingRec: newFormRecOpt)
                    let _ = try newFormRec.saveNewToDB(withOrgRec: nil) // do not auto-include the meta-data fields
                }
                inx = inx + 1
            }
        } else {
            // import the single form record
            let getResult1:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "form", forTableName: RecOrgFormDefs.TABLE_NAME, needsItem: true, priorResult: validationResult)
            userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult1.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
            
            let newFormRecOpt:RecOrgFormDefs_Optionals = RecOrgFormDefs_Optionals(jsonObj: getResult1.jsonItemLevel!)
            let inx = 1
            if !newFormRecOpt.validate() {
                var developer_error_message = "Validate \(getResult1.tableName) 'table' entries; ; record \(inx) did not validate"
                if !(newFormRecOpt.rForm_Code_For_SV_File ?? "").isEmpty {
                    developer_error_message = developer_error_message + "; for \(newFormRecOpt.rForm_Code_For_SV_File!)"
                }
                throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
            }
            // this will delete its linked entries in every other table
            let newFormRec:RecOrgFormDefs = try RecOrgFormDefs(existingRec: newFormRecOpt)
            let _ = try RecOrgFormDefs.orgFormDeleteRec(formShortName: newFormRec.rForm_Code_For_SV_File, forOrgShortName: newFormRec.rOrg_Code_For_SV_File)
            let _ = try newFormRec.saveNewToDB(withOrgRec: nil)    // do not auto-include the meta-data fields
        }
        
        // now all FormField records; note that all subfields need to be re-linked to the primary field's new index# so do this in two passes
        let getResult4:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "formFields", forTableName: RecOrgFormFieldDefs.TABLE_NAME, needsItem: false, priorResult: validationResult)
        userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult4.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
        // first add all primary formfields
        var remappingFFI:[Int64:Int64] = [:]
        var inx:Int  = 1
        for jsonItemObj in getResult4.jsonItemsLevel! {
            let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
            if jsonItem != nil {
                let newFormFieldRecOpt:RecOrgFormFieldDefs_Optionals = RecOrgFormFieldDefs_Optionals(jsonRecObj: jsonItem!)
                if !newFormFieldRecOpt.validate() {
                    var developer_error_message = "Validate \(getResult4.tableName) 'table' entries; ; record \(inx) did not validate"
                    if newFormFieldRecOpt.rFormField_Index != nil {
                        developer_error_message = developer_error_message + "; for \(newFormFieldRecOpt.rFormField_Index!)"
                    }
                    throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                }
                let newFormFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(existingRec: newFormFieldRecOpt)
                if newFormFieldRec.rFormField_SubField_Within_FormField_Index == nil {
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
                let newFormFieldRecOpt:RecOrgFormFieldDefs_Optionals = RecOrgFormFieldDefs_Optionals(jsonRecObj: jsonItem!)
                if !newFormFieldRecOpt.validate() {
                    var developer_error_message = "Validate \(getResult4.tableName) 'table' entries; ; record \(inx) did not validate"
                    if newFormFieldRecOpt.rFormField_Index != nil {
                        developer_error_message = developer_error_message + "; for \(newFormFieldRecOpt.rFormField_Index!)"
                    }
                    throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                }
                let newFormFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(existingRec: newFormFieldRecOpt)
                if newFormFieldRec.rFormField_SubField_Within_FormField_Index != nil {
                    newFormFieldRec.rFormField_SubField_Within_FormField_Index = remappingFFI[newFormFieldRec.rFormField_SubField_Within_FormField_Index!]
                    let originalIndex = newFormFieldRec.rFormField_Index
                    newFormFieldRec.rFormField_Index = -1
                    newFormFieldRec.rFormField_Index = try newFormFieldRec.saveNewToDB()
                    remappingFFI[originalIndex] = newFormFieldRec.rFormField_Index
                }
            }
            inx = inx + 1
        }
        
        // now all FormFieldLocale records; note that every record needs to be re-linked to its corresponding RecOrgFormFieldDefs
        let getResult5:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "formFieldLocales", forTableName: RecOrgFormFieldLocales.TABLE_NAME, needsItem: false, priorResult: validationResult)
        userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult5.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
        inx = 1
        for jsonItemObj in getResult5.jsonItemsLevel! {
            let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
            if jsonItem != nil {
                let newFormFieldLocaleOptRec:RecOrgFormFieldLocales_Optionals = RecOrgFormFieldLocales_Optionals(jsonObj: jsonItem!)
                if !newFormFieldLocaleOptRec.validate() {
                    var developer_error_message = "Validate \(getResult5.tableName) 'table' entries; ; record \(inx) did not validate"
                    if newFormFieldLocaleOptRec.rFormFieldLoc_Index != nil {
                        developer_error_message = developer_error_message + "; for \(newFormFieldLocaleOptRec.rFormFieldLoc_Index!)"
                    }
                    throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                }
                let newFormFieldLocaleRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(existingRec: newFormFieldLocaleOptRec)
                newFormFieldLocaleRec.rFormField_Index = remappingFFI[newFormFieldLocaleRec.rFormField_Index] ?? -1
                newFormFieldLocaleRec.rFormFieldLoc_Index = -1
                newFormFieldLocaleRec.rFormFieldLoc_Index = try newFormFieldLocaleRec.saveNewToDB()
            }
            inx = inx + 1
        }
        
        // now all custom OptionSetLocale records;
        // ?? since these are not tagged by Organization there could be conflicts
        let getResult6:DatabaseHandler.GetJSONdbFileTable_Result = try DatabaseHandler.getJSONdbFileTable(forTableCode: "optionSetLocales", forTableName: RecOptionSetLocales.TABLE_NAME, needsItem: false, priorResult: validationResult)
        userMsg = NSLocalizedString("Content Error: ", comment:"") + "\(getResult6.tableName): " + "4th " + NSLocalizedString("level improperly formatted record", comment:"")
        inx = 1
        for jsonItemObj in getResult6.jsonItemsLevel! {
            let jsonItem:NSDictionary? = jsonItemObj as? NSDictionary
            if jsonItem != nil {
                let newOSLoptRec:RecOptionSetLocales_Optionals = RecOptionSetLocales_Optionals(jsonObj: jsonItem!)
                if !newOSLoptRec.validate() {
                    let developer_error_message = "Validate \(getResult6.tableName) 'table' entries; ; record \(inx) did not validate"
                    throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE, userErrorDetails: "\(userMsg) \(inx)", developerInfo: developer_error_message)
                }
                let newOSLrec:RecOptionSetLocales = try RecOptionSetLocales(existingRec: newOSLoptRec)
                let _ = try newOSLrec.saveNewToDB()
            }
            inx = inx + 1
        }

        // ?? custom tables
        
        return result
    }
    
    // return structure for validateJSONdbFile
    public struct ValidateJSONdbFile_Result {
        public var databaseVersion:String = ""
        public var language:String = ""
        
        // top level contains: "apiVersion","method","context","id","data"
        public var jsonTopLevel:[String:Any?]? = nil
        
        // contents of data: "created", "originOS", "appCode", "appName", "appVersion", "appBuild", "forDatabaseVersion", "language", "tables"
        public var jsonDataLevel:[String:Any?]? = nil
        
        // contents of tables: "org", "orgLangs", "form", "forms", "formFields", "formFieldLocales", "customFields", "customFieldLocales", "fieldAttribLocales", "fieldAttribLocales_packed"
        public var jsonTablesLevel:[String:Any?]? = nil
    }
    
    // validate the header of a JSON database export file;
    // this method only throws errors; it does NOT post them to error.log
    public static func validateJSONdbFile(contents:Data) throws -> ValidateJSONdbFile_Result {
        var result:ValidateJSONdbFile_Result = ValidateJSONdbFile_Result()
        var userErrorMsg:String = NSLocalizedString("Content Error: ", comment:"") + "1st " + NSLocalizedString("level improperly formatted", comment:"")
        
        var jsonData:Any? = nil
        do {
            jsonData = try JSONSerialization.jsonObject(with: contents, options: .allowFragments)
        } catch {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "JSON Parse; \(AppDelegate.developerErrorMessage(errorStruct: error))")
        }
        
        result.jsonTopLevel = jsonData as? [String:Any?]
        if result.jsonTopLevel == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate top level; Level is not NSDictionary")
        } else if (result.jsonTopLevel!["apiVersion"] as? String) == nil || (result.jsonTopLevel!["method"] as? String) == nil || (result.jsonTopLevel!["context"] as? String) == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate top level; Level is missing 'apiVersion', 'method', or 'context'")
        } else if (result.jsonTopLevel!["method"] as! String).isEmpty || (result.jsonTopLevel!["context"] as! String).isEmpty {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate top level; Level 'method' or 'context' isEmpty")
        } else if (result.jsonTopLevel!["apiVersion"] as! String) != "1.0" {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate top level; 'apiVersion' is incorrect: \(result.jsonTopLevel!["apiVersion"] as! String)")
        } else if !((result.jsonTopLevel!["method"] as! String).starts(with: "eContactCollect.db.")) {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate top level; 'method' prefix is incorrect: \((result.jsonTopLevel!["method"] as! String))")
        }

        userErrorMsg = NSLocalizedString("Content Error: ", comment:"") + "2nd " + NSLocalizedString("level improperly formatted", comment:"")
        result.jsonDataLevel = result.jsonTopLevel!["data"] as? [String:Any?]
        if result.jsonDataLevel == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate 'data' level; Level is not NSDictionary")
        } else if (result.jsonDataLevel!["forDatabaseVersion"] as? String) == nil || (result.jsonDataLevel!["language"] as? String) == nil || (result.jsonDataLevel!["tables"] as? [String:Any?]) == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate 'data' level; Level is missing 'forDatabaseVersion', 'language', or 'tables'")
        }
        
        result.databaseVersion = (result.jsonDataLevel!["forDatabaseVersion"] as! String)
        result.language = (result.jsonDataLevel!["language"] as! String)
        if result.databaseVersion != "1" {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate 'data' level; Level 'forDatabaseVersion' is incompatible: \(result.databaseVersion)")
        }

        userErrorMsg = NSLocalizedString("Content Error: ", comment:"") + "3rd " + NSLocalizedString("level improperly formatted", comment:"")
        result.jsonTablesLevel = result.jsonDataLevel!["tables"] as? [String:Any?]
        if result.jsonTablesLevel == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate 'tables' level; 'tables' is missing or not NSDictionary")
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

        result.jsonTableLevel = priorResult.jsonTablesLevel![forTableCode] as? [String:Any?]
        if result.jsonTableLevel == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                userErrorDetails: userErrorMsg, developerInfo: "Validate \(forTableCode) 'table' level; Level is missing or not NSDictionary")
        } else if (result.jsonTableLevel!["tableName"] as? String) == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                userErrorDetails: userErrorMsg, developerInfo: "Validate \(forTableCode) 'table' level; Level is missing 'tableName' key")
        } else if result.jsonTableLevel!["tableName"] as! String != forTableName {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                userErrorDetails: userErrorMsg, developerInfo: "Validate \(forTableCode) 'table' level; Level 'tableName' needed \(forTableName) and is incorrect: \(result.jsonTableLevel!["tableName"] as! String)")
        }
    
        result.tableName = (result.jsonTableLevel!["tableName"] as! String)
        result.jsonItemLevel = result.jsonTableLevel!["item"] as? NSDictionary
        result.jsonItemsLevel = result.jsonTableLevel!["items"] as? NSArray
        
        if result.jsonItemLevel == nil && result.jsonItemsLevel == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate \(forTableCode) 'table' level; Level is missing both 'item' and 'items'")
        } else if needsItem && result.jsonItemLevel == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate \(forTableCode) 'table' level; Level is missing 'item'")
        } else if !needsItem && result.jsonItemsLevel == nil {
            throw APP_ERROR(during:NSLocalizedString("Import File", comment:""), domain:DatabaseHandler.ThrowErrorDomain, errorCode:.DID_NOT_VALIDATE,
                            userErrorDetails: userErrorMsg, developerInfo: "Validate \(forTableCode) 'table' level; Level is missing 'items'")
        }
        return result
    }
}
