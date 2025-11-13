# OutfitPicker Examples

This document provides comprehensive examples of using the OutfitPicker library in various scenarios.

## Table of Contents

- [Basic Setup](#basic-setup)
- [Daily Outfit Selection](#daily-outfit-selection)
- [Wardrobe Management](#wardrobe-management)
- [Outfit Tracking](#outfit-tracking)
- [Search and Discovery](#search-and-discovery)
- [Batch Operations](#batch-operations)
- [Error Handling](#error-handling)
- [Advanced Usage](#advanced-usage)

## Basic Setup

### Simple Setup

```swift
import OutfitPickerCore

// Create services
let configService = ConfigService()
let picker = OutfitPicker(
    configService: configService,
    fileManager: FileManager.default
)

// Create and save configuration
let config = try Config(root: "/Users/yourname/Outfits")
try configService.save(config)
```

### Setup with Custom Configuration

```swift
import OutfitPickerCore

// Using ConfigBuilder for more options
let config = try ConfigBuilder()
    .rootDirectory("/Users/yourname/Outfits")
    .language(.english)
    .exclude("damaged", "too-small", "out-of-season")
    .build()

let configService = ConfigService()
try configService.save(config)

let picker = OutfitPicker(
    configService: configService,
    fileManager: FileManager.default
)
```

## Daily Outfit Selection

### Morning Outfit Picker

```swift
class MorningOutfitPicker {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        let configService = ConfigService()
        let config = try Config(root: outfitDirectory)
        try configService.save(config)
        
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    func selectTodaysOutfit(for occasion: String) async throws -> OutfitSelection? {
        // Get random outfit
        guard let outfit = try await picker.showRandomOutfit(from: occasion) else {
            return nil
        }
        
        // Get remaining count for context
        let remaining = try await picker.getAvailableCount(for: occasion)
        
        return OutfitSelection(
            outfit: outfit,
            remainingInCategory: remaining
        )
    }
    
    func confirmOutfitWorn(_ selection: OutfitSelection) async throws {
        try await picker.wearOutfit(selection.outfit)
    }
    
    func getAlternatives(for category: String, excluding current: OutfitReference) async throws -> [OutfitReference] {
        let allOutfits = try await picker.showAllOutfits(from: category)
        return allOutfits.filter { $0.fileName != current.fileName }
    }
}

struct OutfitSelection {
    let outfit: OutfitReference
    let remainingInCategory: Int
    
    var description: String {
        "\(outfit.fileName) (\(remainingInCategory) remaining in \(outfit.category.name))"
    }
}

// Usage
let morningPicker = try MorningOutfitPicker(outfitDirectory: "/Users/me/Outfits")

// Select work outfit
if let selection = try await morningPicker.selectTodaysOutfit(for: "work") {
    print("Today's work outfit: \(selection.description)")
    
    // User confirms they're wearing it
    try await morningPicker.confirmOutfitWorn(selection)
} else {
    print("No work outfits available - time to do laundry!")
}
```

### Weekly Outfit Planner

```swift
class WeeklyOutfitPlanner {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        let configService = ConfigService()
        let config = try Config(root: outfitDirectory)
        try configService.save(config)
        
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    func planWeek(schedule: [String: String]) async throws -> WeeklyPlan {
        var plan = WeeklyPlan()
        
        for (day, category) in schedule {
            if let outfit = try await picker.showRandomOutfit(from: category) {
                plan.addOutfit(for: day, outfit: outfit)
            }
        }
        
        return plan
    }
    
    func executeDay(_ day: String, from plan: WeeklyPlan) async throws {
        guard let outfit = plan.getOutfit(for: day) else { return }
        try await picker.wearOutfit(outfit)
        print("Wearing \(outfit.fileName) for \(day)")
    }
}

struct WeeklyPlan {
    private var outfits: [String: OutfitReference] = [:]
    
    mutating func addOutfit(for day: String, outfit: OutfitReference) {
        outfits[day] = outfit
    }
    
    func getOutfit(for day: String) -> OutfitReference? {
        outfits[day]
    }
    
    var summary: String {
        outfits.map { "\($0.key): \($0.value.fileName)" }
               .joined(separator: "\n")
    }
}

// Usage
let planner = try WeeklyOutfitPlanner(outfitDirectory: "/Users/me/Outfits")

let schedule = [
    "Monday": "work",
    "Tuesday": "work", 
    "Wednesday": "casual",
    "Thursday": "work",
    "Friday": "casual",
    "Saturday": "casual",
    "Sunday": "formal"
]

let weekPlan = try await planner.planWeek(schedule: schedule)
print("This week's plan:\n\(weekPlan.summary)")

// Execute Monday
try await planner.executeDay("Monday", from: weekPlan)
```

## Wardrobe Management

### Wardrobe Analyzer

```swift
class WardrobeAnalyzer {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        let configService = ConfigService()
        let config = try Config(root: outfitDirectory)
        try configService.save(config)
        
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    func analyzeWardrobe() async throws -> WardrobeAnalysis {
        let categoryInfo = try await picker.getCategoryInfo()
        var analysis = WardrobeAnalysis()
        
        for info in categoryInfo {
            let available = try await picker.getAvailableCount(for: info.category.name)
            let total = info.category.outfits.count
            
            analysis.addCategory(
                name: info.category.name,
                total: total,
                available: available,
                state: info.state
            )
        }
        
        return analysis
    }
    
    func findUnderutilizedCategories() async throws -> [String] {
        let analysis = try await analyzeWardrobe()
        return analysis.categories
            .filter { $0.utilizationRate < 0.3 } // Less than 30% used
            .map { $0.name }
    }
    
    func syncWithFilesystem() async throws -> SyncResult {
        let changes = try await picker.detectChanges()
        try await picker.updateConfig(with: changes)
        
        return SyncResult(
            newCategories: changes.newCategories.count,
            deletedCategories: changes.deletedCategories.count,
            changedCategories: changes.changedCategories.count
        )
    }
}

struct WardrobeAnalysis {
    var categories: [CategoryAnalysis] = []
    
    mutating func addCategory(name: String, total: Int, available: Int, state: CategoryState) {
        categories.append(CategoryAnalysis(
            name: name,
            total: total,
            available: available,
            worn: total - available,
            state: state
        ))
    }
    
    var totalOutfits: Int { categories.reduce(0) { $0 + $1.total } }
    var totalWorn: Int { categories.reduce(0) { $0 + $1.worn } }
    var overallUtilization: Double { 
        totalOutfits > 0 ? Double(totalWorn) / Double(totalOutfits) : 0 
    }
}

struct CategoryAnalysis {
    let name: String
    let total: Int
    let available: Int
    let worn: Int
    let state: CategoryState
    
    var utilizationRate: Double {
        total > 0 ? Double(worn) / Double(total) : 0
    }
    
    var isFullyUtilized: Bool { available == 0 }
}

struct SyncResult {
    let newCategories: Int
    let deletedCategories: Int
    let changedCategories: Int
    
    var hasChanges: Bool {
        newCategories > 0 || deletedCategories > 0 || changedCategories > 0
    }
}

// Usage
let analyzer = try WardrobeAnalyzer(outfitDirectory: "/Users/me/Outfits")

// Analyze current wardrobe
let analysis = try await analyzer.analyzeWardrobe()
print("Total outfits: \(analysis.totalOutfits)")
print("Overall utilization: \(String(format: "%.1f%%", analysis.overallUtilization * 100))")

// Find underutilized categories
let underutilized = try await analyzer.findUnderutilizedCategories()
if !underutilized.isEmpty {
    print("Consider wearing more from: \(underutilized.joined(separator: ", "))")
}

// Sync with filesystem
let syncResult = try await analyzer.syncWithFilesystem()
if syncResult.hasChanges {
    print("Synced: +\(syncResult.newCategories) -\(syncResult.deletedCategories) ~\(syncResult.changedCategories)")
}
```

## Outfit Tracking

### Outfit History Tracker

```swift
class OutfitHistoryTracker {
    private let picker: OutfitPicker
    private var history: [OutfitHistoryEntry] = []
    
    init(outfitDirectory: String) throws {
        let configService = ConfigService()
        let config = try Config(root: outfitDirectory)
        try configService.save(config)
        
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    func selectAndTrackOutfit(from category: String, occasion: String) async throws -> OutfitReference? {
        guard let outfit = try await picker.showRandomOutfit(from: category) else {
            return nil
        }
        
        // Track the selection
        let entry = OutfitHistoryEntry(
            outfit: outfit,
            occasion: occasion,
            date: Date()
        )
        history.append(entry)
        
        // Mark as worn
        try await picker.wearOutfit(outfit)
        
        return outfit
    }
    
    func getRecentHistory(days: Int = 7) -> [OutfitHistoryEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return history.filter { $0.date >= cutoffDate }
    }
    
    func getMostWornOutfits(limit: Int = 5) -> [(outfit: String, count: Int)] {
        let counts = Dictionary(grouping: history) { $0.outfit.fileName }
            .mapValues { $0.count }
        
        return counts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (outfit: $0.key, count: $0.value) }
    }
    
    func getCategoryUsage() -> [String: Int] {
        Dictionary(grouping: history) { $0.outfit.category.name }
            .mapValues { $0.count }
    }
}

struct OutfitHistoryEntry {
    let outfit: OutfitReference
    let occasion: String
    let date: Date
    
    var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: date)): \(outfit.fileName) for \(occasion)"
    }
}

// Usage
let tracker = try OutfitHistoryTracker(outfitDirectory: "/Users/me/Outfits")

// Select and track outfits
_ = try await tracker.selectAndTrackOutfit(from: "work", occasion: "meeting")
_ = try await tracker.selectAndTrackOutfit(from: "casual", occasion: "weekend")
_ = try await tracker.selectAndTrackOutfit(from: "formal", occasion: "dinner")

// View recent history
let recentHistory = tracker.getRecentHistory(days: 7)
print("Recent outfits:")
recentHistory.forEach { print("  \($0.description)") }

// View most worn outfits
let mostWorn = tracker.getMostWornOutfits(limit: 3)
print("\nMost worn outfits:")
mostWorn.forEach { print("  \($0.outfit): \($0.count) times") }

// View category usage
let categoryUsage = tracker.getCategoryUsage()
print("\nCategory usage:")
categoryUsage.forEach { print("  \($0.key): \($0.value) times") }
```

## Search and Discovery

### Outfit Discovery Engine

```swift
class OutfitDiscoveryEngine {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        let configService = ConfigService()
        let config = try Config(root: outfitDirectory)
        try configService.save(config)
        
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    func discoverOutfits(matching criteria: SearchCriteria) async throws -> DiscoveryResult {
        var results = DiscoveryResult()
        
        // Search by pattern if provided
        if let pattern = criteria.pattern {
            let outfits = try await picker.searchOutfits(pattern: pattern)
            results.addOutfits(outfits, reason: "Matches '\(pattern)'")
        }
        
        // Filter by categories if provided
        if !criteria.categories.isEmpty {
            for category in criteria.categories {
                let outfits = try await picker.showAllOutfits(from: category)
                results.addOutfits(outfits, reason: "From \(category) category")
            }
        }
        
        // Find similar categories if pattern provided
        if let pattern = criteria.pattern {
            let categories = try await picker.filterCategories(pattern: pattern)
            for category in categories {
                let outfits = try await picker.showAllOutfits(from: category.name)
                results.addOutfits(outfits, reason: "From similar category '\(category.name)'")
            }
        }
        
        return results
    }
    
    func suggestOutfits(basedOn worn: [OutfitReference]) async throws -> [OutfitReference] {
        // Analyze worn outfits to find patterns
        let categories = Set(worn.map { $0.category.name })
        var suggestions: [OutfitReference] = []
        
        for category in categories {
            if let suggestion = try await picker.showRandomOutfit(from: category) {
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }
    
    func findUnexploredOutfits() async throws -> [OutfitReference] {
        let categories = try await picker.getCategories()
        var unexplored: [OutfitReference] = []
        
        for category in categories {
            let available = try await picker.getAvailableCount(for: category.name)
            let total = try await picker.showAllOutfits(from: category.name).count
            
            // If most outfits are still available, category is unexplored
            if Double(available) / Double(total) > 0.8 {
                let outfits = try await picker.showAllOutfits(from: category.name)
                unexplored.append(contentsOf: outfits)
            }
        }
        
        return unexplored
    }
}

struct SearchCriteria {
    let pattern: String?
    let categories: [String]
    
    init(pattern: String? = nil, categories: [String] = []) {
        self.pattern = pattern
        self.categories = categories
    }
}

struct DiscoveryResult {
    private var outfitsByReason: [String: [OutfitReference]] = [:]
    
    mutating func addOutfits(_ outfits: [OutfitReference], reason: String) {
        outfitsByReason[reason, default: []].append(contentsOf: outfits)
    }
    
    var allOutfits: [OutfitReference] {
        outfitsByReason.values.flatMap { $0 }
    }
    
    var summary: String {
        outfitsByReason.map { reason, outfits in
            "\(reason): \(outfits.count) outfits"
        }.joined(separator: "\n")
    }
}

// Usage
let discovery = try OutfitDiscoveryEngine(outfitDirectory: "/Users/me/Outfits")

// Search for blue outfits
let blueSearch = SearchCriteria(pattern: "blue")
let blueResults = try await discovery.discoverOutfits(matching: blueSearch)
print("Blue outfit discovery:\n\(blueResults.summary)")

// Search in specific categories
let workSearch = SearchCriteria(categories: ["work", "formal"])
let workResults = try await discovery.discoverOutfits(matching: workSearch)
print("\nWork outfit options: \(workResults.allOutfits.count)")

// Find unexplored outfits
let unexplored = try await discovery.findUnexploredOutfits()
print("\nUnexplored outfits: \(unexplored.count)")
```

## Batch Operations

### Batch Outfit Manager

```swift
class BatchOutfitManager {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        let configService = ConfigService()
        let config = try Config(root: outfitDirectory)
        try configService.save(config)
        
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    func markMultipleAsWorn(_ outfitNames: [String], in category: String) async throws {
        let allOutfits = try await picker.showAllOutfits(from: category)
        let toWear = allOutfits.filter { outfitNames.contains($0.fileName) }
        
        guard !toWear.isEmpty else {
            throw OutfitPickerError.noOutfitsAvailable
        }
        
        try await picker.wearOutfits(toWear)
        print("Marked \(toWear.count) outfits as worn in \(category)")
    }
    
    func resetSeasonalCategories(_ season: Season) async throws {
        let categories = season.categories
        try await picker.resetCategories(categories)
        print("Reset \(categories.count) \(season.name) categories")
    }
    
    func bulkCategoryReset(matching pattern: String) async throws -> Int {
        let categories = try await picker.filterCategories(pattern: pattern)
        let categoryNames = categories.map { $0.name }
        
        guard !categoryNames.isEmpty else { return 0 }
        
        try await picker.resetCategories(categoryNames)
        return categoryNames.count
    }
    
    func processOutfitBatch(_ batch: OutfitBatch) async throws -> BatchResult {
        var result = BatchResult()
        
        // Mark outfits as worn
        if !batch.toWear.isEmpty {
            try await picker.wearOutfits(batch.toWear)
            result.wornCount = batch.toWear.count
        }
        
        // Reset categories
        if !batch.categoriesToReset.isEmpty {
            try await picker.resetCategories(batch.categoriesToReset)
            result.resetCount = batch.categoriesToReset.count
        }
        
        return result
    }
}

enum Season {
    case spring, summer, fall, winter
    
    var name: String {
        switch self {
        case .spring: return "spring"
        case .summer: return "summer"
        case .fall: return "fall"
        case .winter: return "winter"
        }
    }
    
    var categories: [String] {
        switch self {
        case .spring: return ["spring", "light", "transitional"]
        case .summer: return ["summer", "beach", "vacation", "shorts"]
        case .fall: return ["fall", "autumn", "layers", "sweaters"]
        case .winter: return ["winter", "coats", "warm", "holiday"]
        }
    }
}

struct OutfitBatch {
    let toWear: [OutfitReference]
    let categoriesToReset: [String]
    
    init(toWear: [OutfitReference] = [], categoriesToReset: [String] = []) {
        self.toWear = toWear
        self.categoriesToReset = categoriesToReset
    }
}

struct BatchResult {
    var wornCount: Int = 0
    var resetCount: Int = 0
    
    var summary: String {
        "Processed: \(wornCount) outfits worn, \(resetCount) categories reset"
    }
}

// Usage
let batchManager = try BatchOutfitManager(outfitDirectory: "/Users/me/Outfits")

// Mark specific outfits as worn
try await batchManager.markMultipleAsWorn(
    ["blue-shirt.avatar", "jeans.avatar"], 
    in: "casual"
)

// Reset seasonal categories
try await batchManager.resetSeasonalCategories(.summer)

// Reset categories matching pattern
let resetCount = try await batchManager.bulkCategoryReset(matching: "old")
print("Reset \(resetCount) old categories")

// Process complex batch
let outfit1 = try await batchManager.picker.showRandomOutfit(from: "casual")
let outfit2 = try await batchManager.picker.showRandomOutfit(from: "work")

let batch = OutfitBatch(
    toWear: [outfit1, outfit2].compactMap { $0 },
    categoriesToReset: ["vacation", "beach"]
)

let result = try await batchManager.processBatch(batch)
print(result.summary)
```

## Error Handling

### Robust Error Handling

```swift
class RobustOutfitManager {
    private let picker: OutfitPicker
    
    init(outfitDirectory: String) throws {
        let configService = ConfigService()
        let config = try Config(root: outfitDirectory)
        try configService.save(config)
        
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    func safelySelectOutfit(from category: String) async -> OutfitSelectionResult {
        do {
            guard let outfit = try await picker.showRandomOutfit(from: category) else {
                return .noOutfitsAvailable(category: category)
            }
            
            try await picker.wearOutfit(outfit)
            return .success(outfit: outfit)
            
        } catch OutfitPickerError.configurationNotFound {
            return .configurationError("Configuration not found - please run setup")
            
        } catch OutfitPickerError.categoryNotFound {
            return .categoryError("Category '\(category)' doesn't exist")
            
        } catch OutfitPickerError.invalidInput(let message) {
            return .inputError(message)
            
        } catch OutfitPickerError.fileSystemError {
            return .systemError("File system error - check permissions")
            
        } catch {
            return .unknownError(error.localizedDescription)
        }
    }
    
    func safelyResetCategory(_ category: String) async -> ResetResult {
        do {
            try await picker.resetCategory(category)
            let available = try await picker.getAvailableCount(for: category)
            return .success(availableCount: available)
            
        } catch OutfitPickerError.invalidInput(let message) {
            return .inputError(message)
            
        } catch {
            return .error(error.localizedDescription)
        }
    }
    
    func performWithRetry<T>(
        operation: () async throws -> T,
        maxRetries: Int = 3
    ) async -> Result<T, Error> {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let result = try await operation()
                return .success(result)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    // Wait before retry
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000))
                }
            }
        }
        
        return .failure(lastError ?? OutfitPickerError.fileSystemError)
    }
}

enum OutfitSelectionResult {
    case success(outfit: OutfitReference)
    case noOutfitsAvailable(category: String)
    case configurationError(String)
    case categoryError(String)
    case inputError(String)
    case systemError(String)
    case unknownError(String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var errorMessage: String? {
        switch self {
        case .success: return nil
        case .noOutfitsAvailable(let category): return "No outfits available in \(category)"
        case .configurationError(let msg): return msg
        case .categoryError(let msg): return msg
        case .inputError(let msg): return msg
        case .systemError(let msg): return msg
        case .unknownError(let msg): return msg
        }
    }
}

enum ResetResult {
    case success(availableCount: Int)
    case inputError(String)
    case error(String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// Usage
let robustManager = try RobustOutfitManager(outfitDirectory: "/Users/me/Outfits")

// Safe outfit selection
let result = await robustManager.safelySelectOutfit(from: "work")
switch result {
case .success(let outfit):
    print("Selected: \(outfit.fileName)")
case .noOutfitsAvailable(let category):
    print("No outfits in \(category) - time to do laundry!")
default:
    if let error = result.errorMessage {
        print("Error: \(error)")
    }
}

// Operation with retry
let retryResult = await robustManager.performWithRetry {
    try await robustManager.picker.getCategories()
}

switch retryResult {
case .success(let categories):
    print("Found \(categories.count) categories")
case .failure(let error):
    print("Failed after retries: \(error)")
}
```

## Advanced Usage

### Custom Outfit Picker with Preferences

```swift
class SmartOutfitPicker {
    private let picker: OutfitPicker
    private var preferences: OutfitPreferences
    
    init(outfitDirectory: String, preferences: OutfitPreferences = OutfitPreferences()) throws {
        let configService = ConfigService()
        let config = try Config(root: outfitDirectory)
        try configService.save(config)
        
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
        self.preferences = preferences
    }
    
    func selectSmartOutfit(for context: OutfitContext) async throws -> SmartOutfitSelection? {
        // Get base category outfits
        let baseOutfits = try await picker.showAllOutfits(from: context.category)
        
        // Apply preferences and filters
        let filteredOutfits = applyPreferences(baseOutfits, context: context)
        
        // Select from filtered options
        guard !filteredOutfits.isEmpty else { return nil }
        
        let selectedOutfit = filteredOutfits.randomElement()!
        
        // Calculate confidence score
        let confidence = calculateConfidence(outfit: selectedOutfit, context: context)
        
        return SmartOutfitSelection(
            outfit: selectedOutfit,
            confidence: confidence,
            reasoning: generateReasoning(outfit: selectedOutfit, context: context)
        )
    }
    
    private func applyPreferences(_ outfits: [OutfitReference], context: OutfitContext) -> [OutfitReference] {
        return outfits.filter { outfit in
            // Apply color preferences
            if !preferences.preferredColors.isEmpty {
                let hasPreferredColor = preferences.preferredColors.contains { color in
                    outfit.fileName.localizedCaseInsensitiveContains(color)
                }
                if !hasPreferredColor { return false }
            }
            
            // Apply weather considerations
            if let weather = context.weather {
                switch weather {
                case .hot:
                    return !outfit.fileName.localizedCaseInsensitiveContains("sweater") &&
                           !outfit.fileName.localizedCaseInsensitiveContains("coat")
                case .cold:
                    return outfit.fileName.localizedCaseInsensitiveContains("sweater") ||
                           outfit.fileName.localizedCaseInsensitiveContains("coat") ||
                           outfit.fileName.localizedCaseInsensitiveContains("warm")
                case .rainy:
                    return !outfit.fileName.localizedCaseInsensitiveContains("white") &&
                           !outfit.fileName.localizedCaseInsensitiveContains("light")
                }
            }
            
            return true
        }
    }
    
    private func calculateConfidence(outfit: OutfitReference, context: OutfitContext) -> Double {
        var score = 0.5 // Base confidence
        
        // Boost for preferred colors
        for color in preferences.preferredColors {
            if outfit.fileName.localizedCaseInsensitiveContains(color) {
                score += 0.2
            }
        }
        
        // Boost for weather appropriateness
        if let weather = context.weather {
            switch weather {
            case .hot:
                if outfit.fileName.localizedCaseInsensitiveContains("light") ||
                   outfit.fileName.localizedCaseInsensitiveContains("summer") {
                    score += 0.2
                }
            case .cold:
                if outfit.fileName.localizedCaseInsensitiveContains("warm") ||
                   outfit.fileName.localizedCaseInsensitiveContains("winter") {
                    score += 0.2
                }
            case .rainy:
                if outfit.fileName.localizedCaseInsensitiveContains("dark") {
                    score += 0.1
                }
            }
        }
        
        return min(score, 1.0)
    }
    
    private func generateReasoning(outfit: OutfitReference, context: OutfitContext) -> String {
        var reasons: [String] = []
        
        reasons.append("Selected from \(context.category) category")
        
        for color in preferences.preferredColors {
            if outfit.fileName.localizedCaseInsensitiveContains(color) {
                reasons.append("Matches preferred color: \(color)")
            }
        }
        
        if let weather = context.weather {
            reasons.append("Appropriate for \(weather.description) weather")
        }
        
        return reasons.joined(separator: "; ")
    }
}

struct OutfitPreferences {
    let preferredColors: [String]
    let avoidedPatterns: [String]
    
    init(preferredColors: [String] = [], avoidedPatterns: [String] = []) {
        self.preferredColors = preferredColors
        self.avoidedPatterns = avoidedPatterns
    }
}

struct OutfitContext {
    let category: String
    let weather: Weather?
    let occasion: String?
    
    init(category: String, weather: Weather? = nil, occasion: String? = nil) {
        self.category = category
        self.weather = weather
        self.occasion = occasion
    }
}

enum Weather {
    case hot, cold, rainy
    
    var description: String {
        switch self {
        case .hot: return "hot"
        case .cold: return "cold"
        case .rainy: return "rainy"
        }
    }
}

struct SmartOutfitSelection {
    let outfit: OutfitReference
    let confidence: Double
    let reasoning: String
    
    var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }
    
    var description: String {
        "\(outfit.fileName) (\(confidencePercentage) confidence) - \(reasoning)"
    }
}

// Usage
let preferences = OutfitPreferences(
    preferredColors: ["blue", "black", "navy"],
    avoidedPatterns: ["stripes", "polka"]
)

let smartPicker = try SmartOutfitPicker(
    outfitDirectory: "/Users/me/Outfits",
    preferences: preferences
)

// Select outfit for cold work day
let context = OutfitContext(
    category: "work",
    weather: .cold,
    occasion: "meeting"
)

if let selection = try await smartPicker.selectSmartOutfit(for: context) {
    print("Smart selection: \(selection.description)")
} else {
    print("No suitable outfits found for the given context")
}
```

These examples demonstrate the full range of OutfitPicker capabilities, from simple daily outfit selection to advanced smart recommendations with preferences and context awareness.