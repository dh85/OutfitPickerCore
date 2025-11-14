import Foundation

/// Validates file system paths for security and safety.
///
/// This validator performs comprehensive path validation to prevent security vulnerabilities
/// and ensure paths are safe for use in the outfit picker configuration. It checks for:
/// - Invalid characters and control sequences
/// - Path traversal attempts (..)
/// - Restricted system directories
/// - Symbolic link traversal
/// - Path length limits
///
/// ## Usage Example
/// ```swift
/// // Valid paths
/// try PathValidator.validate("/home/user/outfits")     // Passes
/// try PathValidator.validate("./my-outfits")           // Passes
///
/// // Invalid paths
/// try PathValidator.validate("/etc/passwd")            // Throws ConfigError.restrictedPath
/// try PathValidator.validate("../../../secret")        // Throws ConfigError.pathTraversalNotAllowed
/// try PathValidator.validate("/path/with\0null")       // Throws ConfigError.invalidCharacters
/// ```
struct PathValidator {
    /// Maximum allowed path length in characters.
    ///
    /// Set to 4096 characters to accommodate most file systems while preventing
    /// potential buffer overflow attacks or excessive memory usage.
    private static let maxPathLength = 4096

    /// Platform-specific set of restricted system paths.
    ///
    /// These paths are considered unsafe for user data storage and are blocked
    /// to prevent accidental or malicious access to system directories.
    ///
    /// - Windows: System directories like System32, Program Files
    /// - Unix-like: System directories like /etc, /usr, /bin, /root
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

    /// Validates a file system path for security and safety.
    ///
    /// Performs comprehensive validation including character validation, length checks,
    /// path traversal detection, restricted path checking, and symlink validation.
    ///
    /// - Parameter path: The file system path to validate
    /// - Throws: `ConfigError` for various validation failures:
    ///   - `invalidCharacters`: Path contains control characters or invalid sequences
    ///   - `pathTooLong`: Path exceeds maximum length limit (4096 characters)
    ///   - `pathTraversalNotAllowed`: Path contains ".." or other traversal attempts
    ///   - `restrictedPath`: Path targets a restricted system directory
    ///   - `symlinkNotAllowed`: Path involves symbolic link traversal
    static func validate(_ path: String) throws {
        // Check for invalid characters
        try validateCharacters(path)

        // Check path length
        try validateLength(path)

        // Check for path traversal attempts
        try validateTraversal(path)

        // Check against restricted paths
        try validateRestrictedPaths(path)

        // Check for symlink traversal
        try validateSymlinks(path)
    }

    // MARK: - Private Validation Methods

    /// Validates that the path contains only safe characters.
    ///
    /// - Parameter path: The path to validate
    /// - Throws: `ConfigError.invalidCharacters` if invalid characters are found
    private static func validateCharacters(_ path: String) throws {
        let sanitized = sanitizePath(path)
        if sanitized != path {
            throw ConfigError.invalidCharacters
        }
    }

    /// Validates that the path length is within acceptable limits.
    ///
    /// - Parameter path: The path to validate
    /// - Throws: `ConfigError.pathTooLong` if path exceeds maximum length
    private static func validateLength(_ path: String) throws {
        guard path.count <= maxPathLength else {
            throw ConfigError.pathTooLong
        }
    }

    /// Validates that the path doesn't contain traversal sequences.
    ///
    /// - Parameter path: The path to validate
    /// - Throws: `ConfigError.pathTraversalNotAllowed` if traversal is detected
    private static func validateTraversal(_ path: String) throws {
        if path.contains("..") {
            throw ConfigError.pathTraversalNotAllowed
        }

        // Additional traversal check using URL standardization
        let url = URL(filePath: path, directoryHint: .isDirectory)
        let standardized = url.standardized

        let originalComponents = path.components(separatedBy: "/")
        let standardizedComponents = standardized.path.components(
            separatedBy: "/"
        )

        if originalComponents.count > standardizedComponents.count + 2 {
            throw ConfigError.pathTraversalNotAllowed
        }
    }

    /// Validates that the path doesn't target restricted system directories.
    ///
    /// - Parameter path: The path to validate
    /// - Throws: `ConfigError.restrictedPath` if path targets a restricted directory
    private static func validateRestrictedPaths(_ path: String) throws {
        let normalizedPath = path.lowercased()
        for restricted in restrictedPaths {
            if normalizedPath.hasPrefix(restricted.lowercased()) {
                throw ConfigError.restrictedPath
            }
        }
    }

    /// Validates that the path doesn't involve symbolic link traversal.
    ///
    /// - Parameter path: The path to validate
    /// - Throws: `ConfigError.symlinkNotAllowed` if symlink traversal is detected
    private static func validateSymlinks(_ path: String) throws {
        if ProcessInfo.processInfo.environment[
            "OUTFITPICKER_DISABLE_SYMLINK_CHECK"
        ] == "true" {
            return
        }
        let url = URL(filePath: path, directoryHint: .isDirectory)
        let standardized = url.standardized
        let resolved = url.resolvingSymlinksInPath()

        if resolved.path(percentEncoded: false)
            != standardized.path(percentEncoded: false)
        {
            throw ConfigError.symlinkNotAllowed
        }
    }

    /// Removes invalid characters from a path string.
    ///
    /// Filters out control characters and non-printable ASCII characters,
    /// keeping only characters in the range 32-126 (printable ASCII).
    ///
    /// - Parameter path: The path string to sanitize
    /// - Returns: A sanitized version of the path with only safe characters
    /// - Note: This method is used internally to detect invalid characters
    private static func sanitizePath(_ path: String) -> String {
        return path.filter { char in
            let ascii = char.asciiValue ?? 0
            return ascii >= 32 && ascii <= 126
        }
    }

    // MARK: - Internal Access for Testing

    /// Returns the maximum allowed path length.
    ///
    /// - Returns: The maximum path length in characters (4096)
    /// - Note: This method is primarily for testing purposes
    static var maximumPathLength: Int {
        return maxPathLength
    }

    /// Returns the set of restricted paths for the current platform.
    ///
    /// - Returns: A set of restricted path prefixes
    /// - Note: This method is primarily for testing purposes
    static var platformRestrictedPaths: Set<String> {
        return restrictedPaths
    }
}
