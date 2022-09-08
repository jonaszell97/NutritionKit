
import Foundation

enum NutritionItemCategory: String {
    /// A macro nutrient like carbs, protein and fat.
    case macronutrient
    
    /// A micro nutrient like sodium, iron, potassium.
    case micronutrient
    
    /// A vitamin.
    case vitamin
    
    /// A different type of nutrient.
    case other
}

enum NutritionItem: String, CaseIterable {
    /// Total caloric content
    case calories
    
    /// Caloric content from fat
    case caloriesFromFat
    
    /// Total fat content
    case fat
    
    /// Saturated fat as part of total fat
    case saturatedFat
    
    /// Unsatured fat as part of total fat
    case unsaturatedFat
    
    /// Monounsaturated fat as part of total fat
    case monounsaturatedFat
    
    /// Polyunsaturated fat as part of total fat
    case polyunsaturatedFat
    
    /// Omega-3 fatty acids
    case omega3FattyAcids
    
    /// Trans fat as part of total fat
    case transFat
    
    /// Total carbohydrates
    case carbohydrates
    
    /// Sugar content as part of total carbs
    case sugar
    
    /// Added sugar content
    case addedSugar
    
    /// Sugar acolohols as part of total carbs
    case sugarAlcohols
    
    /// Starch content as part of total carbs
    case starch
    
    /// Dietary fiber
    case dietaryFiber
    
    /// Total protein content
    case protein
    
    /// Salt
    case salt
    
    /// Sodium
    case sodium
    
    /// Cholesterol
    case cholesterol
    
    /// Vitamins
    case vitaminA, vitaminC, vitaminD, vitaminE, vitaminK
    case vitaminB1, vitaminB2, vitaminB6, vitaminB9, vitaminB12
    
    /// Other
    case caffeine, taurine, alcohol
    
    /// Minerals
    case magnesium, calcium, zinc, potassium, iron, fluoride,
         copper, chloride, phosphorus, iodine, chromium
}

extension NutritionItem {
    var category: NutritionItemCategory {
        switch self {
        case .calories:
            return .other
        case .caloriesFromFat:
            return .other
        case .fat:
            return .macronutrient
        case .saturatedFat:
            return .macronutrient
        case .unsaturatedFat:
            return .macronutrient
        case .monounsaturatedFat:
            return .macronutrient
        case .polyunsaturatedFat:
            return .macronutrient
        case .omega3FattyAcids:
            return .macronutrient
        case .transFat:
            return .macronutrient
        case .carbohydrates:
            return .macronutrient
        case .sugar:
            return .macronutrient
        case .addedSugar:
            return .macronutrient
        case .sugarAlcohols:
            return .macronutrient
        case .starch:
            return .macronutrient
        case .dietaryFiber:
            return .macronutrient
        case .protein:
            return .macronutrient
        case .salt:
            return .micronutrient
        case .sodium:
            return .micronutrient
        case .cholesterol:
            return .micronutrient
        case .vitaminA:
            fallthrough
        case .vitaminB1:
            fallthrough
        case .vitaminB2:
            fallthrough
        case .vitaminB6:
            fallthrough
        case .vitaminB9:
            fallthrough
        case .vitaminB12:
            fallthrough
        case .vitaminC:
            fallthrough
        case .vitaminD:
            fallthrough
        case .vitaminE:
            fallthrough
        case .vitaminK:
            return .vitamin
        case .caffeine:
            fallthrough
        case .taurine:
            fallthrough
        case .alcohol:
            fallthrough
        case .fluoride:
            fallthrough
        case .copper:
            fallthrough
        case .chloride:
            fallthrough
        case .phosphorus:
            fallthrough
        case .iodine:
            fallthrough
        case .chromium:
            fallthrough
        case .magnesium:
            fallthrough
        case .calcium:
            fallthrough
        case .zinc:
            fallthrough
        case .potassium:
            fallthrough
        case .iron:
            return .micronutrient
        }
    }
}

// MARK: Codable, Hashable

extension NutritionItem: Hashable, Codable {
    
}
