import Foundation

/// Protocol for cache persistence operations.
///
/// Defines the interface for loading, saving, and managing outfit cache data.
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
    /// - Throws: `FileSystemError` if no valid cache directory found
    public func cachePath() throws -> URL {
        try fileService.filePath()
    }

    /// Loads cache from the filesystem.
    /// - Returns: Decoded OutfitCache object, or empty cache if file doesn't exist
    /// - Throws: `FileSystemError` or JSON decoding errors
    public func load() throws -> OutfitCache {
        try fileService.load() ?? OutfitCache()
    }

    /// Saves cache to the filesystem.
    /// - Parameter cache: Cache object to persist
    /// - Throws: `FileSystemError` or JSON encoding errors
    public func save(_ cache: OutfitCache) throws {
        try fileService.save(cache)
    }

    /// Deletes the cache file from the filesystem.
    /// - Throws: `FileSystemError` if deletion fails
    public func delete() throws {
        try fileService.delete()
    }
}
