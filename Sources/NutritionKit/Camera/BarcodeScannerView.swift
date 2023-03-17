
import SwiftUI
import Toolbox

public struct Barcode: Codable, Hashable {
    /// The barcode data.
    let data: String
    
    /// The corners of the barcode.
    let corners: [CGPoint]
}

public struct BarcodeScannerView: View {
    /// The current barcode data.
    @Binding var barcodeData: Barcode?
    
    /// The cutout rectangle.
    @State var cameraRectangle: CameraRect = DefaultCameraOverlayView.defaultBarcodeCutoutRect
    
    public init(barcodeData: Binding<Barcode?>) {
        self._barcodeData = barcodeData
    }
    
    func resetCameraCutout() {
        withAnimation {
            self.cameraRectangle = DefaultCameraOverlayView.defaultBarcodeCutoutRect
        }
    }
    
    public var body: some View {
        ZStack {
            AnyCameraView(onBarcodeRead: { data, corners in
                self.barcodeData = .init(data: data, corners: corners)
            }) {
                DefaultCameraOverlayView(rectangle: $cameraRectangle)
            }
        }
    }
}
