import Foundation
import Testing

@testable import OutfitPickerCore

struct CacheTests {

    // MARK: - CategoryCache: Business Logic

    @Test(
        "Rotation completion",
        arguments: [
            (worn: 0, total: 5, complete: false),
            (worn: 3, total: 5, complete: false),
            (worn: 5, total: 5, complete: true),
            (worn: 6, total: 5, complete: true),
            (worn: 0, total: 0, complete: true),
        ]
    )
    func rotationCompletion(worn: Int, total: Int, complete: Bool) {
        let cache = makeCache(worn: worn, total: total)
        #expect(cache.isRotationComplete == complete)
    }

    @Test(
        "Rotation progress",
        arguments: [
            (worn: 0, total: 10, progress: 0.0),
            (worn: 3, total: 10, progress: 0.3),
            (worn: 5, total: 10, progress: 0.5),
            (worn: 10, total: 10, progress: 1.0),
            (worn: 0, total: 0, progress: 1.0),
        ]
    )
    func rotationProgress(worn: Int, total: Int, progress: Double) {
        let cache = makeCache(worn: worn, total: total)
        #expect(abs(cache.rotationProgress - progress) < 0.001)
    }

    @Test(
        "Remaining outfits",
        arguments: [
            (worn: 0, total: 5, remaining: 5),
            (worn: 3, total: 5, remaining: 2),
            (worn: 5, total: 5, remaining: 0),
            (worn: 7, total: 5, remaining: 0),
        ]
    )
    func remainingOutfits(worn: Int, total: Int, remaining: Int) {
        let cache = makeCache(worn: worn, total: total)
        #expect(cache.remainingOutfits == remaining)
    }

    @Test func addingNewFileAddsAndUpdatesTimestamp() {
        let before = Date(timeIntervalSince1970: 1_000)
        let original = CategoryCache(
            wornOutfits: ["a.avatar", "b.avatar"],
            totalOutfits: 5,
            lastUpdated: before
        )

        let updated = original.adding("c.avatar")

        #expect(updated.wornOutfits.count == 3)
        #expect(updated.wornOutfits.contains("c.avatar"))
        #expect(updated.totalOutfits == original.totalOutfits)
        // lastUpdated should be refreshed
        #expect(updated.lastUpdated >= before)
    }

    @Test func addingExistingFileKeepsSetSize() {
        let original = makeCache(worn: 2, total: 5) // contains outfit0, outfit1
        let updated = original.adding("outfit1.avatar")

        #expect(updated.wornOutfits == original.wornOutfits)
        #expect(updated.totalOutfits == original.totalOutfits)
    }

    @Test func resetCacheClearsWornAndKeepsTotals() {
        let original = makeCache(worn: 3, total: 5)
        let reset = original.reset()

        #expect(reset.wornOutfits.isEmpty)
        #expect(reset.totalOutfits == original.totalOutfits)
        #expect(!reset.isRotationComplete)
    }

    // MARK: - OutfitCache: Mutations & Value Semantics

    @Test func updatingExistingCategoryReplacesValueAndPreservesHeader() {
        let fixed = Date(timeIntervalSince1970: 2_000_000)
        let categoryCache = makeCache(worn: 2, total: 5, date: fixed)
        let original = OutfitCache(
            categories: ["/casual": categoryCache],
            version: 7,
            createdAt: fixed
        )
        let newCache = makeCache(worn: 3, total: 5, date: fixed)

        let updated = original.updating(category: "/casual", with: newCache)

        #expect(updated.categories["/casual"] == newCache)
        #expect(updated.version == original.version)
        #expect(updated.createdAt == original.createdAt)
        // Original remains unchanged
        #expect(original.categories["/casual"] == categoryCache)
    }

    @Test func updatingNewCategoryInsertsAndDoesNotMutateOriginal() {
        let original = OutfitCache()
        let newCache = makeCache(worn: 1, total: 3)

        let updated = original.updating(category: "/formal", with: newCache)

        #expect(updated.categories.count == 1)
        #expect(updated.categories["/formal"] == newCache)
        #expect(original.categories.isEmpty) // original untouched
    }

    @Test func resetAllResetsEachCategoryAndPreservesHeader() {
        let fixed = Date(timeIntervalSince1970: 3_000_000)
        let cache1 = makeCache(worn: 3, total: 5, date: fixed)
        let cache2 = makeCache(worn: 2, total: 4, date: fixed)
        let original = OutfitCache(
            categories: ["/casual": cache1, "/formal": cache2],
            version: 2,
            createdAt: fixed
        )

        let reset = original.resetAll()

        #expect(reset.categories["/casual"]?.wornOutfits.isEmpty == true)
        #expect(reset.categories["/formal"]?.wornOutfits.isEmpty == true)
        #expect(reset.categories["/casual"]?.totalOutfits == 5)
        #expect(reset.categories["/formal"]?.totalOutfits == 4)
        #expect(reset.version == original.version)
        #expect(reset.createdAt == original.createdAt)
        // Original untouched
        #expect(original.categories["/casual"]?.wornOutfits.count == 3)
    }

    @Test func removingExistingCategoryRemovesOnlyThatKey() {
        let c1 = CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 3)
        let c2 = CategoryCache(wornOutfits: ["suit.avatar"], totalOutfits: 2)
        let cache = OutfitCache(categories: ["/casual": c1, "/formal": c2])

        let updated = cache.removing(category: "/formal")

        #expect(updated.categories.count == 1)
        #expect(updated.categories["/casual"] == c1)
        #expect(updated.categories["/formal"] == nil)
        // Original untouched
        #expect(cache.categories.count == 2)
    }

    @Test func removingNonexistentCategoryIsNoOp() {
        let c1 = CategoryCache(wornOutfits: ["shirt.avatar"], totalOutfits: 3)
        let cache = OutfitCache(categories: ["/casual": c1])

        let updated = cache.removing(category: "/missing")

        #expect(updated.categories == cache.categories)
    }

    @Test func resettingCategoryResetsOnlyThatCategory() {
        let categoryCache = CategoryCache(
            wornOutfits: ["shirt.avatar", "jeans.avatar"],
            totalOutfits: 5
        )
        let cache = OutfitCache(categories: ["/casual": categoryCache])

        let reset = cache.resetting(category: "/casual")

        #expect(cache.categories["/casual"]?.wornOutfits.count == 2) // original unchanged
        #expect(reset?.categories["/casual"]?.wornOutfits.isEmpty == true)
        #expect(reset?.categories["/casual"]?.totalOutfits == 5)
    }

    @Test func resettingMissingCategoryReturnsNil() {
        let cache = OutfitCache(categories: [:])
        #expect(cache.resetting(category: "/invalid") == nil)
    }

    // MARK: - JSON Serialization

    @Test func categoryCacheJSONRoundTrip() throws {
        let original = CategoryCache(
            wornOutfits: ["outfit1.avatar", "outfit2.avatar"],
            totalOutfits: 5,
            lastUpdated: Date(timeIntervalSince1970: 1_000_000)
        )

        let decoded: CategoryCache = try roundTrip(original)

        #expect(decoded.wornOutfits == original.wornOutfits)
        #expect(decoded.totalOutfits == original.totalOutfits)
        // tolerate minor encoding precision differences
        #expect(abs(decoded.lastUpdated.timeIntervalSince1970 - original.lastUpdated.timeIntervalSince1970) < 1.0)
    }

    @Test func outfitCacheJSONRoundTrip() throws {
        let cat = CategoryCache(
            wornOutfits: ["test.avatar"],
            totalOutfits: 3,
            lastUpdated: Date(timeIntervalSince1970: 2_000_000)
        )
        let original = OutfitCache(
            categories: ["/casual": cat],
            version: 2,
            createdAt: Date(timeIntervalSince1970: 2_000_000)
        )

        let decoded: OutfitCache = try roundTrip(original)

        #expect(decoded.categories.count == 1)
        #expect(decoded.categories["/casual"] == cat)
        #expect(decoded.version == 2)
        #expect(abs(decoded.createdAt.timeIntervalSince1970 - original.createdAt.timeIntervalSince1970) < 1.0)
    }

    @Test func emptyOutfitCacheJSONRoundTrip() throws {
        let original = OutfitCache()
        let decoded: OutfitCache = try roundTrip(original)

        #expect(decoded.categories.isEmpty)
        #expect(decoded.version == original.version)
    }

    // MARK: - Helpers

    private func makeCache(worn: Int, total: Int, date: Date = Date()) -> CategoryCache {
        let outfits = Set((0..<worn).map { "outfit\($0).avatar" })
        return CategoryCache(wornOutfits: outfits, totalOutfits: total, lastUpdated: date)
    }

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
