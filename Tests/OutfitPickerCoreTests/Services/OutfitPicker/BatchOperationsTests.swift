import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

@Suite
struct BatchOperationsTests {
    private let safeRoot = "/Users/test/Outfits"

    // MARK: - wearOutfits Tests

    @Test func wearOutfits_WithMultipleOutfits_MarksAllAsWorn() async throws {
        let config = try Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        
        let (dirA, mapA) = makeCategoryDir(root: safeRoot, name: "A", files: ["outfit1.avatar", "outfit2.avatar"])
        let (dirB, mapB) = makeCategoryDir(root: safeRoot, name: "B", files: ["outfit3.avatar"])
        
        var allMaps = mapA
        allMaps.merge(mapB) { _, new in new }
        
        let fm = FakeFileManager(.ok(allMaps), directories: [dirA, dirB])
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        
        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)
        
        let outfits = [
            makeOutfitReference(root: safeRoot, category: "A", fileName: "outfit1.avatar"),
            makeOutfitReference(root: safeRoot, category: "A", fileName: "outfit2.avatar"),
            makeOutfitReference(root: safeRoot, category: "B", fileName: "outfit3.avatar")
        ]
        
        try await sut.wearOutfits(outfits)
        
        let savedCache = try #require(cacheSvc.saved.first)
        #expect(savedCache.categories["A"]?.wornOutfits == ["outfit1.avatar", "outfit2.avatar"])
        #expect(savedCache.categories["B"]?.wornOutfits == ["outfit3.avatar"])
    }

    @Test func wearOutfits_WithAlreadyWornOutfits_DoesNotDuplicate() async throws {
        let config = try Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        
        let (dir, map) = makeCategoryDir(root: safeRoot, name: "A", files: ["outfit1.avatar", "outfit2.avatar"])
        let fm = FakeFileManager(.ok(map), directories: [dir])
        
        let existingCache = OutfitCache(categories: [
            "A": CategoryCache(wornOutfits: ["outfit1.avatar"], totalOutfits: 2)
        ])
        let cacheSvc = FakeCacheService(.ok(existingCache))
        
        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)
        
        let outfits = [
            makeOutfitReference(root: safeRoot, category: "A", fileName: "outfit1.avatar"),
            makeOutfitReference(root: safeRoot, category: "A", fileName: "outfit2.avatar")
        ]
        
        try await sut.wearOutfits(outfits)
        
        let savedCache = try #require(cacheSvc.saved.first)
        #expect(savedCache.categories["A"]?.wornOutfits == ["outfit1.avatar", "outfit2.avatar"])
    }

    @Test func wearOutfits_WithEmptyArray_DoesNothing() async throws {
        let config = try Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.ok([:]), directories: [])
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        
        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)
        
        try await sut.wearOutfits([])
        
        let savedCache = try #require(cacheSvc.saved.first)
        #expect(savedCache.categories.isEmpty)
    }

    @Test func wearOutfits_WithConfigError_ThrowsOutfitPickerError() async {
        let configSvc = FakeConfigService(.throwsError(ConfigError.pathTraversalNotAllowed))
        let fm = FakeFileManager(.ok([:]), directories: [])
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        
        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)
        
        let outfits = [makeOutfitReference(root: safeRoot, category: "A", fileName: "outfit1.avatar")]
        
        do {
            try await sut.wearOutfits(outfits)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }

    // MARK: - resetCategories Tests

    @Test func resetCategories_WithMultipleCategories_ResetsAll() async throws {
        let config = try Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.ok([:]), directories: [])
        
        let existingCache = OutfitCache(categories: [
            "A": CategoryCache(wornOutfits: ["outfit1.avatar"], totalOutfits: 2),
            "B": CategoryCache(wornOutfits: ["outfit2.avatar"], totalOutfits: 1),
            "C": CategoryCache(wornOutfits: ["outfit3.avatar"], totalOutfits: 3)
        ])
        let cacheSvc = FakeCacheService(.ok(existingCache))
        
        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)
        
        try await sut.resetCategories(["A", "C"])
        
        let savedCache = try #require(cacheSvc.saved.first)
        #expect(savedCache.categories["A"]?.wornOutfits == Set<String>())
        #expect(savedCache.categories["A"]?.totalOutfits == 0)
        #expect(savedCache.categories["B"]?.wornOutfits == ["outfit2.avatar"])
        #expect(savedCache.categories["C"]?.wornOutfits == Set<String>())
        #expect(savedCache.categories["C"]?.totalOutfits == 0)
    }

    @Test func resetCategories_WithEmptyArray_DoesNothing() async throws {
        let config = try Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.ok([:]), directories: [])
        
        let existingCache = OutfitCache(categories: [
            "A": CategoryCache(wornOutfits: ["outfit1.avatar"], totalOutfits: 2)
        ])
        let cacheSvc = FakeCacheService(.ok(existingCache))
        
        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)
        
        try await sut.resetCategories([])
        
        let savedCache = try #require(cacheSvc.saved.first)
        #expect(savedCache.categories["A"]?.wornOutfits == ["outfit1.avatar"])
    }

    @Test func resetCategories_WithNonExistentCategories_CreatesEmptyCache() async throws {
        let config = try Config(root: safeRoot, language: "en")
        let configSvc = FakeConfigService(.ok(config))
        let fm = FakeFileManager(.ok([:]), directories: [])
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        
        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)
        
        try await sut.resetCategories(["NonExistent"])
        
        let savedCache = try #require(cacheSvc.saved.first)
        #expect(savedCache.categories["NonExistent"]?.wornOutfits == Set<String>())
        #expect(savedCache.categories["NonExistent"]?.totalOutfits == 0)
    }

    @Test func resetCategories_WithConfigError_ThrowsOutfitPickerError() async {
        let configSvc = FakeConfigService(.throwsError(ConfigError.pathTraversalNotAllowed))
        let fm = FakeFileManager(.ok([:]), directories: [])
        let cacheSvc = FakeCacheService(.ok(OutfitCache()))
        
        let sut = OutfitPicker(configService: configSvc, cacheService: cacheSvc, fileManager: fm)
        
        do {
            try await sut.resetCategories(["A"])
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is OutfitPickerError)
        }
    }
}