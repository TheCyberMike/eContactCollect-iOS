//
//  FieldHandler.swift
//  eContact Collect
//
//  Created by Yo on 10/6/18.
//

import SQLite
import Eureka

// base handler class for the all the database handlers
public class FieldHandler {
    // member variables
    public var mFHstatus_state:HandlerStatusStates = .Unknown
    public var mAppError:APP_ERROR? = nil
    private var mFields_json:[RecJsonFieldDefs]? = nil
    private var mOptionSetLocales_json:[RecJsonOptionSetLocales]? = nil
    
    // member constants and other static content
    internal var mCTAG:String = "HFl"
    internal var mThrowErrorDomain:String = "FieldHandler"
    internal var mFILE_FIELDS_MAX_VERSION:Int = 1
    internal var mFILE_FIELDATTRIBS_MAX_VERSION:Int = 1
    
    // constructor;
    public init() {}
    
    // initialization; returns true if initialize fully succeeded; errors are stored via the class members;
    // this handler must be mindful that the database initialization may have failed
    public func initialize() -> Bool {
//debugPrint("\(mCTAG).initialize STARTED")
        self.mFHstatus_state = .Unknown
        
        // load JSON files temporarily to ensure they are present and valid
        let result:Bool = self.validateFiles()    // will properly set self.mFHstatus_state
        return result
    }
    
    // first-time setup is needed
    // this handler must be mindful that it or the database handler may not have properly initialized and should bypass this
    public func firstTimeSetup() throws {
//debugPrint("\(mCTAG).firstTimeSetup STARTED")
    }
    
    // return whether the handler is fully operational
    public func isReady() -> Bool {
        if self.mFHstatus_state == .Valid { return true }
        return false
    }
    
    // this will not get called during normal App operation, but does get called during Unit and UI Testing
    // perform any shutdown that may be needed
    internal func shutdown() {
        self.mFHstatus_state = .Unknown
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // methods used to get Language Information from JSON
    /////////////////////////////////////////////////////////////////////////////////////////

    public func getLangInfo(forLangRegion:String, noSubstitution:Bool=false) throws -> RecJsonLangDefs? {
        var jsonPath:String? = Bundle.main.path(forResource: "FieldLocales", ofType: "json", inDirectory: nil, forLocalization: forLangRegion)
        if (jsonPath ?? "").isEmpty {
            jsonPath = Bundle.main.path(forResource: "FieldLocales", ofType: "json")
        }
        if jsonPath == nil {
            self.mFHstatus_state = .Missing
            self.mAppError = APP_ERROR(during: NSLocalizedString("Load", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: nil)
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).getLangInfo", during: "Locate path", errorMessage: "Missing", extra: jsonPath)
            return nil
        }
        let jsonContents = FileManager.default.contents(atPath: jsonPath!)   // obtain the data in JSON format
        if jsonContents == nil {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(during: NSLocalizedString("Load", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: nil)
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).getLangInfo", during: "Load path", errorMessage: "Failed", extra: jsonPath)
            return nil
        }
        var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
        do {
            validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents!)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).getLangInfo", during: ".validateJSONdbFile", errorStruct: error, extra: jsonPath)
            throw error
        }
        if validationResult.jsonTopLevel!["method"] as! String != "eContactCollect.db.fieldLocales.factory" {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(during: NSLocalizedString("Verification", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: nil)
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).getLangInfo", during: "Validate top level", errorMessage: "'ethod' is invalid \(validationResult.jsonTopLevel!["method"] as! String)", extra: jsonPath)
            return nil
        }
        var getResult:DatabaseHandler.GetJSONdbFileTable_Result
        do {
            getResult = try DatabaseHandler.getJSONdbFileTable(forTableCode: "langs", forTableName: "Langs", needsItem: true, priorResult: validationResult)
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).getLangInfo", during: ".getJSONdbFileTable.langs", errorStruct: error, extra: jsonPath)
            throw error
        }
        if noSubstitution && validationResult.language != forLangRegion { return nil }
        let jsonLanDefRec:RecJsonLangDefs = RecJsonLangDefs(jsonRecObj: getResult.jsonItemLevel!, forDBversion: validationResult.databaseVersion)
        jsonLanDefRec.mLang_LangRegionCode = validationResult.language
        return jsonLanDefRec
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // methods used to create formfield definitions from JSON and RecOrgCustomFieldDefs with RecOrgCustomFieldLocales
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // flush the in-memory stored lists
    private func flushInMemoryObjects() {
        if self.mFields_json != nil {
            // deliberately force a flush of any existing in-memory objects
            self.mFields_json!.removeAll()
            self.mFields_json = nil
        }
        if self.mOptionSetLocales_json != nil {
            // deliberately force a flush of any existing in-memory objects
            self.mOptionSetLocales_json!.removeAll()
            self.mOptionSetLocales_json = nil
        }
    }
    
    // adds the default meta-data formFields to the new Form (only from JSON)
    // throws exceptions either for local errors or from the database
    public func addMetadataFormFieldsToNewForm(forFormRec:RecOrgFormDefs, withOrgRec:RecOrganizationDefs) throws {
        _ = self.loadPotentialFieldsForForm(forFormRec: forFormRec, withOrgRec: withOrgRec)
        
        for jsonFieldDefRec:RecJsonFieldDefs in self.mFields_json! {
            if jsonFieldDefRec.isMetaData() {
            
                let jsonFieldLocalesRec:RecJsonFieldLocales = jsonFieldDefRec.mJsonFieldLocalesRecs![0] // the SV-File language is always first

                // add the meta-data RecOrgFormFieldDefs
                let formFieldRecOpt:RecOrgFormFieldDefs_Optionals = RecOrgFormFieldDefs_Optionals(jsonRec: jsonFieldDefRec, forOrgShortName: withOrgRec.rOrg_Code_For_SV_File, forFormShortName: forFormRec.rForm_Code_For_SV_File, withJsonFieldLocaleRec: jsonFieldLocalesRec)
                if formFieldRecOpt.validate() {
                    let formFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(existingRec: formFieldRecOpt)
                    formFieldRec.rFormField_Order_SV_File =  RecOrgFormFieldDefs.getInternalSortOrderFromString(fromString: jsonFieldDefRec.rField_Sort_Order!)
                    formFieldRec.rFormField_Order_Shown = formFieldRec.rFormField_Order_SV_File
                    formFieldRec.rFormField_Index = try formFieldRec.saveNewToDB()
                    
                    // add all the associated RecJsonFieldLocales
                    for jsonFieldLocalesRec:RecJsonFieldLocales in jsonFieldDefRec.mJsonFieldLocalesRecs! {
                        let formFieldLocalesOptRec:RecOrgFormFieldLocales_Optionals = RecOrgFormFieldLocales_Optionals(jsonRec: jsonFieldLocalesRec, forFormFieldRec: formFieldRec, withJsonFormFieldRec: jsonFieldDefRec)
                        if formFieldLocalesOptRec.validate() {
                            let formFieldLocalesRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(existingRec: formFieldLocalesOptRec)
                            let _ = try formFieldLocalesRec.saveNewToDB()
                        }
                    }
                }
            }
        }
        
        self.flushInMemoryObjects()
    }
    
    // add one or more non-meta-data fields (by IDCode) to a form in the database; draws from JSON and any Custom fields
    // only the Org's default SV-File language is loaded
    // note: the Org and the Form are presumed to already exist in the database
    // throws exceptions either for local errors or from the database
    public func addFieldstoForm(field_IDCodes:[String], forFormRec:RecOrgFormDefs, withOrgRec:RecOrganizationDefs, orderSVfile:inout Int, orderShown:inout Int, asSubfieldsOf:Int64?=nil) throws {
        
        if field_IDCodes.count == 0 { return }
        _ = self.loadPotentialFieldsForForm(forFormRec: forFormRec, withOrgRec: withOrgRec)
        
        // step through all the submitted field_IDcodes; note that all errors are handled in the called functions
        for field_IDCode:String in field_IDCodes {
            let jsonFieldDefRec:RecJsonFieldDefs? = self.getJsonFormField(forFieldIDCode: field_IDCode)
            if jsonFieldDefRec != nil {
                let jsonFieldLocalesRec:RecJsonFieldLocales = jsonFieldDefRec!.mJsonFieldLocalesRecs![0] // SV-File language is always first
                
                // add the RecOrgFormFieldDefs as a field or a subfield as appropriate
                let formFieldRecOpt:RecOrgFormFieldDefs_Optionals = RecOrgFormFieldDefs_Optionals(jsonRec: jsonFieldDefRec!, forOrgShortName: withOrgRec.rOrg_Code_For_SV_File, forFormShortName: forFormRec.rForm_Code_For_SV_File, withJsonFieldLocaleRec: jsonFieldLocalesRec)
                if formFieldRecOpt.validate() {
                    let formFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(existingRec: formFieldRecOpt)
                    if asSubfieldsOf != nil {
                        formFieldRec.rFormField_SubField_Within_FormField_Index = asSubfieldsOf!
                        formFieldRec.rFormField_Order_SV_File =  orderSVfile
                        formFieldRec.rFormField_Order_Shown = orderShown
                        orderSVfile = orderSVfile + 10
                        orderShown = orderShown + 1
                    } else {
                        formFieldRec.rFormField_Order_SV_File =  orderSVfile
                        formFieldRec.rFormField_Order_Shown = orderShown
                        orderSVfile = orderSVfile + 10
                        orderShown = orderShown + 10
                    }
                    formFieldRec.rFormField_Index = -1
                    formFieldRec.rFormField_Index = try formFieldRec.saveNewToDB()
                    
                    // add all the associated RecJsonFieldLocales
                    for jsonFieldLocalesRec:RecJsonFieldLocales in jsonFieldDefRec!.mJsonFieldLocalesRecs! {
                        let formFieldLocalesOptRec:RecOrgFormFieldLocales_Optionals = RecOrgFormFieldLocales_Optionals(jsonRec: jsonFieldLocalesRec, forFormFieldRec: formFieldRec, withJsonFormFieldRec: jsonFieldDefRec!)
                        if formFieldLocalesOptRec.validate() {
                            let formFieldLocalesRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(existingRec: formFieldLocalesOptRec)
                            formFieldLocalesRec.rFormFieldLoc_Index = -1
                            let _ = try formFieldLocalesRec.saveNewToDB()
                        }
                    }
                    
                    // are there any subfields?
                    if (jsonFieldDefRec!.rFieldProp_Initial_Field_IDCodes?.count ?? 0) > 0 {
                        // recursive call to immediately add the additional subfields so the sort ordering is correct
                        try self.addFieldstoForm(field_IDCodes: jsonFieldDefRec!.rFieldProp_Initial_Field_IDCodes!, forFormRec: forFormRec, withOrgRec: withOrgRec, orderSVfile: &orderSVfile, orderShown: &orderShown, asSubfieldsOf: formFieldRec.rFormField_Index)
                    }
                }
            }
        }
        orderShown = ((orderShown / 10) + 1) * 10   // used when popping out of a recursive call
        if asSubfieldsOf == nil { self.flushInMemoryObjects() }
    }
    
    // locate a specific formFieldIDcode in the JSON dataset; returns nil if not found;
    // presumes that appropriate fields are preloaded
    private func getJsonFormField(forFieldIDCode:String) -> RecJsonFieldDefs? {
        if self.mFields_json == nil { return nil }
        for jsonFieldDefRec:RecJsonFieldDefs in self.mFields_json! {
            if jsonFieldDefRec.rFieldProp_IDCode == forFieldIDCode { return jsonFieldDefRec }
        }
        return nil
    }
    
    // get all available Field records from the JSON and in the database; sorted in alphanumeric order of the SortOrder
    // used solely by FormEditForm ViewController to present the list of possible fields to choose from;
    // throws exceptions either for local errors or from the database
    public func getAllAvailFieldIDCodes(withOrgRec:RecOrganizationDefs) -> ([CodePair], [String:String], [String:String]) {
        _ = self.loadPotentialFieldsForEditDisplay(withOrgRec: withOrgRec)
        
        var sortInx:Int = 1
        var currentSectionCode:String = ""
        var controlPairs:[CodePair] = []
        var sectionMap:[String:String] = [:]
        var sectionTitles:[String:String] = [:]
        
        for jsonFieldDefRec in self.mFields_json! {
            if !jsonFieldDefRec.isMetaData() {
                let jsonFieldLocalesRec:RecJsonFieldLocales = jsonFieldDefRec.mJsonFieldLocalesRecs![0]  // SV-File language is first
                if jsonFieldDefRec.isSectionHeader() {
                    currentSectionCode = String(format: "%02d ", sortInx) + jsonFieldDefRec.rFieldProp_IDCode!  // sections are sorted by the *key*
                    sectionTitles[currentSectionCode] = jsonFieldLocalesRec.rFieldLocProp_Name_For_Collector!
                    sortInx = sortInx + 1
                } else {
                    sectionMap[jsonFieldLocalesRec.rFieldLocProp_Name_For_Collector!] = currentSectionCode
                    let pairing:CodePair = CodePair(jsonFieldDefRec.rFieldProp_IDCode!, jsonFieldLocalesRec.rFieldLocProp_Name_For_Collector!)
                    controlPairs.append(pairing)
                }
            }
        }
        
        self.flushInMemoryObjects()
        return (controlPairs, sectionMap, sectionTitles)
    }
    
    // get a field's definitions (not added to the database); draws from the JSON and any Custom fields and can include meta-data fields;
    // also included are any subfields (if any);
    // only the Org's default SV-File language is loaded; caller is assumed to set fields such as form name and the sort order fields and subfield linkages;
    // throws exceptions either for local errors or from the database
    public func getFieldDefsAsMatchForEditing(forFieldIDCode:String, forFormRec:RecOrgFormDefs, withOrgRec:RecOrganizationDefs) throws -> OrgFormFields?  {
        _ = self.loadPotentialFieldsForForm(forFormRec: forFormRec, withOrgRec: withOrgRec)
        let forLangRegions:[String] = self.pickFormsLanguages(forFormRec: forFormRec, withOrgRec: withOrgRec)
        let results:OrgFormFields = OrgFormFields()

        // load the primary field
        let fieldEntry:OrgFormFieldsEntry? = self.getOneMatchForEditing(forFieldIDCode: forFieldIDCode, forFormRec: forFormRec, withOrgRec: withOrgRec, forLangRegions: forLangRegions)
        if fieldEntry == nil { self.flushInMemoryObjects(); return nil }
        results.appendNewDuringEditing(fieldEntry!) // auto-assigns temporary indexes within the local context of the return results
        
        // now load for any require subfields
        if (fieldEntry!.mFormFieldRec.rFieldProp_Contains_Field_IDCodes?.count ?? 0) > 0 {
            for subFieldIDCode in fieldEntry!.mFormFieldRec.rFieldProp_Contains_Field_IDCodes! {
                let subfieldEntry:OrgFormFieldsEntry? = self.getOneMatchForEditing(forFieldIDCode: subFieldIDCode, forFormRec: forFormRec, withOrgRec: withOrgRec, forLangRegions: forLangRegions)
                if subfieldEntry != nil {
                    subfieldEntry!.mFormFieldRec.rFormField_SubField_Within_FormField_Index = fieldEntry!.mFormFieldRec.rFormField_Index
                    results.appendNewDuringEditing(subfieldEntry!)  // auto-assigns temporary indexes
                }
            }
        }
        
        self.flushInMemoryObjects()
        return results
    }
    
    // get just one match
    private func getOneMatchForEditing(forFieldIDCode:String, forFormRec:RecOrgFormDefs, withOrgRec:RecOrganizationDefs, forLangRegions:[String]) -> OrgFormFieldsEntry? {
        let jsonFieldDefRec:RecJsonFieldDefs? = self.getJsonFormField(forFieldIDCode: forFieldIDCode)
        if jsonFieldDefRec == nil { return nil }
        return makeEntry(jsonFieldDefRec: jsonFieldDefRec!, forFormRec: forFormRec, withOrgRec: withOrgRec, forLangRegions: forLangRegions)
    }
    
    // make an OrgFormFieldsEntry for a match
    private func makeEntry(jsonFieldDefRec:RecJsonFieldDefs, forFormRec:RecOrgFormDefs, withOrgRec:RecOrganizationDefs, forLangRegions:[String]) -> OrgFormFieldsEntry? {
        let jsonFieldLocalesRec:RecJsonFieldLocales = jsonFieldDefRec.mJsonFieldLocalesRecs![0]  // SV-File language is always first
        
        let formFieldRecOpt:RecOrgFormFieldDefs_Optionals = RecOrgFormFieldDefs_Optionals(jsonRec: jsonFieldDefRec, forOrgShortName: withOrgRec.rOrg_Code_For_SV_File, forFormShortName: nil, withJsonFieldLocaleRec: jsonFieldLocalesRec)
        if !formFieldRecOpt.validate() { return nil }
        var formFieldRec:RecOrgFormFieldDefs
        do {
            formFieldRec = try RecOrgFormFieldDefs(existingRec: formFieldRecOpt)
        } catch { return nil }
        if jsonFieldDefRec.isMetaData() {
            formFieldRec.rFormField_Order_SV_File =  RecOrgFormFieldDefs.getInternalSortOrderFromString(fromString: jsonFieldDefRec.rField_Sort_Order!)
            formFieldRec.rFormField_Order_Shown = formFieldRec.rFormField_Order_SV_File
        }
        
        // add all the associated RecJsonFieldLocales and create a RecOrgFormFieldLocales_Composed
        formFieldRec.mFormFieldLocalesRecs = []
        var checkShown:Bool = false
        if withOrgRec.rOrg_LangRegionCodes_Supported[0] != forLangRegions[0] { checkShown = true }
        let formLingualCnt:Int = (forFormRec.rForm_Lingual_LangRegions?.count ?? 0)
        let formFieldLocalesComposedRec:RecOrgFormFieldLocales_Composed = RecOrgFormFieldLocales_Composed(jsonRec: jsonFieldLocalesRec, forFormFieldRec: formFieldRec)
        for jsonFieldLocalesRec:RecJsonFieldLocales in jsonFieldDefRec.mJsonFieldLocalesRecs! {
            let formFieldLocalesOptRec:RecOrgFormFieldLocales_Optionals = RecOrgFormFieldLocales_Optionals(jsonRec: jsonFieldLocalesRec, forFormFieldRec: formFieldRec, withJsonFormFieldRec: jsonFieldDefRec)
            if formFieldLocalesOptRec.validate() {
                var formFieldLocalesRec:RecOrgFormFieldLocales
                do {
                    formFieldLocalesRec = try RecOrgFormFieldLocales(existingRec: formFieldLocalesOptRec)
                } catch { return nil }  // cannot occur since validate passed
                formFieldLocalesComposedRec.mLocale1LangRegion = formFieldLocalesRec.rFormFieldLoc_LangRegionCode
                formFieldLocalesRec.rFormFieldLoc_Index = -1
                formFieldRec.mFormFieldLocalesRecs!.append(formFieldLocalesRec)
                if formLingualCnt >= 1 {
                    if forFormRec.rForm_Lingual_LangRegions![0] == formFieldLocalesRec.rFormFieldLoc_LangRegionCode {
                        formFieldLocalesComposedRec.rFieldLocProp_Name_Shown = formFieldLocalesRec.rFieldLocProp_Name_Shown
                        formFieldLocalesComposedRec.rFieldLocProp_Placeholder_Shown = formFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        formFieldLocalesComposedRec.rFieldLocProp_Options_Name_Shown = formFieldLocalesRec.rFieldLocProp_Options_Name_Shown
                        formFieldLocalesComposedRec.rFieldLocProp_Metadatas_Name_Shown = formFieldLocalesRec.rFieldLocProp_Metadatas_Name_Shown
                        formFieldLocalesComposedRec.mLocale2LangRegion = formFieldLocalesRec.rFormFieldLoc_LangRegionCode
                    }
                    if formLingualCnt >= 2 {
                        if forFormRec.rForm_Lingual_LangRegions![1] == formFieldLocalesRec.rFormFieldLoc_LangRegionCode {
                            formFieldLocalesComposedRec.mFieldLocProp_Name_Shown_Bilingual_2nd = formFieldLocalesRec.rFieldLocProp_Name_Shown
                            formFieldLocalesComposedRec.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = formFieldLocalesRec.rFieldLocProp_Options_Name_Shown
                            formFieldLocalesComposedRec.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd = formFieldLocalesRec.rFieldLocProp_Metadatas_Name_Shown
                            formFieldLocalesComposedRec.mLocale3LangRegion = formFieldLocalesRec.rFormFieldLoc_LangRegionCode
                        }
                    }
                } else if checkShown {
                    if withOrgRec.rOrg_LangRegionCodes_Supported[0] == formFieldLocalesRec.rFormFieldLoc_LangRegionCode {
                        formFieldLocalesComposedRec.rFieldLocProp_Name_Shown = formFieldLocalesRec.rFieldLocProp_Name_Shown
                        formFieldLocalesComposedRec.rFieldLocProp_Placeholder_Shown = formFieldLocalesRec.rFieldLocProp_Placeholder_Shown
                        formFieldLocalesComposedRec.rFieldLocProp_Options_Name_Shown = formFieldLocalesRec.rFieldLocProp_Options_Name_Shown
                        formFieldLocalesComposedRec.rFieldLocProp_Metadatas_Name_Shown = formFieldLocalesRec.rFieldLocProp_Metadatas_Name_Shown
                        formFieldLocalesComposedRec.mLocale2LangRegion = formFieldLocalesRec.rFormFieldLoc_LangRegionCode
                    }
                }
            }
        }
        
        let entry:OrgFormFieldsEntry = OrgFormFieldsEntry(formFieldRec: formFieldRec, composedFormFieldLocalesRec: formFieldLocalesComposedRec, composedOptionSetLocalesRecs: nil)
        entry.mDuringEditing_isDefault = true
        return entry
    }
    
    // get fully specified subfields allowed for a container field; returns empty array if none are allowed;
    public func getAllowedSubfieldEntriesForEditing(forPrimaryFormFieldRec:RecOrgFormFieldDefs, forFormRec:RecOrgFormDefs, withOrgRec:RecOrganizationDefs) -> OrgFormFields {
        _ = self.loadPotentialFieldsForForm(forFormRec: forFormRec, withOrgRec: withOrgRec)
        let forLangRegions:[String] = self.pickFormsLanguages(forFormRec: forFormRec, withOrgRec: withOrgRec)
        let results:OrgFormFields = OrgFormFields()
        
        let primeJsonFieldDefRec:RecJsonFieldDefs? = self.getJsonFormField(forFieldIDCode: forPrimaryFormFieldRec.rFieldProp_IDCode)
        if primeJsonFieldDefRec == nil { self.flushInMemoryObjects(); return results }
        if (primeJsonFieldDefRec!.rFieldProp_Allows_Field_IDCodes?.count ?? 0) == 0 { self.flushInMemoryObjects(); return results }
        var workingSubSortSVfileOrder:Int = forPrimaryFormFieldRec.rFormField_Order_SV_File + 1
        var workingSubSortShownOrder:Int = forPrimaryFormFieldRec.rFormField_Order_Shown + 1
        
        for fieldIDCode in primeJsonFieldDefRec!.rFieldProp_Allows_Field_IDCodes! {
            let subJsonFieldDefRec:RecJsonFieldDefs? = self.getJsonFormField(forFieldIDCode: fieldIDCode)
            if subJsonFieldDefRec != nil {
                let entry:OrgFormFieldsEntry? = makeEntry(jsonFieldDefRec: subJsonFieldDefRec!, forFormRec: forFormRec, withOrgRec: withOrgRec, forLangRegions: forLangRegions)
                if entry != nil {
                    entry!.mFormFieldRec.rFormField_Order_SV_File =  workingSubSortSVfileOrder
                    entry!.mFormFieldRec.rFormField_Order_Shown = workingSubSortShownOrder
                    entry!.mFormFieldRec.rFormField_SubField_Within_FormField_Index = forPrimaryFormFieldRec.rFormField_Index
                    workingSubSortSVfileOrder = workingSubSortSVfileOrder + 1
                    workingSubSortShownOrder = workingSubSortShownOrder + 1
                    results.appendNewDuringEditing(entry!)   // auto-assigns temporary indexes within the local context of the return results
                }
            }
        }
        
        self.flushInMemoryObjects()
        return results
    }
    
    // get and compose a RecOptionSetLocales with proper information in its subsections from proper languages;
    // return an empty array if nothing found to match
    private func getMatchingOptionSetLocales(forOSLC:String, forSVFileLang:String, forShownLang:String) -> [RecOptionSetLocales_Composed] {
        var returnArray:[RecOptionSetLocales_Composed] = []
        
        _ = self.loadOptionSetLocalesDefaults(forLangRegion: forSVFileLang)
        for jsonOSLrec:RecJsonOptionSetLocales in self.mOptionSetLocales_json! {
            if jsonOSLrec.rOptionSetLoc_Code == forOSLC {
                let oslComposedRec:RecOptionSetLocales_Composed = RecOptionSetLocales_Composed(jsonRec: jsonOSLrec)
                
                oslComposedRec.mLocale1LangRegion = oslComposedRec.rOptionSetLoc_LangRegionCode
                if oslComposedRec.rOptionSetLoc_LangRegionCode == forShownLang {
                    oslComposedRec.mLocale2LangRegion = oslComposedRec.rOptionSetLoc_LangRegionCode
                }
                returnArray.append(oslComposedRec)
            }
        }
        if forSVFileLang == forShownLang { return returnArray }
        
        _ = self.loadOptionSetLocalesDefaults(forLangRegion: forShownLang)
        for jsonOSLrec:RecJsonOptionSetLocales in self.mOptionSetLocales_json! {
            if jsonOSLrec.rOptionSetLoc_Code == forOSLC {
                let oslComposedRec:RecOptionSetLocales_Composed = RecOptionSetLocales_Composed(jsonRec: jsonOSLrec)
                
                for savedOSLrec in returnArray {
                    if savedOSLrec.rOptionSetLoc_Code == oslComposedRec.rOptionSetLoc_Code &&
                        savedOSLrec.rOptionSetLoc_Code_Extension == oslComposedRec.rOptionSetLoc_Code_Extension {
                        
                        savedOSLrec.rFieldLocProp_Options_Name_Shown = oslComposedRec.rFieldLocProp_Options_Name_Shown
                        savedOSLrec.mLocale2LangRegion = oslComposedRec.rOptionSetLoc_LangRegionCode
                        break
                    }
                }
            }
        }
        return returnArray
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // methods used to load and temporarily store in-memory potential formfield definitions from JSON and RecOrgCustomFieldDefs with RecOrgCustomFieldLocales
    /////////////////////////////////////////////////////////////////////////////////////////
    
    private func pickFormsLanguages(forFormRec: RecOrgFormDefs, withOrgRec:RecOrganizationDefs) -> [String] {
        var forLangRegions:[String] = []
        
        // SV-File language is always first
        if !withOrgRec.rOrg_LangRegionCode_SV_File.isEmpty { forLangRegions = [withOrgRec.rOrg_LangRegionCode_SV_File] }
        
        // choose the proper languages depending upon the various configurations
        var cnt:Int = withOrgRec.rOrg_LangRegionCodes_Supported.count
        if cnt == 0 {
            // Org is single lingual mode but has no language defined; this should not happen
            if withOrgRec.rOrg_LangRegionCode_SV_File.isEmpty {
                // Org is single lingual mode but has no language defined
                if !forLangRegions.contains(AppDelegate.mDeviceLangRegion) { forLangRegions.append(AppDelegate.mDeviceLangRegion) }
            } else {
                // Org is single lingual mode
                if !forLangRegions.contains(withOrgRec.rOrg_LangRegionCode_SV_File) { forLangRegions.append(withOrgRec.rOrg_LangRegionCode_SV_File) }
            }
        } else if cnt == 1 {
            // Org is single lingual mode
            if !forLangRegions.contains(withOrgRec.rOrg_LangRegionCodes_Supported[0]) { forLangRegions.append(withOrgRec.rOrg_LangRegionCodes_Supported[0]) }
        } else {
            // Org is multi lingual mode
            cnt = (forFormRec.rForm_Lingual_LangRegions?.count ?? 0)
            if cnt == 1 {
                // form is mono lingual mode
                if !forLangRegions.contains(forFormRec.rForm_Lingual_LangRegions![0]) { forLangRegions.append(forFormRec.rForm_Lingual_LangRegions![0]) }
            } else if cnt == 2 {
                // form is bi lingual mode
                if !forLangRegions.contains(forFormRec.rForm_Lingual_LangRegions![0]) { forLangRegions.append(forFormRec.rForm_Lingual_LangRegions![0]) }
                if !forLangRegions.contains(forFormRec.rForm_Lingual_LangRegions![1]) { forLangRegions.append(forFormRec.rForm_Lingual_LangRegions![1]) }
            } else {
                // form uses all the Org's languages
                for hasLangRegion in withOrgRec.rOrg_LangRegionCodes_Supported {
                    if !forLangRegions.contains(hasLangRegion) { forLangRegions.append(hasLangRegion) }
                }
            }
        }
        return forLangRegions
    }
    
    
    // validate all the files during App startup; do not keep the loaded data in-memory
    private func validateFiles() -> Bool {
        self.flushInMemoryObjects()
        var result:Bool = true
        let allLocalizations = AppDelegate.getAppsLocalizations()
        if !self.loadFieldDefaults() { result = false }
        if !self.mergeInFieldLocalesDefaults(forLangRegions: allLocalizations, validate: true) { result =  false }
        for aLocale in allLocalizations {
            if !self.loadOptionSetLocalesDefaults(forLangRegion: aLocale, validate: true) { result =  false }
        }
        self.flushInMemoryObjects()
        if result { self.mFHstatus_state = .Valid }
        return result
    }
    
    private func loadPotentialFieldsForEditDisplay(withOrgRec: RecOrganizationDefs) -> Bool {
        self.flushInMemoryObjects()
        var result:Bool = true
        
        let forLangRegions:[String] = [withOrgRec.rOrg_LangRegionCode_SV_File]
        
        if !self.loadFieldDefaults() { result = false }
        if !self.mergeInFieldLocalesDefaults(forLangRegions: forLangRegions) { result =  false }
        return result
    }
    
    private func loadPotentialFieldsForForm(forFormRec: RecOrgFormDefs, withOrgRec:RecOrganizationDefs) -> Bool {
        self.flushInMemoryObjects()
        var result:Bool = true
        
        // pre-determine the languages needed
        let forLangRegions:[String] = self.pickFormsLanguages(forFormRec: forFormRec, withOrgRec: withOrgRec)

        if !self.loadFieldDefaults() { result = false }
        if !self.mergeInFieldLocalesDefaults(forLangRegions: forLangRegions) { result =  false }
        return result
    }

    // load the FieldDefs.json file plus any custom fields in the database
    private func loadFieldDefaults() -> Bool {
        // locate the file in the proper non-localized folder
        let jsonPath1:String? = Bundle.main.path(forResource: "FieldDefs", ofType: "json")  // this file is not localized
        self.mFields_json = []
        if jsonPath1 == nil {
            self.mFHstatus_state = .Missing
            self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: "FieldDefs.json")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadFieldDefaults", during: "Locate path", errorMessage: "Missing", extra: jsonPath1)
            return false
        }
        let jsonContents1 = FileManager.default.contents(atPath: jsonPath1!)   // obtain the data in JSON format
        if jsonContents1 == nil {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: "FieldDefs.json")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadFieldDefaults", during: "Load path", errorMessage: "Failed", extra: jsonPath1)
            return false
        }
        var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
        do {
            validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents1!)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError?.during = NSLocalizedString("Load Defaults", comment:"")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadFieldDefaults", during: ".validateJSONdbFile", errorStruct: error, extra: jsonPath1)
            return false
        }
        if validationResult.jsonTopLevel!["method"] as! String != "eContactCollect.db.fieldDefs.factory" {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldDefs.json")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadFieldDefaults", during: "Validate top level", errorMessage: "Method is invalid \(validationResult.jsonTopLevel!["method"] as! String)", extra: jsonPath1)
            return false
        }
        var getResult:DatabaseHandler.GetJSONdbFileTable_Result
        do {
            getResult = try DatabaseHandler.getJSONdbFileTable(forTableCode: "fieldDefs", forTableName: "FieldDefs", needsItem: false, priorResult: validationResult)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError?.during = NSLocalizedString("Load Defaults", comment:"")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadFieldDefaults", during: ".getJSONdbFileTable.fieldDefs", errorStruct: error, extra: jsonPath1)
            return false
        }
        
        // all valid thus far; now read all the records in the JSON file
        var itemNo:Int = 0
        for jsonRecAny in getResult.jsonItemsLevel! {
            // these are the individual records
            let jsonRecObj:NSDictionary? = jsonRecAny as? NSDictionary
            if jsonRecObj == nil {
                self.mFHstatus_state = .Errors
                self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldDefs.json")
                AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).loadFieldDefaults", during:"Validate record level", errorMessage:"Failed to find record, item \(itemNo)", extra:jsonPath1)
                return false
            } else {
                let jsonFieldRec:RecJsonFieldDefs = RecJsonFieldDefs(jsonRecObj: jsonRecObj!, forDBversion: validationResult.databaseVersion)
                if (jsonFieldRec.rFieldProp_IDCode ?? "").isEmpty {
                    self.mFHstatus_state = .Invalid
                    self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldDefs.json")
                    AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).loadFieldDefaults", during:"Validate record level", errorMessage:"Item# \(itemNo) invalid", extra:jsonPath1)
                    return false
                }
                jsonFieldRec.mJsonFieldLocalesRecs = []
                self.mFields_json!.append(jsonFieldRec)
                itemNo = itemNo + 1
            }
        }
        
        // now add in any custom Fields from the database
        // ?? FUTURE
        
        return true
    }
    
    // merge in the FieldLocales.json plus any custom Locales in the database
    private func mergeInFieldLocalesDefaults(forLangRegions:[String], validate:Bool=false) -> Bool {
        for forLangRegion in forLangRegions {
            // locate the file in the proper or best localization folder
            var jsonPath2:String? = nil
            if !forLangRegion.isEmpty {
                jsonPath2 = Bundle.main.path(forResource: "FieldLocales", ofType: "json", inDirectory: nil, forLocalization: forLangRegion)
            }
            if (jsonPath2 ?? "").isEmpty {
                jsonPath2 = Bundle.main.path(forResource: "FieldLocales", ofType: "json")
            }
            if jsonPath2 == nil {
                self.mFHstatus_state = .Missing
                self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: "FieldLocales.json")
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mergeInFieldLocalesDefaults.\(forLangRegion)", during: "Locate path", errorMessage: "Missing", extra: jsonPath2)
                return false
            }
//debugPrint("\(self.mCTAG).loadFiles.FieldLocales PATH=\(jsonPath2!)")
            // read the file, parse the JSON, and validate the file's JSON headers
            let jsonContents2 = FileManager.default.contents(atPath: jsonPath2!)   // obtain the data in JSON format
            if jsonContents2 == nil {
                self.mFHstatus_state = .Errors
                self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: "FieldLocales.json")
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mergeInFieldLocalesDefaults.\(forLangRegion)", during: "Load path", errorMessage: "Failed", extra: jsonPath2)
                return false
            }
            var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
            do {
                validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents2!)
            } catch {
                self.mFHstatus_state = .Errors
                self.mAppError = (error as! APP_ERROR)
                self.mAppError?.during = NSLocalizedString("Load Defaults", comment:"")
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mergeInFieldLocalesDefaults", during: ".validateJSONdbFile", errorStruct: error, extra: jsonPath2)
                return false
            }
            if validationResult.jsonTopLevel!["method"] as! String != "eContactCollect.db.fieldLocales.factory" {
                self.mFHstatus_state = .Errors
                self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldLocales.json")
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mergeInFieldLocalesDefaults.\(forLangRegion)", during: "Validate top level", errorMessage: "Method is invalid \(validationResult.jsonTopLevel!["method"] as! String)", extra: jsonPath2)
                return false
            }
            var getResult:DatabaseHandler.GetJSONdbFileTable_Result
            do {
                getResult = try DatabaseHandler.getJSONdbFileTable(forTableCode: "fieldLocales_packed", forTableName: "FieldLocales_packed", needsItem: false, priorResult: validationResult)
            } catch {
                self.mFHstatus_state = .Errors
                self.mAppError = (error as! APP_ERROR)
                self.mAppError?.during = NSLocalizedString("Load Defaults", comment:"")
                AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).mergeInFieldLocalesDefaults", during: ".getJSONdbFileTable.fieldLocales", errorStruct: error, extra: jsonPath2)
                return false
            }
            
            // all valid thus far; now read all the records in the JSON file
            var itemNo:Int = 0
            for jsonRecAny in getResult.jsonItemsLevel! {
                // these are the individual records
                let jsonRecObj:NSDictionary? = jsonRecAny as? NSDictionary
                if jsonRecObj == nil {
                    self.mFHstatus_state = .Errors
                    self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldLocales.json")
                    AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).mergeInFieldLocalesDefaults.\(forLangRegion)", during:"Validate record level", errorMessage:"Failed to find record, item \(itemNo)", extra:jsonPath2)
                    return false
                } else {
                    let jsonFieldLocalesRec:RecJsonFieldLocales = RecJsonFieldLocales(jsonRecObj: jsonRecObj!, forDBversion: validationResult.databaseVersion)
                    if (jsonFieldLocalesRec.rField_IDCode ?? "").isEmpty {
                        self.mFHstatus_state = .Invalid
                        self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldLocales.json")
                        AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).mergeInFieldLocalesDefaults.\(forLangRegion)", during:"Validate record level", errorMessage:"Item# \(itemNo) invalid", extra:jsonPath2)
                        return false
                    }
                    jsonFieldLocalesRec.mFormFieldLoc_LangRegionCode = validationResult.language
                    
                    // now match this jsonFieldLocalesRec with an existing jsonFieldRec in self.mFields_json
                    var found:Bool = false
                    for jsonFieldRec:RecJsonFieldDefs in self.mFields_json! {
                        if jsonFieldRec.rFieldProp_IDCode == jsonFieldLocalesRec.rField_IDCode {
                            jsonFieldRec.mJsonFieldLocalesRecs!.append(jsonFieldLocalesRec)
                            found = true
                            break
                        }
                    }
                    if !found {
                        self.mFHstatus_state = .Invalid
                        self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldLocales.json")
                        AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).mergeInFieldLocalesDefaults.\(forLangRegion)", during:"Validate record level", errorMessage:"Item# \(itemNo) \(jsonFieldLocalesRec.rField_IDCode!): Field IDCode does not match one in FieldDefs.json", extra:jsonPath2)
                        return false
                    }
                    itemNo = itemNo + 1
                }
            }
            
            // only perform this cross-check during App startup
            if validate {
                for jsonFieldRec:RecJsonFieldDefs in self.mFields_json! {
                    if jsonFieldRec.mJsonFieldLocalesRecs!.count == 0 {
                        self.mFHstatus_state = .Invalid
                        self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldLocales.json")
                        AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).mergeInFieldLocalesDefaults.\(forLangRegion)", during:"Validate record level", errorMessage:"Entry for FieldDefs.json Field IDCode '\(jsonFieldRec.rFieldProp_IDCode!)' is not present", extra:jsonPath2)
                        return false
                    }
                    jsonFieldRec.mJsonFieldLocalesRecs = []
                }
            }
            
            // now merge in any custom Fields from the database for this forLangRegion
            // ?? FUTURE
        }   // end of forLangRegion for loop
        
        return true
    }
    
    private func loadOptionSetLocalesDefaults(forLangRegion:String, validate:Bool=false) -> Bool {
        // locate the file in the proper or best localization folder
        var jsonPath3:String? = nil
        if !forLangRegion.isEmpty {
            jsonPath3 = Bundle.main.path(forResource: "OptionSetLocales", ofType: "json", inDirectory: nil, forLocalization: forLangRegion)
        }
        if (jsonPath3 ?? "").isEmpty {
            jsonPath3 = Bundle.main.path(forResource: "OptionSetLocales", ofType: "json")
        }
        self.mOptionSetLocales_json = []
        if jsonPath3 == nil {
            self.mFHstatus_state = .Missing
            self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: "OptionSetLocales.json")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadOptionSetDefaults.\(forLangRegion)", during: "Locate path", errorMessage: "Missing", extra: jsonPath3)
            return false
        }
//debugPrint("\(self.mCTAG).loadFiles.FieldsLocale PATH=\(jsonPath3!)")
        let jsonContents3 = FileManager.default.contents(atPath: jsonPath3!)   // obtain the data in JSON format
        if jsonContents3 == nil {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: "OptionSetLocales.json")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadOptionSetDefaults.\(forLangRegion)", during: "Load path", errorMessage: "Failed", extra: jsonPath3)
            return false
        }
        var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
        do {
            validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents3!)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError?.during = NSLocalizedString("Load Defaults", comment:"")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadOptionSetDefaults", during: ".validateJSONdbFile", errorStruct: error, extra: jsonPath3)
            return false
        }
        if validationResult.jsonTopLevel!["method"] as! String != "eContactCollect.db.optionSetLocs.factory" {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "OptionSetLocales.json")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadOptionSetDefaults.\(forLangRegion)", during: "Validate top level", errorMessage: "Method is invalid \(validationResult.jsonTopLevel!["method"] as! String)", extra: jsonPath3)
            return false
        }
        var getResult:DatabaseHandler.GetJSONdbFileTable_Result
        do {
            getResult = try DatabaseHandler.getJSONdbFileTable(forTableCode: "optionSetLocales_packed", forTableName: "OptionSetLocales_packed", needsItem: false, priorResult: validationResult)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError?.during = NSLocalizedString("Load Defaults", comment:"")
            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).loadOptionSetDefaults", during: ".getJSONdbFileTable.optionSetLocales", errorStruct: error, extra: jsonPath3)
            return false
        }

        // all valid thus far; now read all the records in the JSON file
        var itemNo:Int = 0
        for jsonRecAny in getResult.jsonItemsLevel! {
            // these are the individual records
            let jsonRecObj:NSDictionary? = jsonRecAny as? NSDictionary
            if jsonRecObj == nil {
                self.mFHstatus_state = .Errors
                self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "FieldAttribLocales.json")
                AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).loadOptionSetDefaults.\(forLangRegion)", during:"Validate record level", errorMessage:"Failed to find record, item \(itemNo)", extra:jsonPath3)
                return false
            } else {
                let jsonOptionSetLocaleRec:RecJsonOptionSetLocales = RecJsonOptionSetLocales(jsonRecObj: jsonRecObj!, forDBversion: validationResult.databaseVersion)
                if (jsonOptionSetLocaleRec.rOptionSetLoc_Code ?? "").isEmpty {
                    self.mFHstatus_state = .Invalid
                    self.mAppError = APP_ERROR(during: NSLocalizedString("Load Defaults", comment:""), domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: "OptionSetLocales.json")
                    AppDelegate.postToErrorLogAndAlert(method:"\(self.mCTAG).loadOptionSetDefaults.\(forLangRegion)", during:"Validate record level", errorMessage:"Item# \(itemNo) invalid", extra:jsonPath3)
                    return false
                }
                jsonOptionSetLocaleRec.mOptionSetLoc_LangRegionCode = validationResult.language
                self.mOptionSetLocales_json!.append(jsonOptionSetLocaleRec)
                itemNo = itemNo + 1
            }
        }
        // performing App startup validations
        if validate {
            self.mOptionSetLocales_json!.removeAll()
        }
        
        return true
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // methods used to interate through a Form's FormFields pulling in reference Field records
    // these methods do not directly utilize the JSON files except to pull in a union of JSON & custom RecFieldAttribLocales when needed
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // get all the necessary records to layout or edit a form in the proper and current languages; already sorted in the desired order
    // primarily used by the Entry & EntryForm and FormEdit ViewControllers
    // throws exceptions either for local errors or from the database
    public func getOrgFormFields(forEFP:EntryFormProvisioner, forceLangRegion:String?, includeOptionSets:Bool, metaDataOnly:Bool, sortedBySVFileOrder:Bool, forEditing:Bool=false) throws -> OrgFormFields {
        let results:OrgFormFields = OrgFormFields()
        if forEFP.mFormRec == nil { return results }

        // pre-determine the languages needed
        var forLangRegionShown1st:String = ""
        var forLangRegionShown2nd:String = ""
        if !(forceLangRegion ?? "").isEmpty {
            // the caller needs a specific language regardless of the form's and org's and AppDelegate current's settings
            forLangRegionShown1st = forceLangRegion!
        } else {
            forLangRegionShown1st = forEFP.mShownLanguage
            if forEFP.mShowMode == .BILINGUAL { forLangRegionShown2nd = forEFP.mShownBilingualLanguage }
        }
        
        // pre-load all the form's RecOrgFormFieldLocales
        var formFieldLocaleRecs:[RecOrgFormFieldLocales] = []
        let rows:AnySequence<SQLite.Row> = try RecOrgFormFieldLocales.formFieldLocalesGetAllRecs(forOrgShortName: forEFP.mOrgRec.rOrg_Code_For_SV_File, forFormShortName: forEFP.mFormRec!.rForm_Code_For_SV_File)
        for row in rows {
            let formFieldLocaleRec:RecOrgFormFieldLocales = try RecOrgFormFieldLocales(row:row)
            formFieldLocaleRecs.append(formFieldLocaleRec)
        }
        
        // get all the form's RecOrgFormFieldDefs
        let rows2:AnySequence<SQLite.Row> = try RecOrgFormFieldDefs.orgFormFieldGetAllRecs(forOrgShortName: forEFP.mOrgRec.rOrg_Code_For_SV_File, forFormShortName: forEFP.mFormRec!.rForm_Code_For_SV_File, sortedBySVFileOrder: sortedBySVFileOrder)
        
        // process the rows, matching in Locales and Attributes
        for row in rows2 {
            let formFieldRec:RecOrgFormFieldDefs = try RecOrgFormFieldDefs(row:row)
//debugPrint("\(self.mCTAG).getFormsFields found#\(formFieldRec.rFormField_Index!)")
            if !metaDataOnly || (metaDataOnly && formFieldRec.isMetaData()) {
                let formFieldLocalesComposedRec:RecOrgFormFieldLocales_Composed? = try self.makeComposedFormFieldLocale(forFormFieldRec: formFieldRec, forLangSVFile: forEFP.mOrgRec.rOrg_LangRegionCode_SV_File, forLangShown1st: forLangRegionShown1st, forLangShown2nd: forLangRegionShown2nd, viaArray: formFieldLocaleRecs, forEditing: forEditing)
                
                var optionSetLocalesComposedRecs:[RecOptionSetLocales_Composed] = []
                if includeOptionSets && (formFieldRec.rFieldProp_Options_Code_For_SV_File?.count() ?? 0) > 0 {
                    for svCP in formFieldRec.rFieldProp_Options_Code_For_SV_File!.mAttributes {
                        if svCP.codeString.starts(with: "***OSLC_") {
                            let oslc:String = String(svCP.codeString.suffix(from: svCP.codeString.index(svCP.codeString.startIndex, offsetBy: 3)))
                            optionSetLocalesComposedRecs = self.getMatchingOptionSetLocales(forOSLC: oslc, forSVFileLang: forEFP.mOrgRec.rOrg_LangRegionCode_SV_File, forShownLang: forLangRegionShown1st)
                            break
                        }
                    }
                }
                results.appendFromDatabase(OrgFormFieldsEntry(formFieldRec: formFieldRec, composedFormFieldLocalesRec: formFieldLocalesComposedRec!, composedOptionSetLocalesRecs: optionSetLocalesComposedRecs))
            }
        }
        self.flushInMemoryObjects()
        return results
    }
    
    // change the shown language in a set of pre-existing entries in OrgFormFields in a EFP
    public func changeOrgFormFieldsLanguageShown(forEFP:EntryFormProvisioner, forceLangRegion:String?, forEditing:Bool=false) throws {
        if forEFP.mFormRec == nil { return }
        if forEFP.mFormFieldEntries == nil { return }
        
        // pre-determine the languages needed
        var forLangRegionShown1st:String = ""
        var forLangRegionShown2nd:String = ""
        if !(forceLangRegion ?? "").isEmpty {
            // the caller needs a specific language regardless of the form's and org's and AppDelegate current's settings
            forLangRegionShown1st = forceLangRegion!
        } else {
            forLangRegionShown1st = forEFP.mShownLanguage
            if forEFP.mShowMode == .BILINGUAL { forLangRegionShown2nd = forEFP.mShownBilingualLanguage }
        }
        
        for entry:OrgFormFieldsEntry in forEFP.mFormFieldEntries! {
            let formFieldRec:RecOrgFormFieldDefs = entry.mFormFieldRec
//debugPrint("\(self.mCTAG).changeOrgFormFieldsLanguageShown found#\(formFieldRec.rFormField_Index!)")
            if formFieldRec.mFormFieldLocalesRecs != nil {
                entry.mComposedFormFieldLocalesRec = try self.makeComposedFormFieldLocale(forFormFieldRec: formFieldRec, forLangSVFile: forEFP.mOrgRec.rOrg_LangRegionCode_SV_File, forLangShown1st: forLangRegionShown1st, forLangShown2nd: forLangRegionShown2nd, viaArray: formFieldRec.mFormFieldLocalesRecs!, forEditing: forEditing)
            }
            
            if (entry.mComposedOptionSetLocalesRecs?.count ?? 0) > 0 && (formFieldRec.rFieldProp_Options_Code_For_SV_File?.count() ?? 0) > 0 {
                for svCP in formFieldRec.rFieldProp_Options_Code_For_SV_File!.mAttributes {
                    if svCP.codeString.starts(with: "***OSLC_") {
                        let oslc:String = String(svCP.codeString.suffix(from: svCP.codeString.index(svCP.codeString.startIndex, offsetBy: 3)))
                        entry.mComposedOptionSetLocalesRecs = self.getMatchingOptionSetLocales(forOSLC: oslc, forSVFileLang: forEFP.mOrgRec.rOrg_LangRegionCode_SV_File, forShownLang: forLangRegionShown1st)
                        break
                    }
                }
            }
        }
    }
    
    // compose a RecFieldLocales with proper information in its subsections from proper languages
    private func makeComposedFormFieldLocale(forFormFieldRec:RecOrgFormFieldDefs, forLangSVFile:String, forLangShown1st:String, forLangShown2nd:String, viaArray:[RecOrgFormFieldLocales], forEditing:Bool=false) throws -> RecOrgFormFieldLocales_Composed {

        // initializations
        var foundCollector:Bool = false
        var found1st:Bool = false
        var found2nd:Bool = true
        if !forLangShown2nd.isEmpty { found2nd = false }
        var returnRec:RecOrgFormFieldLocales_Composed? = nil
        
        // step through all the applicable FormFieldLocales for the Form
        for formFieldLocaleRec:RecOrgFormFieldLocales in viaArray {
            if formFieldLocaleRec.rFormField_Index == forFormFieldRec.rFormField_Index {
                // found a FFL record for the FormField
                if forEditing {
                    // if Editing a form, append a copy of this FFL record to the Form Field's array of applicable FFLs
                    if forFormFieldRec.mFormFieldLocalesRecs == nil { forFormFieldRec.mFormFieldLocalesRecs = [] }
                    let copyFormFieldLocaleRec:RecOrgFormFieldLocales = RecOrgFormFieldLocales(existingRec: formFieldLocaleRec)
                    forFormFieldRec.mFormFieldLocalesRecs!.append(copyFormFieldLocaleRec)
                }
                if returnRec == nil {
                    // if no returnRec has been created yet, use this FFL record as the basis for the returnRec
                    returnRec = RecOrgFormFieldLocales_Composed(existingRec: formFieldLocaleRec)
                    returnRec!.mLocale1LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                    returnRec!.mLocale2LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                    returnRec!.mLocale3LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
                if !foundCollector && formFieldLocaleRec.rFormFieldLoc_LangRegionCode == forLangSVFile {
                    // this FFL record is in the SV-File language
                    foundCollector = true
                    returnRec!.rFieldLocProp_Name_For_Collector = formFieldLocaleRec.rFieldLocProp_Name_For_Collector
                    returnRec!.mLocale1LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
                if !found1st && formFieldLocaleRec.rFormFieldLoc_LangRegionCode == forLangShown1st {
                    // this FFL record is in the shown language
                    found1st = true
                    returnRec!.rFieldLocProp_Name_Shown = formFieldLocaleRec.rFieldLocProp_Name_Shown
                    returnRec!.rFieldLocProp_Placeholder_Shown = formFieldLocaleRec.rFieldLocProp_Placeholder_Shown
                    returnRec!.rFieldLocProp_Options_Name_Shown = formFieldLocaleRec.rFieldLocProp_Options_Name_Shown
                    returnRec!.rFieldLocProp_Metadatas_Name_Shown = formFieldLocaleRec.rFieldLocProp_Metadatas_Name_Shown
                    returnRec!.mLocale2LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
                if !found2nd && formFieldLocaleRec.rFormFieldLoc_LangRegionCode == forLangShown2nd {
                    // this FFL record is in the 2nd bilingual language
                    found2nd = true
                    returnRec!.mFieldLocProp_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Name_Shown
                    returnRec!.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Options_Name_Shown
                    returnRec!.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Metadatas_Name_Shown
                    returnRec!.mLocale3LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
            }
        }
        if returnRec == nil {
            // FormField has no FFLs?  This indicates some type of database damage;
            // create a Composed FFL from the little information in the Form Field record and report an error but do not throw
            returnRec = RecOrgFormFieldLocales_Composed()
            returnRec!.rFormFieldLoc_Index = -1
            returnRec!.rOrg_Code_For_SV_File = forFormFieldRec.rOrg_Code_For_SV_File
            returnRec!.rForm_Code_For_SV_File = forFormFieldRec.rForm_Code_For_SV_File
            returnRec!.rFormField_Index = forFormFieldRec.rFormField_Index
            returnRec!.rFormFieldLoc_LangRegionCode = forLangSVFile
            returnRec!.rFieldLocProp_Name_For_Collector = forFormFieldRec.rFieldProp_Col_Name_For_SV_File
            returnRec!.rFieldLocProp_Name_Shown = forFormFieldRec.rFieldProp_Col_Name_For_SV_File
            returnRec!.rFieldLocProp_Options_Name_Shown = forFormFieldRec.rFieldProp_Options_Code_For_SV_File
            returnRec!.rFieldLocProp_Metadatas_Name_Shown = forFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File
            returnRec!.mLocale1LangRegion = forLangSVFile
            returnRec!.mLocale2LangRegion = forLangSVFile

            AppDelegate.postToErrorLogAndAlert(method: "\(self.mCTAG).makeComposedFormFieldLocale", during: "stepThruFFLs", errorMessage: "FF missing all FFLs", extra: "O=\(forFormFieldRec.rOrg_Code_For_SV_File), F=\(forFormFieldRec.rForm_Code_For_SV_File), FF#=\(forFormFieldRec.rFormField_Index)")
            return returnRec!
        } else if foundCollector && found1st && found2nd { return returnRec! }     // found all necessary languages?
        
        // nope, check now against base languages (no regionalization)
        let newLangSVFile = AppDelegate.getLangOnly(fromLangRegion: forLangSVFile)
        let newLangShown1st = AppDelegate.getLangOnly(fromLangRegion: forLangShown1st)
        let newLangShown2nd = AppDelegate.getLangOnly(fromLangRegion: forLangShown2nd)
        
        for formFieldLocaleRec:RecOrgFormFieldLocales in viaArray {
            if formFieldLocaleRec.rFormField_Index == forFormFieldRec.rFormField_Index {
                if !foundCollector && formFieldLocaleRec.rFormFieldLoc_LangRegionCode == newLangSVFile {
                    // this FFL record is in the SV-File base language
                    foundCollector = true
                    returnRec!.rFieldLocProp_Name_For_Collector = formFieldLocaleRec.rFieldLocProp_Name_For_Collector
                    returnRec!.mLocale1LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
                if !found1st && formFieldLocaleRec.rFormFieldLoc_LangRegionCode == newLangShown1st {
                    // this FFL record is in the shown base language
                    found1st = true
                    returnRec!.rFieldLocProp_Name_Shown = formFieldLocaleRec.rFieldLocProp_Name_Shown
                    returnRec!.rFieldLocProp_Placeholder_Shown = formFieldLocaleRec.rFieldLocProp_Placeholder_Shown
                    returnRec!.rFieldLocProp_Options_Name_Shown = formFieldLocaleRec.rFieldLocProp_Options_Name_Shown
                    returnRec!.rFieldLocProp_Metadatas_Name_Shown = formFieldLocaleRec.rFieldLocProp_Metadatas_Name_Shown
                    returnRec!.mLocale2LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
                if !found2nd && formFieldLocaleRec.rFormFieldLoc_LangRegionCode == newLangShown2nd {
                    // this FFL record is in the 2nd bilingual base language
                    found2nd = true
                    returnRec!.mFieldLocProp_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Name_Shown
                    returnRec!.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Options_Name_Shown
                    returnRec!.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Metadatas_Name_Shown
                    returnRec!.mLocale3LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
            }
        }
        
        if foundCollector && found1st && found2nd { return returnRec! }     // found all necessary languages?
        
        // nope, check now against forced base languages (no regionalization)
        for formFieldLocaleRec:RecOrgFormFieldLocales in viaArray {
            if formFieldLocaleRec.rFormField_Index == forFormFieldRec.rFormField_Index {
                let testLang = AppDelegate.getLangOnly(fromLangRegion: formFieldLocaleRec.rFormFieldLoc_LangRegionCode)
                if !foundCollector && testLang == newLangSVFile {
                    // this FFL record is in the SV-File forced base language
                    foundCollector = true
                    returnRec!.rFieldLocProp_Name_For_Collector = formFieldLocaleRec.rFieldLocProp_Name_For_Collector
                    returnRec!.mLocale1LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
                if !found1st && testLang == newLangShown1st {
                    // this FFL record is in the shown forced base language
                    found1st = true
                    returnRec!.rFieldLocProp_Name_Shown = formFieldLocaleRec.rFieldLocProp_Name_Shown
                    returnRec!.rFieldLocProp_Placeholder_Shown = formFieldLocaleRec.rFieldLocProp_Placeholder_Shown
                    returnRec!.rFieldLocProp_Options_Name_Shown = formFieldLocaleRec.rFieldLocProp_Options_Name_Shown
                    returnRec!.rFieldLocProp_Metadatas_Name_Shown = formFieldLocaleRec.rFieldLocProp_Metadatas_Name_Shown
                    returnRec!.mLocale2LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
                if !found2nd && testLang == newLangShown2nd {
                    // this FFL record is in the 2nd bilingual forced base language
                    found2nd = true
                    returnRec!.mFieldLocProp_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Name_Shown
                    returnRec!.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Options_Name_Shown
                    returnRec!.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd = formFieldLocaleRec.rFieldLocProp_Metadatas_Name_Shown
                    returnRec!.mLocale3LangRegion = formFieldLocaleRec.rFormFieldLoc_LangRegionCode
                }
            }
        }
        
        return returnRec!
    }
}
