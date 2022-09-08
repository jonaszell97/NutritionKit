
import AppUtilities
import SwiftUI

struct Lexer {
    /// The text to parse.
    let rawText: TextDetector.TextBox
    
    /// The language to use for parsing.
    var language: LabelLanguage = .english
    
    /// Callback to invoke when a text segment has been categorized.
    var handleParsedText: (CategorizedText) -> Void
    
    /// The remaining text to parse.
    private var text: String
    
    /// The start offset of the current token.
    private var tokenStartOffset: Int = 0
    
    /// The current offset in the text buffer.
    private var currentOffset: Int = 0
    
    /// The current text buffer.
    private var buffer: String = ""
    
    /// A set containing all known label spellings
    private var allSpellings = Set<String>()
    
    /// A set containing all known unit spellings
    private var allUnits = Set<String>()
    
    /// The last remembered state.
    private var resetPoint: (String, String, Int)? = nil
    
    var nutritionFactLabels: [NutritionItem: Set<String>] {
        switch language {
        case .english:
            return NutritionItem.knownLabelsEnglish
        case .german:
            return NutritionItem.knownLabelsGerman
        }
    }
    
    var metaLabels: [KnownLabel: Set<String>] {
        switch language {
        case .english:
            return KnownLabel.knownLabelsEnglish
        case .german:
            return KnownLabel.knownLabelsGerman
        }
    }
    
    var unitSpellings: [MeasurementUnit: Set<String>] {
        switch language {
        case .english:
            return MeasurementUnit.knownSpellingsEnglish
        case .german:
            return MeasurementUnit.knownSpellingsGerman
        }
    }
    
    var decimalSeparator: Character {
        switch language {
        case .english:
            return "."
        case .german:
            return ","
        }
    }
    
    /// Default initializer.
    init(rawText: TextDetector.TextBox, language: LabelLanguage, handleParsedText: @escaping (CategorizedText) -> Void) {
        self.rawText = rawText
        self.language = language
        self.handleParsedText = handleParsedText
        self.text = rawText.text.lowercased()
        self.allSpellings = Set<String>()
        
        for (_, spellings) in nutritionFactLabels {
            self.allSpellings.insert(contentsOf: spellings)
        }
        for (_, spellings) in metaLabels {
            self.allSpellings.insert(contentsOf: spellings)
        }
        for (_, spellings) in unitSpellings {
            self.allUnits.insert(contentsOf: spellings)
        }
    }
    
    /// Whether or not the buffer contains only numeric characters or decimal points.
    private var bufferIsNumeric: Bool {
        self.buffer.allSatisfy {
            $0.isNumber || $0 == "," || $0 == "."
        }
    }
    
    /// Appends the next character from the text to the buffer.
    private mutating func eat() {
        guard !self.text.isEmpty else {
            fatalError("trying to eat non-existent character")
        }
        
        let character = self.text.first!
        
        self.currentOffset += 1
        self.buffer.append(character)
        self.text.remove(at: self.text.startIndex)
    }
    
    /// Backtrack by one character.
    private mutating func backtrack() {
        guard !self.buffer.isEmpty else {
            fatalError("trying to eat non-existent character")
        }
        
        let character = self.buffer.popLast()!
        
        self.currentOffset -= 1
        self.text.insert(character, at: self.text.startIndex)
    }
    
    /// Whether the end of the text is reached.
    private var atEnd: Bool {
        self.text.isEmpty
    }
    
    /// Eat and discard whitespace characters.
    private mutating func eatWhitespace() {
        while self.text.first?.isWhitespace ?? false {
            self.eat()
        }
        
        self.buffer = ""
    }
    
    /// Eat and discard whitespace characters.
    private mutating func eatUntilWhitespace() {
        while !(self.text.first?.isWhitespace ?? true) {
            self.eat()
        }
    }
    
    /// Parse the text segment.
    mutating func parse() {
        // Continue parsing tokens until we reach the end
        while !self.atEnd {
            // Skip whitespace
            self.eatWhitespace()
            
            guard let token = self.parseNextToken() else {
                break
            }
            
            handleParsedText(token)
        }
    }
    
    /// Remember the current state so that we can restore it.
    private mutating func rememberState() {
        self.resetPoint = (self.text, self.buffer, self.currentOffset)
    }
    
    /// Reset state to the last reset point.
    private mutating func resetState() {
        guard let resetPoint = resetPoint else {
            fatalError("no state to restore!")
        }
        
        self.text = resetPoint.0
        self.buffer = resetPoint.1
        self.currentOffset = resetPoint.2
        self.resetPoint = nil
    }
    
    /// Parse the next token.
    mutating func parseNextToken() -> CategorizedText? {
        // Reset the buffer
        self.buffer = ""
        self.tokenStartOffset = self.currentOffset
        
        // Parse until the end of the token is reached
        var foundMatchingLabel = false
        var isStartOfLabel = true
        var foundNumber = false
        var skippedWhitespace = false
        
        while true {
            if text.starts(with: " ") && !foundNumber && !foundMatchingLabel {
                self.rememberState()
                skippedWhitespace = true
            }
            
            // Eat the next character
            self.eat()
            
            // Check if the current buffer is a known label
            if isStartOfLabel {
                if allSpellings.contains(self.buffer) {
                    if atEnd {
                        return self.parseLabel()
                    }
                    
                    foundMatchingLabel = true
                    // Remember this state in case this is the complete token
                    self.rememberState()
                }
                // Otherwise, check if this may still be the start of a label
                else if !(allSpellings.contains { $0.starts(with: self.buffer) }) {
                    // If we already found a label, reset and return it
                    if foundMatchingLabel {
                        self.resetState()
                        return self.parseLabel()
                    }
                    
                    if !self.bufferIsNumeric {
                        if skippedWhitespace {
                            self.resetState()
                        }
                        
                        return createToken(description: .uncategorized(text: buffer))
                    }
                    
                    isStartOfLabel = false
                }
            }
            
            // Check if this may be a measurement value
            if self.bufferIsNumeric {
                if atEnd {
                    return self.parseMeasurement()
                }
                
                foundNumber = true
                self.rememberState()
            }
            else if foundNumber {
                // Return the number and try to parse the unit
                self.resetState()
                return self.parseMeasurement()
            }
            
            if (!isStartOfLabel && !foundNumber) || self.atEnd {
                // We don't know this token, parse until next whitespace and return as uncategorized
                self.eatUntilWhitespace()
                return createToken(description: .uncategorized(text: buffer))
            }
        }
    }
    
    private func parseLabel() -> CategorizedText {
        for (item, spellings) in nutritionFactLabels {
            if spellings.contains(self.buffer) {
                return createToken(description: .nutritionFactLabel(fact: item))
            }
        }
        
        for (item, spellings) in metaLabels {
            if spellings.contains(self.buffer) {
                return createToken(description: .knownLabel(label: item))
            }
        }
        
        fatalError("not a label!")
    }
    
    private mutating func parseMeasurement() -> CategorizedText {
        // Parse the number
        guard let amount = Double(self.buffer.replacingOccurrences(of: ",", with: ".")) else {
            self.eatUntilWhitespace()
            return createToken(description: .uncategorized(text: buffer))
        }
        
        // Try to find a unit
        self.rememberState()
        self.eatWhitespace()
        
        var foundUnit = false
        while !self.atEnd {
            self.eat()
            
            if allUnits.contains(self.buffer) {
                foundUnit = true
                self.rememberState()
            }
            else if !(allUnits.contains { $0.starts(with: self.buffer) }) {
                if foundUnit {
                    self.resetState()
                }
                
                break
            }
        }
        
        if !foundUnit {
            self.resetState()
            return createToken(description: .amount(value: .unitless(value: amount)))
        }
        
        for (unit, spellings) in unitSpellings {
            if spellings.contains(self.buffer) {
                if unit.isSolid {
                    return createToken(description: .amount(value: .solid(milligrams: unit.normalizeValue(amount))))
                }
                
                if unit.isLiquid {
                    return createToken(description: .amount(value: .liquid(milliliters: unit.normalizeValue(amount))))
                }
                
                if unit.isEnergy {
                    return createToken(description: .amount(value: .energy(kcal: unit.normalizeValue(amount))))
                }
                
                return createToken(description: .amount(value: .dailyValue(percentage: Int(amount))))
            }
        }
        
        fatalError("not a valid unit")
    }
    
    private func createToken(description: TextDescription) -> CategorizedText {
        .init(description: description, rawText: self.estimateTokenPosition())
    }
    
    private func estimateTokenPosition() -> TextDetector.TextBox {
        let tokenLength = self.currentOffset - self.tokenStartOffset
        let totalLength = self.rawText.text.count
        let characterWidth = self.rawText.boundingBox.width / CGFloat(totalLength)
        
        let xPosition = self.rawText.boundingBox.minX + (CGFloat(self.tokenStartOffset) * characterWidth)
        let width = CGFloat(tokenLength) * characterWidth
        
        return .init(text: self.rawText.text, boundingBox: .init(x: xPosition, y: self.rawText.boundingBox.minY,
                                                                 width: width, height: self.rawText.boundingBox.height))
    }
}
