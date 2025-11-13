import Foundation
import Testing

@testable import OutfitPickerCore

@Suite
struct OutfitPickerGetAvailableCountTests {

    private let safeRoot = "/Users/test/Outfits"

    // MARK: - Helpers

    private struct SUT {
        let sut: OutfitPicker
        let fileManager: FakeFileManager
        let cache: FakeCacheService
        let config: FakeConfigService
    }

    private func makeCategoryDir(
        root: String,
        name: String,
        files: [String]
    ) -> (dir: URL, map: [URL: [URL]]) {
        let dir = URL(filePath: root, directoryHint: .isDirectory)
            .appending(path: name, directoryHint: .isDirectory)
        let urls = files.map {
            dir.appending(path: $0, directoryHint: .notDirectory)
        }
        return (dir, [dir: urls])
    }

    private func makeSUT(
        root: String = "/Users/test/Outfits",
        category: String,
        files: [String],
        cache: OutfitCache = OutfitCache()
    ) throws -> SUT {
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let (_, map) = makeCategoryDir(root: root, name: category, files: files)
        let fm = FakeFileManager(.ok(map))
        let cacheSvc = FakeCacheService(.ok(cache))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )
        return .init(
            sut: sut,
            fileManager: fm,
            cache: cacheSvc,
            config: configSvc
        )
    }

    // MARK: - Success cases

    @Test
    func availableCount_noCache_returnsAllFiles() throws {
        // No cache entry for "Club" → totalOutfits = files.count, worn = []
        let files = ["a.avatar", "b.avatar", "c.avatar"]
        let env = try makeSUT(
            root: safeRoot,
            category: "Club",
            files: files,
            cache: OutfitCache()
        )

        let result = env.sut.getAvailableCount(for: "Club")
        let count = try result.get()

        #expect(count == files.count)  // 3
    }

    @Test
    func availableCount_partialWorn_returnsRemaining() throws {
        let files = ["one.avatar", "two.avatar", "three.avatar"]
        let cache = OutfitCache(categories: [
            "Chic": CategoryCache(
                wornOutfits: ["one.avatar"],
                totalOutfits: files.count
            )
        ])

        let env = try makeSUT(
            root: safeRoot,
            category: "Chic",
            files: files,
            cache: cache
        )

        let result = env.sut.getAvailableCount(for: "Chic")
        let count = try result.get()

        // 3 total, 1 worn → 2 remaining
        #expect(count == 2)
    }

    @Test
    func availableCount_allWorn_rotationComplete_returnsTotal() throws {
        let files = ["x.avatar", "y.avatar"]
        let worn = Set(files)
        let cache = OutfitCache(categories: [
            "Latex": CategoryCache(
                wornOutfits: worn,
                totalOutfits: files.count
            )
        ])

        let env = try makeSUT(
            root: safeRoot,
            category: "Latex",
            files: files,
            cache: cache
        )

        let result = env.sut.getAvailableCount(for: "Latex")
        let count = try result.get()

        // rotationComplete → count = files.count, not 0
        #expect(count == files.count)  // 2
    }

    @Test
    func availableCount_emptyDirectory_returnsZero() throws {
        // No .avatar files in directory
        let env = try makeSUT(
            root: safeRoot,
            category: "Empty",
            files: []  // getAvatarFiles → []
        )

        let result = env.sut.getAvailableCount(for: "Empty")
        let count = try result.get()

        #expect(count == 0)
    }

    // MARK: - Error mapping

    @Test
    func availableCount_configLoadFailure_mapsToInvalidConfiguration() {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.pathTraversalNotAllowed)
        )

        // File manager will never be called, but needs a value
        let fm = FakeFileManager(.ok([:]))

        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.getAvailableCount(for: "Any")

        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record(
                "Expected invalidConfiguration when config load fails."
            )
        }
    }
}
