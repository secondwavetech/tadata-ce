# tadata.ai Community Edition

**Self-hosted AI data analysis platform for personal computers**

tadata.ai CE is a complete AI-powered data analysis platform that runs on your local machine using Docker. No Kubernetes knowledge required—just Docker and a few commands to get started.

## Features

- 🤖 **AI-Powered Analysis**: Leverages Claude for intelligent data insights
- 🔒 **Local & Private**: All data stays on your machine
- 📊 **Interactive Interface**: Modern React-based web UI
- ⚡ **Function Runtime**: Execute custom analysis functions in isolated environments
- 🗄️ **PostgreSQL Backend**: Robust data storage with vector support
- 🐳 **Docker-Based**: Simple deployment with Docker Compose

## Quick Start

### Prerequisites

- Docker Desktop or Docker Engine (20.10+)
- Docker Compose V2
- 4GB RAM minimum
- 10GB disk space

**Note**: You'll need an AI provider API key (Claude, OpenAI, Gemini, or AWS Bedrock) to use the platform, but this can be configured through the web UI after installation.

### One-Line Install

**macOS / Linux / WSL:**

```bash
curl -sSL https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.sh | bash
```

**Windows (PowerShell):**

```powershell
iex (irm https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.ps1)
```

This installs to `~/tadata-ce` (or `%USERPROFILE%\tadata-ce` on Windows) by default.

**Custom directory:**

```bash
# macOS / Linux / WSL
curl -sSL https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.sh | bash -s -- --dir=/path/to/install

# Windows (PowerShell)
iex "& { $(irm https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.ps1) } -InstallDir 'C:\path\to\install'"
```

**Specific version:**

```bash
# macOS / Linux / WSL
curl -sSL https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.sh | bash -s -- --version=v1.2.3

# Windows (PowerShell)
iex "& { $(irm https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.ps1) } -Version 'v1.2.3'"
```

This will:
- Download the installer from the `main` branch to `~/tadata-ce` (or custom directory via `--dir`)
- Guide you through interactive setup (API key, port, data directory)
- Pull Docker images (default: `latest` or specified version)
- Start all services

### Manual Installation

**macOS / Linux / WSL:**

```bash
# Clone the repository
git clone https://github.com/secondwavetech/tadata-ce.git
cd tadata-ce/deploy

# Run interactive setup (optionally pin version)
./setup.sh --version=v1.2.3

# Access the application
open http://localhost:3000
```

**Windows (PowerShell):**

```powershell
# Clone the repository
git clone https://github.com/secondwavetech/tadata-ce.git
cd tadata-ce\deploy

# Run interactive setup (optionally pin version)
.\setup.ps1 -Version v1.2.3

# Access the application
start http://localhost:3000
```

## Architecture

tadata.ai CE consists of five containerized services:

- **client** - React web interface (port 3000)
- **server** - NestJS API server (port 3001)
- **faas** - Function-as-a-Service runtime (port 8080)
- **function-executor** - Function execution service (port 3002)
- **db** - PostgreSQL 15 database (port 5432)

## Configuration

All configuration is managed through environment variables. The setup script will guide you through generating secure secrets and providing your API keys.

See [deploy/INSTALL.md](deploy/INSTALL.md) for detailed configuration options.

### Image tags and pinning

By default, application images use the `latest` tag:
- `ghcr.io/secondwavetech/tadata-server:${SERVER_IMAGE_TAG:-latest}`
- `ghcr.io/secondwavetech/tadata-client:${CLIENT_IMAGE_TAG:-latest}`
- `ghcr.io/secondwavetech/tadata-faas:${FAAS_IMAGE_TAG:-latest}`
- `ghcr.io/secondwavetech/tadata-function-executor:${FUNCTION_EXECUTOR_IMAGE_TAG:-latest}`
- Database is fixed to `postgres:15-alpine`.

To pin to a specific release, set tags in `deploy/.env`, for example:

```bash
SERVER_IMAGE_TAG=v1.2.0
CLIENT_IMAGE_TAG=v1.2.0
FAAS_IMAGE_TAG=v1.2.0
FUNCTION_EXECUTOR_IMAGE_TAG=v1.2.0
```

Then apply:

```bash
cd tadata-ce/deploy
docker-compose pull
docker-compose up -d
```

## Upgrading

### Using the upgrade script (recommended)

```bash
cd tadata-ce/deploy

# Upgrade to latest
./upgrade.sh

# Or upgrade to specific version
./upgrade.sh --version=v1.2.3
```

The upgrade script will:
1. Backup your database to `${DATA_DIR}/backups/`
2. Pull new images
3. Stop services
4. Start with new images (migrations run automatically)
5. Provide rollback instructions if needed

### Manual upgrade

```bash
cd tadata-ce/deploy
docker-compose pull
docker-compose up -d
```

## Troubleshooting

See the [Installation Guide](deploy/INSTALL.md#troubleshooting) for common issues and solutions.

## Data Storage

By default, data is stored in `${DATA_DIR}` (configurable during install, defaults to `./data`):
- `${DATA_DIR}/postgres` - Database files
- `${DATA_DIR}/functions` - Custom functions
- `${DATA_DIR}/conversation-files` - Conversation data
- `${DATA_DIR}/lancedb` - Vector database
- `${DATA_DIR}/backups` - Automatic upgrade backups

### Manual Backup

```bash
cd tadata-ce/deploy
source .env
tar czf tadata-backup-$(date +%Y%m%d).tar.gz "$DATA_DIR"
```

## Security

- All secrets are generated locally using cryptographically secure methods
- Services communicate via isolated Docker network
- No external authentication required for local deployment
- Your Anthropic API key is stored in `.env` (keep it secure)

## Support

- 📖 [Installation Guide](deploy/INSTALL.md)
- 🐛 [Issue Tracker](https://github.com/secondwavetech/tadata-ce/issues)
- 💬 [Discussions](https://github.com/secondwavetech/tadata-ce/discussions)

## License

[License information to be added]

## Contributing

Contributions are welcome! Please open an issue first to discuss proposed changes.

---

**Note**: This is the Community Edition for personal/local deployments. For production use cases, contact Second Wave for enterprise options.
