import Foundation

/// Represents the current state of a category directory.
///
/// CategoryState indicates whether a category contains usable outfit files,
/// is empty, or has been excluded by the user.
public enum CategoryState: Codable, Sendable, Equatable {
    /// Category contains outfit files that can be used
    case hasOutfits
    /// Category directory exists but contains no files
    case empty
    /// Category contains files but no .avatar files
    case noAvatarFiles
    /// Category has been excluded by user configuration
    case userExcluded
}

/// Combines a category with its current state information.
///
/// CategoryInfo provides complete information about a category including
/// its directory structure and current usability state.
public struct CategoryInfo: Sendable, Equatable {
    /// The category directory and its outfit files
    public let category: Category
    /// Current state of the category
    public let state: CategoryState

    public init(category: Category, state: CategoryState) {
        self.category = category
        self.state = state
    }
}
