import Foundation

/// Protocol defining configuration persistence operations.
///
/// Provides methods for loading, saving, and managing outfit picker configuration files.
public protocol ConfigServiceProtocol: Sendable {
    func load() throws -> Config
    func save(_ config: Config) throws
    func delete() throws
    func configPath() throws -> URL
}

/// Service for managing outfit picker configuration persistence.
///
/// ConfigService handles reading and writing configuration files to the appropriate
/// platform-specific directory (Application Support on macOS, XDG config on Linux).
/// The service automatically creates necessary directories and formats JSON output.
///
/// Example:
/// ```swift
/// let service = ConfigService()
/// let config = try Config(root: "/path/to/outfits", language: "en")
/// try service.save(config)
/// let loaded = try service.load()
/// ```
public struct ConfigService: ConfigServiceProtocol, @unchecked Sendable {
    private let fileService: FileService<Config>

    /// Creates a new configuration service.
    /// - Parameter fileManager: File manager for filesystem operations. Defaults to `.default`
    public init(
        fileManager: any FileManagerProtocol = FileManager.default,
        dataManager: DataManagerProtocol = DefaultDataManager(),
        directoryProvider: DirectoryProvider = DefaultDirectoryProvider()
    ) {
        self.fileService = FileService(
            fileName: "config.json",
            fileManager: fileManager,
            dataManager: dataManager,
            directoryProvider: directoryProvider,
            errorMapper: { ConfigError.pathTraversalNotAllowed }
        )
    }

    /// Returns the full path to the configuration file.
    /// - Returns: URL pointing to the config.json file location
    /// - Throws: `ConfigError.pathTraversalNotAllowed` if no valid config directory found
    public func configPath() throws -> URL {
        try fileService.filePath()
    }

    /// Loads configuration from the filesystem.
    /// Returns: Decoded Config object
    /// Throws: File system errors or JSON decoding errors
    public func load() throws -> Config {
        guard let config = try fileService.load() else {
            throw OutfitPickerError.configurationNotFound
        }
        return config
    }

    /// Saves configuration to the filesystem.
    /// - Parameter config: Configuration object to persist
    /// - Throws: File system errors or JSON encoding errors
    public func save(_ config: Config) throws {
        try fileService.save(config)
    }

    /// Deletes the configuration file from the filesystem.
    /// - Throws: File system errors if deletion fails
    public func delete() throws {
        try fileService.delete()
    }
}
