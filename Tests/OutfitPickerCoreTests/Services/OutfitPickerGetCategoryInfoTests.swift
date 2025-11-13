import Foundation
import Testing

@testable import OutfitPickerCore

@Suite
struct OutfitPickerGetCategoryInfoTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Happy-path behaviour

    @Test
    func mixedStates_excludedEmptyNoAvatarAndHasOutfits_sortedAlphabetically() throws {
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)

        // Child directories and a non-directory entry
        let excludedURL = rootURL.appending(path: "Excluded", directoryHint: .isDirectory)
        let emptyURL    = rootURL.appending(path: "Empty",    directoryHint: .isDirectory)
        let docsURL     = rootURL.appending(path: "Docs",     directoryHint: .isDirectory)
        let goodURL     = rootURL.appending(path: "Good",     directoryHint: .isDirectory)
        let fileLikeURL = rootURL.appending(path: "loose.txt", directoryHint: .notDirectory)

        // Files inside category dirs
        let docsReadme = docsURL.appending(path: "readme.md", directoryHint: .notDirectory)
        let docsPhoto  = docsURL.appending(path: "photo.png", directoryHint: .notDirectory)

        let goodAvatar = goodURL.appending(path: "g1.avatar", directoryHint: .notDirectory)
        let goodImage  = goodURL.appending(path: "image.png", directoryHint: .notDirectory)

        // File-system layout mapping for contentsOfDirectory
        let contents: [URL: [URL]] = [
            rootURL: [excludedURL, emptyURL, docsURL, goodURL, fileLikeURL],
            emptyURL: [],
            docsURL: [docsReadme, docsPhoto],
            goodURL: [goodAvatar, goodImage],
            // excludedURL: not needed; we never inspect its contents because it is excluded
        ]

        // Mark which paths are treated as directories.
        // fileLikeURL is deliberately *not* in this set, so we hit the
        // `guard fileExists(...), isDirectory.boolValue else { continue }` path.
        let directories = [excludedURL, emptyURL, docsURL, goodURL]

        let fm = FakeFileManager(.ok(contents), directories: directories)

        let config = try Config(
            root: root,
            language: "en",
            excludedCategories: ["Excluded"]
        )
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.getCategoryInfo()
        let infos = try result.get()

        // We should have *four* categories (non-directory "loose.txt" is skipped)
        #expect(infos.count == 4)

        // Sorted lexicographically by category.name
        let names = infos.map { $0.category.name }
        #expect(names == ["Docs", "Empty", "Excluded", "Good"])

        func info(named name: String) -> CategoryInfo? {
            infos.first { $0.category.name == name }
        }

        // Excluded → .userExcluded, no outfits
        do {
            let excluded = try #require(info(named: "Excluded"))
            #expect(excluded.state == .userExcluded)
            #expect(excluded.category.outfits.isEmpty)
            #expect(excluded.category.path == excludedURL.path(percentEncoded: false))
        }

        // Empty → .empty (no files at all)
        do {
            let empty = try #require(info(named: "Empty"))
            #expect(empty.state == .empty)
            #expect(empty.category.outfits.isEmpty)
            #expect(empty.category.path == emptyURL.path(percentEncoded: false))
        }

        // Docs → .noAvatarFiles (non-empty, but no .avatar)
        do {
            let docs = try #require(info(named: "Docs"))
            #expect(docs.state == .noAvatarFiles)
            #expect(docs.category.outfits.isEmpty)
            #expect(docs.category.path == docsURL.path(percentEncoded: false))
        }

        // Good → .hasOutfits with only avatar filenames
        do {
            let good = try #require(info(named: "Good"))
            #expect(good.state == .hasOutfits)
            #expect(good.category.outfits == ["g1.avatar"])
            #expect(good.category.path == goodURL.path(percentEncoded: false))
        }
    }

    @Test
    func noChildrenAtRoot_returnsEmptyArray() throws {
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let fm = FakeFileManager(.ok([rootURL: []]), directories: [])

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result = sut.getCategoryInfo()
        let infos = try result.get()

        #expect(infos.isEmpty)
    }

    // MARK: - Error mapping

    @Test
    func failure_configLoad_mapsToInvalidConfiguration() {
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

        let result = sut.getCategoryInfo()
        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record("Expected invalidConfiguration when config load fails.")
        }
    }

    @Test
    func failure_rootListing_mapsToFileSystemError() throws {
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))

        // Throw from contentsOfDirectory(rootURL, ...) to hit fileSystemError mapping
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

        let result = sut.getCategoryInfo()
        switch result {
        case .failure(let e):
            #expect(e == .fileSystemError)
        case .success:
            Issue.record("Expected fileSystemError when root listing fails.")
        }
    }
}
