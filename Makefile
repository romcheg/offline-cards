.PHONY: help build test test-unit test-ui test-all test-iphone test-iphone-unit test-iphone-ui lint run run-iphone clean generate archive export-ipa release publish check-env generate-export-plist

# ANSI color codes
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# Configuration
SCHEME := OfflineCards
SIMULATOR := iPhone 17
PLATFORM := iOS Simulator

# Load environment variables from .env if it exists
-include .env
export

help: ## Show this help message
	@echo "$(CYAN)OfflineCards - iOS App Build Commands$(RESET)"
	@echo ""
	@echo "$(YELLOW)Setup:$(RESET)"
	@echo "  1. Copy .env-template to .env"
	@echo "  2. Fill in your DEVELOPMENT_TEAM and DEVICE_ID"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""

check-env: ## Verify .env file exists and has required variables
	@if [ ! -f .env ]; then \
		echo "$(RED)Error: .env file not found$(RESET)"; \
		echo "$(YELLOW)Copy .env-template to .env and fill in your values:$(RESET)"; \
		echo "  cp .env-template .env"; \
		exit 1; \
	fi
	@if [ -z "$(DEVELOPMENT_TEAM)" ] || [ "$(DEVELOPMENT_TEAM)" = "YOUR_TEAM_ID_HERE" ]; then \
		echo "$(RED)Error: DEVELOPMENT_TEAM not set in .env$(RESET)"; \
		exit 1; \
	fi

check-device-env: check-env ## Verify DEVICE_ID is set for physical device targets
	@if [ -z "$(DEVICE_ID)" ] || [ "$(DEVICE_ID)" = "YOUR_DEVICE_UDID_HERE" ]; then \
		echo "$(RED)Error: DEVICE_ID not set in .env$(RESET)"; \
		echo "$(YELLOW)Find your device UDID with: xcrun xctrace list devices$(RESET)"; \
		exit 1; \
	fi

generate-export-plist: check-env ## Generate ExportOptions.plist from template
	@echo "$(YELLOW)Generating ExportOptions.plist...$(RESET)"
	@sed 's/{{DEVELOPMENT_TEAM}}/$(DEVELOPMENT_TEAM)/g' altstore/ExportOptions.plist.template > altstore/ExportOptions.plist
	@echo "$(GREEN)✓ ExportOptions.plist generated$(RESET)"

generate: check-env ## Generate Xcode project from project.yml
	@echo "$(YELLOW)Generating Xcode project...$(RESET)"
	xcodegen generate

build: ## Build the app
	@echo "$(YELLOW)Building $(SCHEME)...$(RESET)"
	xcodebuild build \
		-scheme $(SCHEME) \
		-destination 'platform=$(PLATFORM),name=$(SIMULATOR)' \
		-quiet

test-unit: ## Run unit tests only
	@echo "$(YELLOW)Running unit tests...$(RESET)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=$(PLATFORM),name=$(SIMULATOR)' \
		-only-testing:OfflineCardsTests \
		| grep -E "(Test Case.*passed|Test Case.*failed|Test Suite.*tests|error:)" || true

test-ui: ## Run UI tests only
	@echo "$(YELLOW)Running UI tests...$(RESET)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=$(PLATFORM),name=$(SIMULATOR)' \
		-only-testing:OfflineCardsUITests \
		| grep -E "(Test Case.*passed|Test Case.*failed|Test Suite.*tests|error:)" || true

test: test-all ## Run all tests (alias for test-all)

test-all: ## Run all tests (unit + UI)
	@echo "$(YELLOW)Running all tests...$(RESET)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=$(PLATFORM),name=$(SIMULATOR)'

test-iphone-unit: check-device-env ## Run unit tests on connected iPhone
	@echo "$(YELLOW)Running unit tests on iPhone...$(RESET)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=iOS,id=$(DEVICE_ID)' \
		-only-testing:OfflineCardsTests \
		-allowProvisioningUpdates

test-iphone-ui: check-device-env ## Run UI tests on connected iPhone
	@echo "$(YELLOW)Running UI tests on iPhone...$(RESET)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=iOS,id=$(DEVICE_ID)' \
		-only-testing:OfflineCardsUITests \
		-allowProvisioningUpdates

test-iphone: check-device-env ## Run all tests on connected iPhone
	@echo "$(YELLOW)Running all tests on iPhone...$(RESET)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=iOS,id=$(DEVICE_ID)' \
		-allowProvisioningUpdates

lint: ## Run SwiftLint
	@echo "$(YELLOW)Running SwiftLint...$(RESET)"
	swiftlint

run: build ## Build and run the app in simulator
	@echo "$(YELLOW)Opening Simulator...$(RESET)"
	@open -a Simulator
	@echo "$(YELLOW)Waiting for Simulator to start...$(RESET)"
	@sleep 2
	@xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	@echo "$(YELLOW)Installing and launching app...$(RESET)"
	@xcrun simctl install "$(SIMULATOR)" \
		$$(find ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*/Build/Products/Debug-iphonesimulator -name "$(SCHEME).app" | head -1)
	@xcrun simctl launch "$(SIMULATOR)" com.offlinecards.OfflineCards
	@echo "$(GREEN)✓ App launched in Simulator$(RESET)"

run-iphone: check-device-env ## Build and run the app on connected iPhone
	@echo "$(YELLOW)Building for iPhone...$(RESET)"
	xcodebuild build \
		-scheme $(SCHEME) \
		-destination 'platform=iOS,id=$(DEVICE_ID)' \
		-allowProvisioningUpdates \
		-quiet
	@echo "$(YELLOW)Installing app on iPhone...$(RESET)"
	@xcrun devicectl device install app \
		--device $(DEVICE_ID) \
		$$(find ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*/Build/Products/Debug-iphoneos -name "$(SCHEME).app" | head -1)
	@echo "$(GREEN)✓ App installed on iPhone$(RESET)"
	@echo "$(YELLOW)Launch the app manually on your iPhone$(RESET)"

clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(RESET)"
	xcodebuild clean -scheme $(SCHEME)
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*

verify: lint test-all ## Run linting and all tests
	@echo "$(GREEN)✓ All checks passed!$(RESET)"

# AltStore Distribution
ARCHIVE_PATH := build/$(SCHEME).xcarchive
EXPORT_PATH := build/export
IPA_PATH := $(EXPORT_PATH)/$(SCHEME).ipa

archive: check-env ## Archive the app for distribution
	@echo "$(YELLOW)Archiving $(SCHEME)...$(RESET)"
	@mkdir -p build
	xcodebuild archive \
		-scheme $(SCHEME) \
		-destination 'generic/platform=iOS' \
		-archivePath $(ARCHIVE_PATH) \
		-allowProvisioningUpdates \
		CODE_SIGN_STYLE=Automatic \
		DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM)
	@echo "$(GREEN)✓ Archive created at $(ARCHIVE_PATH)$(RESET)"

export-ipa: archive generate-export-plist ## Export IPA for AltStore distribution
	@echo "$(YELLOW)Exporting IPA...$(RESET)"
	@mkdir -p $(EXPORT_PATH)
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist altstore/ExportOptions.plist \
		-allowProvisioningUpdates
	@echo "$(GREEN)✓ IPA exported to $(IPA_PATH)$(RESET)"

release: export-ipa ## Prepare release artifacts for AltStore
	@echo "$(YELLOW)Preparing release artifacts...$(RESET)"
	@mkdir -p build/release
	@cp $(IPA_PATH) build/release/OfflineCards.ipa
	@cp OfflineCards/OfflineCards/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024x1024@1x.png build/release/icon.png
	@VERSION=$$(grep 'MARKETING_VERSION' project.yml | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/'); \
	BUILD=$$(grep 'CURRENT_PROJECT_VERSION' project.yml | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/'); \
	SIZE=$$(stat -f%z build/release/OfflineCards.ipa); \
	DATE=$$(date +%Y-%m-%d); \
	echo "$(CYAN)Release Info:$(RESET)"; \
	echo "  Version: $$VERSION ($$BUILD)"; \
	echo "  Size: $$SIZE bytes"; \
	echo "  Date: $$DATE"; \
	echo ""; \
	echo "$(CYAN)Files ready in build/release/:$(RESET)"; \
	ls -la build/release/
	@echo ""
	@echo "$(CYAN)Next steps:$(RESET)"
	@echo "  1. Create a GitHub release tagged v$$VERSION"
	@echo "  2. Upload build/release/OfflineCards.ipa"
	@echo "  3. Upload build/release/icon.png"
	@echo "  4. Update altstore/source.json version and size if needed"
	@echo ""
	@echo "$(CYAN)Friends add this source URL in AltStore PAL:$(RESET)"
	@echo "  https://romcheg.github.io/offline-cards/source.json"

publish: ## Publish release to GitHub (requires VERSION=x.y.z)
ifndef VERSION
	$(error VERSION is required. Usage: make publish VERSION=1.0.0)
endif
	@echo "$(YELLOW)Publishing version $(VERSION)...$(RESET)"
	@# Build release artifacts
	@$(MAKE) release
	@# Calculate IPA size
	@SIZE=$$(stat -f%z build/release/OfflineCards.ipa); \
	DATE=$$(date +%Y-%m-%d); \
	echo "$(YELLOW)Updating altstore/source.json...$(RESET)"; \
	jq --arg ver "$(VERSION)" --arg size "$$SIZE" --arg date "$$DATE" \
		'.apps[0].versions[0].version = $$ver | .apps[0].versions[0].size = ($$size | tonumber) | .apps[0].versions[0].date = $$date' \
		altstore/source.json > altstore/source.json.tmp && mv altstore/source.json.tmp altstore/source.json
	@echo "$(GREEN)✓ source.json updated$(RESET)"
	@# Commit source.json changes (docs/source.json is a symlink)
	@echo "$(YELLOW)Committing source.json...$(RESET)"
	@git add altstore/source.json
	@git commit -m "chore: update source.json for v$(VERSION)" || echo "$(YELLOW)No changes to commit$(RESET)"
	@git push origin master
	@echo "$(GREEN)✓ Changes pushed$(RESET)"
	@# Create GitHub release with conventional commit notes
	@echo "$(YELLOW)Creating GitHub release v$(VERSION)...$(RESET)"
	@gh release create v$(VERSION) \
		--title "v$(VERSION)" \
		--generate-notes \
		build/release/OfflineCards.ipa \
		build/release/icon.png
	@echo ""
	@echo "$(GREEN)✓ Release v$(VERSION) published!$(RESET)"
	@echo ""
	@echo "$(CYAN)Release URL:$(RESET)"
	@echo "  https://github.com/romcheg/offline-cards/releases/tag/v$(VERSION)"
	@echo ""
	@echo "$(CYAN)AltStore source URL:$(RESET)"
	@echo "  https://romcheg.github.io/offline-cards/source.json"
