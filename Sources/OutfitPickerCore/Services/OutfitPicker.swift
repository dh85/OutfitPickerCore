import Foundation

/// Core protocol defining the outfit picker functionality.
public protocol OutfitPickerProtocol: Sendable {
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

    /// Marks multiple outfits as worn in a single operation.
    func wearOutfits(_ outfits: [OutfitReference]) async throws

    /// Resets multiple categories in a single operation.
    func resetCategories(_ categoryNames: [String]) async throws
    
    /// Searches for outfits matching the given pattern.
    func searchOutfits(pattern: String) async throws -> [OutfitReference]
    
    /// Filters categories by name pattern.
    func filterCategories(pattern: String) async throws -> [CategoryReference]
}

/// Protocol abstracting FileManager operations for testability.
public protocol FileManagerProtocol: Sendable {
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]

    func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool

    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMark: FileManager.SearchPathDomainMask
    ) -> [URL]

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws

    func removeItem(at URL: URL) throws
}

extension FileManager: FileManagerProtocol {}

/// Main implementation of the outfit picker functionality.
public struct OutfitPicker: OutfitPickerProtocol, @unchecked Sendable {
    private let configService: ConfigServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let fileManager: FileManagerProtocol

    public init(
        configService: ConfigServiceProtocol,
        cacheService: CacheServiceProtocol = CacheService(),
        fileManager: FileManagerProtocol
    ) {
        self.configService = configService
        self.cacheService = cacheService
        self.fileManager = fileManager
    }

    // MARK: - Core Operations

    public func showRandomOutfit(from categoryName: String) async throws -> OutfitReference? {
        guard !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OutfitPickerError.invalidInput("Category name cannot be empty")
        }
        
        do {
            let config = try configService.load()
            let categoryPath = URL(filePath: config.root, directoryHint: .isDirectory)
                .appending(path: categoryName, directoryHint: .isDirectory)
                .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            guard !files.isEmpty else { return nil }

            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName] ?? CategoryCache(totalOutfits: files.count)

            let pool: [FileEntry]
            if categoryCache.wornOutfits.count >= files.count {
                let reset = CategoryCache(totalOutfits: files.count)
                try cacheService.save(cache.updating(category: categoryName, with: reset))
                pool = files
            } else {
                pool = files.filter { !categoryCache.wornOutfits.contains($0.fileName) }
            }

            let file = pool.randomElement()!
            let categoryRef = CategoryReference(name: categoryName, path: categoryPath)
            return OutfitReference(fileName: file.fileName, category: categoryRef)
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func showRandomOutfitAcrossCategories() async throws -> OutfitReference? {
        do {
            let config = try configService.load()
            let categoryInfos = try getCategoryInfo(config: config)

            var availableCategories = [(String, String, [FileEntry])]()

            for info in categoryInfos {
                guard case .hasOutfits = info.state else { continue }

                let categoryPath = URL(filePath: config.root, directoryHint: .isDirectory)
                    .appending(path: info.category.name, directoryHint: .isDirectory)
                    .path(percentEncoded: false)

                let files = try getAvatarFiles(in: categoryPath)
                guard !files.isEmpty else { continue }

                let cache = try cacheService.load()
                let categoryCache =
                    cache.categories[info.category.name] ?? CategoryCache(totalOutfits: files.count)
                let availableFiles = files.filter {
                    !categoryCache.wornOutfits.contains($0.fileName)
                }

                if !availableFiles.isEmpty {
                    availableCategories.append((info.category.name, categoryPath, availableFiles))
                }
            }

            guard !availableCategories.isEmpty else { return nil }

            let (categoryName, categoryPath, files) = availableCategories.randomElement()!
            let file = files.randomElement()!
            let categoryRef = CategoryReference(name: categoryName, path: categoryPath)
            return OutfitReference(fileName: file.fileName, category: categoryRef)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func wearOutfit(_ outfit: OutfitReference) async throws {
        guard !outfit.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OutfitPickerError.invalidInput("Outfit filename cannot be empty")
        }
        guard !outfit.category.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OutfitPickerError.invalidInput("Category name cannot be empty")
        }
        
        do {
            let config = try configService.load()
            let categoryPath = URL(filePath: config.root, directoryHint: .isDirectory)
                .appending(path: outfit.category.name, directoryHint: .isDirectory)
                .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            guard files.contains(where: { $0.fileName == outfit.fileName }) else {
                throw OutfitPickerError.noOutfitsAvailable
            }
            
            let cache = try cacheService.load()
            var categoryCache =
                cache.categories[outfit.category.name] ?? CategoryCache(totalOutfits: files.count)

            if !categoryCache.wornOutfits.contains(outfit.fileName) {
                categoryCache = categoryCache.adding(outfit.fileName)
                let updatedOutfitCache = cache.updating(
                    category: outfit.category.name, with: categoryCache)
                try cacheService.save(updatedOutfitCache)
            }
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func getCategoryInfo() async throws -> [CategoryInfo] {
        do {
            let config = try configService.load()
            return try getCategoryInfo(config: config)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func getCategories() async throws -> [CategoryReference] {
        do {
            let config = try configService.load()
            let infos = try getCategoryInfo(config: config)

            return infos.compactMap { info -> CategoryReference? in
                if case .hasOutfits = info.state {
                    return CategoryReference(name: info.category.name, path: info.category.path)
                }
                return nil
            }
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func getAvailableCount(for categoryName: String) async throws -> Int {
        guard !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OutfitPickerError.invalidInput("Category name cannot be empty")
        }
        
        do {
            let config = try configService.load()
            let categoryPath = URL(filePath: config.root, directoryHint: .isDirectory)
                .appending(path: categoryName, directoryHint: .isDirectory)
                .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName] ?? CategoryCache(totalOutfits: files.count)

            let availableFiles = files.filter { !categoryCache.wornOutfits.contains($0.fileName) }
            return categoryCache.isRotationComplete ? files.count : availableFiles.count
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func resetCategory(_ categoryName: String) async throws {
        guard !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OutfitPickerError.invalidInput("Category name cannot be empty")
        }
        
        do {
            _ = try configService.load()
            let cache = try cacheService.load()
            let updatedCache = cache.updating(
                category: categoryName, with: CategoryCache(totalOutfits: 0))
            try cacheService.save(updatedCache)
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func resetAllCategories() async throws {
        do {
            _ = try configService.load()
            try cacheService.save(OutfitCache())
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func partialReset(categoryName: String, wornCount: Int) async throws {
        do {
            let config = try configService.load()
            let categoryPath = URL(filePath: config.root, directoryHint: .isDirectory)
                .appending(path: categoryName, directoryHint: .isDirectory)
                .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            guard wornCount < files.count else { return }

            let cache = try cacheService.load()
            let categoryCache =
                cache.categories[categoryName] ?? CategoryCache(totalOutfits: files.count)

            let wornOutfits = Array(categoryCache.wornOutfits.prefix(wornCount))
            let updatedCache = CategoryCache(
                wornOutfits: Set(wornOutfits), totalOutfits: files.count)
            let updatedOutfitCache = cache.updating(category: categoryName, with: updatedCache)
            try cacheService.save(updatedOutfitCache)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func showAllOutfits(from categoryName: String) async throws -> [OutfitReference] {
        do {
            let config = try configService.load()
            let categoryPath = URL(filePath: config.root, directoryHint: .isDirectory)
                .appending(path: categoryName, directoryHint: .isDirectory)
                .path(percentEncoded: false)

            let files = try getAvatarFiles(in: categoryPath)
            let categoryRef = CategoryReference(name: categoryName, path: categoryPath)
            return files.map { OutfitReference(fileName: $0.fileName, category: categoryRef) }
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func detectChanges() async throws -> CategoryChanges {
        do {
            let config = try configService.load()
            return try detectChanges(config: config)
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func updateConfig(with changes: CategoryChanges) async throws {
        do {
            let config = try configService.load()
            let updatedConfig = try createUpdatedConfig(from: config, with: changes)
            try configService.save(updatedConfig)

            if !changes.deletedCategories.isEmpty {
                var cache = try cacheService.load()
                for _ in changes.deletedCategories {
                    cache = cache.resetAll()
                }
                try cacheService.save(cache)
            }
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func wearOutfits(_ outfits: [OutfitReference]) async throws {
        guard !outfits.isEmpty else {
            try cacheService.save(try cacheService.load())
            return
        }
        
        for outfit in outfits {
            guard !outfit.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw OutfitPickerError.invalidInput("Outfit filename cannot be empty")
            }
            guard !outfit.category.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw OutfitPickerError.invalidInput("Category name cannot be empty")
            }
        }
        
        do {
            let config = try configService.load()
            var cache = try cacheService.load()

            for outfit in outfits {
                let categoryPath = URL(filePath: config.root, directoryHint: .isDirectory)
                    .appending(path: outfit.category.name, directoryHint: .isDirectory)
                    .path(percentEncoded: false)

                let files = try getAvatarFiles(in: categoryPath)
                guard files.contains(where: { $0.fileName == outfit.fileName }) else {
                    throw OutfitPickerError.noOutfitsAvailable
                }
                
                var categoryCache =
                    cache.categories[outfit.category.name]
                    ?? CategoryCache(totalOutfits: files.count)

                if !categoryCache.wornOutfits.contains(outfit.fileName) {
                    categoryCache = categoryCache.adding(outfit.fileName)
                    cache = cache.updating(category: outfit.category.name, with: categoryCache)
                }
            }

            try cacheService.save(cache)
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func resetCategories(_ categoryNames: [String]) async throws {
        guard !categoryNames.isEmpty else {
            try cacheService.save(try cacheService.load())
            return
        }
        
        for categoryName in categoryNames {
            guard !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw OutfitPickerError.invalidInput("Category name cannot be empty")
            }
        }
        
        do {
            _ = try configService.load()
            var cache = try cacheService.load()

            for categoryName in categoryNames {
                cache = cache.updating(category: categoryName, with: CategoryCache(totalOutfits: 0))
            }

            try cacheService.save(cache)
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func searchOutfits(pattern: String) async throws -> [OutfitReference] {
        guard !pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OutfitPickerError.invalidInput("Search pattern cannot be empty")
        }
        
        do {
            let config = try configService.load()
            let categoryInfos = try getCategoryInfo(config: config)
            var results: [OutfitReference] = []
            
            for info in categoryInfos {
                guard case .hasOutfits = info.state else { continue }
                
                let categoryPath = URL(filePath: config.root, directoryHint: .isDirectory)
                    .appending(path: info.category.name, directoryHint: .isDirectory)
                    .path(percentEncoded: false)
                
                let files = try getAvatarFiles(in: categoryPath)
                let categoryRef = CategoryReference(name: info.category.name, path: categoryPath)
                
                let matchingFiles = files.filter { file in
                    file.fileName.localizedCaseInsensitiveContains(pattern)
                }
                
                results.append(contentsOf: matchingFiles.map { 
                    OutfitReference(fileName: $0.fileName, category: categoryRef)
                })
            }
            
            return results.sorted { $0.fileName < $1.fileName }
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    public func filterCategories(pattern: String) async throws -> [CategoryReference] {
        guard !pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OutfitPickerError.invalidInput("Filter pattern cannot be empty")
        }
        
        do {
            let categories = try await getCategories()
            return categories.filter { category in
                category.name.localizedCaseInsensitiveContains(pattern)
            }.sorted { $0.name < $1.name }
        } catch let error as OutfitPickerError {
            throw error
        } catch {
            throw OutfitPickerError.from(error)
        }
    }

    // MARK: - Private Helper Methods

    private func getAvatarFiles(in directoryPath: String) throws -> [FileEntry] {
        let url = URL(filePath: directoryPath, directoryHint: .isDirectory)
        let contents = try fileManager.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil, options: [])

        return contents.compactMap { fileURL in
            guard !fileURL.hasDirectoryPath, fileURL.pathExtension.lowercased() == "avatar" else {
                return nil
            }
            return FileEntry(filePath: fileURL.path(percentEncoded: false))
        }.sorted(by: { $0.fileName < $1.fileName })
    }

    private func getCategoryInfo(config: Config) throws -> [CategoryInfo] {
        let rootURL = URL(filePath: config.root, directoryHint: .isDirectory)
        let contents = try fileManager.contentsOfDirectory(
            at: rootURL, includingPropertiesForKeys: nil, options: [])

        var categoryInfos = [CategoryInfo]()

        for url in contents {
            var isDirectory: ObjCBool = false
            guard
                fileManager.fileExists(
                    atPath: url.path(percentEncoded: false), isDirectory: &isDirectory),
                isDirectory.boolValue
            else { continue }

            let categoryName = url.lastPathComponent

            if config.excludedCategories.contains(categoryName) {
                let category = Category(path: url.path(percentEncoded: false), outfits: [])
                categoryInfos.append(CategoryInfo(category: category, state: .userExcluded))
                continue
            }

            let avatarFiles = try getAvatarFiles(in: url.path(percentEncoded: false))
            let allFiles = try fileManager.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil, options: []
            )
            .filter { !$0.hasDirectoryPath }

            let category = Category(
                path: url.path(percentEncoded: false), outfits: avatarFiles.map(\.fileName))

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
            currentCategoryFiles[info.category.name] = Set(info.category.outfits)
        }

        let previousCategoryFiles = config.knownCategoryFiles

        let previousCategoryNames: Set<String>
        if !previousCategoryFiles.isEmpty {
            previousCategoryNames = Set(previousCategoryFiles.keys)
        } else {
            previousCategoryNames = config.knownCategories
        }

        let currentCategoryNames = Set(currentCategoryFiles.keys)

        let newCategories = currentCategoryNames.subtracting(previousCategoryNames)
        let deletedCategories = previousCategoryNames.subtracting(currentCategoryNames)

        var changedCategories = Set<String>()
        var addedFiles = [String: Set<String>]()
        var deletedFiles = [String: Set<String>]()

        let commonCategories = currentCategoryNames.intersection(previousCategoryNames)

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

    private func createUpdatedConfig(from config: Config, with changes: CategoryChanges) throws
        -> Config
    {
        let currentCategoryInfos = try getCategoryInfo(config: config)
        let updatedKnownCategories = Set(currentCategoryInfos.map { $0.category.name })

        var updatedKnownCategoryFiles: [String: Set<String>] = [:]
        for info in currentCategoryInfos {
            updatedKnownCategoryFiles[info.category.name] = Set(info.category.outfits)
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
