import SwiftUI

struct CardListItem: View {
    let card: Card

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(cardColor)
                .frame(width: 12, height: 12)

            Text(card.storeName)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            if card.holderName != nil {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if card.photoData?.isEmpty == false {
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: card.useQRCode ? "qrcode" : "barcode")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var cardColor: Color {
        Color(hex: card.colorHex) ?? Color.blue
    }
}

#Preview {
    List {
        CardListItem(card: Card(
            cardNumber: "1234567890",
            storeName: "Metro",
            holderName: "John Doe",
            colorHex: "#FF5733",
            photoData: [Data()]
        ))

        CardListItem(card: Card(
            cardNumber: "0987654321",
            storeName: "Selgros",
            useQRCode: true,
            colorHex: "#3498DB"
        ))

        CardListItem(card: Card(
            cardNumber: "5555555555",
            storeName: "Costco",
            colorHex: "#2ECC71"
        ))
    }
}
