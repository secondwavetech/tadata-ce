#!/usr/bin/env bash
set -e

# Script to publish a GitHub release from a release notes file
# Usage: ./scripts/publish-release.sh v1.0.0

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Error: No version specified"
  echo "Usage: ./scripts/publish-release.sh v1.0.0"
  exit 1
fi

RELEASE_FILE="releases/${VERSION}.md"

if [ ! -f "$RELEASE_FILE" ]; then
  echo "❌ Error: Release notes file not found: $RELEASE_FILE"
  echo ""
  echo "Create the file first with release notes, then run this script."
  exit 1
fi

echo "================================================"
echo "Publishing Release: $VERSION"
echo "================================================"
echo ""

# Extract title from release notes (first line after # header)
TITLE=$(grep -m 1 "^# " "$RELEASE_FILE" | sed 's/^# //')

if [ -z "$TITLE" ]; then
  TITLE="tadata.ai CE $VERSION"
fi

echo "📝 Title: $TITLE"
echo "📄 Release notes: $RELEASE_FILE"
echo ""

# Read release notes (skip the title line)
NOTES=$(tail -n +2 "$RELEASE_FILE")

# Commit release notes if not already committed
if ! git diff --quiet HEAD "$RELEASE_FILE" 2>/dev/null || ! git ls-files --error-unmatch "$RELEASE_FILE" >/dev/null 2>&1; then
  echo "📦 Committing release notes..."
  git add "$RELEASE_FILE"
  git commit -m "Add release notes for $VERSION"
  git push
  echo ""
fi

# Create git tag
echo "🏷️  Creating git tag..."
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "⚠️  Tag $VERSION already exists"
else
  git tag "$VERSION"
  git push origin "$VERSION"
  echo "✓ Tag created"
fi
echo ""

# Create GitHub release
echo "🚀 Creating GitHub release..."
gh release create "$VERSION" \
  --title "$TITLE" \
  --notes-file "$RELEASE_FILE" \
  --repo secondwavetech/tadata-ce

echo ""
echo "================================================"
echo "✅ Release published successfully!"
echo "================================================"
echo ""
echo "View at: https://github.com/secondwavetech/tadata-ce/releases/tag/$VERSION"
