import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct CacheServiceTests {

    // MARK: - Round trip

    @Test
    func saveThenLoadRoundTrip() throws {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        let original = OutfitCache(categories: [
            "/cat": .init(wornOutfits: ["a"], totalOutfits: 3)
        ])

        try sut.save(original)
        let loaded = try sut.load()

        #expect(loaded == original)
    }

    // MARK: - Delete

    @Test
    func deleteRemovesFile() throws {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        try sut.save(OutfitCache())
        let path = try sut.cachePath()
        #expect(fileExists(path))

        try sut.delete()
        #expect(!fileExists(path))
    }

    // MARK: - Corruption

    @Test
    func loadThrowsOnCorruptJSON() throws {
        let base = uniqueTempDir()
        let sut = makeSUT(base: base)

        // Write bad bytes at the expected path
        let badPath = try sut.cachePath()
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

        try sut.save(OutfitCache())

        let path = try sut.cachePath()
        #expect(fileExists(path))
    }

    // MARK: - Write errors

    @Test
    func writeFailureSurfaces() {
        let base = uniqueTempDir()
        let sut = CacheService(
            dataManager: ThrowingDataManager(),
            directoryProvider: FixedDirectoryProvider(url: base)
        )
        #expect(throws: Error.self) {
            try sut.save(OutfitCache())
        }
    }

    // MARK: - Directory resolution errors

    @Test
    func directoryResolutionErrorMapsToCacheError() {
        let sut = CacheService(directoryProvider: ThrowingDirectoryProvider())
        #expect(throws: CacheError.pathNotFound) {
            _ = try sut.cachePath()
        }
    }

    // MARK: - Default on missing file (exercises `?? OutfitCache()`)

    @Test
    func loadReturnsDefaultWhenCacheFileIsMissing() throws {
        let base = uniqueTempDir()  // ensure clean, unique location
        let sut = makeSUT(base: base)

        let cache = try sut.load()

        #expect(cache.categories.isEmpty)
        #expect(cache.version == 1)
        #expect(cache.createdAt <= Date())

        // No file should have been created as a side-effect of load
        let path = try sut.cachePath()
        #expect(!fileExists(path))
    }

    // MARK: - Helpers

    private func makeSUT(base: URL) -> CacheService {
        CacheService(directoryProvider: FixedDirectoryProvider(url: base))
    }
}
