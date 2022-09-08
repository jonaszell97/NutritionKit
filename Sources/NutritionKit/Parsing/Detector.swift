
import AppUtilities
import Foundation
import ImageIO
import SwiftUI
import Vision

public final class NutritionLabelDetector {
    /// The image to scan.
    let image: CGImage
    
    /// The detected label language.
    var language: LabelLanguage?
    
    /// The cropped nutrition label.
    var nutritionLabelImage: CGImage?
    
    /// Default initializer.
    public init(image: CGImage) {
        self.image = image
        self.language = nil
        self.nutritionLabelImage = nil
    }
    
    /// Check whether or not an image contains a nutrition label.
    public func findNutritionLabel() async throws -> (CGImage, VNRectangleObservation)? {
        if let result = try await self.findNutritionLabelPrimary() {
            return result
        }
        
        return try await self.findNutritionLabelSecondary()
    }
    
    /// Preferred method for identifying nutrition labels by detecting rectangles in the input image.
    private func findNutritionLabelPrimary() async throws -> (CGImage, VNRectangleObservation)? {
        // Find rectangles in the image
        let rectangleDetector = RectangleDetector(image: image, imageOrientation: .up)
        let rectangles = try await rectangleDetector.detect()
        
        // Find the rectangle that contains the most known labels with the smallest area
        var label: CGImage? = nil
        var observation: VNRectangleObservation? = nil
        
        var mostLabels = 0
        var smallestArea: Int = .max
        
        for rectangle in rectangles {
            guard let deskewedImage = self.deskewImage(image, rectangle: rectangle) else {
                continue
            }
            
            let textDetector = TextDetector(image: deskewedImage, imageOrientation: .up, type: .fast)
            let texts = try await textDetector.detect()
            
            let language = self.determineLabelLanguage(rawText: texts)
            self.language = language
            
            let keywords = KnownLabel.keywordsByLanguage[language] ?? []
            let searchTerms = texts.map { $0.text.lowercased() }
            
            var keywordsInRect = Set<String>()
            for searchTerm in searchTerms {
                for keyword in keywords {
                    if searchTerm.contains(keyword) {
                        keywordsInRect.insert(keyword)
                    }
                }
            }
            
            let keywordCount = keywordsInRect.count
            let area = deskewedImage.width * deskewedImage.height
            
            if keywordCount > mostLabels {
                label = deskewedImage
                observation = rectangle
                mostLabels = keywordCount
                smallestArea = area
            }
            else if keywordCount == mostLabels, area < smallestArea {
                label = deskewedImage
                observation = rectangle
                smallestArea = area
            }
        }
        
        guard let label, let observation else {
            return nil
        }
        
        self.nutritionLabelImage = label
        return (label, observation)
    }
    
    /// Deskew an image.
    private func deskewImage(_ image: CGImage, rectangle: VNRectangleObservation) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let height = CGFloat(image.height)
        let width = CGFloat(image.width)
        
        let applied = ciImage
            .applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: .init(x: rectangle.topLeft.x * width, y: rectangle.topLeft.y * height)),
                "inputTopRight": CIVector(cgPoint: .init(x: rectangle.topRight.x * width, y: rectangle.topRight.y * height)),
                "inputBottomLeft": CIVector(cgPoint: .init(x: rectangle.bottomLeft.x * width, y: rectangle.bottomLeft.y * height)),
                "inputBottomRight": CIVector(cgPoint: .init(x: rectangle.bottomRight.x * width, y: rectangle.bottomRight.y * height)),
            ])
        
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(applied, from: applied.extent) {
            return cgImage
        }
        
        return nil
    }
    
    /// Preferred method for identifying nutrition labels by detecting rectangles in the input image.
    private func findNutritionLabelSecondary() async throws -> (CGImage, VNRectangleObservation)? {
        // Rotate image so that text is horizontal
        let rotatedImage = try await self.rotateImage(image: self.image)
        
        // Detect text to find known keywords
        let textDetector = TextDetector(image: rotatedImage, imageOrientation: .up, type: .fast)
        let texts = try await textDetector.detect()
        let searchTexts = texts.map { ($0.boundingBox, $0.text.lowercased()) }
        
        let language = self.determineLabelLanguage(rawText: texts)
        self.language = language
        
        let keywords = KnownLabel.keywordsByLanguage[language] ?? []
        
        var boundingBox: CGRect? = nil
        for (textBoundingBox, searchText) in searchTexts {
            var foundKeyword = false
            for keyword in keywords {
                if searchText.contains(keyword) {
                    foundKeyword = true
                    break
                }
            }
            
            guard foundKeyword else {
                continue
            }
            
            if var currentBoundingBox = boundingBox {
                currentBoundingBox = currentBoundingBox.expanded(toContain: textBoundingBox.topLeft)
                currentBoundingBox = currentBoundingBox.expanded(toContain: textBoundingBox.bottomRight)
                
                boundingBox = currentBoundingBox
            }
            else {
                boundingBox = textBoundingBox
            }
        }
        
        guard
            let boundingBox = boundingBox?.scaled(by: 1.1),
            let croppedImage = rotatedImage.cropping(to: boundingBox.scaled(width: CGFloat(rotatedImage.width),
                                                                            height: CGFloat(rotatedImage.height)))
        else {
            return nil
        }
        
        self.nutritionLabelImage = croppedImage
        return (croppedImage, .init(boundingBox: boundingBox))
    }
    
    /// Scans the nutrition label.
    public func scanNutritionLabel() async throws -> NutritionLabel {
        guard let language = self.language, let nutritionLabelImage = self.nutritionLabelImage else {
            throw "no nutrition label found"
        }
        
        let textDetector = TextDetector(image: nutritionLabelImage, imageOrientation: .up, type: .accurate)
        let texts = try await textDetector.detect()
        
        let parser = HorizontalTabularNutritionLabelParser(rawDetectedText: texts, language: language)
        return parser.parse()
    }
    
    /// Try to determine the language of the label.
    private func determineLabelLanguage(rawText: [TextDetector.TextBox]) -> LabelLanguage {
        let keywords = KnownLabel.keywordsByLanguage
        var scoreByLanguage = [LabelLanguage: Int]()
        
        for text in rawText {
            let searchText = text.text.lowercased()
            for (language, keywords) in keywords {
                let score = keywords.filter { searchText.contains($0) }.count
                scoreByLanguage[language] = (scoreByLanguage[language] ?? 0) + score
            }
        }
        
        return scoreByLanguage.max { $0.value < $1.value }?.key ?? .english
    }
    
    /// Try to detect image rotation by tracing character lines and rotate the image accordingly.
    private func rotateImage(image: CGImage) async throws -> CGImage {
        // Determine the image orientation based on detected characters
        let characterDetector = CharacterDetector(image: image, imageOrientation: .up)
        let characters = try await characterDetector.detect()
        
        var usedCharacters = Set<CGPoint>()
        var characterAngles = [Int: Int]()
        var i = 0
        
        for character in characters {
            defer {
                i += 1
            }
            
            guard usedCharacters.insert(character.center).inserted else {
                continue
            }
            
            guard let (start, end) = self.findCharacterLine(startingAt: character,
                                                            characters: characters,
                                                            usedCharacters: &usedCharacters) else {
                continue
            }
            
            let line = end - start
            guard line.magnitude >= 0.03 else {
                continue
            }
            
            let angle = line.signedAngle(to: .init(x: 1, y: 0))
            let roughAngle = Int(Angle(radians: angle).degrees)
            
            characterAngles[roughAngle] = (characterAngles[roughAngle] ?? 0) + 1
        }
        
        // Find the max value in the 'histogram'
        let minAngle = characterAngles.min { $0.key < $1.key }?.key ?? 0
        let maxAngle = characterAngles.max { $0.key < $1.key }?.key ?? 0
        
        var maxScore: Double = 0
        var maxScoreAngle = 0
        
        for i in minAngle...maxAngle {
            var valueCount = 0
            var sum = 0
            
            for j in (-2...2) {
                let index = i + j
                if let count = characterAngles[index] {
                    valueCount += 1
                    sum += count
                }
            }
            
            guard valueCount > 0 else {
                continue
            }
            
            let avg = Double(sum) / Double(valueCount)
            if avg > maxScore {
                maxScore = avg
                maxScoreAngle = i
            }
        }
        
        guard maxScore > 5, abs(maxScoreAngle) > 3 else {
            return image
        }
        
        return UIImage(cgImage: image).rotate(radians: Float(-Angle(degrees: Double(maxScoreAngle)).radians))?.cgImage ?? image
    }
    
    /// Try to find a cotiguous line of characters starting at the given character.
    private func findCharacterLine(startingAt firstCharacter: CGRect,
                                   characters: [CGRect],
                                   usedCharacters: inout Set<CGPoint>) -> (CGPoint, CGPoint)? {
        let maxDistanceBetweenCharacters: CGFloat = 0.001
        
        var charactersOnLine: [CGRect] = [firstCharacter]
        var currentCharacter = firstCharacter
        
        while true {
            let center = currentCharacter.center
            
            var minDistance = CGFloat.infinity
            var closestCharacter: CGRect? = nil
            
            for other in characters {
                let line = other.center - center
                guard line.x > 0 else {
                    continue
                }
                
                let distance = line.magnitudeSquared
                guard !distance.isZero, distance <= maxDistanceBetweenCharacters, distance < minDistance else {
                    continue
                }
                
                if charactersOnLine.count > 1 {
                    let last = charactersOnLine[charactersOnLine.count - 1]
                    let secondToLast = charactersOnLine[charactersOnLine.count - 2]
                    let angle = (last.center - secondToLast.center).angle(to: .init(x: 1, y: 0))
                    let newAngle = (other.center - last.center).angle(to: .init(x: 1, y: 0))
                    let diff = abs(angle - newAngle)
                    
                    guard diff < 0.05 else {
                        continue
                    }
                }
                
                minDistance = distance
                closestCharacter = other
            }
            
            guard let closestCharacter = closestCharacter else {
                break
            }
            
            guard usedCharacters.insert(closestCharacter.center).inserted else {
                break
            }
            
            charactersOnLine.append(closestCharacter)
            currentCharacter = closestCharacter
        }
        
        guard charactersOnLine.count > 1 else {
            return nil
        }
        
        guard charactersOnLine.count > 2 else {
            return (charactersOnLine.first!.center, charactersOnLine.last!.center)
        }
        
        let xs = charactersOnLine.map { Double($0.center.x) }
        let ys = charactersOnLine.map { Double($0.center.y) }
        
        let regressor = linearRegression(xs, ys)
        
        let startY = regressor(Double(charactersOnLine.first!.center.x))
        let endY = regressor(Double(charactersOnLine.last!.center.x))
        let start = CGPoint(x: charactersOnLine.first!.center.x, y: CGFloat(startY))
        let end = CGPoint(x: charactersOnLine.last!.center.x, y: CGFloat(endY))
        
        return (start, end)
    }
}
