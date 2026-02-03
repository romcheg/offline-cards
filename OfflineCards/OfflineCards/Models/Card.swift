import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var cardNumber: String
    var storeName: String
    var holderName: String?
    var useQRCode: Bool
    var colorHex: String
    var photoData: [Data]?
    var createdAt: Date

    init(
        cardNumber: String,
        storeName: String,
        holderName: String? = nil,
        useQRCode: Bool = false,
        colorHex: String = "#007AFF",
        photoData: [Data]? = nil
    ) {
        self.cardNumber = cardNumber
        self.storeName = storeName
        self.holderName = holderName
        self.useQRCode = useQRCode
        self.colorHex = colorHex
        self.photoData = photoData
        self.createdAt = Date()
    }
}

// MARK: - Codable Support for Import/Export
extension Card {
    struct ExportData: Codable {
        let cardNumber: String
        let storeName: String
        let holderName: String?
        let useQRCode: Bool
        let colorHex: String
        let photoDataBase64: [String]?
        let createdAt: Date
    }

    func toExportData() -> ExportData {
        ExportData(
            cardNumber: cardNumber,
            storeName: storeName,
            holderName: holderName,
            useQRCode: useQRCode,
            colorHex: colorHex,
            photoDataBase64: photoData?.map { $0.base64EncodedString() },
            createdAt: createdAt
        )
    }

    static func fromExportData(_ data: ExportData) -> Card {
        let photoData = data.photoDataBase64?.compactMap { Data(base64Encoded: $0) }
        return Card(
            cardNumber: data.cardNumber,
            storeName: data.storeName,
            holderName: data.holderName,
            useQRCode: data.useQRCode,
            colorHex: data.colorHex,
            photoData: photoData
        )
    }
}
