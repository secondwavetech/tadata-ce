# Release Notes

This directory contains release notes for each version of tadata.ai Community Edition.

## Quick Start

```bash
# 1. Create release notes from template
cp releases/v1.0.0.md releases/v1.1.0.md

# 2. Edit the new file with your release details
vim releases/v1.1.0.md

# 3. Publish to GitHub
./scripts/publish-release.sh v1.1.0
```

The script will automatically:
- Commit the release notes file
- Create a git tag
- Create a GitHub release with your notes

## Release File Format

Each file should be named `vX.Y.Z.md` and include:

```markdown
# vX.Y.Z - Release Title

**Release Date:** YYYY-MM-DD

## Overview
Brief description of the release

## What's Included
- Feature 1
- Feature 2

## Installation
Installation instructions or links

## Requirements
System requirements

## Known Issues
Any known issues or limitations

## What's Next
Future plans
```

## Workflow

1. **After pushing Docker images** to GHCR
2. **Create release notes** in `releases/vX.Y.Z.md`
3. **Run publish script**: `./scripts/publish-release.sh vX.Y.Z`
4. **Release goes live** on GitHub with proper notes

## Version Numbering

Follow semantic versioning:
- **v1.0.0** - Major release (breaking changes)
- **v1.1.0** - Minor release (new features)
- **v1.1.1** - Patch release (bug fixes)
