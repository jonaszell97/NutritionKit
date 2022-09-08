
import Foundation

public final class OpenFoodFactsAPI {
    public enum Error: Swift.Error {
        case invalidUrl
        case dataNotFound
        case decodingError
    }
    
    public enum ProductStatus: Int {
        case notFound = 0
        case found = 1
    }
    
    public enum ProductFields: String, CaseIterable {
        // Metadata
        case productName = "product_name"
        
        // Nutrition info
        case energyKcal = "energy-kcal_value"
        case servingSize = "serving_size"
        case nutrients = "nutriments"
    }
    
    /// The product fields to use.
    var productFields: [ProductFields]
    
    /// Default initializer.
    public init() {
        self.productFields = ProductFields.allCases
    }
    
    /// The base API URL.
    static let openFoodFactsApiUrl: String = "https://world.openfoodfacts.org/api/v2/product"
    
    /// Shared instance.
    static let shared = OpenFoodFactsAPI()
    
    /// Update the API configuration.
    public func configure(productFields: [ProductFields]? = nil) {
        if let productFields {
            self.productFields = productFields
        }
    }
    
    /// Load info about a food item with the given barcode.
    public func find(_ barcode: String) async throws -> FoodItem {
        guard let url = URL(string: self.formApiUrl(barcode)) else {
            throw Error.invalidUrl
        }
        
        let request = URLRequest(url: url)
        return try await withCheckedThrowingContinuation { continutation in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    continutation.resume(throwing: Error.dataNotFound)
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                guard let responseJSON = responseJSON as? [String: Any] else {
                    continutation.resume(throwing: Error.dataNotFound)
                    return
                }
                
                do {
                    let foodItem = try self.createFoodItem(from: responseJSON)
                    continutation.resume(returning: foodItem)
                }
                catch {
                    continutation.resume(throwing: error)
                }
            }
            
            task.resume()
        }
    }
    
    /// Create a food item from the JSON returned by the API.
    private func createFoodItem(from rawData: [String: Any]) throws -> FoodItem {
        guard let productData = rawData["product"] as? [String: Any] else {
            throw Error.decodingError
        }
        
        let productName: String? = readOptionalField(.productName, from: productData)
        let nutrients: [String: Any] = try readField(.nutrients, from: productData)
        
        var servingSize: ServingSize? = nil
        if let rawServingSize: String = readOptionalField(.servingSize, from: productData) {
            var lexer = Lexer(rawText: .init(text: rawServingSize, boundingBox: .zero), language: .english) { categorizedText in
                guard let description = categorizedText.description else {
                    return
                }
                
                switch description {
                case .amount(let value):
                    servingSize = .amount(amount: value)
                default:
                    break
                }
            }
            
            lexer.parse()
        }
        
        var nutritionFacts = [NutritionItem: NutritionAmount]()
        if let calories: Double = readOptionalField(.energyKcal, from: nutrients) {
            nutritionFacts[.calories] = .energy(kcal: calories)
        }
        
        for fact in NutritionItem.allCases {
            guard let amount = self.readNutritionItem(fact, from: nutrients) else {
                continue
            }
            
            nutritionFacts[fact] = amount
        }
        
        return .init(productName: productName, nutrition: NutritionLabel(language: .english,
                                                                         servingSize: servingSize,
                                                                         nutritionFacts: nutritionFacts))
    }
    
    private func readField<T>(_ field: ProductFields, from rawData: [String: Any]) throws -> T {
        guard let value = rawData[field.rawValue] as? T else {
            throw Error.decodingError
        }
        
        return value
    }
    
    private func readOptionalField<T>(_ field: ProductFields, from rawData: [String: Any]) -> T? {
        rawData[field.rawValue] as? T
    }
    
    private func readNutritionItem(_ item: NutritionItem, from nutrientData: [String: Any]) -> NutritionAmount? {
        guard let key = item.openFoodFactsKey else { return nil }
        guard let value = nutrientData["\(key)_value"] as? Double else { return nil }
        guard let unitSpelling = nutrientData["\(key)_unit"] as? String else { return nil }
        
        for (unit, spellings) in MeasurementUnit.knownSpellingsEnglish {
            guard spellings.contains(unitSpelling) else {
                continue
            }
            
            return .init(amount: value, unit: unit)
        }
        
        return nil
    }
    
    /// Create the API URL for a given barcode.
    public func formApiUrl(_ barcode: String) -> String {
        "\(Self.openFoodFactsApiUrl)/\(barcode)?fields=\(productFields.map { $0.rawValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! }.joined(separator: ","))"
    }
}

fileprivate extension NutritionItem {
    /// The equivalent key for the OpenFoodFacts API.
    var openFoodFactsKey: String? {
        switch self {
        case .calories:
            return "energy_kcal"
        case .caloriesFromFat:
            return nil
        case .fat:
            return "fat"
        case .saturatedFat:
            return "saturated-fat"
        case .unsaturatedFat:
            return nil
        case .monounsaturatedFat:
            return "monounsaturated-fat"
        case .polyunsaturatedFat:
            return "polyunsaturated-fat"
        case .omega3FattyAcids:
            return "omega-3-fat"
        case .transFat:
            return "trans-fat"
        case .carbohydrates:
            return "carbohydrates"
        case .sugar:
            return "sugars"
        case .addedSugar:
            return nil
        case .sugarAlcohols:
            return nil
        case .starch:
            return "starch"
        case .dietaryFiber:
            return "fiber"
        case .protein:
            return "proteins"
        case .salt:
            return "salt"
        case .sodium:
            return "sodium"
        case .cholesterol:
            return "cholesterol"
        case .vitaminA:
            return "vitamin-a"
        case .vitaminB1:
            return "vitamin-b1"
        case .vitaminB2:
            return "vitamin-b2"
        case .vitaminB6:
            return "vitamin-b6"
        case .vitaminB9:
            return "vitamin-b9"
        case .vitaminB12:
            return "vitamin-b12"
        case .vitaminC:
            return "vitamin-c"
        case .vitaminD:
            return "vitamin-d"
        case .vitaminE:
            return "vitamin-e"
        case .vitaminK:
            return "vitamin-k"
        case .caffeine:
            return "caffeine"
        case .taurine:
            return "taurine"
        case .alcohol:
            return "alcohol"
        case .magnesium:
            return "magnesium"
        case .calcium:
            return "calcium"
        case .zinc:
            return "zinc"
        case .potassium:
            return "potassium"
        case .iron:
            return "iron"
        case .fluoride:
            return "fluoride"
        case .copper:
            return "copper"
        case .chloride:
            return "chloride"
        case .phosphorus:
            return "phosphorus"
        case .iodine:
            return "iodine"
        case .chromium:
            return "chromium"
        }
    }
}
