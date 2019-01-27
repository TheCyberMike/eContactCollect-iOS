//
//  OrgFormFields.swift
//  eContact Collect
//
//  Created by Yo on 11/13/18.
//

import Eureka

// Swift Iterator
public struct OrgFormFieldsIterator: IteratorProtocol {
    private var mOrgFormFields:[OrgFormFieldsEntry]?
    private var mIteratorIndex:Int
    
    public init(forArray:[OrgFormFieldsEntry]) {
        self.mOrgFormFields = forArray
        self.mIteratorIndex = 0
    }
    
    public mutating func next() -> OrgFormFieldsEntry? {
        if self.mIteratorIndex < 0 || self.mIteratorIndex >= self.mOrgFormFields!.count { return nil }
        let entry = self.mOrgFormFields![self.mIteratorIndex]
        self.mIteratorIndex = self.mIteratorIndex + 1
        return entry
    }
}

// stores all the Organization's Form's field; during Editing allow for add/change/delete of the entries in an organized manner
public class OrgFormFields:Sequence {
    // class members
    private static var mNextTemporaryFFindex:Int64 = -2     // these temporary assignments will remain unique across multiple instances of OrgFormFields
    private var mOrgFormFields:[OrgFormFieldsEntry] = []
    
    // member constants and other static content
    internal var mCTAG:String = "HOFFs"
    
    // deallocation of the class object is occuring
    deinit {
//debugPrint("\(self.mCTAG).deinit STARTED")
    }
    
    // Sequence protocol compliance function
    public func makeIterator() -> OrgFormFieldsIterator {
        return OrgFormFieldsIterator(forArray: self.mOrgFormFields)
    }
    
    // Sequence protocol compliance function
    public subscript (index:Int) -> OrgFormFieldsEntry {
        get {
            assert(index >= 0 && index < self.mOrgFormFields.count, "Index out of range")
            return self.mOrgFormFields[index]
        }
        set {
            assert(index >= 0 && index < self.mOrgFormFields.count, "Index out of range")
            self.mOrgFormFields[index] = newValue
        }
    }
    
    // clear out all the entries
    public func removeAll() {
        for formField in self.mOrgFormFields { formField.clear() }
        self.mOrgFormFields.removeAll()
        self.mOrgFormFields = []
    }

    // return the count of entries
    public func count() -> Int {
        return self.mOrgFormFields.count
    }

    // append a new OrgFormFieldsEntry
    public func appendFromDatabase(_ entry:OrgFormFieldsEntry) {
        self.mOrgFormFields.append(entry)
    }
    
    // append a new OrgFormFieldsEntry with auto-temporary indexing
    public func appendNewDuringEditing(_ entry:OrgFormFieldsEntry) {
        entry.mFormFieldRec.rFormField_Index = OrgFormFields.mNextTemporaryFFindex
        entry.mComposedFormFieldLocalesRec.rFormFieldLoc_Index = OrgFormFields.mNextTemporaryFFindex
        entry.mComposedFormFieldLocalesRec.rFormField_Index = OrgFormFields.mNextTemporaryFFindex
        
        if (entry.mFormFieldRec.mFormFieldLocalesRecs?.count ?? 0) > 0 {
            for ffLocaleRec:RecOrgFormFieldLocales in entry.mFormFieldRec.mFormFieldLocalesRecs! {
                ffLocaleRec.rFormFieldLoc_Index = OrgFormFields.mNextTemporaryFFindex
                ffLocaleRec.rFormField_Index = OrgFormFields.mNextTemporaryFFindex
            }
        }
        self.mOrgFormFields.append(entry)
        OrgFormFields.mNextTemporaryFFindex = OrgFormFields.mNextTemporaryFFindex - 1
    }
    
    // find the index of a specific FormField index#; return -1 if not found
    public func findIndex(ofFormFieldIndex:Int64) -> Int {
        if self.mOrgFormFields.count == 0 { return -1 }
        var inx:Int = 0
        for entry in self.mOrgFormFields {
            if !entry.mDuringEditing_isDeleted && entry.mFormFieldRec.rFormField_Index == ofFormFieldIndex { return inx }
            inx = inx + 1
        }
        return -1
    }
    
    // find the index of a specific Field ID_Code; return -1 if not found
    public func findIndex(ofFieldIDCode:String) -> Int {
        if self.mOrgFormFields.count == 0 { return -1 }
        var inx:Int = 0
        for entry in self.mOrgFormFields {
            if !entry.mDuringEditing_isDeleted && entry.mFormFieldRec.rFieldProp_IDCode == ofFieldIDCode { return inx }
            inx = inx + 1
        }
        return -1
    }

    // find a specific subfield for a contain primary field; return nil if not found
    public func findSubfield(forPrimaryIndex:Int64, forSubFieldIDCode:String) -> OrgFormFieldsEntry? {
        for entry in self.mOrgFormFields {
            if !entry.mDuringEditing_isDeleted && entry.mFormFieldRec.rFormField_SubField_Within_FormField_Index != nil {
                if entry.mFormFieldRec.rFieldProp_IDCode == forSubFieldIDCode &&
                   entry.mFormFieldRec.rFormField_SubField_Within_FormField_Index! == forPrimaryIndex {
                    return entry
                }
            }
        }
        return nil
    }
    
    // get the next primary field rFormField_Order_Shown that should be used;
    // does not skip past still-held deleted entries
    public func getNextOrderShown() -> Int {
        var result:Int = 0
        for entry in self.mOrgFormFields {
            if entry.mFormFieldRec.rFormField_Order_Shown < RecOrgFormFieldDefs.FORMFIELD_ORDER_UPPERSTART {
                if entry.mFormFieldRec.rFormField_Order_Shown > result { result = entry.mFormFieldRec.rFormField_Order_Shown }
            }
        }
        result = ((result / 10) + 1) * 10
        return result
    }
    
    // get the next primary field rFormField_Order_SV_File that should be used;
    // does not skip past still-held deleted entries
    public func getNextOrderSVfile() -> Int {
        var result:Int = 0
        for entry in self.mOrgFormFields {
            if entry.mFormFieldRec.rFormField_Order_SV_File < RecOrgFormFieldDefs.FORMFIELD_ORDER_UPPERSTART {
                if entry.mFormFieldRec.rFormField_Order_SV_File > result { result = entry.mFormFieldRec.rFormField_Order_SV_File }
            }
        }
        result = ((result / 10) + 1) * 10
        return result
    }
    
    // mark as deleted an entry and all its subEntries (if any)
    public func delete(forFFEindex:Int) {
        assert(forFFEindex >= 0 && forFFEindex < self.mOrgFormFields.count, "Index out of range")
//debugPrint("\(self.mCTAG).delete for FFE index \(forFFEindex)")
        self.mOrgFormFields[forFFEindex].mDuringEditing_isDeleted = true
        
        // also mark as deleted any of its sub-fields
        if (self.mOrgFormFields[forFFEindex].mFormFieldRec.rFieldProp_Contains_Field_IDCodes?.count ?? 0) > 0 {
            let ffIndex:Int64 = self.mOrgFormFields[forFFEindex].mFormFieldRec.rFormField_Index
            for entry:OrgFormFieldsEntry in self.mOrgFormFields {
                if (entry.mFormFieldRec.rFormField_SubField_Within_FormField_Index ?? -1) >= 0 {
                    if entry.mFormFieldRec.rFormField_SubField_Within_FormField_Index == ffIndex {
//debugPrint("\(self.mCTAG).delete for subfield FFE index \(forFFEindex)")
                        entry.mDuringEditing_isDeleted = true
                    }
                }
            }
        }
    }
    
    // move a source FFE to the slot before the destination FFE;
    // true as-shown sort order as used by EntryFormViewController is the mFormFieldRec.rFormField_Order_Shown which must be re-calculated
    // throughout the entire set of form field entries, including its subfield's (if any);
    // note when saving the form, the entire set of fields will be physically and numerically properly re-ordered in a compact manner,
    // so this convenience for the Preview Mode need not be compact
    public func moveToPrimaryEnd(sourceFFEindex:Int) {
        self.moveBefore(sourceFFEindex: sourceFFEindex, destFFEindex: -1)
    }
    public func moveBefore(sourceFFEindex:Int, destFFEindex:Int) {
        assert(sourceFFEindex >= 0 && sourceFFEindex < self.mOrgFormFields.count, "Source index out of range")
        assert(destFFEindex >= -1 && destFFEindex < self.mOrgFormFields.count, "Destination index out of range")
        
        var newDestFFEindex:Int = destFFEindex
        var startingShownOrder:Int = -1
        let movedEntry = self.mOrgFormFields[sourceFFEindex]
        if destFFEindex >= 0 {
            startingShownOrder = self.mOrgFormFields[destFFEindex].mFormFieldRec.rFormField_Order_Shown
            if sourceFFEindex < destFFEindex {
                newDestFFEindex = destFFEindex - 1
//debugPrint("\(self.mCTAG).moveBefore entry physically moved from index \(sourceFFEindex) to index adjusted \(newDestFFEindex)")
            } else {
//debugPrint("\(self.mCTAG).moveBefore entry physically moved from index \(sourceFFEindex) to index \(newDestFFEindex)")
            }
        } else {
            newDestFFEindex = self.mOrgFormFields.count - 1
            for inx in 0...self.mOrgFormFields.count - 1 {
                if self.mOrgFormFields[inx].mFormFieldRec.rFormField_Order_Shown >= RecOrgFormFieldDefs.FORMFIELD_ORDER_UPPERSTART {
                    newDestFFEindex = inx
                    break
                }
            }
//debugPrint("\(self.mCTAG).moveBefore entry physically moved from index \(sourceFFEindex) to end of non-metadata entries \(newDestFFEindex)")
        }
        self.mOrgFormFields.remove(at: sourceFFEindex)
        self.mOrgFormFields.insert(movedEntry, at: newDestFFEindex)
        
        // get an array of sorted index#s into self.mOrgFormFields in rFormField_Order_Shown order
        let currentShownOrder:[Int] = self.mOrgFormFields.enumerated().sorted { $0.element.mFormFieldRec.rFormField_Order_Shown < $1.element.mFormFieldRec.rFormField_Order_Shown }.map { $0.offset }
        
        // reorder all the rFormField_Order_Shown that are at the destination insertion point and beyond (which may include the source too)
        var reordering:Bool = false
        for nextIndex in currentShownOrder {
            if destFFEindex < 0 {
                if self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown < RecOrgFormFieldDefs.FORMFIELD_ORDER_UPPERSTART {
//debugPrint("\(self.mCTAG).moveBefore reordering index \(nextIndex) sort order \(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown) is #\(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Index)")
                    startingShownOrder =  self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown
                }
            } else {
                if self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown == startingShownOrder {
                    reordering = true
                }
                if self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown >= RecOrgFormFieldDefs.FORMFIELD_ORDER_UPPERSTART {
//debugPrint("\(self.mCTAG).moveBefore reordering meta index \(nextIndex) sort order \(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown) is #\(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Index)")
                } else if reordering {
//debugPrint("\(self.mCTAG).moveBefore reordering index \(nextIndex) sort order \(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown) -> \(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown + 10) is #\(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Index)")
                    self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown = self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown + 10
                } else {
//debugPrint("\(self.mCTAG).moveBefore reordering index \(nextIndex) sort order \(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Order_Shown) is #\(self.mOrgFormFields[nextIndex].mFormFieldRec.rFormField_Index)")
                }
            }
        }
        
        // place the source at the destination's former rFormField_Order_Shown
        if destFFEindex < 0 {
            startingShownOrder = ((startingShownOrder / 10) + 1) * 10
        }
//debugPrint("\(self.mCTAG).moveBefore reordering dest index \(newDestFFEindex) sort order \(self.mOrgFormFields[newDestFFEindex].mFormFieldRec.rFormField_Order_Shown) -> \(startingShownOrder) is #\(self.mOrgFormFields[newDestFFEindex].mFormFieldRec.rFormField_Index)")
        self.mOrgFormFields[newDestFFEindex].mFormFieldRec.rFormField_Order_Shown = startingShownOrder
        
        // now deal with its subfield's (if any)
        if (self.mOrgFormFields[newDestFFEindex].mFormFieldRec.rFieldProp_Contains_Field_IDCodes?.count ?? 0) > 0 {
            let ffindex:Int64 = self.mOrgFormFields[newDestFFEindex].mFormFieldRec.rFormField_Index
            var nextIndex = startingShownOrder + 1
            var inx:Int = 0
            for entry in self.mOrgFormFields {
                if entry.mFormFieldRec.rFormField_SubField_Within_FormField_Index != nil {
                    if entry.mFormFieldRec.rFormField_SubField_Within_FormField_Index! == ffindex {
//debugPrint("\(self.mCTAG).moveBefore reordering dest sub index \(inx) sort order \(entry.mFormFieldRec.rFormField_Order_Shown) -> \(nextIndex) is #\(entry.mFormFieldRec.rFormField_Index)")
                        entry.mFormFieldRec.rFormField_Order_Shown = nextIndex
                        nextIndex = nextIndex + 1
                    }
                }
                inx = inx + 1
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// FieldAttributes struct for various Records and OrgFormFieldsEntry class
/////////////////////////////////////////////////////////////////////////

// attribute duo strings:  "tag:value"
// used separately for choice attributes and metadata attributes
// used separately for for SV-File language values and Shown language values
// is a struct so it will be shallow copied upon record duplication
// duplicate CodePair.codeString are not allowed since it will cause exceptions in Eureka
public struct FieldAttributes {
    public var mAttributes:[CodePair]
    
    // default initializer
    init() {
        self.mAttributes = []
    }
    
    // bulk initialization usually from the Database or a JSON file; duplicate codeString are ignored
    init(duos:[String]) {
        self.mAttributes = []
        for pair in duos {
            let pairComponents:[String] = pair.components(separatedBy: ":")
            var cd:CodePair
            if pairComponents.count >= 2 { cd = CodePair(pairComponents[0], pairComponents[1]) }
            else { cd = CodePair(pairComponents[0], pairComponents[0]) }
            if !self.codeExists(givenCode: cd.codeString) {
                self.mAttributes.append(cd)
            }
        }
    }
    
    // pack up the values into a String (for the database or a JSON file)
    public func pack() -> String {
        var retStr:String = ""
        var separator:String = ""
        for pair in self.mAttributes {
            retStr = retStr + "\(separator)\(pair.codeString):\(pair.valueString)"
            separator = ","
        }
        return retStr
    }
    
    // append a new CodePair (if it is not a duplicate codeString)
    public mutating func append(codeString:String, valueString:String) {
        let cd:CodePair = CodePair(codeString, valueString)
        if !self.codeExists(givenCode: cd.codeString) {
            self.mAttributes.append(cd)
        }
    }
    
    // remove a CodePair
    public mutating func remove(givenCode:String) -> Bool {
        for inx in 0...self.mAttributes.count - 1 {
            if givenCode == self.mAttributes[inx].codeString {
                self.mAttributes.remove(at: inx)
                return true
            }
        }
        return false
    }
    
    // count of the number of CodePairs
    public func count() -> Int {
        return self.mAttributes.count
    }
    
    // does a CodePair already exist
    public func codeExists(givenCode:String) -> Bool {
        for pair in self.mAttributes {
            if givenCode == pair.codeString { return true }
        }
        return false
    }
    
    // find an entry's string given its value
    public func findCode(givenValue:String) -> String? {
        for pair in self.mAttributes {
            if givenValue == pair.valueString { return pair.codeString }
        }
        return nil
    }
    
    // find an entry's string given its code
    public func findValue(givenCode:String) -> String? {
        for pair in self.mAttributes {
            if givenCode == pair.codeString { return pair.valueString }
        }
        return nil
    }
    
    // change the value of an existing entry
    public mutating func setValue(newValue:String, givenCode:String) -> Bool {
        for inx in 0...self.mAttributes.count - 1 {
            if givenCode == self.mAttributes[inx].codeString {
                self.mAttributes[inx].valueString = newValue
                return true
            }
        }
        return false
    }
    
    // compare the sync-status of a SV-File set and a Shown set
    public static func compareSync(domain:String, sv:FieldAttributes?, shown:FieldAttributes?, deepSync:Bool=false) throws {
        if sv == nil || shown == nil {
            throw APP_ERROR(funcName: "FieldAttributes.compareSync", domain: domain, errorCode: .MISSING_OR_MISMATCHED_FIELD_OPTIONS, userErrorDetails: nil, developerInfo: "sv == nil || shown == nil")
        }
        if sv!.count() == 0 || shown!.count() == 0 {
            throw APP_ERROR(funcName: "FieldAttributes.compareSync", domain: domain, errorCode: .MISSING_OR_MISMATCHED_FIELD_OPTIONS, userErrorDetails: nil, developerInfo: "sv!.count() == 0 || shown!.count() == 0")
        }
        if sv!.count() != shown!.count() {
            throw APP_ERROR(funcName: "FieldAttributes.compareSync", domain: domain, errorCode: .MISSING_OR_MISMATCHED_FIELD_OPTIONS, userErrorDetails: nil, developerInfo: "sv!.count() != shown!.count()")
        }
        if deepSync {
            for svCP in sv!.mAttributes {
                if !shown!.codeExists(givenCode: svCP.codeString) {
                    throw APP_ERROR(funcName: "FieldAttributes.compareSync", domain: domain, errorCode: .MISSING_OR_MISMATCHED_FIELD_OPTIONS, userErrorDetails: nil, developerInfo: "sv entry '\(svCP.codeString)' not found in shown")
                }
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////
// Entry class for OrgFormFields
/////////////////////////////////////////////////////////////////////////

// an entry in the mOrgFormFields array and convenience editing methods;
public class OrgFormFieldsEntry {
    // the primary formField record; during Editing has all its linked RecOrgFormFieldLocales
    public var mFormFieldRec:RecOrgFormFieldDefs
    // the *composed* RecOrgFormFieldLocales appropriate to the current language sets
    public var mComposedFormFieldLocalesRec:RecOrgFormFieldLocales_Composed
    // the *composed* RecFieldAttribLocales (usually none) appropriate to the current language sets
    public var mComposedOptionSetLocalesRecs:[RecOptionSetLocales_Composed]?
    public var mDuringEditing_isDeleted:Bool = false            // during Editing, the entire entry is marked as deleted
    public var mDuringEditing_isChosen:Bool = false             // during Editing for subfields, indicates that mFormFieldRec and mComposedFormFieldLocalesRec are from the database or are new and custom
    public var mDuringEditing_isDefault:Bool = false             // during Editing for subfields, this field is a direct default from the JSON
    
    // member constants and other static content
    internal var mCTAG:String = "HFfE"
    
    public init(formFieldRec:RecOrgFormFieldDefs, composedFormFieldLocalesRec:RecOrgFormFieldLocales_Composed,
                composedOptionSetLocalesRecs:[RecOptionSetLocales_Composed]?) {
        self.mFormFieldRec = formFieldRec
        self.mComposedFormFieldLocalesRec = composedFormFieldLocalesRec
        self.mComposedOptionSetLocalesRecs = composedOptionSetLocalesRecs
    }
    
    // deallocation of the class object is occuring
    deinit {
//debugPrint("\(self.mCTAG).deinit STARTED")
    }
    
    // performs a deep duplication of a OrgFormFieldsEntry for just the mFormFieldRec and mComposedFormFieldLocalesRec;
    // the mComposedFieldAttribLocalesRecs records (if any) are only shallow copied
    init(existingEntry:OrgFormFieldsEntry) {
        self.mFormFieldRec = RecOrgFormFieldDefs(existingRec: existingEntry.mFormFieldRec)  // this auto-deep-copies any internal RecOrgFormFieldLocales
        self.mComposedFormFieldLocalesRec = RecOrgFormFieldLocales_Composed(existingRec: existingEntry.mComposedFormFieldLocalesRec)
        self.mComposedOptionSetLocalesRecs = existingEntry.mComposedOptionSetLocalesRecs
        self.mDuringEditing_isDeleted = existingEntry.mDuringEditing_isDeleted
    }
    
    // clear out an entry to ensure we get a complete deinit()
    public func clear() {
        if self.mFormFieldRec.mFormFieldLocalesRecs != nil { self.mFormFieldRec.mFormFieldLocalesRecs!.removeAll() }
        if self.mComposedOptionSetLocalesRecs != nil { self.mComposedOptionSetLocalesRecs!.removeAll(); self.mComposedOptionSetLocalesRecs = nil }
    }
    
    /////////////////////////////////////////////////////////////////////////
    // Convenience Regionalization methods for Editing to properly set internal RecOrgFormFieldLocales as well as the mComposedFormFieldLocalesRec
    // getters are also provided for convenience
    /////////////////////////////////////////////////////////////////////////
    
    public func getShown(forLangRegion:String) -> String? {
        let inx:Int = self.chooseLangRecForEditing(langRegion: forLangRegion)
        return self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Name_Shown
    }
    
    // set the shown in both the mComposedFormFieldLocalesRec and any internal RecOrgFormFieldLocales within the RecOrgFormFieldDefs
    public func setShown(value:String?, forLangRegion:String) {
        let inx:Int = self.chooseLangRecForEditing(langRegion: forLangRegion)
        self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Name_Shown = value
        self.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
        
        for aFormFieldLocaleRec in self.mFormFieldRec.mFormFieldLocalesRecs! {
            if aFormFieldLocaleRec.rFormFieldLoc_LangRegionCode == self.mComposedFormFieldLocalesRec.mLocale2LangRegion {
                self.mComposedFormFieldLocalesRec.rFieldLocProp_Name_Shown = aFormFieldLocaleRec.rFieldLocProp_Name_Shown
            }
        }
    }
    
    public func getPlaceholder(forLangRegion:String) -> String? {
        let inx:Int = self.chooseLangRecForEditing(langRegion: forLangRegion)
        return self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Placeholder_Shown
    }
    
    // set the shown in both the mComposedFormFieldLocalesRec and any internal RecOrgFormFieldLocales within the RecOrgFormFieldDefs
    public func setPlaceholder(value:String?, forLangRegion:String) {
        let inx:Int = self.chooseLangRecForEditing(langRegion: forLangRegion)
        self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Placeholder_Shown = value
        self.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
        
        for aFormFieldLocaleRec in self.mFormFieldRec.mFormFieldLocalesRecs! {
            if aFormFieldLocaleRec.rFormFieldLoc_LangRegionCode == self.mComposedFormFieldLocalesRec.mLocale2LangRegion {
                self.mComposedFormFieldLocalesRec.rFieldLocProp_Placeholder_Shown = aFormFieldLocaleRec.rFieldLocProp_Placeholder_Shown
            }
        }
    }
    
    // setters and getters for Option attributes
    public func existsOptionTag(tagValue:String) -> Bool {
        return self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File?.codeExists(givenCode: tagValue) ?? false
    }
    public func getOptionSVFile(forTag:String) -> String? {
        return self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File?.findValue(givenCode: forTag) ?? nil
    }
    public func getOptionShown(forTag:String, forLangRegion:String) -> String? {
        let inx:Int = self.chooseLangRecForEditing(langRegion: forLangRegion)
        if (self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Options_Name_Shown?.count() ?? 0) == 0 { return nil }
        return self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Options_Name_Shown!.findValue(givenCode: forTag) ?? nil
    }
    public func setOptionSVFile(value:String, forTag:String) {
        if self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File != nil {
            let _ = self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File!.setValue(newValue: value, givenCode: forTag)
        }
    }
    public func setOptionShown(value:String, forTag:String, forLangRegion:String) {
        let inx:Int = self.chooseLangRecForEditing(langRegion: forLangRegion)
        if self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Options_Name_Shown != nil {
            let _ = self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Options_Name_Shown!.setValue(newValue: value, givenCode: forTag)
        }
        self.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
        
        for aFormFieldLocaleRec in self.mFormFieldRec.mFormFieldLocalesRecs! {
            if aFormFieldLocaleRec.rFormFieldLoc_LangRegionCode == self.mComposedFormFieldLocalesRec.mLocale2LangRegion {
                self.mComposedFormFieldLocalesRec.rFieldLocProp_Options_Name_Shown = aFormFieldLocaleRec.rFieldLocProp_Options_Name_Shown
            }
            if aFormFieldLocaleRec.rFormFieldLoc_LangRegionCode == self.mComposedFormFieldLocalesRec.mLocale3LangRegion {
                self.mComposedFormFieldLocalesRec.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = aFormFieldLocaleRec.rFieldLocProp_Options_Name_Shown
            }
        }
    }
    public func addOption(tagValue:String, SVfileValue:String, langShownPairs:[CodePair]) {
        if self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File == nil { self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File = FieldAttributes() }
        if !self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File!.codeExists(givenCode: tagValue) {
            self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File!.append(codeString: tagValue, valueString: SVfileValue)
            
            for cp in langShownPairs {
                let inx:Int = self.chooseLangRecForEditing(langRegion: cp.codeString)
                if self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Options_Name_Shown == nil {
                    self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Options_Name_Shown = FieldAttributes()
                }
                self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Options_Name_Shown!.append(codeString: tagValue, valueString: cp.valueString)
            }
        }
    }
    public func removeOption(tagValue:String) {
        let _ = self.mFormFieldRec.rFieldProp_Options_Code_For_SV_File?.remove(givenCode: tagValue)
        if self.mFormFieldRec.mFormFieldLocalesRecs != nil {
            for formFieldLocaleRec in self.mFormFieldRec.mFormFieldLocalesRecs! {
                let _ = formFieldLocaleRec.rFieldLocProp_Options_Name_Shown?.remove(givenCode: tagValue)
            }
        }
        self.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
        
        for aFormFieldLocaleRec in self.mFormFieldRec.mFormFieldLocalesRecs! {
            if aFormFieldLocaleRec.rFormFieldLoc_LangRegionCode == self.mComposedFormFieldLocalesRec.mLocale2LangRegion {
                self.mComposedFormFieldLocalesRec.rFieldLocProp_Options_Name_Shown = aFormFieldLocaleRec.rFieldLocProp_Options_Name_Shown
            }
            if aFormFieldLocaleRec.rFormFieldLoc_LangRegionCode == self.mComposedFormFieldLocalesRec.mLocale3LangRegion {
                self.mComposedFormFieldLocalesRec.mFieldLocProp_Options_Name_Shown_Bilingual_2nd = aFormFieldLocaleRec.rFieldLocProp_Options_Name_Shown
            }
        }
    }
    
    // setters and getters for Metadata attributes
    public func existsMetadataTag(tagValue:String) -> Bool {
        return self.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File?.codeExists(givenCode: tagValue) ?? false
    }
    public func getMetadataSVFile(forTag:String) -> String? {
        return self.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File?.findValue(givenCode: forTag) ?? nil
    }
    public func getMetadataShown(forTag:String, forLangRegion:String) -> String? {
        let inx:Int = self.chooseLangRecForEditing(langRegion: forLangRegion)
        if (self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Metadatas_Name_Shown?.count() ?? 0) == 0 { return nil }
        return self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Metadatas_Name_Shown!.findValue(givenCode: forTag) ?? nil
    }
    public func setMetadataSVFile(value:String, forTag:String) {
        if self.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File != nil {
            let _ = self.mFormFieldRec.rFieldProp_Metadatas_Code_For_SV_File!.setValue(newValue: value, givenCode: forTag)
        }
    }
    public func setMetadataShown(value:String, forTag:String, forLangRegion:String) {
        let inx:Int = self.chooseLangRecForEditing(langRegion: forLangRegion)
        if self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Metadatas_Name_Shown != nil {
            let _ = self.mFormFieldRec.mFormFieldLocalesRecs![inx].rFieldLocProp_Metadatas_Name_Shown!.setValue(newValue: value, givenCode: forTag)
        }
        self.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
        
        for aFormFieldLocaleRec in self.mFormFieldRec.mFormFieldLocalesRecs! {
            if aFormFieldLocaleRec.rFormFieldLoc_LangRegionCode == self.mComposedFormFieldLocalesRec.mLocale2LangRegion {
                self.mComposedFormFieldLocalesRec.rFieldLocProp_Metadatas_Name_Shown = aFormFieldLocaleRec.rFieldLocProp_Metadatas_Name_Shown
            }
            if aFormFieldLocaleRec.rFormFieldLoc_LangRegionCode == self.mComposedFormFieldLocalesRec.mLocale3LangRegion {
                self.mComposedFormFieldLocalesRec.mFieldLocProp_Metadatas_Name_Shown_Bilingual_2nd = aFormFieldLocaleRec.rFieldLocProp_Metadatas_Name_Shown
            }
        }
    }
    
    // choose the RecOrgFormFieldLocales that will be used
    private func chooseLangRecForEditing(langRegion:String) -> Int {
        if self.mFormFieldRec.mFormFieldLocalesRecs == nil { self.mFormFieldRec.mFormFieldLocalesRecs = [] }
        
        var inx:Int = 0
        for formFieldLocRec in self.mFormFieldRec.mFormFieldLocalesRecs! {
            if formFieldLocRec.rFormFieldLoc_LangRegionCode == langRegion { return inx }
            inx = inx + 1
        }
        
        let newFormFieldLocalesRec:RecOrgFormFieldLocales = RecOrgFormFieldLocales(formfieldloc_index: -1, orgShortName: self.mFormFieldRec.rOrg_Code_For_SV_File, formShortName: self.mFormFieldRec.rForm_Code_For_SV_File, formfield_index: self.mFormFieldRec.rFormField_Index, langRegion: langRegion, nameForCollector: "??")
        newFormFieldLocalesRec.rFieldLocProp_Name_Shown = "??"
        self.mFormFieldRec.mFormFieldLocalesRecs!.append(newFormFieldLocalesRec)
        self.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
        
        return self.mFormFieldRec.mFormFieldLocalesRecs!.count - 1
    }
}
