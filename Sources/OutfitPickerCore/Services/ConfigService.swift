import Foundation

/// Protocol defining configuration persistence operations.
///
/// Provides methods for loading, saving, and managing outfit picker configuration files.
/// All methods throw OutfitPickerError for consistent error handling.
public protocol ConfigServiceProtocol: Sendable {
    /// Loads configuration from persistent storage
    func load() throws -> Config
    /// Saves configuration to persistent storage
    func save(_ config: Config) throws
    /// Deletes configuration from persistent storage
    func delete() throws
    /// Returns the path to the configuration file
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

    /// Creates a new configuration service with configurable dependencies.
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
            fileName: "config.json",
            fileManager: fileManager,
            dataManager: dataManager,
            directoryProvider: directoryProvider,
            errorMapper: { ConfigError.pathTraversalNotAllowed }
        )
    }

    /// Returns the full path to the configuration file.
    /// - Returns: URL pointing to the config.json file location
    /// - Throws: `OutfitPickerError` if no valid config directory found
    public func configPath() throws -> URL {
        do {
            return try fileService.filePath()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    /// Loads configuration from the filesystem.
    /// - Returns: Decoded Config object
    /// - Throws: `OutfitPickerError.configurationNotFound` if file doesn't exist, or JSON decoding errors
    public func load() throws -> Config {
        do {
            guard let config = try fileService.load() else {
                throw OutfitPickerError.configurationNotFound
            }
            return config
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    /// Saves configuration to the filesystem.
    /// - Parameter config: Configuration object to persist
    /// - Throws: `OutfitPickerError` for any save failures
    public func save(_ config: Config) throws {
        do {
            try fileService.save(config)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    /// Deletes the configuration file from the filesystem.
    /// - Throws: `OutfitPickerError` if deletion fails
    public func delete() throws {
        do {
            try fileService.delete()
        } catch {
            throw OutfitPickerError.from(error)
        }
    }
}
