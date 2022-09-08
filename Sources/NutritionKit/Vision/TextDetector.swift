
import AppUtilities
import Vision

struct TextDetector {
    struct TextBox {
        /// The ID of this text detection.
        let id = UUID()
        
        /// The actual text as a string.
        let text: String
        
        /// The bounding box of the text.
        let boundingBox: CGRect
    }
    
    /// The image in which text should be detected.
    let image: CGImage
    
    /// The orientation of the detection image.
    var imageOrientation: CGImagePropertyOrientation
    
    /// Whether to use accurate or fast scanning.
    var type: VNRequestTextRecognitionLevel
    
    /// Try to detect text within the image.
    func detect() async throws -> [TextBox] {
        // Create a request handler
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: imageOrientation,
                                                        options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create a detection request for tex
            let textDetectionRequest = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    continuation.resume(throwing: "text detection request failed: \(error.localizedDescription)")
                    return
                }
                
                self.onRectangleRequestCompleted(request) {
                    continuation.resume(returning: $0)
                }
            }
            
            textDetectionRequest.recognitionLevel = type
            
            // Execute the request
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try imageRequestHandler.perform([textDetectionRequest])
                }
                catch {
                    continuation.resume(throwing: "failed to perform image request: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Completion handler for the rectangle detection request.
    private func onRectangleRequestCompleted(_ request: VNRequest, completionHandler: @escaping ([TextBox]) -> Void) {
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            Log.nutritionKit.error("results are not text observations")
            completionHandler([])
            return
        }
        
        let recognitions: [TextBox] = results.compactMap { observation in
            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else { return nil }
            
            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            let boundingBox = boxObservation?.boundingBox ?? .zero
            
            return TextBox(text: candidate.string, boundingBox: boundingBox)
        }
        
        completionHandler(recognitions)
    }
}

