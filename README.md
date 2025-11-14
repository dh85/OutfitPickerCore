# OutfitPicker

A Swift library for intelligent outfit selection and rotation management. OutfitPicker automatically tracks worn outfits and ensures you don't repeat outfits until all have been worn, making it perfect for daily outfit selection and wardrobe management.

## Features

- **Intelligent Rotation**: Automatically prevents outfit repetition until all outfits in a category have been worn
- **Category Management**: Organize outfits into categories (casual, formal, work, etc.)
- **Multiple API Styles**: Factory methods, fluent API, batch operations, and Result-based error handling
- **Smart Recommendations**: Context-aware outfit suggestions with confidence scoring
- **Batch Operations**: Efficiently mark multiple outfits as worn or reset multiple categories
- **Search & Filter**: Find outfits and categories by name patterns
- **Thread-Safe**: All operations are atomic and properly synchronized
- **Async/Await**: Modern Swift concurrency support throughout

## Installation

### Swift Package Manager

Add OutfitPicker to your project using Swift Package Manager:

#### Xcode
1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Enter the repository URL: `https://github.com/dh85/OutfitPickerCore`
4. Select the version you want to use
5. Click **Add Package**

#### Package.swift
Add the dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/dh85/OutfitPickerCore", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["OutfitPickerCore"]
    )
]
```

## Quick Start

### 1. Setup Your Outfit Directory

Create a directory structure for your outfits:

```
/Users/yourname/Outfits/
├── casual/
│   ├── jeans-tshirt.avatar
│   ├── shorts-polo.avatar
│   └── dress-casual.avatar
├── formal/
│   ├── suit-black.avatar
│   ├── dress-formal.avatar
│   └── blazer-pants.avatar
└── work/
    ├── business-casual.avatar
    └── professional.avatar
```

### 2. Basic Usage

```swift
import OutfitPickerCore

// Simple initialization with factory method
let picker = try OutfitPicker.create(outfitDirectory: "/Users/yourname/Outfits")

// Get a random outfit from casual category
if let outfit = try await picker.showRandomOutfit(from: "casual") {
    print("Today's outfit: \(outfit.fileName)")
    
    // Mark it as worn
    try await picker.wearOutfit(outfit)
}
```

## API Reference

### Initialization Options

```swift
// Factory method - simplest approach
let picker = try OutfitPicker.create(outfitDirectory: "/path/to/outfits")

// Builder pattern with configuration
let picker = try OutfitPicker.builder()
    .outfitDirectory("/path/to/outfits")
    .language(.spanish)
    .exclude("old", "damaged")
    .create()

// Simple initialization - automatic service setup
let picker = OutfitPicker()

// Advanced approach - custom service injection
let configService = ConfigService()
let cacheService = CacheService()
let picker = OutfitPicker(
    configService: configService,
    cacheService: cacheService,
    fileManager: FileManager.default
)
```

### Type-Safe Category API

```swift
// Get categories as type-safe references
let categories = try await picker.getCategories()

// Use CategoryReference for compile-time safety
if let casual = categories.first(where: { $0.name == "casual" }) {
    let outfit = try await picker.showRandomOutfit(from: casual)
    let available = try await picker.getAvailableCount(for: casual)
    try await picker.resetCategory(casual)
}
```

### Core Methods

#### Random Outfit Selection

```swift
// Get random outfit from specific category
let outfit = try await picker.showRandomOutfit(from: "casual")

// Get random outfit from any category
let outfit = try await picker.showRandomOutfitAcrossCategories()
```

#### Outfit Management

```swift
// Mark outfit as worn
try await picker.wearOutfit(outfit)

// Mark multiple outfits as worn
try await picker.wearOutfits([outfit1, outfit2, outfit3])

// Get all outfits from a category
let allOutfits = try await picker.showAllOutfits(from: "formal")
```

#### Category Information

```swift
// Get available categories
let categories = try await picker.getCategories()

// Get detailed category information
let categoryInfo = try await picker.getCategoryInfo()

// Get count of available (unworn) outfits
let available = try await picker.getAvailableCount(for: "work")
```

#### Reset Operations

```swift
// Reset specific category
try await picker.resetCategory("casual")

// Reset multiple categories
try await picker.resetCategories(["casual", "formal"])

// Reset all categories
try await picker.resetAllCategories()

// Partial reset (keep only N outfits as worn)
try await picker.partialReset(categoryName: "work", wornCount: 3)
```

#### Search & Filter

```swift
// Search for outfits by name
let blueOutfits = try await picker.searchOutfits(pattern: "blue")

// Filter categories by name
let workCategories = try await picker.filterCategories(pattern: "work")
```

#### Configuration Management

```swift
// Detect filesystem changes
let changes = try await picker.detectChanges()

// Update configuration with changes
try await picker.updateConfig(with: changes)
```

#### Convenience Methods

```swift
// Check if outfit exists
let exists = try await picker.outfitExists("blue-shirt.avatar", in: "casual")

// Check if outfit has been worn
let isWorn = try await picker.isOutfitWorn("blue-shirt.avatar", in: "casual")

// Get specific outfit reference
let outfit = try await picker.getOutfit("blue-shirt.avatar", from: "casual")

// Get rotation progress
let (worn, total) = try await picker.getRotationProgress(for: "casual")
let percentage = try await picker.getRotationProgressPercentage(for: "casual")
```

### Alternative API Styles

#### Result-Based API (No Throwing)

```swift
// Get outfit without throwing errors
let result = await picker.randomOutfit(from: "casual")
switch result {
case .success(let outfit):
    print("Selected: \(outfit.fileName)")
case .failure(let error):
    print("Error: \(error)")
}

// Chain operations with Result
let wearResult = await picker.randomOutfit(from: "casual")
    .flatMap { outfit in
        await picker.wear(outfit)
    }
```

#### Fluent API

```swift
// Select and wear in one fluent chain
let selection = try await picker.select(from: "casual")
let result = try await selection?.wear()

// Check alternatives before wearing
let alternatives = try await selection?.alternatives()
let isWorn = try await selection?.isWorn()

// Works with CategoryReference too
let categories = try await picker.getCategories()
let casualCategory = categories.first { $0.name == "casual" }!
let selection = try await picker.select(from: casualCategory)
```

#### Batch Operations

```swift
// Batch multiple operations
let result = try await picker.batch()
    .wear(outfit1, outfit2)
    .reset("formal", "work")
    .execute()

print("\(result.outfitsWorn) outfits worn, \(result.categoriesReset) categories reset")

// Batch with arrays
let result = try await picker.batch()
    .wear([outfit1, outfit2, outfit3])
    .resetCategories(["summer", "winter"])
    .execute()

// Batch with CategoryReference
let categories = try await picker.getCategories()
let result = try await picker.batch()
    .reset(categories)
    .execute()
```

#### Smart Recommendations

```swift
// Get context-aware recommendations
let recommendations = try await picker.recommendations()
    .forWeather(.sunny, temperature: 75)
    .excludingRecentlyWorn(days: 3)
    .withConfidence(minimum: 0.7)
    .generate()

for rec in recommendations {
    print("\(rec.outfit.fileName) - Confidence: \(rec.confidence)")
}

// Simple recommendations
let quickRecs = try await picker.recommendations().generate()
```

## Examples

### Daily Outfit Selection App

```swift
import OutfitPickerCore

class DailyOutfitManager {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        // Use factory method for simple setup
        picker = try OutfitPicker.create(outfitDirectory: outfitDirectory)
    }
    
    func getTodaysOutfit(for occasion: String) async throws -> String? {
        guard let outfit = try await picker.showRandomOutfit(from: occasion) else {
            return nil
        }
        
        // Mark as worn
        try await picker.wearOutfit(outfit)
        
        return outfit.fileName
    }
    
    func getWardrobeStatus() async throws -> [String: Int] {
        let categories = try await picker.getCategories()
        var status: [String: Int] = [:]
        
        for category in categories {
            let available = try await picker.getAvailableCount(for: category.name)
            status[category.name] = available
        }
        
        return status
    }
}

// Usage
let manager = try DailyOutfitManager(outfitDirectory: "/Users/me/Outfits")

// Get today's work outfit
if let outfit = try await manager.getTodaysOutfit(for: "work") {
    print("Wear: \(outfit)")
} else {
    print("No work outfits available")
}

// Check wardrobe status
let status = try await manager.getWardrobeStatus()
for (category, available) in status {
    print("\(category): \(available) outfits remaining")
}
```

### Wardrobe Management Tool

```swift
import OutfitPickerCore

class WardrobeManager {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        picker = try OutfitPicker.create(outfitDirectory: outfitDirectory)
    }
    
    func syncWithFilesystem() async throws {
        let changes = try await picker.detectChanges()
        
        if !changes.newCategories.isEmpty {
            print("New categories found: \(changes.newCategories.joined(separator: ", "))")
        }
        
        if !changes.deletedCategories.isEmpty {
            print("Deleted categories: \(changes.deletedCategories.joined(separator: ", "))")
        }
        
        try await picker.updateConfig(with: changes)
        print("Wardrobe synchronized")
    }
    
    func searchOutfits(containing term: String) async throws -> [String] {
        let results = try await picker.searchOutfits(pattern: term)
        return results.map { "\($0.category.name)/\($0.fileName)" }
    }
    
    func resetSeason(_ categories: [String]) async throws {
        try await picker.resetCategories(categories)
        print("Reset \(categories.count) seasonal categories")
    }
}

// Usage
let manager = try WardrobeManager(outfitDirectory: "/Users/me/Outfits")

// Sync with filesystem
try await manager.syncWithFilesystem()

// Find all blue outfits
let blueOutfits = try await manager.searchOutfits(containing: "blue")
print("Blue outfits: \(blueOutfits)")

// Reset summer categories
try await manager.resetSeason(["summer", "beach", "vacation"])
```

### Outfit Recommendation System

```swift
import OutfitPickerCore

class OutfitRecommendationSystem {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        picker = try OutfitPicker.create(outfitDirectory: outfitDirectory)
    }
    
    func getRecommendations(count: Int = 3) async throws -> [OutfitRecommendation] {
        let categories = try await picker.getCategories()
        var recommendations: [OutfitRecommendation] = []
        
        for category in categories.prefix(count) {
            if let outfit = try await picker.showRandomOutfit(from: category.name) {
                let available = try await picker.getAvailableCount(for: category.name)
                
                recommendations.append(OutfitRecommendation(
                    outfit: outfit,
                    category: category.name,
                    remainingInCategory: available
                ))
            }
        }
        
        return recommendations
    }
    
    func wearRecommendation(_ recommendation: OutfitRecommendation) async throws {
        try await picker.wearOutfit(recommendation.outfit)
    }
}

struct OutfitRecommendation {
    let outfit: OutfitReference
    let category: String
    let remainingInCategory: Int
    
    var description: String {
        "\(outfit.fileName) from \(category) (\(remainingInCategory) remaining)"
    }
}

// Usage with traditional API
let system = try OutfitRecommendationSystem(outfitDirectory: "/Users/me/Outfits")

// Get recommendations
let recommendations = try await system.getRecommendations(count: 3)
for (index, rec) in recommendations.enumerated() {
    print("\(index + 1). \(rec.description)")
}

// User selects recommendation 1
if let selected = recommendations.first {
    try await system.wearRecommendation(selected)
    print("Wearing: \(selected.outfit.fileName)")
}

// Usage with smart recommendations API
let smartRecs = try await system.picker.recommendations()
    .forWeather(.cloudy, temperature: 65)
    .excludingRecentlyWorn(days: 2)
    .generate()

for rec in smartRecs.prefix(3) {
    print("Smart pick: \(rec.outfit.fileName) (\(Int(rec.confidence * 100))% confidence)")
}
```

## Error Handling

OutfitPicker provides multiple error handling approaches:

### Traditional Throwing API

```swift
do {
    let outfit = try await picker.showRandomOutfit(from: "casual")
} catch OutfitPickerError.configurationNotFound {
    print("No configuration found - run setup first")
} catch OutfitPickerError.categoryNotFound {
    print("Category doesn't exist")
} catch OutfitPickerError.noOutfitsAvailable {
    print("No outfits available in this category")
} catch OutfitPickerError.invalidInput(let message) {
    print("Invalid input: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Result-Based API (No Throwing)

```swift
// Handle errors with Result type
let result = await picker.randomOutfit(from: "casual")
switch result {
case .success(let outfit):
    print("Selected: \(outfit.fileName)")
case .failure(OutfitPickerError.categoryNotFound):
    print("Category doesn't exist")
case .failure(OutfitPickerError.noOutfitsAvailable):
    print("No outfits available")
case .failure(let error):
    print("Error: \(error)")
}

// Chain operations with Result
let finalResult = await picker.randomOutfit(from: "casual")
    .flatMap { outfit in
        await picker.wear(outfit)
    }
```

## Configuration

### Basic Configuration

```swift
// Simple configuration
let config = try Config(root: "/path/to/outfits")

// Configuration with language
let config = try Config(
    root: "/path/to/outfits",
    language: "es"
)

// Configuration with excluded categories
let config = try Config(
    root: "/path/to/outfits",
    language: "en",
    excludedCategories: ["old", "damaged"]
)
```

### Using ConfigBuilder

```swift
let config = try ConfigBuilder()
    .rootDirectory("/Users/me/Outfits")
    .language(.spanish)
    .exclude("old", "damaged", "too-small")
    .build()
```

### Factory Method Configuration

```swift
// Simple factory method
let picker = try OutfitPicker.create(outfitDirectory: "/Users/me/Outfits")

// Builder pattern with factory
let picker = try OutfitPicker.builder()
    .outfitDirectory("/Users/me/Outfits")
    .language(.spanish)
    .exclude("old", "damaged")
    .create()
```

## File Structure

OutfitPicker expects outfit files to have the `.avatar` extension:

```
Outfits/
├── casual/
│   ├── outfit1.avatar
│   ├── outfit2.avatar
│   └── outfit3.avatar
├── formal/
│   ├── suit.avatar
│   └── dress.avatar
└── work/
    └── business.avatar
```

## Thread Safety

OutfitPicker is fully thread-safe and can be used from multiple concurrent contexts:

```swift
// Safe to call from multiple tasks
await withTaskGroup(of: Void.self) { group in
    group.addTask {
        _ = try? await picker.showRandomOutfit(from: "casual")
    }
    group.addTask {
        _ = try? await picker.getCategories()
    }
    group.addTask {
        _ = try? await picker.getCategoryInfo()
    }
}
```

## Requirements

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+
- Swift 6.2+
- Xcode 16.0+

## License

OutfitPicker is available under the MIT license. See the LICENSE file for more info.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.