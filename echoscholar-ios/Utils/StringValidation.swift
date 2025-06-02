//
//  ValidationManager.swift
//  Lixor
//
//  Created by Bibin Joseph on 2025-04-29.
//

import Foundation

typealias ValidationResult = (result: Bool, errorMessage: String?)

struct StringValidation {
    fileprivate let action: (String) -> ValidationResult
    
    static func perform(validation: StringValidation, on string: String) -> ValidationResult {
        validation.action(string)
    }
}

extension StringValidation {
    static let email = StringValidation {
        let regex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let result = $0.range(of: regex, options: .regularExpression) != nil
        return (result, result ? nil : "Please enter a valid email address")
    }
    
    static let name = StringValidation {
        let regex = #"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$"#
        let result = $0.range(of: regex, options: .regularExpression) != nil && $0.count >= 2
        return (result, result ? nil : "Please enter a valid name")
    }
    
    static let notEmpty = StringValidation {
        let result = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (result, result ? nil : "This field is required")
    }
}

extension String {
    var validateEmail: ValidationResult {
        StringValidation.email.action(self)
    }
    
    var validateName: ValidationResult {
        StringValidation.name.action(self)
    }
    
    var validateNotEmpty: ValidationResult {
        StringValidation.notEmpty.action(self)
    }
}
