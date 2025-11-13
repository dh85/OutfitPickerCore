import Foundation

public enum SupportedLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"

    public var code: String { rawValue }
}

public final class ConfigBuilder: @unchecked Sendable {
    private var rootPath: String?
    private var language: SupportedLanguage = .english
    private var excludedCategories = Set<String>()
    private var knownCategories = Set<String>()

    public init() {}

    // MARK: - Fluent setters

    @discardableResult
    public func rootDirectory(_ path: String) -> Self {
        self.rootPath = path
        return self
    }

    @discardableResult
    public func language(_ language: SupportedLanguage) -> Self {
        self.language = language
        return self
    }

    // MARK: Exclude APIs

    @discardableResult
    public func exclude(categories: Set<String>) -> Self {
        self.excludedCategories.formUnion(categories)
        return self
    }

    @discardableResult
    public func exclude(category: String) -> Self {
        self.excludedCategories.insert(category)
        return self
    }

    /// Convenience: variadic exclude
    @discardableResult
    public func exclude(_ categories: String...) -> Self {
        let cleaned = categories.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        self.excludedCategories.formUnion(cleaned.filter { !$0.isEmpty })
        return self
    }

    // MARK: Include / Known APIs

    /// Accepts a dictionary of category -> state, storing only the names.
    @discardableResult
    public func knownCategories(_ categories: [String: CategoryState]) -> Self {
        self.knownCategories = Set(categories.keys)
        return self
    }

    /// Generic sequence overload for ergonomics (arrays, sets, lazy maps, etc.)
    @discardableResult
    public func knownCategories<S: Sequence>(_ categories: S) -> Self
    where S.Element == String {
        self.knownCategories = Set(categories)
        return self
    }

    @discardableResult
    public func include(categories: Set<String>) -> Self {
        self.knownCategories.formUnion(categories)
        return self
    }

    @discardableResult
    public func include(category: String) -> Self {
        self.knownCategories.insert(category)
        return self
    }

    /// Convenience: variadic include
    @discardableResult
    public func include(_ categories: String...) -> Self {
        self.knownCategories.formUnion(categories)
        return self
    }

    // MARK: - Build

    public func build() throws -> Config {
        guard let rootPath else {
            throw ConfigError.missingRoot
        }

        return try Config(
            root: rootPath,
            language: language.code,
            excludedCategories: excludedCategories,
            knownCategories: knownCategories
        )
    }
}
