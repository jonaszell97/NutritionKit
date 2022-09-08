
import AppUtilities
import AVFoundation
import Combine
import SwiftUI

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
    @State var rectangleCutoutTopLeft: CGPoint = .zero
    @State var rectangleCutoutTopRight: CGPoint = .zero
    @State var rectangleCutoutBottomLeft: CGPoint = .zero
    @State var rectangleCutoutBottomRight: CGPoint = .zero
    
    /// The default cutout rect.
    static let defaultBarcodeCutoutRect = (
        topLeft: CGPoint(x: 0.15, y: 0.6),
        topRight: CGPoint(x: 0.85, y: 0.6),
        bottomLeft: CGPoint(x: 0.15, y: 0.4),
        bottomRight: CGPoint(x: 0.85, y: 0.4)
    )
    
    public init(barcodeData: Binding<Barcode?>) {
        self._barcodeData = barcodeData
        self.rectangleCutoutTopLeft = Self.defaultBarcodeCutoutRect.topLeft
        self.rectangleCutoutTopRight = Self.defaultBarcodeCutoutRect.topRight
        self.rectangleCutoutBottomLeft = Self.defaultBarcodeCutoutRect.bottomLeft
        self.rectangleCutoutBottomRight = Self.defaultBarcodeCutoutRect.bottomRight
    }
    
    func resetCameraCutout() {
        withAnimation {
            self.rectangleCutoutTopLeft = Self.defaultBarcodeCutoutRect.topLeft
            self.rectangleCutoutTopRight = Self.defaultBarcodeCutoutRect.topRight
            self.rectangleCutoutBottomLeft = Self.defaultBarcodeCutoutRect.bottomLeft
            self.rectangleCutoutBottomRight = Self.defaultBarcodeCutoutRect.bottomRight
        }
    }
    
    public var body: some View {
        ZStack {
            AnyCameraView(onBarcodeRead: { data, corners in
                self.barcodeData = .init(data: data, corners: corners)
            }) {
                ZStack {
                    CameraCutoutShape(topLeft: self.rectangleCutoutTopLeft,
                                      topRight: self.rectangleCutoutTopRight,
                                      bottomLeft: self.rectangleCutoutBottomLeft,
                                      bottomRight: self.rectangleCutoutBottomRight)
                        .fill(Color.black, style: .init(eoFill: true))
                        .opacity(0.4)
                    
                    CameraCutoutStrokeShape(lineLength: 15,
                                            topLeft: self.rectangleCutoutTopLeft,
                                            topRight: self.rectangleCutoutTopRight,
                                            bottomLeft: self.rectangleCutoutBottomLeft,
                                            bottomRight: self.rectangleCutoutBottomRight)
                        .stroke(Color.white, style: .init(lineWidth: 5, lineCap: .round))
                }
            }
        }
    }
}
