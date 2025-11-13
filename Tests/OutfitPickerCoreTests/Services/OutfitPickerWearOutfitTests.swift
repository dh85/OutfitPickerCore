import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct OutfitPickerWearOutfitTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Happy-path behaviour

    @Test func wear_addsOutfitToNewCategoryCache_andSavesOnce() throws {
        let categoryName = "Chic"
        let fileName = "one.avatar"

        let env = try makeWearSUT(
            root: root,
            category: categoryName,
            files: [fileName, "two.avatar"],  // totalOutfits = 2
            cache: OutfitCache()  // no entry yet
        )

        let ref = makeOutfitRef(
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

        let env = try makeWearSUT(
            root: root,
            category: categoryName,
            files: ["track.avatar", "other1.avatar", "other2.avatar"],
            cache: existingCache
        )

        let ref = makeOutfitRef(
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
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.pathTraversalNotAllowed)
        )
        let fm = FakeFileManager(.ok([:]))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let ref = makeOutfitRef(
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
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.throwsError(FileSystemError.operationFailed))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let ref = makeOutfitRef(
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
        let categoryName = "Latex"
        let fileName = "only.avatar"

        // FS has one avatar file so getAvatarFiles succeeds
        let categoryDir = URL(filePath: root, directoryHint: .isDirectory)
            .appending(path: categoryName, directoryHint: .isDirectory)
        let fileURL = categoryDir.appending(
            path: fileName,
            directoryHint: .notDirectory
        )

        let fm = FakeFileManager(
            .ok([
                categoryDir: [fileURL]
            ])
        )

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))

        let cacheSvc = FakeCacheService(
            .throwsOnLoad(CacheError.decodingFailed)
        )

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let ref = makeOutfitRef(
            root: root,
            category: categoryName,
            fileName: fileName
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

// MARK: - Private helpers

private struct WearEnv {
    let sut: OutfitPicker
    let fileManager: FakeFileManager
    let cache: FakeCacheService
    let config: FakeConfigService
}

private func makeWearSUT(
    root: String,
    category: String,
    files: [String],
    cache: OutfitCache
) throws -> WearEnv {
    let config = try Config(root: root, language: "en")
    let configSvc = FakeConfigService(.ok(config))

    let categoryDir = URL(filePath: root, directoryHint: .isDirectory)
        .appending(path: category, directoryHint: .isDirectory)
    let urls = files.map {
        categoryDir.appending(path: $0, directoryHint: .notDirectory)
    }

    let fm = FakeFileManager(.ok([categoryDir: urls]))
    let cacheSvc = FakeCacheService(.ok(cache))

    let sut = OutfitPicker(
        configService: configSvc,
        cacheService: cacheSvc,
        fileManager: fm
    )

    return WearEnv(
        sut: sut,
        fileManager: fm,
        cache: cacheSvc,
        config: configSvc
    )
}

private func makeOutfitRef(
    root: String,
    category: String,
    fileName: String
) -> OutfitReference {
    let categoryPath = URL(
        filePath: root,
        directoryHint: .isDirectory
    )
    .appending(path: category, directoryHint: .isDirectory)
    .path(percentEncoded: false)

    let catRef = CategoryReference(name: category, path: categoryPath)
    return OutfitReference(fileName: fileName, category: catRef)
}
