# tadata.ai Community Edition - Installation Guide

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [Quick Install](#quick-install)
  - [Manual Installation](#manual-installation)
- [Configuration](#configuration)
- [Starting and Stopping](#starting-and-stopping)
- [Troubleshooting](#troubleshooting)
- [Upgrading](#upgrading)
- [Backup and Restore](#backup-and-restore)
- [Uninstalling](#uninstalling)

---

## System Requirements

### Minimum Requirements

- **Operating System**: macOS 10.15+, Ubuntu 20.04+, Windows 10/11 (native PowerShell or WSL2)
- **Docker**: Docker Desktop 20.10+ or Docker Engine 20.10+
- **Docker Compose**: V2 (included with Docker Desktop)
- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 10GB minimum for images and data
- **CPU**: 2 cores minimum, 4+ recommended

### Prerequisites

1. **Docker Desktop** (macOS/Windows) or **Docker Engine** (Linux)
   - Download: https://www.docker.com/products/docker-desktop

2. **AI Provider API Key** (optional - can be configured after installation)
   - You can configure AI settings through the web UI after first login
   - Supports: Claude (Anthropic), OpenAI, Google Gemini, or AWS Bedrock
   - To get an API key:
     - Claude: https://console.anthropic.com/
     - OpenAI: https://platform.openai.com/
     - Gemini: https://ai.google.dev/
     - AWS Bedrock: https://aws.amazon.com/bedrock/

---

## Installation Methods

### Quick Install

#### macOS / Linux / WSL

Run this single command to download and install tadata.ai:

```bash
curl -sSL https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.sh | bash
```

This will install tadata.ai to `~/tadata-ce` by default.

#### Windows (PowerShell)

Run this command in PowerShell:

```powershell
iex (irm https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.ps1)
```

This will install tadata.ai to `%USERPROFILE%\tadata-ce` by default.

**Install to custom directory:**

```bash
# macOS / Linux / WSL
curl -sSL https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.sh | bash -s -- --dir=/path/to/install

# Windows (PowerShell)
iex "& { $(irm https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.ps1) } -InstallDir 'C:\path\to\install'"
```

**Install specific version:**

```bash
# macOS / Linux / WSL
curl -sSL https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.sh | bash -s -- --version=v1.2.3

# Windows (PowerShell)
iex "& { $(irm https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.ps1) } -Version 'v1.2.3'"
```

**Combine options:**

```bash
# macOS / Linux / WSL
curl -sSL https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.sh | bash -s -- --dir=/path/to/install --version=v1.2.3

# Windows (PowerShell)
iex "& { $(irm https://raw.githubusercontent.com/secondwavetech/tadata-ce/main/deploy/install.ps1) } -InstallDir 'C:\path\to\install' -Version 'v1.2.3'"
```

This will:
- Clone the repository to the specified directory (default: `~/tadata-ce`)
- Check prerequisites
- Guide you through configuration (port, data directory)
- Pull images (specified version or `latest`)
- Start all services

#### What the installer does

The script fetches the `main` branch, then runs `deploy/setup.sh`, which:
- Prompts for:
  - Frontend port (default: 3000)
  - Data directory (default: `./data`)
- Generates and injects secure secrets into `deploy/.env`
- Sets image version tags (if `--version` specified)
- Creates data directory with proper permissions
- Detects existing database and offers to remove it for a clean install
- Pulls Docker images
- Starts all services with `docker-compose up -d`
- Verifies health checks and prints the access URL
- Creates convenience symlinks: `logs.sh`, `stop.sh`, `restart.sh`, `upgrade.sh`, `uninstall.sh`

#### After installation

1. Sign up for your account (first user)
2. Configure AI settings:
   - Go to **Organization Settings → System LLM** tab
   - Select your LLM service (Claude, OpenAI, Gemini, or AWS Bedrock)
   - Enter your API key
   - Save configuration

### Manual Installation

For more control over the installation:

#### macOS / Linux / WSL

1. **Clone the repository**

```bash
git clone https://github.com/secondwavetech/tadata-ce.git
cd tadata-ce/deploy
```

2. **Check prerequisites**

```bash
./scripts/check-prerequisites.sh
```

3. **Run setup script**

```bash
./setup.sh

# Or with specific version
./setup.sh --version=v1.2.3
```

#### Windows (PowerShell)

1. **Clone the repository**

```powershell
git clone https://github.com/secondwavetech/tadata-ce.git
cd tadata-ce\deploy
```

2. **Run setup script**

```powershell
.\setup.ps1

# Or with specific version
.\setup.ps1 -Version v1.2.3
```

This will:
- Prompt for configuration (port, data directory)
- Generate secrets
- Create `.env` file

4. **Access the application**

Open http://localhost:3000 in your browser

5. **Configure AI settings**

- Sign up for your account (first user)
- Go to **Organization Settings → System LLM** tab
- Select your LLM service and enter your API key
- Save configuration

---

## Configuration

### Environment Variables

All configuration is managed through the `.env` file in the `deploy/` directory.

#### Auto-Generated Variables

```bash
# Security (auto-generated, keep secure)
JWT_SECRET=<base64-encoded-32-bytes>
ENCRYPTION_KEY=<hex-encoded-32-bytes>

# Database
POSTGRES_PASSWORD=<auto-generated>
POSTGRES_TADATA_PASSWORD=<auto-generated>
```

#### Optional Variables

```bash
# AI Provider API Key (optional - can be configured via web UI)
# Configure through Organization Settings → System LLM tab after first login
ANTHROPIC_API_KEY=
```

```bash
# Custom port (if default conflicts)
CLIENT_PORT=3000

# Data directory (set during install)
DATA_DIR=./data

# Image versions (default: latest)
CLIENT_IMAGE_TAG=latest
SERVER_IMAGE_TAG=latest
FAAS_IMAGE_TAG=latest
FUNCTION_EXECUTOR_IMAGE_TAG=latest
```

Note: Only the client port is exposed externally. Other services communicate on an internal Docker network.

### Port Conflicts

If any default ports are already in use, modify them in `.env`:

```bash
# Example: Move client to port 8080
CLIENT_PORT=8080
```

Then restart:

```bash
docker-compose down
docker-compose up -d
```

---

## Starting and Stopping

### Using Convenience Scripts (Recommended)

```bash
# View logs
./logs.sh
./logs.sh server  # specific service

# Stop services (preserves data)
./stop.sh

# Restart services
./restart.sh

# Upgrade to latest/specific version
./upgrade.sh
./upgrade.sh --version=v1.2.3

# Uninstall (interactive)
./uninstall.sh
```

### Using Docker Compose Directly

```bash
# View status
docker-compose ps

# View logs
docker-compose logs -f
docker-compose logs -f server  # specific service

# Stop services
docker-compose stop

# Restart services
docker-compose restart

# Stop and remove containers (preserves data)
docker-compose down

# Start services again
docker-compose up -d
```

---

## Troubleshooting

### Services Won't Start

**Check Docker is running:**

```bash
docker info
```

If this fails, start Docker Desktop or the Docker daemon.

**Check for port conflicts:**

```bash
docker-compose logs | grep -i "bind"
```

If you see port binding errors, change the conflicting ports in `.env`.

**Check available resources:**

Docker Desktop → Preferences → Resources

Ensure at least 4GB RAM is allocated.

### Database Connection Errors

**Check database container:**

```bash
docker-compose logs db
```

**Verify database credentials in `.env`:**

```bash
grep POSTGRES .env
```

**Restart the database:**

```bash
docker-compose restart db
```

### Server Health Check Fails

**Wait for startup:**

Services can take 30-60 seconds to fully start. Wait and check again.

**Check server logs:**

```bash
docker-compose logs server
```

**Verify all services are running:**

```bash
docker-compose ps
```

All services should show "Up" status.

### Ports and Network

Default ports:
- Client: `CLIENT_PORT` (default: 3000) - **only exposed port**
- Server: 3001 (internal only)
- Function Executor: 3002 (internal only)
- FaaS: 3000 (internal only)
- Postgres: 5432 (internal only)

Each installation gets its own Docker network (auto-named by Compose based on directory).

### Data Directory Issues

By default, data is stored in bind mounts at `${DATA_DIR}` (set during install):

```bash
# Check your data directory
cd ~/tadata-ce/deploy
source .env
echo $DATA_DIR
ls -la "$DATA_DIR"
```

Multiple installations can coexist if they use different data directories and ports.

### Cannot Access http://localhost:3000

**Check client container:**

```bash
docker-compose logs client
```

**Verify port mapping:**

```bash
docker ps | grep tadata-client
```

Look for `0.0.0.0:3000->80/tcp`

**Try the alternate URL:**

```bash
curl http://localhost:3000
```

### Images Won't Pull

**Check internet connection:**

```bash
docker pull ghcr.io/secondwavetech/tadata-server:latest
```

**Check Docker Hub/GHCR status:**

Visit https://www.githubstatus.com/

**Use specific image tag:**

In `.env`, specify a known working version:

```bash
SERVER_IMAGE_TAG=v1.0.0
```

### Reset Database For A Clean Install

If you want to start fresh:

```bash
cd ~/tadata-ce/deploy
docker-compose down
source .env
rm -rf "$DATA_DIR/postgres"
docker-compose up -d
```

### Memory or Performance Issues

**Check Docker resource usage:**

```bash
docker stats
```

**Increase Docker resources:**

Docker Desktop → Preferences → Resources → Increase Memory to 8GB

**Reduce service memory:**

Edit `docker-compose.yml` and add memory limits:

```yaml
services:
  server:
    mem_limit: 1g
```

---

## Upgrading

### Using the Upgrade Script (Recommended)

The upgrade script automatically backs up your database before upgrading:

```bash
cd ~/tadata-ce/deploy

# Upgrade to latest
./upgrade.sh

# Upgrade to specific version
./upgrade.sh --version=v1.2.3
```

**What it does:**
1. Creates database backup in `${DATA_DIR}/backups/tadata_backup_YYYYMMDD_HHMMSS.sql`
2. Pulls new images (specified version or current `.env` tags)
3. Stops services
4. Starts with new images (migrations run automatically)
5. Waits for health checks
6. Shows rollback instructions if anything fails

### Manual Upgrade

If you prefer manual control:

```bash
cd ~/tadata-ce/deploy

# Backup database first
source .env
docker-compose exec -T db pg_dump -U postgres tadata > backup.sql

# Update version tags in .env (optional)
sed -i '' "s|SERVER_IMAGE_TAG=.*|SERVER_IMAGE_TAG=v1.2.3|" .env

# Pull and restart
docker-compose pull
docker-compose up -d

# Check logs
docker-compose logs -f
```

---

## Backup and Restore

### Automatic Backups

The `upgrade.sh` script automatically creates database backups before upgrading.

Backups are stored in `${DATA_DIR}/backups/`:

```bash
ls -lh "$DATA_DIR/backups/"
```

### Manual Backup

**1. Stop services:**

```bash
docker-compose down
```

**2. Backup data directory:**

```bash
source .env
tar czf tadata-backup-$(date +%Y%m%d).tar.gz "$DATA_DIR"
```

**3. Backup configuration:**

```bash
cp .env .env.backup-$(date +%Y%m%d)
```

**4. Restart services:**

```bash
docker-compose up -d
```

### Database-Only Backup (while running)

```bash
source .env
docker-compose exec -T db pg_dump -U postgres tadata > backup-$(date +%Y%m%d).sql
```

### Restore from Full Backup

**1. Stop services:**

```bash
docker-compose down
```

**2. Restore data directory:**

```bash
source .env
rm -rf "$DATA_DIR"
tar xzf tadata-backup-YYYYMMDD.tar.gz
```

**3. Restore configuration:**

```bash
cp .env.backup-YYYYMMDD .env
```

**4. Start services:**

```bash
docker-compose up -d
```

### Restore Database Only

```bash
# Stop services
docker-compose down

# Remove old database
source .env
rm -rf "$DATA_DIR/postgres"

# Start only database
docker-compose up -d db

# Wait for database to be ready
sleep 10

# Restore from SQL dump
docker-compose exec -T db psql -U postgres -d tadata < backup-YYYYMMDD.sql

# Start all services
docker-compose up -d
```

---

## Uninstalling

### Using the Uninstall Script (Recommended)

```bash
cd ~/tadata-ce/deploy
./uninstall.sh
```

This will:
- Stop and remove all containers
- Remove data directory (if configured with bind mounts)
- Optionally remove the installation directory

### Manual Uninstall

**Complete removal (including data):**

```bash
cd ~/tadata-ce/deploy

# Stop and remove containers
docker-compose down

# Remove data directory
source .env
rm -rf "$DATA_DIR"

# Remove images (optional)
docker rmi ghcr.io/secondwavetech/tadata-client:latest
docker rmi ghcr.io/secondwavetech/tadata-server:latest
docker rmi ghcr.io/secondwavetech/tadata-faas:latest
docker rmi ghcr.io/secondwavetech/tadata-function-executor:latest

# Remove installation directory
cd ~
rm -rf tadata-ce
```

**Keep data, remove application:**

```bash
cd ~/tadata-ce/deploy

# Stop and remove containers
docker-compose down

# Note your data directory location
source .env
echo "Data preserved at: $DATA_DIR"

# Remove installation directory
cd ~
rm -rf tadata-ce
```

---

## Getting Help

- **Documentation**: https://github.com/secondwavetech/tadata-ce
- **Issues**: https://github.com/secondwavetech/tadata-ce/issues
- **Discussions**: https://github.com/secondwavetech/tadata-ce/discussions

For production deployments or enterprise support, contact Second Wave.
