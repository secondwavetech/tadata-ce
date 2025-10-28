# tadata Community Edition - Testing Guide

## Quick Test Instructions

### Step 1: Build Local Test Images

```bash
cd ~/projects/binarycrush
./scripts/build-local-test.sh
```

This builds all 4 services with the `test` tag (~10-15 minutes).

### Step 2: Run Full Integration Test

```bash
cd ~/projects/tadata-ce
./test-community-edition.sh
```

This will:
- Clean any existing test environment
- Create test `.env` with Community Edition settings
- Start all services with local images
- Verify health checks
- Provide manual test checklist

### Step 3: Manual Testing Checklist

Once services are running, test these features:

#### ✅ **Single-User Authentication**
1. Open http://localhost:3000
2. Sign up with an email/password (creates first user)
3. Try to sign up again with different email
   - **Expected**: Error "Community Edition supports only one user"
4. Log in with your created account
   - **Expected**: Successful login with JWT token

#### ✅ **Multi-User Feature Guard**
1. Get your auth token from login
2. Try to create a second user via API:
   ```bash
   curl -X POST http://localhost:3001/api/user \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"email":"test2@example.com","password":"test123"}'
   ```
   - **Expected**: 403 Forbidden (MULTI_USER feature not available)

#### ✅ **Assistant Sharing Feature Guard**
1. Create an assistant (if UI allows)
2. Try to share it:
   ```bash
   curl -X POST http://localhost:3001/api/ai-assistant/ASSISTANT_ID/share \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"userIds":["user-id"]}'
   ```
   - **Expected**: 403 Forbidden (ASSISTANT_SHARING feature not available)

#### ✅ **Flow Sharing Feature Guard**
1. Create a flow (if available in UI)
2. Try to share it:
   ```bash
   curl -X POST http://localhost:3001/api/flow/share/FLOW_ID \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"userIds":["user-id"]}'
   ```
   - **Expected**: 403 Forbidden (FLOW_SHARING feature not available)

#### ✅ **RLS Database Verification**
1. Check server logs for successful migration:
   ```bash
   docker logs tadata-server | grep migration
   ```
   - **Expected**: See "migration:run:prod" completed

2. Check tadatauser creation:
   ```bash
   docker logs tadata-server | grep "tadata user"
   ```
   - **Expected**: See "Successfully initialized tadata user"

3. Verify RLS policies exist:
   ```bash
   docker exec -it tadata-db psql -U postgres -d tadata \
     -c "SELECT schemaname, tablename, policyname FROM pg_policies WHERE policyname LIKE 'tenant_isolation%';"
   ```
   - **Expected**: List of tables with tenant_isolation_policy

## Common Issues

### Services Won't Start
```bash
# Check logs
cd ~/projects/tadata-ce/deploy
docker-compose -f docker-compose.yml -f docker-compose.test.yml logs

# Clean and retry
docker-compose -f docker-compose.yml -f docker-compose.test.yml down -v
./test-community-edition.sh
```

### Database Connection Errors
- Check if PostgreSQL container is healthy
- Verify environment variables in `.env`
- Check server logs for connection errors

### Health Check Fails
- Server might still be running migrations
- Wait 30-60 seconds and retry
- Check server logs for errors

## Cleanup

The test script automatically cleans up on exit, but you can manually cleanup:

```bash
cd ~/projects/tadata-ce/deploy
docker-compose -f docker-compose.yml -f docker-compose.test.yml down -v
rm -f .env
```

## Success Criteria

All tests pass when:
- ✅ All 5 services start successfully
- ✅ Health check returns 200 OK
- ✅ First user can sign up
- ✅ Second signup is blocked
- ✅ Login works with created user
- ✅ MULTI_USER guard blocks user creation
- ✅ ASSISTANT_SHARING guard blocks sharing
- ✅ FLOW_SHARING guard blocks sharing
- ✅ Database migrations complete
- ✅ RLS policies are created
- ✅ tadatauser is initialized

## After Testing

Once all tests pass:
1. Stop test environment
2. Push code changes to binarycrush repo
3. Tag release (e.g., `v1.0.0`)
4. Run `./scripts/push-to-ghcr.sh v1.0.0` to publish images
5. Test tadata-ce with published images
6. Create GitHub release

## Notes

- Test uses locally-built images (not from registry)
- All data is ephemeral (volumes deleted on cleanup)
- ANTHROPIC_API_KEY not needed for basic tests
- Full AI features require valid API key
