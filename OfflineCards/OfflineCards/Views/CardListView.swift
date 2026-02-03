import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.storeName) private var allCards: [Card]

    @State private var searchText = ""
    @AppStorage("isGridView") private var isGridView = true
    @State private var showingAddCard = false
    @State private var showingImport = false
    @State private var exportFileURL: IdentifiableURL?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var importAlertShowing = false
    @State private var pendingImportCards: [Card] = []
    @State private var eraseBeforeImport = false
    @State private var duplicateCardNumbers: [String] = []
    @State private var showingDuplicateAlert = false

    private var filteredCards: [Card] {
        if searchText.isEmpty {
            return allCards
        }
        return allCards.filter { card in
            card.storeName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if allCards.isEmpty {
                    emptyStateView
                } else {
                    if isGridView {
                        gridView
                    } else {
                        listView
                    }
                }
            }
            .navigationTitle("Cards")
            .searchable(text: $searchText, prompt: "Search by store name")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: exportCards) {
                            Label("Export Cards", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { showingImport = true }, label: {
                            Label("Import Cards", systemImage: "square.and.arrow.down")
                        })
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isGridView.toggle() }, label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    })
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddCard = true }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
            .sheet(isPresented: $showingAddCard) {
                NavigationStack {
                    CardFormView(card: nil)
                }
            }
            .sheet(item: $exportFileURL) { identifiableURL in
                ShareSheet(items: [identifiableURL.url])
            }
            .fileImporter(
                isPresented: $showingImport,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Import Cards", isPresented: $importAlertShowing) {
                Button("Keep") {
                    eraseBeforeImport = false
                    performImport()
                }
                Button("Erase All", role: .destructive) {
                    eraseBeforeImport = true
                    performImport()
                }
                Button("Cancel", role: .cancel) {
                    pendingImportCards = []
                }
            } message: {
                Text("Erase existing cards before importing?")
            }
            .alert("Duplicates Found", isPresented: $showingDuplicateAlert) {
                Button("Overwrite", role: .destructive) {
                    confirmOverwrite()
                }
                Button("Skip") {
                    skipDuplicates()
                }
                Button("Cancel", role: .cancel) {
                    pendingImportCards = []
                    duplicateCardNumbers = []
                }
            } message: {
                Text("""
                    \(duplicateCardNumbers.count) card(s) already exist:
                    \(duplicateCardNumbers.joined(separator: ", "))
                    """)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                AppDelegate.orientationLock = .portrait
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Cards Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap + to add your first card")
                .foregroundColor(.secondary)
        }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(filteredCards) { card in
                    NavigationLink(destination: CardDetailView(card: card)) {
                        CardGridItem(card: card)
                            .frame(height: 120)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var listView: some View {
        List(filteredCards) { card in
            NavigationLink(destination: CardDetailView(card: card)) {
                CardListItem(card: card)
            }
        }
    }

    private func exportCards() {
        do {
            let data = try ImportExportService.exportCards(allCards)
            let fileURL = data.temporaryFileURL()
            exportFileURL = IdentifiableURL(url: fileURL)
        } catch {
            errorMessage = "Failed to export cards: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                pendingImportCards = try ImportExportService.importCards(from: url)
                if allCards.isEmpty {
                    eraseBeforeImport = false
                    performImport()
                } else {
                    importAlertShowing = true
                }
            } catch {
                errorMessage = "Failed to import cards: \(error.localizedDescription)"
                showingError = true
            }
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func performImport() {
        if eraseBeforeImport {
            allCards.forEach { modelContext.delete($0) }
        }

        duplicateCardNumbers = ImportExportService.findDuplicates(
            importedCards: pendingImportCards,
            existingCards: allCards
        )

        if !duplicateCardNumbers.isEmpty {
            showingDuplicateAlert = true
        } else {
            insertImportedCards()
        }
    }

    private func confirmOverwrite() {
        allCards.filter { duplicateCardNumbers.contains($0.cardNumber) }
            .forEach { modelContext.delete($0) }
        insertImportedCards()
    }

    private func skipDuplicates() {
        let cardsToInsert = pendingImportCards.filter { card in
            !duplicateCardNumbers.contains(card.cardNumber)
        }
        cardsToInsert.forEach { modelContext.insert($0) }
        pendingImportCards = []
        duplicateCardNumbers = []
    }

    private func insertImportedCards() {
        pendingImportCards.forEach { modelContext.insert($0) }
        pendingImportCards = []
        duplicateCardNumbers = []
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Data {
    func temporaryFileURL() -> URL {
        let fileName = "cards_export_\(Date().timeIntervalSince1970).json"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try? write(to: fileURL)
        return fileURL
    }
}

#Preview {
    CardListView()
        .modelContainer(for: Card.self, inMemory: true)
}
