import AudioToolbox
import AVFoundation
import PhotosUI
import SwiftData
import SwiftUI

struct CardFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let card: Card?

    @State private var cardNumber: String
    @State private var storeName: String
    @State private var holderName: String
    @State private var useQRCode: Bool
    @State private var selectedColor: Color
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photos: [Data] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingScanner = false

    init(card: Card?) {
        self.card = card
        _cardNumber = State(initialValue: card?.cardNumber ?? "")
        _storeName = State(initialValue: card?.storeName ?? "")
        _holderName = State(initialValue: card?.holderName ?? "")
        _useQRCode = State(initialValue: card?.useQRCode ?? false)
        _selectedColor = State(initialValue: Color(hex: card?.colorHex ?? "#007AFF") ?? .blue)
        _photos = State(initialValue: card?.photoData ?? [])
    }

    var body: some View {
        Form {
            Section("Card Information") {
                HStack {
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.default)
                        .accessibilityIdentifier("cardNumberField")

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button(action: { openScanner() }, label: {
                            Image(systemName: useQRCode ? "qrcode.viewfinder" : "barcode.viewfinder")
                                .font(.title2)
                        })
                        .accessibilityIdentifier("scanButton")
                    }
                }

                TextField("Store Name", text: $storeName)
                    .textContentType(.organizationName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("storeNameField")

                TextField("Holder Name (Optional)", text: $holderName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("holderNameField")
            }

            Section("Display Options") {
                Toggle("Use QR Code", isOn: $useQRCode)

                ColorPicker("Card Color", selection: $selectedColor)
            }

            Section("Photos") {
                Menu {
                    Button(action: { showingPhotoPicker = true }, label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    })
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button(action: { openCamera() }, label: {
                            Label("Take Photo", systemImage: "camera")
                        })
                    }
                } label: {
                    Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                }
                .accessibilityIdentifier("addPhotosButton")

                if !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<photos.count, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    if let uiImage = UIImage(data: photos[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    Button(action: { removePhoto(at: index) }, label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black.opacity(0.6)))
                                    })
                                    .padding(4)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(card == nil ? "Add Card" : "Edit Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .accessibilityIdentifier("cancelButton")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCard()
                }
                .accessibilityIdentifier("saveButton")
                .disabled(!isValid)
            }
        }
        .onChange(of: photoItems) { _, _ in
            Task {
                await loadPhotos()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $photoItems,
            maxSelectionCount: 10,
            matching: .images
        )
        .fullScreenCover(isPresented: $showingCamera, content: {
            CameraPicker { imageData in
                photos.append(imageData)
            }
        })
        .fullScreenCover(isPresented: $showingScanner, content: {
            BarcodeScannerView(scanQRCode: useQRCode) { scannedCode in
                cardNumber = scannedCode
            }
        })
        .onAppear {
            AppDelegate.orientationLock = .portrait
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }

    private var isValid: Bool {
        !cardNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveCard() {
        let trimmedCardNumber = cardNumber.trimmingCharacters(in: .whitespaces)
        let trimmedStoreName = storeName.trimmingCharacters(in: .whitespaces)
        let trimmedHolderName = holderName.trimmingCharacters(in: .whitespaces)

        if let existingCard = card {
            existingCard.cardNumber = trimmedCardNumber
            existingCard.storeName = trimmedStoreName
            existingCard.holderName = trimmedHolderName.isEmpty ? nil : trimmedHolderName
            existingCard.useQRCode = useQRCode
            existingCard.colorHex = selectedColor.toHex()
            existingCard.photoData = photos.isEmpty ? nil : photos
        } else {
            let newCard = Card(
                cardNumber: trimmedCardNumber,
                storeName: trimmedStoreName,
                holderName: trimmedHolderName.isEmpty ? nil : trimmedHolderName,
                useQRCode: useQRCode,
                colorHex: selectedColor.toHex(),
                photoData: photos.isEmpty ? nil : photos
            )
            modelContext.insert(newCard)
        }

        dismiss()
    }

    private func loadPhotos() async {
        photos.removeAll()

        for item in photoItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photos.append(data)
            }
        }
    }

    private func removePhoto(at index: Int) {
        photos.remove(at: index)
        if index < photoItems.count {
            photoItems.remove(at: index)
        }
    }

    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = String(localized: "Camera access is required to take photos. Please enable it in Settings.")
            showingError = true
        @unknown default:
            break
        }
    }

    private func openScanner() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingScanner = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = String(localized: "Camera access is required to scan codes. Please enable it in Settings.")
            showingError = true
        @unknown default:
            break
        }
    }
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let scanQRCode: Bool
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.scanQRCode = scanQRCode
        controller.onCodeScanned = { code in
            onCodeScanned(code)
            dismiss()
        }
        controller.onCancel = {
            dismiss()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var scanQRCode = false
    var onCodeScanned: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              let captureSession = captureSession,
              captureSession.canAddInput(videoInput) else {
            return
        }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()

        guard captureSession.canAddOutput(metadataOutput) else {
            return
        }

        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        if scanQRCode {
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            metadataOutput.metadataObjectTypes = [.code128, .ean13, .ean8, .upce, .code39, .code93, .interleaved2of5]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds

        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
    }

    private func setupOverlay() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        let instructionLabel = UILabel()
        instructionLabel.text = scanQRCode
            ? String(localized: "Point camera at QR code")
            : String(localized: "Point camera at barcode")
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.font = .preferredFont(forTextStyle: .headline)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    private func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopScanning() {
        captureSession?.stopRunning()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        stopScanning()
        onCodeScanned?(stringValue)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageCaptured: (Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.onImageCaptured(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        CardFormView(card: nil)
    }
    .modelContainer(for: Card.self, inMemory: true)
}

#Preview("Edit") {
    NavigationStack {
        CardFormView(card: Card(
            cardNumber: "1234567890",
            storeName: "Metro",
            holderName: "John Doe",
            useQRCode: false,
            colorHex: "#FF5733"
        ))
    }
    .modelContainer(for: Card.self, inMemory: true)
}
