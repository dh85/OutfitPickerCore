import Foundation
import OutfitPickerTestSupport
import Testing

@testable import OutfitPickerCore

struct ReferenceAndProgressTests {

    // MARK: - CategoryReference

    @Test("CategoryReference.description is the name")
    func categoryReferenceDescription() {
        let c = CategoryReference(name: "casual", path: "/root/casual")
        #expect(c.description == "casual")
    }

    @Test("CategoryReference Equatable/Hashable semantics")
    func categoryReferenceHashable() {
        let a = CategoryReference(name: "casual", path: "/root/casual")
        let b = CategoryReference(name: "casual", path: "/root/casual")
        let c = CategoryReference(name: "formal", path: "/root/formal")

        #expect(a == b)
        #expect(a != c)

        var set = Set<CategoryReference>()
        set.insert(a)
        set.insert(b)  // should not duplicate
        set.insert(c)
        #expect(set.count == 2)
    }

    // MARK: - OutfitReference

    @Test("OutfitReference.filePath joins dir + filename")
    func outfitReferenceFilePath() {
        let o1 = OutfitReference(
            fileName: "shirt.avatar",
            category: .init(name: "casual", path: "/test/path")
        )
        #expect(o1.filePath == "/test/path/shirt.avatar")
    }

    @Test("OutfitReference.filePath handles trailing slash on dir")
    func outfitReferenceFilePathWithTrailingSlash() {
        let o = OutfitReference(
            fileName: "jeans.avatar",
            category: .init(name: "casual", path: "/test/path/")
        )
        #expect(o.filePath == "/test/path/jeans.avatar")
    }

    @Test("OutfitReference.description is “fileName in categoryName”")
    func outfitReferenceDescription() {
        let o = OutfitReference(
            fileName: "shirt.avatar",
            category: .init(name: "casual", path: "/test/path")
        )
        #expect(o.description == "shirt.avatar in casual")
    }

    @Test("OutfitReference Equatable/Hashable semantics")
    func outfitReferenceHashable() {
        let cat = CategoryReference(name: "casual", path: "/root/casual")
        let a = OutfitReference(fileName: "a.avatar", category: cat)
        let b = OutfitReference(fileName: "a.avatar", category: cat)
        let c = OutfitReference(fileName: "b.avatar", category: cat)

        #expect(a == b)
        #expect(a != c)

        var set = Set<OutfitReference>()
        set.insert(a)
        set.insert(b)  // same -> dedupe
        set.insert(c)
        #expect(set.count == 2)
    }

    // MARK: - SelectionTarget (light smoke tests)

    @Test("SelectionTarget cases pattern-match correctly")
    func selectionTargetPatternMatch() {
        let cat = CategoryReference(name: "casual", path: "/root/casual")
        let t1: SelectionTarget = .category(cat)
        let t2: SelectionTarget = .allCategories
        let t3: SelectionTarget = .categories([cat])

        switch t1 {
        case .category(let c):
            #expect(c == cat)
        default:
            Issue.record("Expected .category case, got \(t1)")
        }

        switch t2 {
        case .allCategories:
            #expect(true)
        default:
            Issue.record("Expected .allCategories case, got \(t2)")
        }

        switch t3 {
        case .categories(let cs):
            #expect(cs == [cat])
        default:
            Issue.record("Expected .categories case, got \(t3)")
        }
    }

    // MARK: - RotationProgress

    @Test("RotationProgress.progress basic cases")
    func rotationProgress() {
        let cat = CategoryReference(name: "x", path: "/x")

        // Normal fraction
        let p1 = RotationProgress(
            category: cat,
            wornCount: 2,
            totalOutfitCount: 4,
            isComplete: false
        )
        #expect(p1.progress == 0.5)

        // totalOutfitCount == 0 => 1.0 (defined behavior)
        let p2 = RotationProgress(
            category: cat,
            wornCount: 2,
            totalOutfitCount: 0,
            isComplete: false
        )
        #expect(p2.progress == 1.0)

        // Negative total => 1.0 (because totalOutfitCount > 0 fails)
        let p3 = RotationProgress(
            category: cat,
            wornCount: 2,
            totalOutfitCount: -1,
            isComplete: false
        )
        #expect(p3.progress == 1.0)

        // Worn > total => progress can exceed 1.0 (document current behavior)
        let p4 = RotationProgress(
            category: cat,
            wornCount: 6,
            totalOutfitCount: 4,
            isComplete: false
        )
        #expect(p4.progress == 1.5)
    }

    @Test("RotationProgress.availableCount respects isComplete flag")
    func rotationAvailableCount() {
        let cat = CategoryReference(name: "x", path: "/x")

        // Complete: available == total
        let c1 = RotationProgress(
            category: cat,
            wornCount: 4,
            totalOutfitCount: 4,
            isComplete: true
        )
        #expect(c1.availableCount == 4)

        // Incomplete: total - worn
        let c2 = RotationProgress(
            category: cat,
            wornCount: 3,
            totalOutfitCount: 4,
            isComplete: false
        )
        #expect(c2.availableCount == 1)

        // Edge: worn > total and not marked complete -> negative (document current behavior)
        let c3 = RotationProgress(
            category: cat,
            wornCount: 5,
            totalOutfitCount: 4,
            isComplete: false
        )
        #expect(c3.availableCount == -1)
    }
}
