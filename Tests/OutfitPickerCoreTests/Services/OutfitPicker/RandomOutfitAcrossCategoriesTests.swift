import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct RandomOutfitAcrossCategoriesTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Nil cases

    @Test func across_returnsNil_whenNoCategoriesAtRoot() throws {
        let env = try makeOutfitPickerSUT(root: root)
        let value = try env.sut.showRandomOutfitAcrossCategories().get()
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
        let junkURL = rootURL.appending(
            path: "notes.txt",
            directoryHint: .notDirectory
        )

        let contents: [URL: [URL]] = [
            rootURL: [goodURL, junkURL],
            goodURL: [goodFile],
            junkURL: [],
        ]

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: contents,
            directories: [rootURL, goodURL]
        )

        let ref = try #require(
            try env.sut.showRandomOutfitAcrossCategories().get()
        )

        #expect(ref.category.name == "Good")
        #expect(ref.fileName == "g1.avatar")
        #expect(normPath(ref.category.path) == "\(root)/Good")
        #expect(env.cache.saved.isEmpty)
    }

    // MARK: - Error mapping

    @Test func across_skipsCategoryIfFilesDisappearBetweenScanAndPick() throws {
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

        let fm = FakeFileManager(
            .ok(contents),
            directories: [rootURL, goodURL],
            secondCallEmptyFor: [goodURL]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: contents,
            directories: [rootURL, goodURL]
        )
        // Replace the file manager with the special one
        let sut = OutfitPicker(
            configService: env.config,
            cacheService: env.cache,
            fileManager: fm
        )

        let value = try sut.showRandomOutfitAcrossCategories().get()
        #expect(value == nil)
        #expect(env.cache.saved.isEmpty)
    }

    @Test func across_failure_configLoad_mapsToInvalidConfiguration() {
        let sut = makeOutfitPickerSUTWithConfigError(
            ConfigError.pathTraversalNotAllowed
        )
        let result = sut.showRandomOutfitAcrossCategories()

        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record("Expected invalidConfiguration")
        }
    }

    @Test func across_failure_rootListing_mapsToFileSystemError() throws {
        let sut = try makeOutfitPickerSUTWithFileSystemError(
            FileSystemError.operationFailed
        )
        let result = sut.showRandomOutfitAcrossCategories()

        switch result {
        case .failure(let e):
            #expect(e == .fileSystemError)
        case .success:
            Issue.record("Expected fileSystemError")
        }
    }

    @Test func across_failure_cacheLoad_mapsToCacheError() throws {
        let fs = makeFS(root: root, categories: ["Good": ["g1.avatar"]])
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(
            .throwsOnLoad(CacheError.decodingFailed)
        )
        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
        )

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.showRandomOutfitAcrossCategories()
        switch result {
        case .failure(let e):
            #expect(e == .cacheError)
        case .success:
            Issue.record("Expected cacheError")
        }
    }
}
