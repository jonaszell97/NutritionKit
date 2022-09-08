
import Foundation

struct NutritionLabel {
    /// The language of the label.
    let language: LabelLanguage
    
    /// The serving size of the label.
    var servingSize: ServingSize?
    
    /// The nutrition facts that were scanned.
    var nutritionFacts: [NutritionItem: NutritionAmount]
}

enum KnownLabel: String, CaseIterable {
    /// The nutriition facts headline.
    case nutritionFacts
    
    /// The serving size label.
    case servingSize
    
    /// A 'per serving' indicator.
    case perServing
    
    /// A 'per container' indiciator
    case perContainer
}

// MARK: Utility extensions

extension NutritionLabel {
    /// Whether or not this label contains enough data to be considered valid.
    var isValid: Bool {
        var score = 0
        
        if servingSize != nil {
            score += 1
        }
        
        score += self.nutritionFacts.count
        return score >= 5
    }
}

// MARK: Codable, Hashable

extension NutritionLabel: Codable {
    enum CodingKeys: String, CodingKey {
        case language, servingSize, nutritionFacts
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(servingSize, forKey: .servingSize)
        try container.encode(nutritionFacts, forKey: .nutritionFacts)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            language: try container.decode(LabelLanguage.self, forKey: .language),
            servingSize: try container.decode(Optional<ServingSize>.self, forKey: .servingSize),
            nutritionFacts: try container.decode(Dictionary<NutritionItem, NutritionAmount>.self, forKey: .nutritionFacts)
        )
    }
}

extension NutritionLabel: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.language == rhs.language
            && lhs.servingSize == rhs.servingSize
            && lhs.nutritionFacts == rhs.nutritionFacts
        )
    }
}

extension NutritionLabel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(language)
        hasher.combine(servingSize)
        hasher.combine(nutritionFacts)
    }
}

extension KnownLabel: Hashable, Codable {
    
}
