import Foundation

/// Represents the rotation state for a single category.
public struct CategoryCache: Codable, Equatable, Sendable {
    /// Files that have been shown in the current rotation
    public let wornOutfits: Set<String>
    /// Total number of files in the category
    public let totalOutfits: Int
    /// Last update timestamp
    public let lastUpdated: Date

    public init(
        wornOutfits: Set<String> = [],
        totalOutfits: Int,
        lastUpdated: Date = Date()
    ) {
        self.wornOutfits = wornOutfits
        self.totalOutfits = totalOutfits
        self.lastUpdated = lastUpdated
    }

    /// Whether all outfits in the category have been worn by the user
    public var isRotationComplete: Bool {
        wornOutfits.count >= totalOutfits
    }

    /// Progress of current rotation (0.0 to 1.0)
    public var rotationProgress: Double {
        guard totalOutfits > 0 else { return 1.0 }
        return Double(wornOutfits.count) / Double(totalOutfits)
    }

    /// Outfits that haven't been worn yet
    public var remainingOutfits: Int {
        max(0, totalOutfits - wornOutfits.count)
    }

    /// Creates a new cache with an additional worn outfit
    public func adding(_ fileName: String) -> CategoryCache {
        CategoryCache(
            wornOutfits: wornOutfits.union([fileName]),
            totalOutfits: totalOutfits,
            lastUpdated: Date()
        )
    }

    /// Creates a reset cache with no outfits worn
    public func reset() -> CategoryCache {
        CategoryCache(totalOutfits: totalOutfits)
    }
}

/// Cache data for all categories with per-category rotation tracking.
public struct OutfitCache: Codable, Equatable {
    /// Cache data per category path
    public let categories: [String: CategoryCache]
    /// Cache format version for migration
    public let version: Int
    /// Cache creation timestamp
    public let createdAt: Date

    public init(
        categories: [String: CategoryCache] = [:],
        version: Int = 1,
        createdAt: Date = Date()
    ) {
        self.categories = categories
        self.version = version
        self.createdAt = createdAt
    }

    /// Updates cache with a new category state
    public func updating(category path: String, with cache: CategoryCache) -> OutfitCache {
        var updatedCategories = categories
        updatedCategories[path] = cache
        return OutfitCache(
            categories: updatedCategories,
            version: version,
            createdAt: createdAt
        )
    }

    /// Resets all category rotations
    public func resetAll() -> OutfitCache {
        let resetCategories = categories.mapValues { $0.reset() }
        return OutfitCache(
            categories: resetCategories,
            version: version,
            createdAt: createdAt
        )
    }

    /// Removes a category from the cache
    public func removing(category path: String) -> OutfitCache {
        var updatedCategories = categories
        updatedCategories.removeValue(forKey: path)
        return OutfitCache(
            categories: updatedCategories,
            version: version,
            createdAt: createdAt
        )
    }

    /// Resets a specific category's rotation state
    public func resetting(category path: String) -> OutfitCache? {
        guard let categoryCache = categories[path] else { return nil }
        return updating(category: path, with: categoryCache.reset())
    }
}
