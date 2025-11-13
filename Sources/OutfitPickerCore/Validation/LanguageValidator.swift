import Foundation

/// Validates language codes against a predefined set of supported languages.
///
/// This validator ensures that only supported language codes are accepted in the configuration.
/// It supports 51 languages covering major world languages and regional variants.
///
/// ## Usage Example
/// ```swift
/// // Valid language codes
/// try LanguageValidator.validate("en")  // English - passes
/// try LanguageValidator.validate("es")  // Spanish - passes
/// try LanguageValidator.validate(nil)   // nil - passes (optional)
///
/// // Invalid language code
/// try LanguageValidator.validate("xyz") // Throws ConfigError.unsupportedLanguage
/// ```
struct LanguageValidator {
    /// Set of supported ISO 639-1 language codes.
    ///
    /// Includes 51 languages covering:
    /// - Major European languages (en, es, fr, de, it, pt, nl, ru, etc.)
    /// - Asian languages (ja, zh, ko, hi, th, vi, etc.)
    /// - Middle Eastern languages (ar, he, ur, etc.)
    /// - African languages (sw, am, yo, zu, af)
    /// - Regional and minority languages
    private static let supportedLanguages: Set<String> = [
        "en", "es", "fr", "de", "it", "pt", "nl", "ru", "ja", "zh", "ko",
        "ar", "hi", "no", "sv", "fi", "da", "pl", "hu", "hr", "sr", "ro",
        "el", "tr", "bg", "lt", "lv", "et", "is", "mt", "ca", "uk", "sk",
        "cs", "sl", "bn", "vi", "th", "he", "id", "ms", "ta", "te", "gu",
        "pa", "ur", "sw", "am", "yo", "zu", "af",
    ]

    /// Validates that a language code is supported.
    ///
    /// - Parameter language: The language code to validate (optional)
    /// - Throws: `ConfigError.unsupportedLanguage` if the language code is not supported
    /// - Note: nil values are considered valid (language is optional in configuration)
    static func validate(_ language: String?) throws {
        if let language, !supportedLanguages.contains(language) {
            throw ConfigError.unsupportedLanguage(language)
        }
    }

    // MARK: - Internal Access for Testing

    /// Returns whether a language code is supported.
    ///
    /// - Parameter language: The language code to check
    /// - Returns: true if the language is supported, false otherwise
    /// - Note: This method is primarily for testing purposes
    static func isSupported(_ language: String) -> Bool {
        return supportedLanguages.contains(language)
    }

    /// Returns the complete set of supported language codes.
    ///
    /// - Returns: A set containing all supported ISO 639-1 language codes
    /// - Note: This method is primarily for testing and introspection purposes
    static var allSupportedLanguages: Set<String> {
        return supportedLanguages
    }
}
