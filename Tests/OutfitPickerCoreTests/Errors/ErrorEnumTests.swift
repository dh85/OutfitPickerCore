import Foundation
import Testing

@testable import OutfitPickerCore

// MARK: - Helpers

private func assertLocalizedMatchesDescription<E: LocalizedError & Equatable>(
    _ error: E
) {
    #expect(
        error.errorDescription == error.localizedDescription,
        "Localized description should match errorDescription"
    )
}

// MARK: - ConfigError Tests

struct ConfigErrorTests {

    @Test
    func descriptions_coverAllCases() {
        #expect(
            ConfigError.emptyRoot.errorDescription
                == "empty root in configuration"
        )
        #expect(
            ConfigError.missingRoot.errorDescription
                == "missing root in configuration"
        )
        #expect(
            ConfigError.missingLanguage.errorDescription
                == "missing language in configuration"
        )
        #expect(
            ConfigError.unsupportedLanguage("fr").errorDescription
                == "unsupported language: fr"
        )
        #expect(
            ConfigError.pathTraversalNotAllowed.errorDescription
                == "path traversal not allowed"
        )
        #expect(ConfigError.pathTooLong.errorDescription == "path too long")
        #expect(
            ConfigError.restrictedPath.errorDescription == "restricted path"
        )
        #expect(
            ConfigError.symlinkNotAllowed.errorDescription
                == "symlink not allowed"
        )
        #expect(
            ConfigError.invalidCharacters.errorDescription
                == "invalid characters"
        )
    }

    @Test
    func localizedDescription_matchesErrorDescription() {
        assertLocalizedMatchesDescription(ConfigError.emptyRoot)
        assertLocalizedMatchesDescription(ConfigError.missingRoot)
        assertLocalizedMatchesDescription(ConfigError.missingLanguage)
        assertLocalizedMatchesDescription(ConfigError.unsupportedLanguage("en"))
        assertLocalizedMatchesDescription(ConfigError.pathTraversalNotAllowed)
        assertLocalizedMatchesDescription(ConfigError.pathTooLong)
        assertLocalizedMatchesDescription(ConfigError.restrictedPath)
        assertLocalizedMatchesDescription(ConfigError.symlinkNotAllowed)
        assertLocalizedMatchesDescription(ConfigError.invalidCharacters)
    }

    @Test
    func equatable_semantics() {
        #expect(ConfigError.emptyRoot == .emptyRoot)
        #expect(ConfigError.emptyRoot != .missingRoot)
        #expect(
            ConfigError.unsupportedLanguage("en") == .unsupportedLanguage("en")
        )
        #expect(
            ConfigError.unsupportedLanguage("en") != .unsupportedLanguage("de")
        )
    }
}

// MARK: - CacheError Tests

struct CacheErrorTests {

    @Test
    func descriptions_coverAllCases() {
        #expect(
            CacheError.pathNotFound.errorDescription
                == "cache directory not found"
        )
        #expect(
            CacheError.fileNotFound.errorDescription == "cache file not found"
        )
        #expect(
            CacheError.encodingFailed.errorDescription
                == "failed to encode cache data"
        )
        #expect(
            CacheError.decodingFailed.errorDescription
                == "failed to decode cache data"
        )
        #expect(CacheError.invalidData.errorDescription == "invalid cache data")
    }

    @Test
    func localizedDescription_matchesErrorDescription() {
        assertLocalizedMatchesDescription(CacheError.pathNotFound)
        assertLocalizedMatchesDescription(CacheError.fileNotFound)
        assertLocalizedMatchesDescription(CacheError.encodingFailed)
        assertLocalizedMatchesDescription(CacheError.decodingFailed)
        assertLocalizedMatchesDescription(CacheError.invalidData)
    }

    @Test
    func equatable_semantics() {
        #expect(CacheError.fileNotFound == .fileNotFound)
        #expect(CacheError.fileNotFound != .pathNotFound)
    }
}

// MARK: - StorageError Tests

struct StorageErrorTests {

    @Test
    func descriptions_coverAllCases() {
        #expect(
            StorageError.fileNotFound.errorDescription
                == "storage file not found"
        )
        #expect(
            StorageError.directoryNotFound.errorDescription
                == "storage directory not found"
        )
        #expect(
            StorageError.permissionDenied.errorDescription
                == "storage permission denied"
        )
        #expect(StorageError.diskFull.errorDescription == "storage disk full")
        #expect(
            StorageError.corruptedData.errorDescription
                == "storage data corrupted"
        )
    }

    @Test
    func localizedDescription_matchesErrorDescription() {
        assertLocalizedMatchesDescription(StorageError.fileNotFound)
        assertLocalizedMatchesDescription(StorageError.directoryNotFound)
        assertLocalizedMatchesDescription(StorageError.permissionDenied)
        assertLocalizedMatchesDescription(StorageError.diskFull)
        assertLocalizedMatchesDescription(StorageError.corruptedData)
    }

    @Test
    func equatable_semantics() {
        #expect(StorageError.diskFull == .diskFull)
        #expect(StorageError.diskFull != .permissionDenied)
    }
}

// MARK: - FileSystemError Tests

struct FileSystemErrorTests {

    @Test
    func descriptions_coverAllCases() {
        #expect(
            FileSystemError.directoryNotFound.errorDescription
                == "directory not found"
        )
        #expect(
            FileSystemError.fileNotFound.errorDescription == "file not found"
        )
        #expect(
            FileSystemError.permissionDenied.errorDescription
                == "file system permission denied"
        )
        #expect(
            FileSystemError.invalidPath.errorDescription
                == "invalid file system path"
        )
        #expect(
            FileSystemError.operationFailed.errorDescription
                == "file system operation failed"
        )
    }

    @Test
    func localizedDescription_matchesErrorDescription() {
        assertLocalizedMatchesDescription(FileSystemError.directoryNotFound)
        assertLocalizedMatchesDescription(FileSystemError.fileNotFound)
        assertLocalizedMatchesDescription(FileSystemError.permissionDenied)
        assertLocalizedMatchesDescription(FileSystemError.invalidPath)
        assertLocalizedMatchesDescription(FileSystemError.operationFailed)
    }

    @Test
    func equatable_semantics() {
        #expect(FileSystemError.operationFailed == .operationFailed)
        #expect(FileSystemError.operationFailed != .invalidPath)
    }
}
