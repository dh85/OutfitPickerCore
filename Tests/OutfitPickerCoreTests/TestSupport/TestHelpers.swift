import Foundation

func uniqueTempDir() -> URL {
    FileManager.default.temporaryDirectory
        .appending(
            path: "outfitpicker-tests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
}

func fileExists(_ url: URL) -> Bool {
    FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
}
