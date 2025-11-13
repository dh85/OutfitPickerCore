import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

// MARK: - Change detection & updateConfig tests

struct OutfitPickerChangeDetectionTests {

    // MARK: - detectChanges

    @Test(
        "detectChanges uses knownCategories when knownCategoryFiles is empty and reports new + changed categories and added files"
    )
    func detectChanges_usesKnownCategoriesFallback() throws {
        let root = "/Users/test/Outfits"

        // Config has only knownCategories, no knownCategoryFiles
        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: ["A", "B"],
            knownCategoryFiles: [:]
        )

        // FS: A, B, C all exist; each has one .avatar file
        let fs = makeFS(
            root: root,
            categories: [
                "A": ["a1.avatar"],
                "B": ["b1.avatar"],
                "C": ["c1.avatar"],
            ]
        )

        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
        )
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let changes = try sut.detectChanges().get()

        // Previously known: A, B. Now: A, B, C.
        #expect(changes.newCategories == Set(["C"]))
        #expect(changes.deletedCategories.isEmpty)

        // A and B now have files where previously we knew nothing,
        // so they should be considered "changed" with addedFiles.
        #expect(changes.changedCategories == Set(["A", "B"]))
        #expect(changes.addedFiles["A"] == Set(["a1.avatar"]))
        #expect(changes.addedFiles["B"] == Set(["b1.avatar"]))
        #expect(changes.deletedFiles.isEmpty)
    }

    @Test(
        "detectChanges uses knownCategoryFiles when present and reports added/deleted files per category"
    )
    func detectChanges_usesKnownCategoryFiles() throws {
        let root = "/Users/test/Outfits"

        // Previous snapshot:
        // A: old1, old2
        // B: b1
        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: [],
            knownCategoryFiles: [
                "A": ["old1.avatar", "old2.avatar"],
                "B": ["b1.avatar"],
            ]
        )

        // Current FS:
        // A: old2, newA
        // B: (empty)
        let fs = makeFS(
            root: root,
            categories: [
                "A": ["old2.avatar", "newA.avatar"],
                "B": [],
            ]
        )

        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
        )
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let changes = try sut.detectChanges().get()

        #expect(changes.newCategories.isEmpty)
        #expect(changes.deletedCategories.isEmpty)
        #expect(changes.changedCategories == Set(["A", "B"]))

        // A: old1 deleted, newA added
        #expect(changes.addedFiles["A"] == Set(["newA.avatar"]))
        #expect(changes.deletedFiles["A"] == Set(["old1.avatar"]))

        // B: b1 deleted, nothing added
        #expect(
            changes.addedFiles["B"] == nil || changes.addedFiles["B"]!.isEmpty
        )
        #expect(changes.deletedFiles["B"] == Set(["b1.avatar"]))
    }

    @Test(
        "detectChanges returns empty changes when FS matches knownCategoryFiles"
    )
    func detectChanges_noChanges() throws {
        let root = "/Users/test/Outfits"

        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: [],
            knownCategoryFiles: [
                "Solo": ["x.avatar"]
            ]
        )

        let fs = makeFS(
            root: root,
            categories: [
                "Solo": ["x.avatar"]
            ]
        )

        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
        )
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let changes = try sut.detectChanges().get()

        #expect(changes.newCategories.isEmpty)
        #expect(changes.deletedCategories.isEmpty)
        #expect(changes.changedCategories.isEmpty)
        #expect(changes.addedFiles.isEmpty)
        #expect(changes.deletedFiles.isEmpty)
        #expect(changes.isEmpty)
    }

    @Test("detectChanges maps ConfigError via OutfitPickerError.from")
    func detectChanges_mapsConfigError() {
        let configSvc = ThrowingConfigService(error: ConfigError.missingRoot)
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let fm = FakeFileManager(.ok([:]), directories: [])

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        #expect(throws: OutfitPickerError.invalidConfiguration) {
            _ = try sut.detectChanges().get()
        }
    }

    // MARK: - updateConfig

    @Test(
        "updateConfig updates config based on current FS and does not reset cache when deletedCategories is empty"
    )
    func updateConfig_updatesConfigWithoutCacheReset() throws {
        let root = "/Users/test/Outfits"

        // Original config is out of date: knows only "Old"
        let original = try Config(
            root: root,
            language: "en",
            excludedCategories: ["Excluded"],
            knownCategories: ["Old"],
            knownCategoryFiles: ["Old": ["old1.avatar"]]
        )

        // Current FS has only "NewCat" with two files
        let fs = makeFS(
            root: root,
            categories: [
                "NewCat": ["one.avatar", "two.avatar"]
            ]
        )

        let configSvc = CapturingConfigService(initial: original)
        let cacheSvc = FakeCacheService(
            .ok(
                OutfitCache(categories: [
                    "NewCat": .init(
                        wornOutfits: ["one.avatar"],
                        totalOutfits: 2
                    )
                ])
            )
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

        // No deleted categories → cache reset branch must NOT run
        let changes = CategoryChanges(
            newCategories: ["NewCat"],
            deletedCategories: [],
            changedCategories: [],
            addedFiles: [:],
            deletedFiles: [:]
        )

        try sut.updateConfig(with: changes).get()

        // Config was saved once with updated categories/files
        #expect(configSvc.saved.count == 1)
        let saved = try #require(configSvc.saved.first)

        #expect(saved.root == original.root)
        #expect(saved.language == original.language)
        #expect(saved.excludedCategories == original.excludedCategories)
        #expect(saved.knownCategories == Set(["NewCat"]))
        #expect(
            saved.knownCategoryFiles["NewCat"]
                == Set(["one.avatar", "two.avatar"])
        )

        // Cache service should not have been written to
        #expect(cacheSvc.saved.isEmpty)
    }

    @Test("updateConfig resets cache when deletedCategories is non-empty")
    func updateConfig_resetsCacheWhenDeletedCategoriesPresent() throws {
        let root = "/Users/test/Outfits"

        let original = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: ["Old"],
            knownCategoryFiles: ["Old": ["old1.avatar"]]
        )

        // FS has a category "Cat" with one file
        let fs = makeFS(
            root: root,
            categories: [
                "Cat": ["one.avatar"]
            ]
        )

        let initialCache = OutfitCache(categories: [
            "Cat": .init(wornOutfits: ["one.avatar"], totalOutfits: 3)
        ])

        let configSvc = CapturingConfigService(initial: original)
        let cacheSvc = FakeCacheService(.ok(initialCache))
        let fm = FakeFileManager(
            .ok(fs.contents),
            directories: Array(fs.directories)
        )

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        // Signal that some categories were deleted → triggers cache reset branch
        let changes = CategoryChanges(
            newCategories: [],
            deletedCategories: ["OldCategory"],
            changedCategories: [],
            addedFiles: [:],
            deletedFiles: [:]
        )

        try sut.updateConfig(with: changes).get()

        // Config saved once
        #expect(configSvc.saved.count == 1)

        // Cache resetAll() applied and saved once
        #expect(cacheSvc.saved.count == 1)
        let resetCache = try #require(cacheSvc.saved.first)

        // Same keys, same version, same createdAt
        #expect(resetCache.version == initialCache.version)
        #expect(resetCache.createdAt == initialCache.createdAt)
        #expect(
            Set(resetCache.categories.keys) == Set(initialCache.categories.keys)
        )

        // For each category: wornOutfits cleared, totalOutfits preserved
        for (name, before) in initialCache.categories {
            let after = try #require(resetCache.categories[name])
            #expect(after.totalOutfits == before.totalOutfits)
            #expect(after.wornOutfits.isEmpty)
            // We *don't* assert on `lastUpdated` because it's time-dependent
        }
    }

    @Test(
        "detectChanges hits `currentFiles == nil` case and records deleted files"
    )
    func detectChanges_nilCurrentFilesCase() throws {
        let root = "/Users/test/Outfits"

        // Previous config: category "X" with one known file
        let original = try Config(
            root: root,
            language: "en",
            excludedCategories: [],
            knownCategories: ["X"],
            knownCategoryFiles: ["X": ["old.avatar"]]
        )

        // FS: root has a directory "X", but FakeFileManager has *no* entry for X
        // → getAvatarFiles(in: "X") sees no .avatar files
        // → currentCategoryFiles["X"] is never set → nil → [] via `?? []`
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let xDir = rootURL.appending(path: "X", directoryHint: .isDirectory)

        let fm = FakeFileManager(
            .ok([
                rootURL: [xDir]  // only root → [X]; no mapping for xDir itself
            ]),
            directories: [rootURL, xDir]
        )

        let configSvc = FakeConfigService(.ok(original))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let changes = try sut.detectChanges().get()

        // No new or fully deleted categories
        #expect(changes.newCategories.isEmpty)
        #expect(changes.deletedCategories.isEmpty)

        // "X" is present in both previous & current names → in commonCategories
        // Files changed (all previous files disappeared)
        #expect(changes.changedCategories == ["X"])

        // We had a previous file, now none → deletedFiles["X"] is that set
        #expect(changes.deletedFiles["X"] == ["old.avatar"])

        // No added files → key not present at all
        #expect(changes.addedFiles["X"] == nil)
    }

    @Test(
        "updateConfig maps ConfigError from load using OutfitPickerError.from"
    )
    func updateConfig_mapsConfigError() {
        let configSvc = ThrowingConfigService(error: ConfigError.missingRoot)
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let fm = FakeFileManager(.ok([:]), directories: [])

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let changes = CategoryChanges()

        #expect(throws: OutfitPickerError.invalidConfiguration) {
            _ = try sut.updateConfig(with: changes).get()
        }
    }
}

// MARK: - Extra test doubles (compatible with your existing ones)

/// A ConfigService that returns a fixed initial config and records every save.
final class CapturingConfigService: ConfigServiceProtocol, @unchecked Sendable {
    private let initial: Config
    private(set) var saved: [Config] = []

    init(initial: Config) {
        self.initial = initial
    }

    func load() throws -> Config { initial }

    func save(_ config: Config) throws {
        saved.append(config)
    }

    func delete() throws { fatalError("not used in these tests") }

    func configPath() throws -> URL {
        URL(filePath: "/dev/null", directoryHint: .notDirectory)
    }
}

/// A ConfigService that always throws a given error (for error-mapping paths).
final class ThrowingConfigService: ConfigServiceProtocol, @unchecked Sendable {
    let error: Error
    init(error: Error) { self.error = error }

    func load() throws -> Config { throw error }
    func save(_ config: Config) throws { throw error }
    func delete() throws { throw error }
    func configPath() throws -> URL {
        URL(filePath: "/dev/null", directoryHint: .notDirectory)
    }
}
