
import AVFoundation
import Combine
import Panorama
import SwiftUI
import Toolbox

internal final class CameraViewController: UIViewController, NutritionCameraDelegate {
    let onBarcodeRead: Optional<(String, [CGPoint]) -> Void>
    let onImageUpdated: Optional<(UIImage, CVPixelBuffer) -> Void>
    
    init(onBarcodeRead: Optional<(String, [CGPoint]) -> Void> = nil,
         onImageUpdated: Optional<(UIImage, CVPixelBuffer) -> Void> = nil) {
        self.onBarcodeRead = onBarcodeRead
        self.onImageUpdated = onImageUpdated
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        CameraManager.shared.stopSession(for: self)
    }
    
    func initialize() {
        let cameraPreviewLayer = CameraManager.shared.previewLayer
        cameraPreviewLayer.frame = self.view.frame
        
        self.view.layer.insertSublayer(cameraPreviewLayer, at: 0)
        CameraManager.shared.startSession(for: self)
    }
    
    var id: ObjectIdentifier {
        .init(self)
    }
    
    func cameraImageUpdated(imageBuffer: CMSampleBuffer) {
        guard let onImageUpdated = self.onImageUpdated else {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer) else {
            return
        }
        
        guard var uiImage = UIImage(pixelBuffer: pixelBuffer) else {
            return
        }
        
        uiImage = UIImage.rotateSnapshotImage(from: uiImage) ?? uiImage
        uiImage = CameraManager.cropOutputImage(uiImage) ?? uiImage
        
        onImageUpdated(uiImage, pixelBuffer)
    }
    
    func barcodeDetected(data: String, corners: [CGPoint]) {
        self.onBarcodeRead?(data, corners)
    }
}

internal struct CameraLiveView: UIViewControllerRepresentable {
    /// The camera controller.
    let controller: CameraViewController
    
    func makeUIViewController(context: Context) -> CameraViewController {
        self.controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController,
                                context: UIViewControllerRepresentableContext<CameraLiveView>) { }
}

internal struct AnyCameraView<Content: View>: View {
    /// The camera manager.
    @ObservedObject var cameraManager: CameraManager
    
    /// The camera controller.
    let controller: CameraViewController
    
    /// The view to display above the camera feed.
    let cameraViewOverlay: Content
    
    init(onBarcodeRead: Optional<(String, [CGPoint]) -> Void> = nil,
         onImageUpdated: Optional<(UIImage, CVPixelBuffer) -> Void> = nil,
         @ViewBuilder content: () -> Content) {
        self.cameraManager = .shared
        self.cameraViewOverlay = content()
        self.controller = .init(onBarcodeRead: onBarcodeRead, onImageUpdated: onImageUpdated)
    }
    
    var uninitializedView: some View {
        Rectangle().fill(Color.black)
    }
    
    func errorView(_ error: CameraManager.CameraManagerError) -> some View {
        ZStack {
            Rectangle().fill(Color.black)
            
            VStack {
                Text(verbatim: error.rawValue)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
    
    var readyView: some View {
        CameraLiveView(controller: self.controller)
            .overlay {
                self.cameraViewOverlay
            }
    }
    
    var body: some View {
        ZStack {
            switch cameraManager.status {
            case .uninitialized:
                uninitializedView
            case .unauthorized:
                uninitializedView
            case .authorized:
                uninitializedView
            case .error(let error):
                errorView(error)
            case .ready:
                readyView
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

public typealias CameraRect = AnimatableTuple4<CGPoint, CGPoint, CGPoint, CGPoint>

public struct CameraCutoutShape: Shape, Animatable {
    var points: CameraRect
    
    public var animatableData: CameraRect {
        get {
            points
        }
        set {
            points = newValue
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.addRect(rect)
        path.closeSubpath()
        
        let topLeft = points.first
        let topRight = points.second
        let bottomLeft = points.third
        let bottomRight = points.fourth
        
        path.move(to: .init(x: topLeft.x * rect.width, y: rect.height - topLeft.y * rect.height))
        path.addLine(to: .init(x: topRight.x * rect.width, y: rect.height - topRight.y * rect.height))
        path.addLine(to: .init(x: bottomRight.x * rect.width, y: rect.height - bottomRight.y * rect.height))
        path.addLine(to: .init(x: bottomLeft.x * rect.width, y: rect.height - bottomLeft.y * rect.height))
        path.addLine(to: .init(x: topLeft.x * rect.width, y: rect.height - topLeft.y * rect.height))
        
        path.closeSubpath()
        
        return path
    }
}

public struct CameraCutoutStrokeShape: Shape, Animatable {
    let lineLength: CGFloat
    var points: CameraRect
    
    public var animatableData: CameraRect {
        get {
            points
        }
        set {
            points = newValue
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        var topLeft = points.first
        var topRight = points.second
        var bottomLeft = points.third
        var bottomRight = points.fourth
        
        topLeft = CGPoint(x: topLeft.x * rect.width, y: rect.height - topLeft.y * rect.height)
        topRight = CGPoint(x: topRight.x * rect.width, y: rect.height - topRight.y * rect.height)
        bottomLeft = CGPoint(x: bottomLeft.x * rect.width, y: rect.height - bottomLeft.y * rect.height)
        bottomRight = CGPoint(x: bottomRight.x * rect.width, y: rect.height - bottomRight.y * rect.height)
        
        // Top Left
        path.move(to: topLeft)
        path.addLine(to: topLeft + (topRight - topLeft).normalized * lineLength)
        
        path.move(to: topLeft)
        path.addLine(to: topLeft + (bottomLeft - topLeft).normalized * lineLength)
        
        // Top Right
        path.move(to: topRight)
        path.addLine(to: topRight + (topLeft - topRight).normalized * lineLength)
        
        path.move(to: topRight)
        path.addLine(to: topRight + (bottomRight - topRight).normalized * lineLength)
        
        // Bottom Left
        path.move(to: bottomLeft)
        path.addLine(to: bottomLeft + (topLeft - bottomLeft).normalized * lineLength)
        
        path.move(to: bottomLeft)
        path.addLine(to: bottomLeft + (bottomRight - bottomLeft).normalized * lineLength)
        
        // Bottom Right
        path.move(to: bottomRight)
        path.addLine(to: bottomRight + (topRight - bottomRight).normalized * lineLength)
        
        path.move(to: bottomRight)
        path.addLine(to: bottomRight + (bottomLeft - bottomRight).normalized * lineLength)
        
        return path
    }
}

public struct DefaultCameraOverlayView: View {
    /// The current corner points.
    @Binding var rectangle: CameraRect
    
    /// The default cutout rect for barcode scanning.
    static let defaultBarcodeCutoutRect: CameraRect = .init(
        CGPoint(x: 0.15, y: 0.6),
        CGPoint(x: 0.85, y: 0.6),
        CGPoint(x: 0.15, y: 0.4),
        CGPoint(x: 0.85, y: 0.4)
    )
    
    /// The default cutout rect for nutrition label scanning.
    static let defaultLabelCutoutRect: CameraRect = .init(
        CGPoint(x: 0.15, y: 0.8),
        CGPoint(x: 0.85, y: 0.8),
        CGPoint(x: 0.15, y: 0.2),
        CGPoint(x: 0.85, y: 0.2)
    )
    
    public var body: some View {
        ZStack {
            CameraCutoutShape(points: rectangle)
                .fill(Color.black, style: .init(eoFill: true))
                .opacity(0.4)
            
            CameraCutoutStrokeShape(lineLength: 15, points: rectangle)
                .stroke(Color.white, style: .init(lineWidth: 5, lineCap: .round))
        }
    }
}

internal extension UIScreen {
    var orientation: UIInterfaceOrientation {
        let point = coordinateSpace.convert(CGPoint.zero, to: fixedCoordinateSpace)
        switch (point.x, point.y) {
        case (0, 0):
            return .portrait
        case let (x, y) where x != 0 && y != 0:
            return .portraitUpsideDown
        case let (0, y) where y != 0:
            return .landscapeLeft
        case let (x, 0) where x != 0:
            return .landscapeRight
        default:
            return .unknown
        }
    }
}

internal extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0,
                                                                  width: CVPixelBufferGetWidth(pixelBuffer),
                                                                  height: CVPixelBufferGetHeight(pixelBuffer)))
        
        guard let cgImage else {
            return nil
        }
        
        self.init(cgImage: cgImage)
    }
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// Create a snapshot of this frame with the correct orientation.
    static func rotateSnapshotImage(from rawPhoto: UIImage) -> UIImage? {
        let rotationAngleDegrees: Float?
        switch UIScreen.main.orientation {
        case .portrait:
            rotationAngleDegrees = 90
        case .portraitUpsideDown:
            rotationAngleDegrees = -90
        case .landscapeLeft:
            rotationAngleDegrees = 180
        case .landscapeRight:
            rotationAngleDegrees = nil
        default:
            rotationAngleDegrees = nil
        }
        
        let finalPhoto: UIImage
        if let rotationAngleDegrees = rotationAngleDegrees {
            finalPhoto = rawPhoto.rotate(radians: rotationAngleDegrees * .deg2rad)!
        }
        else {
            finalPhoto = rawPhoto
        }
        
        return finalPhoto
    }
}
