import Foundation

/// Creates a unique temporary directory URL for isolated test runs.
/// The directory itself is not created automatically.
public func uniqueTempDir() -> URL {
    FileManager.default.temporaryDirectory
        .appending(
            path: "outfitpicker-tests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
}

/// Returns `true` if a file or directory exists at the given URL.
@discardableResult
public func fileExists(_ url: URL) -> Bool {
    FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
}
