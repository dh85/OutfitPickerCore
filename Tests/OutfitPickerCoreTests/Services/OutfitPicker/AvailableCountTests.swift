import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@Suite
struct AvailableCountTests {

    private let safeRoot = "/Users/test/Outfits"

    // MARK: - Success cases

    @Test
    func availableCount_noCache_returnsAllFiles() throws {
        let files = ["a.avatar", "b.avatar", "c.avatar"]
        let env = try makeOutfitPickerSUTWithCategory(
            category: "Club",
            files: files
        )

        let count = try env.sut.getAvailableCount(for: "Club").get()
        #expect(count == files.count)
    }

    @Test
    func availableCount_partialWorn_returnsRemaining() throws {
        let files = ["one.avatar", "two.avatar", "three.avatar"]
        let cache = OutfitCache(categories: [
            "Chic": CategoryCache(
                wornOutfits: ["one.avatar"],
                totalOutfits: files.count
            )
        ])

        let env = try makeOutfitPickerSUTWithCategory(
            category: "Chic",
            files: files,
            cache: cache
        )

        let count = try env.sut.getAvailableCount(for: "Chic").get()
        #expect(count == 2)  // 3 total, 1 worn → 2 remaining
    }

    @Test
    func availableCount_allWorn_rotationComplete_returnsTotal() throws {
        let files = ["x.avatar", "y.avatar"]
        let cache = OutfitCache(categories: [
            "Latex": CategoryCache(
                wornOutfits: Set(files),
                totalOutfits: files.count
            )
        ])

        let env = try makeOutfitPickerSUTWithCategory(
            category: "Latex",
            files: files,
            cache: cache
        )

        let count = try env.sut.getAvailableCount(for: "Latex").get()
        #expect(count == files.count)  // rotationComplete → count = files.count, not 0
    }

    @Test
    func availableCount_emptyDirectory_returnsZero() throws {
        let env = try makeOutfitPickerSUTWithCategory(
            category: "Empty",
            files: []
        )

        let count = try env.sut.getAvailableCount(for: "Empty").get()
        #expect(count == 0)
    }

    // MARK: - Error mapping

    @Test
    func availableCount_configLoadFailure_mapsToInvalidConfiguration() {
        let sut = makeOutfitPickerSUTWithConfigError(
            ConfigError.pathTraversalNotAllowed
        )
        let result = sut.getAvailableCount(for: "Any")

        switch result {
        case .failure(let e):
            #expect(e == .invalidConfiguration)
        case .success:
            Issue.record(
                "Expected invalidConfiguration when config load fails."
            )
        }
    }
}
