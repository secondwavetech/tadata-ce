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
- Anthropic API key ([get one here](https://console.anthropic.com/))

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.sh | bash
```

This installs from the `main` branch, cloning the repo to `~/tadata-ce` and running an interactive setup (`deploy/setup.sh`). By default, Docker images are pulled with the `latest` tag unless overridden in `deploy/.env`.

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/secondwavetech/tadata-ce.git
cd tadata-ce/deploy

# Run interactive setup
./setup.sh

# Access the application
open http://localhost:3000
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

```bash
cd tadata-ce/deploy
docker-compose pull
docker-compose up -d
```

If you have set image tags in `deploy/.env`, the pull will fetch those specific versions. Without overrides, it will pull the latest images.

## Troubleshooting

See the [Installation Guide](deploy/INSTALL.md#troubleshooting) for common issues and solutions.

## Data Backup

Your data is stored in Docker volumes. To back up:

```bash
cd tadata-ce/deploy
docker-compose down
docker run --rm -v tadata-ce_postgres-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/tadata-backup.tar.gz /data
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
