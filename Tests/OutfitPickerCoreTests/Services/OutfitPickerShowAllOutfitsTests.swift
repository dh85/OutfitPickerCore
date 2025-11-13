import Foundation
import Testing

@testable import OutfitPickerCore

@Suite
struct OutfitPickerShowAllOutfitsTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Happy paths

    @Test
    func showAllOutfits_returnsAllAvatars_sortedAndWithCategoryReference()
        throws
    {
        // Given
        let files = ["b.avatar", "a.avatar"]
        let (_, fs) = makeCategoryDir(
            root: root,
            name: "Club",
            files: files
        )

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.ok(fs))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        // When
        let result: OutfitPickerResult<[OutfitReference]> = sut.showAllOutfits(
            from: "Club"
        )
        let outfits = try result.get()

        // Then
        #expect(outfits.count == 2)

        // getAvatarFiles sorts by fileName ascending
        #expect(outfits[0].fileName == "a.avatar")
        #expect(outfits[1].fileName == "b.avatar")

        #expect(outfits[0].category.name == "Club")
        #expect(outfits[1].category.name == "Club")

        #expect(normPath(outfits[0].category.path) == "\(root)/Club")
        #expect(normPath(outfits[1].category.path) == "\(root)/Club")
    }

    @Test
    func showAllOutfits_returnsEmptyArray_whenNoAvatarFiles() throws {
        // Only non-avatar files in directory (filtered out by getAvatarFiles)
        let (_, fs) = makeCategoryDir(
            root: root,
            name: "Misc",
            files: ["photo.png", "readme.txt"]
        )

        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.ok(fs))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result: OutfitPickerResult<[OutfitReference]> = sut.showAllOutfits(
            from: "Misc"
        )
        let outfits = try result.get()

        #expect(outfits.isEmpty)
    }

    // MARK: - Error mapping

    @Test
    func showAllOutfits_configLoadFailure_mapsToInvalidConfiguration() {
        let configSvc = FakeConfigService(
            .throwsError(ConfigError.missingRoot)
        )
        let fm = FakeFileManager(.ok([:]))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result: OutfitPickerResult<[OutfitReference]> = sut.showAllOutfits(
            from: "Any"
        )

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
    func showAllOutfits_fileManagerFailure_mapsToFileSystemError() throws {
        let config = try Config(root: root, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.throwsError(FileSystemError.operationFailed))
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))

        let sut = OutfitPicker(
            configService: configSvc,
            cacheService: cacheSvc,
            fileManager: fm
        )

        let result: OutfitPickerResult<[OutfitReference]> = sut.showAllOutfits(
            from: "Any"
        )

        switch result {
        case .failure(let e):
            #expect(e == .fileSystemError)
        case .success:
            Issue.record(
                "Expected fileSystemError when directory listing fails."
            )
        }
    }
}
