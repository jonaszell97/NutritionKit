
import SwiftUI

public struct USNutritionLabelView: View {
    /// The nutrition label to display.
    let label: NutritionLabel
    
    /// The language of the label.
    let language: LabelLanguage
    
    /// The order of display for the macro nutrients.
    static let macroOrder: [(NutritionItem, Bool)] = [
        (.fat, true),
        (.saturatedFat, false),
        (.unsaturatedFat, false),
        (.monounsaturatedFat, false),
        (.polyunsaturatedFat, false),
        (.transFat, false),
        
        (.cholesterol, true),
        (.sodium, true),
        
        (.carbohydrates, true),
        (.dietaryFiber, false),
        (.sugar, false),
        (.addedSugar, false),
        (.starch, false),
        (.sugarAlcohols, false),
        
        (.protein, true),
    ]
    
    /// The order of display for the micro nutrients and vitamins.
    static let microOrder: [NutritionItem] = [
        .vitaminA,
        .vitaminB1,
        .vitaminB2,
        .vitaminB6,
        .vitaminB9,
        .vitaminB12,
        .vitaminC,
        .vitaminD,
        .vitaminE,
        .vitaminK,
        
        .caffeine,
        .taurine,
        .alcohol,
        
        .calcium,
        .iron,
        .magnesium,
        .potassium,
        .zinc,
        .fluoride,
        .copper,
        .chloride,
        .phosphorus,
        .iodine,
        .chromium
    ]
    
    public init(label: NutritionLabel, language: LabelLanguage? = nil) {
        self.label = label
        self.language = language ?? label.language
    }
    
    var thickBar: some View {
        Rectangle()
            .fill(Color.black)
            .frame(height: 10)
    }
    
    var thinBar: some View {
        Rectangle()
            .fill(Color.black)
            .frame(height: 1)
    }
    
    var caloriesView: some View {
        HStack {
            Text(verbatim: NutritionItem.calories.localizedName)
                .font(.footnote.bold())
                .foregroundColor(.black)
                .padding(.trailing, 5)
            
            if let value = self.label.nutritionFacts[.calories] {
                Text(verbatim: value.description(for: .calories))
                    .font(.footnote)
                    .foregroundColor(.black)
            }
            else {
                Text(verbatim: "-")
                    .font(.footnote)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            if let value = self.label.nutritionFacts[.caloriesFromFat] {
                Text(verbatim: NutritionItem.caloriesFromFat.localizedName)
                    .font(.footnote)
                    .foregroundColor(.black)
                    .padding(.trailing, 5)
                
                Text(verbatim: value.description(for: .caloriesFromFat))
                    .font(.footnote)
                    .foregroundColor(.black)
            }
        }
    }
    
    var macroNutrients: some View {
        let nutrients = Self.macroOrder.compactMap { (fact) -> (NutritionItem, NutritionAmount, Bool)? in
            guard let value = self.label.nutritionFacts[fact.0] else {
                return nil
            }
            
            return (fact.0, value, fact.1)
        }
        
        return VStack(spacing: 2) {
            ForEach(0..<nutrients.count, id: \.self) { i in
                if i > 0 {
                    thinBar
                }
                
                let (fact, value, primary) = nutrients[i]
                let font = primary ? Font.footnote.bold() : Font.footnote
                
                HStack {
                    Text(verbatim: fact.localizedName)
                        .font(font)
                        .foregroundColor(.black)
                        .padding(.leading, primary ? 0 : nil)
                    
                    Spacer()
                    
                    Text(verbatim: value.description(for: fact))
                        .font(.footnote)
                        .foregroundColor(.black)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
        }
    }
    
    var microNutrients: some View {
        var nutrients = Self.microOrder.compactMap { (fact) -> (NutritionItem?, NutritionAmount?)? in
            guard let value = self.label.nutritionFacts[fact] else {
                return nil
            }
            
            return (fact, value)
        }
        
        if nutrients.count % 2 != 0{
            nutrients.append((nil, nil))
        }
        
        return LazyVGrid(columns: [.init(spacing: 0), .init(spacing: 0)], spacing: 0) {
            ForEach(0..<nutrients.count, id: \.self) { i in
                VStack(spacing: 0) {
                    let (fact, value) = nutrients[i]
                    let font = Font.footnote
                    let hasTrailingBorder = i % 2 == 0
                    
                    HStack(spacing: 0) {
                        if let fact, let value {
                            Text(verbatim: fact.localizedName)
                                .font(font.bold())
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text(verbatim: value.description(for: fact))
                                .font(.footnote)
                                .foregroundColor(.black)
                        }
                        else {
                            Text(verbatim: "").font(.footnote)
                            Spacer()
                            Text(verbatim: "").font(.footnote)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.trailing, hasTrailingBorder ? 5 : 0)
                    .padding(.leading,  i % 2 == 1 ? 5 : 0)
                    .padding(.bottom, 2)
                    .overlay {
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 1)
                                .offset(x: 1)
                                .opacity(hasTrailingBorder ? 1 : 0)
                        }
                    }
                    
                    thinBar
                }
            }
        }
    }
    
    public var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.black, lineWidth: 3)
            
            VStack {
                HStack {
                    Text(verbatim: "Nutrition Facts")
                        .foregroundColor(.black)
                        .font(.system(size: 40, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
                
                // Serving size
                HStack {
                    Text(verbatim: "Serving Size")
                        .foregroundColor(.black)
                        .font(.footnote)
                    
                    if let servingSize = label.servingSize {
                        Text(verbatim: servingSize.description)
                            .foregroundColor(.black)
                            .font(.footnote.bold())
                    }
                    else {
                        Text(verbatim: "-")
                            .foregroundColor(.black)
                            .font(.footnote.bold())
                    }
                    
                    Spacer()
                }
                
                // Calories
                thickBar
                caloriesView
                
                // Macros
                thickBar
                macroNutrients
                
                // Micros
                thickBar
                microNutrients
                
                Spacer()
            }
            .padding(10)
        }
        .aspectRatio(0.64, contentMode: .fit)
        .padding(10)
        .background(Color.white)
    }
}

struct USNutritionLabelView_Previews: PreviewProvider {
    static var previews: some View {
        USNutritionLabelView(label: .init(language: .english,
                                          servingSize: .amount(amount: .solid(milligrams: 50_000)),
                                          nutritionFacts: [
                                            .calories: .energy(kcal: 350),
                                            .caloriesFromFat: .energy(kcal: 75),
                                            .fat: .solid(milligrams: 12_000),
                                            .saturatedFat: .solid(milligrams: 3_000),
                                            .transFat: .solid(milligrams: 0),
                                            .cholesterol: .solid(milligrams: 10),
                                            .sodium: .solid(milligrams: 100),
                                            .carbohydrates: .solid(milligrams: 10_000),
                                            .sugar: .solid(milligrams: 5_000),
                                            .dietaryFiber: .solid(milligrams: 3_000),
                                            .protein: .solid(milligrams: 12_000),
                                            .calcium: .solid(milligrams: 100),
                                            .vitaminC: .dailyValue(percentage: 35),
                                            .magnesium: .solid(milligrams: 100),
                                          ]),
                             language: .english)
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .preferredColorScheme(.dark)
    }
}
