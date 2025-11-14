import Foundation

/// Protocol for cache persistence operations.
///
/// Defines the interface for loading, saving, and managing outfit cache data.
/// All methods throw OutfitPickerError for consistent error handling.
public protocol CacheServiceProtocol: Sendable {
    /// Loads cache from persistent storage
    func load() throws -> OutfitCache
    /// Saves cache to persistent storage
    func save(_ cache: OutfitCache) throws
    /// Deletes cache from persistent storage
    func delete() throws
    /// Returns the path to the cache file
    func cachePath() throws -> URL
}

/// Service for managing outfit picker cache persistence.
///
/// CacheService handles reading and writing rotation state to track which outfits
/// have been shown in each category. Cache is stored in the application support directory.
///
/// Example:
/// ```swift
/// let service = CacheService()
/// let cache = OutfitCache(categories: ["casual": CategoryCache(totalOutfits: 10)])
/// try service.save(cache)
/// let loaded = try service.load()
/// ```
public struct CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let fileService: FileService<OutfitCache>

    /// Creates a new cache service with configurable dependencies.
    /// - Parameters:
    ///   - fileManager: File manager for filesystem operations
    ///   - dataManager: Data manager for encoding/decoding operations
    ///   - directoryProvider: Provider for application directories
    public init(
        fileManager: any FileManagerProtocol = FileManager.default,
        dataManager: DataManagerProtocol = DefaultDataManager(),
        directoryProvider: DirectoryProvider = DefaultDirectoryProvider()
    ) {
        self.fileService = FileService(
            fileName: "cache.json",
            fileManager: fileManager,
            dataManager: dataManager,
            directoryProvider: directoryProvider,
            errorMapper: { FileSystemError.directoryNotFound }
        )
    }

    /// Returns the full path to the cache file.
    /// - Returns: URL pointing to the cache.json file location
    /// - Throws: `OutfitPickerError` if no valid cache directory found
    public func cachePath() throws -> URL {
        do {
            return try fileService.filePath()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    /// Loads cache from the filesystem.
    /// - Returns: Decoded OutfitCache object, or empty cache if file doesn't exist
    /// - Throws: `OutfitPickerError` for any load failures
    public func load() throws -> OutfitCache {
        do {
            return try fileService.load() ?? OutfitCache()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    /// Saves cache to the filesystem.
    /// - Parameter cache: Cache object to persist
    /// - Throws: `OutfitPickerError` for any save failures
    public func save(_ cache: OutfitCache) throws {
        do {
            try fileService.save(cache)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    /// Deletes the cache file from the filesystem.
    /// - Throws: `OutfitPickerError` if deletion fails
    public func delete() throws {
        do {
            try fileService.delete()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }
}
