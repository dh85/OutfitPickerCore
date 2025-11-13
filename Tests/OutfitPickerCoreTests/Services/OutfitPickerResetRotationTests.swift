import Foundation
import Testing

@testable import OutfitPickerCore

@Suite
struct OutfitPickerResetRotationTests {

    private let root = "/Users/test/Outfits"

    // MARK: - resetCategory

    @Test
    func resetCategory_resetsNamedCategoryAndPreservesOthers() throws {
        // Given an existing cache with two categories
        let initialCache = OutfitCache(categories: [
            "Casual": CategoryCache(
                wornOutfits: ["c1.avatar", "c2.avatar"],
                totalOutfits: 5
            ),
            "Club": CategoryCache(
                wornOutfits: ["club1.avatar"],
                totalOutfits: 3
            ),
        ])

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(initialCache))
        let fm = FakeFileManager(.ok([:]))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        // When
        let result = sut.resetCategory("Casual")
        try #require(result.get() == ())

        // Then
        #expect(cacheSvc.saved.count == 1)
        let saved = try #require(cacheSvc.saved.first)

        // "Casual" should be reset to 0 total / empty worn
        let casual = try #require(saved.categories["Casual"])
        #expect(casual.totalOutfits == 0)
        #expect(casual.wornOutfits.isEmpty)

        // "Club" should be unchanged
        let club = try #require(saved.categories["Club"])
        #expect(club.totalOutfits == 3)
        #expect(club.wornOutfits == ["club1.avatar"])
    }

    @Test
    func resetCategory_configLoadFailure_mapsToInvalidConfiguration() {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.missingRoot)
        )
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let fm = FakeFileManager(.ok([:]))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.resetCategory("Any")
        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record(
                "Expected invalidConfiguration when config load fails."
            )
        }
    }

    @Test
    func resetCategory_cacheLoadFailure_mapsToCacheError() throws {
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(
            .throwsOnLoad(CacheError.decodingFailed)
        )
        let fm = FakeFileManager(.ok([:]))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.resetCategory("Casual")
        switch result {
        case .failure(let e):
            #expect(e == .cacheError)
        case .success:
            Issue.record("Expected cacheError when cache load fails.")
        }
    }

    // MARK: - resetAllCategories

    @Test
    func resetAllCategories_replacesCacheWithEmpty() throws {
        let existing = OutfitCache(categories: [
            "A": CategoryCache(wornOutfits: ["a1"], totalOutfits: 2),
            "B": CategoryCache(wornOutfits: ["b1", "b2"], totalOutfits: 3),
        ])

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(existing))
        let fm = FakeFileManager(.ok([:]))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.resetAllCategories()
        try #require(result.get() == ())

        #expect(cacheSvc.saved.count == 1)
        let saved = try #require(cacheSvc.saved.first)

        // Saved cache should be completely empty
        #expect(saved.categories.isEmpty)
    }

    @Test
    func resetAllCategories_configLoadFailure_mapsToInvalidConfiguration() {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.pathTraversalNotAllowed)
        )
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let fm = FakeFileManager(.ok([:]))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.resetAllCategories()
        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record(
                "Expected invalidConfiguration when config load fails."
            )
        }
    }

    // MARK: - partialReset

    @Test
    func partialReset_guardWhenWornCountAtLeastTotal_doesNothing() throws {
        // files.count = 2
        let (_, map) = makeCategoryDir(
            root: root,
            name: "DateNight",
            files: ["one.avatar", "two.avatar"]
        )

        let existingCache = OutfitCache(categories: [
            "DateNight": CategoryCache(
                wornOutfits: ["one.avatar", "two.avatar"],
                totalOutfits: 2
            )
        ])

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(existingCache))
        let fm = FakeFileManager(.ok(map))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        // wornCount == files.count → guard fails → early success, no save
        let result = sut.partialReset(categoryName: "DateNight", wornCount: 2)
        try #require(result.get() == ())

        #expect(cacheSvc.saved.isEmpty)
    }

    @Test
    func partialReset_withSmallerWornCount_truncatesWornSet() throws {
        let files = ["one.avatar", "two.avatar", "three.avatar"]
        let (_, map) = makeCategoryDir(
            root: root,
            name: "Chic",
            files: files
        )

        let existingCache = OutfitCache(categories: [
            "Chic": CategoryCache(
                wornOutfits: ["one.avatar", "two.avatar", "three.avatar"],
                totalOutfits: 3
            )
        ])

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(existingCache))
        let fm = FakeFileManager(.ok(map))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        // Ask to keep only 1 worn outfit
        let result = sut.partialReset(categoryName: "Chic", wornCount: 1)
        try #require(result.get() == ())

        #expect(cacheSvc.saved.count == 1)
        let saved = try #require(cacheSvc.saved.first)
        let cat = try #require(saved.categories["Chic"])

        #expect(cat.totalOutfits == files.count)
        #expect(cat.wornOutfits.count == 1)
        // Don't assert which one exactly, as Set ordering is not deterministic
    }

    @Test
    func partialReset_forCategoryWithoutExistingCache_stillWritesCache() throws
    {
        let files = ["x.avatar", "y.avatar"]
        let (_, map) = makeCategoryDir(
            root: root,
            name: "Latex",
            files: files
        )

        let emptyCache = OutfitCache()  // no entry for "Latex"

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(emptyCache))
        let fm = FakeFileManager(.ok(map))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.partialReset(categoryName: "Latex", wornCount: 0)
        try #require(result.get() == ())

        #expect(cacheSvc.saved.count == 1)
        let saved = try #require(cacheSvc.saved.first)
        let cat = try #require(saved.categories["Latex"])

        #expect(cat.totalOutfits == files.count)
        #expect(cat.wornOutfits.isEmpty)
    }

    @Test func partialReset_configLoadFailure_mapsToInvalidConfiguration() {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.missingRoot)
        )
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let fm = FakeFileManager(.ok([:]))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.partialReset(categoryName: "Any", wornCount: 1)
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
