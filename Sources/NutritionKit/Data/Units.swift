
import Foundation
import Toolbox

public enum NutritionAmount {
    /// An unspecified unit.
    case unitless(value: Double)
    
    /// An amount of energy
    case energy(kcal: Double)
    
    /// An amount for a solid mass
    case solid(milligrams: Double)
    
    /// An amount for a liquid volume
    case liquid(milliliters: Double)
    
    /// An amount as a % of daily value
    case dailyValue(percentage: Int)
}

public enum ServingSize {
    /// A serving size determined by an absolute amount.
    case amount(amount: NutritionAmount)
    
    /// A serving size as a relative container size.
    case container(percentage: Double)
    
    /// A serving size as an absolute value (e.g. 1 cookie).
    case absoluteValue(value: Double, unit: String?)
}

public enum MeasurementUnit: String, CaseIterable {
    /// Solid units
    case gram
    case milligram
    case microgram
    case ounce
    
    /// Liquid units
    case liter
    case milliliter
    case cup
    case liquidOunce
    
    /// Other units
    case percent
    case kilocalories
    case kilojoules
}

// MARK: Utility extensions

extension NutritionAmount: CustomStringConvertible {
    /// Create a nutrition amount from a unit and a value.
    public init(amount: Double, unit: MeasurementUnit) {
        if unit.isSolid {
            self = .solid(milligrams: unit.normalizeValue(amount))
            return
        }
        
        if unit.isLiquid {
            self = .liquid(milliliters: unit.normalizeValue(amount))
            return
        }
        
        if unit.isEnergy {
            self = .energy(kcal: unit.normalizeValue(amount))
            return
        }
        
        if case .percent = unit {
            self = .dailyValue(percentage: Int(amount))
            return
        }
        
        self = .unitless(value: amount)
    }
    
    public var precedence: Int {
        switch self {
        case .energy:
            return 2
        case .solid:
            return 2
        case .liquid:
            return 2
        case .unitless:
            return 1
        case .dailyValue:
            return 0
        }
    }
    
    public var description: String {
        switch self {
        case .unitless(let value):
            return "\(value)"
        case .energy(let kcal):
            return "\(kcal) kcal"
        case .solid(let milligrams):
            if milligrams < 1 && milligrams != 0 {
                return "\(Int(milligrams*1000))mcg"
            }
            else if milligrams > 1000 || milligrams == 0 {
                return "\(Int(milligrams/1000))g"
            }
            else {
                return "\(Int(milligrams))mg"
            }
        case .liquid(let milliliters):
            if milliliters > 1000 || milliliters == 0 {
                return "\(Int(milliliters/1000))l"
            }
            else {
                return "\(Int(milliliters))ml"
            }
        case .dailyValue(let percentage):
            return "\(percentage)%"
        }
    }
    
    public func description(for fact: NutritionItem) -> String {
        switch self {
        case .unitless(let value):
            return "\(value)"
        case .energy(let kcal):
            return "\(Int(kcal)) kcal"
        case .solid(let milligrams):
            if case .macronutrient = fact.category, milligrams >= 100 {
                return "\(FormatToolbox.format(milligrams/1000, decimalPlaces: 1, minDecimalPlaces: 0))g"
            }
            
            if milligrams < 1 && milligrams != 0 {
                return "\(Int(milligrams*1000))mcg"
            }
            else if milligrams > 1000 || milligrams == 0 {
                return "\(Int(milligrams/1000))g"
            }
            else {
                return "\(Int(milligrams))mg"
            }
        case .liquid(let milliliters):
            if milliliters > 1000 || milliliters == 0 {
                return "\(Int(milliliters/1000))l"
            }
            else {
                return "\(Int(milliliters))ml"
            }
        case .dailyValue(let percentage):
            return "\(percentage)%"
        }
    }
}

public extension MeasurementUnit {
    /// Whether or not this unit represents a solid.
    var isSolid: Bool {
        switch self {
        case .gram:
            fallthrough
        case .microgram:
            fallthrough
        case .milligram:
            fallthrough
        case .ounce:
            return true
        default:
            return false
        }
    }
    
    /// Whether or not this unit represents a liquid.
    var isLiquid: Bool {
        switch self {
        case .liter:
            fallthrough
        case .milliliter:
            fallthrough
        case .liquidOunce:
            fallthrough
        case .cup:
            return true
        default:
            return false
        }
    }
    
    /// Whether or not this is an energy unit.
    var isEnergy: Bool {
        switch self {
        case .kilojoules:
            fallthrough
        case .kilocalories:
            return true
        default:
            return false
        }
    }
    
    /// Convert an amount to the appropriate base value.
    func normalizeValue(_ amount: Double) -> Double {
        switch self {
        case .gram:
            return amount * 1000
        case .milligram:
            return amount
        case .microgram:
            return amount / 1000
        case .ounce:
            return amount * 28_349
        case .liter:
            return amount * 1000
        case .milliliter:
            return amount
        case .cup:
            return amount * 236.59
        case .liquidOunce:
            return amount * 29.57
        case .percent:
            return amount
        case .kilocalories:
            return amount
        case .kilojoules:
            return amount * 0.239
        }
    }
}

extension ServingSize: CustomStringConvertible {
    public var description: String {
        switch self {
        case .amount(let amount):
            return amount.description
        case .container(let percentage):
            // FIXME
            return "\(percentage)% container"
        case .absoluteValue(let value, let unit):
            return "\(value) \(unit ?? "")"
        }
    }
}

// MARK: Codable, Hashable

extension NutritionAmount: Codable {
    public enum CodingKeys: String, CodingKey {
        case unitless, energy, solid, liquid, dailyValue
    }
    
    public var codingKey: CodingKeys {
        switch self {
        case .unitless: return .unitless
        case .energy: return .energy
        case .solid: return .solid
        case .liquid: return .liquid
        case .dailyValue: return .dailyValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .unitless(let value):
            try container.encode(value, forKey: .unitless)
        case .energy(let kcal):
            try container.encode(kcal, forKey: .energy)
        case .solid(let milligrams):
            try container.encode(milligrams, forKey: .solid)
        case .liquid(let milliliters):
            try container.encode(milliliters, forKey: .liquid)
        case .dailyValue(let percentage):
            try container.encode(percentage, forKey: .dailyValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .unitless:
            let value = try container.decode(Double.self, forKey: .unitless)
            self = .unitless(value: value)
        case .energy:
            let kcal = try container.decode(Double.self, forKey: .energy)
            self = .energy(kcal: kcal)
        case .solid:
            let milligrams = try container.decode(Double.self, forKey: .solid)
            self = .solid(milligrams: milligrams)
        case .liquid:
            let milliliters = try container.decode(Double.self, forKey: .liquid)
            self = .liquid(milliliters: milliliters)
        case .dailyValue:
            let percentage = try container.decode(Int.self, forKey: .dailyValue)
            self = .dailyValue(percentage: percentage)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode enum."
                )
            )
        }
    }
}

extension NutritionAmount: Equatable {
    public static func ==(lhs: NutritionAmount, rhs: NutritionAmount) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        switch lhs {
        case .unitless(let value):
            guard case .unitless(let value_) = rhs else { return false }
            guard value == value_ else { return false }
        case .energy(let kcal):
            guard case .energy(let kcal_) = rhs else { return false }
            guard kcal == kcal_ else { return false }
        case .solid(let milligrams):
            guard case .solid(let milligrams_) = rhs else { return false }
            guard milligrams == milligrams_ else { return false }
        case .liquid(let milliliters):
            guard case .liquid(let milliliters_) = rhs else { return false }
            guard milliliters == milliliters_ else { return false }
        case .dailyValue(let percentage):
            guard case .dailyValue(let percentage_) = rhs else { return false }
            guard percentage == percentage_ else { return false }
        }
        
        return true
    }
}

extension NutritionAmount: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        switch self {
        case .unitless(let value):
            hasher.combine(value)
        case .energy(let kcal):
            hasher.combine(kcal)
        case .solid(let milligrams):
            hasher.combine(milligrams)
        case .liquid(let milliliters):
            hasher.combine(milliliters)
        case .dailyValue(let percentage):
            hasher.combine(percentage)
        }
    }
}

extension ServingSize: Codable {
    public enum CodingKeys: String, CodingKey {
        case amount, container, absoluteValue
    }
    
    public var codingKey: CodingKeys {
        switch self {
        case .amount: return .amount
        case .container: return .container
        case .absoluteValue: return .absoluteValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .amount(let amount):
            try container.encode(amount, forKey: .amount)
        case .container(let percentage):
            try container.encode(percentage, forKey: .container)
        case .absoluteValue(let value, let unit):
            try container.encodeValues(value, unit, for: .absoluteValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .amount:
            let amount = try container.decode(NutritionAmount.self, forKey: .amount)
            self = .amount(amount: amount)
        case .container:
            let percentage = try container.decode(Double.self, forKey: .container)
            self = .container(percentage: percentage)
        case .absoluteValue:
            let (value, unit): (Double, Optional<String>) = try container.decodeValues(for: .absoluteValue)
            self = .absoluteValue(value: value, unit: unit)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode enum."
                )
            )
        }
    }
}

extension ServingSize: Equatable {
    public static func ==(lhs: ServingSize, rhs: ServingSize) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        switch lhs {
        case .amount(let amount):
            guard case .amount(let amount_) = rhs else { return false }
            guard amount == amount_ else { return false }
        case .container(let percentage):
            guard case .container(let percentage_) = rhs else { return false }
            guard percentage == percentage_ else { return false }
        case .absoluteValue(let value, let unit):
            guard case .absoluteValue(let value_, let unit_) = rhs else { return false }
            guard value == value_ else { return false }
            guard unit == unit_ else { return false }
        }
        
        return true
    }
}

extension ServingSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        switch self {
        case .amount(let amount):
            hasher.combine(amount)
        case .container(let percentage):
            hasher.combine(percentage)
        case .absoluteValue(let value, let unit):
            hasher.combine(value)
            hasher.combine(unit)
        }
    }
}


