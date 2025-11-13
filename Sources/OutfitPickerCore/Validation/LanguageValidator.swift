import Foundation

struct LanguageValidator {
    private static let supportedLanguages: Set<String> = [
        "en", "es", "fr", "de", "it", "pt", "nl", "ru", "ja", "zh", "ko",
        "ar", "hi", "no", "sv", "fi", "da", "pl", "hu", "hr", "sr", "ro",
        "el", "tr", "bg", "lt", "lv", "et", "is", "mt", "ca", "uk", "sk",
        "cs", "sl", "bn", "vi", "th", "he", "id", "ms", "ta", "te", "gu",
        "pa", "ur", "sw", "am", "yo", "zu", "af",
    ]

    static func validate(_ language: String?) throws {
        if let language, !supportedLanguages.contains(language) {
            throw ConfigError.unsupportedLanguage(language)
        }
    }
}
