import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct CategoryTests {

    // MARK: - Helpers

    private func expectedName(forDirectoryPath path: String) -> String {
        URL(filePath: path, directoryHint: .isDirectory).lastPathComponent
    }

    private func expectedCategoryPath(forFilePath path: String) -> String {
        URL(filePath: path, directoryHint: .notDirectory)
            .deletingLastPathComponent()
            .path(percentEncoded: false)
    }

    private func expectedFileName(forFilePath path: String) -> String {
        URL(filePath: path, directoryHint: .notDirectory).lastPathComponent
    }

    // MARK: - Category.name

    @Test("Category name extraction (platform-specific)")
    func categoryNameExtraction() {
        #if os(Windows)
        let cases: [(path: String, expected: String)] = [
            ("C:\\Users\\John\\outfits\\casual", "casual"),
            ("C:/Users/John/outfits/formal", "formal"),
            ("\\\\server\\share\\outfits\\summer", "summer"),
            ("C:\\single", "single"),
            ("noseparator", "noseparator"),
            ("C:\\Users\\John Doe\\My Outfits\\posh leather", "posh leather"),
            ("C:\\Users\\John\\outfits\\casual\\", "casual"), // trailing slash
        ]
        #else
        let cases: [(path: String, expected: String)] = [
            ("/Users/john/outfits/casual", "casual"),
            ("/home/user/clothes/formal", "formal"),
            (".outfits/summer", "summer"),
            ("relative/path/winter", "winter"),
            ("/single", "single"),
            ("noseparator", "noseparator"),
            ("/Users/john doe/My Outfits/posh leather", "posh leather"),
            ("/Users/john/outfits/casual/", "casual"), // trailing slash
        ]
        #endif

        for (path, expected) in cases {
            let category = Category(path: path, outfits: [])
            #expect(category.name == expected)
            // also verify against Foundation's parsing
            #expect(category.name == expectedName(forDirectoryPath: path))
        }
    }

    // MARK: - FileEntry basics (categoryPath, fileName, categoryName)

    @Test("FileEntry properties (platform-specific)")
    func fileEntryProperties() {
        #if os(Windows)
        let cases: [(filePath: String, expectedDir: String, expectedFile: String, expectedName: String)] = [
            ("C:\\Users\\John\\outfits\\casual\\outfit1.avatar",
             "C:\\Users\\John\\outfits\\casual",
             "outfit1.avatar", "casual"),
            ("C:/Users/John/outfits/formal/suit.avatar",
             "C:/Users/John/outfits/formal",
             "suit.avatar", "formal"),
            ("\\\\server\\share\\outfits\\summer\\shorts.avatar",
             "\\\\server\\share\\outfits\\summer",
             "shorts.avatar", "summer"),
        ]
        #else
        let cases: [(filePath: String, expectedDir: String, expectedFile: String, expectedName: String)] = [
            ("/Users/john/outfits/casual/outfit1.avatar",
             "/Users/john/outfits/casual/", "outfit1.avatar", "casual"),
            ("/home/user/clothes/formal/suit.avatar",
             "/home/user/clothes/formal/", "suit.avatar", "formal"),
            ("/Users/john doe/My Outfits/summer clothes/blue shirt.avatar",
             "/Users/john doe/My Outfits/summer clothes/", "blue shirt.avatar", "summer clothes"),
            ("relative/path/winter/wool.avatar",
             "relative/path/winter/", "wool.avatar", "winter"),
        ]
        #endif

        for c in cases {
            let entry = FileEntry(filePath: c.filePath)
            let expectedDir = expectedCategoryPath(forFilePath: c.filePath)
            #expect(entry.categoryPath == expectedDir)
            #expect(entry.fileName == c.expectedFile)
            #expect(entry.categoryName == c.expectedName)
            // cross-check via Foundation derivation
            #expect(entry.categoryPath == expectedCategoryPath(forFilePath: c.filePath))
            #expect(entry.fileName == expectedFileName(forFilePath: c.filePath))
            #expect(entry.categoryName == expectedName(forDirectoryPath: entry.categoryPath))
        }
    }

    // MARK: - Additional focused checks

    @Test
    func categoryName_fromFileEntry() {
        #if os(Windows)
        let entry = FileEntry(filePath: "C:\\outfits\\casual\\shirt.avatar")
        #else
        let entry = FileEntry(filePath: "/outfits/casual/shirt.avatar")
        #endif
        #expect(entry.categoryName == "casual")
    }

    @Test
    func categoryPath_fromFileEntry() {
        #if os(Windows)
        let entry = FileEntry(filePath: "C:\\outfits\\casual\\shirt.avatar")
        let expected = "C:\\outfits\\casual"
        #else
        let entry = FileEntry(filePath: "/outfits/casual/shirt.avatar")
        let expected = "/outfits/casual/"
        #endif
        #expect(entry.categoryPath == expected)
    }

    @Test
    func unicodeAndSpacesArePreserved() {
        #if os(Windows)
        let dir = "C:\\Users\\Jöhn Dœ\\My Outfits\\春 夏"
        let file = dir + "\\花 avatar.avatar"
        #else
        let dir = "/Users/jöhn døe/My Outfits/春 夏"
        let file = dir + "/花 avatar.avatar"
        #endif

        let category = Category(path: dir, outfits: [])
        #expect(category.name == expectedName(forDirectoryPath: dir))

        let entry = FileEntry(filePath: file)
        #expect(entry.categoryPath == expectedCategoryPath(forFilePath: file))
        #expect(entry.fileName == expectedFileName(forFilePath: file))
        #expect(entry.categoryName == expectedName(forDirectoryPath: entry.categoryPath))
    }
}
