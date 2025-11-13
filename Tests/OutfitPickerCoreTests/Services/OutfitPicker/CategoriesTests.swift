import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct CategoriesTests {

    private let root = "/Users/test/Outfits"

    // MARK: - Success cases

    @Test
    func returnsCategoryReferences_sorted_andMatchingPaths() throws {
        let fs = makeFS(root: root, categories: [
            "B": ["b.avatar"],  // deliberately unordered
            "A": ["a.avatar"]
        ])
        
        let env = try makeOutfitPickerSUT(
            root: root,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let categories = try env.sut.getCategories().get()

        #expect(categories.count == 2)
        #expect(categories.map(\.name) == ["A", "B"])
        #expect(normPath(categories[0].path) == "\(root)/A")
        #expect(normPath(categories[1].path) == "\(root)/B")
    }

    @Test
    func returnsEmpty_whenNoDirectoriesExist() throws {
        let env = try makeOutfitPickerSUT(root: root)
        let categories = try env.sut.getCategories().get()
        #expect(categories.isEmpty)
    }

    @Test
    func excludesUserExcludedCategories() throws {
        let fs = makeFS(root: root, categories: [
            "Excluded": [],
            "Good": ["g.avatar"]
        ])
        
        let config = try Config(root: root, language: "en", excludedCategories: ["Excluded"])
        let env = try makeOutfitPickerSUT(
            root: root,
            config: config,
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let categories = try env.sut.getCategories().get()
        #expect(categories.count == 1)
        #expect(categories[0].name == "Good")
    }

    // MARK: - Error mapping

    @Test
    func mapsConfigLoadFailure_toInvalidConfiguration() {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.pathTraversalNotAllowed)
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
        let sut = try makeOutfitPickerSUTWithFileSystemError(FileSystemError.operationFailed)
        let result = sut.getCategories()

        switch result {
        case .failure(let e):
            #expect(e == .fileSystemError)
        case .success:
            Issue.record("Expected fileSystemError")
        }
    }
}
