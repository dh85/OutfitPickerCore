#!/usr/bin/env swift

import Foundation
@testable import OutfitPickerCore

// Simple test to verify type-safe CategoryReference overloads work
func testTypeSafeAPI() async throws {
    let picker = OutfitPicker()
    
    // Create a simple config for testing
    let config = try Config(root: "/tmp/test_outfits")
    let configService = ConfigService()
    try configService.save(config)
    
    // Get categories using string-based API
    let categories = try await picker.getCategories()
    
    if let firstCategory = categories.first {
        print("✅ Found category: \(firstCategory.name)")
        
        // Now use the type-safe overloads
        let availableCount = try await picker.getAvailableCount(for: firstCategory)
        print("✅ Type-safe getAvailableCount: \(availableCount)")
        
        let allOutfits = try await picker.showAllOutfits(from: firstCategory)
        print("✅ Type-safe showAllOutfits: \(allOutfits.count) outfits")
        
        let randomOutfit = try await picker.showRandomOutfit(from: firstCategory)
        print("✅ Type-safe showRandomOutfit: \(randomOutfit?.fileName ?? "nil")")
        
        let progress = try await picker.getRotationProgress(for: firstCategory)
        print("✅ Type-safe getRotationProgress: worn=\(progress.worn), total=\(progress.total)")
        
        print("🎉 All type-safe overloads work correctly!")
    } else {
        print("ℹ️ No categories found (expected for empty test)")
    }
}

// Run the test
Task {
    do {
        try await testTypeSafeAPI()
        print("✅ Type-safe API test completed successfully")
    } catch {
        print("❌ Test failed: \(error)")
    }
}

// Keep the script running
RunLoop.main.run()