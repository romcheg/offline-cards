# AI Agent Documentation - Offline Cards iOS App

This document provides technical details for AI agents working on this codebase.

## Project Overview

**Name**: Offline Cards
**Type**: Native iOS application
**Purpose**: Store discount and entry cards with offline functionality
**Target**: iPhone (iOS 17+)
**Language**: Swift 5.9+
**UI Framework**: SwiftUI
**Data Persistence**: SwiftData
**Architecture**: MVVM-like pattern with SwiftUI

## Technology Stack

- **Swift 5.9+**: Primary language
- **SwiftUI**: Declarative UI framework (iOS 17+)
- **SwiftData**: Modern ORM for data persistence (replaces Core Data)
- **Core Image**: Native barcode/QR code generation
- **AVFoundation**: Native barcode/QR code scanning
- **PhotosUI**: Native photo picker integration
- **XCTest**: Unit testing framework
- **XCUITest**: UI/end-to-end testing framework
- **SwiftLint**: Code quality and style enforcement

## Project Structure

```
OfflineCards/
├── OfflineCards/                      # Main app target
│   ├── App/
│   │   └── OfflineCardsApp.swift     # @main entry point, SwiftData container setup
│   ├── Models/
│   │   └── Card.swift                # SwiftData model with Codable support
│   ├── Views/
│   │   ├── CardListView.swift        # Main list/grid view (root)
│   │   ├── CardDetailView.swift      # Card detail with barcode display
│   │   ├── CardFormView.swift        # Add/edit card form
│   │   ├── BarcodeFullScreenView.swift  # Fullscreen barcode with brightness
│   │   ├── ImageFullScreenView.swift    # Fullscreen image viewer
│   │   └── Components/
│   │       ├── BarcodeView.swift     # Reusable barcode/QR component
│   │       ├── CardGridItem.swift    # Grid tile view
│   │       └── CardListItem.swift    # List row view
│   ├── Services/
│   │   ├── BarcodeService.swift      # Barcode/QR generation logic
│   │   └── ImportExportService.swift # JSON import/export logic
│   └── Resources/
│       └── Assets.xcassets            # App assets (icons, colors)
├── OfflineCardsTests/                 # Unit tests
│   ├── CardModelTests.swift
│   ├── BarcodeServiceTests.swift
│   ├── ImportExportServiceTests.swift
│   └── AppDelegateTests.swift         # Orientation locking tests
└── OfflineCardsUITests/               # UI/E2E tests
    └── OfflineCardsUITests.swift
```

## Key Architecture Patterns

### Data Flow
1. **SwiftData** manages persistence automatically
2. Views use `@Query` to observe data changes
3. Views use `@Environment(\.modelContext)` to modify data
4. Model changes automatically trigger view updates

### View Hierarchy
```
CardListView (root)
├── CardGridItem / CardListItem (components)
├── NavigationLink → CardDetailView
│   ├── BarcodeView (component)
│   ├── NavigationLink → CardFormView (edit)
│   ├── fullScreenCover → BarcodeFullScreenView
│   └── fullScreenCover → ImageFullScreenView
└── sheet → CardFormView (add new)
```

### State Management
- **@State**: Local view state
- **@Binding**: Parent-child state sharing
- **@Environment**: Access to system services (modelContext, dismiss)
- **@Query**: SwiftData query observation
- **@Bindable**: Two-way binding to SwiftData models

## Data Model

### Card (SwiftData Model)
Location: `OfflineCards/Models/Card.swift`

**Properties:**
- `cardNumber: String` - Unique identifier, required
- `storeName: String` - Store name, required
- `holderName: String?` - Optional card holder name
- `useQRCode: Bool` - Toggle between barcode/QR (default: false)
- `colorHex: String` - Card color as hex (default: "#007AFF")
- `photoData: [Data]?` - Optional array of image data
- `createdAt: Date` - Auto-set creation timestamp

**Unique Constraint**: `@Attribute(.unique)` on `cardNumber`

**Codable Support**:
- `ExportData` struct for JSON serialization
- `toExportData()` - Convert to exportable format
- `fromExportData(_:)` - Create from imported data
- Photos encoded as base64 strings in JSON

## Service Layer

### BarcodeService
Location: `OfflineCards/Services/BarcodeService.swift`

**Type**: Enum (stateless utility)

**Barcode Format**: Code128 (universally compatible, supports any ASCII input)
- Chosen over EAN-13/EAN-8 for maximum compatibility
- Works with any card number length (numeric or alphanumeric)
- Supported by all modern barcode scanners

**Methods**:
- `generateCode(from:asQRCode:) throws -> UIImage`
  - Generates standard resolution barcode/QR
  - Uses Core Image `CICode128BarcodeGenerator` or `CIQRCodeGenerator`
  - Scales to 300x150 for display quality

- `generateHighResCode(from:asQRCode:) throws -> UIImage`
  - Generates high resolution for fullscreen
  - Scales to 1000x500 for scanner readability

**Errors**: `BarcodeError.invalidInput`, `BarcodeError.generationFailed`

### ImportExportService
Location: `OfflineCards/Services/ImportExportService.swift`

**Type**: Enum (stateless utility)

**Export**:
- `exportCards([Card]) throws -> Data`
- Creates `ExportContainer` with version, date, and cards
- JSON format with pretty printing and sorted keys
- Photos as base64 strings
- Throws `ExportError.noCardsToExport` if empty

**Import**:
- `importCards(from: Data) throws -> [Card]`
- `importCards(from: URL) throws -> [Card]`
- Parses JSON with ISO8601 date decoding
- Returns array of Card instances (not yet inserted)
- Throws `ImportError.decodingFailed` or `.fileReadFailed`

**Utilities**:
- `isDuplicate(card:in:) -> Bool`
- `findDuplicates(importedCards:existingCards:) -> [String]`

## View Details

### CardListView
**Purpose**: Main view, displays cards in list or grid

**Features**:
- Search bar (real-time filter by store name)
- Toggle between list/grid layouts
- Add button (opens CardFormView sheet)
- Menu with Export/Import options
- Empty state view when no cards

**State**:
- `@Query` for all cards (sorted by storeName)
- `@State` for search text, view mode, modals
- Import flow with alerts for erase/duplicate handling

**Navigation**: NavigationStack root

### CardDetailView
**Purpose**: Show card details and barcode

**Features**:
- Large barcode/QR display (tap for fullscreen)
- Store name, card number, holder name
- Photo gallery (thumbnails, tap for fullscreen)
- Edit button (opens CardFormView sheet)
- Delete button (with confirmation alert)

**Parameters**: `@Bindable var card: Card`

### CardFormView
**Purpose**: Add or edit card

**Features**:
- Text fields for card number, store name, holder name
- Barcode/QR scanner button (scans and fills card number)
- QR/Barcode toggle
- Color picker
- Photo picker (PhotosUI, max 10 images)
- Photo removal (X button on thumbnails)
- Validation (required fields)

**Parameters**: `let card: Card?` (nil for add, Card for edit)

**State**: Local @State copies of all fields, synced on save

**Scanner** (BarcodeScannerView):
- Uses AVFoundation `AVCaptureMetadataOutput`
- QR mode: scans `.qr` type
- Barcode mode: scans `.code128`, `.ean13`, `.ean8`, `.upce`, `.code39`, `.code93`, `.interleaved2of5`
- Vibrates on successful scan
- Close button in top-right corner

### BarcodeFullScreenView
**Purpose**: Fullscreen barcode display for scanning

**Features**:
- Black background
- High-resolution barcode
- Auto brightness to max on appear
- Restore brightness on disappear
- Tap to dismiss

**Implementation**: Uses `UIScreen.main.brightness`

### ImageFullScreenView
**Purpose**: Fullscreen image viewer

**Features**:
- Pinch to zoom (MagnificationGesture)
- Pan when zoomed (DragGesture)
- Double-tap to toggle 1x/2x zoom
- Close button (X in top-right)
- No brightness modification

## Orientation Management

### AppDelegate
Location: `OfflineCards/App/OfflineCardsApp.swift`

**Purpose**: Dynamic orientation control per view

**Implementation**:
- `static var orientationLock: UIInterfaceOrientationMask = .portrait`
- Returns orientation mask in `application(_:supportedInterfaceOrientationsFor:)`

**Modern iOS API** (iOS 16+):
- Uses `UIWindowScene.requestGeometryUpdate(.iOS(interfaceOrientations:))`
- Replaces deprecated `UIDevice.current.setValue(..., forKey: "orientation")`

**Orientation Rules**:
- **Main views** (list, detail, form): `.portrait` only
- **Barcode fullscreen**: `.landscape` (better for scanning)
- **Photo fullscreen**: `.all` (user can rotate freely)

**View Lifecycle**:
- Set `AppDelegate.orientationLock` in `.onAppear` or `.onChange`
- Call `requestGeometryUpdate` to force rotation
- Restore portrait in `.onDisappear` or `.onChange` (when closing fullscreen)

**Critical Pattern for fullScreenCover**:
```swift
.onChange(of: showingFullscreen) { _, isShowing in
    if !isShowing {
        AppDelegate.orientationLock = .portrait
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }
}
```
Note: `.onAppear` doesn't fire when returning from `fullScreenCover`, use `.onChange` instead.

## App Icon Configuration

Location: `OfflineCards/OfflineCards/Resources/Assets.xcassets/AppIcon.appiconset/`

**Required Sizes** (15 total):
- 20x20 @1x, @2x, @3x (Settings)
- 29x29 @1x, @2x, @3x (Settings)
- 40x40 @1x, @2x, @3x (Spotlight)
- 60x60 @2x, @3x (App icon)
- 76x76 @1x, @2x (iPad)
- 83.5x83.5 @2x (iPad Pro)
- 1024x1024 @1x (App Store)

**Contents.json**: Manifest describing all icon sizes and their usage
**Generation**: Use `sips` command-line tool for resizing from source image

## Build & Development

### Makefile Targets

**Simulator Testing**:
- `make test` - Run all tests on simulator
- `make test-unit` - Unit tests only
- `make test-ui` - UI tests only
- `make run` - Build and run on simulator

**Physical Device** (requires connected iPhone):
- `make test-iphone` - Run all tests on iPhone
- `make test-iphone-unit` - Unit tests on iPhone
- `make test-iphone-ui` - UI tests on iPhone
- `make run-iphone` - Build and install on iPhone

**Other**:
- `make lint` - Run SwiftLint
- `make clean` - Clean build artifacts
- `make generate` - Regenerate Xcode project from project.yml
- `make verify` - Run linting + all tests

**Configuration**:
- Uses `-allowProvisioningUpdates` for automatic code signing

### Environment Configuration

**Setup**:
1. Copy `.env-template` to `.env`
2. Fill in your `DEVELOPMENT_TEAM` and `DEVICE_ID` values

**Required Variables** (in `.env`):
- `DEVELOPMENT_TEAM` - Apple Developer Team ID (from Apple Developer portal or Xcode)
- `DEVICE_ID` - Physical iPhone UDID (find via `xcrun xctrace list devices`)

**Note**: The `.env` file is gitignored and must be created locally.

### Code Signing (Physical Device)

Location: `project.yml`

**Requirements**:
- Apple ID signed into Xcode
- Development certificate created
- `.env` file with `DEVELOPMENT_TEAM` set

**Team Configuration**:
```yaml
DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}  # Loaded from .env via xcodegen
CODE_SIGN_STYLE: Automatic
```

**Note**: Free Apple ID works for development (7-day app expiration)

## Color Extensions

Location: `OfflineCards/Views/Components/CardGridItem.swift`

**Color(hex:)**:
- Initializer for hex strings ("#RRGGBB")
- Returns `nil` if invalid

**toHex()**:
- Converts Color to hex string
- Returns "#RRGGBB" format

## Coding Conventions

### SwiftUI Patterns
- Use explicit `label:` parameter for buttons with multiple closures
- Use `content:` parameter for sheet/fullScreenCover with onDismiss
- Avoid trailing closure syntax when multiple closures present

### Naming
- Views: `[Feature]View` (e.g., CardListView)
- Components: Descriptive names (e.g., BarcodeView)
- Services: `[Feature]Service` (e.g., BarcodeService)
- Models: Singular nouns (e.g., Card)

### Error Handling
- Services throw typed errors (enum)
- Views catch and display with alerts
- UI tests use optional chaining (`app?.`)

### Testing
- Unit tests: Test model, services, pure logic
- UI tests: Test complete user flows
- Use `@testable import OfflineCards` for unit tests
- UI tests use XCUIApplication optional

## SwiftLint Configuration

Location: `.swiftlint.yml`

**Strict Rules Enabled**:
- `empty_count` - Use `.isEmpty` not `.count > 0`
- `empty_string` - Use `.isEmpty` not `== ""`
- `force_unwrapping` - No `!` force unwrapping
- `implicitly_unwrapped_optional` - No `!` declarations
- `sorted_imports` - Imports alphabetically sorted
- Line length: 120 warning, 200 error
- No trailing whitespace

**Disabled Rules**: None

## Import/Export Format

### JSON Structure
```json
{
  "version": 1,
  "exportDate": "2026-02-02T12:00:00Z",
  "cards": [
    {
      "cardNumber": "1234567890",
      "storeName": "Example Store",
      "holderName": "John Doe",
      "useQRCode": false,
      "colorHex": "#007AFF",
      "photoDataBase64": ["base64string1", "base64string2"],
      "createdAt": "2026-01-15T10:30:00Z"
    }
  ]
}
```

### Import Flow
1. User selects JSON file
2. Alert: "Erase existing cards?" (default: no)
3. Parse JSON to Card objects
4. Check for duplicates (by cardNumber)
5. If duplicates: Alert with options (overwrite/skip/cancel)
6. Insert cards into modelContext

## Common Tasks

### Adding a New Feature
1. Check if it requires model changes (Card.swift)
2. Add service layer logic if needed
3. Update/create views following existing patterns
4. Add unit tests for logic
5. Add UI tests for user flow
6. Run `swiftlint` and fix any violations
7. Update this document if architecture changes

### Modifying the Data Model
1. Update `Card` class in `Models/Card.swift`
2. Update `ExportData` struct if needed
3. Update conversion methods (`toExportData`, `fromExportData`)
4. Consider migration strategy (SwiftData handles most automatically)
5. Update tests
6. Increment export version if format changes

### Adding a New View
1. Create in `Views/` or `Views/Components/`
2. Follow naming convention (`*View.swift`)
3. Use environment objects for data access
4. Add navigation if needed
5. Create #Preview at bottom
6. Follow SwiftUI patterns (explicit labels for multi-closure)

### Service Layer Updates
1. Keep services as enums (stateless)
2. Use throws for errors, not optionals
3. Define typed error enums
4. Add comprehensive unit tests
5. Document public methods with /// comments

## Testing Strategy

### Unit Tests
**Purpose**: Test business logic in isolation

**Coverage**:
- Card model creation and conversion
- Barcode generation (all formats)
- Import/export serialization
- Duplicate detection logic

**Patterns**:
- Use `throws` in test function signature
- `XCTAssert*` for validations
- Test both success and failure paths

### UI Tests
**Purpose**: Test complete user workflows

**Coverage**:
- Add/edit/delete card flows
- Search and filter
- View mode toggle (list/grid)
- Import/export flows
- Navigation between screens

**Patterns**:
- Use optional chaining (`app?.`)
- Helper methods for common actions
- Use accessibility identifiers
- Wait for existence with timeouts

## Dependencies

### Native Frameworks
- `Foundation` - Basic types, Data, Date, JSON
- `SwiftUI` - UI framework
- `SwiftData` - Data persistence
- `CoreImage` - Barcode generation (CIFilter)
- `AVFoundation` - Barcode/QR scanning (AVCaptureMetadataOutput)
- `AudioToolbox` - System sounds (vibration on scan)
- `PhotosUI` - Photo picker
- `UniformTypeIdentifiers` - File types (.json)
- `UIKit` - UIImage, UIColor, UIScreen (limited use)

### No External Dependencies
- All functionality uses native iOS frameworks
- No CocoaPods, SPM packages, or Carthage
- Keeps project simple and maintainable

## Build Configuration

**Deployment Target**: iOS 17.0+
**Xcode Version**: 15.0+
**Swift Version**: 5.9+

## Key Constraints & Requirements

1. **Offline First**: All data stored locally, no network required
2. **SwiftData**: Must use SwiftData (not Core Data)
3. **No External Deps**: Use only native frameworks
4. **Unique Card Numbers**: Enforced at model level
5. **Photo Storage**: Stored as Data arrays in SwiftData
6. **Brightness Control**: Only for barcode fullscreen
7. **Export Completeness**: JSON must include all data (photos as base64)

## Future AI Agent Guidelines

When making changes:
1. Always read relevant files first
2. Follow existing patterns strictly
3. Run SwiftLint after changes
4. Add/update tests for new features
5. Maintain consistency with architecture
6. Update this document for significant changes
7. Never commit or git push (per project instructions)
8. Test changes if possible
9. Be factual and concise in responses
10. Use modern iOS APIs (UIWindowScene.requestGeometryUpdate, not UIDevice.setValue)
11. Test on physical device when possible (make test-iphone)

## Quick Reference

**Root View**: CardListView
**Model**: Card (SwiftData)
**Services**: BarcodeService, ImportExportService (stateless enums)
**Main Features**: List/Grid view, Add/Edit/Delete, Import/Export, Barcode/QR display, Barcode/QR scanning
**Testing**: Unit tests (logic) + UI tests (flows)
**Linting**: SwiftLint (strict, no disabled rules)

---

Last updated: 2026-02-03 (Updated: Moved sensitive data to .env, added environment configuration docs)
