import Foundation

/// Protocol for data I/O operations.
///
/// Abstracts file reading and writing operations for testability.
public protocol DataManagerProtocol {
    /// Reads data from a file URL
    func data(contentsOf url: URL) throws -> Data
    /// Writes data to a file URL
    func write(_ data: Data, to url: URL) throws
}

/// Default implementation of DataManagerProtocol using Foundation APIs.
public struct DefaultDataManager: DataManagerProtocol {
    public init() {}

    public func data(contentsOf url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}

/// Protocol for providing platform-specific directories.
///
/// Abstracts directory resolution for cross-platform compatibility.
public protocol DirectoryProvider {
    /// Returns the base directory for application data
    func baseDirectory() throws -> URL
}

/// Default implementation providing platform-appropriate directories.
///
/// Uses XDG_CONFIG_HOME on Linux, Application Support on macOS.
public struct DefaultDirectoryProvider: DirectoryProvider {
    private let fileManager: any FileManagerProtocol

    public init(fileManager: any FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    public func baseDirectory() throws -> URL {
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            return URL(filePath: xdg, directoryHint: .isDirectory)
        }
        guard
            let appSup = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else { throw OutfitPickerError.invalidConfiguration }
        return appSup
    }
}

/// Generic file service for JSON persistence operations.
///
/// Provides type-safe loading, saving, and deletion of Codable objects
/// with configurable dependencies for testing and platform compatibility.
///
/// Example:
/// ```swift
/// let service = FileService<Config>(fileName: "config.json")
/// try service.save(myConfig)
/// let loaded = try service.load()
/// ```
public struct FileService<T: Codable>: @unchecked Sendable {
    private let fileManager: any FileManagerProtocol
    private let dataManager: DataManagerProtocol
    private let directoryProvider: DirectoryProvider
    private let fileName: String
    private let appName = "outfitpicker"
    private let errorMapper: @Sendable () -> Error

    /// Creates a new file service with configurable dependencies.
    /// - Parameters:
    ///   - fileName: Name of the file to manage
    ///   - fileManager: File manager for filesystem operations
    ///   - dataManager: Data manager for I/O operations
    ///   - directoryProvider: Provider for application directories
    ///   - errorMapper: Function to map directory errors to appropriate types
    public init(
        fileName: String,
        fileManager: any FileManagerProtocol = FileManager.default,
        dataManager: DataManagerProtocol = DefaultDataManager(),
        directoryProvider: DirectoryProvider = DefaultDirectoryProvider(),
        errorMapper: @escaping @Sendable () -> Error = {
            OutfitPickerError.invalidConfiguration
        }
    ) {
        self.fileName = fileName
        self.fileManager = fileManager
        self.dataManager = dataManager
        self.directoryProvider = directoryProvider
        self.errorMapper = errorMapper
    }

    /// Returns the full path to the managed file.
    /// - Returns: URL pointing to the file location
    /// - Throws: Mapped error if directory resolution fails
    public func filePath() throws -> URL {
        do {
            return try directoryProvider.baseDirectory()
                .appending(path: appName, directoryHint: .isDirectory)
                .appending(path: fileName, directoryHint: .notDirectory)
        } catch {
            throw errorMapper()
        }
    }

    /// Loads and decodes an object from the file.
    /// - Returns: Decoded object, or nil if file doesn't exist
    /// - Throws: File system or JSON decoding errors
    public func load() throws -> T? {
        let url = try filePath()
        guard
            fileManager.fileExists(
                atPath: url.path(percentEncoded: false),
                isDirectory: nil
            )
        else {
            return nil
        }
        let data = try dataManager.data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Encodes and saves an object to the file.
    /// - Parameter object: Object to encode and save
    /// - Throws: File system or JSON encoding errors
    public func save(_ object: T) throws {
        let url = try filePath()
        try ensureDirectoryExists(at: url.deletingLastPathComponent())

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(object)
        try dataManager.write(data, to: url)
    }

    /// Deletes the file if it exists.
    /// - Throws: File system errors if deletion fails
    public func delete() throws {
        let url = try filePath()
        if fileManager.fileExists(
            atPath: url.path(percentEncoded: false),
            isDirectory: nil
        ) {
            try fileManager.removeItem(at: url)
        }
    }

    private func ensureDirectoryExists(at url: URL) throws {
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
