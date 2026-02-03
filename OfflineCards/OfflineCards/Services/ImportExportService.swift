import Foundation
import SwiftData

enum ImportExportService {
    enum ExportError: Error {
        case encodingFailed
        case noCardsToExport
    }

    enum ImportError: Error {
        case decodingFailed
        case invalidData
        case fileReadFailed
    }

    struct ExportContainer: Codable {
        let version: Int
        let exportDate: Date
        let cards: [Card.ExportData]
    }

    /// Exports all cards to JSON data
    /// - Parameter cards: Array of cards to export
    /// - Returns: JSON data containing all cards
    static func exportCards(_ cards: [Card]) throws -> Data {
        guard !cards.isEmpty else {
            throw ExportError.noCardsToExport
        }

        let exportData = cards.map { $0.toExportData() }
        let container = ExportContainer(
            version: 1,
            exportDate: Date(),
            cards: exportData
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            return try encoder.encode(container)
        } catch {
            throw ExportError.encodingFailed
        }
    }

    /// Imports cards from JSON data
    /// - Parameter data: JSON data to import
    /// - Returns: Array of cards parsed from JSON
    static func importCards(from data: Data) throws -> [Card] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let container = try decoder.decode(ExportContainer.self, from: data)
            return container.cards.map { Card.fromExportData($0) }
        } catch {
            throw ImportError.decodingFailed
        }
    }

    /// Imports cards from a file URL
    /// - Parameter url: URL of the JSON file
    /// - Returns: Array of cards parsed from file
    static func importCards(from url: URL) throws -> [Card] {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileReadFailed
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            return try importCards(from: data)
        } catch let error as ImportError {
            throw error
        } catch {
            throw ImportError.fileReadFailed
        }
    }

    /// Checks if a card with the same number already exists
    /// - Parameters:
    ///   - card: Card to check
    ///   - existingCards: Array of existing cards
    /// - Returns: True if duplicate exists
    static func isDuplicate(card: Card, in existingCards: [Card]) -> Bool {
        existingCards.contains { $0.cardNumber == card.cardNumber }
    }

    /// Finds duplicates between imported and existing cards
    /// - Parameters:
    ///   - importedCards: Cards being imported
    ///   - existingCards: Cards already in database
    /// - Returns: Array of card numbers that are duplicates
    static func findDuplicates(
        importedCards: [Card],
        existingCards: [Card]
    ) -> [String] {
        let existingNumbers = Set(existingCards.map { $0.cardNumber })
        return importedCards
            .filter { existingNumbers.contains($0.cardNumber) }
            .map { $0.cardNumber }
    }
}
