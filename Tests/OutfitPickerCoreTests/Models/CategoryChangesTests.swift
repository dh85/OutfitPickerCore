import Foundation
import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct CategoryChangesTests {

    // MARK: - hasChanges / isEmpty logic

    @Test("hasChanges and isEmpty reflect the correct state")
    func hasChangesAndIsEmpty() {
        // No changes at all
        let none = CategoryChanges()
        #expect(!none.hasChanges)
        #expect(none.isEmpty)

        // Only new
        let newOnly = CategoryChanges(newCategories: ["casual"])
        #expect(newOnly.hasChanges)
        #expect(!newOnly.isEmpty)

        // Only deleted
        let deletedOnly = CategoryChanges(deletedCategories: ["formal"])
        #expect(deletedOnly.hasChanges)
        #expect(!deletedOnly.isEmpty)

        // Only changed
        let changedOnly = CategoryChanges(changedCategories: ["summer"])
        #expect(changedOnly.hasChanges)
        #expect(!changedOnly.isEmpty)

        // Mixed changes
        let mixed = CategoryChanges(
            newCategories: ["casual"],
            deletedCategories: ["formal"],
            changedCategories: ["summer"]
        )
        #expect(mixed.hasChanges)
        #expect(!mixed.isEmpty)
    }

    // MARK: - Property immutability and equality semantics

    @Test("Stored properties are immutable and preserve given sets")
    func propertyIntegrity() {
        let newSet: Set<String> = ["casual", "formal"]
        let deletedSet: Set<String> = ["beach"]
        let changedSet: Set<String> = ["winter"]

        let changes = CategoryChanges(
            newCategories: newSet,
            deletedCategories: deletedSet,
            changedCategories: changedSet
        )

        #expect(changes.newCategories == newSet)
        #expect(changes.deletedCategories == deletedSet)
        #expect(changes.changedCategories == changedSet)

        // Ensure immutability by verifying they are distinct value copies
        var copy = changes
        copy = CategoryChanges(newCategories: ["different"])
        #expect(copy.newCategories != changes.newCategories)
    }

    // MARK: - Convenience computed property symmetry

    @Test("isEmpty is the inverse of hasChanges")
    func isEmptyIsInverseOfHasChanges() {
        let examples: [CategoryChanges] = [
            .init(),
            .init(newCategories: ["a"]),
            .init(deletedCategories: ["b"]),
            .init(changedCategories: ["c"]),
            .init(newCategories: ["x"], deletedCategories: ["y"], changedCategories: ["z"]),
        ]

        for c in examples {
            #expect(c.isEmpty == !c.hasChanges)
        }
    }
}
