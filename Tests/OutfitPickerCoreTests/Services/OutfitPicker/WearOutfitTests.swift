import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct WearOutfitTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Happy-path behaviour

    @Test func wear_addsOutfitToNewCategoryCache_andSavesOnce() throws {
        let categoryName = "Chic"
        let fileName = "one.avatar"

        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: categoryName,
            files: [fileName, "two.avatar"],
            cache: OutfitCache()
        )

        let ref = makeOutfitReference(
            root: root,
            category: categoryName,
            fileName: fileName
        )

        let result = env.sut.wearOutfit(ref)
        try #require(result.get() == ())

        // One save
        #expect(env.cache.saved.count == 1)

        let saved = try #require(env.cache.saved.first)
        let catCache = try #require(saved.categories[categoryName])

        #expect(catCache.totalOutfits == 2)
        #expect(catCache.wornOutfits.contains(fileName))
        // Don't assert lastUpdated (time-based)
    }

    @Test func wear_doesNotSave_whenOutfitAlreadyMarkedAsWorn() throws {
        let categoryName = "Club"
        let fileName = "track.avatar"

        // Pre-existing cache where this outfit is already in wornOutfits
        let existingCache = OutfitCache(categories: [
            categoryName: CategoryCache(
                wornOutfits: [fileName],
                totalOutfits: 3
            )
        ])

        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: categoryName,
            files: ["track.avatar", "other1.avatar", "other2.avatar"],
            cache: existingCache
        )

        let ref = makeOutfitReference(
            root: root,
            category: categoryName,
            fileName: fileName
        )

        let result = env.sut.wearOutfit(ref)
        try #require(result.get() == ())

        // No additional save should occur
        #expect(env.cache.saved.isEmpty)
    }

    // MARK: - Error mapping

    @Test func wear_failure_configLoad_mapsToInvalidConfiguration() {
        let sut = makeOutfitPickerSUTWithConfigError(
            ConfigError.pathTraversalNotAllowed
        )
        let ref = makeOutfitReference(
            root: root,
            category: "Any",
            fileName: "file.avatar"
        )

        let result = sut.wearOutfit(ref)
        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record(
                "Expected invalidConfiguration from wearOutfit when config load fails."
            )
        }
    }

    @Test func wear_failure_avatarListing_mapsToFileSystemError() throws {
        let sut = try makeOutfitPickerSUTWithFileSystemError(
            FileSystemError.operationFailed
        )
        let ref = makeOutfitReference(
            root: root,
            category: "Chic",
            fileName: "x.avatar"
        )

        let result = sut.wearOutfit(ref)
        switch result {
        case .failure(let e):
            #expect(e == .fileSystemError)
        case .success:
            Issue.record(
                "Expected fileSystemError from wearOutfit when FileManager throws."
            )
        }
    }

    @Test func wear_failure_cacheLoad_mapsToCacheError() throws {
        let sut = try makeOutfitPickerSUTWithCacheError(
            CacheError.decodingFailed
        )
        let ref = makeOutfitReference(
            root: root,
            category: "Latex",
            fileName: "only.avatar"
        )

        let result = sut.wearOutfit(ref)
        switch result {
        case .failure(let e):
            #expect(e == .cacheError)
        case .success:
            Issue.record(
                "Expected cacheError from wearOutfit when cache load fails."
            )
        }
    }
}
