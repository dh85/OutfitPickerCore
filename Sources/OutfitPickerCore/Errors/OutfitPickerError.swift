import Foundation

/// Configuration validation errors.
///
/// These errors occur when validating outfit picker configuration settings,
/// particularly around root paths and language settings.
public enum ConfigError: LocalizedError, Equatable {
    /// Root path is empty or contains only whitespace.
    case emptyRoot
    /// Required root path is missing from configuration.
    case missingRoot
    /// Language setting is missing from configuration.
    case missingLanguage
    /// Specified language is not supported.
    case unsupportedLanguage(String)
    /// Path contains ".." or other traversal attempts.
    case pathTraversalNotAllowed
    /// Path exceeds maximum allowed length (4096 characters).
    case pathTooLong
    /// Path points to a restricted system directory.
    case restrictedPath
    /// Symbolic links are not allowed in paths.
    case symlinkNotAllowed
    /// Path contains invalid or control characters.
    case invalidCharacters

    public var errorDescription: String? {
        switch self {
        case .emptyRoot: "empty root in configuration"
        case .missingRoot: "missing root in configuration"
        case .missingLanguage: "missing language in configuration"
        case .unsupportedLanguage(let lang): "unsupported language: \(lang)"
        case .pathTraversalNotAllowed: "path traversal not allowed"
        case .pathTooLong: "path too long"
        case .restrictedPath: "restricted path"
        case .symlinkNotAllowed: "symlink not allowed"
        case .invalidCharacters: "invalid characters"
        }
    }
}

/// File system operation errors.
///
/// These errors occur during file and directory operations such as
/// reading outfit files, creating cache directories, or accessing configuration.
public enum FileSystemError: LocalizedError, Equatable {
    /// Requested file does not exist.
    case fileNotFound
    /// Requested directory does not exist.
    case directoryNotFound
    /// Insufficient permissions to access file or directory.
    case permissionDenied
    /// Path format is invalid or malformed.
    case invalidPath
    /// File system operation failed for unknown reasons.
    case operationFailed

    public var errorDescription: String? {
        switch self {
        case .fileNotFound: "file not found"
        case .directoryNotFound: "directory not found"
        case .permissionDenied: "permission denied"
        case .invalidPath: "invalid path"
        case .operationFailed: "operation failed"
        }
    }
}

/// Cache data processing errors.
///
/// These errors occur when reading or writing outfit rotation cache data,
/// typically involving JSON serialization issues.
public enum CacheError: LocalizedError, Equatable {
    /// Failed to encode cache data to JSON format.
    case encodingFailed
    /// Failed to decode JSON data to cache structure.
    case decodingFailed
    /// Cache data is corrupted or in unexpected format.
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .encodingFailed: "failed to encode cache data"
        case .decodingFailed: "failed to decode cache data"
        case .invalidData: "invalid cache data"
        }
    }
}

/// Storage device and data integrity errors.
///
/// These errors occur when there are hardware or storage-level issues
/// that prevent successful file operations.
public enum StorageError: LocalizedError, Equatable {
    /// Insufficient disk space to complete operation.
    case diskFull
    /// Stored data is corrupted or unreadable.
    case corruptedData

    public var errorDescription: String? {
        switch self {
        case .diskFull: "disk full"
        case .corruptedData: "data corrupted"
        }
    }
}
