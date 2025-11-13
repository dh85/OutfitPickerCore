import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct ConfigServiceTests {

    // MARK: - Round trip

    @Test
    func saveThenLoadRoundTrip() throws {
        let (sut, _) = makeTestSetup()
        let original = try sampleConfig()

        try sut.save(original)
        let loaded = try sut.load()

        #expect(loaded == original)
    }

    // MARK: - Delete

    @Test
    func deleteRemovesFile() throws {
        let (sut, path) = try makeTestSetupWithSavedConfig()
        #expect(fileExists(path))

        try sut.delete()
        #expect(!fileExists(path))
    }

    // MARK: - Path & file naming

    @Test
    func configUsesCorrectFileNameAndAppFolder() throws {
        let (sut, _) = makeTestSetup()
        let path = try sut.configPath()

        #expect(path.lastPathComponent == "config.json")
        #expect(path.path(percentEncoded: false).contains("outfitpicker"))
    }

    // MARK: - Missing file handling

    @Test
    func loadThrowsWhenConfigFileIsMissing() {
        let (sut, _) = makeTestSetup()

        #expect(throws: OutfitPickerError.configurationNotFound) {
            _ = try sut.load()
        }
    }

    // MARK: - Corruption

    @Test
    func loadThrowsOnCorruptJSON() throws {
        let (sut, _) = makeTestSetup()
        try writeCorruptData(to: sut)

        #expect(throws: DecodingError.self) {
            _ = try sut.load()
        }
    }

    // MARK: - Create-on-save

    @Test
    func saveCreatesMissingDirectories() throws {
        let (sut, _) = makeTestSetup()

        try sut.save(try sampleConfig())
        let path = try sut.configPath()
        #expect(fileExists(path))
    }

    // MARK: - Write errors

    @Test
    func writeFailureSurfaces() {
        let sut = ConfigService(
            dataManager: ThrowingDataManager(),
            directoryProvider: FixedDirectoryProvider(url: uniqueTempDir())
        )
        #expect(throws: Error.self) {
            try sut.save(try sampleConfig())
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

    private func makeTestSetup() -> (ConfigService, URL) {
        let base = uniqueTempDir()
        let sut = ConfigService(
            directoryProvider: FixedDirectoryProvider(url: base)
        )
        return (sut, base)
    }

    private func makeTestSetupWithSavedConfig() throws -> (ConfigService, URL) {
        let (sut, _) = makeTestSetup()
        try sut.save(try sampleConfig())
        let path = try sut.configPath()
        return (sut, path)
    }

    private func sampleConfig() throws -> Config {
        try Config(root: "/x", language: "en")
    }

    private func writeCorruptData(to sut: ConfigService) throws {
        let path = try sut.configPath()
        try FileManager.default.createDirectory(
            at: path.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(to: path)
    }
}
