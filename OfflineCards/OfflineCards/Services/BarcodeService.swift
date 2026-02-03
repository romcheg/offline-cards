import CoreImage
import UIKit

enum BarcodeService {
    enum BarcodeError: Error {
        case generationFailed
        case invalidInput
    }

    /// Generates a barcode or QR code image from the given string
    /// Uses Code128 for barcodes (universally compatible) and CIQRCodeGenerator for QR codes
    /// - Parameters:
    ///   - from: The string to encode
    ///   - asQRCode: If true, generates QR code; otherwise generates Code128 barcode
    /// - Returns: UIImage of the generated code
    static func generateCode(from string: String, asQRCode: Bool) throws -> UIImage {
        guard !string.isEmpty else {
            throw BarcodeError.invalidInput
        }

        // Code128 is used for all barcodes as it's universally compatible
        // and can encode any ASCII data including numeric-only card numbers
        let filterName = asQRCode ? "CIQRCodeGenerator" : "CICode128BarcodeGenerator"

        guard let filter = CIFilter(name: filterName) else {
            throw BarcodeError.generationFailed
        }

        guard let data = string.data(using: .utf8) else {
            throw BarcodeError.invalidInput
        }

        filter.setValue(data, forKey: "inputMessage")

        // For barcodes, we want higher quality
        if !asQRCode {
            filter.setValue(0.0, forKey: "inputQuietSpace")
        }

        guard let outputImage = filter.outputImage else {
            throw BarcodeError.generationFailed
        }

        // Scale up the image for better quality
        // For QR codes, maintain square aspect ratio; for barcodes, scale appropriately
        let scale: CGFloat
        if asQRCode {
            // QR codes must be square
            scale = 300.0 / max(outputImage.extent.width, outputImage.extent.height)
        } else {
            // Barcodes are wider than tall, but we still scale uniformly
            scale = 5.0
        }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            throw BarcodeError.generationFailed
        }

        return UIImage(cgImage: cgImage)
    }

    /// Generates a high-resolution code for fullscreen display
    /// - Parameters:
    ///   - from: The string to encode
    ///   - asQRCode: If true, generates QR code; otherwise generates Code128 barcode
    /// - Returns: UIImage of the generated code at higher resolution
    static func generateHighResCode(from string: String, asQRCode: Bool) throws -> UIImage {
        guard !string.isEmpty else {
            throw BarcodeError.invalidInput
        }

        let filterName = asQRCode ? "CIQRCodeGenerator" : "CICode128BarcodeGenerator"

        guard let filter = CIFilter(name: filterName) else {
            throw BarcodeError.generationFailed
        }

        guard let data = string.data(using: .utf8) else {
            throw BarcodeError.invalidInput
        }

        filter.setValue(data, forKey: "inputMessage")

        if !asQRCode {
            filter.setValue(0.0, forKey: "inputQuietSpace")
        }

        guard let outputImage = filter.outputImage else {
            throw BarcodeError.generationFailed
        }

        // Higher scale for fullscreen display
        // For QR codes, maintain square aspect ratio; for barcodes, scale appropriately
        let scale: CGFloat
        if asQRCode {
            // QR codes must be square
            scale = 1000.0 / max(outputImage.extent.width, outputImage.extent.height)
        } else {
            // Barcodes are wider than tall, but we still scale uniformly
            scale = 10.0
        }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            throw BarcodeError.generationFailed
        }

        return UIImage(cgImage: cgImage)
    }
}
