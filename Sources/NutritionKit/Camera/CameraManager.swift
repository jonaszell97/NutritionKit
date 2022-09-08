
import AppUtilities
import AVFoundation
import SwiftUI

internal protocol NutritionCameraDelegate {
    /// Unique identifier for this delegate.
    var id: ObjectIdentifier { get }
    
    /// Called whenever the camera image is updated.
    func cameraImageUpdated(imageBuffer: CMSampleBuffer)
    
    /// Called whenever a barcode is detected.
    func barcodeDetected(data: String, corners: [CGPoint])
}

internal final class CameraManager: NSObject, ObservableObject {
    enum Status {
        /// The camera manager has not yet been initialized.
        case uninitialized
        
        /// The user needs to grant permission to access the camera.
        case unauthorized
        
        /// The user granted access the camera, but the session is still uninitialized.
        case authorized
        
        /// An error occurred during initialization.
        case error(CameraManagerError)
        
        /// The camera manager is authorized and initialized.
        case ready
    }
    
    enum CameraManagerError: String {
        /// The user denied access to the camera.
        case accessDenied
        
        /// No camera input device is available.
        case noInputDevice
    }
    
    /// The AV session.
    let session: AVCaptureSession
    
    /// The current status of the camera manager.
    @Published var status: Status = .uninitialized
    
    /// The current delegates listening for events.
    var delegates: [NutritionCameraDelegate] = []
    
    /// The current image buffer captured by the session.
    var currentImageBuffer: CMSampleBuffer? = nil
    
    /// The output connection for photos.
    fileprivate var videoDataOutput = AVCaptureVideoDataOutput()
    
    /// The video preview layer
    let previewLayer: AVCaptureVideoPreviewLayer
    
    /// Size of the capture buffer.
    var bufferSize: CGSize = .zero
    
    /// Dispatch queue for video output.
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated,
                                                     attributes: [], autoreleaseFrequency: .workItem)
    
    /// The shared instance of the camera manager.
    static let shared = CameraManager()
    
    /// The current image captured by the session.
    public var currentImage: UIImage? {
        guard let sampleBuffer = currentImageBuffer, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        guard var uiImage = UIImage(pixelBuffer: pixelBuffer) else {
            return nil
        }
        
        uiImage = UIImage.rotateSnapshotImage(from: uiImage) ?? uiImage
        uiImage = Self.cropOutputImage(uiImage) ?? uiImage
        
        return uiImage
    }
    
    /// Default initializer.
    public override init() {
        self.session = AVCaptureSession()
        
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        cameraPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.previewLayer = cameraPreviewLayer
        
        super.init()
        self.initialize()
    }
    
    /// Initialize the capture session.
    func initialize() {
        self.status = .unauthorized
        self.requestAuthorization { granted in
            guard granted else {
                return
            }
            
            self.session.beginConfiguration()
            
            guard
                let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first,
                let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                self.session.canAddInput(videoDeviceInput),
                self.session.canAddOutput(self.videoDataOutput)
            else {
                self.status = .error(.noInputDevice)
                return
            }
            
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            self.videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue)
            
            let captureConnection = self.videoDataOutput.connection(with: .video)
            captureConnection?.isEnabled = true
            
            do {
                try videoDevice.lockForConfiguration()
                
                let dimensions = CMVideoFormatDescriptionGetDimensions(videoDevice.activeFormat.formatDescription)
                self.bufferSize.width = CGFloat(dimensions.width)
                self.bufferSize.height = CGFloat(dimensions.height)
                
                videoDevice.unlockForConfiguration()
            }
            catch {
                Log.nutritionKit.error("initializing video device failed: \(error.localizedDescription)")
                self.status = .error(.noInputDevice)
                
                return
            }
            
            self.session.sessionPreset = .hd1920x1080
            self.session.addInput(videoDeviceInput)
            self.session.addOutput(self.videoDataOutput)
            
            let metadataOutput = AVCaptureMetadataOutput()
            if (self.session.canAddOutput(metadataOutput)) {
                self.session.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                let availableTypes = metadataOutput.availableMetadataObjectTypes
                let desiredTypes = [AVMetadataObject.ObjectType.ean8, .ean13].filter { availableTypes.contains($0) }
                metadataOutput.metadataObjectTypes = desiredTypes
            }
            
            self.session.commitConfiguration()
            self.status = .ready
        }
    }
    
    /// Request access to the camera.
    func requestAuthorization(completionHandler: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.status = .authorized
                }
                else {
                    self.status = .error(.accessDenied)
                }
                
                completionHandler(granted)
            }
        }
    }
    
    /// Start the video session.
    public func startSession<T: NutritionCameraDelegate>(for delegate: T) {
        guard case .ready = self.status else {
            Log.nutritionKit.error("camera manager is not ready")
            return
        }
        
        self.delegates.append(delegate)
        
        guard self.delegates.count == 1 else {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    /// Stop the video session.
    public func stopSession<T: NutritionCameraDelegate>(for delegate: T) {
        guard case .ready = self.status else {
            Log.nutritionKit.error("camera manager is not ready")
            return
        }
        
        self.delegates.removeAll { $0.id.hashValue == delegate.id.hashValue }
        
        guard self.delegates.count == 0 else {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
        }
    }
    
    /// Capture the session output as an image.
    public func captureOutput(completionHandler: @escaping (UIImage, CVPixelBuffer) -> Void) {
        guard let sampleBuffer = self.currentImageBuffer else {
            fatalError("captureOutput called with no image")
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        guard var uiImage = UIImage(pixelBuffer: pixelBuffer) else {
            return
        }
        
        uiImage = UIImage.rotateSnapshotImage(from: uiImage) ?? uiImage
        uiImage = Self.cropOutputImage(uiImage) ?? uiImage
        
        completionHandler(uiImage, pixelBuffer)
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    internal static func cropOutputImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let bounds = UIScreen.main.bounds
        let targetAspectRatio = bounds.width / bounds.height
        
        let targetWidth = (image.size.height) * targetAspectRatio
        let xoffset = (image.size.width - targetWidth) * 0.5
        
        let rect = CGRect(x: xoffset, y: 0, width: targetWidth, height: image.size.height)
        guard let croppedImg = cgImage.cropping(to: rect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedImg)
    }
    
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        self.currentImageBuffer = sampleBuffer
        
        for delegate in delegates {
            delegate.cameraImageUpdated(imageBuffer: sampleBuffer)
        }
    }
}

extension CameraManager: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard !delegates.isEmpty else {
            return
        }
        
        guard let metadataObject = metadataObjects.first else { return }
        guard let readableObject = self.previewLayer.transformedMetadataObject(for: metadataObject) else { return }
        guard let transformedObject = readableObject as? AVMetadataMachineReadableCodeObject else { return }
        guard let stringValue = transformedObject.stringValue else { return }
        
        let relativeCorners = (transformedObject.corners.map {
            CGPoint(x: $0.x / self.previewLayer.bounds.width, y: 1 - ($0.y / self.previewLayer.bounds.height))
        })
        
        for delegate in delegates {
            delegate.barcodeDetected(data: stringValue, corners: relativeCorners)
        }
    }
}
