import Foundation

/// Represents a category of outfit files organized in a directory.
///
/// Categories group related outfit items together (e.g., "casual", "formal", "summer").
/// Each category contains a collection of outfit files and provides the category name
/// derived from the directory path.
///
/// Example:
/// ```swift
/// let causal = Category(
///     path: "/Users/john/outfits/casual",
///     files: ["outfit1.avatar", "outfit2.avatar", "outfit3.avatar"]
/// )
/// print(casual.name) // "casual"
/// ```
public struct Category: Sendable {
    /// Full filesystem path to the category directory
    public let path: String
    /// Array of outfits within this category
    public let outfits: [String]

    /// The category name extracted from the directory path
    public var name: String {
        URL(filePath: path, directoryHint: .isDirectory).lastPathComponent
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
public struct FileEntry {
    /// Complete path to the specific outfit file
    public let filePath: String
    /// Filename without path information
    public let fileName: String

    public init(filePath: String) {
        self.filePath = filePath
        self.fileName =
            URL(filePath: filePath, directoryHint: .notDirectory)
            .lastPathComponent
    }

    /// Path to the parent category directory
    public var categoryPath: String {
        URL(filePath: filePath, directoryHint: .notDirectory)
            .deletingLastPathComponent().path(percentEncoded: false)
    }

    /// Category name derived from the parent directory
    public var categoryName: String {
        URL(filePath: categoryPath, directoryHint: .isDirectory)
            .lastPathComponent
    }
}
