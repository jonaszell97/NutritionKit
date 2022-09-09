
import AppUtilities
import SwiftUI

public struct FoodScannerView: View {
    /// The current scanned food item.
    @Binding var foodItem: FoodItem?
    
    /// Whether or not a barcode is currently being processed.
    @State var isProcessingBarcode: Bool = false
    
    /// The cutout rectangle.
    @State var cameraRectangle: CameraRect = DefaultCameraOverlayView.defaultBarcodeCutoutRect
    
    public init(foodItem: Binding<FoodItem?>) {
        self._foodItem = foodItem
    }
    
    func reset() {
        self.foodItem = nil
        self.isProcessingBarcode = false
        self.resetCameraCutout()
    }
    
    func resetCameraCutout() {
        withAnimation {
            self.cameraRectangle = DefaultCameraOverlayView.defaultBarcodeCutoutRect
        }
    }
    
    func onBarcodeRead(barcode: String, corners: [CGPoint]) {
        guard !self.isProcessingBarcode else {
            return
        }
        
        self.isProcessingBarcode = true
        self.cameraRectangle = .init(corners[3], corners[0], corners[2], corners[1])
        
        Task {
            do {
                let data = try await OpenFoodFactsAPI.shared.find(barcode)
                DispatchQueue.main.async {
                    self.isProcessingBarcode = false
                    self.foodItem = data
                }
            }
            catch {
                Log.nutritionKit.error(error.localizedDescription)
                DispatchQueue.main.async {
                    self.isProcessingBarcode = false
                }
            }
        }
    }
    
    public var body: some View {
        ZStack {
            AnyCameraView(onBarcodeRead: { data, corners in
                self.onBarcodeRead(barcode: data, corners: corners)
            }) {
                DefaultCameraOverlayView(rectangle: $cameraRectangle)
            }
        }
    }
}
