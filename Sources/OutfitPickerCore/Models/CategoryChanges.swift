import Foundation

public struct CategoryChanges: Sendable {
    public let newCategories: Set<String>
    public let deletedCategories: Set<String>
    public let changedCategories: Set<String>
    public let addedFiles: [String: Set<String>]
    public let deletedFiles: [String: Set<String>]

    public init(
        newCategories: Set<String> = [],
        deletedCategories: Set<String> = [],
        changedCategories: Set<String> = [],
        addedFiles: [String: Set<String>] = [:],
        deletedFiles: [String: Set<String>] = [:]
    ) {
        self.newCategories = newCategories
        self.deletedCategories = deletedCategories
        self.changedCategories = changedCategories
        self.addedFiles = addedFiles
        self.deletedFiles = deletedFiles
    }

    public var hasChanges: Bool {
        !newCategories.isEmpty
            || !deletedCategories.isEmpty
            || !changedCategories.isEmpty
            || !addedFiles.isEmpty
            || !deletedFiles.isEmpty
    }

    public var isEmpty: Bool { !hasChanges }
}
