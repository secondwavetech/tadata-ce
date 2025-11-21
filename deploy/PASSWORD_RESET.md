# Password Reset Guide

This guide explains how to reset user passwords in tadata.ai Community Edition.

## Overview

Community Edition uses local authentication (username/password). If you forget your password, you can reset it using the provided scripts that directly update the database.

## Prerequisites

- tadata.ai must be running (`docker compose up -d`)
- Docker must be installed and running
- You must have access to the server/machine running tadata.ai

## Quick Start

### Linux / macOS

```bash
cd deploy
./reset-password.sh
```

### Windows (PowerShell)

```powershell
cd deploy
.\reset-password.ps1
```

## Step-by-Step Instructions

### 1. Navigate to the Deploy Directory

```bash
cd /path/to/tadata-ce/deploy
```

### 2. Run the Password Reset Script

**On Linux/macOS:**
```bash
./reset-password.sh
```

**On Windows:**
```powershell
.\reset-password.ps1
```

### 3. Follow the Prompts

The script will ask for:

1. **User email**: The email address of the account to reset
   ```
   Enter the email address of the user to reset: admin@example.com
   ```

2. **New password**: Your new password (minimum 8 characters)
   ```
   Enter new password: ********
   Confirm new password: ********
   ```

### 4. Verify Success

You should see:
```
╔════════════════════════════════════════════════════════════╗
║                  Password Reset Successful!                ║
╚════════════════════════════════════════════════════════════╝

✓ Password has been reset for: admin@example.com
✓ You can now log in with your new password
```

### 5. Log In

Visit your tadata.ai instance (usually `http://localhost:3000`) and log in with your new password.

## What the Scripts Do

The password reset scripts:

1. ✅ Verify tadata.ai is running
2. ✅ Check that the user exists
3. ✅ Hash your new password using bcrypt
4. ✅ Update the database with the new password
5. ✅ Clear any existing password reset tokens

**Security Note**: Passwords are hashed using bcrypt with 10 salt rounds, the same method used by the application.

## Troubleshooting

### "Error: Docker is not running"
- **Cause**: Docker Desktop is not running
- **Solution**: Start Docker Desktop and try again

### "Error: Could not find database container"
- **Cause**: tadata.ai is not running
- **Solution**:
  ```bash
  cd deploy
  docker compose up -d
  ```

### "Error: No user found with email"
- **Cause**: The email address doesn't exist in the database
- **Solution**: Check the email address for typos. Remember, email is case-sensitive in some databases.

### "Error: .env file not found"
- **Cause**: Running the script from the wrong directory
- **Solution**: Make sure you're in the `deploy` directory

### Permission Denied (Linux/macOS)
- **Cause**: Script is not executable
- **Solution**:
  ```bash
  chmod +x reset-password.sh
  ```

## Alternative: Direct Database Access

If the scripts don't work, you can reset the password manually using PostgreSQL:

### Step 1: Generate Password Hash

Use any bcrypt tool or Node.js:

```bash
# Using Node.js (if installed)
node -e "const bcrypt = require('bcrypt'); bcrypt.hash('your-new-password', 10).then(console.log)"
```

This will output something like:
```
$2b$10$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Step 2: Connect to Database

```bash
# Find your database container
docker ps | grep postgres

# Connect to PostgreSQL
docker exec -it <container-name> psql -U postgres -d tadata
```

### Step 3: Update Password

```sql
-- View users
SELECT id, email FROM "user";

-- Update password (replace with your hash and email)
UPDATE "user"
SET password = '$2b$10$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    password_reset_token = NULL
WHERE email = 'admin@example.com';

-- Verify update
SELECT email, password IS NOT NULL as has_password FROM "user";

-- Exit
\q
```

## Security Best Practices

1. **Use strong passwords**: Minimum 8 characters, include uppercase, lowercase, numbers, and symbols
2. **Don't share passwords**: Each user should have their own account
3. **Change default passwords**: If you're using a default password from setup, change it immediately
4. **Keep backups**: Regularly backup your data directory in case you need to restore

## Need Help?

- **GitHub Issues**: https://github.com/secondwavetech/tadata-ce/issues
- **Documentation**: See `INSTALL.md` for installation help
- **Community Support**: Check GitHub Discussions

## Script Locations

- **Bash Script**: `deploy/reset-password.sh`
- **PowerShell Script**: `deploy/reset-password.ps1`
- **This Guide**: `deploy/PASSWORD_RESET.md`
