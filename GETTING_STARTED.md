# Getting Started with OutfitPicker

Welcome to OutfitPicker! This guide will help you get up and running quickly with intelligent outfit selection and rotation management.

## What is OutfitPicker?

OutfitPicker is a Swift library that helps you manage your wardrobe by:
- **Preventing outfit repetition** until all outfits in a category have been worn
- **Organizing outfits** into categories (casual, formal, work, etc.)
- **Tracking worn outfits** automatically
- **Providing search and filtering** capabilities
- **Supporting batch operations** for efficient management

## Quick Start (5 minutes)

### 1. Install OutfitPicker

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/OutfitPicker", from: "1.0.0")
]
```

Or use Xcode: **File** → **Add Package Dependencies** → Enter URL

### 2. Set Up Your Outfit Directory

Create a simple directory structure:

```
~/Outfits/
├── casual/
│   ├── jeans-tshirt.avatar
│   └── dress-summer.avatar
└── work/
    └── suit-navy.avatar
```

### 3. Write Your First Code

```swift
import OutfitPickerCore

// Setup
let configService = ConfigService()
let config = try Config(root: "~/Outfits")
try configService.save(config)

let picker = OutfitPicker(
    configService: configService,
    fileManager: FileManager.default
)

// Get a random outfit
if let outfit = try await picker.showRandomOutfit(from: "casual") {
    print("Wear: \(outfit.fileName)")
    
    // Mark it as worn
    try await picker.wearOutfit(outfit)
}
```

That's it! You now have intelligent outfit rotation working.

## Core Concepts

### Outfit Files
- Outfit files must have the `.avatar` extension
- File names become the outfit names (e.g., `blue-shirt.avatar` → "blue-shirt")
- Store them in category directories

### Categories
- Organize outfits by type: `casual/`, `formal/`, `work/`, `sports/`
- Each category tracks its own rotation independently
- Categories are discovered automatically from your directory structure

### Rotation Logic
- OutfitPicker prevents repeating outfits until all in a category have been worn
- When all outfits are worn, the rotation resets automatically
- You can manually reset categories anytime

## Common Use Cases

### Daily Outfit Selection

```swift
class DailyOutfitSelector {
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
    
    func getTodaysOutfit(for category: String) async throws -> String? {
        guard let outfit = try await picker.showRandomOutfit(from: category) else {
            return nil
        }
        
        try await picker.wearOutfit(outfit)
        return outfit.fileName
    }
}

// Usage
let selector = try DailyOutfitSelector(outfitDirectory: "~/Outfits")
if let outfit = try await selector.getTodaysOutfit(for: "work") {
    print("Today's work outfit: \(outfit)")
}
```

### Wardrobe Status Check

```swift
func checkWardrobeStatus() async throws {
    let categories = try await picker.getCategories()
    
    for category in categories {
        let available = try await picker.getAvailableCount(for: category.name)
        let total = try await picker.showAllOutfits(from: category.name).count
        print("\(category.name): \(available)/\(total) available")
    }
}
```

### Search Your Wardrobe

```swift
// Find all blue outfits
let blueOutfits = try await picker.searchOutfits(pattern: "blue")
print("Blue outfits: \(blueOutfits.map { $0.fileName })")

// Find work-related categories
let workCategories = try await picker.filterCategories(pattern: "work")
print("Work categories: \(workCategories.map { $0.name })")
```

## Best Practices

### 1. Organize Your Directory Structure

```
Outfits/
├── casual/           # Everyday wear
├── work/            # Professional attire
├── formal/          # Special occasions
├── sports/          # Athletic wear
├── seasonal/        # Season-specific
└── accessories/     # Optional: accessories
```

### 2. Use Descriptive File Names

Good examples:
- `navy-blazer-khakis.avatar`
- `floral-dress-summer.avatar`
- `jeans-white-tshirt.avatar`

Avoid:
- `outfit1.avatar`
- `a.avatar`
- `temp.avatar`

### 3. Handle Errors Gracefully

```swift
do {
    let outfit = try await picker.showRandomOutfit(from: "casual")
} catch OutfitPickerError.noOutfitsAvailable {
    print("No casual outfits available - time to do laundry!")
} catch OutfitPickerError.categoryNotFound {
    print("Casual category doesn't exist")
} catch {
    print("Unexpected error: \(error)")
}
```

### 4. Sync with File System Changes

```swift
// When you add/remove outfit files
let changes = try await picker.detectChanges()
try await picker.updateConfig(with: changes)
```

## iOS App Integration

Here's a complete SwiftUI example:

```swift
import SwiftUI
import OutfitPickerCore

@main
struct OutfitApp: App {
    var body: some Scene {
        WindowGroup {
            OutfitView()
        }
    }
}

struct OutfitView: View {
    @StateObject private var viewModel = OutfitViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let outfit = viewModel.currentOutfit {
                    VStack {
                        Text("Today's Outfit")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text(outfit.fileName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("from \(outfit.category.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                HStack {
                    Button("Casual") {
                        Task { await viewModel.selectOutfit(from: "casual") }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Work") {
                        Task { await viewModel.selectOutfit(from: "work") }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Formal") {
                        Task { await viewModel.selectOutfit(from: "formal") }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .padding()
            .navigationTitle("OutfitPicker")
        }
    }
}

@MainActor
class OutfitViewModel: ObservableObject {
    @Published var currentOutfit: OutfitReference?
    @Published var isLoading = false
    
    private let picker: OutfitPicker
    
    init() {
        do {
            let configService = ConfigService()
            let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                       in: .userDomainMask).first!
            let outfitPath = documentsPath.appendingPathComponent("Outfits").path
            
            let config = try Config(root: outfitPath)
            try configService.save(config)
            
            self.picker = OutfitPicker(
                configService: configService,
                fileManager: FileManager.default
            )
        } catch {
            fatalError("Failed to initialize OutfitPicker: \(error)")
        }
    }
    
    func selectOutfit(from category: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let outfit = try await picker.showRandomOutfit(from: category) {
                currentOutfit = outfit
                try await picker.wearOutfit(outfit)
            }
        } catch {
            print("Error selecting outfit: \(error)")
        }
    }
}
```

## Next Steps

Now that you have the basics working:

1. **Explore Advanced Features**:
   - [Batch operations](EXAMPLES.md#batch-operations) for managing multiple outfits
   - [Search and filtering](EXAMPLES.md#search-and-discovery) for finding specific outfits
   - [Wardrobe analysis](EXAMPLES.md#wardrobe-management) for usage insights

2. **Read the Full Documentation**:
   - [README.md](README.md) - Complete API reference
   - [EXAMPLES.md](EXAMPLES.md) - Comprehensive usage examples
   - [INSTALLATION.md](INSTALLATION.md) - Detailed installation guide

3. **Customize for Your Needs**:
   - Add more categories that match your lifestyle
   - Implement preferences and smart recommendations
   - Build UI components for your specific platform

## Troubleshooting

**No outfits found?**
- Check that your outfit files have the `.avatar` extension
- Verify the directory path is correct
- Ensure the category directory exists

**Permission errors?**
- Make sure your app has access to the outfit directory
- Use directories within your app's sandbox on iOS

**Configuration not found?**
- Always create and save a configuration before using the picker
- Check that the ConfigService is properly initialized

## Get Help

- Check the [Installation Guide](INSTALLATION.md) for setup issues
- Browse [Examples](EXAMPLES.md) for implementation patterns
- Review the [API Documentation](README.md) for detailed method information

Happy outfit picking! 👔👗