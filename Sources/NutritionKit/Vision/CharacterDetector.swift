
import AppUtilities
import Vision

struct CharacterDetector {
    /// The image in which text should be detected.
    let image: CGImage
    
    /// The orientation of the detection image.
    var imageOrientation: CGImagePropertyOrientation
    
    /// Try to detect text within the image.
    func detect() async throws -> [CGRect] {
        // Create a request handler
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: imageOrientation,
                                                        options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create a detection request for character rectangles
            let textDetectionRequest = VNDetectTextRectanglesRequest { (request, error) in
                if let error = error {
                    continuation.resume(throwing: "text detection request failed: \(error.localizedDescription)")
                    return
                }
                
                self.onRectangleRequestCompleted(request) {
                    continuation.resume(returning: $0)
                }
            }
            
            textDetectionRequest.reportCharacterBoxes = true
            
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
    private func onRectangleRequestCompleted(_ request: VNRequest, completionHandler: @escaping ([CGRect]) -> Void) {
        guard let results = request.results as? [VNTextObservation] else {
            Log.nutritionKit.error("results are not text observations")
            completionHandler([])
            
            return
        }
        
        var characters: [CGRect] = []
        for result in results {
            guard let characterBoxes = result.characterBoxes else {
                continue
            }
            
            characters.append(contentsOf: characterBoxes.map { $0.boundingBox })
        }
        
        completionHandler(characters)
    }
}

