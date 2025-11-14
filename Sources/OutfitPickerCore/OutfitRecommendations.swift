import Foundation

/// Context information for smart outfit recommendations.
public struct RecommendationContext {
    /// Weather conditions
    public let weather: WeatherCondition?
    /// Occasion or event type
    public let occasion: String?
    /// Time of day
    public let timeOfDay: TimeOfDay?
    /// User preferences
    public let preferences: [String]
    
    public init(
        weather: WeatherCondition? = nil,
        occasion: String? = nil,
        timeOfDay: TimeOfDay? = nil,
        preferences: [String] = []
    ) {
        self.weather = weather
        self.occasion = occasion
        self.timeOfDay = timeOfDay
        self.preferences = preferences
    }
}

/// Weather conditions for outfit recommendations.
public enum WeatherCondition: String, CaseIterable {
    case sunny, rainy, cold, hot, windy
    
    /// Keywords associated with this weather condition
    public var keywords: [String] {
        switch self {
        case .sunny: return ["light", "bright", "summer"]
        case .rainy: return ["waterproof", "dark", "covered"]
        case .cold: return ["warm", "sweater", "coat", "winter"]
        case .hot: return ["light", "breathable", "shorts", "summer"]
        case .windy: return ["secure", "fitted", "layers"]
        }
    }
}

/// Time of day for outfit recommendations.
public enum TimeOfDay: String, CaseIterable {
    case morning, afternoon, evening, night
    
    /// Keywords associated with this time of day
    public var keywords: [String] {
        switch self {
        case .morning: return ["casual", "comfortable", "fresh"]
        case .afternoon: return ["professional", "polished", "work"]
        case .evening: return ["elegant", "dressy", "formal"]
        case .night: return ["party", "dark", "glamorous"]
        }
    }
}

/// Smart outfit recommendation with confidence score and reasoning.
public struct OutfitRecommendation {
    /// The recommended outfit
    public let outfit: OutfitReference
    /// Confidence score (0.0 to 1.0)
    public let confidence: Double
    /// Human-readable explanation for the recommendation
    public let reasoning: String
    /// Context used for the recommendation
    public let context: RecommendationContext
    
    /// Confidence as a percentage string
    public var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }
}

extension OutfitPicker {
    /// Gets smart outfit recommendations based on context.
    ///
    /// Analyzes available outfits and ranks them based on the provided context,
    /// returning the best matches with confidence scores and explanations.
    ///
    /// - Parameters:
    ///   - categoryName: Category to search in
    ///   - context: Context for recommendations
    ///   - limit: Maximum number of recommendations to return
    /// - Returns: Array of recommendations sorted by confidence (highest first)
    /// - Throws: `OutfitPickerError` if category access fails
    ///
    /// ## Example
    /// ```swift
    /// let context = RecommendationContext(
    ///     weather: .cold,
    ///     occasion: "work",
    ///     preferences: ["blue", "professional"]
    /// )
    /// 
    /// let recommendations = try await picker.recommend(
    ///     from: "work",
    ///     context: context,
    ///     limit: 3
    /// )
    /// 
    /// for rec in recommendations {
    ///     print("\(rec.outfit.fileName) (\(rec.confidencePercentage)): \(rec.reasoning)")
    /// }
    /// ```
    public func recommend(
        from categoryName: String,
        context: RecommendationContext,
        limit: Int = 5
    ) async throws -> [OutfitRecommendation] {
        let allOutfits = try await showAllOutfits(from: categoryName)
        
        let recommendations = allOutfits.compactMap { outfit -> OutfitRecommendation? in
            let score = calculateRecommendationScore(outfit: outfit, context: context)
            guard score > 0.1 else { return nil } // Filter out very low scores
            
            let reasoning = generateRecommendationReasoning(outfit: outfit, context: context)
            
            return OutfitRecommendation(
                outfit: outfit,
                confidence: score,
                reasoning: reasoning,
                context: context
            )
        }
        
        return Array(recommendations
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit))
    }
    
    /// Type-safe version using CategoryReference.
    public func recommend(
        from category: CategoryReference,
        context: RecommendationContext,
        limit: Int = 5
    ) async throws -> [OutfitRecommendation] {
        return try await recommend(from: category.name, context: context, limit: limit)
    }
    
    private func calculateRecommendationScore(
        outfit: OutfitReference,
        context: RecommendationContext
    ) -> Double {
        var score = 0.5 // Base score
        let fileName = outfit.fileName.lowercased()
        
        // Weather-based scoring
        if let weather = context.weather {
            for keyword in weather.keywords {
                if fileName.contains(keyword.lowercased()) {
                    score += 0.2
                }
            }
        }
        
        // Time of day scoring
        if let timeOfDay = context.timeOfDay {
            for keyword in timeOfDay.keywords {
                if fileName.contains(keyword.lowercased()) {
                    score += 0.15
                }
            }
        }
        
        // Occasion scoring
        if let occasion = context.occasion {
            if fileName.contains(occasion.lowercased()) {
                score += 0.25
            }
        }
        
        // Preference scoring
        for preference in context.preferences {
            if fileName.contains(preference.lowercased()) {
                score += 0.1
            }
        }
        
        return min(score, 1.0)
    }
    
    private func generateRecommendationReasoning(
        outfit: OutfitReference,
        context: RecommendationContext
    ) -> String {
        var reasons: [String] = []
        let fileName = outfit.fileName.lowercased()
        
        if let weather = context.weather {
            for keyword in weather.keywords {
                if fileName.contains(keyword.lowercased()) {
                    reasons.append("suitable for \(weather.rawValue) weather")
                    break
                }
            }
        }
        
        if let occasion = context.occasion, fileName.contains(occasion.lowercased()) {
            reasons.append("appropriate for \(occasion)")
        }
        
        if let timeOfDay = context.timeOfDay {
            for keyword in timeOfDay.keywords {
                if fileName.contains(keyword.lowercased()) {
                    reasons.append("good for \(timeOfDay.rawValue)")
                    break
                }
            }
        }
        
        for preference in context.preferences {
            if fileName.contains(preference.lowercased()) {
                reasons.append("matches preference: \(preference)")
            }
        }
        
        return reasons.isEmpty ? "general recommendation" : reasons.joined(separator: ", ")
    }
}