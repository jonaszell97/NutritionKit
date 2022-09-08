
import AppUtilities
import AVFoundation
import Combine
import SwiftUI

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

struct CameraCutoutShape: Shape, Animatable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
    
    var animatableData: AnimatableTuple4<CGPoint, CGPoint, CGPoint, CGPoint> {
        get {
            .init(topLeft, topRight, bottomLeft, bottomRight)
        }
        set {
            topLeft = newValue.first
            topRight = newValue.second
            bottomLeft = newValue.third
            bottomRight = newValue.fourth
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.addRect(rect)
        path.closeSubpath()
        
        path.move(to: .init(x: topLeft.x * rect.width, y: rect.height - topLeft.y * rect.height))
        path.addLine(to: .init(x: topRight.x * rect.width, y: rect.height - topRight.y * rect.height))
        path.addLine(to: .init(x: bottomRight.x * rect.width, y: rect.height - bottomRight.y * rect.height))
        path.addLine(to: .init(x: bottomLeft.x * rect.width, y: rect.height - bottomLeft.y * rect.height))
        path.addLine(to: .init(x: topLeft.x * rect.width, y: rect.height - topLeft.y * rect.height))
        
        path.closeSubpath()
        
        return path
    }
}

struct CameraCutoutStrokeShape: Shape, Animatable {
    let lineLength: CGFloat
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
    
    var animatableData: AnimatableTuple4<CGPoint, CGPoint, CGPoint, CGPoint> {
        get {
            .init(topLeft, topRight, bottomLeft, bottomRight)
        }
        set {
            topLeft = newValue.first
            topRight = newValue.second
            bottomLeft = newValue.third
            bottomRight = newValue.fourth
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = CGPoint(x: self.topLeft.x * rect.width, y: rect.height - self.topLeft.y * rect.height)
        let topRight = CGPoint(x: self.topRight.x * rect.width, y: rect.height - self.topRight.y * rect.height)
        let bottomLeft = CGPoint(x: self.bottomLeft.x * rect.width, y: rect.height - self.bottomLeft.y * rect.height)
        let bottomRight = CGPoint(x: self.bottomRight.x * rect.width, y: rect.height - self.bottomRight.y * rect.height)
        
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
