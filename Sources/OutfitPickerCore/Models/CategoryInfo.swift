import Foundation

public enum CategoryState: Codable, Sendable {
    case hasOutfits
    case empty
    case noAvatarFiles
    case userExcluded
}

public struct CategoryInfo: Sendable {
    public let category: Category
    public let state: CategoryState
}
