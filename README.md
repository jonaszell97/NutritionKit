# NutritionKit

This library provides useful functionality for food and nutrition apps, including:

- Integration with the *OpenFoodFacts* database
- Barcode scanning
- Nutrition label scanning
- Nutrition label rendering

#

## OpenFoodFacts Integration

To lookup a food item from the OpenFoodFacts database, you can use the `OpenFoodFactsAPI` class.

```swift
import NutritionKit

let api = OpenFoodFactsAPI.shared
let foodItem = try await api.find("59032823")

print(foodItem.productName) // Prints "Nutella - 630g"
```

To configure the fields you are interested in, you can use the `configure` function:

```swift
api.configure(productFields: [.productName, .servingSize])
```

#

## Barcode Scanning