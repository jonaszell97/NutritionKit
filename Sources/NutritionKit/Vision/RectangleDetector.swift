
import AppUtilities
import Vision

public struct RectangleDetector {
    /// The image in which a label should be detected.
    let image: CGImage
    
    /// The orientation of the detection image.
    var imageOrientation: CGImagePropertyOrientation
    
    /// Try to detect a nutrition label within the image.
    func detect() async throws -> [VNRectangleObservation] {
        // Create a request handler
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: imageOrientation,
                                                        options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create a detection request for rectangles
            let rectangleDetectionRequest = VNDetectRectanglesRequest { (request, error) in
                if let error = error {
                    continuation.resume(throwing: "rectangle detection request failed: \(error.localizedDescription)")
                    return
                }
                
                self.onRectangleRequestCompleted(request) {
                    continuation.resume(returning: $0)
                }
            }
            
            rectangleDetectionRequest.maximumObservations = 4
            rectangleDetectionRequest.minimumConfidence = 0.7
            
            // Execute the request
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try imageRequestHandler.perform([rectangleDetectionRequest])
                }
                catch {
                    continuation.resume(throwing: "failed to perform image request: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Completion handler for the rectangle detection request.
    private func onRectangleRequestCompleted(_ request: VNRequest, completionHandler: @escaping ([VNRectangleObservation]) -> Void) {
        guard let observations = request.results as? [VNRectangleObservation] else {
            Log.nutritionKit.error("results are not rectangles")
            completionHandler([])
            
            return
        }
        
        completionHandler(observations.sorted { $0.boundingBox.area > $1.boundingBox.area })
    }
}
