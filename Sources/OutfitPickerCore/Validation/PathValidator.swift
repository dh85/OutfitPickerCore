import Foundation

struct PathValidator {
    private static let maxPathLength = 4096
    private static let restrictedPaths: Set<String> = {
        #if os(Windows)
            return [
                "C:\\Windows\\System32", "C:\\Program Files",
                "C:\\Users\\Administrator", "\\\\localhost\\C$",
            ]
        #else
            return [
                "/etc", "/usr", "/bin", "/sbin", "/System", "/private", "/var",
                "/tmp", "/root",
            ]
        #endif
    }()

    static func validate(_ path: String) throws {
        let santized = sanitizePath(path)
        if santized != path {
            throw ConfigError.invalidCharacters
        }

        guard path.count <= maxPathLength else {
            throw ConfigError.pathTooLong
        }

        if path.contains("..") {
            throw ConfigError.pathTraversalNotAllowed
        }

        let normalizedPath = path.lowercased()
        for restricted in restrictedPaths {
            if normalizedPath.hasPrefix(restricted.lowercased()) {
                throw ConfigError.restrictedPath
            }
        }

        let url = URL(filePath: path, directoryHint: .isDirectory)
        let standardized = url.standardized
        let resolved = url.resolvingSymlinksInPath()

        if resolved.path(percentEncoded: false)
            != standardized.path(percentEncoded: false)
        {
            throw ConfigError.symlinkNotAllowed
        }

        let originalComponents = path.components(separatedBy: "/")
        let standardizedComponents = standardized.path.components(
            separatedBy: "/"
        )

        if originalComponents.count > standardizedComponents.count + 2 {
            throw ConfigError.pathTraversalNotAllowed
        }
    }

    private static func sanitizePath(_ path: String) -> String {
        return path.filter { char in
            let ascii = char.asciiValue ?? 0
            return ascii >= 32 && ascii <= 126
        }
    }
}
