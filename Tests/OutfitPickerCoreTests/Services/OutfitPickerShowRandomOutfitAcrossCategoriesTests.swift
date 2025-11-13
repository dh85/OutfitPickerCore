import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct OutfitPickerShowRandomOutfitAcrossCategoriesTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Nil cases

    @Test func across_returnsNil_whenNoCategoriesAtRoot() throws {
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let fm = FakeFileManager(
            .ok([rootURL: []]),
            directories: [rootURL]
        )
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.showRandomOutfitAcrossCategories()
        let value = try result.get()

        #expect(value == nil)
    }

    @Test func across_skipsExcludedEmptyAndNoAvatar_selectsFromAvailable()
        throws
    {
        // Excluded: userExcluded
        // Empty: no files
        // Docs: only non-avatar
        // Good: has avatar
        let env = try makeAcrossCategoriesSUT(
            root: root,
            categories: [
                "Excluded": ["ignore.txt"],
                "Empty": [],
                "Docs": ["readme.md", "photo.png"],
                "Good": ["g1.avatar"],
            ],
            excluded: ["Excluded"]
        )

        let result = env.sut.showRandomOutfitAcrossCategories()
        let ref = try #require(try result.get())

        #expect(ref.category.name == "Good")
        #expect(ref.fileName == "g1.avatar")
        #expect(normPath(ref.category.path) == "\(root)/Good")
        #expect(env.cache.saved.isEmpty)
    }

    @Test func across_respectsWornPerCategory_onlyUnwornAddedToPool() throws {
        // Good has two avatars; one already worn → must pick the other
        let cache = OutfitCache(categories: [
            "Good": CategoryCache(
                wornOutfits: ["g1.avatar"],
                totalOutfits: 2
            )
        ])

        let env = try makeAcrossCategoriesSUT(
            root: root,
            categories: [
                "Good": ["g1.avatar", "g2.avatar"]
            ],
            cache: cache
        )

        let result = env.sut.showRandomOutfitAcrossCategories()
        let ref = try #require(try result.get())

        #expect(ref.category.name == "Good")
        #expect(ref.fileName == "g2.avatar")
        #expect(env.cache.saved.isEmpty)
    }

    @Test func across_allCategoriesFullyWorn_returnsNil() throws {
        // All worn → availableFiles empty for each category → overall nil
        let cache = OutfitCache(categories: [
            "A": CategoryCache(
                wornOutfits: ["a.avatar"],
                totalOutfits: 1
            ),
            "B": CategoryCache(
                wornOutfits: ["b.avatar"],
                totalOutfits: 1
            ),
        ])

        let env = try makeAcrossCategoriesSUT(
            root: root,
            categories: [
                "A": ["a.avatar"],
                "B": ["b.avatar"],
            ],
            cache: cache
        )

        let result: OutfitPickerResult<OutfitReference?> =
            env.sut.showRandomOutfitAcrossCategories()
        let value = try result.get()

        #expect(value == nil)
    }

    // MARK: - Directory detection / guard coverage

    @Test func across_ignoresNonDirectoryEntriesAtRoot() throws {
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let goodURL = rootURL.appending(
            path: "Good",
            directoryHint: .isDirectory
        )
        let goodFile = goodURL.appending(
            path: "g1.avatar",
            directoryHint: .notDirectory
        )

        // This is our "file at root" that should *not* be treated as a directory.
        let junkURL = rootURL.appending(
            path: "notes.txt",
            directoryHint: .notDirectory
        )

        // Fake filesystem layout:
        // root: [Good/, notes.txt]
        // Good/: [g1.avatar]
        let contents: [URL: [URL]] = [
            rootURL: [goodURL, junkURL],
            goodURL: [goodFile],
            junkURL: [],  // unused, but harmless
        ]

        // Mark only root and Good as directories.
        let fm = FakeFileManager(
            .ok(contents),
            directories: [rootURL, goodURL]
        )

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.showRandomOutfitAcrossCategories()
        let ref = try #require(try result.get())

        // We still get the Good/g1.avatar outfit, but the junk file path
        // has gone through the `guard ... else { continue }` branch.
        #expect(ref.category.name == "Good")
        #expect(ref.fileName == "g1.avatar")
        #expect(normPath(ref.category.path) == "\(root)/Good")
        #expect(cacheSvc.saved.isEmpty)
    }

    // MARK: - Error mapping

    @Test func across_skipsCategoryIfFilesDisappearBetweenScanAndPick() throws {
        // Setup a root with one category "Good" that initially has an avatar.
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let goodURL = rootURL.appending(
            path: "Good",
            directoryHint: .isDirectory
        )
        let goodFile = goodURL.appending(
            path: "g1.avatar",
            directoryHint: .notDirectory
        )

        let contents: [URL: [URL]] = [
            rootURL: [goodURL],
            goodURL: [goodFile],
        ]

        // First listing of Good (in getCategoryInfo) -> [g1.avatar]
        // Second listing of Good (in showRandomOutfitAcrossCategories) -> []
        let fm = FakeFileManager(
            .ok(contents),
            directories: [rootURL, goodURL],
            secondCallEmptyFor: [goodURL]
        )

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result: OutfitPickerResult<OutfitReference?> =
            sut.showRandomOutfitAcrossCategories()
        let value = try result.get()

        // Because the only category ends up with files == [],
        // the guard !files.isEmpty hits the `else { continue }` path,
        // leaving availableCategories empty and returning nil.
        #expect(value == nil)
        #expect(cacheSvc.saved.isEmpty)
    }

    @Test func across_failure_configLoad_mapsToInvalidConfiguration() {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.pathTraversalNotAllowed)
        )
        let fm = FakeFileManager(
            .ok([:]),
            directories: []
        )
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result: OutfitPickerResult<OutfitReference?> =
            sut.showRandomOutfitAcrossCategories()
        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record("Expected invalidConfiguration")
        }
    }

    @Test func across_failure_rootListing_mapsToFileSystemError() throws {
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let fm = FakeFileManager(
            .throwsError(FileSystemError.operationFailed),
            directories: [rootURL]
        )
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result: OutfitPickerResult<OutfitReference?> =
            sut.showRandomOutfitAcrossCategories()
        switch result {
        case .failure(let e):
            #expect(e == .fileSystemError)
        case .success:
            Issue.record("Expected fileSystemError")
        }
    }

    @Test func across_failure_cacheLoad_mapsToCacheError() throws {
        // Ensure loop enters at least one category, then fail on cache load
        let fs = makeFS(
            root: root,
            categories: ["Good": ["g1.avatar"]]
        )

        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
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

        let result: OutfitPickerResult<OutfitReference?> =
            sut.showRandomOutfitAcrossCategories()
        switch result {
        case .failure(let e):
            #expect(e == .cacheError)
        case .success:
            Issue.record("Expected cacheError")
        }
    }
}
