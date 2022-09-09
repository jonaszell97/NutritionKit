import XCTest
@testable import NutritionKit

class NutritionLabelScanningTest: XCTestCase {
    func nutritionLabelTest(_ assetName: String, testFunction: @escaping (NutritionLabel) -> Void) async throws {
        let bundle = Bundle(for: NutritionLabelScanningTest.self)
        guard let image = UIImage(named: assetName, in: bundle, with: nil)?.cgImage else {
            XCTAssert(false, "image \(assetName) does not exist")
            return
        }
        
        let scanner = NutritionLabelDetector(image: image)
        guard try await scanner.findNutritionLabel() != nil else {
            XCTAssert(false, "no nutrition label found")
            return
        }
        
        let label = try await scanner.scanNutritionLabel()
        testFunction(label)
    }
}

class USLabelTests: NutritionLabelScanningTest {
    func testUSLabel1() async throws {
        try await self.nutritionLabelTest("testLabelUS1") { label in
            XCTAssertEqual(label.servingSize, .amount(amount: .solid(milligrams: 50_000)))
            
            XCTAssertEqual(label.nutritionFacts[.calories], .energy(kcal: 235))
            XCTAssertEqual(label.nutritionFacts[.caloriesFromFat], .energy(kcal: 12))
            
            XCTAssertEqual(label.nutritionFacts[.fat], .solid(milligrams: 2000))
            XCTAssertEqual(label.nutritionFacts[.saturatedFat], .solid(milligrams: 2000))
            XCTAssertEqual(label.nutritionFacts[.transFat], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.cholesterol], nil) // Label says 'Cholosterol'
            XCTAssertEqual(label.nutritionFacts[.sodium], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.carbohydrates], .solid(milligrams: 19_000))
            XCTAssertEqual(label.nutritionFacts[.dietaryFiber], .solid(milligrams: 2000))
            XCTAssertEqual(label.nutritionFacts[.sugar], .solid(milligrams: 17_000))
            
            XCTAssertEqual(label.nutritionFacts[.protein], .solid(milligrams: 29_000))
            
            XCTAssertEqual(label.nutritionFacts[.vitaminC], .dailyValue(percentage: 35))
            XCTAssertEqual(label.nutritionFacts[.vitaminA], .dailyValue(percentage: 20))
            XCTAssertEqual(label.nutritionFacts[.calcium], .dailyValue(percentage: 5))
            XCTAssertEqual(label.nutritionFacts[.zinc], .dailyValue(percentage: 5))
        }
    }
    
    func testUSLabel2() async throws {
        try await self.nutritionLabelTest("testLabelUS2") { label in
            XCTAssertEqual(label.nutritionFacts[.calories], .energy(kcal: 90))
            
            XCTAssertEqual(label.nutritionFacts[.fat], .solid(milligrams: 2000))
            XCTAssertEqual(label.nutritionFacts[.saturatedFat], .solid(milligrams: 1000))
            XCTAssertEqual(label.nutritionFacts[.transFat], .solid(milligrams: 500))
            
            XCTAssertEqual(label.nutritionFacts[.cholesterol], .solid(milligrams: 10))
            XCTAssertEqual(label.nutritionFacts[.sodium], .solid(milligrams: 200))
            
            XCTAssertEqual(label.nutritionFacts[.carbohydrates], .solid(milligrams: 15_000))
            XCTAssertEqual(label.nutritionFacts[.dietaryFiber], .solid(milligrams: 0))
            XCTAssertEqual(label.nutritionFacts[.sugar], .solid(milligrams: 14_000))
            XCTAssertEqual(label.nutritionFacts[.addedSugar], .solid(milligrams: 13_000))
            
            XCTAssertEqual(label.nutritionFacts[.protein], .solid(milligrams: 3_000))
            
            XCTAssertEqual(label.nutritionFacts[.vitaminD], .dailyValue(percentage: 0))
            XCTAssertEqual(label.nutritionFacts[.calcium], .dailyValue(percentage: 6))
            XCTAssertEqual(label.nutritionFacts[.iron], .dailyValue(percentage: 6))
            XCTAssertEqual(label.nutritionFacts[.potassium], .dailyValue(percentage: 10))
        }
    }
    
    func testUSLabel3() async throws {
        try await self.nutritionLabelTest("testLabelUS3") { label in
            XCTAssertEqual(label.servingSize, .amount(amount: .liquid(milliliters: MeasurementUnit.cup.normalizeValue(1))))
            
            XCTAssertEqual(label.nutritionFacts[.calories], .energy(kcal: 220))
            
            XCTAssertEqual(label.nutritionFacts[.fat], .solid(milligrams: 5000))
            XCTAssertEqual(label.nutritionFacts[.saturatedFat], .solid(milligrams: 2000))
            XCTAssertEqual(label.nutritionFacts[.transFat], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.cholesterol], .solid(milligrams: 15))
            XCTAssertEqual(label.nutritionFacts[.sodium], .solid(milligrams: 240))
            
            XCTAssertEqual(label.nutritionFacts[.carbohydrates], .solid(milligrams: 35_000))
            XCTAssertEqual(label.nutritionFacts[.dietaryFiber], .solid(milligrams: 6000))
            XCTAssertEqual(label.nutritionFacts[.sugar], .solid(milligrams: 7_000))
            XCTAssertEqual(label.nutritionFacts[.addedSugar], .solid(milligrams: 4_000))
            
            XCTAssertEqual(label.nutritionFacts[.protein], .solid(milligrams: 9_000))
            
            XCTAssertEqual(label.nutritionFacts[.vitaminD], .solid(milligrams: 0.005))
            XCTAssertEqual(label.nutritionFacts[.calcium], .solid(milligrams: 200))
            XCTAssertEqual(label.nutritionFacts[.iron], .solid(milligrams: 1))
            XCTAssertEqual(label.nutritionFacts[.potassium], .solid(milligrams: 470))
        }
    }
    
    func testUSLabel4() async throws {
        try await self.nutritionLabelTest("testLabelUS4") { label in
            XCTAssertEqual(label.servingSize, .amount(amount: .solid(milligrams: 41_000)))
            
            XCTAssertEqual(label.nutritionFacts[.calories], .energy(kcal: 150))
            XCTAssertEqual(label.nutritionFacts[.caloriesFromFat], .energy(kcal: 25))
            
            XCTAssertEqual(label.nutritionFacts[.fat], .solid(milligrams: 2500))
            XCTAssertEqual(label.nutritionFacts[.saturatedFat], .solid(milligrams: 500))
        }
    }
    
    func testUSList1() async throws {
        try await self.nutritionLabelTest("testListUS1") { label in
            XCTAssertEqual(label.servingSize, .amount(amount: .solid(milligrams: 2_000)))
            
            XCTAssertEqual(label.nutritionFacts[.calories], .energy(kcal: 5))
            
            XCTAssertEqual(label.nutritionFacts[.fat], .solid(milligrams: 0))
            XCTAssertEqual(label.nutritionFacts[.saturatedFat], .solid(milligrams: 0))
            XCTAssertEqual(label.nutritionFacts[.transFat], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.sodium], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.carbohydrates], .solid(milligrams: 2_000))
            XCTAssertEqual(label.nutritionFacts[.dietaryFiber], .solid(milligrams: 0))
            XCTAssertEqual(label.nutritionFacts[.sugar], .solid(milligrams: 2_000))
            XCTAssertEqual(label.nutritionFacts[.addedSugar], .solid(milligrams: 2_000))
            
            XCTAssertEqual(label.nutritionFacts[.protein], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.vitaminD], .dailyValue(percentage: 0))
            XCTAssertEqual(label.nutritionFacts[.calcium], .dailyValue(percentage: 0))
            XCTAssertEqual(label.nutritionFacts[.iron], .dailyValue(percentage: 0))
            XCTAssertEqual(label.nutritionFacts[.potassium], .dailyValue(percentage: 6))
        }
    }
    
    func testUSList2() async throws {
        try await self.nutritionLabelTest("testListUS2") { label in
            XCTAssertEqual(label.servingSize, .amount(amount: .solid(milligrams: 2_000)))
            
            XCTAssertEqual(label.nutritionFacts[.calories], .energy(kcal: 5))
            
            XCTAssertEqual(label.nutritionFacts[.fat], .unitless(value: 0)) // OCR missing a character?
            XCTAssertEqual(label.nutritionFacts[.saturatedFat], .solid(milligrams: 0))
            XCTAssertEqual(label.nutritionFacts[.transFat], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.sodium], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.carbohydrates], .solid(milligrams: 2_000))
            XCTAssertEqual(label.nutritionFacts[.dietaryFiber], .solid(milligrams: 0))
            XCTAssertEqual(label.nutritionFacts[.sugar], .solid(milligrams: 2_000))
            XCTAssertEqual(label.nutritionFacts[.addedSugar], .solid(milligrams: 2_000))
            
            XCTAssertEqual(label.nutritionFacts[.protein], .solid(milligrams: 0))
            
            XCTAssertEqual(label.nutritionFacts[.vitaminD], .dailyValue(percentage: 0))
            XCTAssertEqual(label.nutritionFacts[.calcium], .dailyValue(percentage: 0))
            XCTAssertEqual(label.nutritionFacts[.iron], .dailyValue(percentage: 0))
            XCTAssertEqual(label.nutritionFacts[.potassium], .dailyValue(percentage: 6))
        }
    }
}

class DELabelTests: NutritionLabelScanningTest {
    func testDELabel1() async throws {
        try await self.nutritionLabelTest("testLabelDE1") { label in
            XCTAssertEqual(label.nutritionFacts[.calories], .energy(kcal: MeasurementUnit.kilojoules.normalizeValue(1603)))
            
            XCTAssertEqual(label.nutritionFacts[.fat], .solid(milligrams: 21_000))
            XCTAssertEqual(label.nutritionFacts[.saturatedFat], .solid(milligrams: 13_000))
            
            XCTAssertEqual(label.nutritionFacts[.carbohydrates], .solid(milligrams: 12_000))
            XCTAssertEqual(label.nutritionFacts[.sugar], .solid(milligrams: 300))
            XCTAssertEqual(label.nutritionFacts[.dietaryFiber], .solid(milligrams: 31_000))
            
            XCTAssertEqual(label.nutritionFacts[.protein], .solid(milligrams: 22_000))
            
            XCTAssertEqual(label.nutritionFacts[.salt], .solid(milligrams: 100))
        }
    }
}
