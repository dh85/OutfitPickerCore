import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct ConfigServiceTests {

    // MARK: - Round trip

    @Test
    func saveThenLoadRoundTrip() throws {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        let original = try Config(root: "/some/path", language: "en")
        try sut.save(original)

        let loaded = try sut.load()
        // Prefer Equatable if Config conforms; otherwise assert fields individually.
        #expect(loaded == original)
    }

    // MARK: - Delete

    @Test
    func deleteRemovesFile() throws {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        try sut.save(try Config(root: "/x", language: "en"))
        let path = try sut.configPath()
        #expect(fileExists(path))

        try sut.delete()
        #expect(!fileExists(path))
    }

    // MARK: - Path & file naming

    @Test
    func configUsesCorrectFileNameAndAppFolder() throws {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        let path = try sut.configPath()
        #expect(path.lastPathComponent == "config.json")
        #expect(path.path(percentEncoded: false).contains("outfitpicker"))
    }

    // MARK: - Missing file handling

    @Test
    func loadThrowsWhenConfigFileIsMissing() {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        #expect(throws: OutfitPickerError.configurationNotFound) {
            _ = try sut.load()
        }
    }

    // MARK: - Corruption

    @Test
    func loadThrowsOnCorruptJSON() throws {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        let badPath = try sut.configPath()
        try FileManager.default.createDirectory(
            at: badPath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(to: badPath)

        #expect(throws: DecodingError.self) {
            _ = try sut.load()
        }
    }

    // MARK: - Create-on-save

    @Test
    func saveCreatesMissingDirectories() throws {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        try sut.save(try Config(root: "/x", language: "en"))

        let path = try sut.configPath()
        #expect(fileExists(path))
    }

    // MARK: - Write errors

    @Test
    func writeFailureSurfaces() {
        let base = uniqueTempDir()
        let sut = ConfigService(
            dataManager: ThrowingDataManager(),
            directoryProvider: FixedDirectoryProvider(url: base)
        )
        #expect(throws: Error.self) {
            try sut.save(try Config(root: "/x", language: "en"))
        }
    }

    // MARK: - Directory resolution errors

    @Test
    func directoryResolutionErrorMapsToConfigError() {
        let sut = ConfigService(directoryProvider: ThrowingDirectoryProvider())
        #expect(throws: ConfigError.pathTraversalNotAllowed) {
            _ = try sut.configPath()
        }
    }

    // MARK: - Helpers

    private func makeSUT(base: URL) -> ConfigService {
        ConfigService(directoryProvider: FixedDirectoryProvider(url: base))
    }
}
