//
//  RuleValidChars.swift
//  Eureka
//
//  Created by Dev on 1/9/19.
//

public struct RuleValidChars: RuleType {
    
    public var id: String?
    public var validationError: ValidationError
    private var acceptableChars:NSCharacterSet
    
    public init(acceptableChars: NSCharacterSet, msg: String? = nil, id: String? = nil) {
        let ruleMsg = msg ?? "One or more characters are invalid"
        self.acceptableChars = acceptableChars
        self.validationError = ValidationError(msg: ruleMsg)
        self.id = id
    }
    
    public func isValid(value: String?) -> ValidationError? {
        guard let value = value else { return nil }
        if value.rangeOfCharacter(from: self.acceptableChars.inverted) != nil { return validationError }
        return nil
    }
}
