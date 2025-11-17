import OutfitPickerCore

// MARK: - Basic Example: Handling Rotation Completion

func basicExample() async throws {
    let picker = OutfitPicker()
    
    // Select an outfit
    guard let outfit = try await picker.showRandomOutfit(from: "casual") else {
        print("No outfits available")
        return
    }
    
    print("Selected: \(outfit.fileName)")
    
    // Mark it as worn
    do {
        try await picker.wearOutfit(outfit)
        print("✓ Outfit marked as worn")
    } catch OutfitPickerError.rotationCompleted(let category) {
        print("🎉 All outfits in '\(category)' have been worn!")
        print("✓ Category reset - starting fresh rotation")
    }
}

// MARK: - CLI Example: Complete Workflow

func cliExample() async throws {
    let picker = OutfitPicker()
    let category = "work"
    
    // Show progress
    let (worn, total) = try await picker.getRotationProgress(for: category)
    print("Progress: \(worn)/\(total) outfits worn")
    
    // Select outfit
    guard let outfit = try await picker.showRandomOutfit(from: category) else {
        print("No outfits available")
        return
    }
    
    print("\nToday's outfit: \(outfit.fileName)")
    print("Wear this outfit? (y/n)")
    // Assume user confirms...
    
    // Mark as worn
    do {
        try await picker.wearOutfit(outfit)
        
        // Show updated progress
        let (newWorn, newTotal) = try await picker.getRotationProgress(for: category)
        print("✓ Marked as worn (\(newWorn)/\(newTotal))")
        
    } catch OutfitPickerError.rotationCompleted(let cat) {
        print("\n🎉 ROTATION COMPLETE!")
        print("You've worn all \(total) outfits in '\(cat)'")
        print("✓ Category has been reset")
        print("All outfits are now available again\n")
    }
}

// MARK: - Detailed Example: With Error Handling

func detailedExample() async throws {
    let picker = OutfitPicker()
    
    guard let outfit = try await picker.showRandomOutfit(from: "casual") else {
        return
    }
    
    do {
        try await picker.wearOutfit(outfit)
        print("Normal case: outfit worn, rotation continues")
        
    } catch OutfitPickerError.rotationCompleted(let category) {
        // This is NOT an error - it's a success notification!
        // The outfit was marked as worn AND the category was reset
        print("Special case: rotation completed for '\(category)'")
        print("Action taken: Category cache reset to 0 worn outfits")
        
    } catch OutfitPickerError.noOutfitsAvailable {
        print("Error: Outfit doesn't exist")
        
    } catch OutfitPickerError.invalidInput(let message) {
        print("Error: \(message)")
        
    } catch {
        print("Unexpected error: \(error)")
    }
}

// MARK: - Real-World Scenario

func realWorldScenario() async throws {
    let picker = OutfitPicker()
    let category = "casual"
    
    // Day 1: 0/3 worn
    let outfit1 = try await picker.showRandomOutfit(from: category)!
    try await picker.wearOutfit(outfit1)
    print("Day 1: Wore \(outfit1.fileName) - 1/3 worn")
    
    // Day 2: 1/3 worn
    let outfit2 = try await picker.showRandomOutfit(from: category)!
    try await picker.wearOutfit(outfit2)
    print("Day 2: Wore \(outfit2.fileName) - 2/3 worn")
    
    // Day 3: 2/3 worn - this will complete the rotation!
    let outfit3 = try await picker.showRandomOutfit(from: category)!
    do {
        try await picker.wearOutfit(outfit3)
        print("Day 3: Wore \(outfit3.fileName) - 3/3 worn")
    } catch OutfitPickerError.rotationCompleted(let cat) {
        print("Day 3: Wore \(outfit3.fileName) - ROTATION COMPLETE! ✨")
        print("       Category '\(cat)' has been reset")
    }
    
    // Day 4: 0/3 worn - fresh start!
    let outfit4 = try await picker.showRandomOutfit(from: category)!
    try await picker.wearOutfit(outfit4)
    print("Day 4: Wore \(outfit4.fileName) - 1/3 worn (new rotation)")
}
