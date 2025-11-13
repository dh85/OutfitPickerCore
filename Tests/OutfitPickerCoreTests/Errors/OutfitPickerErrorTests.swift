import Foundation
import Testing

@testable import OutfitPickerCore

// MARK: - Small helper

private func assertLocalizedMatchesDescription(_ error: OutfitPickerError) {
    #expect(error.errorDescription == error.localizedDescription,
            "localizedDescription should mirror errorDescription")
}

struct OutfitPickerErrorTests {

    // MARK: errorDescription coverage

    @Test
    func descriptions_coverAllCases() {
        #expect(OutfitPickerError.configurationNotFound.errorDescription == "Configuration not found")
        #expect(OutfitPickerError.categoryNotFound.errorDescription == "Category not found")
        #expect(OutfitPickerError.noOutfitsAvailable.errorDescription == "No outfits available")
        #expect(OutfitPickerError.fileSystemError.errorDescription == "File system error")
        #expect(OutfitPickerError.cacheError.errorDescription == "Cache error")
        #expect(OutfitPickerError.invalidConfiguration.errorDescription == "Invalid configuration")
        #expect(OutfitPickerError.invalidInput("whoops").errorDescription == "Invalid input: whoops")
    }

    // MARK: LocalizedError bridging

    @Test
    func localized_matches_errorDescription() {
        assertLocalizedMatchesDescription(.configurationNotFound)
        assertLocalizedMatchesDescription(.categoryNotFound)
        assertLocalizedMatchesDescription(.noOutfitsAvailable)
        assertLocalizedMatchesDescription(.fileSystemError)
        assertLocalizedMatchesDescription(.cacheError)
        assertLocalizedMatchesDescription(.invalidConfiguration)
        assertLocalizedMatchesDescription(.invalidInput("msg"))
    }

    // MARK: Equatable sanity (incl. associated value)

    @Test
    func equatable_behavesAsExpected() {
        #expect(OutfitPickerError.categoryNotFound == .categoryNotFound)
        #expect(OutfitPickerError.cacheError != .fileSystemError)
        #expect(OutfitPickerError.invalidInput("A") == .invalidInput("A"))
        #expect(OutfitPickerError.invalidInput("A") != .invalidInput("B"))
    }

    // MARK: from(_:) passthrough

    @Test
    func from_passthroughOutfitPickerError() {
        let original: OutfitPickerError = .noOutfitsAvailable
        let mapped = OutfitPickerError.from(original)
        #expect(mapped == original)
    }

    // MARK: from(_:) mappings

    @Test
    func from_mapsConfigError_toInvalidConfiguration() {
        let mapped = OutfitPickerError.from(ConfigError.pathTraversalNotAllowed)
        #expect(mapped == .invalidConfiguration)
    }

    @Test
    func from_mapsCacheError_toCacheError() {
        let mapped = OutfitPickerError.from(CacheError.pathNotFound)
        #expect(mapped == .cacheError)
    }

    @Test
    func from_mapsStorageError_toCacheError() {
        // Use the real enum from your module
        let mapped = OutfitPickerError.from(StorageError.fileNotFound)
        #expect(mapped == .cacheError)
    }

    @Test
    func from_mapsFileSystemError_toFileSystemError() {
        // Use the real enum from your module
        let mapped = OutfitPickerError.from(FileSystemError.permissionDenied)
        #expect(mapped == .fileSystemError)
    }

    @Test
    func from_mapsUnknownError_toFileSystemError() {
        struct Unknown: Error {}
        let mapped = OutfitPickerError.from(Unknown())
        #expect(mapped == .fileSystemError)
    }
}
