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
    private static var mNextTemporaryFFindex:Int64 = -10     // these temporary assignments will remain unique across multiple instances of OrgFormFields; -1 to -9 are reserved for other uses
    private var mOrgFormFields:[OrgFormFieldsEntry] = []
    
    // member constants and other static content
    internal var mCTAG:String = "HOFFs"
    
    // deallocation of the class object is occuring
    deinit {
//debugPrint("\(self.mCTAG).deinit STARTED")
    }
    
    // standard initializer
    init() {
    }
    
    // do a deep copy initializer
    init(existing: OrgFormFields) {
        for entry:OrgFormFieldsEntry in existing {
            self.mOrgFormFields.append(OrgFormFieldsEntry(existingEntry: entry))
        }
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
    
    // return the count of primary FormField entries
    public func countPrimary() -> Int {
        var counter:Int = 0
        for formField in self.mOrgFormFields { if !formField.mFormFieldRec.isSubFormField() { counter = counter + 1 } }
        return counter
    }
    
    // return the count of non-deleted FormField entries
    public func countNotDeleted() -> Int {
        var counter:Int = 0
        for formField in self.mOrgFormFields { if !formField.mDuringEditing_isDeleted { counter = counter + 1 } }
        return counter
    }
    
    // has any form field changed?
    // the order of fields in the sequence is not important
    public func hasChanged(existingEntry: OrgFormFields) -> Bool {
        if self.mOrgFormFields.count != existingEntry.mOrgFormFields.count { return true }
        if self.countNotDeleted() != existingEntry.countNotDeleted() { return true }
        
        for ffEntrySelf:OrgFormFieldsEntry in self.mOrgFormFields {
            let ffEntryExistInx:Int = existingEntry.findIndex(ofFormFieldIndex: ffEntrySelf.mFormFieldRec.rFormField_Index, includeDeleted: true)
            if ffEntryExistInx < 0 { return true }
            let ffEntryExist:OrgFormFieldsEntry = existingEntry[ffEntryExistInx]
            if ffEntrySelf.hasChanged(existingEntry: ffEntryExist) { return true }
        }
        for ffEntryExist:OrgFormFieldsEntry in existingEntry.mOrgFormFields {
            let ffEntrySelfInx:Int = self.findIndex(ofFormFieldIndex: ffEntryExist.mFormFieldRec.rFormField_Index, includeDeleted: true)
            if ffEntrySelfInx < 0 { return true }
            let ffEntrySelf:OrgFormFieldsEntry = self.mOrgFormFields[ffEntrySelfInx]
            if ffEntryExist.hasChanged(existingEntry: ffEntrySelf) { return true }
        }
        return false
    }
    
    // append an existing OrgFormFieldsEntry (no temporary auto-indexing)
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
    
    // append a new subfield OrgFormFieldsEntry with auto-temporary indexing
    public func appendNewSubfieldDuringEditing(_ entry:OrgFormFieldsEntry, primary:OrgFormFieldsEntry) {
        entry.mFormFieldRec.rFormField_SubField_Within_FormField_Index = primary.mFormFieldRec.rFormField_Index
        self.appendNewDuringEditing(entry)
    }
    
    // append a collection of fields and subfields; this is usually from a Copy during a Paste
    public func appendNewDuringEditing(fromFormFields:OrgFormFields, forOrgCode:String, forFormCode:String) {
        var orderShown:Int = self.getNextOrderShown()
        var orderSVfile:Int = self.getNextOrderSVfile()
        var subcount:Int = 0
        
        // step thru the primary FormFields; note meta-data FormFields will never be present
        for newFormFieldEntry in fromFormFields {
            if !newFormFieldEntry.mFormFieldRec.isSubFormField() {
                newFormFieldEntry.mFormFieldRec.rOrg_Code_For_SV_File = forOrgCode
                newFormFieldEntry.mFormFieldRec.rForm_Code_For_SV_File = forFormCode
                newFormFieldEntry.mFormFieldRec.rFormField_Order_SV_File = orderSVfile
                newFormFieldEntry.mFormFieldRec.rFormField_Order_Shown = orderShown
                newFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true   // the actual to-be-saved RecOrgFormFieldLocales are within this object
                
                newFormFieldEntry.mComposedFormFieldLocalesRec.rForm_Code_For_SV_File = forOrgCode
                newFormFieldEntry.mComposedFormFieldLocalesRec.rForm_Code_For_SV_File = forFormCode
                
                let originalIndex:Int64 = newFormFieldEntry.mFormFieldRec.rFormField_Index
                self.appendNewDuringEditing(newFormFieldEntry)  // this auto-assigns temporary rFormField_Index and for its internal locale records
                
                subcount = orderShown + 1
                orderShown = orderShown + 10
                orderSVfile = orderSVfile + 1

                // now handle any potential subFormFields of the current primary FormField
                for newSubFormFieldEntry in fromFormFields {
                    if newSubFormFieldEntry.mFormFieldRec.isSubFormField() {
                        if newSubFormFieldEntry.mFormFieldRec.rFormField_SubField_Within_FormField_Index == originalIndex {
                            // found a subfield for the current primary field
                            newSubFormFieldEntry.mFormFieldRec.rOrg_Code_For_SV_File = forOrgCode
                            newSubFormFieldEntry.mFormFieldRec.rForm_Code_For_SV_File = forFormCode
                            newSubFormFieldEntry.mFormFieldRec.rFormField_Order_SV_File = orderSVfile
                            newSubFormFieldEntry.mFormFieldRec.rFormField_Order_Shown = subcount
                            newSubFormFieldEntry.mFormFieldRec.mFormFieldLocalesRecs_are_changed = true
                            
                            newSubFormFieldEntry.mComposedFormFieldLocalesRec.rForm_Code_For_SV_File = forOrgCode
                            newSubFormFieldEntry.mComposedFormFieldLocalesRec.rForm_Code_For_SV_File = forFormCode
                            
                            self.appendNewSubfieldDuringEditing(newSubFormFieldEntry, primary: newFormFieldEntry)  // this auto-assigns temporary rFormField_Index and for its locale records

                            subcount = subcount + 1
                            orderSVfile = orderSVfile + 1
                        }
                    }
                }
            }
        }
    }
    
    // find the index of a specific FormField index#; return -1 if not found
    public func findIndex(ofFormFieldIndex:Int64, includeDeleted:Bool=false) -> Int {
        if self.mOrgFormFields.count == 0 { return -1 }
        var inx:Int = 0
        for entry in self.mOrgFormFields {
            if includeDeleted {
                if entry.mFormFieldRec.rFormField_Index == ofFormFieldIndex { return inx }
            } else {
                if !entry.mDuringEditing_isDeleted && entry.mFormFieldRec.rFormField_Index == ofFormFieldIndex { return inx }
            }
            inx = inx + 1
        }
        return -1
    }
    
    // find the index of a specific Field ID_Code; return -1 if not found
    public func findIndex(ofFieldIDCode:String, includeDeleted:Bool=false) -> Int {
        if self.mOrgFormFields.count == 0 { return -1 }
        var inx:Int = 0
        for entry in self.mOrgFormFields {
            if includeDeleted {
                if entry.mFormFieldRec.rFieldProp_IDCode == ofFieldIDCode { return inx }
            } else {
                if !entry.mDuringEditing_isDeleted && entry.mFormFieldRec.rFieldProp_IDCode == ofFieldIDCode { return inx }
            }
            inx = inx + 1
        }
        return -1
    }

    // find a specific subfield for a contain primary field; return nil if not found
    public func findSubfield(forPrimaryIndex:Int64, forSubFieldIDCode:String) -> OrgFormFieldsEntry? {
        for entry in self.mOrgFormFields {
            if !entry.mDuringEditing_isDeleted && entry.mFormFieldRec.isSubFormField() {
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
        if self.mOrgFormFields[forFFEindex].mFormFieldRec.hasSubFormFields() {
            let ffIndex:Int64 = self.mOrgFormFields[forFFEindex].mFormFieldRec.rFormField_Index
            for entry:OrgFormFieldsEntry in self.mOrgFormFields {
                if entry.mFormFieldRec.isSubFormField() {
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
        if self.mOrgFormFields[newDestFFEindex].mFormFieldRec.hasSubFormFields() {
            let ffindex:Int64 = self.mOrgFormFields[newDestFFEindex].mFormFieldRec.rFormField_Index
            var nextIndex = startingShownOrder + 1
            var inx:Int = 0
            for entry in self.mOrgFormFields {
                if entry.mFormFieldRec.isSubFormField() {
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
        // special situations
        if (sv?.count() ?? 0) == 1, (shown?.count() ?? 0) == 0, sv!.mAttributes[0].codeString.prefix(8) == "***OSLC_" { return }
        
        // standard consistency checks
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
// Entry class for OrgFormFieldsEntry
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
    public var mDuringEditing_isDefault:Bool = false            // during Editing for subfields, this field is a direct default from the JSON
    public var mDuringEditing_SubFormFields:[OrgFormFieldsEntry]? = nil     // during Editing, storage for the primary field's subfields
    
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
    // the mComposedOptionSetLocalesRecs records (if any) are only shallow copied but any subfields are deep copied
    init(existingEntry:OrgFormFieldsEntry) {
        self.mFormFieldRec = RecOrgFormFieldDefs(existingRec: existingEntry.mFormFieldRec)  // this auto-deep-copies any internal RecOrgFormFieldLocales
        self.mComposedFormFieldLocalesRec = RecOrgFormFieldLocales_Composed(existingRec: existingEntry.mComposedFormFieldLocalesRec)
        self.mComposedOptionSetLocalesRecs = existingEntry.mComposedOptionSetLocalesRecs
        self.mDuringEditing_isDeleted = existingEntry.mDuringEditing_isDeleted
        self.mDuringEditing_isChosen = existingEntry.mDuringEditing_isChosen
        self.mDuringEditing_isDefault = existingEntry.mDuringEditing_isDefault
        
        if existingEntry.mDuringEditing_SubFormFields != nil {
            self.mDuringEditing_SubFormFields = []
            for subEntry in existingEntry.mDuringEditing_SubFormFields! {
                self.mDuringEditing_SubFormFields!.append(OrgFormFieldsEntry(existingEntry: subEntry))
            }
        }
    }
    
    // clear out an entry to ensure we get a complete deinit()
    public func clear() {
        if self.mFormFieldRec.mFormFieldLocalesRecs != nil { self.mFormFieldRec.mFormFieldLocalesRecs!.removeAll(); self.mFormFieldRec.mFormFieldLocalesRecs = nil }
        if self.mComposedOptionSetLocalesRecs != nil { self.mComposedOptionSetLocalesRecs!.removeAll(); self.mComposedOptionSetLocalesRecs = nil }
        if self.mDuringEditing_SubFormFields != nil { self.mDuringEditing_SubFormFields!.removeAll();  self.mDuringEditing_SubFormFields = nil }
    }
    
    // is there an already existing subFormField with the indicated Field IDCode?
    public func hasSubFormField(ofFieldIDCode:String) -> Bool {
        if self.mDuringEditing_SubFormFields == nil { return false }
        for subEntry:OrgFormFieldsEntry in self.mDuringEditing_SubFormFields! {
            if subEntry.mFormFieldRec.rFieldProp_IDCode == ofFieldIDCode { return true }
        }
        return false
    }
    
    // has the form field changed in any of its values?
    // do not bother with the composed members
    public func hasChanged(existingEntry:OrgFormFieldsEntry) -> Bool {
        if self.mFormFieldRec.hasChanged(existingEntry: existingEntry.mFormFieldRec) { return true }    // includes all included locale records
        if self.mDuringEditing_isChosen != existingEntry.mDuringEditing_isChosen { return true }
        if self.mDuringEditing_isDeleted != existingEntry.mDuringEditing_isDeleted { return true }
        if (self.mDuringEditing_SubFormFields == nil && existingEntry.mDuringEditing_SubFormFields != nil) ||
           (self.mDuringEditing_SubFormFields != nil && existingEntry.mDuringEditing_SubFormFields == nil) { return true }
        
        // also check any stored subFormFields
        if self.mDuringEditing_SubFormFields != nil {
            for subEntrySelf:OrgFormFieldsEntry in self.mDuringEditing_SubFormFields! {
                var found:Bool = false
                for subEntryExisting:OrgFormFieldsEntry in existingEntry.mDuringEditing_SubFormFields! {
                    if subEntrySelf.mFormFieldRec.rFieldProp_IDCode == subEntryExisting.mFormFieldRec.rFieldProp_IDCode {
                        if subEntrySelf.hasChanged(existingEntry: subEntryExisting) { return true }
                        found = true
                    }
                }
                if !found { return true }
            }
            for subEntryExisting:OrgFormFieldsEntry in existingEntry.mDuringEditing_SubFormFields! {
                var found:Bool = false
                for subEntrySelf:OrgFormFieldsEntry in self.mDuringEditing_SubFormFields! {
                    if subEntrySelf.mFormFieldRec.rFieldProp_IDCode == subEntryExisting.mFormFieldRec.rFieldProp_IDCode {
                        if subEntrySelf.hasChanged(existingEntry: subEntryExisting) { return true }
                        found = true
                    }
                }
                if !found { return true }
            }
        }
        return false
    }
    
    // include a copy of subFormField entries from the master list
    public func includeSubFormFields(from: OrgFormFields) {
        for entry in from {
            if entry.mFormFieldRec.rFormField_SubField_Within_FormField_Index == self.mFormFieldRec.rFormField_Index {
//debugPrint("\(self.mCTAG).includeSubFormFields SubFormField from master list: \(entry.mFormFieldRec.rFormField_Index) \(entry.mFormFieldRec.rFieldProp_IDCode)")
                if entry.mDuringEditing_isDeleted { entry.mDuringEditing_isChosen = false }
                else { entry.mDuringEditing_isChosen = true }
                if self.mDuringEditing_SubFormFields == nil { self.mDuringEditing_SubFormFields = [] }
                self.mDuringEditing_SubFormFields!.append(entry)
            }
        }
    }
    
    // save the primary form field back into its source list of form fields; includes saving any stored subFormFields;
    // note that at this stage, form fields are marked as deleted rather than being removed from the OrgFormFields
    public func save(into:OrgFormFields) {
//debugPrint("\(self.mCTAG).save STARTED")
        // first correct the .rFieldProp_Contains_Field_IDCodes if there are any subFormFields
        if (self.mDuringEditing_SubFormFields?.count ?? 0) > 0 {
            self.mFormFieldRec.rFieldProp_Contains_Field_IDCodes = []
            for subFormFieldEntry in self.mDuringEditing_SubFormFields! {
                if subFormFieldEntry.mDuringEditing_isChosen {
                    self.mFormFieldRec.rFieldProp_Contains_Field_IDCodes!.append(subFormFieldEntry.mFormFieldRec.rFieldProp_IDCode)
                }
            }
        }
        
        // next update or add this primary form field to the master list
        let inx:Int = into.findIndex(ofFormFieldIndex: self.mFormFieldRec.rFormField_Index)
        if inx >= 0 {
            // formField already exists in the master list
            into[inx] = self
        } else {
            // formField not already present; need to add it to the master list even if marked as deleted;
            // new temporary index# will be assigned
            into.appendNewDuringEditing(self)
        }

        // now do the subFormFields as they need to be "stripped" out of the entry into their own form fields;
        // some subFormFields may require an add into the main list
        if (self.mDuringEditing_SubFormFields?.count ?? 0) > 0 {
            for subFormFieldEntry in self.mDuringEditing_SubFormFields! {
                if subFormFieldEntry.mDuringEditing_isChosen { subFormFieldEntry.mDuringEditing_isDeleted = false }
                else { subFormFieldEntry.mDuringEditing_isDeleted = true }
                let inx1:Int = into.findIndex(ofFormFieldIndex: subFormFieldEntry.mFormFieldRec.rFormField_Index, includeDeleted: true)
                if inx1 >= 0 {
                    // subFormField already exists in the master list
                    into[inx1] = subFormFieldEntry
                } else {
                    // subFormField not already present; need to add it to the master list even if marked as deleted;
                    // new temporary index# will be assigned; and the primary field will get auto-linked to the subFormField
                    into.appendNewSubfieldDuringEditing(subFormFieldEntry, primary: self)
                }
            }
        }
        if self.mDuringEditing_SubFormFields != nil {
            self.mDuringEditing_SubFormFields!.removeAll()
            self.mDuringEditing_SubFormFields = nil
        }
    }
    
    // save the subFormField back into its source list of subFormFields
    public func saveSubFormField(into:OrgFormFieldsEntry) {
//debugPrint("\(self.mCTAG).saveSubFormField STARTED")
        if self.mDuringEditing_isChosen { self.mDuringEditing_isDeleted = false }
        else {self.mDuringEditing_isDeleted = true }    // even if deleted, save any changes made by end-user to the not-chosen entry

        if into.mDuringEditing_SubFormFields == nil {
            // no subfields yet, so just append it
            into.mDuringEditing_SubFormFields = []
            into.mDuringEditing_SubFormFields!.append(self)
        } else {
            // find any existing entry
            var found:Bool = false
            for inx:Int in 0...into.mDuringEditing_SubFormFields!.count - 1 {
                let existingSFF:OrgFormFieldsEntry = into.mDuringEditing_SubFormFields![inx]
                if existingSFF.mFormFieldRec.rFieldProp_IDCode == self.mFormFieldRec.rFieldProp_IDCode {
                    // found existing entry:  delete the existing and append the updated
                    into.mDuringEditing_SubFormFields!.remove(at: inx)
                    into.mDuringEditing_SubFormFields!.append(self)
                    found = true
                }
            }
            if !found { into.mDuringEditing_SubFormFields!.append(self) }   // not found so append this new entry
        }
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

/////////////////////////////////////////////////////////////////////////
// Entry class for OrgFormFieldsEntryTag
/////////////////////////////////////////////////////////////////////////

public class OrgFormFieldsEntryTag {
    // current values of the Tag (ignore what is stored in mFormFieldRec)
    public var mTag:String = ""
    public var mCodeForSVFile:String = ""
    public var mPhraseShownByLang:[String:String] = [:]

    // the *composed* RecOrgFormFieldLocales appropriate to the current language sets
    public var mIsMetadata:Bool = false                         // tag is for metadata, not an option
    
    // member constants and other static content
    internal var mCTAG:String = "HFfET"
    
    public init(formField:OrgFormFieldsEntry, tag:String, isMetadata:Bool) {
        self.mTag = tag
        self.mIsMetadata = isMetadata
        
        var codeSVFile:String?
        if self.mIsMetadata { codeSVFile = formField.getMetadataSVFile(forTag: self.mTag) }
        else { codeSVFile = formField.getOptionSVFile(forTag: self.mTag) }
        if !(codeSVFile ?? "").isEmpty { self.mCodeForSVFile = codeSVFile! }
        else { self.mCodeForSVFile = "??" }
        
        if formField.mFormFieldRec.mFormFieldLocalesRecs != nil {
            for ffLocaleRec in formField.mFormFieldRec.mFormFieldLocalesRecs! {
                var shownInLang:String?
                if self.mIsMetadata { shownInLang = formField.getMetadataShown(forTag: self.mTag, forLangRegion: ffLocaleRec.rFormFieldLoc_LangRegionCode) }
                else { shownInLang = formField.getOptionShown(forTag: self.mTag, forLangRegion: ffLocaleRec.rFormFieldLoc_LangRegionCode) }
                if !(shownInLang ?? "").isEmpty { self.mPhraseShownByLang[ffLocaleRec.rFormFieldLoc_LangRegionCode] = shownInLang }
                else { self.mPhraseShownByLang[ffLocaleRec.rFormFieldLoc_LangRegionCode] = "??" }
            }
        }
    }
    
    // deallocation of the class object is occuring
    deinit {
//debugPrint("\(self.mCTAG).deinit STARTED")
    }
    
    // clear out an entry to ensure we get a complete deinit()
    public func clear() {
        //self.mFormField = nil
        self.mPhraseShownByLang = [:]
    }

    // performs a deep duplication of a OrgFormFieldsEntryTag; the weak reference to mFormFieldRec is just shallow copied
    init(existingEntry:OrgFormFieldsEntryTag) {
//debugPrint("\(self.mCTAG).init STARTED")
        self.mTag = String(existingEntry.mTag)
        self.mCodeForSVFile = String(existingEntry.mCodeForSVFile)
        self.mIsMetadata = existingEntry.mIsMetadata
        
        self.mPhraseShownByLang = [:]
        for (lang,shown) in existingEntry.mPhraseShownByLang {
            self.mPhraseShownByLang[lang] = String(shown)
        }
    }
    
    // has a tag changed in any of its values?
    public func hasChanged(existingEntry:OrgFormFieldsEntryTag) -> Bool {
        if self.mTag != existingEntry.mTag { return true }
        if self.mCodeForSVFile != existingEntry.mCodeForSVFile { return true }
        
        if self.mPhraseShownByLang.count != existingEntry.mPhraseShownByLang.count { return true }
        for (lrCode,shown) in existingEntry.mPhraseShownByLang {
            if shown != self.mPhraseShownByLang[lrCode] { return true }
        }
        for (lrCode,shown) in self.mPhraseShownByLang {
            if shown != existingEntry.mPhraseShownByLang[lrCode] { return true }
        }
        return false
    }
    
    // save the tag back into its source Form Field
    public func save(into:OrgFormFieldsEntry, was:OrgFormFieldsEntryTag) {
//debugPrint("\(self.mCTAG).save STARTED")
        if was.mTag == self.mTag || self.mIsMetadata {
            // tag did not change or it is metadata, so just update the CodeSVFile and the per-language phrases
            if self.mIsMetadata { into.setMetadataSVFile(value: self.mCodeForSVFile, forTag: self.mTag) }
            else { into.setOptionSVFile(value: self.mCodeForSVFile, forTag: self.mTag) }
            for (lrCode,shown) in self.mPhraseShownByLang {
                if self.mIsMetadata { into.setMetadataShown(value: shown, forTag: self.mTag, forLangRegion: lrCode) }
                else { into.setOptionShown(value: shown, forTag: self.mTag, forLangRegion: lrCode) }
            }
            return
        }
        
        // not metadata tag but the tag was changed; delete the old tag and add the new tag
        into.removeOption(tagValue: was.mTag)
        var langShownPairs:[CodePair] = []
        for (lrCode,shown) in self.mPhraseShownByLang {
            langShownPairs.append(CodePair(lrCode, shown))
        }
        into.addOption(tagValue: self.mTag, SVfileValue: self.mCodeForSVFile, langShownPairs: langShownPairs)
    }
}
