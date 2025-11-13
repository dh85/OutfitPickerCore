import Foundation

/// Represents a category of outfit files organized in a directory.
///
/// Categories group related outfit items together (e.g., "casual", "formal", "summer").
/// Each category contains a collection of outfit files and provides the category name
/// derived from the directory path.
///
/// Example:
/// ```swift
/// let casual = Category(
///     path: "/Users/john/outfits/casual",
///     outfits: ["outfit1.avatar", "outfit2.avatar", "outfit3.avatar"]
/// )
/// print(casual.name) // "casual"
/// ```
public struct Category: Sendable, Equatable {
    /// Full filesystem path to the category directory
    public let path: String
    /// Array of outfits within this category
    public let outfits: [String]

    private let _url: URL

    public init(path: String, outfits: [String]) {
        self.path = path
        self.outfits = outfits
        self._url = URL(filePath: path, directoryHint: .isDirectory)
    }

    /// The category name extracted from the directory path
    public var name: String {
        _url.lastPathComponent
    }
}

/// Represents an individual outfit file with its context information.
///
/// FileEntry provides complete information about a single outfit item,
/// with the category path and filename derived from the full file path.
///
/// Example:
/// ```swift
/// let outfit1 = FileEntry(filePath: "/Users/john/outfits/casual/outfit1.avatar")
/// print(outfit1.fileName) // "outfit1.avatar"
/// print(outfit1.categoryPath) // "/Users/john/outfits/casual"
/// ```
public struct FileEntry: Equatable, Sendable {
    /// Complete path to the specific outfit file
    public let filePath: String
    /// Filename without path information
    public let fileName: String

    private let _url: URL
    private let _categoryURL: URL

    public init(filePath: String) {
        self.filePath = filePath
        self._url = URL(filePath: filePath, directoryHint: .notDirectory)
        self.fileName = _url.lastPathComponent
        self._categoryURL = _url.deletingLastPathComponent()
    }

    /// Path to the parent category directory
    public var categoryPath: String {
        _categoryURL.path(percentEncoded: false)
    }

    /// Category name derived from the parent directory
    public var categoryName: String {
        _categoryURL.lastPathComponent
    }
}
