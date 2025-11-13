import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct OutfitPickerShowRandomOutfitTests {

    private let safeRoot = "/Users/test/Outfits"

    // MARK: - Nil cases

    @Test func returnsNilWhenNoAvatarFiles() throws {
        let env = try makeSingleCategorySUT(category: "Casual", files: [])

        let result = env.sut.showRandomOutfit(from: "Casual")
        let value = try result.get()

        #expect(value == nil)
        #expect(env.cache.saved.isEmpty)
    }

    @Test func returnsNilWhenDirectoryHasNoAvatarExtensions() throws {
        let env = try makeSingleCategorySUT(
            category: "Misc",
            files: ["readme.txt", "photo.png"]
        )

        let result = env.sut.showRandomOutfit(from: "Misc")
        let value = try result.get()

        #expect(value == nil)
        #expect(env.cache.saved.isEmpty)
    }

    // MARK: - Normal selection

    @Test func picksFromAllWhenNoExistingCategoryCache_noSaveOccurs() throws {
        let files = ["a.avatar", "b.avatar", "c.avatar"]
        let env = try makeSingleCategorySUT(category: "Club", files: files)

        let result = env.sut.showRandomOutfit(from: "Club")
        let ref = try #require(try result.get())

        #expect(files.contains(ref.fileName))
        #expect(ref.category.name == "Club")
        #expect(normPath(ref.category.path) == "\(safeRoot)/Club")
        #expect(env.cache.saved.isEmpty)  // no reset write
    }

    @Test func respectsWornOutfits_picksOnlyUnworn() throws {
        let files = ["one.avatar", "two.avatar"]
        let cache = OutfitCache(categories: [
            "Chic": CategoryCache(
                wornOutfits: ["one.avatar"],
                totalOutfits: 2
            )
        ])

        let env = try makeSingleCategorySUT(
            category: "Chic",
            files: files,
            cache: cache
        )

        let result = env.sut.showRandomOutfit(from: "Chic")
        let ref = try #require(try result.get())

        #expect(ref.fileName == "two.avatar")
        #expect(env.cache.saved.isEmpty)
    }

    // MARK: - Rotation reset

    @Test func allWorn_resetsCategoryCache_thenReturnsFromAll_savesOnce() throws
    {
        let files = ["only.avatar"]
        let cache = OutfitCache(categories: [
            "Latex": CategoryCache(
                wornOutfits: Set(files),
                totalOutfits: 1
            )
        ])

        let env = try makeSingleCategorySUT(
            category: "Latex",
            files: files,
            cache: cache
        )

        let result = env.sut.showRandomOutfit(from: "Latex")
        let ref = try #require(try result.get())

        #expect(ref.fileName == "only.avatar")

        // Ensure a reset write occurred
        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)
        let cat = try #require(saved.categories["Latex"])

        #expect(cat.totalOutfits == 1)
        #expect(cat.wornOutfits.isEmpty)
    }

    // MARK: - Path composition

    @Test func categoryReferencePathComposedFromRootPlusCategoryName() throws {
        let root = "/Users/mu/Outfits"

        let env = try makeSingleCategorySUT(
            root: root,
            category: "DateNight",
            files: ["PickMe.avatar"]
        )

        let result = env.sut.showRandomOutfit(from: "DateNight")
        let ref = try #require(try result.get())

        #expect(ref.category.name == "DateNight")
        #expect(normPath(ref.category.path) == "\(root)/DateNight")
    }

    // MARK: - Error mapping

    @Test func failureWhenConfigLoadThrows_mapsToInvalidConfiguration() {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.pathTraversalNotAllowed)
        )
        let fm = FakeFileManager(.ok([:]), directories: [])
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result: OutfitPickerResult<OutfitReference?> =
            sut.showRandomOutfit(from: "Any")
        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record("Expected failure when config load throws.")
        }
    }

    @Test func failureWhenFileManagerThrows_mapsToFileSystemError() throws {
        let config = try Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(
            .throwsError(FileSystemError.operationFailed),
            directories: []
        )
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.showRandomOutfit(from: "Any")
        switch result {
        case .failure(let e):
            #expect(e == .fileSystemError)
        case .success:
            Issue.record("Expected failure when file manager throws.")
        }
    }

    @Test func failureWhenCacheLoadThrows_mapsToCacheError() throws {
        let files = ["A.avatar"]
        let config = try Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))

        let (dir, map) = makeCategoryDir(
            root: safeRoot,
            name: "Club",
            files: files
        )

        let fm = FakeFileManager(.ok(map), directories: [dir])

        let cacheSvc = FakeCacheService(
            .throwsOnLoad(CacheError.decodingFailed)
        )

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.showRandomOutfit(from: "Club")
        switch result {
        case .failure(let e):
            #expect(e == .cacheError)
        case .success:
            Issue.record("Expected failure when cache load throws.")
        }
    }
}
