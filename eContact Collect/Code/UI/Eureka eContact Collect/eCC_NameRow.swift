//
//  eCC_NameRow.swift
//  eContact Collect
//
//  Created by Yo on 10/16/18.
//

// eContactsCollect NameRow custom class to add capability to aggregate name components into a hidden full-name row
public final class ECC_NameRow: _NameRow, RowType {
    private let cTAG:String = "EuRN"
    public var vCard_Subproperty_No:Int = 0
    public weak var eccHiddenFullNameRow:ECC_HiddenFullNameRow? = nil
    
    required public init(tag: String?) {
        super.init(tag: tag)
        
        self.onChange { chgRow in
            // Row's value has changed; post the new value to the hidden full name row
//debugPrint("\(self.cTAG).onChange STARTED")
            if chgRow.eccHiddenFullNameRow != nil && chgRow.value != nil {
                chgRow.eccHiddenFullNameRow!.postNameComponent(chgRow.value!, vCard_subpropertyNo: chgRow.vCard_Subproperty_No)
            }
        }
    }
}

// eContactsCollect NameRow custom class to aggregate a full-name from individual name components in separate Eureka Rows
public final class ECC_HiddenFullNameRow: _NameRow, RowType {
    private let cCTAG:String = "EuRHFN"
    public struct NameComponentsInfo {
        public var nameHonorPrefix:String
        public var nameFirst:String
        public var nameLast:String
        public var nameFull:String
    }
    var nameComponents:NameComponentsInfo = NameComponentsInfo(nameHonorPrefix: "", nameFirst:"", nameLast:"", nameFull:"")
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
    
    // accept a name component from a ECC_NameRow instance
    public func postNameComponent(_ nameComponent:String, vCard_subpropertyNo:Int) {
//debugPrint("\(self.cTAG).postNameComponent \(vCard_subpropertyNo) = \(nameComponent)")
        switch vCard_subpropertyNo {
        case 4:
            // honorific prefix
            self.nameComponents.nameHonorPrefix = nameComponent
            break
        case 2:
            // first or given name
            self.nameComponents.nameFirst = nameComponent
            self.makeFullName()
            break
        case 1:
            // last or family name
            self.nameComponents.nameLast = nameComponent
            self.makeFullName()
            break
        case -1:
            // full-name
            self.nameComponents.nameFull = nameComponent
            self.value = nameComponent
            self.updateCell()
            break
        default:
            break
        }
    }
    
    // update the hidden row's value from the submitted name components
    private func makeFullName() {
        self.nameComponents.nameFull = ""
        if !(self.nameComponents.nameHonorPrefix.isEmpty) {
            self.nameComponents.nameFull  = self.nameComponents.nameFull + self.nameComponents.nameHonorPrefix + " "
        }
        if !(self.nameComponents.nameFirst.isEmpty) {
            self.nameComponents.nameFull  = self.nameComponents.nameFull + self.nameComponents.nameFirst + " "
        }
        if !(self.nameComponents.nameLast.isEmpty) {
            self.nameComponents.nameFull  = self.nameComponents.nameFull + self.nameComponents.nameLast + " "
        }
        self.value = self.nameComponents.nameFull
        self.updateCell()
    }
}
