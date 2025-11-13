import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct OutfitPickerGetCategoriesTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Success cases

    @Test
    func returnsCategoryReferences_sorted_andMatchingPaths() throws {
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)

        let aURL = rootURL.appending(path: "A", directoryHint: .isDirectory)
        let bURL = rootURL.appending(path: "B", directoryHint: .isDirectory)

        let aAvatar = aURL.appending(path: "a.avatar", directoryHint: .notDirectory)
        let bAvatar = bURL.appending(path: "b.avatar", directoryHint: .notDirectory)

        let fs: [URL: [URL]] = [
            rootURL: [bURL, aURL],           // deliberately unordered
            aURL: [aAvatar],
            bURL: [bAvatar]
        ]

        let directories = [rootURL, aURL, bURL]

        let fm = FakeFileManager(.ok(fs), directories: directories)
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)

        let result = sut.getCategories()
        let categories = try result.get()

        #expect(categories.count == 2)
        #expect(categories.map(\.name) == ["A", "B"])
        #expect(categories[0].path == aURL.path(percentEncoded: false))
        #expect(categories[1].path == bURL.path(percentEncoded: false))
    }

    @Test
    func returnsEmpty_whenNoDirectoriesExist() throws {
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)
        let fm = FakeFileManager(.ok([rootURL: []]), directories: [])

        let config = try Config(root: root, language: "en")
        let sut = OutfitPicker(
            configService: FakeConfigService(.ok(config)),
            cacheService: FakeCacheService(.ok(OutfitCache())),
            fileManager: fm
        )

        let result = sut.getCategories()
        let categories = try result.get()

        #expect(categories.isEmpty)
    }

    @Test
    func excludesUserExcludedCategories() throws {
        let rootURL = URL(filePath: root, directoryHint: .isDirectory)

        let exURL = rootURL.appending(path: "Excluded", directoryHint: .isDirectory)
        let goodURL = rootURL.appending(path: "Good", directoryHint: .isDirectory)

        let goodAvatar = goodURL.appending(path: "g.avatar", directoryHint: .notDirectory)

        let fs: [URL: [URL]] = [
            rootURL: [exURL, goodURL],
            exURL: [],
            goodURL: [goodAvatar]
        ]
        let directories = [rootURL, exURL, goodURL]

        let config = try Config(root: root, language: "en", excludedCategories: ["Excluded"])
        let sut = OutfitPicker(
            configService: FakeConfigService(.ok(config)),
            cacheService: FakeCacheService(.ok(OutfitCache())),
            fileManager: FakeFileManager(.ok(fs), directories: directories)
        )

        let result = sut.getCategories()
        let categories = try result.get()

        #expect(categories.count == 1)
        #expect(categories[0].name == "Good")
    }

    // MARK: - Error mapping

    @Test
    func mapsConfigLoadFailure_toInvalidConfiguration() {
        let configSvc = FakeConfigService(.throwsError(ConfigError.pathTraversalNotAllowed))
        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: FakeCacheService(.ok(OutfitCache())),
            fileManager: FakeFileManager(.ok([:]), directories: [])
        )

        let result = sut.getCategories()

        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record("Expected invalidConfiguration")
        }
    }

    @Test
    func mapsFileManagerFailureInsideCategoryInfo_toFileSystemError() throws {
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: FakeCacheService(.ok(OutfitCache())),
            fileManager: FakeFileManager(
                .throwsError(FileSystemError.operationFailed),
                directories: []
            )
        )

        let result = sut.getCategories()

        switch result {
        case .failure(let e):
            #expect(e == .fileSystemError)
        case .success:
            Issue.record("Expected fileSystemError")
        }
    }
}
