
import Foundation

public enum LabelLanguage: String, Codable, Hashable {
    case english, german
}

extension NutritionItem: CustomStringConvertible {
    /// The localized name of this label.
    public var localizedName: String {
        NSLocalizedString("nutrient.\(self.rawValue)", comment: "")
    }
    
    public var description: String {
        localizedName
    }
    
    /// The known textual representations for this item in the English language.
    public static let knownLabelsEnglish: [NutritionItem: Set<String>] = [
        .calories: ["total calories", "calories", "total cal.", "cal."],
        .caloriesFromFat: ["calories from fat"],
        .fat: ["total fat", "fat"],
        .saturatedFat: ["saturated fat", "sat. fat"],
        .unsaturatedFat: ["unsaturated fat", "unsat. fat"],
        .monounsaturatedFat: ["monounsaturated fat"],
        .polyunsaturatedFat: ["polyunsaturated fat"],
        .omega3FattyAcids: ["omega 3 fatty acids", "omega-3 fatty acids", "omega 3", "omega-3"],
        .transFat: ["trans fat"],
        .carbohydrates: ["total carbohydrate", "total carbohydrates", "carbohydrates", "carbohydrate", "total carbs", "total carb.", "carbs", "carb."],
        .sugar: ["total sugars", "total sugar", "sugars", "sugar"],
        .addedSugar: ["incl. added sugars", "incl. added sugar", "added sugars", "added sugar"],
        .sugarAlcohols: ["sugar alcohols"],
        .starch: ["starch"],
        .dietaryFiber: ["dietary fibre", "dietary fiber", "total fibre", "total fiber", "fibre", "fiber"],
        .protein: ["total protein", "protein"],
        .salt: ["total salt", "salt"],
        .sodium: ["total sodium", "sodium"],
        .cholesterol: ["total cholesterol", "cholesterol", "cholest."],
        .vitaminA: ["vit. a", "vitamin a"],
        .vitaminB1: ["vit. b1", "vitamin b1"],
        .vitaminB2: ["vit. b2", "vitamin b2"],
        .vitaminB6: ["vit. b6", "vitamin b6"],
        .vitaminB9: ["vit. b9", "vitamin b9"],
        .vitaminB12: ["vit. b12", "vitamin b12"],
        .vitaminC: ["vit. c", "vitamin c"],
        .vitaminD: ["vit. d", "vitamin d"],
        .vitaminE: ["vit. e", "vitamin e"],
        .vitaminK: ["vit. k", "vitamin k"],
        .caffeine: ["caffeine"],
        .taurine: ["taurine"],
        .alcohol: ["alcohol", "alc.", "alc.%"],
        .magnesium: ["magnesium"],
        .zinc: ["zinc"],
        .potassium: ["potassium", "potas."],
        .calcium: ["calcium"],
        .iron: ["iron"],
        .fluoride: ["fluoride", "flouride"],
        .copper: ["copper"],
        .chloride: ["chloride"],
        .phosphorus: ["phosphorus"],
        .iodine: ["iodine"],
        .chromium: ["chromium"],
    ]
    
    /// The known textual representations for this item in the german language.
    public static let knownLabelsGerman: [NutritionItem: Set<String>] = [
        .calories: ["energie", "brennwert", "kalorien"],
        .fat: ["fett"],
        .saturatedFat: ["davon gesättigte fettsäuren", "davon ges. fettsäuren", "gesättigte fettsäuren", "ges. fettsäuren"],
        .unsaturatedFat: ["davon ungesättigte fettsäuren", "davon unges. fettsäuren", "ungesättigte fettsäuren", "unges. fettsäuren"],
        .monounsaturatedFat: ["davon einfach ungesättigte fettsäuren", "davon einfach unges. fettsäuren", "einfach ungesättigte fettsäuren", "einfach unges. fettsäuren"],
        .polyunsaturatedFat: ["davon mehrfach ungesättigte fettsäuren", "davon mehrfach unges. fettsäuren", "mehrfach ungesättigte fettsäuren", "mehrfach unges. fettsäuren"],
        .omega3FattyAcids: ["omega-3 fettsäuren", "omega 3 fettsäuren", "omega-3", "omega 3"],
        .transFat: [],
        .carbohydrates: ["kohlenhydrate"],
        .sugar: ["davon zucker", "zucker"],
        .addedSugar: [],
        .sugarAlcohols: ["davon mehrwertige alkohole", "mehrwertige alkohole"],
        .starch: ["davon stärke", "stärke"],
        .dietaryFiber: ["davon ballaststoffe", "ballaststoffe"],
        .protein: ["protein", "eiweiß", "eiweiss"],
        .salt: ["salz"],
        .sodium: ["natrium"],
        .cholesterol: ["cholesterin"],
        .vitaminA: ["vit. a", "vitamin a"],
        .vitaminB1: ["vit. b1", "vitamin b1"],
        .vitaminB2: ["vit. b2", "vitamin b2"],
        .vitaminB6: ["vit. b6", "vitamin b6"],
        .vitaminB9: ["vit. b9", "vitamin b9"],
        .vitaminB12: ["vit. b12", "vitamin b12"],
        .vitaminC: ["vit. c", "vitamin c"],
        .vitaminD: ["vit. d", "vitamin d"],
        .vitaminE: ["vit. e", "vitamin e"],
        .vitaminK: ["vit. k", "vitamin k"],
        .caffeine: ["koffein"],
        .taurine: ["taurin"],
        .alcohol: ["alkohol", "alk.", "alk.%"],
        .magnesium: ["magnesium"],
        .zinc: ["zink"],
        .potassium: ["kalium"],
        .calcium: ["kalzium"],
        .iron: ["eisen"],
        .fluoride: ["fluorid", "flourid"],
        .copper: ["kupfer"],
        .chloride: ["chlor"],
        .phosphorus: ["phosphor"],
        .iodine: ["iod", "jod"],
        .chromium: ["chrom"],
    ]
}

public extension KnownLabel {
    /// The known textual representations for this item in the English language.
    static let knownLabelsEnglish: [KnownLabel: Set<String>] = [
        .nutritionFacts: ["nutrition facts"],
        .servingSize: ["serving size", "serv. size"],
        .perServing: ["per serving", "/ serving", "/serving"],
        .perContainer: ["per container", "/ container", "/container"],
    ]
    
    /// The known textual representations for this item in the German language.
    static let knownLabelsGerman: [KnownLabel: Set<String>] = [
        .nutritionFacts: ["durchschnittliche nährwertangaben", "durchschn. nährwertangaben", "durchschnittliche nährwerte", "durchschn. nährwerte", "nährwertangaben", "nährwerte"],
        .servingSize: ["portion"],
        .perServing: ["pro portion", "/ portion", "/portion"],
        .perContainer: [],
    ]
    
    /// Keywords that can be used to determine the language of the label.
    static let keywordsByLanguage: [LabelLanguage: Set<String>] = {
        var keywords = [LabelLanguage: Set<String>]()
        
        // English
        keywords[.english] = []
        for (_, spellings) in NutritionItem.knownLabelsEnglish {
            keywords[.english]?.insert(contentsOf: spellings)
        }
        
        // German
        keywords[.german] = []
        for (_, spellings) in NutritionItem.knownLabelsGerman {
            keywords[.german]?.insert(contentsOf: spellings)
        }
        
        return keywords
    }()
}

public extension MeasurementUnit {
    /// Known spellings for this unit in English.
    static let knownSpellingsEnglish: [MeasurementUnit: Set<String>] = [
        .gram: ["gram", "grams", "g"],
        .milligram: ["milligram", "milligrams", "mg"],
        .microgram: ["microgram", "micrograms", "mcg", "μg"],
        .ounce: ["ounce", "ounces", "oz", "oz."],
        .liter: ["liter", "litre", "l"],
        .milliliter: ["milliliter", "millilitre", "ml"],
        .cup: ["cup", "cups"],
        .liquidOunce: ["liquid ounces", "liquid oz.", "fluid oz.", "fl. oz."],
        .percent: ["%", "percent"],
        .kilocalories: ["calories", "cal.", "cal", "kcal"],
        .kilojoules: ["kj", "kilojoules", "kilojoule", "kjoule"]
    ]
    
    /// Known spellings for this unit in German.
    static let knownSpellingsGerman: [MeasurementUnit: Set<String>] = [
        .gram: ["gramm", "g"],
        .milligram: ["milligramm", "mg"],
        .ounce: ["unze", "unzen"],
        .liter: ["liter", "l"],
        .milliliter: ["milliliter", "ml"],
        .cup: [],
        .liquidOunce: [],
        .percent: ["%", "prozent"],
        .kilocalories: ["kalorien", "kal.", "cal", "kcal"],
        .kilojoules: ["kj", "kilojoules", "kilojoule", "kjoule"]
    ]
}
