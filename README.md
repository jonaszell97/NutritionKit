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

NutritionKit provides a SwiftUI view for scanning generic barcodes, `BarcodeScannerView`. To use this view, you must set the value `Privacy - Camera Usage Description` in your app's `Info.plist`.

By itself `BarcodeScannerView` only shows the live camera feed with no overlay or other info. You can provide more information yourself by embedding it in a `ZStack` or in another view.

```swift
import NutritionKit

struct ContentView: View {
    @State var barcodeData: Barcode? = nil

    var body: some View {
        BarcodeScannerView(barcodeData: $barcodeData)
            .onChange(of: barcodeData) { data in
                // A barcode was detected in the camera feed
            }
    }
}
```