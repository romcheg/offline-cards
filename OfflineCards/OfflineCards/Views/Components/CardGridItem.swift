import SwiftUI

struct CardGridItem: View {
    let card: Card

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Text(card.storeName)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(textColor)

            Spacer()

            HStack(spacing: 8) {
                if card.holderName != nil {
                    Image(systemName: "person.fill")
                }
                if card.photoData?.isEmpty == false {
                    Image(systemName: "photo")
                }
                Image(systemName: card.useQRCode ? "qrcode" : "barcode")
            }
            .font(.caption)
            .foregroundColor(textColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(cardColor)
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var cardColor: Color {
        Color(hex: card.colorHex) ?? Color.blue
    }

    private var textColor: Color {
        cardColor.isLight ? .black : .white
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count

        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else {
            return nil
        }
    }

    func toHex() -> String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        let red = Int(components[0] * 255.0)
        let green = Int(components[1] * 255.0)
        let blue = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    var isLight: Bool {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        // WCAG relative luminance formula
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance > 0.5
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
        CardGridItem(card: Card(
            cardNumber: "1234567890",
            storeName: "Metro",
            holderName: "John Doe",
            colorHex: "#FF5733",
            photoData: [Data()]
        ))
        .frame(height: 120)

        CardGridItem(card: Card(
            cardNumber: "0987654321",
            storeName: "Selgros",
            useQRCode: true,
            colorHex: "#FFEB3B"
        ))
        .frame(height: 120)

        CardGridItem(card: Card(
            cardNumber: "5555555555",
            storeName: "Costco",
            colorHex: "#E0E0E0"
        ))
        .frame(height: 120)
    }
    .padding()
}
