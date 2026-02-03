import SwiftUI

struct BarcodeView: View {
    let cardNumber: String
    let useQRCode: Bool
    let highResolution: Bool

    init(cardNumber: String, useQRCode: Bool, highResolution: Bool = false) {
        self.cardNumber = cardNumber
        self.useQRCode = useQRCode
        self.highResolution = highResolution
    }

    var body: some View {
        Group {
            if let image = generateBarcodeImage() {
                if useQRCode {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Failed to generate barcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }

    private func generateBarcodeImage() -> UIImage? {
        do {
            if highResolution {
                return try BarcodeService.generateHighResCode(
                    from: cardNumber,
                    asQRCode: useQRCode
                )
            } else {
                return try BarcodeService.generateCode(
                    from: cardNumber,
                    asQRCode: useQRCode
                )
            }
        } catch {
            print("Barcode generation error: \(error)")
            return nil
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BarcodeView(cardNumber: "1234567890", useQRCode: false)
            .frame(height: 100)

        BarcodeView(cardNumber: "1234567890", useQRCode: true)
            .frame(height: 200)
    }
    .padding()
}
