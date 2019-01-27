//
//  eContact_CollectTests.swift
//  eContact CollectTests
//
//  Created by Yo on 9/21/18.
//

import XCTest
import SQLite
@testable import eContact_Collect

extension UIFont {
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    public func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    public func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
    
    public func boldItalic() -> UIFont {
        return withTraits(traits: [.traitBold, .traitItalic])
    }
    
    private func withTraits(traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        if descriptor == nil { return self }
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }
}

class eContact_CollectTests_001_Error: XCTestCase {
    // This is the setUp() class method.
    // It is called before the first test method begins.
    // Set up any overall initial state here.
    override class func setUp() {
        super.setUp()   // should be first
    }
    
    // This is the setUp() instance method.
    // It is called before each test method begins.
    // Set up any per-test state here.
    override func setUp() {
        // setup code here
    }
    
    // This is the tearDown() instance method.
    // It is called after each test method completes.
    // Perform any per-test cleanup here.
    override func tearDown() {
        // teardown code here
    }
    
    // This is the tearDown() class method.
    // It is called after all test methods complete.
    // Perform any overall cleanup here.
    override class func tearDown() {
        // teardown code here
        super.tearDown()    // should be last
    }
    
    func test_001_FileSystemErrors() {
        continueAfterFailure = false
        
        // stage 1 - test the APP_ERROR struct itself by causing an error throw
        var stage:Int = 1
        do {
            try FileManager.default.createDirectory(atPath:"/INVALID", withIntermediateDirectories:false, attributes:nil)
            XCTFail("APP_ERROR.*.\(stage): improperly allowed directory creation")
        } catch {
            var appError = APP_ERROR(funcName: "test_001_FileSystemErrors", during: "createDirectory", domain: "domain", error: error, errorCode: .FILESYSTEM_ERROR, userErrorDetails: "User Details", developerInfo: "/INVALID", noAlert: true)
            XCTAssertEqual(appError.callStack, "test_001_FileSystemErrors", "APP_ERROR.*.\(stage):  appError.callStack wrong")
            XCTAssertEqual(appError.during, "createDirectory", "APP_ERROR.*.\(stage):  appError.during wrong")
            XCTAssertEqual(appError.domain, "domain", "APP_ERROR.*.\(stage):  appError.domain wrong")
            XCTAssertEqual(appError.errorCode, .FILESYSTEM_ERROR, "APP_ERROR.*.\(stage):  appError.errorCode wrong")
            XCTAssertEqual(appError.userErrorDetails, "User Details", "APP_ERROR.*.\(stage):  appError.userErrorDetails wrong")
            XCTAssertEqual(appError.developerInfo, "/INVALID", "APP_ERROR.*.\(stage):  appError.developerInfo wrong")
            XCTAssertEqual(appError.noAlert, true, "APP_ERROR.*.\(stage):  appError.noAlert wrong")
            XCTAssertEqual(appError.noPost, false, "APP_ERROR.*.\(stage):  appError.noPost wrong")
            XCTAssertNotNil(appError.error, "APP_ERROR.*.\(stage):  appError.error is nil")
            
            XCTAssertEqual(appError.error!._domain, "NSCocoaErrorDomain", "APP_ERROR.*.\(stage):  appError.error!._domain wrong")
            XCTAssertEqual(appError.error!._code, 513, "APP_ERROR.*.\(stage):  appError.error!._code wrong")
            if appError.error!._userInfo != nil {
                for (key, value) in (error._userInfo! as! NSDictionary) {
                    let keyString = key as? String
                    let valueString = value as? String
                    if !(keyString ?? "").isEmpty && !(valueString ?? "").isEmpty {
                        XCTAssertEqual(keyString!, "NSFilePath", "APP_ERROR.*.\(stage):  appError.error!._userInfo key wrong")
                        XCTAssertEqual(valueString!, "/INVALID", "APP_ERROR.*.\(stage):  appError.error!._userInfo value wrong")
                    } else if !(keyString ?? "").isEmpty {
                        XCTAssertEqual(keyString!, "NSUnderlyingError", "APP_ERROR.*.\(stage):  appError.error!._userInfo key wrong")
                    } else if !(valueString ?? "").isEmpty {
                        XCTFail("APP_ERROR.*.\(stage): appError.error!._userInfo value with no key")
                    }
                }
            } else {
                XCTFail("APP_ERROR.*.\(stage): appError.error!._userInfo is nil")
            }
            
            appError.prependCallStack(funcName: "TestPrepend")
            XCTAssertEqual(appError.callStack, "TestPrepend:test_001_FileSystemErrors", "APP_ERROR.*.\(stage):  appError.callStack prepending wrong")
        }
        
        // stage 2 - test an APP_ERROR throw from a one-level-deep function; filesystem type error
        stage = 2
        let baseAppError1:APP_ERROR = APP_ERROR(funcName: "\(DatabaseHandler.CTAG).importOrgOrForm", during: "FileManager.default.contents", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_OPEN, userErrorDetails: NSLocalizedString("Import File", comment:""), developerInfo: "!!!CANNOT_EXIST!!!")
        let baseAppError2:APP_ERROR = APP_ERROR(funcName: "testFileSystemErrors:\(DatabaseHandler.CTAG).importOrgOrForm", during: "FileManager.default.contents", domain: DatabaseHandler.ThrowErrorDomain, errorCode: .DID_NOT_OPEN, userErrorDetails: NSLocalizedString("Import File", comment:""), developerInfo: "!!!CANNOT_EXIST!!!")
        do {
            let _ = try DatabaseHandler.importOrgOrForm(fromFileAtPath: "!!!CANNOT_EXIST!!!")
            XCTFail("APP_ERROR.*.\(stage): improperly returned a result")
        } catch var appError as APP_ERROR {
#if TESTING
            XCTAssertTrue(baseAppError1.sameAs(baseError: appError), "APP_ERROR.*.\(stage): error obtained not as expected")
            appError.prependCallStack(funcName: "testFileSystemErrors")
            XCTAssertTrue(baseAppError2.sameAs(baseError: appError), "APP_ERROR.*.\(stage): prepended error obtained not as expected")
#endif
        } catch {
            XCTFail("APP_ERROR.*.\(stage): did not return an APP_ERROR")
        }
    }
}

class eContact_CollectTests_002_Database: XCTestCase {
    
    // This is the setUp() class method.
    // It is called before the first test method begins.
    // Set up any overall initial state here.
    override class func setUp() {
        super.setUp()   // should be first
    }
    
    // This is the setUp() instance method.
    // It is called before each test method begins.
    // Set up any per-test state here.
    override func setUp() {
        // setup code here
    }

    // This is the tearDown() instance method.
    // It is called after each test method completes.
    // Perform any per-test cleanup here.
    override func tearDown() {
        // teardown code here
    }
    
    // This is the tearDown() class method.
    // It is called after all test methods complete.
    // Perform any overall cleanup here.
    override class func tearDown() {
        // teardown code here            
        super.tearDown()    // should be last
    }

    func test_001_Alerts() {
        continueAfterFailure = false
        XCTAssertNotNil(AppDelegate.mDatabaseHandler, "RecAlert: Fatal-DatabaseHandler is nil")
        XCTAssertEqual(AppDelegate.mDatabaseHandler!.mDBstatus_state, HandlerStatusStates.Valid, "RecAlert: Fatal-DatabaseHandler is in state \(AppDelegate.mDatabaseHandler!.mDBstatus_state.rawValue)")
        let baseAlertRec1:RecAlert = RecAlert(timestamp_ms_utc: AppDelegate.utcCurrentTimeMillis(), timezone_ms_utc_offset: -33000, message: "Alert message 1")
        let baseAlertRec2:RecAlert = RecAlert(timestamp_ms_utc: AppDelegate.utcCurrentTimeMillis(), timezone_ms_utc_offset: 44000, message: "Alert #2 message")
        let baseAlertRec3:RecAlert = RecAlert(timestamp_ms_utc: AppDelegate.utcCurrentTimeMillis(), timezone_ms_utc_offset: 0, message: "Alert message the third")
        var stage:Int = 0
        do {
            // stage 1
            stage = 1
            var qty = try RecAlert.alertGetQtyRecs()
            XCTAssertEqual(qty, 0, "RecAlert.alertGetQtyRecs.\(stage): Qty Wrong")
            
            // stage 2
            stage = 2
            baseAlertRec1.rAlert_DBID = try baseAlertRec1.saveNewToDB()
            qty = try RecAlert.alertGetQtyRecs()
            XCTAssertEqual(qty, 1, "RecAlert.alertGetQtyRecs.\(stage): Qty Wrong")
            var rows = try RecAlert.alertGetAllRecs()
            var cntr:Int = 0
            for row in rows {
                let alertRec:RecAlert = try RecAlert(row:row)
#if TESTING
                XCTAssertTrue(alertRec.sameAs(baseRec:baseAlertRec1), "RecAlert.alertGetAllRecs.\(stage): Rec retrieved not same as saved")
#endif
                cntr = cntr + 1
            }
            XCTAssertEqual(cntr, 1, "RecAlert.alertGetAllRecs.\(stage): Found Qty Wrong")
            
            // stage 3
            stage = 3
            baseAlertRec2.rAlert_DBID = try baseAlertRec2.saveNewToDB()
            baseAlertRec3.rAlert_DBID = try baseAlertRec3.saveNewToDB()
            qty = try RecAlert.alertGetQtyRecs()
            XCTAssertEqual(qty, 3, "RecAlert.alertGetQtyRecs.\(stage): Qty Wrong")
            rows = try RecAlert.alertGetAllRecs()
            cntr = 0
            for row in rows {
                let alertRec:RecAlert = try RecAlert(row:row)
#if TESTING
                if alertRec.rAlert_DBID == baseAlertRec1.rAlert_DBID {
                    XCTAssertTrue(alertRec.sameAs(baseRec:baseAlertRec1), "RecAlert.alertGetAllRecs.\(stage): Rec1 retrieved not same as saved")
                } else if alertRec.rAlert_DBID == baseAlertRec2.rAlert_DBID {
                    XCTAssertTrue(alertRec.sameAs(baseRec:baseAlertRec2), "RecAlert.alertGetAllRecs.\(stage): Rec2 retrieved not same as saved")
                } else if alertRec.rAlert_DBID == baseAlertRec3.rAlert_DBID {
                    XCTAssertTrue(alertRec.sameAs(baseRec:baseAlertRec3), "RecAlert.alertGetAllRecs.\(stage): Rec3 retrieved not same as saved")
                } else {
                    XCTFail("RecAlert.alertGetAllRecs.\(stage): Rec found with ID not matching any saved IDs")
                }
#endif
                cntr = cntr + 1
            }
            XCTAssertEqual(cntr, 3, "RecAlert.alertGetAllRecs.\(stage): Found Qty Wrong")
            
            // stage 4
            stage = 4
            let _ = try baseAlertRec2.deleteFromDB()
            qty = try RecAlert.alertGetQtyRecs()
            XCTAssertEqual(qty, 2, "RecAlert.alertGetQtyRecs.\(stage): Qty Wrong")
            rows = try RecAlert.alertGetAllRecs()
            cntr = 0
            for row in rows {
                let alertRec:RecAlert = try RecAlert(row:row)
#if TESTING
                if alertRec.rAlert_DBID == baseAlertRec1.rAlert_DBID {
                    XCTAssertTrue(alertRec.sameAs(baseRec:baseAlertRec1), "RecAlert.alertGetAllRecs.\(stage): Rec1 retrieved not same as saved")
                } else if alertRec.rAlert_DBID == baseAlertRec2.rAlert_DBID {
                    XCTFail("RecAlert.alertGetAllRecs.\(stage): Deleted Rec2 still in database")
                } else if alertRec.rAlert_DBID == baseAlertRec3.rAlert_DBID {
                    XCTAssertTrue(alertRec.sameAs(baseRec:baseAlertRec3), "RecAlert.alertGetAllRecs.\(stage): Rec3 retrieved not same as saved")
                } else {
                    XCTFail("RecAlert.alertGetAllRecs.\(stage): Rec found with ID not matching any saved IDs")
                }
#endif
                cntr = cntr + 1
            }
            XCTAssertEqual(cntr, 2, "RecAlert.alertGetAllRecs.\(stage): Found Qty Wrong")
            
            // stage 5
            stage = 5
            let _ = try RecAlert.alertDeleteAll()
            qty = try RecAlert.alertGetQtyRecs()
            XCTAssertEqual(qty, 0, "RecAlert.alertGetQtyRecs.\(stage): Qty Wrong")
            rows = try RecAlert.alertGetAllRecs()
            cntr = 0
            for row in rows {
                let _ = try RecAlert(row:row)
                cntr = cntr + 1
            }
            XCTAssertEqual(cntr, 0, "RecAlert.alertGetAllRecs.\(stage): Found Qty Wrong")
        } catch let errResult as Result {
            XCTFail("RecAlert.*.\(stage): SQL Error thrown: \(errResult.localizedDescription)")
        } catch {
            XCTFail("RecAlert.*.\(stage): Error thrown: \(error.localizedDescription)")
        }
    }
    
    // TOBE tested
    //public var rOrg_LangRegionCodes_Supported:[String]?             // ISO language code-region entries that the Organization supports
    //public var rOrg_LangRegionCode_SV_File:String?                  // ISO language code-region used for SV-File columns and meta-data
    //public var rOrg_Logo_Image_Blob:Data?                           // organization's logo (stored in 3x size as PNG)
    
    func test_002_Organizations() {
        continueAfterFailure = false
        XCTAssertNotNil(AppDelegate.mDatabaseHandler, "RecOrganizationDefs: Fatal-DatabaseHandler is nil")
        XCTAssertEqual(AppDelegate.mDatabaseHandler!.mDBstatus_state, HandlerStatusStates.Valid, "RecOrganizationDefs: Fatal-DatabaseHandler is in state \(AppDelegate.mDatabaseHandler!.mDBstatus_state.rawValue)")
        
        let baseOrgRec1:RecOrganizationDefs = RecOrganizationDefs(org_code_sv_file: "Test Org1", org_title_mode: RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE, org_logo_image_png_blob: nil, org_email_to: "email1@email.com", org_email_cc: "emailcc1@smail.net", org_email_subject: "Subject1")
        baseOrgRec1.rOrg_Event_Code_For_SV_File = "AA18"
        baseOrgRec1.rOrg_Visuals.rOrgTitle_Background_Color = UIColor.black
        baseOrgRec1.rOrg_Visuals.rOrgTitle_TitleText_Color = UIColor.white
        baseOrgRec1.rOrg_Visuals.rOrgTitle_TitleText_Font = UIFont.systemFont(ofSize: 15).bold()
        
        let image2:UIImage = #imageLiteral(resourceName: "flag_spain")
        let baseOrgRec2:RecOrganizationDefs = RecOrganizationDefs(org_code_sv_file: "Test Organization2", org_title_mode: RecOrganizationDefs.ORG_TITLE_MODE.BOTH_50_50, org_logo_image_png_blob: image2.pngData(), org_email_to: "emailHow2@email.com", org_email_cc: "onlycc2@smail.net", org_email_subject: "")
        baseOrgRec2.rOrg_Event_Code_For_SV_File = nil
        baseOrgRec2.rOrg_Visuals.rOrgTitle_Background_Color = UIColor(red: 0.5, green: 0.25, blue: 0.8, alpha: 0.7)
        baseOrgRec2.rOrg_Visuals.rOrgTitle_TitleText_Color = UIColor.red
        baseOrgRec2.rOrg_Visuals.rOrgTitle_TitleText_Font = UIFont.systemFont(ofSize: 19).boldItalic()
        
        let image3:UIImage = #imageLiteral(resourceName: "Wizard")
        let baseOrgRec3:RecOrganizationDefs = RecOrganizationDefs(org_code_sv_file: "Org 3 for Testing", org_title_mode: RecOrganizationDefs.ORG_TITLE_MODE.ONLY_LOGO, org_logo_image_png_blob: image3.pngData(), org_email_to: "", org_email_cc: "emailcc1@smail.net", org_email_subject: nil)
        baseOrgRec3.rOrg_Event_Code_For_SV_File = "Whatevers"
        baseOrgRec3.rOrg_Visuals.rOrgTitle_Background_Color = UIColor.black
        baseOrgRec3.rOrg_Visuals.rOrgTitle_TitleText_Color = UIColor.white
        baseOrgRec3.rOrg_Visuals.rOrgTitle_TitleText_Font = UIFont.systemFont(ofSize: 24).italic()
        
        var stage:Int = 0
        do {
            // stage 1
            stage = 1
            var qty = try RecOrganizationDefs.orgGetQtyRecs()
            XCTAssertEqual(qty, 0, "RecOrganizationDefs.orgGetQtyRecs.\(stage): Qty Wrong")
            
            // stage 2
            stage = 2
            let _ = try baseOrgRec1.saveNewToDB()
            qty = try RecOrganizationDefs.orgGetQtyRecs()
            XCTAssertEqual(qty, 1, "RecOrganizationDefs.orgGetQtyRecs.\(stage): Qty Wrong")
            var rows = try RecOrganizationDefs.orgGetAllRecs()
            var cntr:Int = 0
            for row in rows {
                let orgRec:RecOrganizationDefs = try RecOrganizationDefs(row:row)
#if TESTING
                XCTAssertTrue(orgRec.sameAs(baseRec:baseOrgRec1), "RecOrganizationDefs.orgGetAllRecs.\(stage): Rec retrieved not same as saved")
#endif
                cntr = cntr + 1
            }
            XCTAssertEqual(cntr, 1, "RecOrganizationDefs.orgGetAllRecs.\(stage): Found Qty Wrong")
            
            // stage 3
            stage = 3
            let _ = try baseOrgRec2.saveNewToDB()
            do {
                let _ = try baseOrgRec2.saveNewToDB()
                XCTFail("RecOrganizationDefs.saveNewToDB.\(stage): Duplicate Rec2 saveNew was allowed")
            } catch {}  // TESTING; this catch does not need to be handled
            let _ = try baseOrgRec3.saveNewToDB()
            qty = try RecOrganizationDefs.orgGetQtyRecs()
            XCTAssertEqual(qty, 3, "RecOrganizationDefs.orgGetQtyRecs.\(stage): Qty Wrong")
            rows = try RecOrganizationDefs.orgGetAllRecs()
            cntr = 0
            for row in rows {
                let orgRec:RecOrganizationDefs = try RecOrganizationDefs(row:row)
#if TESTING
                if orgRec.rOrg_Code_For_SV_File == baseOrgRec1.rOrg_Code_For_SV_File {
                    XCTAssertTrue(orgRec.sameAs(baseRec:baseOrgRec1), "RecOrganizationDefs.orgGetAllRecs.\(stage): Rec1 retrieved not same as saved")
                } else if orgRec.rOrg_Code_For_SV_File == baseOrgRec2.rOrg_Code_For_SV_File {
                    XCTAssertTrue(orgRec.sameAs(baseRec:baseOrgRec2), "RecOrganizationDefs.orgGetAllRecs.\(stage): Rec2 retrieved not same as saved")
                } else if orgRec.rOrg_Code_For_SV_File == baseOrgRec3.rOrg_Code_For_SV_File {
                    XCTAssertTrue(orgRec.sameAs(baseRec:baseOrgRec3), "RecOrganizationDefs.orgGetAllRecs.\(stage): Rec3 retrieved not same as saved")
                } else {
                    XCTFail("RecOrganizationDefs.orgGetAllRecs.\(stage): Rec found with ID not matching any saved IDs")
                }
#endif
                cntr = cntr + 1
            }
            XCTAssertEqual(cntr, 3, "RecOrganizationDefs.orgGetAllRecs.\(stage): Found Qty Wrong")
            
            // stage 4
            stage = 4
            let _ = try baseOrgRec2.deleteFromDB()
            qty = try RecOrganizationDefs.orgGetQtyRecs()
            XCTAssertEqual(qty, 2, "RecOrganizationDefs.orgGetQtyRecs.\(stage): Qty Wrong")
            rows = try RecOrganizationDefs.orgGetAllRecs()
            cntr = 0
            for row in rows {
                let orgRec:RecOrganizationDefs = try RecOrganizationDefs(row:row)
#if TESTING
                if orgRec.rOrg_Code_For_SV_File == baseOrgRec1.rOrg_Code_For_SV_File {
                    XCTAssertTrue(orgRec.sameAs(baseRec:baseOrgRec1), "RecOrganizationDefs.orgGetAllRecs.\(stage): Rec1 retrieved not same as saved")
                } else if orgRec.rOrg_Code_For_SV_File == baseOrgRec2.rOrg_Code_For_SV_File {
                    XCTFail("RecOrganizationDefs.orgGetAllRecs.\(stage): Deleted Rec2 still in database")
                } else if orgRec.rOrg_Code_For_SV_File == baseOrgRec3.rOrg_Code_For_SV_File {
                    XCTAssertTrue(orgRec.sameAs(baseRec:baseOrgRec3), "RecOrganizationDefs.orgGetAllRecs.\(stage): Rec3 retrieved not same as saved")
                } else {
                    XCTFail("RecOrganizationDefs.orgGetAllRecs.\(stage): Rec found with ID not matching any saved IDs")
                }
#endif
                cntr = cntr + 1
            }
            XCTAssertEqual(cntr, 2, "RecOrganizationDefs.orgGetAllRecs.\(stage): Found Qty Wrong")
            
            // stage 5
            stage = 5
            let orgRec1:RecOrganizationDefs? = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: baseOrgRec2.rOrg_Code_For_SV_File)
            XCTAssertNil(orgRec1, "RecOrganizationDefs.orgGetSpecifiedRecOfShortName.\(stage): Deleted Rec2 still in database")
            let orgRec2:RecOrganizationDefs? = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: baseOrgRec1.rOrg_Code_For_SV_File)
            XCTAssertNotNil(orgRec2, "RecOrganizationDefs.orgGetSpecifiedRecOfShortName.\(stage): Rec1 could not be retrieved")
#if TESTING
            XCTAssertTrue(orgRec2!.sameAs(baseRec:baseOrgRec1), "RecOrganizationDefs.orgGetSpecifiedRecOfShortName.\(stage): Rec1 retrieved not same as saved")
#endif
            
            // stage 6
            stage = 6
            let baseOrgRec4:RecOrganizationDefs = RecOrganizationDefs(existingRec: baseOrgRec3)
#if TESTING
            XCTAssertTrue(baseOrgRec4.sameAs(baseRec:baseOrgRec3), "RecOrganizationDefs(existingRec:).\(stage): Rec4 not same as Rec3")
#endif
            baseOrgRec4.rOrg_Email_To = "UPDATED!"
            baseOrgRec4.rOrg_Title_Mode = RecOrganizationDefs.ORG_TITLE_MODE.ONLY_TITLE
            baseOrgRec4.rOrg_Logo_Image_PNG_Blob = nil
            let intQty = try baseOrgRec4.saveChangesToDB(originalOrgRec: baseOrgRec3)
            XCTAssertEqual(intQty, 1, "RecOrganizationDefs.saveChangesToDB.\(stage): Updated Qty Wrong")
            let orgRec3:RecOrganizationDefs? = try RecOrganizationDefs.orgGetSpecifiedRecOfShortName(orgShortName: baseOrgRec4.rOrg_Code_For_SV_File)
            XCTAssertNotNil(orgRec3, "RecOrganizationDefs.orgGetSpecifiedRecOfShortName.\(stage): Updated Rec3 could not be retrieved")
#if TESTING
            XCTAssertTrue(orgRec3!.sameAs(baseRec:baseOrgRec4), "RecOrganizationDefs.saveChangesToDB.\(stage): Rec3 failed to update")
#endif
            
            // stage 7
            stage = 7
            var jsonObj:NSDictionary? = try baseOrgRec2.buildJSONObject()
            XCTAssertNotNil(jsonObj, "RecOrganizationDefs.buildJSONObject.\(stage): Rec2 could not be converted to JSON Objects")
            var jsonData:Data = try JSONSerialization.data(withJSONObject: jsonObj!, options: JSONSerialization.WritingOptions())
            XCTAssertNotNil(jsonData, "RecOrganizationDefs.JSONSerialization.data.\(stage): Rec2 could not be converted to JSON Data")
            var jsonObj2:NSDictionary = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions()) as! NSDictionary
            XCTAssertNotNil(jsonObj2, "RecOrganizationDefs.JSONSerialization.jsonObject.\(stage): Rec2 could not be re-converted back to JSON Objects")
            var orgRec4opt:RecOrganizationDefs_Optionals = RecOrganizationDefs_Optionals(jsonObj: jsonObj2)
            XCTAssertTrue(orgRec4opt.validate(), "RecOrganizationDefs.RecOrganizationDefs_Optionals(jsonObj:).\(stage): Rec2 did not re-convert back to Org Rec")
            var orgRec4:RecOrganizationDefs = try RecOrganizationDefs(existingRec: orgRec4opt)
#if TESTING
            XCTAssertTrue(orgRec4.sameAs(baseRec:baseOrgRec2), "RecOrganizationDefs.RecOrganizationDefs(existingRec:).\(stage): Rec2 failed its JSON conversions")
#endif
      
            // stage 8
            stage = 8
            jsonObj = try baseOrgRec1.buildJSONObject()
            XCTAssertNotNil(jsonObj, "RecOrganizationDefs.buildJSONObject.\(stage): Rec1 could not be converted to JSON Objects")
            jsonData = try JSONSerialization.data(withJSONObject: jsonObj!, options: JSONSerialization.WritingOptions())
            XCTAssertNotNil(jsonData, "RecOrganizationDefs.JSONSerialization.data.\(stage): Rec1 could not be converted to JSON Data")
            jsonObj2 = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions()) as! NSDictionary
            XCTAssertNotNil(jsonObj2, "RecOrganizationDefs.JSONSerialization.jsonObject.\(stage): Rec1 could not be re-converted back to JSON Objects")
            orgRec4opt = RecOrganizationDefs_Optionals(jsonObj: jsonObj2)
            XCTAssertTrue(orgRec4opt.validate(), "RecOrganizationDefs.RecOrganizationDefs_Optionals(jsonObj:).\(stage): Rec1 did notre-convert back to Org Rec")
            orgRec4 = try RecOrganizationDefs(existingRec: orgRec4opt)
#if TESTING
            XCTAssertTrue(orgRec4.sameAs(baseRec:baseOrgRec1), "RecOrganizationDefs.RecOrganizationDefs(existingRec:).\(stage): Rec1 failed its JSON conversions")
#endif
            
            // stage 9
            stage = 9
            jsonObj = try baseOrgRec3.buildJSONObject()
            XCTAssertNotNil(jsonObj, "RecOrganizationDefs.buildJSONObject.\(stage): Rec3 could not be converted to JSON Objects")
            jsonData = try JSONSerialization.data(withJSONObject: jsonObj!, options: JSONSerialization.WritingOptions())
            XCTAssertNotNil(jsonData, "RecOrganizationDefs.JSONSerialization.data.\(stage): Rec3 could not be converted to JSON Data")
            jsonObj2 = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions()) as! NSDictionary
            XCTAssertNotNil(jsonObj2, "RecOrganizationDefs.JSONSerialization.jsonObject.\(stage): Rec3 could not be re-converted back to JSON Objects")
            orgRec4opt = RecOrganizationDefs_Optionals(jsonObj: jsonObj2)
            XCTAssertTrue(orgRec4opt.validate(), "RecOrganizationDefs.RecOrganizationDefs_Optionals(jsonObj:).\(stage): Rec3 did not re-convert back to Org Rec")
            orgRec4 = try RecOrganizationDefs(existingRec: orgRec4opt)
#if TESTING
            XCTAssertTrue(orgRec4.sameAs(baseRec:baseOrgRec3), "RecOrganizationDefs.RecOrganizationDefs(existingRec:).\(stage): Rec3 failed its JSON conversions")
#endif
            
            
        } catch let errResult as Result {
            XCTFail("RecOrganizationDefs.*.\(stage): SQL Error thrown: \(errResult.localizedDescription)")
        } catch {
            XCTFail("RecOrganizationDefs.*.\(stage): Error thrown: \(error.localizedDescription)")
        }
    }
}
