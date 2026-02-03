import SwiftUI
import UIKit

struct BarcodeFullScreenView: View {
    @Environment(\.dismiss) private var dismiss

    let cardNumber: String
    let useQRCode: Bool

    @State private var originalBrightness: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack {
                    BarcodeView(
                        cardNumber: cardNumber,
                        useQRCode: useQRCode,
                        highResolution: true
                    )
                    .frame(
                        maxWidth: useQRCode
                            ? min(geometry.size.width, geometry.size.height) * 0.8
                            : max(geometry.size.width, geometry.size.height) * 0.85,
                        maxHeight: useQRCode
                            ? min(geometry.size.width, geometry.size.height) * 0.8
                            : min(geometry.size.width, geometry.size.height) * 0.65
                    )
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                VStack {
                    Spacer()
                    Text("Tap to close")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 40)
                }
            }
        }
        .onTapGesture {
            UIScreen.main.brightness = originalBrightness
            dismiss()
        }
        .onAppear {
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .statusBar(hidden: true)
    }
}

#Preview {
    BarcodeFullScreenView(cardNumber: "1234567890", useQRCode: false)
}

#Preview("QR Code") {
    BarcodeFullScreenView(cardNumber: "1234567890", useQRCode: true)
}
