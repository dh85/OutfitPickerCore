import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct RotationResetTests {

    private let root = "/Users/test/Outfits"

    // MARK: - resetCategory

    @Test
    func resetCategory_resetsNamedCategoryAndPreservesOthers() throws {
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

        let env = try makeOutfitPickerSUT(root: root, cache: initialCache)
        try #require(env.sut.resetCategory("Casual").get() == ())

        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)

        let casual = try #require(saved.categories["Casual"])
        #expect(casual.totalOutfits == 0)
        #expect(casual.wornOutfits.isEmpty)

        let club = try #require(saved.categories["Club"])
        #expect(club.totalOutfits == 3)
        #expect(club.wornOutfits == ["club1.avatar"])
    }

    @Test
    func resetCategory_configLoadFailure_mapsToInvalidConfiguration() {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)
        let result = sut.resetCategory("Any")

        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record("Expected invalidConfiguration when config load fails.")
        }
    }

    @Test
    func resetCategory_cacheLoadFailure_mapsToCacheError() throws {
        let sut = try makeOutfitPickerSUTWithCacheError(CacheError.decodingFailed)
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

        let env = try makeOutfitPickerSUT(root: root, cache: existing)
        try #require(env.sut.resetAllCategories().get() == ())

        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)
        #expect(saved.categories.isEmpty)
    }

    @Test
    func resetAllCategories_configLoadFailure_mapsToInvalidConfiguration() {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.pathTraversalNotAllowed)
        let result = sut.resetAllCategories()

        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record("Expected invalidConfiguration when config load fails.")
        }
    }

    // MARK: - partialReset

    @Test
    func partialReset_guardWhenWornCountAtLeastTotal_doesNothing() throws {
        let existingCache = OutfitCache(categories: [
            "DateNight": CategoryCache(
                wornOutfits: ["one.avatar", "two.avatar"],
                totalOutfits: 2
            )
        ])

        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: "DateNight",
            files: ["one.avatar", "two.avatar"],
            cache: existingCache
        )

        try #require(env.sut.partialReset(categoryName: "DateNight", wornCount: 2).get() == ())
        #expect(env.cache.saved.isEmpty)  // guard fails → early success, no save
    }

    @Test
    func partialReset_withSmallerWornCount_truncatesWornSet() throws {
        let files = ["one.avatar", "two.avatar", "three.avatar"]
        let existingCache = OutfitCache(categories: [
            "Chic": CategoryCache(
                wornOutfits: Set(files),
                totalOutfits: 3
            )
        ])

        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: "Chic",
            files: files,
            cache: existingCache
        )

        try #require(env.sut.partialReset(categoryName: "Chic", wornCount: 1).get() == ())

        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)
        let cat = try #require(saved.categories["Chic"])

        #expect(cat.totalOutfits == files.count)
        #expect(cat.wornOutfits.count == 1)
    }

    @Test
    func partialReset_forCategoryWithoutExistingCache_stillWritesCache() throws {
        let files = ["x.avatar", "y.avatar"]
        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: "Latex",
            files: files,
            cache: OutfitCache()  // no entry for "Latex"
        )

        try #require(env.sut.partialReset(categoryName: "Latex", wornCount: 0).get() == ())

        #expect(env.cache.saved.count == 1)
        let saved = try #require(env.cache.saved.first)
        let cat = try #require(saved.categories["Latex"])

        #expect(cat.totalOutfits == files.count)
        #expect(cat.wornOutfits.isEmpty)
    }

    @Test func partialReset_configLoadFailure_mapsToInvalidConfiguration() {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)
        let result = sut.partialReset(categoryName: "Any", wornCount: 1)

        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record("Expected invalidConfiguration when config load fails.")
        }
    }
}
