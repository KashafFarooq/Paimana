# Paimana Express API

Node.js 20+, Express 5 and MongoDB API for the Flutter app. The API contract is
documented in [docs/api.md](./docs/api.md).

## Local setup

```powershell
Set-Location C:\Users\HP\Desktop\Paimana\paimana\backend
npm ci
Copy-Item .env.example .env
```

Edit `.env`: set `MONGODB_URI` to a reachable MongoDB replica set or Atlas
database URI; payment balance updates use transactions. Replace both JWT
secret placeholders with separate random values of at least 32 characters.
For example, run this twice in PowerShell and use each output for one secret:

```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

To enable assistant calls, add `GEMINI_API_KEY`; the key remains on the server.

Start the API:

```powershell
npm run dev
```

Before deploying, ensure MongoDB contains the schema indexes:

```powershell
npm run db:indexes
```

The health endpoint is `http://localhost:4000/health`; the REST API prefix is
`http://localhost:4000/api/v1`. The server binds to `0.0.0.0`, so a physical
phone on the same network can use the computer's private LAN IPv4 address
(allow inbound TCP port 4000 through Windows Firewall on the private network
if needed). From the Android emulator, the host computer is reachable as
`10.0.2.2`. Use HTTPS for deployed builds.

## Tests

```powershell
npm test
npm audit --omit=dev
```

## Security notes

- Production must use HTTPS and strong, separate JWT secrets.
- Set `CLIENT_ORIGIN` to the exact allowed browser origins in production.
- MongoDB indexes are declared on the schemas; run `npm run db:indexes` before
  serving production traffic.
- The backend uses request validation, account-scoped queries, password
  hashing, authentication and AI rate limits.
- Customer and order writes carrying `clientId` are account-scoped upserts, so
  an offline retry cannot create a duplicate record.
