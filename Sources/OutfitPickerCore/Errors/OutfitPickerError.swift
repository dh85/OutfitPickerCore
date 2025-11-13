import Foundation

public enum ConfigError: LocalizedError, Equatable {
    case emptyRoot
    case missingRoot
    case missingLanguage
    case unsupportedLanguage(String)
    case pathTraversalNotAllowed
    case pathTooLong
    case restrictedPath
    case symlinkNotAllowed
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

/// Errors that can occur during cache validation.
public enum CacheError: LocalizedError, Equatable {
    case pathNotFound
    case fileNotFound
    case encodingFailed
    case decodingFailed
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .pathNotFound: "cache directory not found"
        case .fileNotFound: "cache file not found"
        case .encodingFailed: "failed to encode cache data"
        case .decodingFailed: "failed to decode cache data"
        case .invalidData: "invalid cache data"
        }
    }
}

public enum StorageError: LocalizedError, Equatable {
    case fileNotFound
    case directoryNotFound
    case permissionDenied
    case diskFull
    case corruptedData

    public var errorDescription: String? {
        switch self {
        case .fileNotFound: "storage file not found"
        case .directoryNotFound: "storage directory not found"
        case .permissionDenied: "storage permission denied"
        case .diskFull: "storage disk full"
        case .corruptedData: "storage data corrupted"
        }
    }
}

public enum FileSystemError: LocalizedError, Equatable {
    case directoryNotFound
    case fileNotFound
    case permissionDenied
    case invalidPath
    case operationFailed

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound: "directory not found"
        case .fileNotFound: "file not found"
        case .permissionDenied: "file system permission denied"
        case .invalidPath: "invalid file system path"
        case .operationFailed: "file system operation failed"
        }
    }
}
