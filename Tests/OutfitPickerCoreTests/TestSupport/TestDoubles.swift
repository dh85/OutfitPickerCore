import Foundation

@testable import OutfitPickerCore

struct FixedDirectoryProvider: DirectoryProvider {
    let url: URL
    func baseDirectory() throws -> URL { url }
}

struct ThrowingDirectoryProvider: DirectoryProvider {
    let error: Error
    init(_ error: Error = NSError(domain: "dir", code: 1, userInfo: nil)) {
        self.error = error
    }
    func baseDirectory() throws -> URL { throw error }
}

struct ThrowingDataManager: DataManagerProtocol {
    let error: Error = NSError(domain: "io", code: 5, userInfo: nil)
    func data(contentsOf url: URL) throws -> Data { Data() }
    func write(_ data: Data, to url: URL) throws { throw error }
}

struct ThrowingReadDataManager: DataManagerProtocol {
    let error: Error
    init(_ error: Error = NSError(domain: "io-read", code: 2, userInfo: nil)) {
        self.error = error
    }
    func data(contentsOf url: URL) throws -> Data { throw error }
    func write(_ data: Data, to url: URL) throws { try data.write(to: url) }
}

struct CorruptingDataManager: DataManagerProtocol {
    func data(contentsOf url: URL) throws -> Data { Data("not json".utf8) }
    func write(_ data: Data, to url: URL) throws { try data.write(to: url) }
}

final class RecordingDataManager: DataManagerProtocol {
    private(set) var lastWriteURL: URL?
    private(set) var lastData: Data?
    private(set) var lastReadURL: URL?

    func data(contentsOf url: URL) throws -> Data {
        lastReadURL = url
        return try Data(contentsOf: url)
    }
    func write(_ data: Data, to url: URL) throws {
        lastWriteURL = url
        lastData = data
        try data.write(to: url)
    }
}

final class FileManagerThrowingCreateDir: FileManagerProtocol,
    @unchecked Sendable
{
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] { [] }

    func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool {
        false
    }

    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        [URL(filePath: "/tmp", directoryHint: .isDirectory)]
    }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        // Force the failure path in FileService.save(...)
        throw NSError(domain: "mkdir", code: 13, userInfo: nil)
    }

    func removeItem(at url: URL) throws { /* no-op */  }
}
