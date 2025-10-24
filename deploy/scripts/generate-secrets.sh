#!/usr/bin/env bash

# Generate cryptographically secure secrets

# JWT Secret (32-byte base64)
JWT_SECRET=$(openssl rand -base64 32)

# Encryption Key (32-byte hex)
ENCRYPTION_KEY=$(openssl rand -hex 32)

# PostgreSQL passwords
POSTGRES_PASSWORD=$(openssl rand -base64 24)
POSTGRES_TADATA_PASSWORD=$(openssl rand -base64 24)

# Save to temporary file for setup script to use
cat > /tmp/tadata-secrets.env << EOF
JWT_SECRET=$JWT_SECRET
ENCRYPTION_KEY=$ENCRYPTION_KEY
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_TADATA_PASSWORD=$POSTGRES_TADATA_PASSWORD
EOF

echo "Secrets generated successfully"
