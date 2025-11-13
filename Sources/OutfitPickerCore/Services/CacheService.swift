import Foundation

public protocol CacheServiceProtocol: Sendable {
    func load() throws -> OutfitCache
    func save(_ cache: OutfitCache) throws
    func delete() throws
    func cachePath() throws -> URL
}

/// Service for managing outfit picker cache persistence.
///
/// CacheService handles reading and writing rotation state to track which outfits
/// have been shown in each category. Cache is stored in the same directory as config.
///
/// Example:
/// ```swift
/// let service = CacheService()
/// let cache = OutfitCache(categories: ["casual": CategoryCache(totalFiles: 10)])
/// try service.save(cache)
/// let loaded = try await service.load()
/// ```
public struct CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let fileService: FileService<OutfitCache>

    /// Creates a new cache service.
    /// - Parameter fileManager: File manager for filesystem operations. Defaults to `.default`.
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
            errorMapper: { CacheError.pathNotFound }
        )
    }

    /// Returns the full path to the cache file.
    /// - Returns: URL pointing to the cache.json file location
    /// - Throws: `CacheError.pathNotFound` if no valid cache directory found
    public func cachePath() throws -> URL {
        try fileService.filePath()
    }

    /// Loads cache from the filesystem.
    /// - Returns: Decoded OutfitCache object, or empty cache if file doesn't exist
    /// - Throws: JSON decoding errors
    public func load() throws -> OutfitCache {
        try fileService.load() ?? OutfitCache()
    }

    /// Saves cache to the filesystem.
    /// - Parameter cache: Cache object to persist
    /// - Throws: File system errors or JSON encoding errors
    public func save(_ cache: OutfitCache) throws {
        try fileService.save(cache)
    }

    /// Deletes the cache file from the filesystem.
    /// Throws: File stem errors if deletion fails
    public func delete() throws {
        try fileService.delete()
    }
}
