import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

private struct TestModel: Codable, Equatable {
    var id: Int
    var name: String
}
private enum DummyError: Error { case mapped }

struct FileServiceTests {

    @Test func loadReturnsNilWhenMissing() throws {
        let sut = makeTestSUT(fileName: "missing.json")
        let m: TestModel? = try sut.load()
        #expect(m == nil)
    }

    @Test func loadThrowsWhenReadFailsBeforeDecode() throws {
        let (sut, _) = try makeTestSUTWithFile(
            fileName: "readfail.json",
            dataManager: ThrowingReadDataManager()
        )

        #expect(throws: Error.self) { let _: TestModel? = try sut.load() }
    }

    @Test func loadThrowsOnCorruptJSON() throws {
        let (sut, _) = try makeTestSUTWithFile(
            fileName: "bad.json",
            dataManager: CorruptingDataManager()
        )

        #expect(throws: DecodingError.self) {
            let _: TestModel? = try sut.load()
        }
    }

    @Test func saveCreatesDirAndWrites() throws {
        let recorder = RecordingDataManager()
        let sut = makeTestSUT(fileName: "model.json", dataManager: recorder)

        try sut.save(sampleModel())

        let p = try sut.filePath()
        #expect(fileExists(p))
        #expect(recorder.lastWriteURL?.lastPathComponent == "model.json")
    }

    @Test func savePropagatesCreateDirectoryFailure() {
        let sut = makeTestSUT(
            fileName: "failmkdir.json",
            fileManager: FileManagerThrowingCreateDir()
        )

        #expect(throws: Error.self) {
            try sut.save(sampleModel())
        }
    }

    @Test func saveMapsErrorWhenDirectoryProviderFails() {
        let sut = makeTestSUTWithThrowingProvider(errorMapper: { DummyError.mapped })

        #expect(throws: DummyError.mapped) {
            try sut.save(sampleModel())
        }
    }

    @Test func filePathMapsError() {
        let sut = makeTestSUTWithThrowingProvider(errorMapper: { DummyError.mapped })
        #expect(throws: DummyError.mapped) { _ = try sut.filePath() }
    }

    @Test func deleteIsNoOpWhenMissing() throws {
        let sut = makeTestSUT(fileName: "gone.json")
        try sut.delete()  // no throw
        let p = try sut.filePath()
        #expect(!fileExists(p))
    }

    @Test func deleteRemovesWhenPresent() throws {
        let sut = makeTestSUT(fileName: "del.json")

        try sut.save(sampleModel())
        let p = try sut.filePath()
        #expect(fileExists(p))

        try sut.delete()
        #expect(!fileExists(p))
    }

    @Test func deleteMapsErrorWhenDirectoryProviderFails() {
        let sut = makeTestSUTWithThrowingProvider(errorMapper: { DummyError.mapped })
        #expect(throws: DummyError.mapped) { try sut.delete() }
    }

    @Test("baseDirectory uses XDG_CONFIG_HOME when set")
    func usesXDGConfigHomeWhenSet() throws {
        // Save and override env
        let old = getenv("XDG_CONFIG_HOME").map { String(cString: $0) }
        let tempXDG = "/tmp/xdg-config-\(UUID().uuidString)"
        setenv("XDG_CONFIG_HOME", tempXDG, 1)
        defer {
            // Restore previous value
            if let old {
                setenv("XDG_CONFIG_HOME", old, 1)
            } else {
                unsetenv("XDG_CONFIG_HOME")
            }
        }

        // FileManager won't be used in this branch, so use the real one
        let provider = DefaultDirectoryProvider(
            fileManager: FileManager.default
        )
        let base = try provider.baseDirectory()

        #expect(normPath(base.path(percentEncoded: false)) == tempXDG)
    }

    @Test("baseDirectory falls back to Application Support when XDG is not set")
    func usesApplicationSupportWhenXDGNotSet() throws {
        let old = getenv("XDG_CONFIG_HOME").map { String(cString: $0) }
        unsetenv("XDG_CONFIG_HOME")
        defer {
            if let old {
                setenv("XDG_CONFIG_HOME", old, 1)
            } else {
                unsetenv("XDG_CONFIG_HOME")
            }
        }

        let expectedAppSup = URL(
            filePath: "/tmp/app-support-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )

        let fakeFM = FakeFileManagerForAppSup(appSupportURL: expectedAppSup)
        let provider = DefaultDirectoryProvider(fileManager: fakeFM)

        let base = try provider.baseDirectory()

        #expect(base == expectedAppSup)
    }

    @Test("baseDirectory throws when Application Support is unavailable")
    func baseDirectoryThrowsWhenAppSupportMissing() {
        // Ensure we do NOT take the XDG_CONFIG_HOME branch
        let old = getenv("XDG_CONFIG_HOME").map { String(cString: $0) }
        unsetenv("XDG_CONFIG_HOME")
        defer {
            if let old {
                setenv("XDG_CONFIG_HOME", old, 1)
            } else {
                unsetenv("XDG_CONFIG_HOME")
            }
        }

        let fm = FakeFileManagerNoAppSupport()
        let provider = DefaultDirectoryProvider(fileManager: fm)

        #expect(throws: OutfitPickerError.invalidConfiguration) {
            _ = try provider.baseDirectory()
        }
    }

    @Test(
        "FileService uses its own default errorMapper when DirectoryProvider fails"
    )
    func fileServiceInitDefaultErrorMapperIsUsed() {
        let failingProvider = ThrowingDirectoryProvider(
            NSError(domain: "dir", code: 9, userInfo: nil)
        )

        // NOTE: no `errorMapper:` argument here → this is where the default
        // in FileService.init is actually used.
        let sut = FileService<TestModel>(
            fileName: "x.json",
            fileManager: FileManager.default,
            dataManager: DefaultDataManager(),
            directoryProvider: failingProvider
        )

        #expect(throws: OutfitPickerError.invalidConfiguration) {
            _ = try sut.filePath()
        }
    }

    // MARK: - Helpers

    private func makeTestSUT(
        fileName: String = "test.json",
        fileManager: FileManagerProtocol = FileManager.default,
        dataManager: DataManagerProtocol = DefaultDataManager()
    ) -> FileService<TestModel> {
        FileService<TestModel>(
            fileName: fileName,
            fileManager: fileManager,
            dataManager: dataManager,
            directoryProvider: FixedDirectoryProvider(url: uniqueTempDir()),
            errorMapper: { ConfigError.pathTraversalNotAllowed }
        )
    }

    private func makeTestSUTWithFile(
        fileName: String,
        dataManager: DataManagerProtocol
    ) throws -> (FileService<TestModel>, URL) {
        let base = uniqueTempDir()
        let path =
            base
            .appending(path: "outfitpicker", directoryHint: .isDirectory)
            .appending(path: fileName, directoryHint: .notDirectory)

        try FileManager.default.createDirectory(
            at: path.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        _ = FileManager.default.createFile(
            atPath: path.path(percentEncoded: false),
            contents: Data()
        )

        let sut = FileService<TestModel>(
            fileName: fileName,
            fileManager: FileManager.default,
            dataManager: dataManager,
            directoryProvider: FixedDirectoryProvider(url: base),
            errorMapper: { ConfigError.pathTraversalNotAllowed }
        )

        return (sut, path)
    }

    private func makeTestSUTWithThrowingProvider(
        errorMapper: @escaping @Sendable () -> Error
    ) -> FileService<TestModel> {
        FileService<TestModel>(
            fileName: "x.json",
            fileManager: FileManager.default,
            dataManager: DefaultDataManager(),
            directoryProvider: ThrowingDirectoryProvider(
                NSError(domain: "dir", code: 9, userInfo: nil)
            ),
            errorMapper: errorMapper
        )
    }

    private func sampleModel() -> TestModel {
        TestModel(id: 1, name: "test")
    }
}

private final class FakeFileManagerForAppSup: FileManagerProtocol {
    let appSupportURL: URL

    init(appSupportURL: URL) {
        self.appSupportURL = appSupportURL
    }

    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        // Only care about this call in the test
        guard directory == .applicationSupportDirectory else { return [] }
        return [appSupportURL]
    }

    // Unused protocol requirements in these tests – minimal stubs
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] { [] }

    func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool { false }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {}

    func removeItem(at URL: URL) throws {}
}

private final class FakeFileManagerNoAppSupport: FileManagerProtocol {
    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        // Simulate the OS giving us *no* Application Support directory
        return []
    }

    // Unused in these tests – minimal stubs:
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] { [] }

    func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool { false }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {}

    func removeItem(at URL: URL) throws {}
}
