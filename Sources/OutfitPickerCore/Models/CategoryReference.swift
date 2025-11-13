import Foundation

public struct CategoryReference: Sendable, Hashable, CustomStringConvertible {
    public let name: String
    public let path: String

    internal init(name: String, path: String) {
        self.name = name
        self.path = path
    }

    public var description: String { name }
}

public struct OutfitReference: Sendable, Hashable, CustomStringConvertible {
    public let fileName: String
    public let category: CategoryReference

    internal init(fileName: String, category: CategoryReference) {
        self.fileName = fileName
        self.category = category
    }

    public var filePath: String {
        URL(filePath: category.path, directoryHint: .isDirectory)
            .appending(path: fileName, directoryHint: .notDirectory)
            .path(percentEncoded: false)
    }

    public var description: String { "\(fileName) in \(category.name)" }
}

public enum SelectionTarget: Sendable {
    case category(CategoryReference)
    case allCategories
    case categories([CategoryReference])
}

public struct RotationProgress: Sendable {
    public let category: CategoryReference
    public let wornCount: Int
    public let totalOutfitCount: Int
    public let isComplete: Bool

    public var progress: Double {
        totalOutfitCount > 0
            ? Double(wornCount) / Double(totalOutfitCount) : 1.0
    }

    public var availableCount: Int {
        isComplete ? totalOutfitCount : totalOutfitCount - wornCount
    }
}
