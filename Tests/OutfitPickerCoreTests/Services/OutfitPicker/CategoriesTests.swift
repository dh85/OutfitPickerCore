import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct CategoriesTests {

    private let root = "/Users/test/Outfits"

    @Test func returnsNonExcludedCategories_sortedByName() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "B": ["b.avatar"],
                "A": ["a.avatar"],
                "Excluded": ["ex.avatar"],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            config: try Config(
                root: root,
                language: "en",
                excludedCategories: ["Excluded"]
            ),
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let categories = try await env.sut.getCategories()

        #expect(categories.count == 2)
        #expect(categories.map { $0.name } == ["A", "B"])
        #expect(normPath(categories[0].path) == "\(root)/A")
        #expect(normPath(categories[1].path) == "\(root)/B")
    }

    @Test func returnsEmpty_whenNoDirectoriesExist() async throws {
        let env = try makeOutfitPickerSUT(root: root)
        let categories = try await env.sut.getCategories()
        #expect(categories.isEmpty)
    }

    @Test func includesEmptyAndNoAvatarCategories_excludesUserExcluded() async throws {
        let fs = makeFS(
            root: root,
            categories: [
                "Empty": [],
                "NoAvatar": ["readme.txt"],
                "Good": ["g.avatar"],
                "Excluded": ["ex.avatar"],
            ]
        )

        let env = try makeOutfitPickerSUT(
            root: root,
            config: try Config(
                root: root,
                language: "en",
                excludedCategories: ["Excluded"]
            ),
            fileSystem: fs.contents,
            directories: Array(fs.directories)
        )

        let categories = try await env.sut.getCategories()
        #expect(categories.count == 1)
        #expect(categories[0].name == "Good")
    }

    @Test
    func mapsConfigLoadFailure_toInvalidConfiguration() async {
        let sut = makeOutfitPickerSUTWithConfigError(
            ConfigError.pathTraversalNotAllowed
        )
        
        do {
            _ = try await sut.getCategories()
            Issue.record("Expected invalidConfiguration")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    @Test
    func mapsFileManagerFailureInsideCategoryInfo_toFileSystemError() async throws {
        let sut = try makeOutfitPickerSUTWithFileSystemError(
            FileSystemError.operationFailed
        )
        
        do {
            _ = try await sut.getCategories()
            Issue.record("Expected fileSystemError")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}