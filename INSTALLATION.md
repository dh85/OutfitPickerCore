# OutfitPicker Installation Guide

This guide covers all the ways to install and integrate OutfitPicker into your Swift projects.

## Requirements

- **iOS**: 13.0+
- **macOS**: 10.15+
- **tvOS**: 13.0+
- **watchOS**: 6.0+
- **Swift**: 5.9+
- **Xcode**: 15.0+

## Installation Methods

### 1. Swift Package Manager (Recommended)

Swift Package Manager is the recommended way to install OutfitPicker.

#### Using Xcode

1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Enter the repository URL:
   ```
   https://github.com/yourusername/OutfitPicker
   ```
4. Choose the version you want to use:
   - **Up to Next Major**: Recommended for most projects
   - **Up to Next Minor**: For more conservative updates
   - **Exact Version**: For maximum stability
5. Select the target where you want to add OutfitPicker
6. Click **Add Package**

#### Using Package.swift

Add OutfitPicker as a dependency in your `Package.swift` file:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourProject",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/OutfitPicker", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: [
                .product(name: "OutfitPickerCore", package: "OutfitPicker")
            ]
        )
    ]
)
```

Then run:
```bash
swift package resolve
```

### 2. Manual Installation

If you prefer to manually integrate OutfitPicker:

1. Download the source code from the repository
2. Drag the `Sources/OutfitPickerCore` folder into your Xcode project
3. Make sure to add it to your target's dependencies
4. Import `OutfitPickerCore` in your Swift files

## Verification

After installation, verify that OutfitPicker is working correctly:

```swift
import OutfitPickerCore

// This should compile without errors
let configService = ConfigService()
print("OutfitPicker installed successfully!")
```

## Project Setup

### 1. Create Outfit Directory Structure

Set up your outfit directory structure:

```bash
mkdir -p ~/Outfits/{casual,formal,work,sports}
```

### 2. Add Outfit Files

Create `.avatar` files for your outfits:

```bash
# Example outfit files
touch ~/Outfits/casual/jeans-tshirt.avatar
touch ~/Outfits/casual/dress-summer.avatar
touch ~/Outfits/formal/suit-black.avatar
touch ~/Outfits/work/business-casual.avatar
```

### 3. Basic Configuration

Create a basic configuration in your app:

```swift
import OutfitPickerCore

class OutfitManager {
    private let picker: OutfitPicker
    
    init() throws {
        // Setup configuration service
        let configService = ConfigService()
        
        // Create configuration
        let config = try Config(root: "~/Outfits")
        try configService.save(config)
        
        // Initialize picker
        self.picker = OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    func getRandomOutfit() async throws -> String? {
        let outfit = try await picker.showRandomOutfit(from: "casual")
        return outfit?.fileName
    }
}
```

## Integration Examples

### iOS App Integration

```swift
import SwiftUI
import OutfitPickerCore

@main
struct OutfitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var outfitManager = OutfitManager()
    
    var body: some View {
        VStack {
            Text("Today's Outfit")
                .font(.title)
            
            if let outfit = outfitManager.currentOutfit {
                Text(outfit)
                    .font(.headline)
            }
            
            Button("Get New Outfit") {
                Task {
                    await outfitManager.selectNewOutfit()
                }
            }
        }
        .padding()
    }
}

@MainActor
class OutfitManager: ObservableObject {
    @Published var currentOutfit: String?
    private let picker: OutfitPicker
    
    init() {
        do {
            let configService = ConfigService()
            let config = try Config(root: getOutfitDirectory())
            try configService.save(config)
            
            self.picker = OutfitPicker(
                configService: configService,
                fileManager: FileManager.default
            )
        } catch {
            fatalError("Failed to initialize OutfitPicker: \(error)")
        }
    }
    
    func selectNewOutfit() async {
        do {
            let outfit = try await picker.showRandomOutfit(from: "casual")
            currentOutfit = outfit?.fileName
            
            if let outfit = outfit {
                try await picker.wearOutfit(outfit)
            }
        } catch {
            print("Error selecting outfit: \(error)")
        }
    }
    
    private func getOutfitDirectory() -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("Outfits").path
    }
}
```

### macOS Command Line Tool

```swift
import Foundation
import OutfitPickerCore

@main
struct OutfitCLI {
    static func main() async {
        do {
            let picker = try setupOutfitPicker()
            
            if CommandLine.arguments.contains("--random") {
                await selectRandomOutfit(picker: picker)
            } else if CommandLine.arguments.contains("--status") {
                await showStatus(picker: picker)
            } else {
                showHelp()
            }
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }
    
    static func setupOutfitPicker() throws -> OutfitPicker {
        let configService = ConfigService()
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let outfitDirectory = homeDirectory.appendingPathComponent("Outfits")
        
        let config = try Config(root: outfitDirectory.path)
        try configService.save(config)
        
        return OutfitPicker(
            configService: configService,
            fileManager: FileManager.default
        )
    }
    
    static func selectRandomOutfit(picker: OutfitPicker) async {
        do {
            let categories = try await picker.getCategories()
            guard !categories.isEmpty else {
                print("No outfit categories found")
                return
            }
            
            let randomCategory = categories.randomElement()!
            if let outfit = try await picker.showRandomOutfit(from: randomCategory.name) {
                print("Today's outfit: \(outfit.fileName) from \(randomCategory.name)")
                try await picker.wearOutfit(outfit)
            } else {
                print("No outfits available in \(randomCategory.name)")
            }
        } catch {
            print("Error selecting outfit: \(error)")
        }
    }
    
    static func showStatus(picker: OutfitPicker) async {
        do {
            let categories = try await picker.getCategories()
            print("Wardrobe Status:")
            
            for category in categories {
                let available = try await picker.getAvailableCount(for: category.name)
                let total = try await picker.showAllOutfits(from: category.name).count
                print("  \(category.name): \(available)/\(total) available")
            }
        } catch {
            print("Error getting status: \(error)")
        }
    }
    
    static func showHelp() {
        print("""
        OutfitPicker CLI
        
        Usage:
          outfit-cli --random    Select a random outfit
          outfit-cli --status    Show wardrobe status
          outfit-cli --help      Show this help
        """)
    }
}
```

## Troubleshooting

### Common Issues

#### 1. Configuration Not Found

**Error**: `OutfitPickerError.configurationNotFound`

**Solution**: Make sure you've created and saved a configuration:

```swift
let configService = ConfigService()
let config = try Config(root: "/path/to/your/outfits")
try configService.save(config)
```

#### 2. No Outfits Available

**Error**: `OutfitPickerError.noOutfitsAvailable`

**Solutions**:
- Check that your outfit directory exists
- Ensure outfit files have the `.avatar` extension
- Verify the category name is correct

#### 3. Permission Denied

**Error**: `OutfitPickerError.fileSystemError`

**Solutions**:
- Check file system permissions for the outfit directory
- Ensure the app has access to the specified directory
- On macOS, you might need to grant Full Disk Access

#### 4. Invalid Path

**Error**: `ConfigError.restrictedPath` or `ConfigError.pathTraversalNotAllowed`

**Solutions**:
- Use absolute paths without `..` or symbolic links
- Avoid system directories like `/etc`, `/usr/bin`
- Use user directories like `~/Documents/Outfits`

### Debug Mode

Enable debug logging to troubleshoot issues:

```swift
// Add this to see more detailed error information
do {
    let outfit = try await picker.showRandomOutfit(from: "casual")
} catch let error as OutfitPickerError {
    print("OutfitPicker error: \(error.localizedDescription)")
} catch {
    print("Unexpected error: \(error)")
}
```

### File System Verification

Verify your outfit directory structure:

```swift
func verifyOutfitDirectory(_ path: String) {
    let fileManager = FileManager.default
    let url = URL(fileURLWithPath: path)
    
    do {
        let contents = try fileManager.contentsOfDirectory(at: url, 
                                                         includingPropertiesForKeys: nil)
        print("Found \(contents.count) items in outfit directory:")
        
        for item in contents {
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory)
            
            if isDirectory.boolValue {
                let categoryContents = try fileManager.contentsOfDirectory(at: item, 
                                                                         includingPropertiesForKeys: nil)
                let avatarFiles = categoryContents.filter { $0.pathExtension == "avatar" }
                print("  \(item.lastPathComponent)/: \(avatarFiles.count) outfits")
            }
        }
    } catch {
        print("Error reading directory: \(error)")
    }
}

// Usage
verifyOutfitDirectory("~/Outfits")
```

## Next Steps

After successful installation:

1. **Read the [API Documentation](README.md)** for detailed usage information
2. **Check out [Examples](EXAMPLES.md)** for practical implementation patterns
3. **Set up your outfit directory structure** with `.avatar` files
4. **Start with basic outfit selection** and gradually add more features

## Support

If you encounter issues:

1. Check this troubleshooting guide
2. Review the [Examples](EXAMPLES.md) for similar use cases
3. Open an issue on GitHub with:
   - Your platform and Swift version
   - Complete error messages
   - Minimal reproduction code
   - Your outfit directory structure