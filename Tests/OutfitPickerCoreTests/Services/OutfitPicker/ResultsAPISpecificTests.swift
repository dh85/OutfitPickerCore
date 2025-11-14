import Testing
@testable import OutfitPickerCore
@testable import OutfitPickerTestSupport

@Test("randomOutfit error path")
func randomOutfitErrorPath() async {
    let failingConfigService = FakeConfigService(.throwsError(ConfigError.missingRoot))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(configService: failingConfigService, cacheService: fakeCacheService, fileManager: fakeFileManager)
    
    let result = await picker.randomOutfit(from: "casual")
    
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.invalidConfiguration)
    }
}

@Test("wear error path")
func wearErrorPath() async {
    let failingCacheService = FakeCacheService(.throwsOnLoad(CacheError.decodingFailed))
    let config = try! Config(root: "/test")
    let fakeConfigService = FakeConfigService(.ok(config))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(configService: fakeConfigService, cacheService: failingCacheService, fileManager: fakeFileManager)
    let outfit = OutfitReference(fileName: "test.avatar", category: CategoryReference(name: "casual", path: "/test/casual"))
    
    let result = await picker.wear(outfit)
    
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.noOutfitsAvailable)
    }
}

@Test("availableCategories error path")
func availableCategoriesErrorPath() async {
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

@Test("reset error path")
func resetErrorPath() async {
    let failingConfigService = FakeConfigService(.throwsError(StorageError.diskFull))
    let fakeCacheService = FakeCacheService(.ok(OutfitCache()))
    let fakeFileManager = FakeFileManager(.ok([:]))
    let picker = OutfitPicker(configService: failingConfigService, cacheService: fakeCacheService, fileManager: fakeFileManager)
    
    let result = await picker.reset(category: "casual")
    
    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == OutfitPickerError.cacheError)
    }
}