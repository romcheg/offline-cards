#!/bin/bash
set -e

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

echo -e "${CYAN}=== Offline Cards Release Script ===${RESET}"

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: gh CLI not installed. Install with: brew install gh${RESET}"
    exit 1
fi

# Check gh auth
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub. Run: gh auth login${RESET}"
    exit 1
fi

# Get version from project.yml
VERSION=$(grep 'MARKETING_VERSION' project.yml | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
BUILD=$(grep 'CURRENT_PROJECT_VERSION' project.yml | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
TAG="v${VERSION}"

echo -e "${YELLOW}Version: ${VERSION} (build ${BUILD})${RESET}"
echo -e "${YELLOW}Tag: ${TAG}${RESET}"
echo ""

# Check if tag already exists
if git tag -l | grep -q "^${TAG}$"; then
    echo -e "${RED}Error: Tag ${TAG} already exists. Update MARKETING_VERSION in project.yml${RESET}"
    exit 1
fi

# Build release artifacts
echo -e "${YELLOW}Building release artifacts...${RESET}"
make release

# Get IPA size for source.json
IPA_SIZE=$(stat -f%z build/release/OfflineCards.ipa)
DATE=$(date +%Y-%m-%d)

# Update source.json with new version info
echo -e "${YELLOW}Updating altstore/source.json...${RESET}"
# Create a temporary file with updated version info
python3 << EOF
import json

with open('altstore/source.json', 'r') as f:
    source = json.load(f)

# Update the latest version
source['apps'][0]['versions'][0]['version'] = '${VERSION}'
source['apps'][0]['versions'][0]['date'] = '${DATE}'
source['apps'][0]['versions'][0]['size'] = ${IPA_SIZE}

with open('altstore/source.json', 'w') as f:
    json.dump(source, f, indent=2)

print('source.json updated')
EOF

# Show what will be released
echo ""
echo -e "${CYAN}Release contents:${RESET}"
ls -la build/release/
echo ""
echo -e "${CYAN}IPA size: ${IPA_SIZE} bytes${RESET}"

# Confirm release
echo ""
read -p "Create GitHub release ${TAG}? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Aborted.${RESET}"
    exit 0
fi

# Create git tag
echo -e "${YELLOW}Creating git tag ${TAG}...${RESET}"
git tag -a "${TAG}" -m "Release ${VERSION}"

# Push tag
echo -e "${YELLOW}Pushing tag to origin...${RESET}"
git push origin "${TAG}"

# Create GitHub release
echo -e "${YELLOW}Creating GitHub release...${RESET}"
gh release create "${TAG}" \
    build/release/OfflineCards.ipa \
    build/release/icon.png \
    --title "Offline Cards ${VERSION}" \
    --notes "## Offline Cards ${VERSION}

### Installation (AltStore PAL)
1. Install [AltStore PAL](https://altstore.io) on your iPhone (EU only)
2. Open AltStore PAL → Sources → Add Source
3. Enter: \`https://raw.githubusercontent.com/romcheg/offline-cards/master/altstore/source.json\`
4. Find 'Offline Cards' and tap Install

### Changes
- See commit history for changes in this release
"

echo ""
echo -e "${GREEN}✓ Release ${TAG} created successfully!${RESET}"
echo ""
echo -e "${CYAN}Source URL for friends:${RESET}"
echo "https://raw.githubusercontent.com/romcheg/offline-cards/master/altstore/source.json"
echo ""
echo -e "${YELLOW}Don't forget to commit the updated altstore/source.json!${RESET}"
