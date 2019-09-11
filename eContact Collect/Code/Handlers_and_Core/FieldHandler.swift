//
//  FieldHandler.swift
//  eContact Collect
//
//  Created by Yo on 10/6/18.
//

import SQLite
import Eureka

// base handler class for Form Fields;
//  combines the JSON file factory defaults with custom fields in the database;
//  also handles building of Form Field datasets with Language options
public class FieldHandler {
    // member variables
    public var mFHstatus_state:HandlerStatusStates = .Unknown
    public var mAppError:APP_ERROR? = nil
    private var mFields_json:[RecJsonFieldDefs]? = nil
    private var mOptionSetLocales_json:[RecJsonOptionSetLocales]? = nil
    public var mFormFieldClipboard:FormFieldClipboard? = nil
    
    // member constants and other static content
    public static let shared:FieldHandler = FieldHandler()
    internal var mCTAG:String = "HFl"
    internal var mThrowErrorDomain:String = NSLocalizedString("Field-Handler", comment:"")
    internal var mFILE_FIELDS_MAX_VERSION:Int = 1
    internal var mFILE_FIELDATTRIBS_MAX_VERSION:Int = 1
    
    // formField(s) clipboard
    public struct FormFieldClipboard {
        public var mFrom_Org_Code_For_SV_File:String        // origin Organization
        public var mFrom_Form_Code_For_SV_File:String       // origin Form
        public var mFrom_FormFields:OrgFormFields           // form field(s) and subfields that were copied
        
        init(orgCode:String, formCode:String, formFields:OrgFormFields) {
            self.mFrom_Org_Code_For_SV_File = orgCode
            self.mFrom_Form_Code_For_SV_File = formCode
            self.mFrom_FormFields = formFields
        }
    }
    
    // constructor;
    public init() {}
    
    // initialization; returns true if initialize fully succeeded;
    // errors are stored via the class members and will already be posted to the error.log;
    // this handler must be mindful that the database initialization may have failed
    public func initialize(method:String) -> Bool {
//debugPrint("\(mCTAG).initialize STARTED")
        self.mFHstatus_state = .Unknown
        
        // load JSON files temporarily to ensure they are present and valid; will properly set self.mFHstatus_state
        let result:Bool = self.validateFiles(method: "\(self.mCTAG).initialize")    // already posted to error.log
        return result
    }
    
    // perform any handler first time setups that have not already been performed; the sequence# allows later versions to retro-add a first-time setup;
    // this handler must be mindful that it or the database handler may not have properly initialized and should bypass this;
    // errors are stored via the class members and will already be posted to the error.log
    public func firstTimeSetup(method:String) {
//debugPrint("\(mCTAG).firstTimeSetup STARTED")
        if AppDelegate.getPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Handler_Field_FirstTime_Done) != 1 {
            // none at this time
            AppDelegate.setPreferenceInt(prefKey: PreferencesKeys.Ints.APP_Handler_Field_FirstTime_Done, value: 1)
        }
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
    
    // record a formfield that the end-user tagged as a "copy"
    public func copyToClipboardOneEdited(editedFF:OrgFormFieldsEntry?) {
        if editedFF == nil { return }
        let copyFFs:OrgFormFields = OrgFormFields()
        
        let copiedFF = OrgFormFieldsEntry(existingEntry: editedFF!)
        copyFFs.appendNewDuringEditing(copiedFF)
        
        // are there any subfields?
        if (editedFF!.mDuringEditing_SubFormFields?.count ?? 0) > 0 {
            // yes; copy them as well as full entries
            for sFFentry:OrgFormFieldsEntry in editedFF!.mDuringEditing_SubFormFields! {
                let copiedSubFF = OrgFormFieldsEntry(existingEntry: sFFentry)
                copyFFs.appendNewSubfieldDuringEditing(copiedSubFF, primary: copiedFF)
            }
        }
        
        // remember the copied formfield and its subfields
        self.mFormFieldClipboard = FormFieldClipboard(orgCode: editedFF!.mFormFieldRec.rOrg_Code_For_SV_File,
                                                      formCode: editedFF!.mFormFieldRec.rForm_Code_For_SV_File,
                                                      formFields: copyFFs)
    }
    
    // clear the clipboard
    public func clearClipboard() {
        self.mFormFieldClipboard = nil
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // methods used to get Language Information from JSON
    /////////////////////////////////////////////////////////////////////////////////////////

    // get any information for the langRegion from the json files;
    // returns nil if no matching language file was found;
    // throws other filesystem errors and file validation errors
    public func getLangInfo(forLangRegion:String, noSubstitution:Bool=false) throws -> RecJsonLangDefs? {
        let funcName:String = "\(self.mCTAG).getLangInfo"
        var jsonPath:String? = nil
        (jsonPath, _) = self.locateLocaleFile(named: "FieldLocales", ofType: "json", forLangRegion: forLangRegion)
        if jsonPath == nil {
            self.mFHstatus_state = .Missing
            self.mAppError = APP_ERROR(funcName: funcName, during: "Bundle.main.path", domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Missing: FieldLocales.json")
            throw self.mAppError!
        }
        let jsonContents = FileManager.default.contents(atPath: jsonPath!)   // obtain the data in JSON format
        if jsonContents == nil {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: funcName, during: "FileManager.default.contents", domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Failed: \(jsonPath!)")
            throw self.mAppError!
        }
        var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
        do {
            validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents!, isFactory: true)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError!.prependCallStack(funcName: funcName)
            if self.mAppError!.developerInfo == nil { self.mAppError!.developerInfo = "" }
            self.mAppError!.developerInfo = self.mAppError!.developerInfo! + ": \(jsonPath!)"
            throw self.mAppError!
        }
        if validationResult.jsonTopLevel!["method"] as! String != "eContactCollect.db.fieldLocales.factory" {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: funcName, during: "Validate top level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Method is invalid \(validationResult.jsonTopLevel!["method"] as! String): \(jsonPath!)")
            throw self.mAppError!
        }
        var getResult:DatabaseHandler.GetJSONdbFileTable_Result
        do {
            getResult = try DatabaseHandler.getJSONdbFileTable(forTableCode: "langs", forTableName: "Langs", needsItem: true, priorResult: validationResult)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError!.prependCallStack(funcName: funcName)
            if self.mAppError!.developerInfo == nil { self.mAppError!.developerInfo = "" }
            self.mAppError!.developerInfo = self.mAppError!.developerInfo! + ": \(jsonPath!)"
            throw self.mAppError!
        }
        if noSubstitution && validationResult.languages[0] != forLangRegion { return nil }
        let jsonLanDefRec:RecJsonLangDefs = RecJsonLangDefs(jsonRecObj: getResult.jsonItemLevel!, forDBversion: validationResult.databaseVersion)
        jsonLanDefRec.mLang_LangRegionCode = validationResult.languages[0]
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
        do {
            let _ = try self.loadPotentialFieldsForForm(forFormRec: forFormRec, withOrgRec: withOrgRec)
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
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).addMetadataFormFieldsToNewForm")
            throw appError
        } catch { throw error }
        
        self.flushInMemoryObjects()
    }
    
    // add one or more non-meta-data fields (by IDCode) to a form in the database; draws from JSON and any Custom fields
    // only the Org's default SV-File language is loaded
    // note: the Org and the Form are presumed to already exist in the database
    // throws exceptions either for local errors or from the database
    public func addFieldstoForm(field_IDCodes:[String], forFormRec:RecOrgFormDefs, withOrgRec:RecOrganizationDefs, orderSVfile:inout Int, orderShown:inout Int, asSubfieldsOf:Int64?=nil) throws {
        
        if field_IDCodes.count == 0 { return }
        do {
            let _ = try self.loadPotentialFieldsForForm(forFormRec: forFormRec, withOrgRec: withOrgRec)
    
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
                        
                        // are there any subfields?;
                        // note that the list of initial subfields could have been regionalized during initialization of formFieldRecOpt
                        if (formFieldRecOpt.rFieldProp_Contains_Field_IDCodes?.count ?? 0) > 0 {
                            // recursive call to immediately add the additional subfields so the sort ordering is correct
                            try self.addFieldstoForm(field_IDCodes: formFieldRecOpt.rFieldProp_Contains_Field_IDCodes!, forFormRec: forFormRec, withOrgRec: withOrgRec, orderSVfile: &orderSVfile, orderShown: &orderShown, asSubfieldsOf: formFieldRec.rFormField_Index)
                        }
                    }
                }
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).addFieldstoForm")
            throw appError
        } catch { throw error }
        
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
    public func getAllAvailFieldIDCodes(withOrgRec:RecOrganizationDefs) throws -> ([CodePair], [String:String], [String:String]) {
        do {
            let _ = try self.loadPotentialFieldsForEditDisplay(withOrgRec: withOrgRec)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getAllAvailFieldIDCodes")
            throw appError
        } catch { throw error }
        
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
        do {
            let _ = try self.loadPotentialFieldsForForm(forFormRec: forFormRec, withOrgRec: withOrgRec)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getFieldDefsAsMatchForEditing")
            throw appError
        } catch { throw error }
        
        let forLangRegions:[String] = self.pickFormsLanguages(forFormRec: forFormRec, withOrgRec: withOrgRec)
        let results:OrgFormFields = OrgFormFields()

        // load the primary field
        let fieldEntry:OrgFormFieldsEntry? = self.getOneMatchForEditing(forFieldIDCode: forFieldIDCode, forFormRec: forFormRec, withOrgRec: withOrgRec, forLangRegions: forLangRegions)
        if fieldEntry == nil { self.flushInMemoryObjects(); return nil }
        results.appendNewDuringEditing(fieldEntry!) // auto-assigns temporary indexes within the local context of the return results
        
        // now load for any required subfields
        if fieldEntry!.mFormFieldRec.hasSubFormFields() {
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
        } catch { return nil }  // will never happen since !formFieldRecOpt.validate() already detected the throwable conditions
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
                } catch { return nil }  // will never happen since formFieldLocalesOptRec.validate() already detected the throwable conditions
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
    public func getAllowedSubfieldEntriesForEditing(forPrimaryFormFieldRec:RecOrgFormFieldDefs, forFormRec:RecOrgFormDefs, withOrgRec:RecOrganizationDefs) throws -> OrgFormFields {
        do {
            let _ = try self.loadPotentialFieldsForForm(forFormRec: forFormRec, withOrgRec: withOrgRec)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getAllowedSubfieldEntriesForEditing")
            throw appError
        } catch { throw error }
        
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
    private func getMatchingOptionSetLocales(forOSLC:String, forSVFileLang:String, forShownLang:String) throws -> [RecOptionSetLocales_Composed] {
        var returnArray:[RecOptionSetLocales_Composed] = []
        
        do {
            let _ = try self.loadOptionSetLocalesDefaults(forLangRegion: forSVFileLang)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getMatchingOptionSetLocales")
            throw appError
        } catch { throw error }
        
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
        
        do {
            let _ = try self.loadOptionSetLocalesDefaults(forLangRegion: forShownLang)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getMatchingOptionSetLocales")
            throw appError
        } catch { throw error }
        
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
    
    // find a localized file as-named; can be in various places and defaults to english
    // iOS prefers underscore (rather than dash) to separate language from region
    // returns:  (filePath:String?, defaultedToEnglish:Bool)
    public func locateLocaleFile(named: String, ofType: String, forLangRegion: String) -> (String?, Bool) {
        var jsonPath:String? = nil
        var defaultedToEnglish:Bool = false
        
        if !forLangRegion.isEmpty {
            // look first in one of the iOS Localization folders
            jsonPath = Bundle.main.path(forResource: named, ofType: ofType, inDirectory: nil, forLocalization: forLangRegion)
            if (jsonPath ?? "").isEmpty {
                // now try the base directory with localization part of the filename
                jsonPath = Bundle.main.path(forResource: named + "_" + forLangRegion, ofType: ofType)
            }
            if (jsonPath ?? "").isEmpty {
                // now try the base directory with localization part of the filename
                jsonPath = Bundle.main.path(forResource: named + "_" + AppDelegate.getLangOnly(fromLangRegion: forLangRegion), ofType: ofType)
            }
        }
        
        // language-specific file not found; now switch to U.S. english which should ALWAYS be present
        if (jsonPath ?? "").isEmpty {
            // load the english version; look first in one of the iOS Localization folders
            jsonPath = Bundle.main.path(forResource: named, ofType: ofType, inDirectory: nil, forLocalization: "en")
            if (jsonPath ?? "").isEmpty {
                // now try the base directory with localization part of the filename
                jsonPath = Bundle.main.path(forResource: named + "_en", ofType: ofType)
            }
            defaultedToEnglish = true
        }
        return (jsonPath, defaultedToEnglish)
    }
    
    // validate all the files during App startup; do not keep the loaded data in-memory;
    // all errors will be posted but not shown
    private func validateFiles(method:String) -> Bool {
        self.flushInMemoryObjects()
        
        // pre-determine the languages needed and verify the FieldDefs.json
        let allLocalizations = AppDelegate.getAppsLocalizations()
        do {
            try self.loadFieldDefaults()
            try self.mergeInFieldLocalesDefaults(forLangRegions: allLocalizations, validate: true)
            for aLocale in allLocalizations {
                try self.loadOptionSetLocalesDefaults(forLangRegion: aLocale, validate: true)
            }
        } catch {
            AppDelegate.postToErrorLogAndAlert(method: "\(method):\(self.mCTAG).validateFiles", errorStruct: error, extra: nil)
            // do not show anything to the end-user
            return false
        }

        self.flushInMemoryObjects()
        self.mFHstatus_state = .Valid
        return true
    }
    
    // load default fields which will be shown to the collector in SV-File language
    private func loadPotentialFieldsForEditDisplay(withOrgRec: RecOrganizationDefs) throws {
        self.flushInMemoryObjects()
        
        // pre-determine the languages needed
        let forLangRegion:[String] = [withOrgRec.rOrg_LangRegionCode_SV_File]
        
        // load the FieldDefs.json and the proper FieldLocales.json
        do {
            try self.loadFieldDefaults()
            try self.mergeInFieldLocalesDefaults(forLangRegions: forLangRegion)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).loadPotentialFieldsForEditDisplay")
            throw appError
        } catch { throw error }
    }
    
    // load default fields for use in Editing in all languages for the Org
    private func loadPotentialFieldsForForm(forFormRec: RecOrgFormDefs, withOrgRec:RecOrganizationDefs) throws {
        self.flushInMemoryObjects()
        
        // pre-determine the languages needed and load the FieldDefs.json
        let forLangRegions:[String] = self.pickFormsLanguages(forFormRec: forFormRec, withOrgRec: withOrgRec)
        
        // load the FieldDefs.json and the proper set of FieldLocales.json
        do {
            try self.loadFieldDefaults()
            try self.mergeInFieldLocalesDefaults(forLangRegions: forLangRegions)
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).loadPotentialFieldsForForm")
            throw appError
        } catch { throw error }
    }

    // load the FieldDefs.json file plus any custom fields in the database
    private func loadFieldDefaults() throws {
        // locate the file in the proper non-localized folder
        let funcName:String = "\(self.mCTAG).loadFieldDefaults"
        let jsonPath1:String? = Bundle.main.path(forResource: "FieldDefs", ofType: "json")  // this file is not localized
        self.mFields_json = []
        if jsonPath1 == nil {
            self.mFHstatus_state = .Missing
            self.mAppError = APP_ERROR(funcName: funcName, during: "Bundle.main.path", domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Missing: FieldDefs.json")
            throw self.mAppError!
        }
        let jsonContents1 = FileManager.default.contents(atPath: jsonPath1!)   // obtain the data in JSON format
        if jsonContents1 == nil {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: funcName, during: "FileManager.default.contents", domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Failed: \(jsonPath1!)")
            throw self.mAppError!
        }
        var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
        do {
            validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents1!, isFactory: true)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError!.prependCallStack(funcName: funcName)
            if self.mAppError!.developerInfo == nil { self.mAppError!.developerInfo = "" }
            self.mAppError!.developerInfo = self.mAppError!.developerInfo! + ": \(jsonPath1!)"
            throw self.mAppError!
        }
        if validationResult.jsonTopLevel!["method"] as! String != "eContactCollect.db.fieldDefs.factory" {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: funcName, during: "Validate top level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Method is invalid \(validationResult.jsonTopLevel!["method"] as! String): \(jsonPath1!)")
            throw self.mAppError!
        }
        var getResult:DatabaseHandler.GetJSONdbFileTable_Result
        do {
            getResult = try DatabaseHandler.getJSONdbFileTable(forTableCode: "fieldDefs", forTableName: "FieldDefs", needsItem: false, priorResult: validationResult)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError!.prependCallStack(funcName: funcName)
            if self.mAppError!.developerInfo == nil { self.mAppError!.developerInfo = "" }
            self.mAppError!.developerInfo = self.mAppError!.developerInfo! + ": \(jsonPath1!)"
            throw self.mAppError!
        }
        
        // all valid thus far; now read all the records in the JSON file
        var itemNo:Int = 0
        for jsonRecAny in getResult.jsonItemsLevel! {
            // these are the individual records
            let jsonRecObj:NSDictionary? = jsonRecAny as? NSDictionary
            if jsonRecObj == nil {
                self.mFHstatus_state = .Errors
                self.mAppError = APP_ERROR(funcName: funcName, during: "Validate record level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Failed to find record, item \(itemNo): \(jsonPath1!)")
                throw self.mAppError!
            } else {
                let jsonFieldRec:RecJsonFieldDefs = RecJsonFieldDefs(jsonRecObj: jsonRecObj!, forDBversion: validationResult.databaseVersion)
                if (jsonFieldRec.rFieldProp_IDCode ?? "").isEmpty {
                    self.mFHstatus_state = .Invalid
                    self.mAppError = APP_ERROR(funcName: funcName, during: "Validate record level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Item# \(itemNo) invalid: \(jsonPath1!)")
                    throw self.mAppError!
                }
                jsonFieldRec.mJsonFieldLocalesRecs = []
                self.mFields_json!.append(jsonFieldRec)
                itemNo = itemNo + 1
            }
        }
        
        // now add in any custom Fields from the database
        // ?? FUTURE
    }
    
    // merge in the FieldLocales.json plus any custom Locales in the database
    private func mergeInFieldLocalesDefaults(forLangRegions:[String], validate:Bool=false) throws {
        let funcName:String = "\(self.mCTAG).mergeInFieldLocalesDefaults"
        for forLangRegion in forLangRegions {
            // locate the file in the proper or best localization folder
            var jsonPath2:String? = nil
            var defaultedToEnglish:Bool = false
            (jsonPath2, defaultedToEnglish) = self.locateLocaleFile(named: "FieldLocales", ofType: "json", forLangRegion: forLangRegion)
            if jsonPath2 == nil {
                self.mFHstatus_state = .Missing
                self.mAppError = APP_ERROR(funcName: funcName, during: "Bundle.main.path", domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Missing: FieldLocales.json")
                throw self.mAppError!
            }
//debugPrint("\(self.mCTAG).loadFiles.FieldLocales LR=\(forLangRegion) PATH=\(jsonPath2!)")
            // read the file, parse the JSON, and validate the file's JSON headers
            let jsonContents2 = FileManager.default.contents(atPath: jsonPath2!)   // obtain the data in JSON format
            if jsonContents2 == nil {
                self.mFHstatus_state = .Errors
                self.mAppError = APP_ERROR(funcName: funcName, during: "FileManager.default.contents", domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Failed: \(jsonPath2!)")
                throw self.mAppError!
            }
            var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
            do {
                validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents2!, isFactory: true)
            } catch {
                self.mFHstatus_state = .Errors
                self.mAppError = (error as! APP_ERROR)
                self.mAppError!.prependCallStack(funcName: funcName)
                if self.mAppError!.developerInfo == nil { self.mAppError!.developerInfo = "" }
                self.mAppError!.developerInfo = self.mAppError!.developerInfo! + ": \(jsonPath2!)"
                throw self.mAppError!
            }
            if validationResult.jsonTopLevel!["method"] as! String != "eContactCollect.db.fieldLocales.factory" {
                self.mFHstatus_state = .Errors
                self.mAppError = APP_ERROR(funcName: funcName, during: "Validate top level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Method is invalid \(validationResult.jsonTopLevel!["method"] as! String): \(jsonPath2!)")
                throw self.mAppError!
            }
            var getResult:DatabaseHandler.GetJSONdbFileTable_Result
            do {
                getResult = try DatabaseHandler.getJSONdbFileTable(forTableCode: "fieldLocales_packed", forTableName: "FieldLocales_packed", needsItem: false, priorResult: validationResult)
            } catch {
                self.mFHstatus_state = .Errors
                self.mAppError = (error as! APP_ERROR)
                self.mAppError!.prependCallStack(funcName: funcName)
                if self.mAppError!.developerInfo == nil { self.mAppError!.developerInfo = "" }
                self.mAppError!.developerInfo = self.mAppError!.developerInfo! + ": \(jsonPath2!)"
                throw self.mAppError!
            }
            
            // all valid thus far; now read all the records in the JSON file
            var itemNo:Int = 0
            for jsonRecAny in getResult.jsonItemsLevel! {
                // these are the individual records
                let jsonRecObj:NSDictionary? = jsonRecAny as? NSDictionary
                if jsonRecObj == nil {
                    self.mFHstatus_state = .Errors
                    self.mAppError = APP_ERROR(funcName: funcName, during: "Validate record level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Failed to find record, item# \(itemNo): \(jsonPath2!)")
                    throw self.mAppError!
                } else {
                    let jsonFieldLocalesRec:RecJsonFieldLocales = RecJsonFieldLocales(jsonRecObj: jsonRecObj!, forDBversion: validationResult.databaseVersion)
                    if (jsonFieldLocalesRec.rField_IDCode ?? "").isEmpty {
                        self.mFHstatus_state = .Invalid
                        self.mAppError = APP_ERROR(funcName: funcName, during: "Validate record level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Item# \(itemNo) invalid: \(jsonPath2!)")
                        throw self.mAppError!
                    }
                    if defaultedToEnglish {
                        if jsonFieldLocalesRec.rFieldLocProp_Col_Name_For_SV_File != nil { jsonFieldLocalesRec.rFieldLocProp_Col_Name_For_SV_File = "??" + jsonFieldLocalesRec.rFieldLocProp_Col_Name_For_SV_File! }
                        if jsonFieldLocalesRec.rFieldLocProp_Name_Shown != nil { jsonFieldLocalesRec.rFieldLocProp_Name_Shown = "??" + jsonFieldLocalesRec.rFieldLocProp_Name_Shown! }
                        if jsonFieldLocalesRec.rFieldLocProp_Placeholder_Shown != nil { jsonFieldLocalesRec.rFieldLocProp_Placeholder_Shown = "??" + jsonFieldLocalesRec.rFieldLocProp_Placeholder_Shown! }
                        jsonFieldLocalesRec.rFieldLocProp_Option_Trios = self.tweakNonEnglishJsonAttributes(type: "o", set: jsonFieldLocalesRec.rFieldLocProp_Option_Trios)
                        jsonFieldLocalesRec.rFieldLocProp_Metadata_Trios = self.tweakNonEnglishJsonAttributes(type: "m", set: jsonFieldLocalesRec.rFieldLocProp_Metadata_Trios)
                        jsonFieldLocalesRec.mFormFieldLoc_LangRegionCode = forLangRegion
                    } else if AppDelegate.getLangOnly(fromLangRegion: validationResult.languages[0]) == AppDelegate.getLangOnly(fromLangRegion: forLangRegion) {
                        jsonFieldLocalesRec.mFormFieldLoc_LangRegionCode = forLangRegion
                    } else {
                        jsonFieldLocalesRec.mFormFieldLoc_LangRegionCode = validationResult.languages[0]
                    }
                    
                    
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
                        self.mAppError = APP_ERROR(funcName: funcName, during: "Validate record level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Item# \(itemNo) \(jsonFieldLocalesRec.rField_IDCode!): Field IDCode does not match one in FieldDefs.json: \(jsonPath2!)")
                        throw self.mAppError!
                    }
                    itemNo = itemNo + 1
                }
            }
            
            // only perform this cross-check during App startup
            if validate {
                for jsonFieldRec:RecJsonFieldDefs in self.mFields_json! {
                    if jsonFieldRec.mJsonFieldLocalesRecs!.count == 0 {
                        self.mFHstatus_state = .Invalid
                        self.mAppError = APP_ERROR(funcName: funcName, during: "Validate record level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Entry for FieldDefs.json Field IDCode '\(jsonFieldRec.rFieldProp_IDCode!)' is not present: \(jsonPath2!)")
                        throw self.mAppError!
                    }
                    jsonFieldRec.mJsonFieldLocalesRecs = []
                }
            }
            
            // now merge in any custom Fields from the database for this forLangRegion
            // ?? FUTURE
        }   // end of forLangRegion for loop
    }
    
    // need to indicate that non-translated attributes were included into a locales record
    // trios are tag:SV:Shown
    private func tweakNonEnglishJsonAttributes(type:String, set: [String]?) -> [String]? {
        if set == nil { return nil }
        if set!.count == 0 { return [] }
        var result:[String] = []
        for trio in set! {
            if type == "m" {
                // metadata
                if trio.prefix(3) == "###" {
                    result.append(trio)
                } else if trio.prefix(3) == "***" {
                    var trioComponents = trio.components(separatedBy: ":")
                    if trioComponents.count >= 3 {
                        trioComponents[2] = "??" + trioComponents[2]
                    } else if trioComponents.count >= 2 {
                        trioComponents[1] = "??" + trioComponents[1]
                    }
                    result.append(trioComponents.joined(separator: ":"))
                } else {
                    var trioComponents = trio.components(separatedBy: ":")
                    if trioComponents.count >= 3 {
                        trioComponents[1] = "??" + trioComponents[1]
                        trioComponents[2] = "??" + trioComponents[2]
                    } else if trioComponents.count >= 2 {
                        trioComponents[1] = "??" + trioComponents[1]
                    }
                    result.append(trioComponents.joined(separator: ":"))
                }
            } else {
                // options
                if trio.prefix(3) == "***" {
                    result.append(trio)
                } else {
                    var trioComponents = trio.components(separatedBy: ":")
                    if trioComponents.count >= 3 {
                        trioComponents[1] = "??" + trioComponents[1]
                        trioComponents[2] = "??" + trioComponents[2]
                    } else if trioComponents.count >= 2 {
                        trioComponents[1] = "??" + trioComponents[1]
                    }
                    result.append(trioComponents.joined(separator: ":"))
                }
            }
        }
        return result
    }
    
    private func loadOptionSetLocalesDefaults(forLangRegion:String, validate:Bool=false) throws {
        // locate the file in the proper or best localization folder
        let funcName:String = "\(self.mCTAG).loadOptionSetLocalesDefaults"
        var jsonPath3:String? = nil
        (jsonPath3, _) = self.locateLocaleFile(named: "OptionSetLocales", ofType: "json", forLangRegion: forLangRegion)
        self.mOptionSetLocales_json = []
        if jsonPath3 == nil {
            self.mFHstatus_state = .Missing
            self.mAppError = APP_ERROR(funcName: funcName, during: "Bundle.main.path", domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Missing: OptionSetLocales.json")
            throw self.mAppError!
        }
//debugPrint("\(self.mCTAG).loadFiles.FieldsLocale LR=\(forLangRegion) PATH=\(jsonPath3!)")
        let jsonContents3 = FileManager.default.contents(atPath: jsonPath3!)   // obtain the data in JSON format
        if jsonContents3 == nil {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: funcName, during: "FileManager.default.contents", domain: self.mThrowErrorDomain, errorCode: .FILESYSTEM_ERROR, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Failed: \(jsonPath3!)")
            throw self.mAppError!
        }
        var validationResult:DatabaseHandler.ValidateJSONdbFile_Result
        do {
            validationResult = try DatabaseHandler.validateJSONdbFile(contents: jsonContents3!, isFactory: true)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError!.prependCallStack(funcName: funcName)
            if self.mAppError!.developerInfo == nil { self.mAppError!.developerInfo = "" }
            self.mAppError!.developerInfo = self.mAppError!.developerInfo! + ": \(jsonPath3!)"
            throw self.mAppError!
        }
        if validationResult.jsonTopLevel!["method"] as! String != "eContactCollect.db.optionSetLocs.factory" {
            self.mFHstatus_state = .Errors
            self.mAppError = APP_ERROR(funcName: funcName, during: "Validate top level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Method is invalid \(validationResult.jsonTopLevel!["method"] as! String): \(jsonPath3!)")
            throw self.mAppError!
        }
        var getResult:DatabaseHandler.GetJSONdbFileTable_Result
        do {
            getResult = try DatabaseHandler.getJSONdbFileTable(forTableCode: "optionSetLocales_packed", forTableName: "OptionSetLocales_packed", needsItem: false, priorResult: validationResult)
        } catch {
            self.mFHstatus_state = .Errors
            self.mAppError = (error as! APP_ERROR)
            self.mAppError!.prependCallStack(funcName: funcName)
            if self.mAppError!.developerInfo == nil { self.mAppError!.developerInfo = "" }
            self.mAppError!.developerInfo = self.mAppError!.developerInfo! + ": \(jsonPath3!)"
            throw self.mAppError!
        }

        // all valid thus far; now read all the records in the JSON file
        var itemNo:Int = 0
        for jsonRecAny in getResult.jsonItemsLevel! {
            // these are the individual records
            let jsonRecObj:NSDictionary? = jsonRecAny as? NSDictionary
            if jsonRecObj == nil {
                self.mFHstatus_state = .Errors
                self.mAppError = APP_ERROR(funcName: funcName, during: "Validate record level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Failed to find record, item \(itemNo): \(jsonPath3!)")
                throw self.mAppError!
            } else {
                let jsonOptionSetLocaleRec:RecJsonOptionSetLocales = RecJsonOptionSetLocales(jsonRecObj: jsonRecObj!, forDBversion: validationResult.databaseVersion)
                if (jsonOptionSetLocaleRec.rOptionSetLoc_Code ?? "").isEmpty {
                    self.mFHstatus_state = .Invalid
                    self.mAppError = APP_ERROR(funcName: funcName, during: "Validate record level", domain: self.mThrowErrorDomain, errorCode: .DID_NOT_VALIDATE, userErrorDetails: NSLocalizedString("Load Defaults", comment:""), developerInfo: "Item# \(itemNo) invalid: \(jsonPath3!)")
                    throw self.mAppError!
                }
                jsonOptionSetLocaleRec.mOptionSetLoc_LangRegionCode = validationResult.languages[0]
                self.mOptionSetLocales_json!.append(jsonOptionSetLocaleRec)
                itemNo = itemNo + 1
            }
        }
        // performing App startup validations
        if validate {
            self.mOptionSetLocales_json!.removeAll()
        }
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
        do {
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
                                optionSetLocalesComposedRecs = try self.getMatchingOptionSetLocales(forOSLC: oslc, forSVFileLang: forEFP.mOrgRec.rOrg_LangRegionCode_SV_File, forShownLang: forLangRegionShown1st)
                                break
                            }
                        }
                    }
                    results.appendFromDatabase(OrgFormFieldsEntry(formFieldRec: formFieldRec, composedFormFieldLocalesRec: formFieldLocalesComposedRec!, composedOptionSetLocalesRecs: optionSetLocalesComposedRecs))
                }
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).getOrgFormFields")
            throw appError
        } catch { throw error }
        
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
        
        do {
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
                            entry.mComposedOptionSetLocalesRecs = try self.getMatchingOptionSetLocales(forOSLC: oslc, forSVFileLang: forEFP.mOrgRec.rOrg_LangRegionCode_SV_File, forShownLang: forLangRegionShown1st)
                            break
                        }
                    }
                }
            }
        } catch var appError as APP_ERROR {
            appError.prependCallStack(funcName: "\(self.mCTAG).changeOrgFormFieldsLanguageShown")
            throw appError
        } catch { throw error }
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
