import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct AsyncOutfitPickerTests {

    // MARK: - Core async functionality tests

    @Test("async showRandomOutfit returns outfit from category")
    func asyncShowRandomOutfit_returnsOutfit() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    )
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let outfit = try await env.sut.showRandomOutfit(from: "Casual")

        #expect(outfit?.fileName == "outfit1.avatar")
        #expect(outfit?.category.name == "Casual")
    }

    @Test("async showRandomOutfit returns nil for empty category")
    func asyncShowRandomOutfit_returnsNilForEmpty() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Empty",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Empty",
                    directoryHint: .isDirectory
                ): [],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Empty",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let outfit = try await env.sut.showRandomOutfit(from: "Empty")
        #expect(outfit == nil)
    }

    @Test("async showRandomOutfitAcrossCategories returns outfit")
    func asyncShowRandomOutfitAcrossCategories_returnsOutfit() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    )
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let outfit = try await env.sut.showRandomOutfitAcrossCategories()

        #expect(outfit?.fileName == "outfit1.avatar")
        #expect(outfit?.category.name == "Casual")
    }

    @Test("async wearOutfit marks outfit as worn")
    func asyncWearOutfit_marksAsWorn() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    )
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let outfit = makeOutfitReference(
            root: "/Users/test/Outfits",
            category: "Casual",
            fileName: "outfit1.avatar"
        )

        try await env.sut.wearOutfit(outfit)

        // Verify it was saved
        #expect(env.cache.saved.count == 1)
    }

    @Test("async getAvailableCount returns correct count")
    func asyncGetAvailableCount_returnsCount() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    ),
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit2.avatar",
                        directoryHint: .notDirectory
                    ),
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let count = try await env.sut.getAvailableCount(for: "Casual")
        #expect(count == 2)
    }

    @Test("async resetCategory resets category cache")
    func asyncResetCategory_resetsCache() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    )
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        try await env.sut.resetCategory("Casual")

        #expect(env.cache.saved.count == 1)
    }

    @Test("async resetAllCategories resets all cache")
    func asyncResetAllCategories_resetsAll() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): []
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                )
            ]
        )

        try await env.sut.resetAllCategories()

        #expect(env.cache.saved.count == 1)
        #expect(env.cache.saved.first?.categories.isEmpty == true)
    }

    @Test("async partialReset resets partial cache")
    func asyncPartialReset_resetsPartial() async throws {
        let existingCache = OutfitCache(categories: [
            "Casual": CategoryCache(
                wornOutfits: ["outfit1.avatar", "outfit2.avatar"],
                totalOutfits: 2
            )
        ])

        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            cache: existingCache,
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    ),
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit2.avatar",
                        directoryHint: .notDirectory
                    )
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        try await env.sut.partialReset(categoryName: "Casual", wornCount: 1)

        #expect(env.cache.saved.count == 1)
    }

    @Test("async showAllOutfits returns all outfits")
    func asyncShowAllOutfits_returnsAll() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    ),
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit2.avatar",
                        directoryHint: .notDirectory
                    ),
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let outfits = try await env.sut.showAllOutfits(from: "Casual")

        #expect(outfits.count == 2)
        #expect(
            outfits.map(\.fileName).sorted() == [
                "outfit1.avatar", "outfit2.avatar",
            ]
        )
    }

    @Test("async getCategoryInfo returns category information")
    func asyncGetCategoryInfo_returnsInfo() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    )
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let categoryInfos = try await env.sut.getCategoryInfo()

        #expect(categoryInfos.count == 1)
        #expect(categoryInfos.first?.category.name == "Casual")
    }

    @Test("async getCategories returns category references")
    func asyncGetCategories_returnsCategories() async throws {
        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/Casual/outfit1.avatar",
                        directoryHint: .notDirectory
                    )
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/Casual",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let categories = try await env.sut.getCategories()

        #expect(categories.count == 1)
        #expect(categories.first?.name == "Casual")
    }

    @Test("async detectChanges detects filesystem changes")
    func asyncDetectChanges_detectsChanges() async throws {
        let config = try Config(
            root: "/Users/test/Outfits",
            language: "en",
            excludedCategories: [],
            knownCategories: ["Old"],
            knownCategoryFiles: ["Old": ["old.avatar"]]
        )

        let env = try makeOutfitPickerSUT(
            root: "/Users/test/Outfits",
            config: config,
            fileSystem: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/New",
                        directoryHint: .isDirectory
                    )
                ],
                URL(
                    filePath: "/Users/test/Outfits/New",
                    directoryHint: .isDirectory
                ): [
                    URL(
                        filePath: "/Users/test/Outfits/New/new.avatar",
                        directoryHint: .notDirectory
                    )
                ],
            ],
            directories: [
                URL(
                    filePath: "/Users/test/Outfits",
                    directoryHint: .isDirectory
                ),
                URL(
                    filePath: "/Users/test/Outfits/New",
                    directoryHint: .isDirectory
                ),
            ]
        )

        let changes = try await env.sut.detectChanges()

        #expect(changes.newCategories.contains("New"))
        #expect(changes.deletedCategories.contains("Old"))
    }

    // MARK: - Error handling tests

    @Test("async methods properly propagate errors")
    func asyncMethods_propagateErrors() async {
        let sut = makeOutfitPickerSUTWithConfigError(ConfigError.missingRoot)

        // Test key async methods throw errors appropriately
        do {
            _ = try await sut.showRandomOutfit(from: "Test")
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            _ = try await sut.showRandomOutfitAcrossCategories()
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            let outfit = makeOutfitReference(
                root: "/test",
                category: "Test",
                fileName: "test.avatar"
            )
            try await sut.wearOutfit(outfit)
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            _ = try await sut.getCategoryInfo()
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            _ = try await sut.getCategories()
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            _ = try await sut.getAvailableCount(for: "Test")
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            _ = try await sut.showAllOutfits(from: "Test")
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            _ = try await sut.detectChanges()
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            try await sut.resetCategory("Test")
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            try await sut.resetAllCategories()
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            try await sut.partialReset(categoryName: "Test", wornCount: 1)
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }

        do {
            let changes = CategoryChanges(
                newCategories: [],
                deletedCategories: [],
                changedCategories: [],
                addedFiles: [:],
                deletedFiles: [:]
            )
            try await sut.updateConfig(with: changes)
            #expect(Bool(false), "Should have thrown")
        } catch { #expect(error is OutfitPickerError) }
    }
}
