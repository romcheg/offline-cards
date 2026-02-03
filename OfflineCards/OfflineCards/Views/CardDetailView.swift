import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var card: Card

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var barcodeFullscreenID: UUID?
    @State private var selectedPhotoIndex: IndexWrapper?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                barcodeSection

                detailsSection

                if let photoData = card.photoData, !photoData.isEmpty {
                    photosSection(photoData)
                }
            }
            .padding()
        }
        .navigationTitle(card.storeName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingEdit = true }, label: {
                    Text("Edit")
                })
                .accessibilityIdentifier("editButton")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive, action: { showingDeleteAlert = true }, label: {
                    Image(systemName: "trash")
                })
                .accessibilityIdentifier("deleteButton")
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                CardFormView(card: card)
            }
        }
        .fullScreenCover(item: $barcodeFullscreenID) { _ in
            BarcodeFullScreenView(
                cardNumber: card.cardNumber,
                useQRCode: card.useQRCode
            )
        }
        .fullScreenCover(item: $selectedPhotoIndex) { index in
            if let photoData = card.photoData,
               index.value < photoData.count,
               let uiImage = UIImage(data: photoData[index.value]) {
                ImageFullScreenView(image: uiImage, isPresented: Binding(
                    get: { selectedPhotoIndex != nil },
                    set: { if !$0 { selectedPhotoIndex = nil } }
                ))
            }
        }
        .alert("Delete Card", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteCard)
        } message: {
            Text("Are you sure you want to delete this card? This action cannot be undone.")
        }
        .onAppear {
            AppDelegate.orientationLock = .portrait
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
        .onChange(of: barcodeFullscreenID) { _, newID in
            if newID == nil {
                AppDelegate.orientationLock = .portrait
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
            }
        }
        .onChange(of: selectedPhotoIndex) { _, index in
            if index == nil {
                AppDelegate.orientationLock = .portrait
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
            }
        }
    }

    private var barcodeSection: some View {
        VStack(spacing: 12) {
            if card.useQRCode {
                // QR code layout: code on left, card number on right
                HStack(spacing: 16) {
                    BarcodeView(
                        cardNumber: card.cardNumber,
                        useQRCode: true
                    )
                    .frame(width: 150, height: 150)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .onTapGesture {
                        openBarcodeFullscreen()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Card Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.cardNumber.formattedCardNumber)
                            .font(.system(.headline, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                // Barcode layout: code on top, card number below
                VStack(spacing: 8) {
                    BarcodeView(
                        cardNumber: card.cardNumber,
                        useQRCode: false
                    )
                    .frame(height: 150)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .onTapGesture {
                        openBarcodeFullscreen()
                    }

                    Text(card.cardNumber.formattedCardNumber)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }

            Text("Tap to view fullscreen")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let holderName = card.holderName {
                DetailRow(label: "Holder:", value: holderName)
            }

            HStack {
                Text("Code Type:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: card.useQRCode ? "qrcode" : "barcode")
                    Text(card.useQRCode ? "QR Code" : "Barcode")
                }
                .font(.body)
            }

            HStack {
                Text("Card Color:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Circle()
                    .fill(Color(hex: card.colorHex) ?? .blue)
                    .frame(width: 24, height: 24)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func photosSection(_ photoData: [Data]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<photoData.count, id: \.self) { index in
                        if let uiImage = UIImage(data: photoData[index]) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    selectedPhotoIndex = IndexWrapper(value: index)
                                }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func openBarcodeFullscreen() {
        if !card.useQRCode {
            AppDelegate.orientationLock = .landscape
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
            }
        }
        barcodeFullscreenID = UUID()
    }

    private func deleteCard() {
        modelContext.delete(card)
        try? modelContext.save()
        dismiss()
    }
}

struct DetailRow: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

struct IndexWrapper: Identifiable, Equatable {
    let id = UUID()
    let value: Int

    static func == (lhs: IndexWrapper, rhs: IndexWrapper) -> Bool {
        lhs.value == rhs.value
    }
}

extension String {
    /// Formats a card number for display by grouping digits.
    /// Groups by 4 from the right, with any remainder at the front.
    /// Examples: "1234567890" → "12 3456 7890", "12345678" → "1234 5678"
    var formattedCardNumber: String {
        let digits = self.filter { $0.isNumber }
        guard digits.count > 4 else { return self }

        var result: [String] = []
        var remaining = digits

        // Calculate remainder for first group
        let remainder = digits.count % 4
        if remainder > 0 {
            let index = remaining.index(remaining.startIndex, offsetBy: remainder)
            result.append(String(remaining[..<index]))
            remaining = String(remaining[index...])
        }

        // Group remaining digits by 4
        while !remaining.isEmpty {
            let endIndex = remaining.index(remaining.startIndex, offsetBy: min(4, remaining.count))
            result.append(String(remaining[..<endIndex]))
            remaining = String(remaining[endIndex...])
        }

        return result.joined(separator: " ")
    }
}

extension UUID: Identifiable {
    public var id: UUID { self }
}

#Preview {
    NavigationStack {
        CardDetailView(card: Card(
            cardNumber: "1234567890",
            storeName: "Metro",
            holderName: "John Doe",
            useQRCode: false,
            colorHex: "#FF5733"
        ))
    }
    .modelContainer(for: Card.self, inMemory: true)
}
