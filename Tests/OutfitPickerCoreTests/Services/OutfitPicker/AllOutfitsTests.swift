import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct AllOutfitsTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Happy paths

    @Test
    func showAllOutfits_returnsAllAvatars_sortedAndWithCategoryReference()
        throws
    {
        let files = ["b.avatar", "a.avatar"]
        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: "Club",
            files: files
        )

        let outfits = try env.sut.showAllOutfits(from: "Club").get()

        #expect(outfits.count == 2)
        #expect(outfits[0].fileName == "a.avatar")  // sorted ascending
        #expect(outfits[1].fileName == "b.avatar")
        #expect(outfits[0].category.name == "Club")
        #expect(normPath(outfits[0].category.path) == "\(root)/Club")
    }

    @Test
    func showAllOutfits_returnsEmptyArray_whenNoAvatarFiles() throws {
        let env = try makeOutfitPickerSUTWithCategory(
            root: root,
            category: "Misc",
            files: ["photo.png", "readme.txt"]  // non-avatar files
        )

        let outfits = try env.sut.showAllOutfits(from: "Misc").get()
        #expect(outfits.isEmpty)
    }

    // MARK: - Error mapping

    @Test
    func showAllOutfits_configLoadFailure_mapsToInvalidConfiguration() {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)
        let result = sut.showAllOutfits(from: "Any")

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
        let sut = try makeOutfitPickerSUTWithFileSystemError(
            FileSystemError.operationFailed
        )
        let result = sut.showAllOutfits(from: "Any")

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
