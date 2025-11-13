import Foundation

/// Core protocol defining the outfit picker functionality.
/// 
/// This protocol provides methods for selecting random outfits, managing worn outfit tracking,
/// and handling category changes. All methods return `OutfitPickerResult` for consistent error handling.
/// 
/// ## Usage Example
/// ```swift
/// let picker = OutfitPicker(configService: configService, fileManager: FileManager.default)
/// 
/// // Show a random outfit from a specific category
/// switch picker.showRandomOutfit(from: "casual") {
/// case .success(let outfit):
///     print("Selected outfit: \(outfit?.fileName ?? "none available")")
/// case .failure(let error):
///     print("Error: \(error)")
/// }
/// ```
public protocol OutfitPickerProtocol: Sendable {
    /// Shows a random unworn outfit from the specified category.
    /// 
    /// - Parameter categoryName: The name of the category to select from
    /// - Returns: A result containing an optional outfit reference, or nil if no outfits are available
    /// - Note: Automatically resets the category's worn list when all outfits have been worn
    func showRandomOutfit(from categoryName: String) -> OutfitPickerResult<OutfitReference?>
    
    /// Shows a random unworn outfit from any available category.
    /// 
    /// - Returns: A result containing an optional outfit reference, or nil if no outfits are available
    /// - Note: Only considers categories that have unworn outfits available
    func showRandomOutfitAcrossCategories() -> OutfitPickerResult<OutfitReference?>
    
    /// Marks an outfit as worn by adding it to the category's worn list.
    /// 
    /// - Parameter outfit: The outfit reference to mark as worn
    /// - Returns: A result indicating success or failure
    /// - Note: Has no effect if the outfit is already marked as worn
    func wearOutfit(_ outfit: OutfitReference) -> OutfitPickerResult<Void>
    
    /// Retrieves detailed information about all categories including their states.
    /// 
    /// - Returns: A result containing an array of category information
    /// - Note: Includes categories that are empty, excluded, or have no avatar files
    func getCategoryInfo() -> OutfitPickerResult<[CategoryInfo]>
    
    /// Retrieves references to all non-excluded categories.
    /// 
    /// - Returns: A result containing an array of category references
    /// - Note: Excludes user-excluded categories but includes empty categories
    func getCategories() -> OutfitPickerResult<[CategoryReference]>
    
    /// Gets the count of available (unworn) outfits in a category.
    /// 
    /// - Parameter categoryName: The name of the category to check
    /// - Returns: A result containing the count of available outfits
    /// - Note: Returns total count if rotation is complete, otherwise returns unworn count
    func getAvailableCount(for categoryName: String) -> OutfitPickerResult<Int>
    
    /// Resets the worn outfit list for a specific category.
    /// 
    /// - Parameter categoryName: The name of the category to reset
    /// - Returns: A result indicating success or failure
    func resetCategory(_ categoryName: String) -> OutfitPickerResult<Void>
    
    /// Resets the worn outfit lists for all categories.
    /// 
    /// - Returns: A result indicating success or failure
    func resetAllCategories() -> OutfitPickerResult<Void>
    
    /// Partially resets a category to have only the specified number of worn outfits.
    /// 
    /// - Parameters:
    ///   - categoryName: The name of the category to partially reset
    ///   - wornCount: The number of outfits to keep as worn
    /// - Returns: A result indicating success or failure
    /// - Note: Has no effect if wornCount >= total outfit count
    func partialReset(categoryName: String, wornCount: Int) -> OutfitPickerResult<Void>
    
    /// Retrieves all outfit references from a specific category.
    /// 
    /// - Parameter categoryName: The name of the category to list
    /// - Returns: A result containing an array of all outfit references in the category
    func showAllOutfits(from categoryName: String) -> OutfitPickerResult<[OutfitReference]>
    
    /// Detects changes in the filesystem compared to the stored configuration.
    /// 
    /// - Returns: A result containing detected category and file changes
    /// - Note: Compares current filesystem state with known categories and files
    func detectChanges() -> OutfitPickerResult<CategoryChanges>
    
    /// Updates the configuration with detected changes.
    /// 
    /// - Parameter changes: The category changes to apply to the configuration
    /// - Returns: A result indicating success or failure
    /// - Note: Automatically resets cache for deleted categories
    func updateConfig(with changes: CategoryChanges) -> OutfitPickerResult<Void>
}

/// Async/await version of the outfit picker protocol.
/// 
/// This protocol provides the same functionality as `OutfitPickerProtocol` but uses
/// async/await for better concurrency support and cleaner error handling.
/// 
/// ## Usage Example
/// ```swift
/// let picker = OutfitPicker(configService: configService, fileManager: FileManager.default)
/// 
/// do {
///     let outfit = try await picker.showRandomOutfit(from: "casual")
///     print("Selected outfit: \(outfit?.fileName ?? "none available")")
/// } catch {
///     print("Error: \(error)")
/// }
/// ```
public protocol AsyncOutfitPickerProtocol: Sendable {
    /// Shows a random unworn outfit from the specified category.
    func showRandomOutfit(from categoryName: String) async throws -> OutfitReference?
    
    /// Shows a random unworn outfit from any available category.
    func showRandomOutfitAcrossCategories() async throws -> OutfitReference?
    
    /// Marks an outfit as worn by adding it to the category's worn list.
    func wearOutfit(_ outfit: OutfitReference) async throws
    
    /// Retrieves detailed information about all categories including their states.
    func getCategoryInfo() async throws -> [CategoryInfo]
    
    /// Retrieves references to all non-excluded categories.
    func getCategories() async throws -> [CategoryReference]
    
    /// Gets the count of available (unworn) outfits in a category.
    func getAvailableCount(for categoryName: String) async throws -> Int
    
    /// Resets the worn outfit list for a specific category.
    func resetCategory(_ categoryName: String) async throws
    
    /// Resets the worn outfit lists for all categories.
    func resetAllCategories() async throws
    
    /// Partially resets a category to have only the specified number of worn outfits.
    func partialReset(categoryName: String, wornCount: Int) async throws
    
    /// Retrieves all outfit references from a specific category.
    func showAllOutfits(from categoryName: String) async throws -> [OutfitReference]
    
    /// Detects changes in the filesystem compared to the stored configuration.
    func detectChanges() async throws -> CategoryChanges
    
    /// Updates the configuration with detected changes.
    func updateConfig(with changes: CategoryChanges) async throws
}

/// Protocol abstracting FileManager operations for testability.
/// 
/// This protocol wraps essential FileManager methods used by the outfit picker,
/// allowing for dependency injection and easier unit testing.
public protocol FileManagerProtocol: Sendable {
    /// Lists the contents of a directory.
    /// 
    /// - Parameters:
    ///   - url: The directory URL to enumerate
    ///   - keys: Resource keys to include in the enumeration
    ///   - mask: Options for the directory enumeration
    /// - Returns: An array of URLs for the directory contents
    /// - Throws: FileManager errors if the directory cannot be read
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
    
    /// Checks if a file exists at the specified path.
    /// 
    /// - Parameters:
    ///   - path: The file path to check
    ///   - isDirectory: Optional pointer to receive directory status
    /// - Returns: True if the file exists, false otherwise
    func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool
    
    /// Returns URLs for the specified search path directory.
    /// 
    /// - Parameters:
    ///   - directory: The search path directory type
    ///   - domainMark: The domain mask for the search
    /// - Returns: An array of URLs matching the search criteria
    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMark: FileManager.SearchPathDomainMask
    ) -> [URL]
    
    /// Creates a directory at the specified URL.
    /// 
    /// - Parameters:
    ///   - url: The URL where the directory should be created
    ///   - createIntermediates: Whether to create intermediate directories
    ///   - attributes: File attributes for the new directory
    /// - Throws: FileManager errors if the directory cannot be created
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws
    
    /// Removes the item at the specified URL.
    /// 
    /// - Parameter URL: The URL of the item to remove
    /// - Throws: FileManager errors if the item cannot be removed
    func removeItem(at URL: URL) throws
}

extension FileManager: FileManagerProtocol {}

/// Main implementation of the outfit picker functionality.
/// 
/// This struct coordinates between configuration, cache, and file system services
/// to provide outfit selection and management capabilities.
/// 
/// ## Usage Example
/// ```swift
/// let configService = ConfigService(directoryProvider: DefaultDirectoryProvider())
/// let picker = OutfitPicker(
///     configService: configService,
///     fileManager: FileManager.default
/// )
/// 
/// // Use the picker methods
/// let result = picker.showRandomOutfit(from: "casual")
/// ```
public struct OutfitPicker: OutfitPickerProtocol, AsyncOutfitPickerProtocol, @unchecked Sendable {
    private let configService: ConfigServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let fileManager: FileManagerProtocol

    /// Initializes a new outfit picker with the specified services.
    /// 
    /// - Parameters:
    ///   - configService: Service for loading and saving configuration
    ///   - cacheService: Service for managing worn outfit cache (defaults to CacheService())
    ///   - fileManager: File manager for filesystem operations
    public init(
        configService: ConfigServiceProtocol,
        cacheService: CacheServiceProtocol = CacheService(),
        fileManager: FileManagerProtocol
    ) {
        self.configService = configService
        self.cacheService = cacheService
        self.fileManager = fileManager
    }
    
    // MARK: - Public API Methods

    public func showRandomOutfit(from categoryName: String)
        -> OutfitPickerResult<OutfitReference?>
    {
        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            guard !files.isEmpty else { return .success(nil) }

            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName]
                ?? CategoryCache(totalOutfits: files.count)

            let pool: [FileEntry]
            if categoryCache.wornOutfits.count >= files.count {
                let reset = CategoryCache(totalOutfits: files.count)
                try cacheService.save(
                    cache.updating(category: categoryName, with: reset)
                )
                pool = files
            } else {
                pool = files.filter {
                    !categoryCache.wornOutfits.contains($0.fileName)
                }
            }

            // Given the earlier guard, pool cannot be empty
            let file = pool.randomElement()!

            let categoryRef = CategoryReference(
                name: categoryName,
                path: categoryPath
            )
            return .success(
                OutfitReference(fileName: file.fileName, category: categoryRef)
            )
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func showRandomOutfitAcrossCategories() -> OutfitPickerResult<
        OutfitReference?
    > {
        do {
            let config = try configService.load()
            let categoryInfos = try getCategoryInfo(config: config)

            var availableCategories = [(String, String, [FileEntry])]()

            for info in categoryInfos {
                guard case .hasOutfits = info.state else { continue }

                let categoryPath = URL(
                    filePath: config.root,
                    directoryHint: .isDirectory
                )
                .appending(
                    path: info.category.name,
                    directoryHint: .isDirectory
                )
                .path(percentEncoded: false)

                let files = try getAvatarFiles(in: categoryPath)
                guard !files.isEmpty else { continue }

                let cache = try cacheService.load()
                let categoryCache =
                    cache.categories[info.category.name]
                    ?? CategoryCache(totalOutfits: files.count)
                let availableFiles = files.filter {
                    !categoryCache.wornOutfits.contains($0.fileName)
                }

                if !availableFiles.isEmpty {
                    availableCategories.append(
                        (info.category.name, categoryPath, availableFiles)
                    )
                }
            }

            guard !availableCategories.isEmpty else { return .success(nil) }

            let (categoryName, categoryPath, files) =
                availableCategories.randomElement()!

            // Invariant: `files` is non-empty here.
            let file = files.randomElement()!

            let categoryRef = CategoryReference(
                name: categoryName,
                path: categoryPath
            )
            return .success(
                OutfitReference(
                    fileName: file.fileName,
                    category: categoryRef
                )
            )

        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func wearOutfit(_ outfit: OutfitReference) -> OutfitPickerResult<
        Void
    > {
        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: outfit.category.name, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            let cache = try cacheService.load()
            var categoryCache =
                cache.categories[outfit.category.name]
                ?? CategoryCache(totalOutfits: files.count)

            if !categoryCache.wornOutfits.contains(outfit.fileName) {
                categoryCache = categoryCache.adding(outfit.fileName)
                let updatedOutfitCache = cache.updating(
                    category: outfit.category.name,
                    with: categoryCache
                )
                try cacheService.save(updatedOutfitCache)
            }
            return .success(())
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func getCategoryInfo() -> OutfitPickerResult<[CategoryInfo]> {
        do {
            let config = try configService.load()
            let infos = try getCategoryInfo(config: config)
            return .success(infos)
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func getCategories() -> OutfitPickerResult<[CategoryReference]> {
        do {
            let config = try configService.load()
            let infos = try getCategoryInfo(config: config)

            let categories = infos.compactMap { info -> CategoryReference? in
                // Skip user-excluded categories
                if case .userExcluded = info.state {
                    return nil
                }

                return CategoryReference(
                    name: info.category.name,
                    path: info.category.path
                )
            }

            return .success(categories)
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func getAvailableCount(for categoryName: String)
        -> OutfitPickerResult<Int>
    {
        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName]
                ?? CategoryCache(totalOutfits: files.count)

            let availableFiles = files.filter {
                !categoryCache.wornOutfits.contains($0.fileName)
            }
            let count =
                categoryCache.isRotationComplete
                ? files.count : availableFiles.count
            return .success(count)
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func resetCategory(_ categoryName: String) -> OutfitPickerResult<
        Void
    > {
        do {
            _ = try configService.load()
            let cache = try cacheService.load()
            let updatedCache = cache.updating(
                category: categoryName,
                with: CategoryCache(totalOutfits: 0)
            )
            try cacheService.save(updatedCache)
            return .success(())
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func resetAllCategories() -> OutfitPickerResult<Void> {
        do {
            _ = try configService.load()
            try cacheService.save(OutfitCache())
            return .success(())
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func partialReset(categoryName: String, wornCount: Int)
        -> OutfitPickerResult<Void>
    {
        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            guard wornCount < files.count else { return .success(()) }

            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName]
                ?? CategoryCache(totalOutfits: files.count)

            let wornOutfits = Array(categoryCache.wornOutfits.prefix(wornCount))
            let updatedCache = CategoryCache(
                wornOutfits: Set(wornOutfits),
                totalOutfits: files.count
            )
            let updatedOutfitCache = cache.updating(
                category: categoryName,
                with: updatedCache
            )
            try cacheService.save(updatedOutfitCache)
            return .success(())
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func showAllOutfits(from categoryName: String) -> OutfitPickerResult<
        [OutfitReference]
    > {
        do {
            let config = try configService.load()
            let categoryPath = URL(
                filePath: config.root,
                directoryHint: .isDirectory
            )
            .appending(path: categoryName, directoryHint: .isDirectory)
            .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            let categoryRef = CategoryReference(
                name: categoryName,
                path: categoryPath
            )
            let outfits = files.map {
                OutfitReference(fileName: $0.fileName, category: categoryRef)
            }
            return .success(outfits)
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func detectChanges() -> OutfitPickerResult<CategoryChanges> {
        do {
            let config = try configService.load()
            let changes = try detectChanges(config: config)
            return .success(changes)
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    public func updateConfig(with changes: CategoryChanges)
        -> OutfitPickerResult<Void>
    {
        do {
            let config = try configService.load()
            let updatedConfig = try createUpdatedConfig(
                from: config,
                with: changes
            )
            try configService.save(updatedConfig)

            if !changes.deletedCategories.isEmpty {
                var cache = try cacheService.load()
                for _ in changes.deletedCategories {
                    cache = cache.resetAll()
                }
                try cacheService.save(cache)
            }
            return .success(())
        } catch {
            return .failure(OutfitPickerError.from(error))
        }
    }

    // MARK: - Private Helper Methods

    private func getAvatarFiles(in directoryPath: String) throws -> [FileEntry]
    {
        let url = URL(filePath: directoryPath, directoryHint: .isDirectory)
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: []
        )

        return contents.compactMap { fileURL in
            guard !fileURL.hasDirectoryPath,
                fileURL.pathExtension.lowercased() == "avatar"
            else {
                return nil
            }
            return FileEntry(filePath: fileURL.path(percentEncoded: false))
        }.sorted(by: { $0.fileName < $1.fileName })
    }

    private func getCategoryInfo(config: Config) throws -> [CategoryInfo] {
        let rootURL = URL(filePath: config.root, directoryHint: .isDirectory)
        let contents = try fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: nil,
            options: []
        )

        var categoryInfos = [CategoryInfo]()

        for url in contents {
            var isDirectory: ObjCBool = false
            guard
                fileManager.fileExists(
                    atPath: url.path(percentEncoded: false),
                    isDirectory: &isDirectory
                ), isDirectory.boolValue
            else {
                continue
            }

            let categoryName = url.lastPathComponent

            if config.excludedCategories.contains(categoryName) {
                let category = Category(
                    path: url.path(percentEncoded: false),
                    outfits: []
                )
                categoryInfos.append(
                    CategoryInfo(category: category, state: .userExcluded)
                )
                continue
            }

            let avatarFiles = try getAvatarFiles(
                in: url.path(percentEncoded: false)
            )
            let allFiles = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: []
            ).filter { !$0.hasDirectoryPath }

            let category = Category(
                path: url.path(percentEncoded: false),
                outfits: avatarFiles.map(\.fileName)
            )

            let state: CategoryState
            if avatarFiles.isEmpty {
                state = allFiles.isEmpty ? .empty : .noAvatarFiles
            } else {
                state = .hasOutfits
            }

            categoryInfos.append(CategoryInfo(category: category, state: state))
        }

        return categoryInfos.sorted { $0.category.name < $1.category.name }
    }

    private func detectChanges(config: Config) throws -> CategoryChanges {
        let currentCategoryInfos = try getCategoryInfo(config: config)

        var currentCategoryFiles = [String: Set<String>]()
        for info in currentCategoryInfos {
            currentCategoryFiles[info.category.name] = Set(
                info.category.outfits
            )
        }

        let previousCategoryFiles = config.knownCategoryFiles

        let previousCategoryNames: Set<String>
        if !previousCategoryFiles.isEmpty {
            previousCategoryNames = Set(previousCategoryFiles.keys)
        } else {
            previousCategoryNames = config.knownCategories
        }

        let currentCategoryNames = Set(currentCategoryFiles.keys)

        let newCategories = currentCategoryNames.subtracting(
            previousCategoryNames
        )
        let deletedCategories = previousCategoryNames.subtracting(
            currentCategoryNames
        )

        var changedCategories = Set<String>()
        var addedFiles = [String: Set<String>]()
        var deletedFiles = [String: Set<String>]()

        let commonCategories = currentCategoryNames.intersection(
            previousCategoryNames
        )

        for category in commonCategories {
            let previousFiles = previousCategoryFiles[category] ?? []
            let currentFiles = currentCategoryFiles[category]!

            let added = currentFiles.subtracting(previousFiles)
            let deleted = previousFiles.subtracting(currentFiles)

            if !added.isEmpty || !deleted.isEmpty {
                changedCategories.insert(category)
                if !added.isEmpty {
                    addedFiles[category] = added
                }
                if !deleted.isEmpty {
                    deletedFiles[category] = deleted
                }
            }
        }

        return CategoryChanges(
            newCategories: newCategories,
            deletedCategories: deletedCategories,
            changedCategories: changedCategories,
            addedFiles: addedFiles,
            deletedFiles: deletedFiles
        )
    }

    private func createUpdatedConfig(
        from config: Config,
        with changes: CategoryChanges
    ) throws -> Config {
        let currentCategoryInfos = try getCategoryInfo(config: config)
        let updatedKnownCategories = Set(
            currentCategoryInfos.map { $0.category.name }
        )

        var updatedKnownCategoryFiles: [String: Set<String>] = [:]
        for info in currentCategoryInfos {
            updatedKnownCategoryFiles[info.category.name] = Set(
                info.category.outfits
            )
        }

        return try Config(
            root: config.root,
            language: config.language,
            excludedCategories: config.excludedCategories,
            knownCategories: updatedKnownCategories,
            knownCategoryFiles: updatedKnownCategoryFiles
        )
    }
}

// MARK: - Async/Await Implementation

extension OutfitPicker {
    public func showRandomOutfit(from categoryName: String) async throws -> OutfitReference? {
        return try await withCheckedThrowingContinuation { continuation in
            let result = showRandomOutfit(from: categoryName)
            switch result {
            case .success(let outfit):
                continuation.resume(returning: outfit)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func showRandomOutfitAcrossCategories() async throws -> OutfitReference? {
        return try await withCheckedThrowingContinuation { continuation in
            let result = showRandomOutfitAcrossCategories()
            switch result {
            case .success(let outfit):
                continuation.resume(returning: outfit)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func wearOutfit(_ outfit: OutfitReference) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let result = wearOutfit(outfit)
            switch result {
            case .success:
                continuation.resume()
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func getCategoryInfo() async throws -> [CategoryInfo] {
        return try await withCheckedThrowingContinuation { continuation in
            let result = getCategoryInfo()
            switch result {
            case .success(let info):
                continuation.resume(returning: info)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func getCategories() async throws -> [CategoryReference] {
        return try await withCheckedThrowingContinuation { continuation in
            let result = getCategories()
            switch result {
            case .success(let categories):
                continuation.resume(returning: categories)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func getAvailableCount(for categoryName: String) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            let result = getAvailableCount(for: categoryName)
            switch result {
            case .success(let count):
                continuation.resume(returning: count)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func resetCategory(_ categoryName: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let result = resetCategory(categoryName)
            switch result {
            case .success:
                continuation.resume()
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func resetAllCategories() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let result = resetAllCategories()
            switch result {
            case .success:
                continuation.resume()
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func partialReset(categoryName: String, wornCount: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let result = partialReset(categoryName: categoryName, wornCount: wornCount)
            switch result {
            case .success:
                continuation.resume()
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func showAllOutfits(from categoryName: String) async throws -> [OutfitReference] {
        return try await withCheckedThrowingContinuation { continuation in
            let result = showAllOutfits(from: categoryName)
            switch result {
            case .success(let outfits):
                continuation.resume(returning: outfits)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func detectChanges() async throws -> CategoryChanges {
        return try await withCheckedThrowingContinuation { continuation in
            let result = detectChanges()
            switch result {
            case .success(let changes):
                continuation.resume(returning: changes)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func updateConfig(with changes: CategoryChanges) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let result = updateConfig(with: changes)
            switch result {
            case .success:
                continuation.resume()
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
