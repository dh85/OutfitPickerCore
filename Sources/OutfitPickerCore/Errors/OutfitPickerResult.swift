import Foundation

public enum OutfitPickerError: Error, LocalizedError, Equatable {
    case configurationNotFound
    case categoryNotFound
    case noOutfitsAvailable
    case fileSystemError
    case cacheError
    case invalidConfiguration
    case invalidInput(String)

    public var errorDescription: String? {
        switch self {
        case .configurationNotFound: "Configuration not found"
        case .categoryNotFound: "Category not found"
        case .noOutfitsAvailable: "No outfits available"
        case .fileSystemError: "File system error"
        case .cacheError: "Cache error"
        case .invalidConfiguration: "Invalid configuration"
        case .invalidInput(let message): "Invalid input: \(message)"
        }
    }
}

extension OutfitPickerError {
    public static func from(_ error: Error) -> OutfitPickerError {
        if let outfitError = error as? OutfitPickerError {
            return outfitError
        }
        if error is ConfigError {
            return .invalidConfiguration
        }
        if error is StorageError {
            return .cacheError
        }
        if error is FileSystemError {
            return .fileSystemError
        }
        if error is CacheError {
            return .cacheError
        }
        return .fileSystemError
    }
}

public typealias OutfitPickerResult<T> = Result<T, OutfitPickerError>
