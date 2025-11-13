import Foundation

public protocol OutfitPickerProtocol: Sendable {
    func showRandomOutfit(from categoryName: String) -> OutfitPickerResult<
        OutfitReference?
    >
    func showRandomOutfitAcrossCategories() -> OutfitPickerResult<
        OutfitReference?
    >
    func wearOutfit(_ outfit: OutfitReference) -> OutfitPickerResult<Void>
    func getCategoryInfo() -> OutfitPickerResult<[CategoryInfo]>
    func getCategories() -> OutfitPickerResult<[CategoryReference]>
    func getAvailableCount(for categoryName: String) -> OutfitPickerResult<Int>
    func resetCategory(_ categoryName: String) -> OutfitPickerResult<Void>
    func resetAllCategories() -> OutfitPickerResult<Void>
    func partialReset(categoryName: String, wornCount: Int)
        -> OutfitPickerResult<Void>
    func showAllOutfits(from categoryName: String) -> OutfitPickerResult<
        [OutfitReference]
    >
    func detectChanges() -> OutfitPickerResult<CategoryChanges>
    func updateConfig(with changes: CategoryChanges) -> OutfitPickerResult<Void>
}

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
