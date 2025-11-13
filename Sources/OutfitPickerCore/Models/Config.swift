import Foundation

/// Configuration for outfit picker application.
///
/// Stores the root directory path for outfit files and optional language preference.
/// Configurations are automatically validated during creation to ensure security.
///
/// Example:
/// ```swift
/// let config = try Config(root: "/Users/john/outfits", language: "en")
/// ```
public struct Config: Codable, Sendable, Equatable {
    /// Root directory path containing outfit files
    public let root: String
    /// Optional language code (e.g., "en", "es", "fr")
    public let language: String?
    public let excludedCategories: Set<String>
    public let knownCategories: Set<String>
    public let knownCategoryFiles: [String: Set<String>]

    /// Creates and validates a new configuration.
    ///
    /// Performs comprehensive validation including:
    /// - Path security checks (traversal, restricted directories, symlinks
    /// - Language code validation
    /// - Input sanitization
    ///
    /// - Parameters:
    ///     - root: Path to the root directory containing outfit files
    ///     - language: Optional ISO 639-1 language code
    /// - Throws: `ConfigError` if validation fails
    public init(
        root: String,
        language: String? = nil,
        excludedCategories: Set<String> = [],
        knownCategories: Set<String> = [],
        knownCategoryFiles: [String: Set<String>] = [:]
    ) throws {
        guard !root.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw ConfigError.emptyRoot
        }

        try PathValidator.validate(root)
        try LanguageValidator.validate(language)

        self.root = root
        self.language = language ?? "en"
        self.excludedCategories = excludedCategories
        self.knownCategories = knownCategories
        self.knownCategoryFiles = knownCategoryFiles
    }
}
