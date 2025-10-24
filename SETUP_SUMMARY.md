# tadata-ce Setup Summary

## ✅ What Was Created

### GitHub Repository
- **URL**: https://github.com/secondwavetech/tadata-ce
- **Type**: Public
- **Purpose**: Deployment package for self-hosted tadata.ai Community Edition

### Repository Contents

```
tadata-ce/
├── README.md                           # Main project documentation
├── .gitignore                          # Git ignore rules
├── deploy/
│   ├── docker-compose.yml             # Production Docker Compose config
│   ├── .env.template                  # Environment variable template
│   ├── setup.sh                       # Interactive setup script
│   ├── install.sh                     # One-line installer
│   ├── INSTALL.md                     # Comprehensive installation guide
│   └── scripts/
│       ├── check-prerequisites.sh     # Prerequisites checker
│       ├── generate-secrets.sh        # Secret generator
│       └── verify-installation.sh     # Installation verifier
```

### Image Push Script (in binarycrush repo)
- **Location**: `~/projects/binarycrush/scripts/push-to-ghcr.sh`
- **Purpose**: Copy Docker images from Harbor to GitHub Container Registry

## 🚀 Next Steps

### 1. Test the Repository Locally

```bash
# Clone and test
cd ~/test
git clone https://github.com/secondwavetech/tadata-ce.git
cd tadata-ce/deploy
./setup.sh
```

### 2. Push Your First Release Images

When you have a tagged release in GitLab (e.g., `v1.0.0`):

```bash
# Login to registries (one-time setup)
docker login harbor.secondwavetech.com
docker login ghcr.io -u ckumabe
# Use GitHub Personal Access Token: https://github.com/settings/tokens/new?scopes=write:packages

# Push images to GHCR
cd ~/projects/binarycrush
./scripts/push-to-ghcr.sh v1.0.0
```

This will push:
- `ghcr.io/secondwavetech/tadata-client:v1.0.0`
- `ghcr.io/secondwavetech/tadata-server:v1.0.0`
- `ghcr.io/secondwavetech/tadata-faas:v1.0.0`
- `ghcr.io/secondwavetech/tadata-function-executor:v1.0.0`

### 3. Make Packages Public (First Time Only)

After pushing images, visit:
- https://github.com/orgs/secondwavetech/packages

For each package:
1. Click the package name
2. Go to "Package settings"
3. Change visibility to "Public"

### 4. Tag and Release

```bash
cd ~/projects/tadata-ce
git tag v1.0.0
git push origin v1.0.0

# Create GitHub release
gh release create v1.0.0 \
  --title "tadata.ai CE v1.0.0" \
  --notes "First public release" \
  --repo secondwavetech/tadata-ce
```

## 📝 Important Notes

### Image Architecture
- Current images are **linux/amd64** only
- Works on all platforms via Docker Desktop:
  - Mac (Intel): Native
  - Mac (M-series): Emulation
  - Windows: WSL2
  - Linux: Native

### Client Image Configuration
The client image needs to be built **without Auth0** for the CE version. The current GitLab CI builds it with Auth0 enabled. You'll need to either:

1. **Option A**: Build a separate CE version locally:
   ```bash
   cd ~/projects/binarycrush/client
   docker build \
     --build-arg VITE_AUTH_TYPE="local" \
     --build-arg VITE_API_BASE_URL="http://localhost:3001" \
     -t ghcr.io/secondwavetech/tadata-client:v1.0.0 .
   docker push ghcr.io/secondwavetech/tadata-client:v1.0.0
   ```

2. **Option B**: Add a CE build job to GitLab CI

### Environment Variables
The CE version uses simplified configuration:
- No Auth0 required
- Local authentication only
- Simplified networking (all services on localhost)

## 🔗 Links

- **Repository**: https://github.com/secondwavetech/tadata-ce
- **Packages**: https://github.com/orgs/secondwavetech/packages
- **Source Code**: Internal GitLab (binarycrush)
- **Harbor Registry**: https://harbor.secondwavetech.com

## 📞 Questions?

If you need to modify the deployment:
- Update files in `~/projects/tadata-ce/deploy/`
- Commit and push to GitHub
- Test locally before releasing
