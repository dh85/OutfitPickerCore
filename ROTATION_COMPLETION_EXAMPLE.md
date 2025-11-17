# Rotation Completion Handling

When you wear an outfit that completes the rotation (all outfits in a category have been worn), `wearOutfit()` will:
1. Reset the category cache (clear all worn outfits)
2. Throw `OutfitPickerError.rotationCompleted(category: String)`

This allows your CLI/UI to notify the user that the rotation is complete.

## Example CLI Usage

```swift
import OutfitPickerCore

let picker = OutfitPicker()

// User selects an outfit
if let outfit = try await picker.showRandomOutfit(from: "casual") {
    print("Selected outfit: \(outfit.fileName)")
    
    // Mark it as worn
    do {
        try await picker.wearOutfit(outfit)
        print("✓ Outfit marked as worn")
    } catch OutfitPickerError.rotationCompleted(let category) {
        // Rotation completed! Category has been reset
        print("🎉 Congratulations! You've worn all outfits in '\(category)'")
        print("✓ Category has been reset - starting fresh rotation")
    } catch {
        print("Error: \(error)")
    }
}
```

## Scenario Example

Given a category with 3 outfits:
- outfit1.avatar
- outfit2.avatar  
- outfit3.avatar

### Workflow:

1. **Day 1**: Select outfit1 → wear it → Cache: 1/3 worn
2. **Day 2**: Select outfit2 → wear it → Cache: 2/3 worn
3. **Day 3**: Select outfit3 → wear it → **Rotation Complete!**
   - `wearOutfit()` throws `rotationCompleted(category: "casual")`
   - Cache is reset to 0/3 worn
   - UI shows: "All outfits worn! Category reset."

4. **Day 4**: Fresh start - all 3 outfits available again

## Benefits

- **User Feedback**: Users know when they've completed a rotation
- **Automatic Reset**: No manual intervention needed
- **Clean State**: Category automatically resets for next rotation
- **Motivation**: Gamification element - completing rotations feels rewarding
