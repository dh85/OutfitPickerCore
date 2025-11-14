# Type-Safe CategoryReference API

The OutfitPicker now provides type-safe overloads that accept `CategoryReference` instead of `String` parameters, eliminating typos and making the API much safer to use.

## Before (String-based, error-prone):

```swift
let categories = try await picker.getCategories()
if let firstCategory = categories.first {
    // Typo risk: "casaul" instead of "casual"
    let outfit = try await picker.showRandomOutfit(from: "casaul") // ❌ Runtime error
}
```

## After (Type-safe):

```swift
let categories = try await picker.getCategories()
if let firstCategory = categories.first {
    // This call is now type-safe and avoids typos!
    let outfit = try await picker.showRandomOutfit(from: firstCategory) // ✅ Compile-time safe
}
```

## Available Type-Safe Overloads:

All these methods now have CategoryReference overloads:

- `showRandomOutfit(from: CategoryReference)`
- `getAvailableCount(for: CategoryReference)`
- `resetCategory(_: CategoryReference)`
- `partialReset(category: CategoryReference, wornCount: Int)`
- `showAllOutfits(from: CategoryReference)`
- `getRotationProgress(for: CategoryReference)`

## Example Usage:

```swift
import OutfitPickerCore

let picker = OutfitPicker()

// Get categories using the existing API
let categories = try await picker.getCategories()

// Use type-safe overloads with CategoryReference
for category in categories {
    let available = try await picker.getAvailableCount(for: category)
    let progress = try await picker.getRotationProgress(for: category)
    
    print("\(category.name): \(available) available, \(progress.worn)/\(progress.total) worn")
    
    if let outfit = try await picker.showRandomOutfit(from: category) {
        print("Selected: \(outfit.fileName)")
        try await picker.wearOutfit(outfit)
    }
}
```

This eliminates the "stringly-typed" API issues and provides compile-time safety for category operations.