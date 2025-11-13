import Foundation

@testable import OutfitPickerCore

// MARK: - Path helpers

func normPath(_ p: String) -> String {
    p.hasSuffix("/") ? String(p.dropLast()) : p
}

// MARK: - FS helpers

func makeCategoryDir(root: String, name: String, files: [String]) -> (
    dir: URL, map: [URL: [URL]]
) {
    let dir = URL(filePath: root, directoryHint: .isDirectory)
        .appending(path: name, directoryHint: .isDirectory)
    let urls = files.map {
        dir.appending(path: $0, directoryHint: .notDirectory)
    }
    return (dir, [dir: urls])
}

func makeFS(root: String, categories: [String: [String]]) -> (
    rootURL: URL, contents: [URL: [URL]], directories: Set<URL>
) {
    let rootURL = URL(filePath: root, directoryHint: .isDirectory)
    var map: [URL: [URL]] = [:]
    var dirs: Set<URL> = [rootURL]

    let categoryDirs = categories.keys.sorted().map {
        rootURL.appending(path: $0, directoryHint: .isDirectory)
    }
    map[rootURL] = categoryDirs
    dirs.formUnion(categoryDirs)

    for (name, files) in categories {
        let d = rootURL.appending(path: name, directoryHint: .isDirectory)
        map[d] = files.map {
            d.appending(path: $0, directoryHint: .notDirectory)
        }
    }

    return (rootURL, map, dirs)
}

// MARK: - SUT containers

struct SingleCategorySUT {
    let sut: OutfitPicker
    let fileManager: FakeFileManager
    let cache: FakeCacheService
    let config: FakeConfigService
}

func makeSingleCategorySUT(
    root: String = "/Users/test/Outfits",
    category: String,
    files: [String],
    cache: OutfitCache = OutfitCache()
) throws -> SingleCategorySUT {
    let config = try Config(root: root, language: "en")
    let configSvc = FakeConfigService(.ok(config))
    let (_, map) = makeCategoryDir(root: root, name: category, files: files)
    let fm = FakeFileManager(
        .ok(map),
        directories: [URL(filePath: root, directoryHint: .isDirectory)]
    )
    let cacheSvc = FakeCacheService(.ok(cache))

    let sut = OutfitPicker(
        configService: configSvc,
        cacheService: cacheSvc,
        fileManager: fm
    )
    return .init(sut: sut, fileManager: fm, cache: cacheSvc, config: configSvc)
}

struct AcrossCategoriesSUT {
    let sut: OutfitPicker
    let fileManager: FakeFileManager
    let cache: FakeCacheService
    let config: FakeConfigService
}

func makeAcrossCategoriesSUT(
    root: String = "/Users/test/Outfits",
    categories: [String: [String]],
    excluded: Set<String> = [],
    cache: OutfitCache = OutfitCache()
) throws -> AcrossCategoriesSUT {
    let config = try Config(
        root: root,
        language: "en",
        excludedCategories: excluded
    )
    let configSvc = FakeConfigService(.ok(config))

    let fs = makeFS(root: root, categories: categories)
    let fm = FakeFileManager(.ok(fs.contents), directories: Array(fs.directories))
    let cacheSvc = FakeCacheService(.ok(cache))

    let sut = OutfitPicker(
        configService: configSvc,
        cacheService: cacheSvc,
        fileManager: fm
    )
    return .init(sut: sut, fileManager: fm, cache: cacheSvc, config: configSvc)
}

// MARK: - Fakes

final class FakeConfigService: ConfigServiceProtocol, @unchecked Sendable {
    enum Mode {
        case ok(Config)
        case throwsError(Error)
    }
    let mode: Mode

    init(_ mode: Mode) { self.mode = mode }

    func load() throws -> Config {
        switch mode {
        case .ok(let c): return c
        case .throwsError(let e): throw e
        }
    }

    func save(_ config: Config) throws { fatalError("not used") }
    func delete() throws { fatalError("not used") }
    func configPath() throws -> URL { fatalError("not used") }
}

final class FakeCacheService: CacheServiceProtocol, @unchecked Sendable {
    enum Mode {
        case ok(OutfitCache)
        case throwsOnLoad(Error)
    }
    let mode: Mode

    init(_ mode: Mode) { self.mode = mode }

    private(set) var saved: [OutfitCache] = []

    func load() throws -> OutfitCache {
        switch mode {
        case .ok(let c): return c
        case .throwsOnLoad(let e): throw e
        }
    }

    func save(_ cache: OutfitCache) throws { saved.append(cache) }
    func delete() throws { fatalError("not used") }
    func cachePath() throws -> URL { fatalError("not used") }
}

final class FakeFileManager: FileManagerProtocol, @unchecked Sendable {
    enum Behavior {
        case ok([URL: [URL]])
        case throwsError(Error)
    }

    let behavior: Behavior
    let directories: Set<String>

    /// For these directory paths, the *second* call to contentsOfDirectory
    /// will return an empty array (to simulate files disappearing).
    let secondCallEmptyFor: Set<String>

    private var callCounts: [String: Int] = [:]

    init(
        _ behavior: Behavior,
        directories: [URL] = [],
        secondCallEmptyFor: [URL] = []
    ) {
        self.behavior = behavior
        self.directories = Set(directories.map { $0.path(percentEncoded: false) })
        self.secondCallEmptyFor = Set(
            secondCallEmptyFor.map { $0.path(percentEncoded: false) }
        )
    }

    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        switch behavior {
        case .throwsError(let e):
            throw e
        case .ok(let map):
            let path = url.path(percentEncoded: false)

            let count = (callCounts[path] ?? 0) + 1
            callCounts[path] = count

            // If configured, return real contents on first call, empty on 2nd+
            if secondCallEmptyFor.contains(path), count >= 2 {
                return []
            }

            return map[url] ?? []
        }
    }

    func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool {
        if let ptr = isDirectory {
            ptr.pointee = ObjCBool(directories.contains(path))
        }
        return true
    }

    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMark: FileManager.SearchPathDomainMask
    ) -> [URL] { [] }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {}

    func removeItem(at URL: URL) throws {}
}


