
import AppUtilities
import SwiftUI

public struct NutritionLabelScannerView: View {
    /// The scanned nutrition label.
    @Binding var label: NutritionLabel?
    
    /// Whether we're currently processing an image.
    @State var isProcessingImage: Bool = false
    
    /// The cutout rectangle.
    @State var cameraRectangle: CameraRect = DefaultCameraOverlayView.defaultLabelCutoutRect
    
    /// The threshold blur score below which an image is rejected.
    let minBlurScore: Float
    
    public init(label: Binding<NutritionLabel?>, minBlurScore: Float = 1300) {
        self._label = label
        self.minBlurScore = minBlurScore
    }
    
    func reset() {
        self.label = nil
        self.isProcessingImage = false
        self.resetCameraCutout()
    }
    
    func resetCameraCutout() {
        withAnimation {
            self.cameraRectangle = DefaultCameraOverlayView.defaultLabelCutoutRect
        }
    }
    
    func onImageCaptured(_ img: UIImage, _ buffer: CVPixelBuffer) {
        guard let cgImage = img.cgImage else {
            self.reset()
            return
        }
        
        self.isProcessingImage = true
        
        let copy = buffer.copy()
        Task {
            let score = try await BlurDetector().processImage(copy)
            guard score >= self.minBlurScore else {
                DispatchQueue.main.async {
                    self.reset()
                }
                
                return
            }
            
            await self.processCapturedImage(cgImage)
        }
    }
    
    func processCapturedImage(_ image: CGImage) async {
        let scanner = NutritionLabelDetector(image: image)
        do {
            guard let (_, rect) = try await scanner.findNutritionLabel() else {
                DispatchQueue.main.async {
                    self.reset()
                }
                
                return
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.cameraRectangle = .init(rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight)
                }
            }
            
            let label = try await scanner.scanNutritionLabel()
            guard label.isValid else {
                DispatchQueue.main.async {
                    self.reset()
                }
                
                return
            }
            
            DispatchQueue.main.async {
                self.isProcessingImage = false
                self.label = label
            }
        }
        catch {
            Log.nutritionKit.error("finding nutrition label failed: \(error.localizedDescription)")
        }
    }
    
    public var body: some View {
        ZStack {
            AnyCameraView(onImageUpdated: { img, buffer in
                self.onImageCaptured(img, buffer)
            }) {
                DefaultCameraOverlayView(rectangle: $cameraRectangle)
            }
        }
    }
}
