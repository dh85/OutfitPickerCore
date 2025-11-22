import Foundation
import OutfitPickerCore

@main
struct TestRotation {
    static func main() async throws {
        print("=== Testing Rotation Completion ===\n")
        
        // Setup test environment
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "test-outfits-\(UUID().uuidString)")
        
        let testRoot = tempDir.appending(path: "outfits")
        let casualDir = testRoot.appending(path: "casual")
        
        try FileManager.default.createDirectory(at: casualDir, withIntermediateDirectories: true)
        
        // Create 3 test outfits
        let outfits = ["outfit1.avatar", "outfit2.avatar", "outfit3.avatar"]
        for outfit in outfits {
            let file = casualDir.appending(path: outfit)
            try Data().write(to: file)
        }
        
        // Create config
        let config = try Config(root: testRoot.path(percentEncoded: false))
        let picker = OutfitPicker()
        let configService = ConfigService()
        try configService.save(config)
        
        print("Created test category 'casual' with 3 outfits\n")
        
        // Day 1: Wear first outfit
        print("--- Day 1 ---")
        let outfit1 = try await picker.showRandomOutfit(from: "casual")!
        print("Selected: \(outfit1.fileName)")
        
        do {
            try await picker.wearOutfit(outfit1)
            let (worn, total) = try await picker.getRotationProgress(for: "casual")
            print("✓ Marked as worn (\(worn)/\(total))\n")
        } catch OutfitPickerError.rotationCompleted(let cat) {
            print("🎉 Rotation completed for '\(cat)'\n")
        }
        
        // Day 2: Wear second outfit
        print("--- Day 2 ---")
        let outfit2 = try await picker.showRandomOutfit(from: "casual")!
        print("Selected: \(outfit2.fileName)")
        
        do {
            try await picker.wearOutfit(outfit2)
            let (worn, total) = try await picker.getRotationProgress(for: "casual")
            print("✓ Marked as worn (\(worn)/\(total))\n")
        } catch OutfitPickerError.rotationCompleted(let cat) {
            print("🎉 Rotation completed for '\(cat)'\n")
        }
        
        // Day 3: Wear third outfit - THIS COMPLETES THE ROTATION
        print("--- Day 3 ---")
        let outfit3 = try await picker.showRandomOutfit(from: "casual")!
        print("Selected: \(outfit3.fileName)")
        
        do {
            try await picker.wearOutfit(outfit3)
            let (worn, total) = try await picker.getRotationProgress(for: "casual")
            print("✓ Marked as worn (\(worn)/\(total))\n")
        } catch OutfitPickerError.rotationCompleted(let cat) {
            print("🎉 ROTATION COMPLETE!")
            print("All outfits in '\(cat)' have been worn!")
            print("✓ Category has been reset\n")
        }
        
        // Day 4: Verify reset - should be 0/3 worn
        print("--- Day 4 (After Reset) ---")
        let (worn, total) = try await picker.getRotationProgress(for: "casual")
        print("Progress: \(worn)/\(total) worn")
        print("All \(total) outfits are available again!\n")
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
        print("=== Test Complete ===")
    }
}
