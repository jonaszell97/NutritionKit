
import Foundation
import SwiftUI
import Toolbox

enum NutritionLabelStructure {
    /// The label has a tabular structure with values to the right of labels.
    case tabularHorizontal
    
    /// The nutrition label is formatted as a single text paragraph.
    case list
}

enum TextDescription {
    /// This text refers to a nutrition fact label.
    case nutritionFactLabel(fact: NutritionItem)
    
    /// This text refers to an amount.
    case amount(value: NutritionAmount)
    
    /// This text describes a serving size.
    case servingSize(value: ServingSize)
    
    /// A known label.
    case knownLabel(label: KnownLabel)
    
    /// Unknown text.
    case uncategorized(text: String)
}

struct CategorizedText {
    /// The ID of this text label.
    let id = UUID()
    
    /// The category of this text.
    let description: TextDescription?
    
    /// The raw text instance this belongs to.
    let rawText: TextDetector.TextBox
}

extension CategorizedText {
    var precedence: Int {
        switch self.description {
        case .nutritionFactLabel(let fact):
            switch fact {
            case .calories:
                fallthrough
            case .caloriesFromFat:
                return 9
            default:
                return 10
            }
        case .servingSize:
            return 8
        case .knownLabel:
            return 8
        case .uncategorized:
            return 5
        case .amount(let amount):
            return amount.precedence
        case .none:
            return 0
        }
    }
}

class NutritionLabelParser {
    /// The detected text boxes.
    let rawDetectedText: [TextDetector.TextBox]
    
    /// The language to use for parsing.
    let language: LabelLanguage
    
    /// The categorized text instances.
    var categorizedText: [CategorizedText]
    
    /// The amount the nutrition facts are relative to (e.g. per serving, per 100g).
    var nutritionFactsRelativeAmount: ServingSize = .absoluteValue(value: 1, unit: "serving")
    
    /// The nutrition item detections.
    var nutritionFacts: [NutritionItem: NutritionAmount] = [:]
    
    /// The parsed serving size.
    var servingSize: ServingSize? = nil
    
    /// The maximum distance the y coordinate of two labels can have for them to be considered in the same row.
    static let maxYDistance: CGFloat = 0.025
    
    /// Default initializer.
    init(rawDetectedText: [TextDetector.TextBox], language: LabelLanguage) {
        self.rawDetectedText = rawDetectedText
        self.language = language
        self.categorizedText = []
        
        self.categorizeText()
    }
    
    var nutritionFactLabels: [NutritionItem: Set<String>] {
        switch language {
        case .english:
            return NutritionItem.knownLabelsEnglish
        case .german:
            return NutritionItem.knownLabelsGerman
        }
    }
    
    var metaLabels: [KnownLabel: Set<String>] {
        switch language {
        case .english:
            return KnownLabel.knownLabelsEnglish
        case .german:
            return KnownLabel.knownLabelsGerman
        }
    }
    
    var unitSpellings: [MeasurementUnit: Set<String>] {
        switch language {
        case .english:
            return MeasurementUnit.knownSpellingsEnglish
        case .german:
            return MeasurementUnit.knownSpellingsGerman
        }
    }
    
    /// Classify raw detected text.
    func categorizeText() {
        for rawText in rawDetectedText {
            var parser = Lexer(rawText: rawText, language: language) {
                self.categorizedText.append($0)
            }
            
            parser.parse()
        }
    }
    
    /// Find a text segment of the specified type on the same row.
    func findOnSameRow(_ segment: CategorizedText,
                       leading: Bool, trailing: Bool,
                       maxDistance: CGFloat = .infinity,
                       where predicate: (CategorizedText) -> Bool) -> CategorizedText? {
        let maxYDistance = segment.rawText.boundingBox.height * 0.5
        
        var closestDistance: CGFloat = .infinity
        var closestSegment: CategorizedText? = nil
        var closestPrecedence: Int = 0
        
        for otherText in categorizedText {
            guard predicate(otherText) else {
                continue
            }
            
            let yDistance = abs(otherText.rawText.boundingBox.midY - segment.rawText.boundingBox.midY)
            guard segment.rawText.id == otherText.rawText.id || yDistance <= maxYDistance else {
                continue
            }
            
            let xDistance = otherText.rawText.boundingBox.minX - segment.rawText.boundingBox.minX
            if !leading && xDistance < 0 {
                continue
            }
            
            if !trailing && xDistance > 0 {
                continue
            }
            
            let distance = (otherText.rawText.boundingBox.center - segment.rawText.boundingBox.center).magnitude
            guard distance < closestDistance || closestPrecedence < otherText.precedence, distance <= maxDistance else {
                continue
            }
            
            if let closestSegment = closestSegment, closestSegment.precedence > otherText.precedence {
                continue
            }
            
            closestDistance = distance
            closestSegment = otherText
            closestPrecedence = otherText.precedence
        }
        
        return closestSegment
    }
    
    /// Find a text segment of the specified type that is close.
    func findCloseBy(_ segment: CategorizedText,
                     maxDistance: CGFloat = .infinity,
                     where predicate: (CategorizedText) -> Bool) -> CategorizedText? {
        var closestDistance: CGFloat = .infinity
        var closestSegment: CategorizedText? = nil
        var closestPrecedence: Int = 0
        
        for otherText in categorizedText {
            guard predicate(otherText) else {
                continue
            }
            
            let distance = (segment.rawText.boundingBox.center - otherText.rawText.boundingBox.center).magnitudeSquared
            guard distance < closestDistance || closestPrecedence < otherText.precedence, distance <= maxDistance else {
                continue
            }
            
            if let closestSegment = closestSegment, closestSegment.precedence > otherText.precedence {
                continue
            }
            
            closestDistance = distance
            closestSegment = otherText
            closestPrecedence = otherText.precedence
        }
        
        return closestSegment
    }
    
    func parse() -> NutritionLabel {
        fatalError("must be implemented in subclass")
    }
}

final class HorizontalTabularNutritionLabelParser: NutritionLabelParser {
    /// Default initializer.
    override init(rawDetectedText: [TextDetector.TextBox], language: LabelLanguage) {
        super.init(rawDetectedText: rawDetectedText, language: language)
    }
    
    /// Scan the detected text to find nutritional facts.
    override func parse() -> NutritionLabel {
        var usedLabels = Set<UUID>()
    outer: for text in (self.categorizedText.sorted { $0.precedence > $1.precedence }) {
        switch text.description {
        case .nutritionFactLabel:
            break
        case .knownLabel(let label):
            switch label {
            case .servingSize:
                break
            default:
                continue outer
            }
        default:
            continue outer
        }
        
        // Handle cases like 'incl. 13g added sugar'
        var leading = false
        if case .nutritionFactLabel(let fact) = text.description {
            if case .addedSugar = fact {
                leading = self.findOnSameRow(text, leading: true, trailing: false) {
                    guard case .uncategorized(let text) = $0.description else {
                        return false
                    }
                    
                    return text.lowercased() == "incl."
                } != nil
            }
        }
        
        // Find the value label that is closest horizontally
        var closestSegment = self.findOnSameRow(text, leading: leading, trailing: true) { otherText in
            guard case .amount = otherText.description else {
                return false
            }
            guard !usedLabels.contains(otherText.id) else {
                return false
            }
            
            return true
        }
        
        // For Calories, also accept any label that is close by
        if closestSegment == nil, case .nutritionFactLabel(let fact) = text.description, case .calories = fact {
            closestSegment = self.findCloseBy(text, maxDistance: 0.5) { otherText in
                guard case .amount(let value) = otherText.description else {
                    return false
                }
                guard !usedLabels.contains(otherText.id) else {
                    return false
                }
                
                switch value {
                case .unitless:
                    fallthrough
                case .energy:
                    return true
                default:
                    return false
                }
            }
        }
        
        guard let segment = closestSegment, case .amount(let closestAmount) = segment.description else {
            continue
        }
        
        var amount = closestAmount
        switch text.description {
        case .nutritionFactLabel(let fact):
            if let existingFact = self.nutritionFacts[fact] {
                guard existingFact.precedence < amount.precedence else {
                    continue
                }
            }
            
            if fact == .calories || fact == .caloriesFromFat {
                if case .unitless(let value) = amount {
                    amount = .energy(kcal: value)
                }
            }
            
            self.nutritionFacts[fact] = amount
        case .knownLabel(let label):
            switch label {
            case .servingSize:
                servingSize = .amount(amount: amount)
            default:
                break
            }
        default:
            fatalError("should never happen")
        }
        
        usedLabels.insert(segment.id)
    }
        
        return .init(language: language, servingSize: servingSize, nutritionFacts: nutritionFacts)
    }
}
