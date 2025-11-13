import Foundation
import OutfitPickerCore

// MARK: - Directory Providers

public struct FixedDirectoryProvider: DirectoryProvider {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func baseDirectory() throws -> URL { url }
}

public struct ThrowingDirectoryProvider: DirectoryProvider {
    public let error: Error
    public init(_ error: Error = NSError(domain: "dir", code: 1, userInfo: nil)) {
        self.error = error
    }
    public func baseDirectory() throws -> URL { throw error }
}

// MARK: - Data Managers

public struct ThrowingDataManager: DataManagerProtocol, @unchecked Sendable {
    public let error: Error
    public init(_ error: Error = NSError(domain: "io", code: 5, userInfo: nil)) {
        self.error = error
    }
    public func data(contentsOf url: URL) throws -> Data { Data() }
    public func write(_ data: Data, to url: URL) throws { throw error }
}

public struct ThrowingReadDataManager: DataManagerProtocol, @unchecked Sendable {
    public let error: Error
    public init(_ error: Error = NSError(domain: "io-read", code: 2, userInfo: nil)) {
        self.error = error
    }
    public func data(contentsOf url: URL) throws -> Data { throw error }
    public func write(_ data: Data, to url: URL) throws { try data.write(to: url) }
}

public struct CorruptingDataManager: DataManagerProtocol, @unchecked Sendable {
    public init() {}
    public func data(contentsOf url: URL) throws -> Data { Data("not json".utf8) }
    public func write(_ data: Data, to url: URL) throws { try data.write(to: url) }
}

public final class RecordingDataManager: DataManagerProtocol, @unchecked Sendable {
    public private(set) var lastWriteURL: URL?
    public private(set) var lastData: Data?
    public private(set) var lastReadURL: URL?

    public init() {}

    public func data(contentsOf url: URL) throws -> Data {
        lastReadURL = url
        return try Data(contentsOf: url)
    }

    public func write(_ data: Data, to url: URL) throws {
        lastWriteURL = url
        lastData = data
        try data.write(to: url)
    }
}

// MARK: - File Manager that throws on createDirectory

public final class FileManagerThrowingCreateDir: FileManagerProtocol, @unchecked Sendable {
    public init() {}

    public func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] { [] }

    public func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool {
        false
    }

    public func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        [URL(filePath: "/tmp", directoryHint: .isDirectory)]
    }

    public func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        // Force the failure path in FileService.save(...)
        throw NSError(domain: "mkdir", code: 13, userInfo: nil)
    }

    public func removeItem(at url: URL) throws { /* no-op */ }
}
