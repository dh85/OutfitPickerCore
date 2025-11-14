import Testing
import Foundation
@testable import OutfitPickerCore
@testable import OutfitPickerTestSupport

@Test("randomOutfit success path")
func randomOutfitSuccessPath() async {
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([URL(filePath: "/test"): []]), directories: [URL(filePath: "/test")])
    let picker = OutfitPicker(configService: fakeConfigService, cacheService: fakeCacheService, fileManager: fakeFileManager)
    
    let result = await picker.randomOutfit(from: "test")
    
    switch result {
    case .success(let outfit):
        #expect(outfit == nil)
    case .failure:
        Issue.record("Expected success")
    }
}

@Test("randomOutfit failure path")
func randomOutfitFailurePath() async {
    let failingConfigService = FakeConfigService(.throwsError(ConfigError.missingRoot))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(configService: failingConfigService, cacheService: fakeCacheService, fileManager: fakeFileManager)
    
    let result = await picker.randomOutfit(from: "test")
    
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.invalidConfiguration)
    }
}

@Test("wear success path")
func wearSuccessPath() async {
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([URL(filePath: "/test"): []]), directories: [URL(filePath: "/test")])
    let picker = OutfitPicker(configService: fakeConfigService, cacheService: fakeCacheService, fileManager: fakeFileManager)
    let outfit = OutfitReference(fileName: "", category: CategoryReference(name: "test", path: "/test"))
    
    let result = await picker.wear(outfit)
    
    switch result {
    case .success:
        Issue.record("Expected failure for empty filename")
    case .failure(let error):
        #expect(error == OutfitPickerError.invalidInput("Outfit filename cannot be empty"))
    }
}

@Test("wear failure path")
func wearFailurePath() async {
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let failingCacheService = FakeCacheService(.throwsOnLoad(CacheError.decodingFailed))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(configService: fakeConfigService, cacheService: failingCacheService, fileManager: fakeFileManager)
    let outfit = OutfitReference(fileName: "test.avatar", category: CategoryReference(name: "test", path: "/test"))
    
    let result = await picker.wear(outfit)
    
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.noOutfitsAvailable)
    }
}

@Test("availableCategories success path")
func availableCategoriesSuccessPath() async {
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([URL(filePath: "/test"): []]), directories: [URL(filePath: "/test")])
    let picker = OutfitPicker(configService: fakeConfigService, cacheService: fakeCacheService, fileManager: fakeFileManager)
    
    let result = await picker.availableCategories()
    
    switch result {
    case .success(let categories):
        #expect(categories.isEmpty)
    case .failure:
        Issue.record("Expected success")
    }
}

@Test("availableCategories failure path")
func availableCategoriesFailurePath() async {
    struct CustomError: Error {}
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let failingFileManager = FakeFileManager(.throwsError(CustomError()))
    let picker = OutfitPicker(configService: fakeConfigService, cacheService: fakeCacheService, fileManager: failingFileManager)
    
    let result = await picker.availableCategories()
    
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.fileSystemError)
    }
}

@Test("reset success path")
func resetSuccessPath() async {
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(configService: fakeConfigService, cacheService: fakeCacheService, fileManager: fakeFileManager)
    
    let result = await picker.reset(category: "test")
    
    switch result {
    case .success:
        break
    case .failure:
        Issue.record("Expected success")
    }
}

@Test("reset failure path")
func resetFailurePath() async {
    let failingConfigService = FakeConfigService(.throwsError(StorageError.diskFull))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(configService: failingConfigService, cacheService: fakeCacheService, fileManager: fakeFileManager)
    
    let result = await picker.reset(category: "test")
    
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.cacheError)
    }
}